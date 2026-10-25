"""Two cover concepts for the Growth A/B test (CG 1920x1080 landscape notext). Built from shipped sprites only.
Dashed box = where the title goes later (no text, no logo). Output: art/covers/concept_{A,B}_1920x1080.jpg + _800x800 crop."""
import math, numpy as np
from PIL import Image, ImageDraw, ImageFilter
from ttdraw import gen_board
from ttb2 import render_board_b2
A="/workspace/tea-and-tarts/assets"; OUT="/workspace/tea-and-tarts/art/covers"
def L(p,s=None):
    im=Image.open(f"{A}/{p}").convert("RGBA")
    return im.resize(s if isinstance(s,tuple) else (s,s),Image.LANCZOS) if s else im
def shadow(im,sp,xy,r=18,a=90,off=(10,16)):
    m=sp.split()[3].point(lambda v:int(v*a/255)); sh=Image.new("RGBA",sp.size,(67,40,58,0)); sh.putalpha(m)
    big=Image.new("RGBA",im.size,(0,0,0,0)); big.alpha_composite(sh,(xy[0]+off[0],xy[1]+off[1])); im.alpha_composite(big.filter(ImageFilter.GaussianBlur(r)))
    im.alpha_composite(sp,xy)
def dashed(d,box,col=(67,40,58,150),w=4,dash=22):
    x0,y0,x1,y1=box
    for x in range(x0,x1,dash*2): d.line([(x,y0),(min(x+dash,x1),y0)],fill=col,width=w); d.line([(x,y1),(min(x+dash,x1),y1)],fill=col,width=w)
    for y in range(y0,y1,dash*2): d.line([(x0,y),(x0,min(y+dash,y1))],fill=col,width=w); d.line([(x1,y),(x1,min(y+dash,y1))],fill=col,width=w)
def board_img(n,seed,size,cakes=True):
    reg,sol=gen_board(n,seed); b=render_board_b2(n,reg,{},size); cell=size/n
    if cakes:
        for (r,c) in sol[: n]:
            ck=L("board/cake_berry@2x.png",int(cell)); b.alpha_composite(ck,(int(c*cell),int(r*cell+cell*0.02)))
    fr=L("board/tray_frame_solved@2x.png")
    # 9-slice frame around the board
    pad=int(size*0.045); W=size+2*pad; out=Image.new("RGBA",(W,W+4),(0,0,0,0)); m=64
    xs=[0,m,192-m,192]; xd=[0,m,W-m,W]
    for i in range(3):
        for j in range(3):
            tw,th=xd[i+1]-xd[i],xd[j+1]-xd[j]
            out.alpha_composite(fr.crop((xs[i],xs[j],xs[i+1],xs[j+1])).resize((tw,th)),(xd[i],xd[j]))
    out.alpha_composite(b,(pad,pad)); return out,sol,cell,pad
def concept_A():   # "Golden tray": the solved board is the hero, steam rising, tea things beside it
    bg=Image.open(f"{A}/backdrop/backdrop_landscape.webp").convert("RGBA").filter(ImageFilter.GaussianBlur(6))
    im=bg.copy(); im.alpha_composite(Image.new("RGBA",im.size,(251,241,236,60)))
    b,sol,cell,pad=board_img(6,7,620); x0,y0=650,300
    bb=b.rotate(-6,resample=Image.BICUBIC,expand=True); shadow(im,bb,(x0,y0))
    for (r,c) in sol[:3]:
        st=L("board/steam_puff@2x.png",int(cell*1.4))
        im.alpha_composite(st,(int(x0+60+pad+c*cell-cell*0.2),int(y0+20+pad+r*cell-cell*1.1)))
    shadow(im,L("decor/decor_2_cake_stand@2x.png",420),(1230,470))
    shadow(im,L("decor/decor_1_teapot@2x.png",320),(380,690))
    shadow(im,L("board/cake_victoria@2x.png",200),(1180,820))
    d=ImageDraw.Draw(im); dashed(d,(560,60,1360,250))
    return im.convert("RGB")
def concept_B():   # "Recipe book table": fanned recipe cards + a small board in play on a gingham cloth
    im=Image.new("RGBA",(1920,1080),(246,227,222,255))
    bg=Image.open(f"{A}/backdrop/backdrop_landscape.webp").convert("RGBA").filter(ImageFilter.GaussianBlur(8)).crop((0,0,1920,560))
    im.alpha_composite(bg,(0,0))
    cloth=Image.new("RGBA",(1920,560),(255,253,248,255)); cd=ImageDraw.Draw(cloth)
    for x in range(0,1920,48): cd.rectangle([x,0,x+24,560],fill=(184,223,166,120))
    for y in range(0,560,48): cd.rectangle([0,y,1920,y+24],fill=(184,223,166,100))
    im.alpha_composite(cloth,(0,520))
    for i,(n,ang) in enumerate(((3,14),(5,4),(8,-8))):
        c=L(f"recipes/recipe_{n}@2x.png",(384,512)).rotate(ang,resample=Image.BICUBIC,expand=True); shadow(im,c,(1060+i*150,330+abs(ang)*4))
    b,sol,cell,pad=board_img(5,3,470); bb=b.rotate(4,resample=Image.BICUBIC,expand=True); shadow(im,bb,(520,380))
    shadow(im,L("decor/decor_8_copper_kettle@2x.png",300),(180,560))
    shadow(im,L("decor/decor_4_doily_teacups@2x.png",260),(960,780))
    shadow(im,L("board/cake_bakewell@2x.png",150),(400,850))
    d=ImageDraw.Draw(im); dashed(d,(560,50,1360,240))
    return im.convert("RGB")
for name,fn in (("A",concept_A),("B",concept_B)):
    im=fn(); im.resize((960,540),Image.LANCZOS).save(f"{OUT}/concept_{name}_960x540.jpg",quality=86)
    sq=im.crop((420,0,1500,1080)).resize((540,540),Image.LANCZOS); sq.save(f"{OUT}/concept_{name}_square_540.jpg",quality=86)
    im.save(f"/tmp/tt_cover_{name}.jpg",quality=85)
print("ok")
