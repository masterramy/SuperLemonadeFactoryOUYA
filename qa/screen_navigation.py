"""QA-only conservative screenshot classification and Android system-dialog targeting.

Unknown frames must never be silently treated as Level Select/gameplay.
This reads rendered frames and does not alter game-state or save data.
"""
import io
import re
import xml.etree.ElementTree as ET
from PIL import Image


def system_dialog_target(xml_text):
    try:
        root = ET.fromstring(xml_text)
    except (ET.ParseError, TypeError):
        return None
    for label in ('Wait', 'Got it', 'Continue', 'OK'):
        for node in root.iter('node'):
            if node.attrib.get('text') != label:
                continue
            m = re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]',node.attrib.get('bounds',''))
            if m:
                x1,y1,x2,y2=map(int,m.groups())
                return ((x1+x2)//2,(y1+y2)//2)
    return None


def _count(im,rect,predicate):
    w,h=im.size
    x1,y1,x2,y2=rect
    crop=im.crop((int(w*x1),int(h*y1),int(w*x2),int(h*y2)))
    return sum(1 for r,g,b in crop.getdata() if predicate(r,g,b))


def classify_screen(image):
    if isinstance(image,(bytes,bytearray)):
        image=Image.open(io.BytesIO(image))
    im=image.convert('RGB')
    w,h=im.size
    green=_count(im,(.30,.03,.67,.39),lambda r,g,b:g>80 and g>r*1.2 and g>b*1.3)
    red=_count(im,(.68,.10,.92,.65),lambda r,g,b:r>120 and r>g*1.4 and r>b*1.3)
    purple=_count(im,(.15,.12,.90,.82),lambda r,g,b:r>70 and b>r and r>g*1.2 and b>g*1.2)
    if green>int(w*h*.025):
        return 'title' if red>int(w*h*.0005) else 'menu'
    if purple>int(w*h*.005):
        return 'level_select'
    return 'unknown'
