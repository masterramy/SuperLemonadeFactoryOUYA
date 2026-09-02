import sys
from PIL import Image, ImageChops

a = Image.open(sys.argv[1]).convert('RGB')
b = Image.open(sys.argv[2]).convert('RGB')
w, h = a.size
d = ImageChops.difference(a, b).convert('L')
hist = d.histogram()
total = sum(hist)
changed = total - hist[0]
print(f"{w},{h},{changed / total if total else 0:.6f}")
