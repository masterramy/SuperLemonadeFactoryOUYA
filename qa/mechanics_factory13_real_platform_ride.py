#!/usr/bin/env python3
"""Bounded original Factory13 moving-platform RIDER test.
Only ordinary RIGHT input to mount a genuine original moving platform and
then RELEASE ALL INPUT. A moving platform alone does not establish carrying.
QA source: read-only state observer and nonshipping direct original scene
entry, no edits to gameplay physics/maps/saves/player positions.
"""
import time,json,traceback
from pathlib import Path
import observed_playthrough as g
OUT=Path("qa-factory13-real-platform-ride");OUT.mkdir(exist_ok=True)
R={"identity":"QA_ISOLATED_ORIGINAL_FACTORY13_NOT_SHIPPING",
"base":"0d5fd0bb63558ad6659ba31552deaede4745382b",
"results":{},"records":[],"limitations":["Only one finite genuine platform boarding attempt","No original level select/progression claim","No source or runtime mutation of platform or character coordinates"]}
def val(st,k):
 try:return float(st.get(k,-1))
 except:return -1
def yes(st,k):return str(st.get(k,"false")).lower()=="true"
def snap(k,pic=False):
 s=g.state()
 R["records"].append({"label":k,"state":s,"time":time.time()})
 with (OUT/"trace.jsonl").open("a") as h:h.write(json.dumps(R["records"][-1],sort_keys=True)+"\n")
 if pic:g.screenshot(k)
 (OUT/"result.json").write_text(json.dumps(R,indent=2))
 return s
def verdict(k,v):
 R["results"][k]=v
 (OUT/"result.json").write_text(json.dumps(R,indent=2))
 print(k,"=>",v,flush=True)
def main():
 g.OUT=OUT
 g.run(["adb","root"],check=False);time.sleep(2);g.run(["adb","wait-for-device"])
 g.DEV=g.find_keyboard()
 g.run(["adb","install","-r","runtime/dist/emulator-qa/SLF-emulator-x64.apk"])
 g.shell(f"pm clear {g.PACKAGE}")
 g.shell("wm size 1920x1080");g.shell("wm density 420")
 g.shell("settings put secure immersive_mode_confirmations confirmed",check=False)
 g.shell("settings put system accelerometer_rotation 0",check=False)
 g.shell("settings put system user_rotation 1",check=False)
 g.shell("wm user-rotation lock 1",check=False)
 g.shell("input keyevent KEYCODE_WAKEUP",check=False)
 g.shell("wm dismiss-keyguard",check=False)
 g.shell(f"am start -W -n {g.PACKAGE}/.AIRAppEntry");time.sleep(8)
 g.tap("X");time.sleep(.7);g.tap("X");time.sleep(2.4)
 g.locate_state();g.wait_for_level(1,30)
 start=snap("01-original-factory13",True)
 if not(start.get("levelType")==2 and start.get("levelNumber")==1
   and int(start.get("movingPlatformCount",0))>=2
   and not g.is_death(start)):
  verdict("scene","INCONCLUSIVE_ORIGINAL_SCENE_NOT_CONFIRMED");return
 verdict("scene","OBSERVED_ORIGINAL_FACTORY13_2_MOVERS")
 g.ensure_active(2);time.sleep(.7)
 # The original Liselot start x620 on solid floor x560..770 top840.
 # Stage near x743 only, safely on the actual starting solid floor.
 state=snap("02-female-selected",True)
 for i in range(11):
  x=val(state,"p2x")
  if 732<=x<=758:break
  if g.is_death(state) or x>800:
   verdict("board","INCONCLUSIVE_REAL_HAZARD_OR_OUT_OF_RANGE");return
  if x>758:
   # First CI38697063685: .29 sec overshot x686.13->771.69 alive
   # before boarding. Ordinary reverse a small amount onto the solid;
   # do NOT teleport, reset, or edit collision. Stop if correction fails.
   g.hold("LEFT",.08)
  else:
   g.hold("RIGHT",min(.18,max(.045,(738-x)/330)))
  state=snap("03-authentic-normal-input-on-solid-"+str(i))
 if not(726<=val(state,"p2x")<=765 and not g.is_death(state)):
  verdict("board","INCONCLUSIVE_NOT_NEAR_AUTHORED_EDGE");return
 # Original second 40px-wide moving platform moves between x770..980
 # (read-only telemetry). Wait for its natural return toward its left end.
 # At most 12 seconds. Never edit path, collision or game time.
 moving_before=None
 last=None
 for i in range(28):
  s=snap("04-wait-original-platform-return-"+str(i),pic=i in (0,27))
  x=val(s,"movingPlatform2X")
  if last is not None and 768<=x<=789 and x>last+1:
   moving_before=s;break
  last=x
  time.sleep(.34)
 if moving_before is None:
  verdict("board","INCONCLUSIVE_NO_SAFE_BOARDING_WINDOW");return
 snap("05-before-authentic-platform-boarding",True)
 # One finite real RIGHT keypress to walk off x~743 solid edge and step
 # onto a platform whose actual original sprite is x770..x810.
 g.hold("RIGHT",.15)
 entered=snap("06-after-normal-input-release",True)
 if g.is_death(entered):
  verdict("board","INCONCLUSIVE_REAL_HAZARD_DEATH");return
 player0=val(entered,"p2x");moving0=val(entered,"movingPlatform2X");y0=val(entered,"p2y")
 # NO input in the following window. A correlated spontaneous translation
 # is direct evidence of actual rider contact/carry.
 time.sleep(.67)
 after=snap("07-no-key-held-original-platform-motion",True)
 dp=val(after,"p2x")-player0;dm=val(after,"movingPlatform2X")-moving0;dy=val(after,"p2y")-y0
 R["motion"]={"player_delta_x":round(dp,2),"platform_delta_x":round(dm,2),"player_delta_y":round(dy,2),
"before_player_x":player0,"after_player_x":val(after,"p2x"),
"before_platform_x":moving0,"after_platform_x":val(after,"movingPlatform2X")}
 if(g.is_death(after) or abs(dy)>12):
  verdict("ride","INCONCLUSIVE_POSITION_OR_HAZARD");return
 if abs(dp)>=7 and abs(dm)>=7 and dp*dm>0 and abs(dp-dm)<=13:
  verdict("ride","OBSERVED_ORIGINAL_PLATFORM_CARRY_WITH_ALL_INPUT_RELEASED")
 else:
  verdict("ride","INCONCLUSIVE_NO_CORRELATED_IDLE_RIDER_MOTION")
if __name__=="__main__":
 try:
  main()
  if R["results"].get("ride")!="OBSERVED_ORIGINAL_PLATFORM_CARRY_WITH_ALL_INPUT_RELEASED":
   raise RuntimeError("Ride not observed within one finite genuine original-map attempt; QA INCONCLUSIVE not product defect")
 except Exception as e:
  R["error"]={"kind":type(e).__name__,"message":str(e),"traceback":traceback.format_exc()}
  (OUT/"result.json").write_text(json.dumps(R,indent=2))
  raise
