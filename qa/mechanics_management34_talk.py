#!/usr/bin/env python3
"""Observe real conversation with a naturally patrolling character.

Only original authored Management Level34; ordinary V switch and X action,
read-only state observation, original map and enemy AI unchanged. Stop if
proximity is never naturally achieved. QA direct level entry never qualifies
natural chapter unlock, shipped APK or mobile touch.
"""
import json,time,traceback
from pathlib import Path
import observed_playthrough as g
OUT=Path("qa-management34-dialogue-evidence");OUT.mkdir(exist_ok=True)
R={"identity":"QA_ONLY_ORIGINAL_MANAGEMENT34_UNMODIFIED_INTERACTION",
   "product":"0d5fd0bb63558ad6659ba31552deaede4745382b",
   "results":{}, "records":[], "boundaries":[
    "QA-only scene entry bypasses authentic level-select and storyline",
    "source changes limited to QA menu hook and readonly observation",
    "no forced speech, enemy relocation, player teleport, or save changes",
    "not production release binary, Fold screen, or normal chapter progression"]}
def f(d,k):
    try:return float(d.get(k,-1))
    except:return -1
def yes(d,k):return str(d.get(k,"false")).lower()=="true"
def rec(tag,image=False):
    d=g.state()
    R["records"].append({"label":tag,"state":d,"timestamp":time.time()})
    with (OUT/"trace.jsonl").open("a",encoding="utf8") as h:
        h.write(json.dumps(R["records"][-1],sort_keys=True)+"\n")
    if image:g.screenshot(tag)
    (OUT/"results.json").write_text(json.dumps(R,indent=2))
    return d
def verdict(key,value):
    R["results"][key]=value
    (OUT/"results.json").write_text(json.dumps(R,indent=2))
    print(key,"=>",value,flush=True)
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
    g.locate_state();g.wait_for_level(10,30)
    start=rec("01-original-management34",True)
    if not (start.get("levelType")==3 and start.get("levelNumber")==10
            and 0<=f(start,"p2x")<=25 and abs(f(start,"p2y")-509.11)<20
            and not g.is_death(start)
            and "hasTalkedToEnemy" in start
            and not yes(start,"hasTalkedToEnemy")):
        verdict("talk","INCONCLUSIVE_WRONG_STAGE_OR_OBSERVER");return
    verdict("stage","ORIGINAL_MANAGEMENT34_STARTED")
    g.ensure_active(2);time.sleep(1.75)
    selected=rec("02-female-selected-normal-V",True)
    if not selected.get("p2controlled") or g.is_death(selected):
        verdict("talk","INCONCLUSIVE_SWITCH_OR_DEATH");return
    # Original author places Liselot at (10,500) and Chef at (50,500)
    # patrolling normally toward (560,500). Observe up to one patrol
    # cycle instead of chasing input/timing pixels.
    approach=None
    for i in range(30):
        d=rec("03-wait-for-natural-chef-proximity-%02d"%i,image=(i in (0,15,29)))
        if yes(d,"hasTalkedToEnemy"):
            verdict("talk","INCONCLUSIVE_UNEXPECTED_PRIOR_TALK");return
        if g.is_death(d):
            verdict("talk","INCONCLUSIVE_DEAD_BEFORE_TALK");return
        dx=f(d,"enemy0X")-f(d,"p2x")
        dy=f(d,"enemy0Y")-f(d,"p2y")
        if dx>=0 and abs(dx)<70 and abs(dy)<30:
            approach=d
            break
        time.sleep(.43)
    if approach is None:
        verdict("talk","INCONCLUSIVE_PATROL_NEVER_NEAR_ENOUGH");return
    rec("04-real-nearby-chef-before-X",True)
    g.tap("X")
    time.sleep(.13)
    result=rec("05-after-ordinary-real-X",True)
    if yes(result,"hasTalkedToEnemy") and not g.is_death(result):
        verdict("talk","OBSERVED_AUTHENTIC_CHEF_CONVERSATION_QA_EMULATOR")
    else:
        verdict("talk","INCONCLUSIVE_NO_GAME_CONVERSATION_FLAG")
    verdict("piggyback","NOT_TESTED_CHARACTERS_NOT_TOUCHING")
    verdict("save","NOT_TESTED_NO_LEVEL_COMPLETION")
if __name__=="__main__":
    try:
        main()
        if R["results"].get("talk")!="OBSERVED_AUTHENTIC_CHEF_CONVERSATION_QA_EMULATOR":
            raise RuntimeError("Real authored dialogue not yet observed; inconclusive, NOT product RED")
    except Exception as e:
        R["error"]={"type":type(e).__name__,"message":str(e),"traceback":traceback.format_exc()}
        (OUT/"results.json").write_text(json.dumps(R,indent=2))
        raise
