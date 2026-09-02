import csv
from PIL import Image, ImageDraw

rows = list(csv.DictReader(open('boundaries/metrics.csv', newline='')))
assert len(rows) == 9, len(rows)
sheet = Image.new('RGB', (1200, 1890), 'black')
for i, row in enumerate(rows):
    tag = f"{int(row['case']):02d}-{row['description']}"
    for j, suffix in enumerate(('before', 'after')):
        im = Image.open(f"boundaries/{tag}-{suffix}.png").convert('RGB')
        im.thumbnail((590, 180))
        x, y = j * 600, i * 210
        sheet.paste(im, (x + (590 - im.width) // 2, y))
        ImageDraw.Draw(sheet).text((x + 5, y + 184), f"{row['case']} {suffix}: {row['description']}", fill='white')
sheet.save('boundaries/boundary-contact-sheet.jpg', quality=90)
