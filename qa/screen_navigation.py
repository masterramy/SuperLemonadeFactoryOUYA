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
    # Real Android gameplay has six evenly-spaced tan control pads at
    # y≈90% of the canvas. Purple effects/scenery ALSO occur in gameplay,
    # so classify this distinctive native gameplay HUD before Level Select.
    controls=[
        im.getpixel((int(w*x),int(h*.90)))
        for x in (.08,.24,.40,.56,.72,.89)
    ]
    active_controls=sum(
        130<=r<=160 and 110<=g<=140 and 95<=b<=125 and r>g>b
        for r,g,b in controls)
    if active_controls>=5:
        return 'gameplay'
    # Exact CI run 38368800892: Level 2's real story/dialogue screen has
    # black cinematic bars and a bright central dialogue sheet, plus purple
    # accents that previously tripped the generic Level Select color check.
    # Keep this distinct from gameplay so ordinary story-advance inputs can
    # be bounded and verified, never mistaken for repeated level selection.
    def dark_at(x,y):
        return max(im.getpixel((int(w*x),int(h*y)))) < 24
    if (dark_at(.25,.08) and dark_at(.75,.08)
            and dark_at(.25,.93) and dark_at(.75,.93)
            and min(im.getpixel((int(w*.50),int(h*.28)))) > 220):
        return 'cutscene'
    green=_count(im,(.30,.03,.67,.39),lambda r,g,b:g>80 and g>r*1.2 and g>b*1.3)
    red=_count(im,(.68,.10,.92,.65),lambda r,g,b:r>120 and r>g*1.4 and r>b*1.3)
    purple=_count(im,(.15,.12,.90,.82),lambda r,g,b:r>70 and b>r and r>g*1.2 and b>g*1.2)
    if green>int(w*h*.025):
        return 'title' if red>int(w*h*.0005) else 'menu'
    if purple>int(w*h*.005):
        return 'level_select'
    return 'unknown'


def advance_cutscene_to_gameplay(observe, action, wait, attempts=8):
    """Advance an actual rendered story using ordinary taps, never blind taps.

    This is navigation, not a gameplay-completion assertion. Unexpected or
    unclassified screens fail closed without another input.
    """
    for _ in range(attempts):
        label=observe()
        if label=='gameplay':
            return label
        if label=='cutscene':
            action()
            wait()
            continue
        if label=='unknown':
            raise RuntimeError('Unknown frame during cutscene; no blind action')
        raise RuntimeError(f'Unexpected frame during cutscene: {label}')
    label=observe()
    if label=='gameplay':
        return label
    raise RuntimeError(f'Cutscene did not reach gameplay in bounded steps: {label}')


def retry_level_select_transition(observe, action, wait, attempts=4):
    """Retry ONLY while the rendered frame is actually Level Select.

    Each action is an ordinary Android tap. Unknown/gameplay/cutscene frames
    receive no additional touches. The caller must separately verify the
    specific desired level from its observation stream, not infer victory.
    """
    for _ in range(attempts):
        label=observe()
        if label=='level_select':
            action()
            wait()
            continue
        if label=='unknown':
            # Pixel Launcher ANR/system dialogs can arrive AFTER the game
            # has reached Level Select. Do not tap uncertain frames.
            wait()
            continue
        if label in ('menu','title'):
            raise RuntimeError(f'Unexpected navigation regression: {label}')
        return label
    label=observe()
    if label=='level_select':
        raise RuntimeError('Level Select remains after bounded action attempts')
    if label=='unknown':
        raise RuntimeError('Unknown screen remains after bounded observation attempts')
    if label in ('menu','title'):
        raise RuntimeError(f'Unexpected navigation regression: {label}')
    return label
