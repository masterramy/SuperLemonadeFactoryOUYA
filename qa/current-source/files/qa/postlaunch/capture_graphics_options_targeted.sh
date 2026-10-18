#!/usr/bin/env bash
# Isolated emulator QA only. No production app, signing key, levels or saves.
set -euo pipefail
APK="${1:?Need disposable x64 DEV APK}"; OUT="${2:-qa-options-capture}"
PKG='com.ramybaheeg.slfport.dev'
mkdir -p "$OUT"
[[ -f "$APK" ]] || { echo "Missing APK: $APK" >&2; exit 1; }
adb install -r "$APK" | tee "$OUT/install.txt"
adb shell pm clear "$PKG" >/dev/null
adb shell wm size 1920x1080
adb shell wm density 420
adb shell am start -W -n "$PKG/.AIRAppEntry" | tee "$OUT/launch.txt"
# Do not automatically dismiss an ANR and then call navigation verified.
# Any launcher/system blocking dialog must remain visible and make QA fail.
sleep 12
capture() {
  local name="$1"
  adb exec-out screencap -p > "$OUT/$name.png"
  adb shell uiautomator dump /sdcard/gate2a.xml >/dev/null
  adb exec-out cat /sdcard/gate2a.xml > "$OUT/$name.xml"
}
# From title -> original main menu. Options button internal x224,y291.
adb shell input tap 960 850; sleep 5
capture '01_menu'
adb shell input tap 735 900; sleep 4
capture '02_options_classic'
# Options: Graphics is internal x140,y210; target its center at x~500,y~660.
adb shell input tap 495 655; sleep 3
capture '03_graphics_toggled'
adb shell input tap 495 655; sleep 3
capture '04_graphics_restored'
# Blank tap must never trigger Delete; hit between visible buttons.
adb shell input tap 1400 750; sleep 3
capture '05_blank_touch'
python3 qa/postlaunch/verify_options_screen_evidence.py "$OUT" | tee "$OUT/guard_result.txt"
echo 'Automated UI pixel checks complete; inspect all PNGs before human visual PASS.'
