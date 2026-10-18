#!/usr/bin/env python3
"""Locate ONLY Android's exact immersive onboarding confirmation control.

Callers may tap the returned screen center; never click arbitrary Android
prompts or application UI. Unknown/ambiguous prompts remain untouched.
"""
import argparse
from pathlib import Path
import re
import xml.etree.ElementTree as ET

RECT = re.compile(r'^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$')


def find_dismiss_center(xml_text):
    root = ET.fromstring(xml_text)
    has_intro = any(n.get('text') == 'Viewing full screen' and n.get('package') in ('android', None)
                    for n in root.iter())
    if not has_intro:
        return None
    matches = [n for n in root.iter() if n.get('text') == 'Got it' and
               n.get('clickable') == 'true' and n.get('resource-id') in ('android:id/ok', None)]
    if len(matches) != 1:
        return None
    bounds = RECT.fullmatch(matches[0].get('bounds', ''))
    if bounds is None:
        return None
    left, top, right, bottom = map(int, bounds.groups())
    if not (left < right and top < bottom):
        return None
    return ((left + right) // 2, (top + bottom) // 2)


if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('uiautomator_xml', type=Path)
    a = p.parse_args()
    pos = find_dismiss_center(a.uiautomator_xml.read_text(encoding='utf-8'))
    print('NONE' if pos is None else f'{pos[0]} {pos[1]}')
