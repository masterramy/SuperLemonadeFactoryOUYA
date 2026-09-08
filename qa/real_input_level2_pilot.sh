#!/usr/bin/env bash
set +e
mkdir -p qa-out/screens qa-out/logs
APK="$(find runtime-apk -type f -name '*.apk' -print -quit)"
PACKAGE="air.com.ramybaheeg.slfport"
FAIL=0
STAGING_REACHED=0
WORKER_PHASE_REACHED=0
APPROACH_COUNT=0
WORKER_X_AT_LAUNCH=-1

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

# Read-only rendered-state helper. It inspects screenshot pixels only; it does not read or mutate game state.
if ! python3 -c 'import PIL, numpy' >/dev/null 2>&1; then
  python3 -m pip install --quiet --disable-pip-version-check pillow numpy >> qa-out/vision-setup.txt 2>&1 || true
fi
cat > qa-out/vision_state.py <<'PY'
from PIL import Image
import numpy as np
import sys

path = sys.argv[1]
a = np.asarray(Image.open(path).convert("RGB"))

# Andre: green sprite pixels in gameplay area; HUD/icons are excluded by the crop.
g = a[300:1000, 400:1800]
gm = ((g[:,:,1] > 120) &
      (g[:,:,1] > g[:,:,0] * 1.15) &
      (g[:,:,1] > g[:,:,2] * 1.10) &
      (g[:,:,0] < 220))
gy, gx = np.where(gm)
if gx.size >= 500:
    andre_x = int(np.median(gx)) + 400
    andre_y = int(np.median(gy)) + 300
else:
    andre_x = andre_y = -1

# Worker: dense near-black 88-104 px silhouette in the main-platform band.
w = a[500:680, 1000:2700]
wm = np.all(w < 80, axis=2)
counts = wm.sum(axis=0)
xs = np.where(counts > 50)[0]
runs = []
if xs.size:
    start = prev = int(xs[0])
    for xv in xs[1:]:
        xv = int(xv)
        if xv > prev + 1:
            runs.append((start, prev))
            start = xv
        prev = xv
    runs.append((start, prev))
worker_x = -1
best_weight = -1
for start, end in runs:
    width = end - start + 1
    if 40 <= width <= 130:
        ww = counts[start:end+1]
        weight = int(ww.sum())
        if weight > best_weight:
            xx = np.arange(start, end+1)
            worker_x = int(np.average(xx, weights=ww)) + 1000
            best_weight = weight
print(f"ANDRE_X={andre_x} ANDRE_Y={andre_y} WORKER_X={worker_x}")
PY

sense_file() {
  local file="$1" label="$2"
  local vals
  vals="$(python3 qa-out/vision_state.py "$file" 2>>qa-out/vision-errors.txt)"
  echo "$label $vals" >> qa-out/vision-log.txt
  eval "$vals"
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

# Closed-loop prerequisite: after each ordinary approach, let Andre settle and inspect only the rendered pixels.
for i in 1 2 3 4 5 6 7 8; do
  APPROACH_COUNT=$i
  combo 420 KEYCODE_DPAD_RIGHT KEYCODE_C
  sleep 0.45
  shot "40-visual-approach-${i}-mid"
  sleep 0.70
  shot "40-visual-approach-${i}-settle"
  sense_file "qa-out/screens/40-visual-approach-${i}-settle.png" "approach-${i}"
  if [ "$ANDRE_X" -ge 1180 ] && [ "$ANDRE_X" -le 1480 ] && [ "$ANDRE_Y" -ge 400 ] && [ "$ANDRE_Y" -le 620 ]; then
    STAGING_REACHED=1
    echo "decision staging_reached approach=$i andre_x=$ANDRE_X andre_y=$ANDRE_Y" >> qa-out/vision-log.txt
    break
  fi
done

if [ "$STAGING_REACHED" -eq 1 ]; then
  PREV_WORKER_X=-1
  for i in $(seq -w 1 24); do
    sleep 0.25
    shot "42-visual-worker-poll-${i}"
    sense_file "qa-out/screens/42-visual-worker-poll-${i}.png" "worker-poll-${i}"
    if [ "$WORKER_X" -ge 2080 ] && [ "$PREV_WORKER_X" -ge 0 ] && [ "$WORKER_X" -gt $((PREV_WORKER_X + 15)) ]; then
      WORKER_PHASE_REACHED=1
      WORKER_X_AT_LAUNCH=$WORKER_X
      echo "decision worker_rightward_phase worker_x=$WORKER_X previous_x=$PREV_WORKER_X" >> qa-out/vision-log.txt
      break
    fi
    if [ "$WORKER_X" -ge 0 ]; then PREV_WORKER_X=$WORKER_X; fi
  done
fi

if [ "$STAGING_REACHED" -eq 1 ] && [ "$WORKER_PHASE_REACHED" -eq 1 ]; then
  echo "combo duration=650 keys=KEYCODE_DPAD_RIGHT KEYCODE_C label=visual-guided-final-platform-jump" >> qa-out/input-sequence.txt
  adb shell input keycombination -t 650 KEYCODE_DPAD_RIGHT KEYCODE_C >> qa-out/input-command.txt 2>&1 &
  LAND_PID=$!
  for i in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18; do
    sleep 0.05
    shot "50-visual-guided-platform-jump-${i}"
  done
  wait "$LAND_PID" 2>/dev/null || true
  for i in 19 20 21 22 23 24; do
    sleep 0.08
    shot "50-visual-guided-platform-jump-post-${i}"
  done
  sleep 0.25
  record_state "51-visual-guided-platform-jump-settle"
  sleep 0.75
  record_state "52-visual-guided-platform-jump-long-settle"
else
  record_state "49-visual-controller-prerequisite-not-reached"
fi

adb logcat -d > qa-out/logcat-final.txt 2>&1 || true
if grep -E "FATAL EXCEPTION|Process: $PACKAGE|Fatal signal|SecurityError|ArgumentError|ReferenceError|TypeError|VerifyError|RangeError" qa-out/logcat-final.txt > qa-out/fatal-scan.txt; then FAIL=1; else : > qa-out/fatal-scan.txt; fi
{
  echo "candidate_source=d7783af3dbaa0a27071c51d5965f2e9dec5864e2"
  echo "qa_branch=gate2a-customer-facing-qa-r13"
  echo "game_source_modified=false"
  echo "forced_completion_used=false"
  echo "state_teleport_used=false"
  echo "player_coordinate_mutation_used=false"
  echo "internal_game_state_sensing_used=false"
  echo "rendered_screenshot_sensing_only=true"
  echo "level=2"
  echo "mode=normal"
  echo "diagnostic=run46-visual-closed-loop-staging-and-worker-phase"
  echo "ordinary_input_only=true"
  echo "staging_reached=$STAGING_REACHED"
  echo "approach_count=$APPROACH_COUNT"
  echo "worker_phase_reached=$WORKER_PHASE_REACHED"
  echo "worker_x_at_launch=$WORKER_X_AT_LAUNCH"
  echo "isolated_final_jump_duration_ms=650"
  echo "downstream_clear_inputs_executed=false"
  echo "fatal_scan=$FAIL"
  echo "screenshots=$(find qa-out/screens -type f -name '*.png' | wc -l)"
  echo "NOTE=Run 46 rejects elapsed-time state assumptions. A QA-only detector reads rendered screenshot pixels for Andre and worker location, then decides when to issue only ordinary shipping RIGHT/JUMP inputs. It never reads or mutates internal game state. Semantic proof still requires sequential review of all captured frames. Shipping game source/state are untouched."
} > qa-out/metadata.txt
if [ "$FAIL" -ne 0 ]; then echo "FAIL_FATAL_RUNTIME" > qa-out/result.txt; exit 20; fi
echo "PILOT_EXECUTED_REAL_INPUT_PATH" > qa-out/result.txt
exit 0
