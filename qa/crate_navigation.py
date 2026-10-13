"""Ordinary-input Level 2 movable-crate puzzle, verified by read-only state.

Source: Level2.oel explicitly requires pushing the small crate off the
left ledge. The QA player cannot edit positions, gravity, saves or physics.
Neither an issued keypress nor a character move constitutes puzzle proof.
"""

def high_double_jump_over_crate(keydown, keyup, sleep):
    """Liselot's ordinary vertical first/second jumps BEFORE moving right.

    A rightward jump from floor x690 used to physically shove the crate
    x763 into the wrong edge. Gain vertical clearance first, then translate
    over the crate. No read-state or screenshots during time-sensitive input.
    """
    held=set()
    def down(k):
        keydown(k); held.add(k)
    def up(k):
        if k in held:
            keyup(k); held.remove(k)
    try:
        down('C')
        sleep(.29)
        up('C')
        sleep(.08)
        down('C')
        sleep(.07)
        up('C')
        down('RIGHT')
        sleep(.69)
    finally:
        up('C')
        up('RIGHT')
    sleep(.23)


def reach_right_side_without_pushing(read_state, hold, high_jump, capture,
                                    max_steps=12):
    """Walk to x~690 on floor and vault ABOVE the crate without shoving it.

    It is not enough to stand right of an already-displaced crate. Require
    real crate telemetry and refuse success when ordinary input displaced
    it right more than a small tolerance.
    """
    def observed():
        d=read_state()
        if d.get('p1dead') or d.get('p2dead'):
            raise RuntimeError(f'player death in crate approach: {d}')
        if 'crateX' not in d or 'crateY' not in d:
            raise RuntimeError(f'crate observer unavailable: {d}')
        return d
    start=observed()
    original_x=float(start['crateX'])
    original_y=float(start['crateY'])
    if not (735.0<=original_x<=830.0 and 330.0<=original_y<=410.0):
        raise RuntimeError(f'crate wrong edge or unsafe initial position: {start}')
    for step in range(max_steps):
        d=observed()
        x,y=float(d['p2x']),float(d['p2y'])
        if float(d['crateX'])>original_x+20.:
            raise RuntimeError(f'crate moved right during safe approach: {d}')
        if 670.0<=x<=715.0 and y>=430.0:
            break
        if x>715.0:
            raise RuntimeError(f'crate approach got too close without clearance: {d}')
        hold('RIGHT', max(.10,min(.25,(690.0-x)/230.0)))
    else:
        raise RuntimeError(f'cannot stage Liselot left of crate: {observed()}')
    capture('crate-left-ground-stage')
    high_jump()
    d=observed()
    if float(d['crateX'])>original_x+20.0:
        raise RuntimeError(f'crate moved right during vault, not a puzzle pass: {d}')
    if float(d['p2x'])<float(d['crateX'])+32.0 or float(d['p2x'])>1010.:
        raise RuntimeError(f'Liselot not safely right of crate: {d}')
    if float(d['p2y'])>425.:
        raise RuntimeError(f'Liselot did not clear crate to upper platform: {d}')
    capture('crate-right-side-without-shoving')
    return d


def move_crate_off_left_ledge(read_state, hold, jump_right, capture, pause=None,
                              platform_left=740.0, crate_width=24.0,
                              max_actions=35):
    def observed():
        d=read_state()
        if d.get("p1dead") or d.get("p2dead"):
            raise RuntimeError(f"player death during crate puzzle: {d}")
        cx=float(d.get("crateX",-1))
        cy=float(d.get("crateY",-1))
        if not (0.0<=cx<=1500.0 and 0.0<=cy<=800.0):
            raise RuntimeError(f"movable crate unavailable or invalid: {d}")
        return d

    d=observed()
    if float(d["crateX"])+crate_width<=platform_left and float(d["crateY"])>410:
        return d
    if float(d["crateX"])>990 or float(d["crateY"])>420:
        raise RuntimeError(f"crate staging unexpected: {d}")

    # The earlier QA walked LEFT while Liselot was LEFT of the crate,
    # leaving it on the platform. Get beyond its RIGHT-hand face first.
    for attempt in range(3):
        d=observed()
        if float(d["p2x"])>=float(d["crateX"])+crate_width+7:
            break
        capture(f"crate-approach-{attempt:02d}")
        jump_right()  # authentic female jump/double-jump key events
        d=observed()
        if float(d["p2x"])>1120.0 or (float(d["p2x"])>1020.0 and float(d["p2y"])>395.0):
            raise RuntimeError(f"unsafe jump near spikes without recovery room: {d}")
        # Real run 38463869038: a legitimate double-jump went x809 to
        # x1046,y257, alive and well above the spike strip. Brake LEFT
        # immediately while airborne, before a slow screenshot or idle wait
        # lets gravity/continued RIGHT momentum carry her into the hazards.
        for correction in range(8):
            if float(d["p2x"])<=975.0:
                break
            hold("LEFT",0.14)
            d=observed()
            if float(d["p2x"])>1120.0 or (float(d["p2x"])>1020.0 and float(d["p2y"])>430.0):
                raise RuntimeError(f"airborne spike recovery unsafe: {d}")
    else:
        raise RuntimeError(f"Liselot not right of crate after ordinary jumps: {d}")

    capture("crate-right-side-established")
    for action in range(max_actions):
        d=observed()
        cx,cy=float(d["crateX"]),float(d["crateY"])
        if cx+crate_width<=platform_left and cy>410.0:
            capture("crate-fell-off-left")
            return d
        if float(d["p2x"])<690 and cx+crate_width>platform_left:
            raise RuntimeError(f"unsafe leftward crate chase: {d}")
        if cx+crate_width<=platform_left:
            # Crate has crossed the edge but is still falling; don't keep
            # blindly walking Liselot off the same ledge.
            if pause is not None:
                pause(0.22)
            else:
                hold("RIGHT",0.04)
            continue
        if float(d["p2x"])<cx-5.0:
            raise RuntimeError(f"Liselot got behind crate on wrong side: {d}")
        hold("LEFT",0.14)
        if action in (0,3,7,12,20,28):
            capture(f"crate-left-push-{action:02d}")
    raise RuntimeError(f"crate not off left ledge or not fallen after bounded actions: {observed()}")
