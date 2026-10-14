#!/usr/bin/env python3
"""QA-only isolated SCENE proof: real gameplay mechanics from original Level1.

The QA build intercepts the title/menu and enters the unmodified authored
Warehouse Level1. It does not award unlocks, edit saves, teleport characters,
alter physical mechanics, or force any end-level state. This is NOT evidence
that the actual shipping UI/progression works. Release still requires the
normal, unmodified shipping app journey and persisted unlock.
"""
import json
import time
from pathlib import Path
import observed_playthrough as g

OUT=Path("isolated-scene-evidence")
OUT.mkdir(exist_ok=True)
E={"mode":"QA_ISOLATED_SCENE__NOT_SHIPPING_PROGRESS_PROOF",
   "stage":"original_warehouse_level1",
   "mechanics":{},
   "scope_limits":["no original UI navigation","no natural level completion",
       "no genuine save/unlock proof","no physical device","not exact shipping binary"]}

def record(label,state=None):
    d=state if state is not None else g.state()
    E["mechanics"][label]={"state":d}
    (OUT/"state-trace.jsonl").open("a",encoding="utf8").write(
        json.dumps({"label":label,"state":d,"t":time.time()},sort_keys=True)+"\n")
    g.screenshot(label)
    (OUT/"results.json").write_text(json.dumps(E,indent=2),encoding="utf8")
    return d

def check(name,pass_value,detail):
    E["mechanics"][name]={"pass":bool(pass_value),"detail":detail}
    (OUT/"results.json").write_text(json.dumps(E,indent=2),encoding="utf8")
    if not pass_value:
        raise RuntimeError(f"QA isolated scene: {name} not demonstrated. {detail}")

def live():
    d=g.state()
    if g.is_death(d): raise RuntimeError(f"unexpected death: {d}")
    if d.get("levelNumber")!=1: raise RuntimeError(f"wrong stage: {d}")
    return d

def main():
    g.OUT=OUT
    g.run(["adb","root"],check=False)
    time.sleep(2)
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
    # PCIntroState.as (exact Rev52) counts two ordinary Action presses to
    # enter PCMenuState. That menu has the QA-only direct scene entry.
    # This deliberately avoids title/cinematic vision/tap classifiers.
    g.screenshot("00-intro-before-two-normal-action-inputs")
    g.tap("X")
    time.sleep(.75)
    g.tap("X")
    time.sleep(3)
    g.screenshot("00-after-normal-intro-actions")
    g.locate_state()
    d=g.wait_for_level(1,30)
    record("01-original-level1-loaded",d)
    check("direct_scene_actual_playstate",d.get("levelNumber")==1
          and d.get("exitX",-1)>0 and not g.is_death(d),
          {"level":d.get("levelNumber"),"exit":d.get("exitX")})
    if not d.get("p1controlled"):
        g.ensure_active(1)
    start=live()
    g.hold("RIGHT",.25)
    moved=live()
    record("02-andre-walk-right",moved)
    check("andre_real_move",moved["p1x"]>start["p1x"]+8,
          {"before":start["p1x"],"after":moved["p1x"]})
    ground=live()
    g.ev(g.KEY["C"],True)
    time.sleep(.22)
    mid=live()
    g.ev(g.KEY["C"],False)
    time.sleep(.12)
    record("03-andre-airborne",mid)
    check("andre_real_jump",mid["p1y"]<ground["p1y"]-8,
          {"before":ground["p1y"],"midair":mid["p1y"]})
    time.sleep(.8)
    g.ensure_active(2)
    switch=record("04-liselot-selected")
    check("switch_controls_liselot",switch.get("p2controlled") is True,
          {"p1":switch.get("p1controlled"),"p2":switch.get("p2controlled")})
    start2=live()
    g.hold("RIGHT",.23)
    end2=record("05-liselot-walk-right")
    check("liselot_real_move",end2["p2x"]>start2["p2x"]+8,
          {"before":start2["p2x"],"after":end2["p2x"]})
    g.ev(g.KEY["C"],True)
    time.sleep(.13)
    first=live()
    g.ev(g.KEY["C"],False)
    time.sleep(.11)
    # Capture the airborne second press independently. Do NOT call a mere
    # positive displacement proof of actual double-jump impulse.
    before_second=live()
    g.tap("C")
    after_second=record("06-liselot-second-jump-input")
    E["mechanics"]["double_jump_specific_impulse"]={
        "pass":None,"evidence":"two ordinary C inputs while airborne; distinct second impulse needs direct vy/trajectory adjudication",
        "before_vy":before_second.get("p2vy"),"after_vy":after_second.get("p2vy"),
        "before_y":before_second.get("p2y"),"after_y":after_second.get("p2y")}
    (OUT/"results.json").write_text(json.dumps(E,indent=2),encoding="utf8")
    print(json.dumps({"completed_checks":list(E["mechanics"].keys()),
                      "still_unproven":E["scope_limits"]},indent=2))

if __name__=="__main__":
    main()
