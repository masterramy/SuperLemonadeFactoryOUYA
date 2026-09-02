#!/usr/bin/env bash
set +e
mkdir -p boundaries
APK="runtime-apk/SLF-boundary-qa.apk"
PACKAGE="air.com.initialsgames.SLF"
FAIL=0
adb install -r "$APK" > boundaries/install.txt 2>&1 || exit 10
adb shell settings put secure immersive_mode_confirmations confirmed >/dev/null 2>&1 || true
adb shell settings put system accelerometer_rotation 0 >/dev/null 2>&1 || true
adb shell settings put system user_rotation 1 >/dev/null 2>&1 || true
adb shell settings put global hide_error_dialogs 1 >/dev/null 2>&1 || true
adb shell am force-stop com.google.android.apps.nexuslauncher >/dev/null 2>&1 || true
adb shell wm user-rotation lock 1 >/dev/null 2>&1 || true
echo "case,description,pid_before,pid_after,focused_after,width,height,diff_ratio,fatal" > boundaries/metrics.csv
descriptions=("normal-w1-l12-to-cinematic1" "normal-w2-l12-to-cinematic2" "normal-w3-l12-to-cinematic3" "old-normal-w1-to-w2" "old-normal-w2-to-w3" "old-normal-w3-to-hc-w1" "old-hc-w1-to-hc-w2" "old-hc-w2-to-hc-w3" "old-hc-w3-to-prize")

for C in $(seq 1 9); do
  DESC=${descriptions[$((C-1))]}
  TAG=$(printf "%02d-%s" "$C" "$DESC")
  adb shell am force-stop "$PACKAGE" >/dev/null 2>&1 || true
  adb logcat -c
  adb shell am start -W -n "$PACKAGE/.AIRAppEntry" > "boundaries/${TAG}-launch.txt" 2>&1
  sleep 5
  adb shell input keyevent "KEYCODE_${C}" >/dev/null 2>&1
  sleep 10
  PID1=$(adb shell pidof "$PACKAGE" | tr -d '\r')
  adb exec-out screencap -p > "boundaries/${TAG}-before.png"
  adb logcat -c
  adb shell input keyevent KEYCODE_K >/dev/null 2>&1
  sleep 7
  PID2=$(adb shell pidof "$PACKAGE" | tr -d '\r')
  adb shell dumpsys window > "boundaries/${TAG}-window.txt" 2>&1
  FOCUS=$(grep -m1 'mCurrentFocus=' "boundaries/${TAG}-window.txt" || true)
  FOCUSED=0; echo "$FOCUS" | grep -q "$PACKAGE" && FOCUSED=1
  adb exec-out screencap -p > "boundaries/${TAG}-after.png"
  adb logcat -d > "boundaries/${TAG}-logcat.txt" 2>&1
  FATAL=0
  if grep -E "FATAL EXCEPTION|Process: $PACKAGE|Fatal signal|SecurityError|ArgumentError|ReferenceError|TypeError|VerifyError|RangeError" "boundaries/${TAG}-logcat.txt" > "boundaries/${TAG}-fatal.txt"; then FATAL=1; FAIL=1; else : > "boundaries/${TAG}-fatal.txt"; fi
  [ -z "$PID1" ] && FAIL=1
  [ -z "$PID2" ] && FAIL=1
  [ "$FOCUSED" -ne 1 ] && FAIL=1
  MET=$(python3 qa/boundary_metrics.py "boundaries/${TAG}-before.png" "boundaries/${TAG}-after.png")
  IFS=',' read W H DIFF <<< "$MET"
  python3 -c 'import sys; w,h=int(sys.argv[1]),int(sys.argv[2]); d=float(sys.argv[3]); raise SystemExit(0 if w>h and d>=0.01 else 1)' "$W" "$H" "$DIFF"
  if [ $? -ne 0 ]; then echo "BOUNDARY_VISUAL_RISK $TAG ${W}x${H} diff=$DIFF" >> boundaries/failures.txt; FAIL=1; fi
  echo "$C,$DESC,$PID1,$PID2,$FOCUSED,$W,$H,$DIFF,$FATAL" >> boundaries/metrics.csv
done

python3 qa/boundary_sheet.py
[ -f boundaries/failures.txt ] && cat boundaries/failures.txt > boundaries/summary.txt || : > boundaries/summary.txt
echo "boundaries=9" >> boundaries/summary.txt
echo "fail=$FAIL" >> boundaries/summary.txt
if [ "$FAIL" -ne 0 ]; then exit 20; fi
echo "PASS-CANDIDATE: 9/9 actual PCPlayState.levelOver boundary invocations changed state while process/focus/landscape stayed healthy and fatal scan stayed empty. Visual target-state identity requires contact-sheet review." >> boundaries/summary.txt
