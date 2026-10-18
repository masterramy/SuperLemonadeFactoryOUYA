#!/usr/bin/env python3
"""Prepare/validate exact-source artwork; never call copied pixels 'remastered'.

Usage: python tools/postlaunch/prepare_semantic_remaster.py stage OUTPUT_DIRECTORY
       python tools/postlaunch/prepare_semantic_remaster.py validate OUTPUT_DIRECTORY
No game source art or shipped production version is edited by this tool.
"""
from __future__ import annotations
import argparse, csv, hashlib, json, shutil
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]


def inventory(root:Path):
    rows = list(csv.DictReader((root/'qa/postlaunch/REMASTER_ASSET_PRIORITY.csv').open(encoding='utf-8')))
    if len(rows) != 109 or len({r['image'] for r in rows}) != 109:
        raise ValueError('Expected exact 109 unique source-used images; regenerate verified inventory before changing counts')
    return rows


def stage_remaster(root:Path,out:Path):
    rows=inventory(root)
    manifest=[]
    for r in rows:
        name=r['image']; source=(root/name).resolve()
        if not source.is_file() or not source.is_relative_to(root.resolve()):
            raise ValueError(f'Unsafe/missing source asset {name}')
        with Image.open(source) as im:
            dims=im.size
        if dims != (int(r['width']),int(r['height'])):
            raise ValueError(f'Stale source dimension metadata {name}: {dims}')
        target=out/'originals'/name
        target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(source,target)
        manifest.append(dict(priority=r['priority'],category=r['category'],path=name,dimensions=list(dims),source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),status='AWAITING_SEMANTIC_REDRAW'))
    mapping=json.loads((root/'qa/postlaunch/CHARACTER_REMASTER_ANIMATION_MAP.json').read_text(encoding='utf-8'))
    source=Image.open(root/mapping['original_atlas']).convert('RGBA')
    indices=[int(it['frame']) for it in mapping['referenced_frame_geometry']]
    if len(indices)!=69 or len(set(indices))!=69:raise ValueError('Animation frame map not the recorded 69 used slots')
    frame_dir=out/'frames/original';frame_dir.mkdir(parents=True,exist_ok=True)
    fw,fh=mapping['frame_size'];cols=mapping['grid'][0]
    for i in sorted(indices):
        x=i%cols*fw; y=i//cols*fh
        source.crop((x,y,x+fw,y+fh)).save(frame_dir/f'frame_{i:03d}.png')
    document={
        'ready':False,'status':'REFERENCE_AND_EMPTY_CANDIDATE_WORKSPACE_NOT_REMASTERED',
        'source_assets':len(manifest),'referenced_animation_frames':len(indices),
        'candidate_dir':'candidate/ (empty until an artist supplies authentic redraws)',
        'originals_dir':'originals/ (immutable source copies)',
        'acceptance':'All 109 candidate paths exist at exact original dimensions; every animation slot and world renders in Android; license preserved',
        'assets':manifest
    }
    out.mkdir(parents=True,exist_ok=True)
    (out/'manifest.json').write_text(json.dumps(document,indent=2)+'\n',encoding='utf-8')
    return {'total_assets':len(manifest),'frame_count':len(indices),'ready':False}


def validate_remaster(root:Path,out:Path):
    manifest_file=out/'manifest.json'
    if not manifest_file.exists(): return {'ready':False,'issues':['Missing staged manifest']}
    manifest=json.loads(manifest_file.read_text(encoding='utf-8'))
    issues=[]
    expected=manifest.get('assets') or []
    if len(expected)!=109:issues.append('Missing source inventory, expected 109 assets')
    for entry in expected:
        candidate=out/'candidate'/entry['path']
        if not candidate.is_file():
            issues.append('missing candidate: '+entry['path']);continue
        try:
            with Image.open(candidate) as im:
                if list(im.size)!=entry['dimensions']:
                    issues.append('wrong dimensions: '+entry['path'])
                if im.mode not in ('RGBA','RGB','P','LA'):
                    issues.append('unsupported pixels: '+entry['path'])
        except Exception:
            issues.append('not a valid image: '+entry['path'])
    # Automatic geometry completion does NOT imply the art is actually improved.
    return {'ready':len(issues)==0,'geometry_ready_only':len(issues)==0,'human_visual_acceptance':False,'issues':issues}

if __name__ == '__main__':
    cli=argparse.ArgumentParser();cli.add_argument('action',choices=['stage','validate']);cli.add_argument('output',type=Path)
    a=cli.parse_args()
    result=stage_remaster(ROOT,a.output) if a.action=='stage' else validate_remaster(ROOT,a.output)
    print(json.dumps({k:(v[:10] if isinstance(v,list) else v) for k,v in result.items()},indent=2))
    if a.action=='validate' and not result['ready']: raise SystemExit(1)
