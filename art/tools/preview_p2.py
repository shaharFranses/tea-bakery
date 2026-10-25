import json
from PIL import Image, ImageDraw
A="/workspace/tea-and-tarts/assets"
L=lambda p: Image.open(f"{A}/{p}").convert("RGBA")
sheet=Image.new("RGBA",(2200,1500),(246,227,222,255))
for i in range(9):
    c=L(f"recipes/recipe_{i+1}@2x.png" if i<8 else "recipes/recipe_locked@2x.png")
    sheet.alpha_composite(c.resize((240,320)),(20+i*242,20))
for i in range(8):
    import glob; f=sorted(glob.glob(f"{A}/decor/decor_{i+1}_*@2x.png"))[0]
    sheet.alpha_composite(Image.open(f).convert("RGBA"),(20+i*200,370))
# shelf with all decor at @2x
sl=json.load(open(f"{A}/decor/shelf_slots.json"))
sh=Image.new("RGBA",(720,320),(0,0,0,0)); sh.alpha_composite(L("decor/shelf_counter@2x.png")); sh.alpha_composite(L("decor/shelf_gingham_drape@2x.png"))
for k,s in sl["slots"].items():
    if "x" not in s: continue
    f=sorted(glob.glob(f"{A}/decor/decor_{k}_*@2x.png"))[0]; sz=s["size"]*2
    im=Image.open(f).convert("RGBA").resize((sz,sz),Image.LANCZOS); sh.alpha_composite(im,(int(s["x"]*2-sz/2),int(sl["baseline_y"]*2-sz*0.94)))
sh.alpha_composite(L("decor/shelf_bunting_garland@2x.png"))
sheet.alpha_composite(sh,(20,590))
wb=Image.open(f"{A}/backdrop/backdrop_landscape.webp").convert("RGBA").resize((960,540)); sheet.alpha_composite(wb,(760,580))
pb=Image.open(f"{A}/backdrop/backdrop_portrait.webp").convert("RGBA").resize((400,866)); sheet.alpha_composite(pb,(1760,580))
sheet.save("/workspace/tea-and-tarts/art/p2_preview.png"); sheet.resize((1100,750)).save("/tmp/tt_p2_a.png")
