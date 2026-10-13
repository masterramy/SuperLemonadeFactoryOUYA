"""QA-only, legitimate Level 2 tall-platform traversal helpers.

The shipped Character jump height depends on holding its C key for up to
0.35 s. A 0.04 s tap is materially different and cannot prove traversal.
This module changes only controller input, not game state or physics.
"""


def sustained_jump_right(keydown, keyup, sleep):
    """Hold game direction and jump, then release both even on failure."""
    keydown('RIGHT')
    try:
        sleep(0.04)
        keydown('C')
        try:
            sleep(0.34)
        finally:
            keyup('C')
        sleep(0.42)
    finally:
        keyup('RIGHT')
    sleep(0.18)




def apex_first_jump_right(keydown, keyup, sleep, observe):
    """Jump vertically to near apex, then advance right over the tall wall.

    The prior immediate-horizontal held jump landed against the wall at x730.
    Inspect the true airborne QA state at the end of the height-gaining phase.
    Only ordinary player key events are sent, with guaranteed release.
    """
    held=set()
    def down(k):
        keydown(k); held.add(k)
    def up(k):
        if k in held:
            keyup(k); held.remove(k)
    try:
        down('C')
        sleep(0.34)
        observe('apex-before-translate')
        down('RIGHT')
        sleep(0.12)
        up('C')
        sleep(0.45)
        observe('after-apex-translate')
    finally:
        up('C')
        up('RIGHT')
    sleep(0.18)

def crate_jump_right(keydown, keyup, sleep):
    """Legitimate ordinary C/right jump from the observed fallen-crate foothold.

    Never block on ADB state reads or screenshots while the player is rising.
    Keep C held through the engine's variable-height jump window; use
    RIGHT only after some altitude is gained. Input is always released.
    """
    held=set()
    def down(key):
        keydown(key); held.add(key)
    def up(key):
        if key in held:
            keyup(key); held.remove(key)
    try:
        down('C')
        sleep(.26)
        down('RIGHT')
        sleep(.10)
        up('C')
        sleep(.32)
    finally:
        up('C')
        up('RIGHT')
    sleep(.22)


def clear_tall_ledge(read_state, hold, jump, capture, attempts=4,
                     crate_jump=None):
    """Traverse only with observed positions and real player inputs.

    Level2.oel has a 120px tall ledge (x740,y400). When Liselot has
    legitimately pushed its movable crate LEFT onto ground (x~716,
    y~497), Andre must jump onto that crate, then jump AGAIN toward
    the ledge. The old controller walked LEFT off the crate every
    attempt, then kept repeating an impossible ground-only jump.
    """
    def check(d):
        if d.get('p1dead') or d.get('p2dead'):
            raise RuntimeError(f'Death during tall platform traversal: {d}')
        return d
    def crossed(d):
        return float(d['p1x']) >= 740.0 and float(d['p1y'])+41.0 <= 400.0
    def on_fallen_crate(d):
        cx=float(d.get('crateX',-1.0))
        cy=float(d.get('crateY',-1.0))
        if cx<0 or not (485.0<=cy<=515.0):
            return False
        x,y=float(d['p1x']),float(d['p1y'])
        return (cx-8.0<=x<=cx+25.0 and
                abs((y+41.0)-cy)<=6.0)

    for attempt in range(attempts):
        d=check(read_state())
        if crossed(d):
            return d
        if on_fallen_crate(d):
            if crate_jump is None:
                raise RuntimeError('Fallen crate foothold observed; missing normal crate jump')
            # IMPORTANT no staged LEFT correction here: x730,y457
            # is the real foothold. Moving to x690 loses elevation.
            capture(f'andre-crate-foothold-{attempt:02d}')
            crate_jump()
            d=check(read_state())
            capture(f'andre-crate-jump-result-{attempt:02d}')
            if crossed(d):
                return d
            continue

        # On the floor, take off LEFT of the fallen crate and land on
        # its upper face. If no valid crate telemetry, preserve the
        # former bounded staging as a diagnostic-only fallback.
        cx=float(d.get('crateX',-1.0))
        cy=float(d.get('crateY',-1.0))
        target=max(665.0,min(cx-25.0,712.0)) if (0<=cx<=780 and 485<=cy<=515) else 690.0+6.0*attempt
        for _ in range(16):
            d=check(read_state())
            delta=target-float(d['p1x'])
            if abs(delta)<12.0:
                break
            direction='RIGHT' if delta>0 else 'LEFT'
            hold(direction,max(.10,min(.25,abs(delta)/240.0)))
        capture(f'andre-ledge-stage-{attempt:02d}')
        jump()
        d=check(read_state())
        capture(f'andre-ledge-result-{attempt:02d}')
        if crossed(d):
            return d
        # Next iteration MUST detect any valid landing on the
        # fallen crate instead of restaging left and undoing it.

    raise RuntimeError(
        f'Tall platform not crossed after {attempts} legitimate held-jump attempts; '
        f'last={check(read_state())}')
