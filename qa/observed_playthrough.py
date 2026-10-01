#!/usr/bin/env python3
import subprocess, time, os, re, sys, json
from pathlib import Path

ADB=["adb"]
PACKAGE="com.ramybaheeg.slfport"
OUT=Path("playthrough-evidence")
OUT.mkdir(exist_ok=True)
STATE_PATH=None
KEY={"LEFT":105,"RIGHT":106,"UP":103,"DOWN":108,"C":46,"X":45,"V":47,"B":48}

def run(args, check=True, capture=True):
    p=subprocess.run(args,text=True,capture_output=capture)
    if check and p.returncode:
        raise RuntimeError(f"command failed {args}: {p.returncode}\n{p.stdout}\n{p.stderr}")
    return p

def shell(cmd, check=True):
    return run(["adb","shell",cmd],check=check).stdout.strip()

def screenshot(tag):
    p=subprocess.run(["adb","exec-out","screencap","-p"],capture_output=True)
    if p.returncode==0 and p.stdout:
        (OUT/f"{tag}.png").write_bytes(p.stdout)

def find_keyboard():
    text=shell("getevent -pl",check=False)
    blocks=re.split(r"(?=add device \d+:)",text)
    for block in blocks:
        m=re.search(r"(/dev/input/event\d+)",block)
        if m and all(k in block for k in ("KEY_RIGHT","KEY_LEFT","KEY_C","KEY_X","KEY_V")):
            return m.group(1)
    for n in range(8):
        dev=f"/dev/input/event{n}"
        t=shell(f"getevent -lp {dev}",check=False)
        if all(k in t for k in ("KEY_RIGHT","KEY_LEFT","KEY_C","KEY_X","KEY_V")):
            return dev
    raise RuntimeError("No keyboard event device with required keys")
DEV=None

def ev(code,down):
    shell(f"sendevent {DEV} 1 {code} {1 if down else 0}; sendevent {DEV} 0 0 0")

def tap(name):
    code=KEY[name]; ev(code,True); time.sleep(.04); ev(code,False); time.sleep(.12)

def hold(name,seconds):
    code=KEY[name]; ev(code,True); time.sleep(seconds); ev(code,False); time.sleep(.18)

def move_jump(direction, double=False, dash=False, duration=.48):
    ev(KEY[direction],True)
    time.sleep(.04)
    tap("C")
    if double:
        time.sleep(.12); tap("C")
    if dash:
        time.sleep(.05); ev(KEY["X"],True)
    time.sleep(max(.08,duration-.25))
    if dash: ev(KEY["X"],False)
    ev(KEY[direction],False)
    time.sleep(.20)

def locate_state():
    global STATE_PATH
    for _ in range(30):
        s=shell(f"find /data/user/0/{PACKAGE} /data/data/{PACKAGE} -name qa_state.txt -type f 2>/dev/null | head -1",check=False)
        if s:
            STATE_PATH=s.splitlines()[0].strip()
            return STATE_PATH
        time.sleep(.5)
    raise RuntimeError("qa_state.txt not found")

def state():
    global STATE_PATH
    if not STATE_PATH: locate_state()
    txt=shell(f"cat {STATE_PATH}",check=False)
    d={}
    for line in txt.splitlines():
        if "=" not in line: continue
        k,v=line.split("=",1); d[k]=v
    for k in ("p1x","p1y","p1vx","p1vy","p2x","p2y","p2vx","p2vy","exitX","exitY"):
        if k in d:
            try:d[k]=float(d[k])
            except:pass
    for k in ("levelType","levelNumber","playersNo"):
        if k in d:
            try:d[k]=int(d[k])
            except:pass
    for k in ("p1controlled","p2controlled","p1dead","p2dead","p1piggy","p2piggy","levelFinished","levelOverMenu","paused","hardCore"):
        if k in d:d[k]=str(d[k]).lower()=="true"
    return d

def log_state(tag):
    d=state()
    with (OUT/"state-trace.jsonl").open("a",encoding="utf-8") as f:
        f.write(json.dumps({"tag":tag,"t":time.time(),"state":d},sort_keys=True)+"\n")
    return d

def wait_for_level(level, timeout=25):
    end=time.time()+timeout
    last={}
    while time.time()<end:
        try:last=state()
        except: time.sleep(.5); continue
        if last.get("levelNumber")==level and last.get("exitX",-1)>=0:
            return last
        time.sleep(.5)
    screenshot(f"wait-level-{level}-timeout")
    raise RuntimeError(f"Did not reach level {level}; last={last}")

def active_player(d):
    if d.get("p1controlled"): return 1
    if d.get("p2controlled"): return 2
    return 0

def ensure_active(which):
    for _ in range(5):
        d=state()
        if active_player(d)==which:return d
        if d.get("p1piggy") or d.get("p2piggy"):
            tap("B"); time.sleep(.4)
        tap("V"); time.sleep(.5)
    raise RuntimeError(f"Could not select player {which}: {state()}")

def advance_player(which, target_x, max_steps=60):
    ensure_active(which)
    lastx=None; stuck=0
    for step in range(max_steps):
        d=state()
        if d.get("levelFinished"): return d
        x=d[f"p{which}x"]; y=d[f"p{which}y"]
        if abs(target_x-x) < 38:
            return d
        direction="RIGHT" if target_x>x else "LEFT"
        if lastx is not None and abs(x-lastx)<3: stuck+=1
        else: stuck=0
        lastx=x
        if which==2:
            move_jump(direction,double=True,dash=False,duration=.46 if stuck<3 else .65)
        else:
            move_jump(direction,double=False,dash=True,duration=.42 if stuck<3 else .62)
        if stuck in (3,6):
            # break a bad collision cycle without changing state artificially
            opposite="LEFT" if direction=="RIGHT" else "RIGHT"
            hold(opposite,.28)
            tap("C")
        if stuck in (8,12):
            tap("UP"); hold(direction,.55)
        if step%8==0:
            log_state(f"p{which}-step-{step:02d}")
            screenshot(f"p{which}-step-{step:02d}")
    return state()

def settle_exit(max_rounds=30):
    for r in range(max_rounds):
        d=state()
        if d.get("levelFinished"): return True
        ex=d.get("exitX",-1)
        if ex<0:return False
        # Move the farther character first, then the nearer one.
        dist1=abs(d["p1x"]-ex); dist2=abs(d["p2x"]-ex)
        which=1 if dist1>=dist2 else 2
        ensure_active(which)
        x=d[f"p{which}x"]
        direction="RIGHT" if ex>x else "LEFT"
        if which==2: move_jump(direction,double=True,duration=.32)
        else: move_jump(direction,dash=True,duration=.32)
        if r%4==0:
            screenshot(f"exit-settle-{r:02d}")
            log_state(f"exit-settle-{r:02d}")
        time.sleep(.3)
    return bool(state().get("levelFinished"))

def solve_level2():
    d=wait_for_level(2)
    ex=d["exitX"]
    log_state("level2-start"); screenshot("level2-start")

    # Source-grounded crate setup: Liselot starts near the small crate. Get to
    # its right side, then push it left off the ledge using ordinary input.
    ensure_active(2)
    advance_player(2, 825, max_steps=30)
    screenshot("level2-liselot-right-of-crate"); log_state("level2-liselot-right-of-crate")
    hold("LEFT",1.45)
    time.sleep(.7)
    screenshot("level2-crate-push"); log_state("level2-crate-push")

    # Move Liselot to the exit with her real double-jump controls.
    advance_player(2, ex+8, max_steps=55)
    screenshot("level2-liselot-at-exit"); log_state("level2-liselot-at-exit")

    # Bring Andre through the route with normal jump+dash controls.
    ensure_active(1)
    advance_player(1, ex+4, max_steps=75)
    screenshot("level2-andre-at-exit"); log_state("level2-andre-at-exit")

    ok=settle_exit(36)
    screenshot("level2-final")
    d=log_state("level2-final")
    (OUT/"level2-result.json").write_text(json.dumps({"completion":ok,"state":d},indent=2),encoding="utf-8")
    if not ok:
        raise RuntimeError(f"Level 2 not completed: {d}")
    return d

def main():
    global DEV
    apk="runtime/SLF-emulator-x64.apk"
    run(["adb","root"],check=False); time.sleep(2); run(["adb","wait-for-device"])
    DEV=find_keyboard()
    (OUT/"keyboard-device.txt").write_text(DEV+"\n",encoding="utf-8")
    run(["adb","install","-r",apk])
    shell(f"pm clear {PACKAGE}")
    shell("wm size 1920x1080")
    shell("wm density 420")
    shell("settings put secure immersive_mode_confirmations confirmed",check=False)
    shell("settings put system accelerometer_rotation 0",check=False)
    shell("settings put system user_rotation 1",check=False)
    shell("wm user-rotation lock 1",check=False)
    shell("input keyevent KEYCODE_WAKEUP",check=False)
    shell("wm dismiss-keyguard",check=False)
    shell(f"am start -W -n {PACKAGE}/.AIRAppEntry")
    time.sleep(9)
    screenshot("00-title")
    # One Android tap uses the shipping mobile intro path.
    shell("input tap 960 540"); time.sleep(5)
    screenshot("01-main-menu")
    shell("input tap 960 540"); time.sleep(5)
    screenshot("02-level-select")
    # Fresh level select: Level 1 selected. Select Level 2 with a real swipe.
    shell("input swipe 700 540 1250 540 250"); time.sleep(1)
    shell("input tap 960 540"); time.sleep(9)
    locate_state()
    wait_for_level(2)
    solve_level2()
    # Use ordinary Next Level action. This must naturally transition to Level 3.
    time.sleep(5)
    shell("input keyevent KEYCODE_X"); time.sleep(10)
    d=wait_for_level(3,30)
    screenshot("50-natural-level3")
    log_state("natural-level3")
    (OUT/"result.txt").write_text(
        "ordinary_shipping_inputs_only=true\n"
        "save_or_game_state_edit=false\n"
        "teleport=false\n"
        "forced_completion=false\n"
        "qa_observation_mutates_game_state=false\n"
        "level2_natural_completion=true\n"
        "level3_natural_transition=true\n"
        f"final_state={json.dumps(d,sort_keys=True)}\n",
        encoding="utf-8")
    print((OUT/"result.txt").read_text())

if __name__=="__main__":
    main()
