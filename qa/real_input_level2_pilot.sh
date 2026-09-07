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

# Capture Android's real logical/physical input geometry before any touch assertions.
adb shell wm size > qa-out/logs/wm-size.txt 2>&1 || true
adb shell wm density > qa-out/logs/wm-density.txt 2>&1 || true
adb shell dumpsys display > qa-out/logs/display.txt 2>&1 || true
adb shell dumpsys input > qa-out/logs/input.txt 2>&1 || true
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

# Retain the proven keyboard-driven Liselot opening route so touch calibration starts
# from a stable, visually recognizable, low-risk position.
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
record_state "20-before-touch-jump"

# Calibrate ADB touch against the actual shipping JUMP control first. On the 3120x1440
# rendered emulator image, JUMP is the far-right bottom control centered near 2630,1250.
echo "tap x=2630 y=1250 label=shipping-mobile-jump-calibration" >> qa-out/input-sequence.txt
adb shell input tap 2630 1250 >> qa-out/input-command.txt 2>&1 || true
sleep 0.08
record_state "21-touch-jump-tplus080ms"
sleep 0.10
record_state "22-touch-jump-tplus180ms"
sleep 0.17
record_state "23-touch-jump-tplus350ms"
sleep 0.35
record_state "24-touch-jump-tplus700ms"
sleep 0.80
record_state "25-touch-jump-settled"

# Only after the harmless JUMP calibration, probe the real shipping SWITCH button.
echo "tap x=1350 y=1250 label=shipping-mobile-switch-after-calibration" >> qa-out/input-sequence.txt
adb shell input tap 1350 1250 >> qa-out/input-command.txt 2>&1 || true
sleep 0.15
record_state "30-after-touch-switch-150ms"
sleep 0.35
record_state "31-after-touch-switch-500ms"
sleep 0.70
record_state "32-after-touch-switch-settled"

# A second harmless JUMP tap provides a behavioral probe of whichever character is now
# controlled; rendered review decides identity rather than assuming the switch worked.
echo "tap x=2630 y=1250 label=post-switch-mobile-jump-probe" >> qa-out/input-sequence.txt
adb shell input tap 2630 1250 >> qa-out/input-command.txt 2>&1 || true
sleep 0.12
record_state "33-post-switch-jump-120ms"
sleep 0.18
record_state "34-post-switch-jump-300ms"
sleep 0.60
record_state "35-post-switch-jump-settled"

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
  echo "diagnostic=run23-mobile-touch-coordinate-and-switch-calibration"
  echo "fatal_scan=$FAIL"
  echo "screenshots=$(find qa-out/screens -type f -name '*.png' | wc -l)"
  echo "NOTE=Rendered review must first prove whether the shipping JUMP tap is received; only then may SWITCH behavior be interpreted."
} > qa-out/metadata.txt
if [ "$FAIL" -ne 0 ]; then echo "FAIL_FATAL_RUNTIME" > qa-out/result.txt; exit 20; fi
echo "PILOT_EXECUTED_REAL_INPUT_PATH" > qa-out/result.txt
exit 0
