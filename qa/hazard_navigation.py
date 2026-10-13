"""Observation-driven ordinary-input corridor traversal for the QA runtime.

No state writes: this sends the same jump, directional, and double-jump
inputs a player can send, then observes the live coordinates/death flags.
"""


def cross_spike_and_worker_corridor(read_state, keydown, keyup, sleep, capture,
                                    target_x=1315.0, max_polls=20):
    """From top platform x=980..1010, cross spikes and patrolling worker.

    Character.as supports a first jump held for up to 0.35s; 0.04s taps
    truncate that jump and led prior QA to fall near the final worker.
    Second jump must be a fresh keydown after releasing C while airborne.
    Keep RIGHT down until the observed x is beyond the worker corridor;
    success is never inferred from elapsed time or a scripted action alone.
    """
    initial=read_state()
    if initial.get('p1dead') or initial.get('p2dead'):
        raise RuntimeError(f'corridor death before launch: {initial}')
    x=float(initial['p2x'])
    if not 975.0 <= x <= 1010.0:
        raise ValueError(f'unsafe staging for corridor traversal x={x}')

    held=set()
    def down(k):
        keydown(k); held.add(k)
    def up(k):
        if k in held:
            keyup(k); held.remove(k)

    try:
        capture('corridor-00-pre-takeoff')
        down('RIGHT')
        down('C')
        sleep(0.34)  # held variable-height first jump, below game's 0.35s cap
        up('C')
        sleep(0.14)
        down('C')   # true second justPressed while airborne
        sleep(0.05)
        up('C')
        for i in range(max_polls):
            sleep(0.10)
            d=read_state()
            if d.get('p1dead') or d.get('p2dead'):
                capture(f'corridor-death-{i:02d}')
                raise RuntimeError(f'corridor death at x={d.get("p2x")}: {d}')
            if i in (0,4,8,12):
                capture(f'corridor-{i:02d}')
            if float(d['p2x']) >= target_x:
                capture('corridor-exit-x-reached')
                return d
        capture('corridor-exhausted')
        raise RuntimeError(f'corridor not crossed after {max_polls} real-state polls; last={read_state()}')
    finally:
        # Never leave buttons held after success, death, missing observer, or timeout.
        up('C')
        up('RIGHT')


def align_exit_from_right(read_state, hold, exit_x, max_steps=12):
    """Reapproach the exit from safe right-hand ground by measured walking.

    A large double-jump back toward exit overshot from x1380 to x1224
    and entered the worker patrol. This method never jumps, never accepts
    an unobserved position, and fails if it crosses the safety boundary.
    """
    for step in range(max_steps):
        d=read_state()
        if d.get('p1dead') or d.get('p2dead'):
            raise RuntimeError(f'exit alignment death: {d}')
        x=float(d['p2x'])
        if abs(x-exit_x)<=15.0:
            return d
        if x < exit_x-15.0:
            # Actual run 38359529083 observed x=1303.46, only 16.54px
            # short of exit. The prior strict LEFT-only alignment
            # incorrectly classified this as an unsafe overshoot and
            # stopped a living character. Make one measured ordinary
            # RIGHT correction if within a 22px safe margin.
            # Larger retreats remain a hard failure to avoid the patrol.
            if x < exit_x-22.0:
                raise RuntimeError(f'unsafe exit alignment overshoot: {d}')
            seconds=max(0.04,min(0.08,(exit_x-x)/220.0))
            hold('RIGHT', seconds)
            continue
        seconds=max(0.07,min(0.16,(x-exit_x)/230.0))
        hold('LEFT', seconds)
    raise RuntimeError(f'exit not aligned after {max_steps} ordinary walks; state={read_state()}')
