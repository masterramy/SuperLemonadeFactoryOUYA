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

# Keep the proven Liselot preparation so the Level 2 object/patrol phase matches the
# deterministic cutscene-skipped route. All movement is ordinary shipping input.
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

# Run 14 semantic correction: the earlier tag called the x~220 state a platform
# landing, but rendered review proves Andre was still below the first raised platform.
# Reproduce the four safe approach jumps and the short base positioning only.
pulse KEYCODE_V
sleep 0.30
record_state "30-andre-resume"
for i in 1 2 3 4; do
  combo 420 KEYCODE_DPAD_RIGHT KEYCODE_C
  sleep 0.45
  record_state "31-andre-approach-${i}"
done
combo 180 KEYCODE_DPAD_RIGHT KEYCODE_C
sleep 0.70
record_state "40-andre-platform-base"

# First bounded jump reaches the small x~220 moving step. Stop all forward input there.
combo 360 KEYCODE_DPAD_RIGHT KEYCODE_C
sleep 0.70
record_state "41-andre-on-left-step"

# The first army patrol traverses x260..490 above Andre. Run 14 proved Andre can remain
# alive on this step while the patrol walks away. Wait it out rather than colliding blindly.
sleep 4.50
record_state "42-army-clear-window"

# From the step, use one full ordinary running jump to attempt the first raised platform.
# No action dash, teleport, coordinate mutation, forced completion, or game-source hook.
combo 420 KEYCODE_DPAD_RIGHT KEYCODE_C
sleep 0.80
record_state "43-first-platform-ascent-attempt"
sleep 0.85
record_state "44-first-platform-ascent-settled"

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
  echo "diagnostic=run15-first-army-wait-and-andre-first-platform-ascent"
  echo "fatal_scan=$FAIL"
  echo "screenshots=$(find qa-out/screens -type f -name '*.png' | wc -l)"
  echo "NOTE=Manual sequential rendered review determines patrol clearance and whether Andre genuinely ascended the first raised platform."
} > qa-out/metadata.txt

if [ "$FAIL" -ne 0 ]; then echo "FAIL_FATAL_RUNTIME" > qa-out/result.txt; exit 20; fi
echo "PILOT_EXECUTED_REAL_INPUT_PATH" > qa-out/result.txt
exit 0
