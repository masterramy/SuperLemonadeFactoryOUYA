#!/usr/bin/env python3
"""Isolated AIR compiler smoke for 3 world-asset GraphicsMode embed selectors.
This generates QA-only pixels; art acceptance and exact canonical ZIP build
are independent requirements and are NEVER claimed by this compile test.
"""
from pathlib import Path
from PIL import Image

R=Path(__file__).resolve().parents[2]
triples=[
 (1,"CrateWithLabel","LargeCrate",(80,60)),
 (2,"level2_tank","Registry",(100,187)),
 (3,"level3_desk1","Registry",(108,70)),
]
for world,name,_,size in triples:
    orig=R/f"data/level{world}/{name}.png"
    target=R/f"data/remastered/level{world}/{name}.png"
    with Image.open(orig) as original:
        im=original.convert("RGBA")
    assert im.size==size
    pix=im.load()
    for y in range(im.height):
        for x in range(im.width):
            red,green,blue,alpha=pix[x,y]
            if alpha:
                pix[x,y]=(min(255,red+4),min(255,green+5),max(0,blue-2),alpha)
    target.parent.mkdir(parents=True,exist_ok=True)
    im.save(target)
    with Image.open(target) as test:
        assert test.size==size and test.convert("RGBA").getchannel("A").tobytes()==Image.open(orig).convert("RGBA").getchannel("A").tobytes()

def replace_once(file, old, new):
    p=R/file
    data=p.read_text()
    if data.count(old)!=1:
        raise ValueError(f"QA original source anchor changed: {file!s}: {old[:65]}")
    p.write_text(data.replace(old,new))

replace_once("src/LargeCrate.as",
    '[Embed(source="../data/level1/CrateWithLabel.png")] private var ImgCrate:Class;',
    '[Embed(source="../data/level1/CrateWithLabel.png")] private var ImgCrate:Class;\n'
    '        [Embed(source="../data/remastered/level1/CrateWithLabel.png")] private var ImgCrateRemastered:Class;')
replace_once("src/LargeCrate.as",
    'loadGraphic(ImgCrate, true, false, 80,60);',
    'loadGraphic(GraphicsMode.choose(ImgCrate, ImgCrateRemastered), true, false, 80,60);')
for world,name in ((2,"level2_tank"),(3,"level3_desk1")):
    orig=f'[Embed(source = "../data/level{world}/{name}.png") ] public static var {name}:Class;'
    newer=orig+f'\n            [Embed(source = "../data/remastered/level{world}/{name}.png") ] public static var {name}Remastered:Class;'
    replace_once("src/Registry.as",orig,newer)
    orig=f'else if (toLoad == "{name}") img = Registry.{name};'
    newer=f'else if (toLoad == "{name}") img = GraphicsMode.choose(Registry.{name}, Registry.{name}Remastered);'
    replace_once("src/PlayState.as",orig,newer)
print("PASS isolated new-embed AIR compilation inputs for three worlds; candidate pixels here are smoke-only")
