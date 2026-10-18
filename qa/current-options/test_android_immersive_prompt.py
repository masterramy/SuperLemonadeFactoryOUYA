#!/usr/bin/env python3
"""The emulator may dismiss only the known one-time OS immersive onboarding popup."""
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).parent))
from dismiss_android_immersive_prompt import find_dismiss_center
fixture = '<hierarchy><node text="Viewing full screen" package="android"/><node text="Got it" resource-id="android:id/ok" clickable="true" bounds="[1371,436][1553,562]"/></hierarchy>'
assert find_dismiss_center(fixture) == (1462,499)
assert find_dismiss_center('<hierarchy><node text="Other dialog" bounds="[0,0][20,20]"/></hierarchy>') is None
assert find_dismiss_center('<hierarchy><node text="Viewing full screen"/><node text="Got it" clickable="false" bounds="[0,0][20,20]"/></hierarchy>') is None
script=(Path(__file__).parent/'capture_graphics_options_targeted.sh').read_text()
assert script.index('dismiss_android_immersive_prompt.py') < script.index('adb shell input tap 960 850')
print('4/4 Android immersive onboarding handling guards PASS')
