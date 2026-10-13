"""Pixel-exact regression for the in-game Super Limeade Factory title."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
source = Image.open(DATA / "logo.png").convert("RGBA")
result = Image.open(DATA / "logo_limeade.png").convert("RGBA")
assert source.size == result.size == (228, 116)

def white_pixels(im, row_start, row_end):
    return {(x, y) for y in range(row_start, row_end) for x in range(im.width)
            if min(im.getpixel((x, y))[:3]) >= 250 and im.getpixel((x, y))[3] == 255}

assert white_pixels(source, 21, 40) == white_pixels(result, 21, 40)
assert white_pixels(source, 75, 92) == white_pixels(result, 75, 92)

glyph_source = {"L": (41, 51), "E": (59, 69), "M": (77, 91),
                "A": (142, 155), "D": (163, 176)}
expected = set()
x = (228 - (11+11+15+11+14+14+11+6*7)) // 2
for ch in "LIMEADE":
    if ch == "I":
        w = 11
        for yy in range(17):
            for xx in range(11):
                if yy < 3 or yy >= 14 or 4 <= xx <= 6:
                    expected.add((x+xx, 49+yy))
    else:
        lo, hi = glyph_source[ch]
        w = hi-lo+1
        for yy in range(17):
            for xx in range(w):
                if min(source.getpixel((lo+xx, 49+yy))[:3]) >= 250:
                    expected.add((x+xx, 49+yy))
    x += w+7

actual = {p for p in white_pixels(result, 43, 70) if 25 <= p[0] < 204}
assert actual == expected, (
    f"bad lettering: {len(expected-actual)} missing; {len(actual-expected)} extra"
)
assert min(y for _,y in actual) == 49 and max(y for _,y in actual) == 65
assert min(x for x,_ in actual) == 49 and max(x for x,_ in actual) == 177
print("PASS: native pixel strokes, height, 7px tracking, baseline and untouched neighboring lines")
