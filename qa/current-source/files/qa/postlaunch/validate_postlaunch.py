#!/usr/bin/env python3
"""Static source/asset safety checks. NOT an Adobe AIR compile or device test."""
from pathlib import Path
import re, hashlib, ast
from PIL import Image
root=Path(__file__).resolve().parents[2]
fail=[]
def check(cond,label):
    print(('PASS' if cond else 'FAIL')+' '+label)
    if not cond: fail.append(label)

app=(root/'application.xml').read_text()
check('com.ramybaheeg.slfport' in app,'package retained')
check('<versionNumber>1.9.1</versionNumber>' in app and '1009001' in (root/'tools/build-apk.ps1').read_text(),'shipped version identity retained')
check('com.google.android.gms.games' not in app,'no unconfigured Play Games SDK shipped')
s=(root/'src/org/flixel/system/input/FlxJoystick.as').read_text()
check('GameInput.getDeviceAt' in s and 'j1ButtonAJustPressed = a && !lastA' in s,'controller polling and press edges')
check('axisX < -0.30' in s,'analog dead zone')
check('return hasFaceButtons && hasDirectionControl;' in s and 'if (isGamepadTopology(d))' in s,'unknown controller mapping fails closed')
s=(root/'src/org/flixel/FlxG.as').read_text()
check('FlxG.joystick.update();' in s and 'may connect after startup' in s,'hotplug polling enabled independent of startup state')
pairs=[('data/level1_tiles.png','data/remaster_prototype/warehouse_tiles.png'),('data/level2/level2_tiles.png','data/remaster_prototype/factory_tiles.png'),('data/level3/level3_tiles.png','data/remaster_prototype/management_tiles.png')]
for a,b in pairs:
    ia=Image.open(root/a).convert('RGBA');ib=Image.open(root/b).convert('RGBA')
    check(ia.size==ib.size, b+' exact dimensions')
    check(ia.getchannel('A').tobytes()==ib.getchannel('A').tobytes(),b+' exact collision-facing transparency')
    check(ia.tobytes()!=ib.tobytes(),b+' actually visually modified')
mode=(root/'src/GraphicsMode.as').read_text()
check('"SLF"' in mode and 'graphicsMode' in mode,'graphics mode uses existing local save')
codec=(root/'src/CloudProgressCodec.as').read_text()
fields=re.findall(r'"([a-zA-Z]+(?:Complete|TalkAndre|Talk|Cap))"',codec)
# Regex alternative isn't enough for mixed names; extract array section instead.
arr=codec.split('private static const FIELDS:Array = [',1)[1].split('];',1)[0]
fields=re.findall(r'"([A-Za-z]+)"',arr)
check(len(fields)==24 and len(set(fields))==24,'cloud codec fields cover all 24 distinct progression arrays')
reg=(root/'src/Registry.as').read_text()
check(set(fields)==set(re.findall(r'save\.data\.([A-Za-z]+)\s*=\s*normaliseProgressArray',reg)),'cloud codec exactly matches actual Registry progress-save schema')
check('return null;' in codec and 'lv != "0"' in codec,'bad cloud data rejected rather than resetting saves')
check('save.close()' in codec and 'mergeIntoLocal' in codec,'local save integration writes after merging')
# Cloud snapshot field labels must match the original game save schema exactly,
# not merely have 13 flag entries: otherwise a corrupted remote record can be
# incorrectly interpreted as another category (e.g. collectibles vs unlocks).
expected_labels = re.findall(r'save\.data\.([A-Za-z]+)\s*=\s*normaliseProgressArray\(save\.data\.\w+,\s*"([^"]+)"', reg)
labels_block = codec.split('private static const LABELS:Array = [', 1)[1].split('];', 1)[0]
codec_labels = re.findall(r'"([^"]+)"', labels_block)
check([name for name, label in expected_labels] == fields and
      [label for name, label in expected_labels] == codec_labels,
      'cloud save category/label order matches original Registry save schema')
check('l[0] !== label || r[0] !== label' in codec and 'var result:Array = [label];' in codec,
      'rejects wrong cloud category labels and canonicalizes output labels')
check('localJSON.length > 65536 || remoteJSON.length > 65536' in codec,
      'limits both local and remote snapshot sizes before JSON parsing')

check('GameServices' not in codec,'no false cloud service claims')
trail=(root/'tools/postlaunch/make_trailer_from_real_video.py').read_text()
check('ffprobe' in trail and 'ffmpeg' in trail and 'nargs=\'+\'' in trail,'trailer uses real video inputs only')
options=(root/'src/PCOptionsState.as').read_text()
# GUI order is delete -> graphics -> back. Button-index logic must follow it
# for keyboard/controller use as well as mouse/touch callbacks.
start=options.split('protected function beginFade():void',1)[1].split('protected function completeFade():void',1)[0]
complete=options.split('protected function completeFade():void',1)[1].split('//IMPORT FILE HELPERS',1)[0]
check('currentButton == 0' in start and 'deleteHistory();' in start,
      'controller Options index0 deletes only through confirmation')
check('currentButton == 1' in start and 'changeGraphics();' in start,
      'controller Options index1 toggles graphics, not menu navigation')
check('currentButton == 2' in start and 'FlxG.fade' in start and 'currentButton == 2' in complete,
      'controller Options index2 returns to menu')
helper=(root/'tools/postlaunch/compile_wip.ps1').read_text()
batch=(root/'COMPILE_POSTLAUNCH_WIP.bat').read_text()
check('air-51.3.4.3' in helper and 'SuperLemonadeFactory\\toolchain' in helper,
      'compile helper locates existing owner-local AIR toolchain')
check('POSTLAUNCH_COMPILE_RESULT.txt' in batch and 'pause' in batch.lower() and 'SIGN_V191' not in batch,
      'BAT retains a diagnostic log and never calls production signing')

# Parallel track continuation: source-level contracts, not device acceptance.
controller=(root/'src/org/flixel/system/input/FlxJoystick.as').read_text()
check('hatX < -0.50' in controller and 'hatY < -0.50' in controller,
      'Bluetooth controller D-pad HAT axes handled (runtime remains unproven)')
check('validFieldSet(local)' in codec and 'validFieldSet(remote)' in codec and
      'FIELDS.indexOf(key) < 0' in codec and 'local.schema !== SCHEMA' in codec,
      'cloud snapshot field set and strict schema validation')
capture=(root/'tools/postlaunch/capture_real_gameplay.ps1').read_text()
check('pidof $package' in capture and '.capture.txt' in capture,
      'recording requires real running Android game and creates a hash receipt')
devapk=(root/'tools/postlaunch/build_disposable_android.ps1').read_text()
check('com.ramybaheeg.slfport.dev' in devapk and 'Remove-Item -LiteralPath $key' in devapk and
      'SLF-DEV-PHONE.apk' in devapk,
      'test APK uses isolated package and deletes disposable signing key')

if fail: raise SystemExit(f'{len(fail)} failed')
print('Static validation complete. This is NOT an Android runtime certification.')

# New diagnostics and remaster frame-map contracts. These are static
# invariants only; Bluetooth hardware and remastered rendering remain gated.
qa_pad=(root/'src/org/flixel/system/input/FlxJoystick.as').read_text()
qa_options=(root/'src/PCOptionsState.as').read_text()
check('public function qaStatus():String' in qa_pad and 'qaMapping' in qa_pad,
      'controller QA reports anonymous mapping and held button states')
check('NativeApplication.nativeApplication.applicationID == "com.ramybaheeg.slfport.dev"' in qa_options,
      'diagnostics are visible only in separately installed DEV package')
check('qaPadText.text = FlxG.joystick.qaStatus()' in qa_options,
      'controller diagnostic reflects current GameInput polling')
import json as _json
frame_file=root/'qa/postlaunch/CHARACTER_REMASTER_ANIMATION_MAP.json'
fm=_json.loads(frame_file.read_text(encoding='utf8'))
check(fm['frame_size']==[50,80] and fm['sheet_size']==[600,640]
      and fm['referenced_frames']>=60 and len(fm['animations_by_game_class'])>=7,
      'character remaster map covers real animation-sheet frame geometry')
if fail: raise SystemExit(f'{len(fail)} failed after extended checks')


script=(root/'tools/postlaunch/build_disposable_android.ps1').read_text()
check('SLF_DEV_PHONE_RECEIPT.txt' in script and 'SLF_DEV_EMULATOR_RECEIPT.txt' in script,
      'phone and emulator builds preserve separate hash/signing receipts')
if fail: raise SystemExit(f'{len(fail)} failed including distinct receipt test')
