"""P0 game-ready export (B2 approved): mold, cakes, cell-state overlays, padded cookie tiles.
Writes res://assets/board/ at 1x (128 px) and @2x (256 px). Original art, generated here."""
import os, json, math, numpy as np
from PIL import Image, ImageDraw, ImageFilter
from ttdraw import rgb, shade, UI, REG, pattern_layer, font, icon
from ttb2 import cake, mold, CAKE_FOR_REGION
OUT="/workspace/tea-and-tarts/assets/board"; os.makedirs(OUT,exist_ok=True)
INK=UI["earl_grey_ink"]; CREAM="#FFF8EC"; CHERRY=UI["cherry_alert"]
SIZES={"":128,"@2x":256}
written=[]
def save(im,name,suf):
    p=f"{OUT}/{name}{suf}.png"; im.save(p,optimize=True); written.append(p)

def tile_face(k,S,SS=3):
    B=S*SS; name,hx,pat=REG[k]
    face=Image.new("RGBA",(B,B),rgb(hx))
    unit=max(6,int(B*0.29))
    face.alpha_composite(pattern_layer(pat,B,B,unit,shade(hx,0.82)[:3]+(150,),rng_seed=k+3))
    hl=Image.new("RGBA",(B,B),(0,0,0,0)); hd=ImageDraw.Draw(hl)
    hd.rounded_rectangle([B*0.07,B*0.06,B*0.72,B*0.18],radius=B*0.06,fill=(255,255,255,60))
    face.alpha_composite(hl.filter(ImageFilter.GaussianBlur(B*0.04)))
    # soft bottom bevel in seam tint (padded look)
    bev=Image.new("RGBA",(B,B),(0,0,0,0)); bd=ImageDraw.Draw(bev)
    bd.rounded_rectangle([0,B*0.9,B,B],radius=B*0.05,fill=shade(hx,0.88)[:3]+(170,))
    face.alpha_composite(bev.filter(ImageFilter.GaussianBlur(B*0.02)))
    m=Image.new("L",(B,B),0); ImageDraw.Draw(m).rounded_rectangle([0,0,B-1,B-1],radius=B*0.22,fill=255)
    face.putalpha(m)
    return face.resize((S,S),Image.LANCZOS)

def conflict_overlay(S,SS=3,part="under"):
    B=S*SS; im=Image.new("RGBA",(B,B),(0,0,0,0)); d=ImageDraw.Draw(im)
    hl=Image.new("RGBA",(B,B),(0,0,0,0)); hd=ImageDraw.Draw(hl)
    for t in range(-B,B*2,int(B/6)): hd.line([(t,0),(t-B,B)],fill=rgb(CHERRY,110),width=int(B*0.05))
    m=Image.new("L",(B,B),0); ImageDraw.Draw(m).rounded_rectangle([0,0,B-1,B-1],radius=B*0.22,fill=255)
    hl.putalpha(Image.fromarray(np.minimum(np.array(hl.split()[3]),np.array(m)))); im.alpha_composite(hl)
    # dashed cherry ring (D-10 "dashed berry outline")
    lw=int(B*0.075); r=B*0.22; x0=y0=lw/2; x1=y1=B-lw/2
    ring=Image.new("L",(B,B),0); ImageDraw.Draw(ring).rounded_rectangle([x0,y0,x1,y1],radius=r,outline=255,width=lw)
    ang=np.arctan2(np.arange(B)[:,None]-B/2, np.arange(B)[None,:]-B/2)
    dash=((np.degrees(ang)+180)%30<19).astype(np.uint8)*255
    ring=Image.fromarray(np.minimum(np.array(ring),dash))
    rl=Image.new("RGBA",(B,B),rgb(CHERRY)); rl.putalpha(ring); im.alpha_composite(rl)
    if part=="badge": im=Image.new("RGBA",(B,B),(0,0,0,0))
    else: return im.resize((S,S),Image.LANCZOS)
    d=ImageDraw.Draw(im); br=B*0.17; bx,by=B-br*1.0,br*1.0
    d.ellipse([bx-br,by-br,bx+br,by+br],fill=rgb(CHERRY),outline=rgb(CREAM),width=int(br*0.18))
    d.text((bx,by),"!",fill=rgb(CREAM),font=font("ui",br*1.5,800),anchor="mm")
    return im.resize((S,S),Image.LANCZOS)

def solved_overlay(S,SS=3,part="under"):
    B=S*SS; im=Image.new("RGBA",(B,B),(0,0,0,0))
    gl=Image.new("RGBA",(B,B),(0,0,0,0)); ImageDraw.Draw(gl).ellipse([B*0.04,B*0.04,B*0.96,B*0.96],fill=rgb(UI["toasted_crust"],150))
    im.alpha_composite(gl.filter(ImageFilter.GaussianBlur(B*0.08)))
    if part=="badge": im=Image.new("RGBA",(B,B),(0,0,0,0))
    else: return im.resize((S,S),Image.LANCZOS)
    d=ImageDraw.Draw(im); br=B*0.15; bx,by=B-br*1.0,B-br*1.0
    d.ellipse([bx-br,by-br,bx+br,by+br],fill=rgb(UI["sage_leaf"]),outline=rgb(CREAM),width=int(br*0.15))
    icon(d,"check",bx,by,br*0.75,rgb(CREAM),int(br*0.3))
    return im.resize((S,S),Image.LANCZOS)

def given_plate(S,SS=3):
    B=S*SS; im=Image.new("RGBA",(B,B),(0,0,0,0)); d=ImageDraw.Draw(im)
    sh=Image.new("RGBA",(B,B),(0,0,0,0)); ImageDraw.Draw(sh).ellipse([B*0.08,B*0.12,B*0.92,B*0.96],fill=rgb(INK,60))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(B*0.03)))
    d.ellipse([B*0.06,B*0.06,B*0.94,B*0.94],fill=rgb("#FFFDF8"),outline=rgb(INK),width=int(B*0.025))
    d.ellipse([B*0.17,B*0.17,B*0.83,B*0.83],outline=rgb("#E7B9C2"),width=int(B*0.02))
    return im.resize((S,S),Image.LANCZOS)

for suf,S in SIZES.items():
    save(mold(S),"mold",suf)
    save(cake("berry",S),"cake_berry",suf)
    for k in ["lemon","victoria","scone","bakewell","chocolate","macaron","custard","apricot"]:
        save(cake(k,S),f"cake_{k}",suf)
    save(conflict_overlay(S),"overlay_conflict",suf)          # under the cake: hatch + dashed ring
    save(conflict_overlay(S,part="badge"),"badge_conflict",suf) # over the cake: "!" badge
    save(solved_overlay(S),"overlay_solved",suf)              # under the cake: toasted glow
    save(solved_overlay(S,part="badge"),"badge_solved",suf)     # over the cake: sage tick
    save(given_plate(S),"given_plate",suf)
    for k,(name,hx,pat) in enumerate(REG):
        save(tile_face(k,S),f"tile_{k}_{name}",suf)

# preview sheet (not shipped): composite states on each tile, in art/
prev=Image.new("RGBA",(9*140+20,5*140+20),rgb("#FBF4EE"))
for k in range(9):
    t=Image.open(f"{OUT}/tile_{k}_{REG[k][0]}.png")
    for j,st in enumerate(["empty","mold","cake","conflict","solved"]):
        c=t.copy()
        if st=="mold": m=Image.open(f"{OUT}/mold.png").resize((77,77),Image.LANCZOS); c.alpha_composite(m,(25,25))
        if st in("cake","conflict","solved"):
            if st=="solved": c.alpha_composite(Image.open(f"{OUT}/overlay_solved.png"))
            if st=="conflict": c.alpha_composite(Image.open(f"{OUT}/overlay_conflict.png"))
            ck=Image.open(f"{OUT}/cake_berry.png").resize((112,112),Image.LANCZOS); c.alpha_composite(ck,(8,9))
            if st=="conflict": c.alpha_composite(Image.open(f"{OUT}/badge_conflict.png"))
            if st=="solved": c.alpha_composite(Image.open(f"{OUT}/badge_solved.png"))
        prev.alpha_composite(c,(10+k*140,10+j*140))
prev.convert("RGB").save("/workspace/tea-and-tarts/art/p0_preview.png")
tot=sum(os.path.getsize(p) for p in written)
json.dump({"files":[os.path.relpath(p,"/workspace/tea-and-tarts") for p in written],"bytes":tot},open("/workspace/tea-and-tarts/art/tools/p0_files.json","w"),indent=1)
print(len(written),"files",tot,"bytes")
