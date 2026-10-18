"""Verify every *active* embedded asset path resolves with exact case (CI Linux-safe)."""
from pathlib import Path
import re
root=Path(__file__).resolve().parents[2]
missing=[];checked=0
for source in sorted((root/'src').rglob('*.as')):
    text=source.read_text(encoding='utf-8-sig',errors='replace')
    text=re.sub(r'/\*.*?\*/','',text,flags=re.S)
    text=re.sub(r'(?m)^\s*//.*$','',text)
    for m in re.finditer(r'\[Embed\s*\(\s*source\s*=\s*[\x27\"]([^\x27\"]+)[\x27\"]',text):
        checked+=1
        p=(source.parent/m.group(1)).resolve()
        if not p.is_file() or not p.is_relative_to(root):missing.append((str(source.relative_to(root)),m.group(1)))
print('Active embedded assets inspected:',checked,'missing:',len(missing))
for issue in missing:print('FAIL',*issue)
assert not missing
