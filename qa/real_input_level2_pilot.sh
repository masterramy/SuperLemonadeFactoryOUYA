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
# The level cutscene explicitly advertises Y as its shipping skip control. Use it before
# any traversal inputs so QA never accidentally consumes the route while advancing story text.
pulse KEYCODE_Y
sleep 2
record_state "04-level2-post-cutscene"

# Proven Liselot tall-platform route.
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

# Deterministic cutscene skipping changes the moving-platform phase. Four proven safe approach
# jumps still place Andre immediately left of the tall platform, but the previous extra step-up
# pushed him into the worker enemy. Use one short genuine running jump and settle on the left edge.
pulse KEYCODE_V
record_state "30-andre-resume"
for i in 1 2 3 4; do
  combo 420 KEYCODE_DPAD_RIGHT KEYCODE_C
  sleep 0.45
  record_state "31-andre-approach-${i}"
done
combo 180 KEYCODE_DPAD_RIGHT KEYCODE_C
sleep 0.70
record_state "40-andre-left-edge-landing"
sleep 0.75
record_state "42-andre-left-edge-settled"

# Natural Liselot reunion attempt from the now-bounded Andre position.
pulse KEYCODE_V
sleep 0.30
record_state "50-liselot-rejoin-start"
combo 220 KEYCODE_DPAD_RIGHT KEYCODE_C
sleep 0.06
combo 140 KEYCODE_DPAD_RIGHT KEYCODE_C
combo 180 KEYCODE_DPAD_RIGHT
sleep 0.50
record_state "51-liselot-rejoin-landing"
sleep 0.55
record_state "52-liselot-rejoined"

# Proven Liselot spike-cross sequence, attempted only through shipping controls.
combo 250 KEYCODE_DPAD_RIGHT
sleep 0.20
record_state "58-liselot-near-spike-lip"
combo 240 KEYCODE_DPAD_RIGHT KEYCODE_C
sleep 0.06
combo 180 KEYCODE_DPAD_RIGHT KEYCODE_C
combo 520 KEYCODE_DPAD_RIGHT
sleep 0.65
record_state "60-liselot-spike-cross-attempt"
sleep 0.45
record_state "61-liselot-spike-cross-settled"
combo 650 KEYCODE_DPAD_RIGHT
sleep 0.55
record_state "62-liselot-exit-approach"

# Andre continuation is intentionally bounded. If the left-edge landing remains alive,
# switch back and test a worker-clearing jump before any blind rightward push.
pulse KEYCODE_V
sleep 0.30
record_state "70-andre-resume-after-liselot"
combo 360 KEYCODE_DPAD_RIGHT KEYCODE_C
combo 220 KEYCODE_DPAD_RIGHT
sleep 0.70
record_state "74-andre-worker-jump-attempt"
sleep 0.50
record_state "75-andre-worker-jump-settled"
combo 220 KEYCODE_DPAD_RIGHT
sleep 0.80
record_state "76-both-exit-approach"

# Completion must come only from shipping exit overlap/proximity logic.
combo 220 KEYCODE_DPAD_RIGHT
sleep 0.80
record_state "80-natural-completion-check"
sleep 1.25
record_state "81-natural-completion-settled"

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
  echo "diagnostic=deterministic-cutscene-skip-short-andre-left-edge-landing"
  echo "fatal_scan=$FAIL"
  echo "screenshots=$(find qa-out/screens -type f -name '*.png' | wc -l)"
  echo "NOTE=Manual sequential rendered review determines Andre survival/reunion, Liselot traversal, and whether shipping LEVEL COMPLETE occurred."
} > qa-out/metadata.txt

if [ "$FAIL" -ne 0 ]; then echo "FAIL_FATAL_RUNTIME" > qa-out/result.txt; exit 20; fi
echo "PILOT_EXECUTED_REAL_INPUT_PATH" > qa-out/result.txt
exit 0
