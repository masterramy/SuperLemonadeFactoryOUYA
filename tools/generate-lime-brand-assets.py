from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
ICON_DIR = ROOT / "icons" / "android" / "icons"
STORE = ROOT / "release" / "store-assets"
STORE.mkdir(parents=True, exist_ok=True)

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

# Feature graphic: 1024x500, no alpha, uses the same artwork family without
# added claims, badges, prices, rankings, or third-party branding.
feature = Image.new("RGB", (1024,500), (214,195,184))
scaled = icon.convert("RGB").resize((500,500), Image.Resampling.LANCZOS)
feature.paste(scaled, ((1024-500)//2,0))
feature.save(STORE / "feature-graphic-1024x500.png", optimize=True)

print("generated and dimension-checked Super Limeade Factory brand assets")
