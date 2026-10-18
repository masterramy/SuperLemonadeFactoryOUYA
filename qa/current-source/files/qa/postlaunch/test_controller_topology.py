"""Guard actual AS3 GameInput topology selection and disconnection behavior.
Static contract only; physical Bluetooth mapping requires phone tests.
"""
from pathlib import Path
p=Path(__file__).resolve().parents[2]/'src/org/flixel/system/input/FlxJoystick.as'
s=p.read_text(encoding='utf-8')
checks={
'controller selected by supported topology even when device name is atypical': 'isGamepadTopology(d)' in s and 'if (isGamepadTopology(d))' in s,
'face buttons and directional control both required': 'hasFaceButtons' in s and 'hasDirectionControl' in s,
'device selection is not gated solely on product name': 'name.indexOf("xbox") >= 0 || name.indexOf("wireless controller") >= 0' not in s,
'diagnostic name is taken from selected device': 'qaDeviceName = name.substr(0, 26);' in s and 'if (isGamepadTopology(d))' in s,
'unknown/no device clears diagnostics': 'qaDeviceName = "none";' in s and 'qaMapping = "disconnected";' in s,
}
for name,ok in checks.items(): print(('PASS' if ok else 'FAIL'),name)
assert all(checks.values()),'GameInput topology selection not fully implemented'
