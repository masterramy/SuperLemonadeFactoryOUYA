#!/usr/bin/env python3
"""Bounded, ordinary-input mechanic smoke test — not a perfect-level solver.

Checks a representative chapter-1 stage using the same QA-only read-only
observer APK, then records what *actually* happened. Does not edit saves,
teleport, call completion hooks, or change game physics.
"""
import json
import time
from pathlib import Path
import observed_playthrough as g

OUT=Path("mechanics-evidence")
OUT.mkdir(exist_ok=True)
result={"suite":"representative-mechanics-v1","chapter":"Warehouse","level":1,
        "checks":{},"scope":"ordinary-input observational smoke",
        "not_claimed":["level_completion","level_unlock","whole_campaign"]}

def check(name, observed, before=None, after=None, note=""):
    result["checks"][name]={"observed":bool(observed),"before":before,
                            "after":after,"note":note}
    (OUT/"mechanics-results.json").write_text(json.dumps(result,indent=2),encoding="utf-8")
    if not observed:
        raise RuntimeError(f"Mechanic not demonstrated: {name}, before={before}, after={after}. {note}")

def still_alive(d):
    if g.is_death(d):
        raise RuntimeError(f"Unexpected death during simple controls smoke: {d}")
    if d.get("levelNumber")!=1:
        raise RuntimeError(f"Unexpected level during simple controls smoke: {d}")
    return d

def screenshot(tag):
    # Binary PNG capture: never request the text-decoded subprocess wrapper.
    import subprocess
    p=subprocess.run(["adb","exec-out","screencap","-p"],capture_output=True)
    if p.returncode==0 and p.stdout:
        (OUT/(tag+".png")).write_bytes(p.stdout)

def watch():
    return still_alive(g.state())

def main():
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
    time.sleep(9)
    g.navigate_to_level_select()
    screenshot("01-level-select")
    # Level 1 is the opening tutorial; no swipes or progression manipulation.
    # Rendered 1920x1080 Level Select: Level 1 is the LEFT purple
    # button at approximately x560,y392. Prior center tap missed it.
    g.shell("input tap 560 392")
    time.sleep(5)
    def frame():
        import subprocess
        from screen_navigation import classify_screen
        p=subprocess.run(["adb","exec-out","screencap","-p"],capture_output=True)
        if p.returncode or not p.stdout:
            raise RuntimeError("No startup frame")
        return classify_screen(p.stdout)
    from screen_navigation import retry_level_select_transition
    label=retry_level_select_transition(
        frame,
        lambda:g.shell("input tap 560 392"),
        lambda:time.sleep(4), attempts=3)
    if label=="cutscene":
        from screen_navigation import advance_cutscene_to_gameplay
        advance_cutscene_to_gameplay(frame,lambda:g.shell("input tap 960 540"),
                                    lambda:time.sleep(2),attempts=8)
    elif label!="gameplay":
        raise RuntimeError(f"Expected gameplay or cutscene after Level 1 select, got {label}")
    g.locate_state()
    d=still_alive(g.wait_for_level(1))
    screenshot("02-level1-initial")
    check("chapter1_level_entry",d["levelNumber"]==1,
          after=d["levelNumber"],note="Actual fresh game, Level 1 via UI")

    # Test Andre's ordinary movement, not an exact coordinate/pixel.
    g.ensure_active(1)
    start=watch()
    g.hold("RIGHT",.22)
    moved=watch()
    check("andre_movement",float(moved["p1x"])-float(start["p1x"])>8,
          before=round(start["p1x"],1),after=round(moved["p1x"],1))
    # Capture a real midair state immediately after a held C jump.
    ground=watch()
    g.ev(g.KEY["C"],True)
    time.sleep(.21)
    g.ev(g.KEY["C"],False)
    time.sleep(.06)
    air=watch()
    check("andre_jump",float(air["p1y"])<float(ground["p1y"])-8,
          before=round(ground["p1y"],1),after=round(air["p1y"],1))
    screenshot("03-andre-after-jump")
    time.sleep(.85)

    # Switch character then prove that only Liselot responds to RIGHT.
    pre=watch()
    g.tap("V")
    selected=watch()
    check("character_switch",selected.get("p2controlled") is True
          and selected.get("p1controlled") is False,
          before={"p1":pre.get("p1controlled"),"p2":pre.get("p2controlled")},
          after={"p1":selected.get("p1controlled"),"p2":selected.get("p2controlled")})
    start=watch()
    g.hold("RIGHT",.19)
    end=watch()
    check("liselot_movement",float(end["p2x"])-float(start["p2x"])>8,
          before=round(start["p2x"],1),after=round(end["p2x"],1))
    # Ordinary midair second C press: observe her airborne position.
    base=watch()
    g.tap("C")
    time.sleep(.13)
    g.tap("C")
    time.sleep(.07)
    double=watch()
    check("liselot_airborne_double_jump_input",
          float(double["p2y"]) < float(base["p2y"])-8,
          before={"y":round(base["p2y"],1)},after={"y":round(double["p2y"],1)},
          note="Second C input made during airborne phase; confirms jump response, not precise apex.")
    screenshot("04-liselot-after-double-jump")
    time.sleep(.85)

    # Use X while Andre is moving; do not call dash proven solely
    # because an X key was sent. Record actual movement and a frame.
    g.ensure_active(1)
    before=watch()
    g.ev(g.KEY["RIGHT"],True)
    time.sleep(.04)
    g.ev(g.KEY["X"],True)
    time.sleep(.15)
    g.ev(g.KEY["X"],False)
    g.ev(g.KEY["RIGHT"],False)
    time.sleep(.12)
    after=watch()
    result["checks"]["andre_action_dash_probe"]={
        "observed":float(after["p1x"])>float(before["p1x"])+5,
        "before":round(before["p1x"],2),"after":round(after["p1x"],2),
        "note":"Real X+RIGHT action and frame. Displacement alone is not proof of crate break or dash animation."
    }
    screenshot("05-andre-action-probe")
    (OUT/"mechanics-results.json").write_text(json.dumps(result,indent=2),encoding="utf-8")
    if not result["checks"]["andre_action_dash_probe"]["observed"]:
        raise RuntimeError("Andre X+RIGHT action had no observed response; inspect screenshot")
    print(json.dumps(result,indent=2))

if __name__=="__main__":
    main()
