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

if [ -z "$APK" ] || [ ! -f "$APK" ]; then echo "No APK" > qa-out/install.txt; exit 10; fi
record_state(){ local tag="$1"; adb shell dumpsys window > "qa-out/logs/${tag}-window.txt" 2>&1||true; adb shell pidof "$PACKAGE" > "qa-out/logs/${tag}-pid.txt"||true; adb exec-out screencap -p > "qa-out/screens/${tag}.png" 2>/dev/null||true; adb logcat -d > "qa-out/logs/${tag}-logcat.txt" 2>&1||true; }
shot(){ adb exec-out screencap -p > "qa-out/screens/$1.png" 2>/dev/null||true; }
combo(){ local d="$1"; shift; echo "combo duration=$d keys=$*" >> qa-out/input-sequence.txt; adb shell input keycombination -t "$d" "$@" >> qa-out/input-command.txt 2>&1||true; sleep .06; }
pulse(){ echo "pulse key=$1" >> qa-out/input-sequence.txt; adb shell input keyevent "$1" >> qa-out/input-command.txt 2>&1||true; sleep .25; }
if ! python3 -c 'import PIL,numpy' >/dev/null 2>&1; then python3 -m pip install --quiet pillow numpy >> qa-out/vision-setup.txt 2>&1||true; fi
cat > qa-out/vision_state.py <<'PY'
from PIL import Image
import numpy as np,sys
a=np.asarray(Image.open(sys.argv[1]).convert('RGB'))
g=a[300:1000,400:1800]; gm=((g[:,:,1]>120)&(g[:,:,1]>g[:,:,0]*1.15)&(g[:,:,1]>g[:,:,2]*1.10)&(g[:,:,0]<220)); gy,gx=np.where(gm)
ax=int(np.median(gx))+400 if gx.size>=500 else -1; ay=int(np.median(gy))+300 if gx.size>=500 else -1
w=a[500:680,1000:2700]; wm=np.all(w<80,axis=2); c=wm.sum(axis=0); xs=np.where(c>50)[0]; runs=[]
if xs.size:
 s=p=int(xs[0])
 for q in xs[1:]:
  q=int(q)
  if q>p+1:runs.append((s,p));s=q
  p=q
 runs.append((s,p))
wx=-1; bw=-1
for s,e in runs:
 if 40<=e-s+1<=130:
  ww=c[s:e+1]; wt=int(ww.sum())
  if wt>bw: wx=int(np.average(np.arange(s,e+1),weights=ww))+1000;bw=wt
print(f'ANDRE_X={ax} ANDRE_Y={ay} WORKER_X={wx}')
PY
sense_file(){ vals="$(python3 qa-out/vision_state.py "$1" 2>>qa-out/vision-errors.txt)"; echo "$2 $vals" >> qa-out/vision-log.txt; eval "$vals"; }
adb install -r "$APK" > qa-out/install.txt 2>&1||exit 10
adb shell settings put secure immersive_mode_confirmations confirmed >/dev/null 2>&1||true; adb shell settings put system accelerometer_rotation 0 >/dev/null 2>&1||true; adb shell settings put system user_rotation 1 >/dev/null 2>&1||true; adb shell wm user-rotation lock 1 >/dev/null 2>&1||true
adb logcat -c; adb shell am force-stop "$PACKAGE" >/dev/null 2>&1||true; adb shell am start -W -n "$PACKAGE/.AIRAppEntry" > qa-out/launch.txt 2>&1; sleep 16; record_state 00-startup-after-air-splash
pulse KEYCODE_X; sleep 2; pulse KEYCODE_X; sleep 6; record_state 01-main-menu; pulse KEYCODE_X; sleep 4; record_state 02-level-select; pulse KEYCODE_DPAD_RIGHT; pulse KEYCODE_X; sleep 12; record_state 03-level2-start; pulse KEYCODE_Y; sleep 2; record_state 04-level2-post-cutscene
pulse KEYCODE_V; sleep 1; record_state 10-liselot-start; combo 650 KEYCODE_DPAD_RIGHT; sleep .2; record_state 11-at-high-ledge-base; combo 220 KEYCODE_DPAD_RIGHT KEYCODE_C; sleep .06; combo 140 KEYCODE_DPAD_RIGHT KEYCODE_C; combo 180 KEYCODE_DPAD_RIGHT; sleep .35; record_state 12-platform-landing; sleep .65; record_state 13-platform-settled; combo 300 KEYCODE_DPAD_LEFT; sleep .35; record_state 20-short-crate-shove
adb shell input swipe 1350 1250 1350 1250 300 >> qa-out/input-command.txt 2>&1||true; sleep .45; record_state 30-andre-after-held-switch; adb shell input tap 2630 1250 >> qa-out/input-command.txt 2>&1||true; sleep .12; record_state 31-andre-jump-probe-airborne; sleep .88; record_state 32-andre-jump-probe-settled
# Run47: rendered closed-loop approach. Long jumps while clearly left; shorter jumps near the ledge face to avoid repeatedly overshooting the staging geometry.
for i in $(seq 1 12); do
 APPROACH_COUNT=$i; shot "40-pre-${i}"; sense_file "qa-out/screens/40-pre-${i}.png" "pre-${i}"
 if [ "$ANDRE_X" -ge 1180 ] && [ "$ANDRE_X" -le 1480 ] && [ "$ANDRE_Y" -ge 400 ] && [ "$ANDRE_Y" -le 650 ]; then STAGING_REACHED=1; echo "decision staging_reached pre=$i" >> qa-out/vision-log.txt; break; fi
 DUR=420; if [ "$ANDRE_X" -ge 1000 ]; then DUR=300; fi; if [ "$ANDRE_X" -ge 1120 ]; then DUR=240; fi
 echo "decision approach=$i andre_x=$ANDRE_X andre_y=$ANDRE_Y duration=$DUR" >> qa-out/vision-log.txt; combo "$DUR" KEYCODE_DPAD_RIGHT KEYCODE_C; sleep .35; shot "40-visual-approach-${i}-mid"; sleep .65; shot "40-visual-approach-${i}-settle"; sense_file "qa-out/screens/40-visual-approach-${i}-settle.png" "settle-${i}"
 if [ "$ANDRE_X" -ge 1180 ] && [ "$ANDRE_X" -le 1480 ] && [ "$ANDRE_Y" -ge 400 ] && [ "$ANDRE_Y" -le 650 ]; then STAGING_REACHED=1; echo "decision staging_reached approach=$i" >> qa-out/vision-log.txt; break; fi
done
if [ "$STAGING_REACHED" -eq 1 ]; then PREV_WORKER_X=-1; for i in $(seq -w 1 24); do sleep .25; shot "42-worker-${i}"; sense_file "qa-out/screens/42-worker-${i}.png" "worker-${i}"; if [ "$WORKER_X" -ge 2080 ] && [ "$PREV_WORKER_X" -ge 0 ] && [ "$WORKER_X" -gt $((PREV_WORKER_X+15)) ]; then WORKER_PHASE_REACHED=1; WORKER_X_AT_LAUNCH=$WORKER_X; break; fi; if [ "$WORKER_X" -ge 0 ]; then PREV_WORKER_X=$WORKER_X; fi; done; fi
if [ "$STAGING_REACHED" -eq 1 ] && [ "$WORKER_PHASE_REACHED" -eq 1 ]; then adb shell input keycombination -t 650 KEYCODE_DPAD_RIGHT KEYCODE_C >> qa-out/input-command.txt 2>&1 & P=$!; for i in $(seq -w 1 18); do sleep .05; shot "50-guided-jump-${i}"; done; wait $P||true; sleep .3; record_state 51-guided-settle; sleep .75; record_state 52-guided-long-settle; else record_state 49-visual-controller-prerequisite-not-reached; fi
adb logcat -d > qa-out/logcat-final.txt 2>&1||true; if grep -E "FATAL EXCEPTION|Process: $PACKAGE|Fatal signal|SecurityError|ArgumentError|ReferenceError|TypeError|VerifyError|RangeError" qa-out/logcat-final.txt > qa-out/fatal-scan.txt; then FAIL=1; else : > qa-out/fatal-scan.txt; fi
printf 'candidate_source=d7783af3dbaa0a27071c51d5965f2e9dec5864e2\ngame_source_modified=false\nforced_completion_used=false\nstate_teleport_used=false\nplayer_coordinate_mutation_used=false\ninternal_game_state_sensing_used=false\nrendered_screenshot_sensing_only=true\nordinary_input_only=true\nstaging_reached=%s\napproach_count=%s\nworker_phase_reached=%s\nworker_x_at_launch=%s\nfatal_scan=%s\n' "$STAGING_REACHED" "$APPROACH_COUNT" "$WORKER_PHASE_REACHED" "$WORKER_X_AT_LAUNCH" "$FAIL" > qa-out/metadata.txt
[ "$FAIL" -ne 0 ] && { echo FAIL_FATAL_RUNTIME > qa-out/result.txt; exit 20; }; echo PILOT_EXECUTED_REAL_INPUT_PATH > qa-out/result.txt
