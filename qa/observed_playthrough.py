#!/usr/bin/env python3
import subprocess, time, os, re, sys, json, shlex
from pathlib import Path
from progress_guard import is_genuine_completion, is_death
from ledge_navigation import sustained_jump_right, apex_first_jump_right, clear_tall_ledge, crate_jump_right
from hazard_navigation import cross_spike_and_worker_corridor, align_exit_from_right
from guard_navigation import airborne_dash_past_guard
from crate_navigation import move_crate_off_left_ledge, reach_right_side_without_pushing, high_double_jump_over_crate
from screen_navigation import classify_screen, system_dialog_target, retry_level_select_transition, advance_cutscene_to_gameplay

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

def dismiss_system_ui(max_attempts=4):
    """Dismiss only explicitly recognized Android system dialogs (e.g. ANR Wait).

    Never blindly tap game pixels while a system dialog is obscuring gameplay.
    A dialog may appear several seconds after emulator startup.
    """
    xml_file=OUT/"system-window.xml"
    for attempt in range(max_attempts):
        try:
            result=subprocess.run(
                ["adb","shell","uiautomator","dump","/sdcard/gate2a-window.xml"],
                text=True,capture_output=True,timeout=15)
            if result.returncode:
                return
            result=subprocess.run(
                ["adb","pull","/sdcard/gate2a-window.xml",str(xml_file)],
                text=True,capture_output=True,timeout=15)
            if result.returncode or not xml_file.exists():
                return
        except subprocess.TimeoutExpired:
            return
        target=system_dialog_target(xml_file.read_text(errors="replace"))
        if target is None:
            return
        shell(f"input tap {target[0]} {target[1]}",check=False)
        (OUT/"system-dismissals.txt").open("a",encoding="utf-8").write(
            f"dialog_attempt={attempt} tapped={target}\\n")
        time.sleep(2.0)


def navigate_to_level_select():
    """Observe actual rendered UI before each navigation action.

    Fixes Pixel Launcher ANR swallowing the first tap and corrupting all
    subsequent level selection assumptions. Unknown state is NOT a pass.
    """
    for attempt in range(8):
        dismiss_system_ui()
        p=subprocess.run(["adb","exec-out","screencap","-p"],capture_output=True)
        if p.returncode or not p.stdout:
            raise RuntimeError("Cannot capture startup UI")
        label=classify_screen(p.stdout)
        (OUT/f"bootstrap-{attempt:02d}-{label}.png").write_bytes(p.stdout)
        (OUT/"bootstrap-classifications.txt").open("a",encoding="utf-8").write(
            f"attempt={attempt} classification={label}\\n")
        if label=="level_select":
            return
        if label=="unknown":
            time.sleep(2.0)
            continue
        # One normal touchscreen action advances title -> menu -> level select.
        shell("input tap 960 540"); time.sleep(5.0)
    raise RuntimeError("Could not reach visually confirmed Level Select; inspect bootstrap screenshots")


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
    # Fail with evidence, not with the false conclusion that Level 2 was
    # never reached. An emulator screenshot may already prove gameplay.
    probes=[
        ("identity", "id; getprop ro.build.type"),
        ("package", "pm path com.ramybaheeg.slfport; dumpsys package com.ramybaheeg.slfport | grep -E 'dataDir=|userId=|DEBUGGABLE' | head -12"),
        ("private-roots", "ls -lad /data/user/0/com.ramybaheeg.slfport /data/data/com.ramybaheeg.slfport /data/user/0/com.ramybaheeg.slfport/files /data/user/0/com.ramybaheeg.slfport/files/SUPERLEMONADEFACTORY 2>&1"),
        ("external-roots", "ls -lad /sdcard/Android/data/com.ramybaheeg.slfport /storage/emulated/0/Android/data/com.ramybaheeg.slfport 2>&1"),
        ("all-candidate-files", "find /data/user/0/com.ramybaheeg.slfport /data/data/com.ramybaheeg.slfport /sdcard/Android/data/com.ramybaheeg.slfport -maxdepth 8 -type f \\( -name 'qa_state*' -o -name 'progress_backup.slf' \\) 2>&1 | head -80"),
    ]
    with (OUT/"observation-access-diagnostics.txt").open("w",encoding="utf-8") as h:
        for name,cmd in probes:
            p=run(["adb","shell",cmd],check=False)
            h.write(f"=== {name} ===\\n{cmd}\\nexit={p.returncode}\\n{p.stdout}\\n{p.stderr}\\n")
    screenshot("observation-missing-rendered-frame")
    raise RuntimeError("QA observation file unavailable; see observation-access-diagnostics.txt. Do not interpret this as a gameplay failure.")

def state():
    global STATE_PATH
    if not STATE_PATH: locate_state()
    result=run(["adb","shell",f"cat {shlex.quote(STATE_PATH)}"],check=False)
    txt=result.stdout
    if not txt.strip():
        diagnostic=OUT/"observation-read-failure.txt"
        if not diagnostic.exists():
            probes=[
                ("state-path", f"ls -l {shlex.quote(STATE_PATH)}; stat {shlex.quote(STATE_PATH)}; cat {shlex.quote(STATE_PATH)}"),
                ("whoami", "id; getenforce; getprop ro.build.type"),
                ("package", "pm path com.ramybaheeg.slfport; dumpsys package com.ramybaheeg.slfport | grep -E 'dataDir=|userId=|DEBUGGABLE' | head -12"),
                ("private-roots", "ls -la /data/user/0/com.ramybaheeg.slfport /data/data/com.ramybaheeg.slfport /data/user/0/com.ramybaheeg.slfport/files /data/user/0/com.ramybaheeg.slfport/files/SUPERLEMONADEFACTORY 2>&1"),
            ]
            with diagnostic.open("w",encoding="utf-8") as h:
                h.write(f"read_returncode={result.returncode}\\npath={STATE_PATH}\\nstdout={result.stdout}\\nstderr={result.stderr}\\n")
                for name,cmd in probes:
                    p=run(["adb","shell",cmd],check=False)
                    h.write(f"=== {name} ===\\n{cmd}\\nexit={p.returncode}\\n{p.stdout}\\n{p.stderr}\\n")
            screenshot("observation-read-failure-rendered-frame")
        raise RuntimeError(f"QA state read returned empty, exit={result.returncode}; inspect observation-read-failure.txt")
    d={}
    for line in txt.splitlines():
        if "=" not in line: continue
        k,v=line.split("=",1); d[k]=v
    for k in ("p1x","p1y","p1vx","p1vy","p2x","p2y","p2vx","p2vy","armyX","armyY","armyVx","crateX","crateY","exitX","exitY"):
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
        if is_death(d):
            screenshot("death-during-switch"); log_state("death-during-switch")
            raise RuntimeError(f"Player death during selection (not victory): {d}")
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
        if is_genuine_completion(d): return d
        if is_death(d):
            screenshot(f"p{which}-death-step-{step:02d}")
            log_state(f"p{which}-death-step-{step:02d}")
            raise RuntimeError(f"Player death, not victory: {d}")
        x=d[f"p{which}x"]; y=d[f"p{which}y"]
        if abs(target_x-x) < 38:
            return d
        direction="RIGHT" if target_x>x else "LEFT"
        if lastx is not None and abs(x-lastx)<3: stuck+=1
        else: stuck=0
        lastx=x
        # On the long elevated platform at x=740..1020, jump+double-jump
        # travels too far to safely stage at x≈955 before the spike strip.
        # Use bounded ground walking for the last 200px, observing every
        # resulting state, so a single command cannot silently overrun it.
        if which==2 and target_x<=970 and 740<=x<=1015 and abs(y-359.11)<40 and abs(target_x-x)<=210:
            if x>=1000:
                screenshot("unsafe-pre-spike-overrun")
                raise RuntimeError(f"Pre-spike staging overrun: x={x} y={y}")
            hold(direction, max(.10, min(.28, abs(target_x-x)/390.0)))
            log_state(f"p2-precision-walk-{step:02d}")
            continue
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
        if is_genuine_completion(d): return True
        if is_death(d):
            screenshot(f"exit-death-{r:02d}"); log_state(f"exit-death-{r:02d}")
            raise RuntimeError(f"Death at exit, not victory: {d}")
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
    return is_genuine_completion(state())

def solve_level2():
    d=wait_for_level(2)
    ex=d["exitX"]
    log_state("level2-start"); screenshot("level2-start")

    # Level2.oel: the small crate at x763,y373 must be pushed OFF the
    # LEFT edge of the elevated x740 platform. Prior QA actually stopped
    # Liselot on the crate's LEFT and walked away; Andre then faced an
    # unreachable tall ledge. Observe the crate itself, never infer success
    # from simply issuing a LEFT command.
    ensure_active(2)
    # Ground-walk only to x690, then use legitimate VERTICAL female
    # double-jump BEFORE translating right over the x763 crate. Previous
    # generic advance_player physically shoved crate to x1092 off wrong
    # edge in real run 38473523858. Verify it stays near authored x763.
    reach_right_side_without_pushing(
        state,hold,
        lambda: high_double_jump_over_crate(
            lambda k: ev(KEY[k],True),
            lambda k: ev(KEY[k],False),
            time.sleep),
        screenshot,
        fallback_jump=lambda:move_jump("RIGHT",double=True,duration=.46))
    screenshot("level2-before-crate-puzzle"); log_state("level2-before-crate-puzzle")
    d=move_crate_off_left_ledge(
        state,hold,
        lambda: move_jump("RIGHT",double=True,duration=.30),
        screenshot,time.sleep,max_actions=40)
    screenshot("level2-crate-off-left-verified"); log_state("level2-crate-off-left-verified")

    # Move Liselot to the exit with her real double-jump controls.
    # Level 2 source map: top platform ends x=1020; spike strip 1020..1090;
    # patrolling enemy later at 1170..1290. The blind walk died near x=1244.
    # This is a distinct, map-aware ordinary-input route.
    advance_player(2, 955, max_steps=48)
    # Stage near the end of the x=740..1020 platform. The prior 0.04s
    # first-jump tap caused Liselot to land on the worker near x=1248.
    # Keep stage x <=1010 to avoid walking into the spike strip at x=1020.
    for step in range(12):
        d=state()
        if is_death(d): raise RuntimeError(f"Liselot died before corridor: {d}")
        x=float(d["p2x"])
        if 975.0<=x<=1010.0: break
        if x>1010: raise RuntimeError(f"Unsafe Liselot staging overrun: {d}")
        hold("RIGHT", .10)
        if step in (3,7): log_state(f"liselot-stage-{step:02d}")
    else:
        raise RuntimeError(f"Could not stage Liselot before spike corridor: {state()}")
    screenshot("level2-liselot-pre-spike"); log_state("level2-liselot-pre-spike")
    d=cross_spike_and_worker_corridor(
        state, lambda k: ev(KEY[k],True), lambda k: ev(KEY[k],False),
        time.sleep, screenshot)
    screenshot("level2-liselot-hazard-leap"); log_state("level2-liselot-hazard-leap")
    time.sleep(.5)
    d=state()
    if is_death(d): raise RuntimeError(f"Liselot died after corridor crossing: {d}")
    # Last successful corridor jump reached x=1380 beyond exit x=1320.
    # Do not jump backward: that landed in the worker patrol at x=1224.
    # Measure each ordinary small LEFT walk and stop only from live state.
    d=align_exit_from_right(state,hold,ex)
    screenshot("level2-liselot-at-exit"); log_state("level2-liselot-at-exit")

    # Andre starts before an armed guard on the first elevated platform.
    ensure_active(1)
    advance_player(1, 205, max_steps=9)
    screenshot("level2-andre-pre-army"); log_state("level2-andre-pre-army")
    d=airborne_dash_past_guard(
        state,
        lambda k: ev(KEY[k],True),
        lambda k: ev(KEY[k],False),
        time.sleep,
        lambda tag: (log_state(tag),screenshot(tag)))
    d=log_state("level2-andre-guarded-army-leap")
    screenshot("level2-andre-guarded-army-leap")
    # The prior 0.04-second C taps trapped Andre at world x=730 below the
    # 120px tall platform starting x=740. Stage him LEFT of that wall, hold
    # jump for the game's real 0.35-second variable-height window, and
    # accept passage only from the live QA observer's post-input position.
    advance_player(1, 690, max_steps=30)
    screenshot("level2-andre-before-tall-ledge"); log_state("level2-andre-before-tall-ledge")
    clear_tall_ledge(
        state, hold,
        # Do not take read-state screenshots in flight: the old
        # apex-first helper delayed RIGHT until after landing, repeatedly
        # returning Andre to x706 instead of the observed fallen crate.
        # Use genuine sustained RIGHT+C without interruption, then observe.
        lambda: sustained_jump_right(
            lambda k: ev(KEY[k], True),
            lambda k: ev(KEY[k], False),
            time.sleep),
        screenshot,
        crate_jump=lambda: crate_jump_right(
            lambda k: ev(KEY[k], True),
            lambda k: ev(KEY[k], False),
            time.sleep))
    screenshot("level2-andre-over-tall-ledge"); log_state("level2-andre-over-tall-ledge")
    advance_player(1, 965, max_steps=18)
    screenshot("level2-andre-pre-spike"); log_state("level2-andre-pre-spike")
    move_jump("RIGHT", dash=True, duration=.80)
    d=log_state("level2-andre-hazard-leap")
    screenshot("level2-andre-hazard-leap")
    if is_death(d): raise RuntimeError(f"Andre hazard leap death: {d}")
    advance_player(1, ex+4, max_steps=16)
    screenshot("level2-andre-at-exit"); log_state("level2-andre-at-exit")

    ok=settle_exit(36)
    screenshot("level2-final")
    d=log_state("level2-final")
    (OUT/"level2-result.json").write_text(json.dumps({"completion":ok,"state":d},indent=2),encoding="utf-8")
    if not ok or not is_genuine_completion(d):
        raise RuntimeError(f"Level 2 not genuinely completed: {d}")
    return d

def main():
    global DEV
    apk="runtime/dist/emulator-qa/SLF-emulator-x64.apk"
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
    # Emulator system UI can display a Pixel Launcher ANR dialog at startup.
    # Do not assume initial touches reached the game. Classify each frame and
    # dismiss only Android-system buttons such as "Wait" before moving on.
    navigate_to_level_select()
    screenshot("02-level-select-confirmed")
    # Fresh level select: Level 1 selected. Select Level 2 with a real swipe.
    shell("input swipe 700 540 1250 540 250"); time.sleep(1)
    count=[0]
    def level2_launch_screen():
        # Late Pixel Launcher ANR dialogs may obscure a genuine Level Select
        # transition. Only dismiss recognized Android system UI, never
        # blindly act on unknown game frames.
        dismiss_system_ui()
        p=subprocess.run(["adb","exec-out","screencap","-p"],capture_output=True)
        if p.returncode or not p.stdout:
            raise RuntimeError("Cannot observe Level 2 transition")
        label=classify_screen(p.stdout)
        (OUT/f"level2-launch-view-{count[0]:02d}-{label}.png").write_bytes(p.stdout)
        count[0]+=1
        return label
    scene=retry_level_select_transition(
        level2_launch_screen,
        lambda: shell("input tap 960 540"),
        lambda: time.sleep(7),
        attempts=4)
    if scene=='cutscene':
        scene=advance_cutscene_to_gameplay(
            level2_launch_screen,
            lambda: shell("input tap 960 540"),
            lambda: time.sleep(2),
            attempts=8)
    if scene!='gameplay':
        raise RuntimeError(f"Level 2 gameplay not visually established: {scene}")
    # Genuine gameplay still requires the read-only runtime observer below.
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
