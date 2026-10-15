#!/usr/bin/env python3
"""Original Factory World2 global level21: real-input talk and piggyback.
No map, checkpoint, physics, character position, enemy or save mutations.
QA direct-stage entry + read-only observation: never shipping/unlock proof.
One finite input attempt; absent proximity is harness INCONCLUSIVE.
"""
import time,json,traceback
from pathlib import Path
import observed_playthrough as g
OUT=Path("qa-factory21-contact-evidence");OUT.mkdir(exist_ok=True)
R={"baseline":"exact Rev52 0d5fd0bb63558ad6659ba31552deaede4745382b",
   "scope":"QA original Factory global Level21, read-only observer and ordinary inputs",
   "results":{},"records":[],"prohibitions":["no teleports","no fake speech","no forced piggyback","no save edits","no forced win"]}
def f(d,k):
 try:return float(d.get(k,-1))
 except:return -1
def yes(d,k):return str(d.get(k,"false")).lower()=="true"
def snap(label,pic=False):
 d=g.state()
 R["records"].append({"label":label,"state":d,"time":time.time()})
 with (OUT/"trace.jsonl").open("a") as w:w.write(json.dumps(R["records"][-1],sort_keys=True)+"\n")
 if pic:g.screenshot(label)
 (OUT/"result.json").write_text(json.dumps(R,indent=2))
 return d
def status(k,v):
 R["results"][k]=v
 (OUT/"result.json").write_text(json.dumps(R,indent=2))
 print(k,"=>",v,flush=True)
def advance(which,target,label):
 g.ensure_active(which)
 time.sleep(.24)
 for i in range(10):
  s=snap(label+"-"+str(i), i==0 or i==9)
  if g.is_death(s):return None
  x=f(s,"p1x" if which==1 else "p2x")
  if abs(x-target)<(14 if which==2 else 22):return s
  if x>target+60 or x<0:return None
  # Real original walk speed; bounded, no injected velocity/position
  g.hold("RIGHT" if x<target else "LEFT",min(.33,max(.09,abs(x-target)/220)))
 return None
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
 g.tap("X");time.sleep(.75);g.tap("X");time.sleep(2.5)
 g.locate_state();g.wait_for_level(9,30)
 first=snap("01-real-Factory21-start",True)
 if not(first.get("levelType")==2 and first.get("levelNumber")==9
    and 0<=f(first,"p1x")<90 and 0<=f(first,"p2x")<110
    and not yes(first,"hasTalkedToAndre") and not yes(first,"p1piggy")
    and not g.is_death(first)):
  status("scene","INCONCLUSIVE_INCORRECT_STAGE");return
 status("scene","OBSERVED_ORIGINAL_FACTORY21")
 # Original solid floor at y590; Andre starts (20,540). Moving him to
 # x250-290 stays below the authored upper platforms and inside left wall.
 andre=advance(1,270,"02-andre-authentic-right")
 if andre is None:
  status("contact","INCONCLUSIVE_ANDRE_UNABLE_TO_REACH_ORIGINAL_FLOOR");return
 # Liselot starts (50,420) on upper solid at y470 (ends x250);
 # moving to x~280 walks her naturally over the ledge onto the same floor.
 # Do not fall, reset, teleport, fake collision, or move any platform.
 lis=advance(2,277,"03-liselot-authentic-right-off-ledge")
 if lis is None:
  status("contact","INCONCLUSIVE_LISELOT_UNABLE_TO_DROP_TO_LOWER_FLOOR");return
 for i in range(10):
  lis=snap("04-original-gravity-after-ledge-"+str(i),i in (0,9))
  if g.is_death(lis):
   status("contact","INCONCLUSIVE_ORIGINAL_HAZARD_DEATH");return
  if abs(f(lis,"p2y")-f(lis,"p1y"))<37:break
  time.sleep(.22)
 dx=abs(f(lis,"p1x")-f(lis,"p2x"))
 dy=abs(f(lis,"p1y")-f(lis,"p2y"))
 snap("05-before-authentic-interactions",True)
 if dx>58 or dy>38 or not yes(lis,"p2controlled"):
  status("contact",f"INCONCLUSIVE_PROXIMITY_dx{dx:.1f}_dy{dy:.1f}");return
 status("contact","OBSERVED_BOTH_ORIGINAL_CHARACTERS_IN_RANGE")
 g.tap("X");time.sleep(.20)
 talked=snap("06-female-action-X-real-talk",True)
 if yes(talked,"hasTalkedToAndre"):
  status("talk","OBSERVED_REAL_ORIGINAL_ANDRE_CONVERSATION")
 else:
  status("talk","INCONCLUSIVE_ORIGINAL_TALK_FLAG_NOT_SET")
 g.tap("B");time.sleep(.20)
 pig=snap("07-original-piggyback-key-B",True)
 if yes(pig,"p1piggy") and yes(pig,"p2piggy"):
  status("piggyback","OBSERVED_REAL_ORIGINAL_PIGGYBACK")
 else:
  status("piggyback","INCONCLUSIVE_NO_PIGGYBACK_FLAG")
 if yes(pig,"p1piggy") and yes(pig,"p2piggy"):
  g.tap("B");time.sleep(.20)
  again=snap("08-original-B-dismount",True)
  status("dismount","OBSERVED" if not yes(again,"p1piggy") and not yes(again,"p2piggy") else "INCONCLUSIVE")
 status("progression","NOT_TESTED_QA_STAGE_ENTRY_DOES_NOT_PROVE_REAL_UNLOCK")
if __name__=="__main__":
 try:
  main()
  if not(R["results"].get("talk")=="OBSERVED_REAL_ORIGINAL_ANDRE_CONVERSATION" and
        R["results"].get("piggyback")=="OBSERVED_REAL_ORIGINAL_PIGGYBACK"):
   raise RuntimeError("Original talk/piggyback not both proven; QA INCONCLUSIVE not game defect")
 except Exception as e:
  R["error"]={"type":type(e).__name__,"message":str(e),"traceback":traceback.format_exc()}
  (OUT/"result.json").write_text(json.dumps(R,indent=2))
  raise
