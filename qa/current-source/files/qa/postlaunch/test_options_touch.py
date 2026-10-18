#!/usr/bin/env python3
"""Safety contract: Android Options taps must select exact buttons, never implicit Delete."""
from pathlib import Path
r = Path(__file__).resolve().parents[2]
options = (r/'src/PCOptionsState.as').read_text()
touch = (r/'src/MobileControls.as').read_text()
assert 'public function activateOptionsButtonAt(gameX:Number, gameY:Number):Boolean' in options
start = options.index('public function activateOptionsButtonAt(')
end = options.index('private function changeGraphics()',start)
area = options[start:end]
assert 'var items:Array = [eraseBtn, graphicsBtn, backBtn]' in area
assert 'gameX >= button.x' in area and 'gameY >= button.y' in area
assert 'if (i == 0) deleteHistory();' in area
assert 'else if (i == 1) changeGraphics();' in area
assert 'else onQuit();' in area
assert 'return false;' in area
start = touch.index('else if (FlxG.state is PCOptionsState)')
end = touch.index('else pulseKey(KEY_X)',start)
path = touch[start:end]
assert 'optionsMenu.activateOptionsButtonAt(optionX, optionY)' in path
assert 'pulseKey(KEY_X)' not in path
assert 'else if (FlxG.state is PCMenuState)' in touch
print('PASS exact-screen-coordinate Options touch routes Delete / Graphics / Back safely')
