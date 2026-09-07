#!/usr/bin/env bash
set +e
mkdir -p qa-out/screens qa-out/logs
APK="$(find runtime-apk -type f -name '*.apk' -print -quit)"
PACKAGE="air.com.ramybaheeg.slfport"
FAIL=0

if [ -z "$APK" ] || [ ! -f "$APK" ]; then
  echo "No APK discovered under runtime-apk" > qa-out/install.txt
  find runtime-apk -maxdepth 4 -type f -printf '%p\n' >> qa-out/install.txt 2>/dev/null || true
  echo "INSTALL_FAIL_NO_APK" > qa-out/result.txt
  exit 10
fi

echo "APK=$APK" > qa-out/apk-path.txt

record_state() {
  local tag="$1"
  adb shell dumpsys window > "qa-out/logs/${tag}-window.txt" 2>&1 || true
  adb shell pidof "$PACKAGE" | tr -d '\r' > "qa-out/logs/${tag}-pid.txt" || true
  adb exec-out screencap -p > "qa-out/screens/${tag}.png" 2>/dev/null || true
  adb logcat -d > "qa-out/logs/${tag}-logcat.txt" 2>&1 || true
}

combo() {
  local duration="$1"; shift
  echo "combo duration=${duration} keys=$*" >> qa-out/input-sequence.txt
  adb shell input keycombination -t "$duration" "$@" >> qa-out/input-command.txt 2>&1
  local rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "keycombination failed rc=$rc; falling back to sequential keyevents" >> qa-out/input-command.txt
    for key in "$@"; do adb shell input keyevent --longpress "$key" >> qa-out/input-command.txt 2>&1 || true; done
  fi
  sleep 0.06
}

pulse() {
  local key="$1"
  echo "pulse key=$key" >> qa-out/input-sequence.txt
  adb shell input keyevent "$key" >> qa-out/input-command.txt 2>&1 || true
  sleep 0.25
}

double_jump_profile() {
  local tag="$1" first="$2" gap="$3" second="$4" carry="$5"
  echo "profile=$tag first=$first gap=$gap second=$second carry=$carry" >> qa-out/input-sequence.txt
  combo "$first" KEYCODE_DPAD_RIGHT KEYCODE_C
  record_state "${tag}-after-first"
  sleep "$gap"
  combo "$second" KEYCODE_DPAD_RIGHT KEYCODE_C
  record_state "${tag}-after-second"
  combo "$carry" KEYCODE_DPAD_RIGHT
  sleep 0.30
  record_state "${tag}-after-carry"
}

adb install -r "$APK" > qa-out/install.txt 2>&1
if [ $? -ne 0 ]; then echo "INSTALL_FAIL" > qa-out/result.txt; exit 10; fi
adb shell settings put secure immersive_mode_confirmations confirmed >/dev/null 2>&1 || true
adb shell settings put system accelerometer_rotation 0 >/dev/null 2>&1 || true
adb shell settings put system user_rotation 1 >/dev/null 2>&1 || true
adb shell settings put global hide_error_dialogs 1 >/dev/null 2>&1 || true
adb shell am force-stop com.google.android.apps.nexuslauncher >/dev/null 2>&1 || true
adb shell wm user-rotation lock 1 >/dev/null 2>&1 || true
adb shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1 || true
adb shell wm dismiss-keyguard >/dev/null 2>&1 || true
adb logcat -c
adb shell am force-stop "$PACKAGE" >/dev/null 2>&1 || true
adb shell am start -W -n "$PACKAGE/.AIRAppEntry" > qa-out/launch.txt 2>&1
sleep 16
record_state "00-startup-after-air-splash"

# Shipping navigation path: intro -> main menu -> Factory Floor -> Level Select -> Level 2.
pulse KEYCODE_X
sleep 2
pulse KEYCODE_X
sleep 6
record_state "01-main-menu"
pulse KEYCODE_X
sleep 4
record_state "02-level-select"
pulse KEYCODE_DPAD_RIGHT
pulse KEYCODE_X
sleep 12
record_state "03-level2-start"

# Switch immediately to Liselot. Shipping source says her second jump requires a NEW C
# just-press after >0.1 s airborne. Run bounded profiles with explicit release gaps and
# a post-double-jump RIGHT carry so she can move horizontally over the x=740 platform lip.
pulse KEYCODE_V
sleep 1
record_state "20-liselot-start"

# Approach the base of the high platform without jumping.
combo 650 KEYCODE_DPAD_RIGHT
sleep 0.25
record_state "21-at-high-ledge-base"

# Focused real-input timing sweep. No X/action, no state mutation, no completion hook.
double_jump_profile "30-p1" 220 0.14 160 420
sleep 0.60
double_jump_profile "31-p2" 260 0.13 180 520
sleep 0.60
double_jump_profile "32-p3" 300 0.12 160 620
sleep 0.60

record_state "40-diagnostic-final"

adb logcat -d > qa-out/logcat-final.txt 2>&1 || true
if grep -E "FATAL EXCEPTION|Process: $PACKAGE|Fatal signal|SecurityError|ArgumentError|ReferenceError|TypeError|VerifyError|RangeError" qa-out/logcat-final.txt > qa-out/fatal-scan.txt; then
  FAIL=1
else
  : > qa-out/fatal-scan.txt
fi

{
  echo "candidate_source=d7783af3dbaa0a27071c51d5965f2e9dec5864e2"
  echo "qa_branch=gate2a-customer-facing-qa-r13"
  echo "game_source_modified=false"
  echo "forced_completion_used=false"
  echo "state_teleport_used=false"
  echo "player_coordinate_mutation_used=false"
  echo "level=2"
  echo "mode=normal"
  echo "diagnostic=liselot-double-jump-timing-sweep"
  echo "fatal_scan=$FAIL"
  echo "screenshots=$(find qa-out/screens -type f -name '*.png' | wc -l)"
  echo "NOTE=Manual rendered review determines whether Liselot cleared the high platform and which timing profile succeeded."
} > qa-out/metadata.txt

if [ "$FAIL" -ne 0 ]; then echo "FAIL_FATAL_RUNTIME" > qa-out/result.txt; exit 20; fi
echo "PILOT_EXECUTED_REAL_INPUT_PATH" > qa-out/result.txt
exit 0
