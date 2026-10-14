"""QA-only genuine completion/death classifier.

Never treat PlayState.levelFinished alone as success: tryAgain() sets it
on death. Only PCPlayState.__levelOver (levelOverMenu) represents the
normal Next Level outcome; dead flags are a hard veto.
"""

def is_genuine_completion(state):
    return (state.get("levelFinished") is True
            and state.get("levelOverMenu") is True
            and state.get("p1dead") is False
            and state.get("p2dead") is False)


def is_death(state):
    return (state.get("p1dead") is True
            or state.get("p2dead") is True
            or (state.get("levelFinished") is True and not is_genuine_completion(state)))
