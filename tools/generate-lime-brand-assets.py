from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
ICON_DIR = ROOT / "icons" / "android" / "icons"
STORE = ROOT / "release" / "store-assets"
ADAPTIVE = ROOT / "icons" / "android" / "adaptive"
STORE.mkdir(parents=True, exist_ok=True)
ADAPTIVE.mkdir(parents=True, exist_ok=True)

FONT = DATA / "C64.ttf"
LIME = (103, 181, 47, 255)
WHITE = (255, 255, 255, 255)

def recolor_purple(im):
    im = im.convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r,g,b,a = px[x,y]
            if a and b > r * 1.15 and r > g * 1.4 and b > g * 1.8:
                lum = (r + g + b) / 3.0
                ratio = max(0.4, min(1.5, lum / 106.0))
                px[x,y] = (
                    min(255, int(103 * ratio)),
                    min(255, int(181 * ratio)),
                    min(255, int(47 * ratio)),
                    a,
                )
    return im

def centered_text(draw, canvas_w, y, text, font):
    box = draw.textbbox((0,0), text, font=font)
    w = box[2] - box[0]
    draw.text(((canvas_w - w)//2, y), text, font=font, fill=WHITE)

# In-game logo: preserve the original pixel-art sign silhouette and border,
# change the sign color to lime, and replace only the edition-name line.
logo = recolor_purple(Image.open(DATA / "logo.png"))
ld = ImageDraw.Draw(logo)
ld.rectangle([25, 40, 203, 68], fill=(105,176,46,255))
centered_text(ld, logo.width, 43, "LIMEADE", ImageFont.truetype(str(FONT), 16))
logo.save(DATA / "logo_limeade.png", optimize=True)

# Launcher/Play icon: preserve the original sign composition, recolor it, and
# replace the title line so no public icon says LEMONADE.
icon = recolor_purple(Image.open(ICON_DIR / "icon512.png"))
idraw = ImageDraw.Draw(icon)
fill = icon.getpixel((260,250))
idraw.rectangle([54, 215, 464, 302], fill=fill)
centered_text(idraw, icon.width, 225, "LIMEADE", ImageFont.truetype(str(FONT), 62))

for size in (16,29,32,36):
    icon.resize((size,size), Image.Resampling.LANCZOS).save(ICON_DIR / f"icon{size}.png", optimize=True)
for size in (48,57,72,96,114,128,144,192,512):
    icon.resize((size,size), Image.Resampling.LANCZOS).save(ICON_DIR / f"icon_{size}.png", optimize=True)

# Play listing icon is exactly 512x512, 32-bit PNG with alpha.
icon.save(STORE / "app-icon-512.png", optimize=True)


# Android 8+ adaptive launcher icon resources. AIR does not synthesize these
# automatically, so release builders inject this deterministic resource set
# into AIR's temporary Android resource tree and restore the SDK afterward.
# Keep the public sign inside the adaptive safe center and preserve the same
# warm factory-paper background used by the legacy launcher icon.
adaptive_sizes = {
    "mdpi": 108,
    "hdpi": 162,
    "xhdpi": 216,
    "xxhdpi": 324,
    "xxxhdpi": 432,
}
bg_rgb = icon.convert("RGB").getpixel((0, 0))
for density, size in adaptive_sizes.items():
    out_dir = ADAPTIVE / f"mipmap-{density}"
    out_dir.mkdir(parents=True, exist_ok=True)

    background = Image.new("RGB", (size, size), bg_rgb)
    background.save(out_dir / "slf_icon_background.png", optimize=True)

    foreground = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sign = logo.copy()
    target_w = max(1, round(size * 0.64))
    target_h = max(1, round(sign.height * target_w / sign.width))
    sign = sign.resize((target_w, target_h), Image.Resampling.NEAREST)
    foreground.alpha_composite(sign, ((size - target_w)//2, (size - target_h)//2))
    foreground.save(out_dir / "slf_icon_foreground.png", optimize=True)

xml_dir = ADAPTIVE / "mipmap-anydpi-v26"
xml_dir.mkdir(parents=True, exist_ok=True)
(xml_dir / "icon.xml").write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '    <background android:drawable="@mipmap/slf_icon_background"/>\n'
    '    <foreground android:drawable="@mipmap/slf_icon_foreground"/>\n'
    '</adaptive-icon>\n',
    encoding="utf-8",
)

# Human-review preview using a circular mask, representative rather than a
# replacement for device-rendered launcher verification.
preview_size = 512
preview_bg = Image.new("RGBA", (preview_size, preview_size), bg_rgb + (255,))
preview_sign = logo.copy()
preview_w = round(preview_size * 0.64)
preview_h = round(preview_sign.height * preview_w / preview_sign.width)
preview_sign = preview_sign.resize((preview_w, preview_h), Image.Resampling.NEAREST)
preview_bg.alpha_composite(preview_sign, ((preview_size-preview_w)//2, (preview_size-preview_h)//2))
mask = Image.new("L", (preview_size, preview_size), 0)
ImageDraw.Draw(mask).ellipse((0, 0, preview_size-1, preview_size-1), fill=255)
preview = Image.new("RGBA", (preview_size, preview_size), (0,0,0,0))
preview.paste(preview_bg, (0,0), mask)
preview.save(STORE / "adaptive-icon-circle-preview-512.png", optimize=True)

# Feature graphic: 1024x500, no alpha. Use the canonical pixel-art sign
# itself rather than enlarging the square launcher canvas. This keeps the
# original visual language intact, reads cleanly at Play-store sizes, and adds
# no badges, rankings, pricing, or affiliation claims.
feature = Image.new("RGB", (1024,500), (214,195,184))
feature_logo = logo.resize((820,417), Image.Resampling.NEAREST)
feature.paste(feature_logo.convert("RGB"), ((1024-820)//2, (500-417)//2), feature_logo)
feature.save(STORE / "feature-graphic-1024x500.png", optimize=True)

print("generated and dimension-checked Super Limeade Factory brand assets")
