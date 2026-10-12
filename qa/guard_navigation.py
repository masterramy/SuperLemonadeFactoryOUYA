"""Source-informed guard traversal using actual player button inputs and read-only state.

The previous 0.04s jump + simultaneous dash landed Andre in the first guard
patrol around x382. This controller gains altitude before horizontal air-dash.
It never edits position, health, save data, collisions, enemies, or game time.
"""

def airborne_dash_past_guard(read_state, keydown, keyup, sleep, capture, grounded_retries=1):
    d=read_state()
    if d.get('p1dead') or d.get('p2dead'):
        raise RuntimeError(f'guard death before movement: {d}')
    x=float(d['p1x'])
    if not (175.0 <= x <= 235.0):
        raise ValueError(f'unsafe guard staging at x={x}; expect x~205')

    held=set()
    def down(k):
        keydown(k); held.add(k)
    def up(k):
        if k in held:
            keyup(k); held.remove(k)
    try:
        down('C')
        sleep(0.34)
        up('C')
        mid=read_state()
        if mid.get('p1dead') or mid.get('p2dead'):
            raise RuntimeError(f'guard death at airborne apex: {mid}')
        capture('guard-apex-before-dash')

        down('RIGHT')
        # PlayerMale uses _facing, which updates in Character.move() once
        # per game frame. Do not press X in the same frame as RIGHT: prior
        # staging may have left Andre facing left, producing a LEFT dash.
        sleep(0.07)
        down('X')
        sleep(0.50)
        up('X')
        capture('guard-after-dash')
        mid=read_state()
        if mid.get('p1dead') or mid.get('p2dead'):
            raise RuntimeError(f'guard death after air dash: {mid}')
        sleep(0.30)
        out=read_state()
        if out.get('p1dead') or out.get('p2dead'):
            raise RuntimeError(f'guard death while exiting patrol: {out}')
        if float(out['p1x']) < 510.0:
            # A genuinely observed run sometimes finishes the first ordinary
            # air-dash safely on the ground at x~210 instead of advancing.
            # One *different* short grounded approach changes the takeoff
            # point; re-observe before a second ordinary jump/dash. Never
            # edit positions or silently label this a successful crossing.
            x, y = float(out['p1x']), float(out['p1y'])
            if grounded_retries>0 and 190.0<=x<=230.0 and 460.0<=y<=495.0:
                up('RIGHT')
                down('RIGHT')
                sleep(0.12)
                up('RIGHT')
                sleep(0.16)
                advanced=read_state()
                capture('guard-ground-reapproach')
                if advanced.get('p1dead') or advanced.get('p2dead'):
                    raise RuntimeError(f'death during grounded reapproach: {advanced}')
                nx,ny=float(advanced['p1x']),float(advanced['p1y'])
                if not (x+5.0 <= nx <= 235.0 and 455.0<=ny<=495.0):
                    raise RuntimeError(f'ground reapproach not safely observed: before={out} after={advanced}')
                return airborne_dash_past_guard(
                    read_state,keydown,keyup,sleep,capture,
                    grounded_retries=grounded_retries-1)
            # Level2.oel's ordinary route has a helper block at x220,y480
            # before the guard ledge at x260,y440. The original dash can
            # legitimately land on this lower block: observed (250,439).
            # That is a safe STEP, not a defeated guard or proof of failure.
            x, y = float(out['p1x']), float(out['p1y'])
            if not (235.0 <= x <= 260.0 and 420.0 <= y <= 455.0):
                raise RuntimeError(f'first guard not cleared and no observed helper step: {out}')
            up('RIGHT')
            sleep(0.18)
            step = read_state()
            if step.get('p1dead') or step.get('p2dead'):
                raise RuntimeError(f'death on first guard helper step: {step}')
            if not (235.0 <= float(step['p1x']) <= 260.0 and 420.0 <= float(step['p1y']) <= 455.0):
                raise RuntimeError(f'helper step not stably occupied: {step}')

            # Jump from the +40px helper block to clear the next +40px
            # ledge. PlayerMale has no double-jump; only normal jump and
            # facing-correct ordinary air-dash are used.
            down('C')
            sleep(0.34)
            up('C')
            capture('guard-helper-step-apex')
            apex = read_state()
            if apex.get('p1dead') or apex.get('p2dead'):
                raise RuntimeError(f'death during helper step jump: {apex}')
            if float(apex['p1y']) + 41.0 > 440.0:
                raise RuntimeError(f'helper jump did not clear ledge top: {apex}')

            # The second jump from the helper clears the raised block's
            # front edge, but run 38126835150 showed a long dash straight
            # into the patrol at x≈372 while descending. First land on the
            # upper platform's safe left edge using a short normal walk.
            down('RIGHT')
            sleep(0.07)
            sleep(0.12)
            up('RIGHT')
            sleep(0.45)
            platform = read_state()
            capture('guard-upper-platform-stage')
            if platform.get('p1dead') or platform.get('p2dead'):
                raise RuntimeError(f'death staging on upper guard platform: {platform}')
            if not (270.0 <= float(platform['p1x']) <= 340.0
                    and 375.0 <= float(platform['p1y']) <= 414.0):
                raise RuntimeError(f'upper guard platform landing unproven: {platform}')

            # The player must be on the higher y440 platform before this
            # separate ordinary jump, giving enough altitude to pass
            # over the y390 guard. Still no teleport, saves, or physics edits.
            down('C')
            sleep(0.34)
            up('C')
            capture('guard-upper-platform-apex')
            high = read_state()
            if high.get('p1dead') or high.get('p2dead'):
                raise RuntimeError(f'death on upper platform jump: {high}')
            if float(high['p1y'])+41.0 >= 390.0:
                raise RuntimeError(f'upper platform jump below guard top: {high}')
            down('RIGHT')
            sleep(0.07)
            down('X')
            sleep(0.12)
            capture('guard-upper-platform-flight-00')
            flight = read_state()
            if flight.get('p1dead') or flight.get('p2dead'):
                raise RuntimeError(f'death during upper platform dash: {flight}')
            sleep(0.38)
            up('X')
            capture('guard-upper-platform-after-dash')
            sleep(0.30)
            out = read_state()
            if out.get('p1dead') or out.get('p2dead'):
                raise RuntimeError(f'death clearing upper guard platform: {out}')
            if float(out['p1x']) < 510.0:
                raise RuntimeError(f'guard not cleared by upper platform leap: {out}')
        return out
    finally:
        up('C')
        up('X')
        up('RIGHT')
