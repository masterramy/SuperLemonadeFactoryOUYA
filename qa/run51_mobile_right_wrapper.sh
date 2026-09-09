#!/usr/bin/env bash
set -euo pipefail
SRC="qa/real_input_level2_pilot.sh"
TMP="$(mktemp)"
python3 - "$SRC" "$TMP" <<'PY'
import sys
src,dst=sys.argv[1:]
s=open(src,encoding='utf-8').read()
old='''  echo "combo duration=520 keys=KEYCODE_DPAD_RIGHT label=guided-airborne-right-after-jump" >> qa-out/input-sequence.txt\n  adb shell input keycombination -t 520 KEYCODE_DPAD_RIGHT >> qa-out/input-command.txt 2>&1 &\n  P=$!\n'''
new='''  echo "swipehold x=920 y=1250 duration=520 label=guided-airborne-right-after-jump-shipping-mobile-right" >> qa-out/input-sequence.txt\n  adb shell input swipe 920 1250 920 1250 520 >> qa-out/input-command.txt 2>&1 &\n  P=$!\n'''
if s.count(old) != 1:
    raise SystemExit(f'Run51 patch expected one final RIGHT block, found {s.count(old)}')
s=s.replace(old,new)
s=s.replace('diagnostic=run50-jump-first-then-airborne-right','diagnostic=run51-jump-first-then-mobile-right-hold',1)
needle='  echo "airborne_right_duration_ms=520"\n'
if s.count(needle) != 1:
    raise SystemExit('Run51 metadata duration anchor missing')
s=s.replace(needle, needle+'  echo "airborne_right_input=shipping_mobile_right_hold_x920_y1250"\n',1)
oldnote='NOTE=Run 50 preserves Run49 closed-loop staging and far-right/rightward patrol prerequisites. It changes only final ordinary-input geometry from simultaneous RIGHT+JUMP to JUMP first, a brief vertical lead, then RIGHT while airborne. No internal state sensing or mutation. Semantic proof requires sequential rendered review.'
newnote='NOTE=Run 51 preserves Run50 closed-loop staging, far-right/rightward patrol gating, and JUMP-first 80ms vertical lead. It changes only the previously invalid single-key RIGHT delivery to an ordinary shipping mobile RIGHT hold at rendered control center x=920,y=1250 for 520ms. No internal state sensing or mutation. Semantic proof requires sequential rendered review.'
if oldnote not in s:
    raise SystemExit('Run51 NOTE anchor missing')
s=s.replace(oldnote,newnote,1)
open(dst,'w',encoding='utf-8').write(s)
PY
echo "run51_wrapper_patch=shipping_mobile_right_hold_x920_y1250_duration520" > qa-out-wrapper.txt
bash "$TMP"
