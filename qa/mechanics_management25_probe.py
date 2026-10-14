#!/usr/bin/env python3
"""QA ONLY original Management stage25 and moving-platform proof.

The app's original authored Level25 data/physics are unchanged. QA-only
menu hook starts stage25 (normally preceded by a story cutscene); the tester
never edits progress or grants completion. No inference about natural Factory
unlock, exact release binary, or physical touch controls.
"""
import json,time
from pathlib import Path
import observed_playthrough as g

OUT=Path("isolated-management25-evidence")
OUT.mkdir(exist_ok=True)
S={"mode":"QA_ISOLATED_AUTHORED_MANAGEMENT_STAGE25__NOT_SHIPPING_UNLOCK",
   "product_commit":"0d5fd0bb63558ad6659ba31552deaede4745382b",
   "checks":{},"limitations":["chapter story cinematic intentionally bypassed by QA-only hook",
   "no unlock/save manipulation, no teleport or forced completion",
   "not identical production binary/physical device/real level selection"]}

def snap(name):
    st=g.state()
    S["checks"][name]={"state":st}
    with (OUT/"state-trace.jsonl").open("a",encoding="utf8") as f:
        f.write(json.dumps({"label":name,"utc":time.time(),"state":st},sort_keys=True)+"\n")
    g.screenshot(name)
    (OUT/"results.json").write_text(json.dumps(S,indent=2),encoding="utf8")
    return st

def check(label,passed,details):
    S["checks"][label]={"passed":bool(passed),"details":details}
    (OUT/"results.json").write_text(json.dumps(S,indent=2),encoding="utf8")
    if not passed:raise RuntimeError(f"QA stage25 {label} inconclusive: {details}")

def main():
    g.OUT=OUT
    g.run(["adb","root"],check=False);time.sleep(2)
    g.run(["adb","wait-for-device"])
    g.DEV=g.find_keyboard()
    g.run(["adb","install","-r","runtime/dist/emulator-qa/SLF-emulator-x64.apk"])
    g.shell(f"pm clear {g.PACKAGE}")
    g.shell("wm size 1920x1080")
    g.shell("wm density 420")
    g.shell("settings put secure immersive_mode_confirmations confirmed",check=False)
    g.shell("settings put system accelerometer_rotation 0",check=False)
    g.shell("settings put system user_rotation 1",check=False)
    g.shell("wm user-rotation lock 1",check=False)
    g.shell("input keyevent KEYCODE_WAKEUP",check=False)
    g.shell("wm dismiss-keyguard",check=False)
    g.shell(f"am start -W -n {g.PACKAGE}/.AIRAppEntry")
    time.sleep(8)
    g.tap("X");time.sleep(.75);g.tap("X");time.sleep(3)
    g.locate_state()
    g.wait_for_level(1,30)
    start=snap("01-original-management25-entry")
    check("correct_authored_management_chapter",start.get("levelType")==3
      and start.get("levelNumber")==1 and start.get("exitX",-1)>0
      and not g.is_death(start),{"levelType":start.get("levelType"),
          "levelNumber":start.get("levelNumber"),"exitX":start.get("exitX")})
    check("authored_platforms_present",int(start.get("movingPlatformCount",0))>=1,
      {"count":start.get("movingPlatformCount"),
       "platformX":start.get("movingPlatformX"),
       "platformY":start.get("movingPlatformY")})
    p0=float(start["movingPlatformY"])
    time.sleep(.85)
    later=snap("02-natural-moving-platform-after-850ms")
    check("platform_really_moves_in_runtime",
      abs(float(later.get("movingPlatformY",-1))-p0)>4,
      {"before":p0,"after":later.get("movingPlatformY"),
       "delta":float(later.get("movingPlatformY",-1))-p0})
    if not later.get("p1controlled"):g.ensure_active(1)
    before=snap("03-before-input-walk")
    g.hold("LEFT",.16)
    after=snap("04-real-factory-walk")
    check("real_factory_character_movement",after["p1x"]<before["p1x"]-6
      and not g.is_death(after),
      {"before":before["p1x"],"after":after["p1x"],
       "dead":after["p1dead"]})
    check("no_forced_completion",not after.get("levelFinished")
      and not after.get("levelOverMenu"),{"finished":after.get("levelFinished"),
       "levelOverMenu":after.get("levelOverMenu")})
    print(json.dumps({"passed":[k for k,v in S["checks"].items() if v.get("passed")],
        "limits":S["limitations"]},indent=2))

if __name__=="__main__":main()
