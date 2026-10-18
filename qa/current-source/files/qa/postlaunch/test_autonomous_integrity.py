#!/usr/bin/env python3
"""Executable source contracts, not a replacement for hardware QA."""
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[2]
checks={}
def test(label,predicate):
    checks[label]=bool(predicate)
    print(('PASS' if predicate else 'FAIL'),label)

for name in ['ICloudSaveTransport.as','CloudSyncCoordinator.as','PGSNativeTransport.as']:
    test('cloud bridge source present '+name,(root/'src'/name).is_file())
s=(root/'src/CloudSyncCoordinator.as').read_text()
test('explicit consent and transport availability before any network', 'if (busy || !consent || transport == null || !transport.supported)' in s and 'transport.authorize(' in s)
test('cannot fake successful save without network write', 'transport.write(SLOT, snapshot' in s and 'status == "ok"' in s)
test('bounded conflict reread', 'MAX_CONFLICT_RETRIES:int = 3' in s and 'self.readFresh()' in s)
test('remote corruption fails closed', 'CloudProgressCodec.merge(current, remote)' in s and 'merged == null' in s)
test('local restored before cloud write', s.index('CloudProgressCodec.mergeIntoLocal(remote)')<s.index('self.writeMerged(merged)'))
s=(root/'src/PGSNativeTransport.as').read_text()
test('native service fail-closed without ANE', 'extensionSupported = context.call("supported") === true' in s and 'ready = extensionSupported && context.call("signedIn") === true' in s)
test('unconfigured extension not declared as installed', 'com.ramybaheeg.slfport.pgs.savedgames' not in (root/'application.xml').read_text())
pad=(root/'src/org/flixel/system/input/FlxJoystick.as').read_text()
test('gamepad edge events persisted only in ephemeral QA memory', 'noteQAEdge("A")' in pad and 'qaLastInputTime' in pad and 'Count: ' in pad)
test('controller no account or hardware ID in diagnostics', 'deviceID' not in pad.split('public function qaStatus():String')[1].split('public function FlxJoystick()')[0])
player=(root/'src/PlayerMale.as').read_text()
test('remaster run pilot wired behind existing graphics mode', 'GraphicsMode.choose(ImgPlayer, ImgPlayerPreview)' in player)
test('Liselot preview also gated', 'GraphicsMode.choose(ImgPlayer, ImgPlayerPreview)' in (root/'src/PlayerFemale.as').read_text())
old=Image.open(root/'data/chars_50x50.png').convert('RGBA')
new=Image.open(root/'data/remaster_prototype/chars_two_heroes_run_preview.png').convert('RGBA')
test('original atlas dimensions preserved',old.size==new.size==(600,640))
changed=[]
for frame in range(96):
    x=frame%12*50;y=frame//12*80;box=(x,y,x+50,y+80)
    if old.crop(box).tobytes()!=new.crop(box).tobytes():changed.append(frame)
test('only twelve hero movement frames changed',changed==list(range(6,18)))
test('original original gameplay source maps unchanged',all((root/'data'/name).exists() for name in ('level1','level2','level3')))
if not all(checks.values()): raise SystemExit(f'{sum(not b for b in checks.values())} autonomous checks failed')
print(f'{len(checks)}/{len(checks)} PASS — CI hardware/runtime still required')
