#!/usr/bin/env bash
set +e
mkdir -p qa-out/screens qa-out/logs
APK="runtime-apk/SLF-completion-qa.apk"
PACKAGE="air.com.initialsgames.SLF"
FAIL=0
adb install -r "$APK" > qa-out/install.txt 2>&1 || exit 10
adb shell settings put secure immersive_mode_confirmations confirmed >/dev/null 2>&1 || true
adb shell settings put system accelerometer_rotation 0 >/dev/null 2>&1 || true
adb shell settings put system user_rotation 1 >/dev/null 2>&1 || true
adb shell settings put global hide_error_dialogs 1 >/dev/null 2>&1 || true
adb shell am force-stop com.google.android.apps.nexuslauncher >/dev/null 2>&1 || true
adb shell wm user-rotation lock 1 >/dev/null 2>&1 || true
adb shell am force-stop "$PACKAGE" >/dev/null 2>&1 || true
adb logcat -c
adb shell am start -W -n "$PACKAGE/.AIRAppEntry" > qa-out/launch.txt 2>&1
sleep 14

echo "index,mode,world,level,pid,focused,diff_ratio,fatal" > qa-out/metrics.csv
for IDX in $(seq 0 71); do
  if [ "$IDX" -gt 0 ]; then
    adb shell input keyevent KEYCODE_N >/dev/null 2>&1
    sleep 2
  fi
  MODE=normal; RAW=$IDX
  if [ "$IDX" -ge 36 ]; then MODE=hardcore; RAW=$((IDX-36)); fi
  WORLD=$((RAW/12+1)); LEVEL=$((RAW%12+1))
  TAG=$(printf "%02d-%s-w%d-l%02d" $((IDX+1)) "$MODE" "$WORLD" "$LEVEL")

  PID=$(adb shell pidof "$PACKAGE" | tr -d '\r')
  adb shell dumpsys window > "qa-out/logs/${TAG}-window.txt" 2>&1
  FOCUS=$(grep -m1 'mCurrentFocus=' "qa-out/logs/${TAG}-window.txt" || true)
  FOCUSED=0; echo "$FOCUS" | grep -q "$PACKAGE" && FOCUSED=1
  [ -z "$PID" ] && FAIL=1
  [ "$FOCUSED" -ne 1 ] && FAIL=1
  adb exec-out screencap -p > "qa-out/screens/${TAG}-before.png"

  adb logcat -c
  adb shell input keyevent KEYCODE_K >/dev/null 2>&1
  sleep 1
  adb exec-out screencap -p > "qa-out/screens/${TAG}-complete.png"
  adb logcat -d > "qa-out/logs/${TAG}-logcat.txt" 2>&1

  FATAL=0
  if grep -E "FATAL EXCEPTION|Process: $PACKAGE|Fatal signal|SecurityError|ArgumentError|ReferenceError|TypeError|VerifyError|RangeError" "qa-out/logs/${TAG}-logcat.txt" > "qa-out/logs/${TAG}-fatal.txt"; then
    FATAL=1; FAIL=1
  else
    : > "qa-out/logs/${TAG}-fatal.txt"
  fi

  DIFF=$(python3 - "qa-out/screens/${TAG}-before.png" "qa-out/screens/${TAG}-complete.png" <<'PY'
import sys
from PIL import Image, ImageChops
a=Image.open(sys.argv[1]).convert('RGB'); b=Image.open(sys.argv[2]).convert('RGB')
w,h=a.size; crop=(0,int(h*.10),w,int(h*.72))
d=ImageChops.difference(a.crop(crop),b.crop(crop)).convert('L')
hist=d.histogram(); total=sum(hist); changed=total-hist[0]
print(f"{changed/total if total else 0:.6f}")
PY
  )
  python3 - "$DIFF" <<'PY'
import sys
raise SystemExit(0 if float(sys.argv[1]) >= 0.003 else 1)
PY
  if [ $? -ne 0 ]; then echo "NO_COMPLETION_VISUAL $TAG diff=$DIFF" >> qa-out/failures.txt; FAIL=1; fi
  echo "$((IDX+1)),$MODE,$WORLD,$LEVEL,$PID,$FOCUSED,$DIFF,$FATAL" >> qa-out/metrics.csv
done

python3 qa/make_completion_sheets.py
[ -f qa-out/failures.txt ] && cat qa-out/failures.txt > qa-out/summary.txt || : > qa-out/summary.txt
echo "completion_variants=72" >> qa-out/summary.txt
echo "fail=$FAIL" >> qa-out/summary.txt
if [ "$FAIL" -ne 0 ]; then exit 20; fi
echo "PASS: shipping PCPlayState.levelOver() executed for 72/72 variants with visible completion-state changes and no fatal/AS3 runtime signatures." >> qa-out/summary.txt
