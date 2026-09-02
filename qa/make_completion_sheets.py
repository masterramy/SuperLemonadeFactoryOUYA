import csv
from PIL import Image, ImageDraw

rows = list(csv.DictReader(open('qa-out/metrics.csv', newline='')))
assert len(rows) == 72, len(rows)
for mode, start in [('normal', 0), ('hardcore', 36)]:
    tiles = []
    for r in rows[start:start + 36]:
        tag = f"{int(r['index']):02d}-{r['mode']}-w{r['world']}-l{int(r['level']):02d}"
        im = Image.open(f"qa-out/screens/{tag}-complete.png").convert('RGB')
        im.thumbnail((390, 180))
        tile = Image.new('RGB', (400, 210), 'black')
        tile.paste(im, ((400 - im.width) // 2, 0))
        ImageDraw.Draw(tile).text((5, 184), f"{r['index']}/72 W{r['world']} L{r['level']} diff={r['diff_ratio']}", fill='white')
        tiles.append(tile)
    sheet = Image.new('RGB', (2400, 1260), 'black')
    for i, tile in enumerate(tiles):
        sheet.paste(tile, ((i % 6) * 400, (i // 6) * 210))
    sheet.save(f"qa-out/{mode}-completion-contact-sheet.jpg", quality=88)
