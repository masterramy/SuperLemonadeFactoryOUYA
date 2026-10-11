"""Source-informed guard traversal using actual player button inputs and read-only state.

The previous 0.04s jump + simultaneous dash landed Andre in the first guard
patrol around x382. This controller gains altitude before horizontal air-dash.
It never edits position, health, save data, collisions, enemies, or game time.
"""

def airborne_dash_past_guard(read_state, keydown, keyup, sleep, capture):
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
            raise RuntimeError(f'first guard not cleared by observed air dash: {out}')
        return out
    finally:
        up('C')
        up('X')
        up('RIGHT')
