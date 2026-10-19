#!/usr/bin/env python3
"""Player 2 must keep polling when the first physical pad disconnects."""
from pathlib import Path
s=(Path(__file__).resolve().parents[2]/'src/org/flixel/system/input/FlxJoystick.as').read_text()
start=s.index('public function update():void')
body=s[start:s.index('private function updatePrimary():void',start)]
assert 'if (active == null) { clearState(); clearSecondaryState(); return; }' not in body
assert 'if (active == null) clearState();' in body
assert 'else updatePrimary();' in body
assert body.index('updateSecondary();') > body.index('else updatePrimary();')
print('PASS Player 2 polling survives P1 unplug')
