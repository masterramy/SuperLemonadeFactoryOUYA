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
                # Real run 38214609453: Andre is at x210 with the x220,
                # y480 helper block physically in his way. Walking RIGHT
                # cannot cross a solid! Use a legitimate variable-height
                # jump before moving onto that block. This changes input
                # strategy, not physics/save/game state.
                up('RIGHT')
                down('C')
                sleep(0.34)
                up('C')
                capture('guard-ground-helper-takeoff')
                rise=read_state()
                if rise.get('p1dead') or rise.get('p2dead'):
                    raise RuntimeError(f'death during normal helper jump: {rise}')
                if float(rise['p1y']) >= 440.0:
                    raise RuntimeError(f'Andre did not rise above helper block: {rise}')
                down('RIGHT')
                sleep(0.18)
                up('RIGHT')
                sleep(0.38)
                advanced=read_state()
                capture('guard-ground-helper-landed')
                if advanced.get('p1dead') or advanced.get('p2dead'):
                    raise RuntimeError(f'death during helper-block landing: {advanced}')
                nx,ny=float(advanced['p1x']),float(advanced['p1y'])
                if not (235.0 <= nx <= 260.0 and 420.0 <= ny <= 455.0):
                    raise RuntimeError(f'normal helper jump did not land on observed lower step: {advanced}')
                # Fall through to the proven separate helper-to-upper
                # platform jump below; x250,y439 is not completion.
                out=advanced
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
            # In-air screenshot capture takes long enough to consume the jump
            # window (real run 38349561527). Read state without a capture.
            apex = read_state()
            if apex.get('p1dead') or apex.get('p2dead'):
                raise RuntimeError(f'death during helper step jump: {apex}')
            if float(apex['p1y']) + 41.0 > 440.0:
                raise RuntimeError(f'helper jump did not clear ledge top: {apex}')

            # Real run 38349009371: landing at x310,y399 puts Andre
            # directly into the moving guard. Avoid the unsafe landing;
            # continue the ordinary helper-step jump until the player's
            # feet are genuinely ABOVE the patrol, then execute his
            # normal facing-correct midair dash. No physics/save edits.
            sleep(0.22)
            high = read_state()
            if high.get('p1dead') or high.get('p2dead'):
                raise RuntimeError(f'death while rising above guard: {high}')
            if float(high['p1y']) + 41.0 >= 390.0:
                raise RuntimeError(f'normal helper jump not yet clear above guard: {high}')
            down('RIGHT')
            sleep(0.07)
            down('X')
            sleep(0.12)
            capture('guard-high-air-dash-early')
            flight = read_state()
            if flight.get('p1dead') or flight.get('p2dead'):
                raise RuntimeError(f'death during high air dash: {flight}')
            sleep(0.38)
            up('X')
            capture('guard-high-air-dash-late')
            sleep(0.30)
            out = read_state()
            if out.get('p1dead') or out.get('p2dead'):
                raise RuntimeError(f'death after airborne guard clearance: {out}')
            if float(out['p1x']) < 510.0:
                raise RuntimeError(f'guard not cleared by genuine airborne helper leap: {out}')
        return out
    finally:
        up('C')
        up('X')
        up('RIGHT')
