#!/usr/bin/env python3
"""QA-only, observation-driven ordinary-control player.

Never modifies saves, sets entity positions, invokes completion routines or
patches the shipping binary. QA build exposes READ-ONLY position telemetry.
Successful routes must later be replayed on the unchanged shipping candidate.
"""
import argparse
import json
import os
import re
import subprocess
import time
import xml.etree.ElementTree as ET
from pathlib import Path

PKG = "com.ramybaheeg.slfport"
PROBE = "qa-natural-route.txt"
EVENT = "/dev/input/event1"
OUT = Path("natural-playthrough")
OUT.mkdir(exist_ok=True)

def adb(*args, check=True):
    return subprocess.run(["adb", *map(str, args)], stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT, text=True,
                          check=check).stdout.strip()

def snap(name):
    p=OUT / (name+".png")
    with p.open("wb") as f:
        r=subprocess.run(["adb","exec-out","screencap","-p"],stdout=f)
    if r.returncode or p.stat().st_size < 1000:
        raise RuntimeError("Unable to capture screenshot: "+name)
    return str(p)

def level_data(number):
    path=Path(f"data/SLF_levelEditor/PC/level{number}.oel")
    root=ET.parse(path).getroot()
    def rows(tag):
        parent=root.find(tag)
        return [{"kind":e.tag, **{k:(float(v) if k in
                 ("x","y","w","h","width","height") else v)
                 for k,v in e.attrib.items()}} for e in parent] if parent is not None else []
    chars=rows("characters")
    exits=[x for x in rows("objects") if x["kind"]=="exit"]
    if not exits or not any(x["kind"]=="player" for x in chars):
        raise RuntimeError("No player/exit in "+str(path))
    return {"level":number,"width":int(root.findtext("width","0")),
            "height":int(root.findtext("height","0")),
            "solids":rows("solids"),"extra":rows("extraPlatforms"),
            "objects":rows("objects"),"characters":chars,
            "exit":exits[0]}

def btn(code,down):
    flag="1" if down else "0"
    adb("shell",f"sendevent {EVENT} 1 {code} {flag}; sendevent {EVENT} 0 0 0")

def pulse(key, duration=0.32):
    codes={"right":106,"left":105,"jump":46,"action":45}
    btn(codes[key],True)
    try:time.sleep(duration)
    finally:btn(codes[key],False)
    time.sleep(0.25)

def walk_jump(direction,duration=0.42,double=False):
    h=106 if direction=="right" else 105
    btn(h,True)
    try:
        time.sleep(0.04)
        btn(46,True)
        time.sleep(0.14)
        btn(46,False)
        if double:
            time.sleep(0.13)
            btn(46,True)
            time.sleep(0.09)
            btn(46,False)
        time.sleep(max(0.05,duration-(0.27 if double else 0.18)))
    finally:
        btn(46,False);btn(h,False)
    time.sleep(0.27)

def probe_path():
    for _ in range(20):
        result=adb("shell",f"find /data/data/{PKG} /data/user/0/{PKG} -name {PROBE} 2>/dev/null | head -1",
                   check=False).strip()
        if result:return result.splitlines()[0]
        time.sleep(1)
    raise RuntimeError("Read-only telemetry not found in QA build")

def telemetry(path):
    value=adb("shell",f"cat '{path}'",check=False)
    if "level=" not in value:raise RuntimeError("No QA state returned: "+value[:300])
    d={}
    for cell in value.split(","):
        if "=" in cell:
            k,v=cell.split("=",1);d[k.strip()]=v.strip()
    for field in ("p1x","p1y","p2x","p2y","level","world"):
        d[field]=int(d[field])
    return d

def choose_action(state,mapdata,stall):
    goal=mapdata["exit"]["x"]
    x1,x2=state["p1x"],state["p2x"]
    if state["p1dead"]=="true" or state["p2dead"]=="true":
        return ("dead",None,None)
    if min(x1,x2)>=goal-50:
        return ("align","right",0.15)
    # Advance the character furthest behind but handle 80px ledges by
    # using Liselot's double-jump and the source-authored crate helper.
    target="p1" if x1+80<x2 else "p2" if x2+80<x1 else ("p1" if stall%2 else "p2")
    x=state[target+"x"]; y=state[target+"y"]
    ahead=[]
    for obstacle in mapdata["solids"]+mapdata["extra"]:
        ox=obstacle.get("x",-999)
        if x-10 <= ox <= x+125:
            kind=obstacle["kind"]
            if kind=="rect" and obstacle.get("y",999) <= y+20 and ox+obstacle.get("w",0)>x:
                ahead.append(obstacle)
            if kind.lower().startswith("spike") or kind.endswith("specialBlock"):
                ahead.append(obstacle)
    spike=any(z["kind"].lower().startswith("spike") for z in ahead)
    ledge=any(z["kind"]=="rect" and z.get("y",999)<y-10 for z in ahead)
    crate=any(z["kind"].endswith("specialBlock") for z in ahead)
    if spike or ledge or crate or stall>=2:
        return (target,"jump",{"double":target=="p2" or stall>=3,"duration":0.45})
    return (target,"right",0.38)

def game_boot(apk):
    (OUT/"install.txt").write_text(adb("install","-r",apk))
    adb("shell","pm clear "+PKG)
    adb("shell","wm size 1920x1080")
    adb("shell","wm density 420")
    adb("shell","settings put secure immersive_mode_confirmations confirmed",check=False)
    adb("shell","settings put system accelerometer_rotation 0",check=False)
    adb("shell","settings put system user_rotation 1",check=False)
    adb("shell","wm user-rotation lock 1",check=False)
    adb("shell","am start -W -n "+PKG+"/.AIRAppEntry")
    time.sleep(9)
    snap("00-title")
    adb("shell","input tap 960 540");time.sleep(5)
    snap("01-menu")
    adb("shell","input tap 960 540");time.sleep(5)
    snap("02-level-select")
    adb("shell","input swipe 700 540 1250 540 250");time.sleep(2)
    snap("03-level2-selected")
    adb("shell","input tap 960 540");time.sleep(9)
    snap("04-level2-entered")

def run(apk,max_steps):
    adb("root",check=False);time.sleep(2)
    info=adb("shell",f"getevent -lp {EVENT}",check=False)
    if any(k not in info for k in ("KEY_C","KEY_RIGHT","KEY_LEFT","KEY_V")):
        raise RuntimeError("Expected ordinary keyboard control event device absent")
    game_boot(apk)
    probe=probe_path()
    log=(OUT/"decisions.jsonl").open("w")
    progress=(OUT/"progression.json").open("w")
    try:
        old=None;stall=0;completed=[]
        for step in range(max_steps):
            state=telemetry(probe)
            if state["finished"]=="true" or state["completionUI"]=="true":
                current=(state["world"]-1)*12+state["level"]
                completed.append(current)
                snap(f"complete-{current:02d}")
                # Ordinary Next Level input only, never state editing.
                adb("shell","input keyevent KEYCODE_X");time.sleep(7)
                state2=telemetry(probe)
                if (state2["world"],state2["level"])==(state["world"],state["level"]):
                    raise RuntimeError("Completion screen did not advance through normal control")
                log.write(json.dumps({"step":step,"event":"natural-level-completion",
                   "level":current,"next":state2})+"\n");log.flush()
                old=None;stall=0
                if state2["world"]>=3 and state2["level"]>=12:
                    break
                continue
            number=(state["world"]-1)*12+state["level"]
            mp=level_data(number)
            state_key=(state["p1x"],state["p1y"],state["p2x"],state["p2y"])
            if old is not None and abs(state_key[0]-old[0])+abs(state_key[2]-old[2])<10:
                stall+=1
            else:stall=0
            actor,action,settings=choose_action(state,mp,stall)
            evidence={"step":step,"stage":number,"state":state,"stall":stall,
                      "actor":actor,"action":action,"settings":settings}
            log.write(json.dumps(evidence)+"\n");log.flush()
            if step%5==0 or stall>=4:
                snap(f"route-{step:03d}")
            if actor=="dead":
                break
            active="p1" if state["p1active"]=="true" else "p2"
            if actor in ("p1","p2") and actor!=active:
                adb("shell","input keyevent KEYCODE_V");time.sleep(0.65)
            if action=="jump":
                walk_jump("right",settings["duration"],settings["double"])
            elif action=="right":
                pulse("right",settings)
            elif action=="left":
                pulse("left",settings)
            if stall>8:
                snap(f"stalled-{step:03d}")
                # Try a new source-grounded route by first retreating from
                # the failed obstacle; never replay an identical input loop.
                pulse("left",0.7)
                stall=0
            old=state_key
        final=telemetry(probe)
        snap("final")
        json.dump({"observed_completions":completed,"last_state":final,
                   "max_steps":max_steps,
                   "cheat_or_forced_completion":False,
                   "remaining": "UNPROVEN if not naturally completed"},
                  progress,indent=2)
    finally:
        log.close();progress.close()
    return 0

if __name__=="__main__":
    a=argparse.ArgumentParser()
    a.add_argument("--apk")
    a.add_argument("--steps",type=int,default=70)
    a.add_argument("--map-only",action="store_true")
    args=a.parse_args()
    if args.map_only:
        all_levels=[level_data(n) for n in range(1,37)]
        (OUT/"source-map-manifest.json").write_text(json.dumps(all_levels,indent=2))
        print("Mapped",len(all_levels),"real authored levels")
    else:
        if not args.apk:raise SystemExit("--apk required")
        raise SystemExit(run(args.apk,args.steps))
