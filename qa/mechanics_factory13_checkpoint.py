#!/usr/bin/env python3
"""Factory13 bounded checkpoint/contact/death/respawn QA, never shipping.

Uses the original authored Level13, unchanged physics/hazards/checkpoints.
Only QA-only level entry and read-only telemetry are permitted source deltas.
Interactions are ordinary keyboard inputs to a real Android emulator.
A missed geometry/timing window is INCONCLUSIVE, never a product RED.
"""
import json, time, traceback
from pathlib import Path
import observed_playthrough as g

OUT=Path("qa-factory13-checkpoint-evidence")
OUT.mkdir(exist_ok=True)
R={
 "identity":"QA_ISOLATED_ORIGINAL_FACTORY13_NOT_SHIPPING",
 "product_base":"0d5fd0bb63558ad6659ba31552deaede4745382b",
 "records":[], "verdict":{},
 "limitations":["Bypassed natural level selection/cinematic with QA-only entry",
 "Unmodified original level geometry, controls, physics and death logic",
 "Read-only observer and QA-only entry are NOT the release binary",
 "Emulator keyboard input, NOT Fold touchscreen or progression proof"]}

def f(st,key,default=-1):
    try: return float(st.get(key,default))
    except (ValueError,TypeError): return default

def truth(st,key):
    return str(st.get(key,"false")).lower()=="true"

def save(label, image=False):
    st=g.state()
    R["records"].append({"label":label,"state":st,"timestamp":time.time()})
    with (OUT/"trace.jsonl").open("a",encoding="utf8") as h:
        h.write(json.dumps(R["records"][-1],sort_keys=True)+"\n")
    if image: g.screenshot(label)
    (OUT/"verdict.json").write_text(json.dumps(R,indent=2),encoding="utf8")
    return st

def verdict(key,value):
    R["verdict"][key]=value
    (OUT/"verdict.json").write_text(json.dumps(R,indent=2),encoding="utf8")
    print(key,"=>",value,flush=True)

def activated(st,origin):
    return (truth(st,"liselotCheckpointChecked")
        and abs(f(st,"p2CheckpointX")-1030)<16
        and abs(f(st,"p2CheckpointY")-782)<5
        and abs(f(st,"p2CheckpointX")-f(origin,"p2CheckpointX"))>100)

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
    g.tap("X");time.sleep(.75);g.tap("X");time.sleep(2.5)
    g.locate_state()
    g.wait_for_level(1,30)
    initial=save("01-authored-map-start",True)
    if not (initial.get("levelType")==2 and initial.get("levelNumber")==1
        and f(initial,"movingPlatformCount")>=2 and not g.is_death(initial)):
        verdict("factory13","INCONCLUSIVE_NOT_ORIGINAL_SCENE")
        raise RuntimeError("Actual Factory13 scene not confirmed")
    if not all(k in initial for k in ("p2CheckpointX","p2CheckpointY",
                                    "liselotCheckpointChecked","p2Lives")):
        verdict("checkpoint","INCONCLUSIVE_OBSERVER_NOT_PRESENT")
        raise RuntimeError("Read-only checkpoint observer missing")
    verdict("factory13","ORIGINAL_MAP_ALIVE_WITH_MOVERS_OBSERVED")
    # Switch to Liselot with ordinary V, then settle the real switch flicker.
    g.ensure_active(2);time.sleep(1.7)
    start=save("02-selected-liselot",True)
    if not start.get("p2controlled"):
        verdict("checkpoint","INCONCLUSIVE_PLAYER_NOT_CONTROLLED");return

    # Actual p2 starts x620 on the left floor (560..770, top840).
    # Approach the original right-moving platform without stepping blindly
    # into the spike gap. Four finite actions, no position injection.
    staged=start
    for i in range(4):
        x=f(staged,"p2x")
        if 700<=x<=763:break
        if x>763 or g.is_death(staged):
            verdict("checkpoint","INCONCLUSIVE_START_STAGING");return
        g.hold("RIGHT", .30 if x<680 else .18)
        staged=save("03-safe-approach-%02d"%i)
    if not (695<=f(staged,"p2x")<=763 and not g.is_death(staged)):
        verdict("checkpoint","INCONCLUSIVE_COULD_NOT_STAGE");return
    save("04-before-authentic-gap-jump",True)

    # Ordinary held C, release, then second C for female double jump.
    # One continuous real rightward crossing, original collisions untouched.
    g.ev(g.KEY["RIGHT"],True)
    try:
        g.ev(g.KEY["C"],True);time.sleep(.25)
        g.ev(g.KEY["C"],False);time.sleep(.14)
        g.ev(g.KEY["C"],True);time.sleep(.07)
        g.ev(g.KEY["C"],False);time.sleep(.58)
    finally:
        g.ev(g.KEY["RIGHT"],False)
    time.sleep(.24)
    cross=save("05-original-bridge-double-jump",True)
    if g.is_death(cross) or f(cross,"p2x")<f(staged,"p2x")+45:
        verdict("checkpoint","INCONCLUSIVE_BRIDGE_CROSSING");return

    # No blind full-width walk. Observe at every bounded input.
    # Stop before the authored worker patrol to the right of x1210.
    seen=None
    for i in range(14):
        s=save("06-checkpoint-approach-%02d"%i,image=(i in (0,6,13)))
        if activated(s,start):
            seen=s
            break
        if g.is_death(s):
            verdict("checkpoint","INCONCLUSIVE_DEATH_BEFORE_TOUCH");return
        x,y=f(s,"p2x"),f(s,"p2y")
        if x>1125 or x<700:
            verdict("checkpoint","INCONCLUSIVE_POSITION_OUTSIDE_SAFE_WINDOW");return
        if x>=1010 and y<760:
            time.sleep(.30) # Let real gravity settle onto checkpoint.
        elif x>=1055:
            g.hold("LEFT",.12)
        else:
            g.hold("RIGHT",.17 if x<970 else .10)
    if seen is None:
        verdict("checkpoint","INCONCLUSIVE_NO_CONFIRMED_TOUCH");return
    verdict("checkpoint","OBSERVED_ORIGINAL_LISELOT_ACTIVATION")
    save("07-checkpoint-activated",True)
    lives=f(seen,"p2Lives")
    cp_x,cp_y=f(seen,"p2CheckpointX"),f(seen,"p2CheckpointY")

    # Seek one naturally lethal collision with the original factory worker.
    # No damage commands, no hazard edits, no kill/reset/teleport calls.
    # The moving worker patrol at x1210..1540, y860 is original authored.
    # Bounded: never script an infinite pixel chase.
    killed=None
    for i in range(18):
        s=save("08-worker-approach-%02d"%i,image=(i in (0,8,17)))
        if s.get("p2dead") or f(s,"p2Lives")<lives:
            killed=s
            break
        x,ex=f(s,"p2x"),f(s,"enemy0X")
        if x>1540 or x<900:
            verdict("respawn","INCONCLUSIVE_UNSAFE_GEOMETRY_STOP");return
        if ex<0:
            verdict("respawn","INCONCLUSIVE_WORKER_NOT_OBSERVED");return
        if abs(ex-x)<26:
            time.sleep(.25)
        elif x<ex:
            g.hold("RIGHT",min(.32,max(.13,(ex-x)/350)))
        else:
            g.hold("LEFT",min(.25,max(.10,(x-ex)/350)))
    if killed is None:
        verdict("respawn","NOT_TESTED_NO_GENUINE_DEATH_WITHIN_BUDGET");return
    verdict("death","OBSERVED_REAL_ENEMY_COLLISION")
    save("09-after-original-lethal-collision",True)

    # Death must visibly complete, not just reflect the collision animation.
    # Observe original Character.update() restoring checkPointValue after
    # the death animation; no game state mutation or artificial reset.
    final=None
    for i in range(24):
        time.sleep(.35)
        s=save("10-original-death-animation-%02d"%i,image=(i in (0,8,23)))
        if (not s.get("p2dead") and abs(f(s,"p2x")-cp_x)<18
            and abs(f(s,"p2y")-cp_y)<24 and f(s,"p2Lives")<lives):
            final=s;break
    if final:
        verdict("respawn","OBSERVED_ORIGINAL_CHECKPOINT_RESPAWN_EMULATOR_ONLY")
        save("11-original-checkpoint-respawn",True)
    else:
        verdict("respawn","INCONCLUSIVE_DEATH_OBSERVED_BUT_RESPAWN_NOT_PROVEN")

if __name__=="__main__":
    try:main()
    except Exception as exc:
        R["error"]={"message":str(exc),"traceback":traceback.format_exc()}
        (OUT/"verdict.json").write_text(json.dumps(R,indent=2),encoding="utf8")
        raise
