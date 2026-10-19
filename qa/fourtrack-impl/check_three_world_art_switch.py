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
# The canonical 1369-source implementation resolves approved map props once,
# after the authored item's original mapping. Compile the *same* source shape
# here, but never claim the QA-generated pixels are the canonical art.
replace_once("src/GraphicsMode.as",
    "        public static function choose(classicArt:Class, enhancedArt:Class):Class",
    "        public static function chooseForItem(itemName:String, classicArt:Class):Class\n"
    "        {\n"
    "            return RemasteredItemCatalog.choose(itemName, classicArt);\n"
    "        }\n"
    "        public static function choose(classicArt:Class, enhancedArt:Class):Class")
replace_once("src/PlayState.as",
    "\t\t\tif (item.@width!=undefined) {",
    "\t\t\timg = GraphicsMode.chooseForItem(toLoad, img);\n"
    "\t\t\tif (item.@width!=undefined) {")
catalog="""// Staged QA compiler mirror of canonical generated RemasteredItemCatalog.as.
package
{
    public class RemasteredItemCatalog
    {
        public static function choose(itemName:String, classicArt:Class):Class
        {
            if (!GraphicsMode.remastered) return classicArt;
            switch (itemName)
            {
                case "level2_tank":
                    return Registry.level2_tankRemastered == null ? classicArt : Registry.level2_tankRemastered;
                case "level3_desk1":
                    return Registry.level3_desk1Remastered == null ? classicArt : Registry.level3_desk1Remastered;
                default: return classicArt;
            }
        }
    }
}
"""
(R/"src/RemasteredItemCatalog.as").write_text(catalog)
assert (R/"src/RemasteredItemCatalog.as").is_file()
print("PASS staged AIR compiler mirror of 1369 catalog selection with 3 QA-only art props")
