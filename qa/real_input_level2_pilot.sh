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

shot() {
  local tag="$1"
  adb exec-out screencap -p > "qa-out/screens/${tag}.png" 2>/dev/null || true
}

combo() {
  local duration="$1"; shift
  echo "combo duration=${duration} keys=$*" >> qa-out/input-sequence.txt
  if [ "$#" -ge 2 ]; then
    adb shell input keycombination -t "$duration" "$@" >> qa-out/input-command.txt 2>&1
    local rc=$?
    if [ "$rc" -ne 0 ]; then
      echo "keycombination failed rc=$rc; falling back to sequential keyevents" >> qa-out/input-command.txt
      for key in "$@"; do adb shell input keyevent --longpress "$key" >> qa-out/input-command.txt 2>&1 || true; done
    fi
  else
    adb shell input keyevent --longpress "$1" >> qa-out/input-command.txt 2>&1 || true
  fi
  sleep 0.06
}

pulse() {
  local key="$1"
  echo "pulse key=$key" >> qa-out/input-sequence.txt
  adb shell input keyevent "$key" >> qa-out/input-command.txt 2>&1 || true
  sleep 0.25
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
pulse KEYCODE_Y
sleep 2
record_state "04-level2-post-cutscene"

# Preserve the rendered-proven Liselot setup.
pulse KEYCODE_V
sleep 1
record_state "10-liselot-start"
combo 650 KEYCODE_DPAD_RIGHT
sleep 0.20
record_state "11-at-high-ledge-base"
combo 220 KEYCODE_DPAD_RIGHT KEYCODE_C
sleep 0.06
combo 140 KEYCODE_DPAD_RIGHT KEYCODE_C
combo 180 KEYCODE_DPAD_RIGHT
sleep 0.35
record_state "12-platform-landing"
sleep 0.65
record_state "13-platform-settled"
combo 300 KEYCODE_DPAD_LEFT
sleep 0.35
record_state "20-short-crate-shove"

# Use the rendered-proven shipping SWITCH hold, then reconfirm Andre identity.
echo "swipehold x=1350 y=1250 duration=300 label=shipping-mobile-switch-held-to-andre" >> qa-out/input-sequence.txt
adb shell input swipe 1350 1250 1350 1250 300 >> qa-out/input-command.txt 2>&1 || true
sleep 0.45
record_state "30-andre-after-held-switch"
echo "tap x=2630 y=1250 label=andre-identity-jump-probe" >> qa-out/input-sequence.txt
adb shell input tap 2630 1250 >> qa-out/input-command.txt 2>&1 || true
sleep 0.12
record_state "31-andre-jump-probe-airborne"
sleep 0.88
record_state "32-andre-jump-probe-settled"

# Reproduce the first three ordinary Andre approaches.
for i in 1 2 3; do
  combo 420 KEYCODE_DPAD_RIGHT KEYCODE_C
  sleep 0.45
  record_state "40-andre-approach-${i}"
done

# Run 31 rendered-proved that waiting on the narrow staging ledge lets the worker patrol
# away to the right before Andre makes the final platform jump. Keep that successful timing.
sleep 0.85
record_state "41-andre-staging-ledge-settled"
for i in 01 02 03 04 05 06 07 08; do
  sleep 0.50
  shot "42-worker-walkaway-wait-${i}"
done

# Make the same ordinary final RIGHT+JUMP and capture its landing window.
combo 420 KEYCODE_DPAD_RIGHT KEYCODE_C
for i in 01 02 03 04 05 06; do
  sleep 0.08
  shot "50-safe-final-jump-${i}"
done
record_state "51-safe-main-platform-landing"

# Run 31 proved Andre can be safely on the final platform with two hearts while the worker
# is still to the right. Test one immediate ordinary RIGHT+JUMP from that safe landing window
# to traverse behind/over the worker before its return. No state sensing or mutation is used.
combo 420 KEYCODE_DPAD_RIGHT KEYCODE_C
for i in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20; do
  sleep 0.08
  shot "60-post-landing-traverse-${i}"
done
sleep 0.35
record_state "61-post-traverse-settle"
sleep 0.75
record_state "62-post-traverse-long-settle"

adb logcat -d > qa-out/logcat-final.txt 2>&1 || true
if grep -E "FATAL EXCEPTION|Process: $PACKAGE|Fatal signal|SecurityError|ArgumentError|ReferenceError|TypeError|VerifyError|RangeError" qa-out/logcat-final.txt > qa-out/fatal-scan.txt; then FAIL=1; else : > qa-out/fatal-scan.txt; fi
{
  echo "candidate_source=d7783af3dbaa0a27071c51d5965f2e9dec5864e2"
  echo "qa_branch=gate2a-customer-facing-qa-r13"
  echo "game_source_modified=false"
  echo "forced_completion_used=false"
  echo "state_teleport_used=false"
  echo "player_coordinate_mutation_used=false"
  echo "level=2"
  echo "mode=normal"
  echo "diagnostic=run32-safe-landing-immediate-right-jump-traverse"
  echo "run31_safe_landing_reused=true"
  echo "fatal_scan=$FAIL"
  echo "screenshots=$(find qa-out/screens -type f -name '*.png' | wc -l)"
  echo "NOTE=Review every rendered frame sequentially. Run 31 proved the pre-jump patrol wait yields a safe two-heart main-platform landing. Run 32 keeps that timing and adds exactly one immediate ordinary RIGHT+JUMP from the safe landing window to test traversal past the worker."
} > qa-out/metadata.txt
if [ "$FAIL" -ne 0 ]; then echo "FAIL_FATAL_RUNTIME" > qa-out/result.txt; exit 20; fi
echo "PILOT_EXECUTED_REAL_INPUT_PATH" > qa-out/result.txt
exit 0
