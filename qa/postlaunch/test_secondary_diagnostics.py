"""Contract: physical controller diagnostics must show both controllers independently."""
from pathlib import Path
source=(Path(__file__).resolve().parents[2]/"src/org/flixel/system/input/FlxJoystick.as").read_text(encoding="utf-8")
assert 'P2: ' in source
assert 'noteQAEdge2(' in source
assert 'qaDevice2Name' in source and 'qaMapping2' in source
assert 'qaLast2Input' in source and 'qa2EventCount' in source
print('PASS: Player2 independent controller diagnostics')
