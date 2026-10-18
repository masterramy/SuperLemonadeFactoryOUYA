#!/usr/bin/env python3
"""Negative controls prove UI proof cannot be achieved using repeated/ANR frames."""
from pathlib import Path
from tempfile import TemporaryDirectory
import sys
sys.path.insert(0,str(Path(__file__).parent))
from verify_options_screen_evidence import verify,FILES
from PIL import Image, ImageDraw

with TemporaryDirectory() as dirname:
    path=Path(dirname)
    base=Image.new('RGB',(1920,1080),'#a7aba8')
    for name in FILES:base.save(path/name)
    try: verify(path)
    except ValueError as e: assert 'IDENTICAL_FULL_FRAMES' in str(e),e
    else:raise AssertionError('unchanged frames incorrectly passed')
    print('PASS identical screen captures fail closed')
    (path/'03_graphics_toggled.png').write_bytes((path/'02_options_classic.png').read_bytes())
    (path/'03_graphics_toggled.png.xml').write_text('<hierarchy><node text="Pixel Launcher isn\'t responding"/></hierarchy>')
    try: verify(path)
    except ValueError as e:assert 'ANDROID_SYSTEM_ANR_DIALOG' in str(e),e
    else:raise AssertionError('system ANR incorrectly passed')
    print('PASS accessibility ANR dialog fails closed')
    (path/'03_graphics_toggled.png.xml').unlink()
    # Non-duplicate images with superficial outside-of-label differences
    # must still fail to demonstrate Options graphics toggle.
    for i,name in enumerate(FILES):
        im=base.copy(); ImageDraw.Draw(im).rectangle((10+i*3,10,14+i*3,14),fill='white');im.save(path/name)
    try: verify(path)
    except ValueError as e: assert 'GRAPHICS_LABEL_DID_NOT_CHANGE' in str(e),e
    else: raise AssertionError('unrelated motion incorrectly passed')
    print('PASS unrelated changing frames do not prove graphics toggle')
    # A genuine label difference in a stable static options screenshot,
    # with return-to-classic, is what the pixel guard requires.
    images=[]
    for i in range(5):
        im=base.copy();ImageDraw.Draw(im).rectangle((10+i*3,10,14+i*3,14),fill='white')
        if i==2: ImageDraw.Draw(im).rectangle((690,640,760,654),fill='black')
        images.append(im)
    for im,name in zip(images,FILES): im.save(path/name)
    assert verify(path)['changed_pixels']>160
    print('PASS true target-region change and restoration meets pixel contract')
print('4/4 synthetic visual-proof control cases PASS; NOT genuine Android acceptance')
