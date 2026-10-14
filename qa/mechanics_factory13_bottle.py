#!/usr/bin/env python3
"""One bounded ordinary-input original Factory13 bottle pickup acceptance.
Only exact Rev52-authored game data, source-guarded QA scene entry, and
read-only pickup telemetry; never edit bottle, save state or level progress.
"""
import json,time,traceback
from pathlib import Path
import observed_playthrough as g
OUT=Path("qa-factory13-bottle-evidence");OUT.mkdir(exist_ok=True)
R={"identity":"QA_ONLY_ORIGINAL_FACTORY13_BOTTLE", "base":"0d5fd0bb63558ad6659ba31552deaede4745382b",
   "records":[],"verdict":{}, "limits":["QA direct original authored scene, no natural unlock",
   "no bottle or save manipulation", "not exact released binary or Fold touch",
   "bottle pickup is NOT bottle persistence after real level completion"]}
def f(st,key):
    try:return float(st.get(key,-1))
    except:return -1
def yes(st,key):return str(st.get(key,"false")).lower()=="true"
def rec(label,image=False):
    s=g.state();R["records"].append({"label":label,"state":s,"ts":time.time()})
    with (OUT/"trace.jsonl").open("a") as h:h.write(json.dumps(R["records"][-1],sort_keys=True)+"\n")
    if image:g.screenshot(label)
    (OUT/"verdict.json").write_text(json.dumps(R,indent=2))
    return s
def mark(k,v):
    R["verdict"][k]=v
    (OUT/"verdict.json").write_text(json.dumps(R,indent=2))
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
    g.tap("X");time.sleep(.75);g.tap("X");time.sleep(2.5)
    g.locate_state();g.wait_for_level(1,30)
    start=rec("01-original-bottle-and-both-actors",True)
    if not (start.get("levelType")==2 and start.get("levelNumber")==1
      and abs(f(start,"bottleX")-884)<5 and abs(f(start,"bottleY")-726)<5
      and not yes(start,"hasCollectedCap") and yes(start,"bottleAlive")
      and not g.is_death(start)):
        mark("pickup","INCONCLUSIVE_ORIGINAL_BOTTLE_NOT_PRESENT");return
    mark("map","ORIGINAL_BOTTLE_ALIVE_AT_884_726")
    g.ensure_active(2);time.sleep(1.7)
    staged=rec("02-selected-liselot",True)
    # Exactly the already-successful ordinary movement/jump route from
    # CI38650036449; one bounded attempt, NOT a frame or pixel bot.
    for i in range(4):
        x=f(staged,"p2x")
        if 700<=x<=815:break
        if x>815 or g.is_death(staged):
            mark("pickup","INCONCLUSIVE_STAGE_GEOMETRY");return
        g.hold("RIGHT",.30 if x<680 else .18)
        staged=rec("03-authentic-route-%02d"%i,image=True)
    if f(staged,"p2x")<690:
        mark("pickup","INCONCLUSIVE_UNREACHED_STAGE");return
    g.ev(g.KEY["RIGHT"],True)
    try:
        g.ev(g.KEY["C"],True);time.sleep(.25)
        g.ev(g.KEY["C"],False);time.sleep(.14)
        g.ev(g.KEY["C"],True);time.sleep(.07)
        g.ev(g.KEY["C"],False);time.sleep(.58)
    finally:
        g.ev(g.KEY["RIGHT"],False)
    time.sleep(.30)
    after=rec("04-after-legitimate-bottle-approach",True)
    if yes(after,"hasCollectedCap") and not yes(after,"bottleAlive"):
        mark("pickup","OBSERVED_REAL_SOFTDRINK_PICKUP_ISOLATED_ANDROID_QA")
    else:
        mark("pickup","INCONCLUSIVE_BOTTLE_NOT_OBSERVED_COLLECTED")
    mark("persistence","NOT_TESTED_NO_AUTHENTIC_LEVEL_COMPLETION")
if __name__=="__main__":
    try:
        main()
        if R["verdict"].get("pickup")!="OBSERVED_REAL_SOFTDRINK_PICKUP_ISOLATED_ANDROID_QA":
            raise RuntimeError("Authentic bottle pickup not observed; not a game RED")
    except Exception as e:
        R["error"]={"type":type(e).__name__,"message":str(e),"traceback":traceback.format_exc()}
        (OUT/"verdict.json").write_text(json.dumps(R,indent=2))
        raise
