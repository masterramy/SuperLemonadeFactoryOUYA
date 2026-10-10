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


def clear_tall_ledge(read_state, hold, jump, capture, attempts=4):
    """Try stage-left-and-held-jump, using only actual inputs and observed state.

    A crossing is reported only when the real post-input player position
    is on top of or beyond the tall platform. Death/stall fails closed.
    """
    for attempt in range(attempts):
        d = read_state()
        if d.get('p1dead') or d.get('p2dead'):
            raise RuntimeError(f'Death while staging tall platform: {d}')
        desired = 605.0 + 12.0*attempt
        for _ in range(16):
            d = read_state()
            if d.get('p1dead') or d.get('p2dead'):
                raise RuntimeError(f'Death while staging tall platform: {d}')
            delta = desired - float(d['p1x'])
            if abs(delta) < 12.0:
                break
            direction = 'RIGHT' if delta > 0 else 'LEFT'
            hold(direction, max(0.10, min(0.25, abs(delta)/240.0)))
        capture(f'andre-ledge-stage-{attempt:02d}')
        jump()
        capture(f'andre-ledge-result-{attempt:02d}')
        d = read_state()
        if d.get('p1dead') or d.get('p2dead'):
            raise RuntimeError(f'Death during tall platform jump: {d}')
        if float(d['p1x']) >= 740.0 and float(d['p1y']) <= 400.0:
            return d
    raise RuntimeError(f'Tall platform not crossed after {attempts} legitimate held-jump attempts; last={read_state()}')
