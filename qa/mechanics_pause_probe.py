#!/usr/bin/env python3
"""QA-only original-map pause/resume/input-freeze probe with native P control.
Never edits saves, unlocks, positions, map, physics, or completion.
Uses the already source-verified Rev52-derived QA-only APK from CI38489944996.
"""
from pathlib import Path
import json,time
import observed_playthrough as g

OUT=Path("isolated-pause-evidence")
OUT.mkdir(exist_ok=True)
E={"mode":"ISOLATED_QA_NOT_EXACT_SHIPPING","source":"Rev52 original Warehouse Level1",
   "checks":{},"limits":["NOT natural level completion","NOT actual Play delivery",
      "NOT exact unchanged shipping APK","NOT Fold physical proof"]}

def save(label):
    d=g.state()
    with (OUT/"state-trace.jsonl").open("a",encoding="utf8") as f:
        f.write(json.dumps({"name":label,"time":time.time(),"state":d},sort_keys=True)+"\n")
    E["checks"][label]={"state":d}
    (OUT/"pause-results.json").write_text(json.dumps(E,indent=2),encoding="utf8")
    g.screenshot(label)
    return d

def observed(name,ok,details):
    E["checks"][name]={"pass":bool(ok),"details":details}
    (OUT/"pause-results.json").write_text(json.dumps(E,indent=2),encoding="utf8")
    if not ok: raise RuntimeError(f"QA pause evidence inconclusive at {name}: {details}")

def await_paused(want,seconds=3):
    until=time.time()+seconds
    last=None
    while time.time()<until:
        last=g.state()
        if last.get("paused") is want:
            return last
        time.sleep(.25)
    return last

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
    # Exact PCIntroState requires two ordinary X inputs to reach QA menu.
    g.tap("X");time.sleep(.75);g.tap("X");time.sleep(3)
    g.locate_state()
    d=g.wait_for_level(1,30)
    observed("original_scene_and_initial_unpaused", d["levelNumber"]==1
       and d.get("paused") is False and not g.is_death(d),
       {"level":d.get("levelNumber"),"paused":d.get("paused"),"p1x":d.get("p1x")})
    d=save("01-before-pause")
    g.KEY["P"]=25 # Android/Linux keyboard KEY_P; actual game FlxG.keys.justPressed("P")
    g.tap("P")
    d=await_paused(True)
    save("02-after-pause")
    observed("real_pause_event",d is not None and d.get("paused") is True,
             {"state":d})
    x=float(d["p1x"])
    g.hold("RIGHT",.19)
    d=save("03-right-input-while-paused")
    observed("paused_ignores_movement",abs(float(d["p1x"])-x)<2,
             {"before":x,"after":d["p1x"]})
    g.tap("P")
    d=await_paused(False)
    save("04-after-resume")
    observed("real_resume_event",d is not None and d.get("paused") is False,
             {"state":d})
    x=float(d["p1x"])
    g.hold("RIGHT",.22)
    d=save("05-right-input-after-resume")
    observed("resumed_movement",d["p1x"]>x+8 and not g.is_death(d),
             {"before":x,"after":d["p1x"]})
    print(json.dumps({"pass_items":[k for k,v in E["checks"].items() if v.get("pass")],
         "limits":E["limits"]},indent=2))

if __name__=="__main__":main()
