#!/usr/bin/env python3
"""One bounded actual-input Level32 mid-air dash acceptance probe.

QA ONLY, never ship. Uses original authored Management Level32 and a
read-only observer, not a level unlock or real-device release proof.
No character repositioning, physics edits, save edits or forced wins.
"""
import json
import time
from pathlib import Path
import observed_playthrough as g

OUT = Path("qa-management32-airdash-evidence")
OUT.mkdir(exist_ok=True)
report = {
    "identity": "QA_ONLY_ORIGINAL_MANAGEMENT_LEVEL32__NOT_SHIPPING",
    "release_base": "0d5fd0bb63558ad6659ba31552deaede4745382b",
    "observations": [],
    "conclusions": {},
    "limits": ["QA-only scene entry", "read-only game observer",
               "not natural chapter unlock", "not exact release APK",
               "not real Fold hardware or touchscreen parity"]
}

def record(label, capture=True):
    st = g.state()
    report["observations"].append({"label": label, "state": st})
    with (OUT / "state-trace.jsonl").open("a", encoding="utf8") as f:
        f.write(json.dumps({"label": label, "state": st}, sort_keys=True) + "\n")
    if capture:
        g.screenshot(label)
    (OUT / "results.json").write_text(json.dumps(report, indent=2), encoding="utf8")
    return st

def main():
    g.OUT = OUT
    g.run(["adb", "root"], check=False)
    time.sleep(2)
    g.run(["adb", "wait-for-device"])
    g.DEV = g.find_keyboard()
    (OUT / "keyboard-device.txt").write_text(g.DEV + "\n")
    g.run(["adb", "install", "-r", "runtime/dist/emulator-qa/SLF-emulator-x64.apk"])
    g.shell(f"pm clear {g.PACKAGE}")
    g.shell("wm size 1920x1080")
    g.shell("wm density 420")
    g.shell("settings put secure immersive_mode_confirmations confirmed", check=False)
    g.shell("wm user-rotation lock 1", check=False)
    g.shell("input keyevent KEYCODE_WAKEUP", check=False)
    g.shell("wm dismiss-keyguard", check=False)
    g.shell(f"am start -W -n {g.PACKAGE}/.AIRAppEntry")
    time.sleep(8)
    g.tap("X")
    time.sleep(.7)
    g.tap("X")
    time.sleep(2.5)
    g.locate_state()
    g.wait_for_level(8, 30)
    initial = record("01-authored-management32-entry")
    if initial.get("levelType") != 3 or initial.get("levelNumber") != 8:
        report["conclusions"]["stage"] = "INCONCLUSIVE_WRONG_STAGE"
        raise RuntimeError("Did not observe original Management Level32")
    report["conclusions"]["stage"] = "OBSERVED_ORIGINAL_STAGE32"
    if g.is_death(initial):
        report["conclusions"]["airdash"] = "INCONCLUSIVE_START_DEAD"
        raise RuntimeError("Stage32 started with dead actor; not game RED")
    if not initial["p1controlled"]:
        g.ensure_active(1)
    initial = record("02-andre-before-jump")

    # Ordinary gameplay C jump from untouched authored start, no horizontal
    # navigation/pixel chasing. Leave C pressed long enough for a real frame.
    g.ev(g.KEY["C"], True)
    time.sleep(.11)
    g.ev(g.KEY["C"], False)
    time.sleep(.04)
    # Do NOT screenshot before the X input: screenshot latency can let
    # the short original jump land and falsely invalidate an air-dash.
    airborne = record("03-after-real-C-jump", capture=False)
    is_airborne = (float(airborne["p1y"]) < float(initial["p1y"]) - 4
                   and float(airborne["p1vy"]) < 0
                   and not g.is_death(airborne))
    report["conclusions"]["jump"] = "OBSERVED_AIRBORNE" if is_airborne else "INCONCLUSIVE"
    if not is_airborne:
        report["conclusions"]["airdash"] = "NOT_TESTED_NO_CONFIRMED_AIRBORNE_STATE"
        raise RuntimeError("Ordinary jump not observed airborne; QA inconclusive, not product RED")

    # One SHORT mid-air X press. Read velocity before release while dash
    # is actually held: source PlayerMale.update assigns +/-500 x velocity.
    # Do not continue toward first spike at authored x290.
    g.ev(g.KEY["X"], True)
    time.sleep(.075)
    during = g.state()
    g.ev(g.KEY["X"], False)
    report["observations"].append({"label": "04-during-held-X", "state": during})
    with (OUT / "state-trace.jsonl").open("a", encoding="utf8") as f:
        f.write(json.dumps({"label": "04-during-held-X", "state": during},
                           sort_keys=True) + "\n")
    g.screenshot("04-after-short-real-X")
    after = record("05-dash-released")

    dash_velocity = abs(float(during.get("p1vx", 0)))
    baseline_velocity = abs(float(airborne.get("p1vx", 0)))
    displacement = abs(float(during.get("p1x", 0)) - float(airborne["p1x"]))
    really_airborne_at_dash = float(during["p1y"]) < float(initial["p1y"]) - 3
    # PlayerMale.update sets +/-500 on X, but FlxObject.postUpdate
    # clamps read-only final velocity to Character.maxVelocity.x=210.
    # Compare against normal baseline, not unreachable 500 telemetry.
    dash_pass = (really_airborne_at_dash and dash_velocity >= 180
                 and dash_velocity > baseline_velocity + 100
                 and displacement > 8 and not g.is_death(during))
    report["conclusions"]["dash_speed_during_real_X"] = dash_velocity
    report["conclusions"]["pre_dash_speed"] = baseline_velocity
    report["conclusions"]["airborne_during_X"] = really_airborne_at_dash
    report["conclusions"]["dash_displacement"] = displacement
    report["conclusions"]["airdash"] = ("OBSERVED_PASS_ISOLATED_QA_EMULATOR"
                                        if dash_pass else "INCONCLUSIVE_NOT_PRODUCT_RED")
    report["conclusions"]["game_completion"] = "NOT_TESTED"
    (OUT / "results.json").write_text(json.dumps(report, indent=2), encoding="utf8")
    print(json.dumps(report["conclusions"], indent=2))
    if not dash_pass:
        raise RuntimeError("Bounded air-dash observation inconclusive; inspect actual frames/states; not product RED")

if __name__ == "__main__":
    main()
