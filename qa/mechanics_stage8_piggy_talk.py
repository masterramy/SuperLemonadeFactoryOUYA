#!/usr/bin/env python3
"""BOUNDED QA ONLY: genuine Warehouse Level8 proximity/piggyback/talk attempt.

Only original authored map + ordinary inputs. Never move characters directly,
edit saves, change physics, unlock levels or force completion. Outcomes are
inconclusive unless observed states prove an individual mechanic.
"""
import time,json,math
from pathlib import Path
import observed_playthrough as g
OUT=Path("qa-warehouse8-piggy-talk-evidence"); OUT.mkdir(exist_ok=True)
r={"mode":"QA_ONLY_ORIGINAL_AUTHORED_STAGE8", "release_commit":"0d5fd0bb63558ad6659ba31552deaede4745382b",
   "measured":[],"conclusions":{},"limitations":["direct stage QA entry, not natural unlock","not release APK or physical device","no save or physics manipulation"]}
def shot(label):
 st=g.state();r["measured"].append({"step":label,"state":st})
 (OUT/"state-trace.jsonl").open("a",encoding="utf8").write(json.dumps({"label":label,"state":st},sort_keys=True)+"\n")
 g.screenshot(label);(OUT/"results.json").write_text(json.dumps(r,indent=2),encoding="utf8")
 return st
def sep(s):
 return math.hypot(float(s["p1x"])-float(s["p2x"]),float(s["p1y"])-float(s["p2y"]))
def main():
 g.OUT=OUT
 g.run(["adb","root"],check=False);time.sleep(2);g.run(["adb","wait-for-device"])
 g.DEV=g.find_keyboard();g.run(["adb","install","-r","runtime/dist/emulator-qa/SLF-emulator-x64.apk"])
 g.shell(f"pm clear {g.PACKAGE}");g.shell("wm size 1920x1080");g.shell("wm density 420")
 g.shell("settings put secure immersive_mode_confirmations confirmed",check=False)
 g.shell("wm user-rotation lock 1",check=False)
 g.shell("input keyevent KEYCODE_WAKEUP",check=False);g.shell("wm dismiss-keyguard",check=False)
 g.shell(f"am start -W -n {g.PACKAGE}/.AIRAppEntry");time.sleep(8)
 g.tap("X");time.sleep(.7);g.tap("X");time.sleep(2.5)
 g.locate_state();g.wait_for_level(8,30)
 st=shot("01-original-warehouse8-entry")
 if st["levelType"]!=1 or st["levelNumber"]!=8 or g.is_death(st):
  r["conclusions"]["authored_stage"]="INCONCLUSIVE_OR_WRONG";raise RuntimeError("Wrong stage or death")
 r["conclusions"]["authored_stage"]="OBSERVED_PASS_ORIGINAL_MAP"
 # One bounded honest interaction window: male moves/jumps using ONLY game keyboard input.
 if not st["p1controlled"]:g.ensure_active(1)
 g.ev(g.KEY["C"],True);time.sleep(.15);g.ev(g.KEY["C"],False)
 candidate=None
 for i in range(9):
  time.sleep(.09);st=g.state()
  if i%3==0:shot(f"02-proximity-sample-{i}")
  if g.is_death(st):break
  if sep(st)<61:
   candidate=st;break
 r["conclusions"]["proximity_observed"]="NEAR" if candidate else "INCONCLUSIVE__NO_AUTHORED_CONTACT"
 if candidate:
  shot("03-before-natural-piggy")
  g.tap("B");p=shot("04-after-ordinary-B")
  piggy=bool(p.get("p1piggy")) and bool(p.get("p2piggy"))
  r["conclusions"]["piggyback"]="OBSERVED_PASS" if piggy else "INCONCLUSIVE__ACTION_NOT_ENGAGED"
  if piggy:
   time.sleep(.3);g.tap("B");d=shot("05-after-ordinary-B-dismount")
   r["conclusions"]["dismount"]="OBSERVED_PASS" if not d.get("p1piggy") and not d.get("p2piggy") else "INCONCLUSIVE"
  else: d=p
  if sep(d)<80 and not g.is_death(d):
   g.ensure_active(2);t=shot("06-female-selected-near-andre")
   if sep(t)<80:
    g.tap("X");t=shot("07-after-ordinary-X-talk")
    r["conclusions"]["talk_to_andre"]="OBSERVED_PASS" if t.get("talkedToAndre") else "INCONCLUSIVE"
 else:
  shot("03-final-proximity-not-attained")
  r["conclusions"]["piggyback"]="INCONCLUSIVE__STAGE_GEOMETRY"
  r["conclusions"]["talk_to_andre"]="UNTESTED__STAGE_GEOMETRY"
 r["conclusions"]["game_finished"]="NO" 
 (OUT/"results.json").write_text(json.dumps(r,indent=2),encoding="utf8")
 print(json.dumps(r["conclusions"],indent=2))
 if r["conclusions"].get("piggyback")!="OBSERVED_PASS":
  raise RuntimeError("Bounded honest piggyback attempt inconclusive, no game defect proven")
if __name__=="__main__":main()
