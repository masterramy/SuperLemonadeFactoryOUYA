"""Native pixel-geometry and coverage gates for *pending* full-art remaster."""
from pathlib import Path
from tempfile import TemporaryDirectory
from PIL import Image
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'tools/postlaunch'))
from prepare_semantic_remaster import stage_remaster, validate_remaster
root=Path(__file__).resolve().parents[2]
with TemporaryDirectory() as d:
    out=Path(d)
    status=stage_remaster(root,out)
    assert status['total_assets']==109, status
    assert status['frame_count']==69
    assert (out/'originals/data/chars_50x50.png').exists()
    assert (out/'frames/original/frame_006.png').exists()
    assert not (out/'candidate/data/chars_50x50.png').exists(), 'Do not invent a completed remaster'
    assert not validate_remaster(root, out)['ready']
    c=out/'candidate/data/chars_50x50.png'
    c.parent.mkdir(parents=True,exist_ok=True)
    Image.new('RGBA',(10,10),(0,0,0,0)).save(c)
    result=validate_remaster(root,out)
    assert any('dimensions' in item for item in result['issues'])
print('PASS remaster workpackage exactly 109 source assets / 69 sprite frames; missing and wrongly-sized candidates fail closed')
