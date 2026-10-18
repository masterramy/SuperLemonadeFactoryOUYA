#!/usr/bin/env python3
"""Fail-closed visual guard for genuine Android Options touch captures.

Checks pixels in immutable UI-label boxes; it is deliberately *not* an
independent proof that every button is functionally correct. Archive the raw
PNGs and inspect them before making the final Android UI acceptance claim.

Screens required: 01_menu, 02_options_classic, 03_graphics_toggled,
04_graphics_restored, 05_blank_touch. Requires screenshot native 1920x1080.
"""
import argparse
import hashlib
from pathlib import Path
from PIL import Image, ImageChops
import xml.etree.ElementTree as ET

FILES = ('01_menu.png', '02_options_classic.png', '03_graphics_toggled.png',
         '04_graphics_restored.png', '05_blank_touch.png')
# Flixel viewport 640x360 rendered at integer 3x onto 1920x1080.
# Actual graphics status label begins at (xPos1+button.width, ySmallPos6).
GRAPHICS_LABEL = (655, 625, 1420, 686)
DELETE_LABEL = (655, 535, 1420, 596)


def diff_pixels(a, b, box, min_channel_delta=35):
    a = a.crop(box).convert('RGB'); b = b.crop(box).convert('RGB')
    if a.size != b.size: raise ValueError('different crop dimensions')
    delta = ImageChops.difference(a,b)
    return sum(1 for p in delta.getdata() if max(p)>=min_channel_delta)


def confirm_no_dialogs(folder):
    for p in sorted(folder.glob('*.xml')):
        # Actual platform accessibility dump, not OCR or guessing from screenshots.
        root = ET.parse(p).getroot()
        contents = ' '.join((node.attrib.get('text','')+' '+node.attrib.get('content-desc','')).lower()
                            for node in root.iter())
        if "isn't responding" in contents or "is not responding" in contents or 'system ui isn' in contents:
            raise ValueError(f'ANDROID_SYSTEM_ANR_DIALOG: {p.name}')


def verify(folder):
    confirm_no_dialogs(folder)
    shots = {}
    for name in FILES:
        p=folder/name
        if not p.is_file(): raise ValueError(f'MISSING_CAPTURE: {name}')
        image=Image.open(p).convert('RGB')
        if image.size!=(1920,1080): raise ValueError(f'WRONG_VIEWPORT: {name} {image.size}')
        shots[name]=image
    raws=[hashlib.sha256((folder/n).read_bytes()).hexdigest() for n in FILES]
    if len(set(raws))<len(raws): raise ValueError('IDENTICAL_FULL_FRAMES: touches not proven')
    before,toggled,restored,blank = [shots[n] for n in FILES[1:]]
    changed = diff_pixels(before,toggled,GRAPHICS_LABEL)
    restored_error = diff_pixels(before,restored,GRAPHICS_LABEL)
    blank_error = diff_pixels(restored,blank,GRAPHICS_LABEL)
    deleted = max(diff_pixels(before,other,DELETE_LABEL) for other in (toggled,restored,blank))
    if changed < 160: raise ValueError(f'GRAPHICS_LABEL_DID_NOT_CHANGE: {changed} pixels')
    # More than 1,500 inconsistent pixels after toggling back indicate a wrong UI
    # state or animation/dialog. Never silently call such a run a PASS.
    if restored_error > 1500: raise ValueError(f'GRAPHICS_LABEL_NOT_RESTORED: {restored_error}')
    if blank_error > 1500: raise ValueError(f'BLANK_TOUCH_MUTATED_GRAPHICS: {blank_error}')
    if deleted > 1500: raise ValueError(f'POSSIBLE_DELETE_TEXT_MUTATION: {deleted}')
    return dict(changed_pixels=changed, restored_difference=restored_error,
                blank_difference=blank_error, delete_label_max_difference=deleted)


if __name__=='__main__':
    p=argparse.ArgumentParser()
    p.add_argument('capture_dir',type=Path)
    a=p.parse_args()
    try:
        print('PIXEL_GUARD_PASS (not human visual acceptance):',verify(a.capture_dir))
    except (ValueError, OSError, ET.ParseError) as error:
        p.exit(1,'PIXEL_GUARD_FAIL: '+str(error)+'\n')
