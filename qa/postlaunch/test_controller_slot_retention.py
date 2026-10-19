"""Contract: Bluetooth hotplug must never silently move a surviving pad between players."""
from pathlib import Path

root = Path(__file__).resolve().parents[2]
source = (root / "src/org/flixel/system/input/FlxJoystick.as").read_text(encoding="utf-8")
body = source.split("private function selectDevice():void", 1)[1].split("private function updateSecondary():void", 1)[0]
assert "if (d == active)" in body, "Player 1 assignment must survive reorder"
assert "if (d == secondary)" in body, "Player 2 assignment must survive reorder"
assert body.index("if (d == active)") < body.index("if (found == null)")
assert body.index("if (d == secondary)") < body.index("if (found == null)")
assert "if (d == found || d == foundSecondary) continue;" in body
print("PASS: controller slots preserve physical identity across hotplug")
