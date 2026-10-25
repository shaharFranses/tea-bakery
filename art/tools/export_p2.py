"""P2 game-ready export (B2): 8 recipe cards (+ locked back), 8 decor pieces + counter shelf (+ shelf drape/bunting),
portrait + wide backdrops. Original art drawn here (Pillow). No text baked into any image (names are Godot labels)."""
import os, json, math, numpy as np
from PIL import Image, ImageDraw, ImageFilter
from ttdraw import rgb as _rgb, shade as _shade, UI, REG, pattern_layer, piece, font
from ttb2 import cake, _fluted, _finish
import ttland
ROOT="/workspace/tea-and-tarts"; A=f"{ROOT}/assets"
CARDS=f"{A}/recipes"; DECOR=f"{A}/decor"; BACK=f"{A}/backdrop"
for d_ in (CARDS,DECOR,BACK): os.makedirs(d_,exist_ok=True)
def rgb(h,a=255): return (tuple(h[:3])+(a,)) if isinstance(h,tuple) else _rgb(h,a)
def shade(h,f): return _shade(h if isinstance(h,str) else "#%02X%02X%02X"%h[:3],f)
INK=UI["earl_grey_ink"]; CREAM="#FFF8EC"; RASP=UI["raspberry_jam"]; SAGE=UI["sage_leaf"]
oc=rgb(INK); written=[]
def save(im,path,**kw): im.save(path,**kw); written.append(path)
def down(im,size): return im.resize(size,Image.LANCZOS)
REGD={n:(h,p) for n,h,p in REG}

# ---------------- extra dishes (256 canvas, same conventions as ttb2.cake) ----------------
def macaron_img(col,B=256):
    im=Image.new("RGBA",(B,B),(0,0,0,0)); d=ImageDraw.Draw(im); ow=10
    shell=rgb(col); foot=shade(col,0.80)
    d.chord([28,112,228,226],0,180,fill=shell,outline=oc,width=ow)
    d.rounded_rectangle([40,120,216,174],radius=22,fill=rgb("#FFF6E8"),outline=oc,width=8)
    d.rectangle([38,98,218,116],fill=foot)
    for x in range(46,214,21): d.ellipse([x-12,104,x+12,126],fill=foot)
    d.chord([28,30,228,170],180,360,fill=shell,outline=oc,width=ow)
    d.ellipse([70,52,130,78],fill=(255,255,255,130)); return im
def dish(kind):
    B=256; im=Image.new("RGBA",(B,B),(0,0,0,0)); d=ImageDraw.Draw(im); cx=cy=B/2; ow=10
    hl=(255,255,255,140)
    if kind=="lemon_drizzle":   # round loaf-free drizzle cake, side view: sponge drum, white icing drips, lemon slices on top
        d.rectangle([30,110,226,206],fill=rgb("#F2CF6A")); d.ellipse([30,176,226,236],fill=rgb("#F2CF6A"),outline=oc,width=ow)
        d.rectangle([30+ow//2,110,226-ow//2,206],fill=rgb("#F2CF6A"))
        d.line([(30,110),(30,206)],fill=oc,width=ow); d.line([(226,110),(226,206)],fill=oc,width=ow)
        d.line([(40,190),(216,190)],fill=rgb("#E5B84E"),width=4)
        ice=rgb("#FFFDF5")
        d.ellipse([30,80,226,140],fill=ice)
        for x,L in ((44,40),(70,22),(98,52),(130,30),(160,46),(190,24),(212,36)):
            d.rounded_rectangle([x-9,104,x+9,110+L],radius=9,fill=ice); d.ellipse([x-10,100+L,x+10,120+L],fill=ice)
        d.ellipse([30,80,226,140],outline=oc,width=ow)
        for x,L in ((44,40),(70,22),(98,52),(130,30),(160,46),(190,24),(212,36)):
            d.arc([x-10,100+L,x+10,120+L],0,180,fill=oc,width=4)
        for X,Y in ((92,84),(128,74),(164,86)):
            r=24; d.ellipse([X-r,Y-r*0.75,X+r,Y+r*0.75],fill=rgb("#FBE38A"),outline=oc,width=5)
            d.ellipse([X-r+6,Y-r*0.75+5,X+r-6,Y+r*0.75-5],fill=rgb("#FFF3B8"))
            for k in range(6):
                aa=k*math.pi/3; d.line([(X,Y),(X+(r-7)*math.cos(aa),Y+(r-7)*0.75*math.sin(aa))],fill=rgb("#E8C640"),width=3)
        for x0 in (60,184): d.line([(x0,96),(x0+8,90),(x0+16,96)],fill=rgb("#E8B820"),width=5)
    elif kind=="jam_tarts":
        for (X,Y,j) in ((cx-52,cy-34,"#C2335A"),(cx+52,cy-34,"#EE9A3A"),(cx,cy+50,"#5E2A4E")):
            _fluted(d,X,Y,56,14,rgb("#F2C584"),oc,7,depth=6)
            d.ellipse([X-40,Y-40,X+40,Y+40],fill=rgb(j),outline=oc,width=5)
            d.ellipse([X-26,Y-28,X-6,Y-16],fill=hl)
    elif kind=="shortcake":   # round cream cake, side view: strawberry layer in the cut-free side band, berries on top
        cr=rgb("#FFF6E8")
        d.rectangle([30,110,226,200],fill=cr); d.ellipse([30,170,226,230],fill=cr,outline=oc,width=ow)
        d.rectangle([30+ow//2,110,226-ow//2,200],fill=cr)
        d.line([(30,110),(30,200)],fill=oc,width=ow); d.line([(226,110),(226,200)],fill=oc,width=ow)
        d.rectangle([34,150,222,166],fill=rgb("#F4D9A0"))
        for x in range(46,214,28): d.ellipse([x-8,152,x+8,164],fill=rgb("#E0506A"))
        d.ellipse([30,80,226,140],fill=cr,outline=oc,width=ow)
        for k in range(7):
            a_=math.pi*(0.1+0.8*k/6); X=128-84*math.cos(a_); Y=110-4+20*math.sin(a_)*-1+18
            d.ellipse([X-13,Y-10,X+13,Y+10],fill=rgb("#FFFFFF"),outline=oc,width=4)
        for X,Y in ((92,96),(128,86),(164,96),(110,112),(148,112)):
            d.ellipse([X-15,Y-17,X+15,Y+15],fill=rgb("#D8344F"),outline=oc,width=5)
            d.polygon([(X-8,Y-15),(X,Y-24),(X+8,Y-15),(X,Y-11)],fill=rgb(SAGE))
            d.ellipse([X-7,Y-8,X-2,Y-3],fill=rgb("#FBE2A0")); d.ellipse([X+3,Y,X+8,Y+5],fill=rgb("#FBE2A0"))
    elif kind=="crumble":   # round dish seen at 3/4: crumble top, apple peeking, sage rim
        d.ellipse([20,70,236,226],fill=rgb("#8FB08A"),outline=oc,width=ow)
        d.rectangle([24,148,232,190],fill=rgb("#8FB08A")); d.chord([20,112,236,240],0,180,fill=rgb("#7FA07A"),outline=oc,width=ow)
        d.line([(22,150),(22,176)],fill=oc,width=ow); d.line([(234,150),(234,176)],fill=oc,width=ow)
        d.ellipse([20,70,236,226],outline=oc,width=ow)
        d.ellipse([36,82,220,206],fill=rgb("#D9A24E"),outline=oc,width=6)
        rng=np.random.default_rng(4)
        for _ in range(150):
            a=rng.uniform(0,2*math.pi); r=rng.uniform(0,1)**0.5; X=128+82*r*math.cos(a); Y=144+54*r*math.sin(a); s=rng.uniform(5,11)
            d.ellipse([X-s,Y-s*0.8,X+s,Y+s*0.8],fill=rgb(rng.choice(["#E8B866","#C98A3A","#F2CF87"])))
        for X,Y,r in ((84,132,9),(118,170,8),(158,118,10),(176,158,8)):
            d.polygon([(X-r,Y),(X,Y-r*0.8),(X+r,Y-r*0.2),(X+r*0.4,Y+r*0.7)],fill=rgb("#F6E7B0"),outline=oc)   # apple chunks
        d.ellipse([60,96,100,110],fill=hl)
    return im
def dish_img(kind,size):
    if kind in ("lemon_drizzle","jam_tarts","shortcake","crumble"): return down(_finish(dish(kind)),(size,size))
    if kind=="scones":
        im=Image.new("RGBA",(256,256),(0,0,0,0)); im.alpha_composite(cake("scone",190),(100,34)); im.alpha_composite(cake("scone",206),(-12,62))
        return down(im,(size,size))
    if kind=="macarons":
        im=Image.new("RGBA",(256,256),(0,0,0,0))
        for (x,y,c) in ((128,92,"#B8DFA6"),(70,150,"#EC93AA"),(186,150,"#D5BCF1")):
            m=down(_finish(macaron_img(c)),(130,130)); im.alpha_composite(m,(int(x-65),int(y-65)))
        return down(im,(size,size))
    return cake(kind,size)
# chapter -> (id, dish, tint region, display name)  [names are labels in Godot; NOT baked in]
CH=[(1,"scones","pistachio","Scones & clotted cream"),(2,"victoria","lavender","Victoria sponge"),
    (3,"lemon_drizzle","blueberry","Lemon drizzle"),(4,"jam_tarts","butter","Jam tarts"),
    (5,"bakewell","cocoa","Cherry Bakewell"),(6,"shortcake","honey","Strawberry shortcake"),
    (7,"crumble","rhubarb","Apple crumble"),(8,"macarons","vanilla","Macarons")]

def card(dish_kind,tint,S=2):   # S=2 -> 480x640 (@2x); drawn at 2x that and downsampled
    K=S*2; W,H=240*K,320*K; im=Image.new("RGBA",(W,H),(0,0,0,0)); d=ImageDraw.Draw(im); u=K
    sh=Image.new("RGBA",(W,H),(0,0,0,0)); ImageDraw.Draw(sh).rounded_rectangle([6*u,9*u,W-6*u,H-3*u],radius=18*u,fill=rgb(INK,70))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(4*u)))
    d.rounded_rectangle([4*u,4*u,W-6*u,H-8*u],radius=18*u,fill=rgb(CREAM),outline=oc,width=int(2*u))
    hx,pat=REGD[tint]
    # scalloped inner border in tint
    x0,y0,x1,y1=14*u,14*u,W-16*u,H-18*u
    d.rounded_rectangle([x0,y0,x1,y1],radius=12*u,outline=rgb(shade(hx,0.85)),width=int(2*u))
    for x in np.arange(x0+12*u,x1-8*u,12*u):
        for yy in (y0,y1): d.ellipse([x-3*u,yy-3*u,x+3*u,yy+3*u],fill=rgb(shade(hx,0.85)))
    # illustration disc with region pattern
    cx,cy,R=W/2-1*u,126*u,90*u
    disc=Image.new("RGBA",(W,H),(0,0,0,0)); dd=ImageDraw.Draw(disc); dd.ellipse([cx-R,cy-R,cx+R,cy+R],fill=rgb(hx))
    pl=pattern_layer(pat,W,H,int(26*u),shade(hx,0.82)[:3]+(150,),rng_seed=3)
    m=Image.new("L",(W,H),0); ImageDraw.Draw(m).ellipse([cx-R,cy-R,cx+R,cy+R],fill=255)
    disc.alpha_composite(Image.composite(pl,Image.new("RGBA",(W,H),(0,0,0,0)),m))
    ImageDraw.Draw(disc).ellipse([cx-R,cy-R,cx+R,cy+R],outline=rgb(shade(hx,0.72)),width=int(3*u))
    im.alpha_composite(disc)
    # plate
    d.ellipse([cx-74*u,cy+30*u,cx+74*u,cy+74*u],fill=rgb("#FFFDF8"),outline=oc,width=int(2*u))
    d.ellipse([cx-56*u,cy+38*u,cx+56*u,cy+66*u],outline=rgb("#E7B9C2"),width=int(2*u))
    ds=int(150*u); di=dish_img(dish_kind,ds); im.alpha_composite(di,(int(cx-ds/2),int(cy-ds/2-6*u)))
    # blank name ribbon (Godot draws name + chapter here)
    ry0,ry1=232*u,288*u
    d.polygon([(22*u,ry0+8*u),(34*u,ry0+8*u),(34*u,ry1-2*u),(22*u,ry1-2*u),(30*u,(ry0+ry1)/2+3*u)],fill=rgb(shade(hx,0.72)))
    d.polygon([(W-24*u,ry0+8*u),(W-36*u,ry0+8*u),(W-36*u,ry1-2*u),(W-24*u,ry1-2*u),(W-32*u,(ry0+ry1)/2+3*u)],fill=rgb(shade(hx,0.72)))
    d.rounded_rectangle([32*u,ry0,W-34*u,ry1-8*u],radius=6*u,fill=rgb("#FFFDF8"),outline=oc,width=int(2*u))
    return down(im,(240*S,320*S))
def card_back(S=2):
    K=S*2; W,H=240*K,320*K; im=Image.new("RGBA",(W,H),(0,0,0,0)); d=ImageDraw.Draw(im); u=K
    sh=Image.new("RGBA",(W,H),(0,0,0,0)); ImageDraw.Draw(sh).rounded_rectangle([6*u,9*u,W-6*u,H-3*u],radius=18*u,fill=rgb(INK,70))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(4*u)))
    base=Image.new("RGBA",(W,H),rgb(RASP)); base.alpha_composite(pattern_layer("lattice",W,H,int(30*u),(255,248,236,70),rng_seed=1))
    m=Image.new("L",(W,H),0); ImageDraw.Draw(m).rounded_rectangle([4*u,4*u,W-6*u,H-8*u],radius=18*u,fill=255)
    im.alpha_composite(Image.composite(base,Image.new("RGBA",(W,H),(0,0,0,0)),m)); d=ImageDraw.Draw(im)
    d.rounded_rectangle([4*u,4*u,W-6*u,H-8*u],radius=18*u,outline=oc,width=int(2*u))
    d.rounded_rectangle([14*u,14*u,W-16*u,H-18*u],radius=12*u,outline=rgb(CREAM,180),width=int(2*u))
    cx,cy,r=W/2-1*u,H/2-4*u,40*u
    d.ellipse([cx-r,cy-r,cx+r,cy+r],fill=rgb(CREAM),outline=oc,width=int(2*u))
    lk=Image.open(f"{A}/ui/icons/icon_lock@2x.png").convert("RGBA").resize((int(48*u),int(48*u)),Image.LANCZOS)
    im.alpha_composite(lk,(int(cx-24*u),int(cy-24*u)))
    return down(im,(240*S,320*S))
for i,dk,tint,name in CH:
    for suf,S in (("",1),("@2x",2)): save(card(dk,tint,S),f"{CARDS}/recipe_{i}{suf}.png",optimize=True)
for suf,S in (("",1),("@2x",2)): save(card_back(S),f"{CARDS}/recipe_locked{suf}.png",optimize=True)

# ---------------- decor (96 px 1x, square, bottom-anchored at y=0.94) ----------------
B=800; U=B/100
def canvas(): im=Image.new("RGBA",(B,B),(0,0,0,0)); return im,ImageDraw.Draw(im)
OW=int(2.4*U)
def finish_decor(im,base_y=94):
    a=im.split()[3]; sh=Image.new("RGBA",(B,B),(0,0,0,0))
    ImageDraw.Draw(sh).ellipse([20*U,(base_y-3)*U,80*U,(base_y+3)*U],fill=rgb(INK,70))
    sh=sh.filter(ImageFilter.GaussianBlur(2*U)); sh.alpha_composite(im); return sh
def flower(d,x,y,r,col):
    for k in range(5):
        a=k*2*math.pi/5; d.ellipse([x+r*0.55*math.cos(a)-r*0.55,y+r*0.55*math.sin(a)-r*0.55,x+r*0.55*math.cos(a)+r*0.55,y+r*0.55*math.sin(a)+r*0.55],fill=rgb(col),outline=oc,width=max(2,int(OW*0.5)))
    d.ellipse([x-r*0.3,y-r*0.3,x+r*0.3,y+r*0.3],fill=rgb("#F2C14E"))
def teapot():
    im,d=canvas()
    d.rounded_rectangle([12*U,44*U,26*U,52*U],radius=3*U,fill=rgb("#F6C7CF"))
    d.polygon([(22*U,62*U),(6*U,40*U),(11*U,37*U),(28*U,56*U)],fill=rgb("#F6C7CF"),outline=oc); d.line([(22*U,62*U),(6*U,40*U),(11*U,37*U),(28*U,56*U)],fill=oc,width=OW)
    d.arc([66*U,42*U,92*U,74*U],-90,90,fill=oc,width=int(OW*2.6)); d.arc([67*U,43*U,91*U,73*U],-90,90,fill=rgb("#F6C7CF"),width=int(OW*1.2))
    d.ellipse([20*U,38*U,80*U,94*U],fill=rgb("#FBE3E7"),outline=oc,width=OW)
    for (x,y,c) in ((38,62,"#E07A95"),(58,72,"#C8B5E6"),(48,82,"#E07A95"),(64,56,"#F2C14E")): flower(d,x*U,y*U,6*U,c)
    for (x,y) in ((44,70),(56,64),(52,56)): d.ellipse([x*U-2*U,y*U-1.2*U,x*U+2*U,y*U+1.2*U],fill=rgb(SAGE))
    d.chord([32*U,30*U,68*U,46*U],180,360,fill=rgb(RASP),outline=oc,width=OW); d.ellipse([45*U,23*U,55*U,33*U],fill=rgb(RASP),outline=oc,width=OW)
    d.ellipse([28*U,46*U,40*U,54*U],fill=(255,255,255,150))
    return finish_decor(im)
def cakestand():
    im,d=canvas(); gold=rgb("#E2B05E")
    d.line([(50*U,10*U),(50*U,90*U)],fill=oc,width=int(OW*2.2)); d.line([(50*U,10*U),(50*U,90*U)],fill=gold,width=OW)
    d.ellipse([46*U,5*U,54*U,13*U],fill=gold,outline=oc,width=OW)
    for (y,w,cks) in ((34,22,["macaron"]),(60,32,["berry","lemon"]),(88,42,["victoria","bakewell","scone"])):
        n=len(cks); sz=int(min(2*w/n+8,26)*U)
        for j,k in enumerate(cks):
            x=50-w+ (2*w)*(j+0.5)/n; c=cake(k,sz); im.alpha_composite(c,(int(x*U-sz/2),int(y*U-sz*0.85)))
        d=ImageDraw.Draw(im); d.ellipse([(50-w-2)*U,(y-3)*U,(50+w+2)*U,(y+3)*U],fill=rgb("#FFFDF8"),outline=oc,width=OW)
    return finish_decor(im,92)
def gingham_folded():
    im,d=canvas(); h,_=REGD["strawberry"]
    for i,(y,col) in enumerate(((70,"#F1A7B7"),(52,"#B8DFA6"),(34,"#F1A7B7"))):
        x0,x1=14*U+i*3*U,86*U-i*3*U
        d.rounded_rectangle([x0,y*U,x1,(y+20)*U],radius=5*U,fill=rgb("#FFFDF8"),outline=oc,width=OW)
        for x in np.arange(x0+2*U,x1-2*U,6*U): d.rectangle([x,y*U+OW,x+3*U,(y+20)*U-OW],fill=rgb(col,140))
        for yy in np.arange(y*U+2*U,(y+19)*U,6*U): d.rectangle([x0+OW,yy,x1-OW,yy+3*U],fill=rgb(col,120))
        d.rounded_rectangle([x0,y*U,x1,(y+20)*U],radius=5*U,outline=oc,width=OW)
    d.polygon([(70*U,34*U),(80*U,34*U),(78*U,26*U)],fill=rgb(RASP))  # little ribbon
    return finish_decor(im,92)
def teacups():
    im,d=canvas()
    d.ellipse([4*U,74*U,96*U,98*U],fill=rgb("#FFFFFF"),outline=rgb("#D9C8BE"),width=int(OW*0.8))
    for k in range(30):
        a=2*math.pi*k/30; d.ellipse([50*U+44*U*math.cos(a)-3*U,86*U+11*U*math.sin(a)-3*U,50*U+44*U*math.cos(a)+3*U,86*U+11*U*math.sin(a)+3*U],outline=rgb("#E3D6CC"),width=int(U*0.8))
    for (x,col) in ((30,"#C8B5E6"),(68,"#B8DFA6")):
        d.ellipse([(x-20)*U,80*U,(x+20)*U,90*U],fill=rgb("#FFFDF8"),outline=oc,width=OW)
        d.arc([(x+8)*U,58*U,(x+24)*U,76*U],-90,90,fill=oc,width=OW)
        d.chord([(x-16)*U,48*U,(x+16)*U,88*U],0,180,fill=rgb(col),outline=oc,width=OW); d.line([((x-16)*U,68*U),((x+16)*U,68*U)],fill=oc,width=OW)
        d.ellipse([(x-15)*U,65*U,(x+15)*U,71*U],fill=rgb("#B9764A"))
        for s in (-5,4): d.line([((x+s)*U,58*U),((x+s-3)*U,50*U),((x+s+2)*U,42*U)],fill=rgb(INK,120),width=int(U*1.4),joint="curve")
    return finish_decor(im,90)
def vase():
    im,d=canvas()
    for (sx,sy,ex,ey) in ((50,60,30,22),(50,60,48,12),(50,60,66,18),(50,60,76,34),(50,60,24,40)):
        d.line([(sx*U,sy*U),((sx+ex)/2*U,(sy+ey)/2*U-4*U),(ex*U,ey*U)],fill=rgb(SAGE),width=int(1.6*U),joint="curve")
    for (x,y,c) in ((30,22,"#F1A7B7"),(48,12,"#D5BCF1"),(66,18,"#FFFFFF"),(76,34,"#E07A95"),(24,40,"#C8B5E6"),(56,30,"#F6C7CF"),(40,32,"#FFFFFF")):
        for k in range(3): d.ellipse([(x-6+k*3)*U,(y-5+k*1.5)*U,(x+2+k*3)*U,(y+3+k*1.5)*U],fill=rgb(c),outline=oc,width=max(2,int(OW*0.5)))
    d.ellipse([60*U,22*U,66*U,28*U],fill=rgb(SAGE))
    d.polygon([(38*U,52*U),(62*U,52*U),(70*U,72*U),(64*U,94*U),(36*U,94*U),(30*U,72*U)],fill=rgb("#8FB08A"),outline=oc)
    d.line([(38*U,52*U),(62*U,52*U),(70*U,72*U),(64*U,94*U),(36*U,94*U),(30*U,72*U),(38*U,52*U)],fill=oc,width=OW,joint="curve")
    d.ellipse([37*U,49*U,63*U,56*U],fill=rgb("#7FA07A"),outline=oc,width=OW)
    d.line([(36*U,64*U),(34*U,80*U)],fill=(255,255,255,150),width=int(2.5*U))
    return finish_decor(im)
def cuckoo():
    im,d=canvas(); wood=rgb("#B07A4F"); woodD=rgb("#8A5A3A")
    d.line([(38*U,70*U),(38*U,96*U)],fill=oc,width=int(U*0.9)); d.line([(62*U,70*U),(62*U,90*U)],fill=oc,width=int(U*0.9))
    for x,y in ((38,96),(62,90)): d.rounded_rectangle([(x-3)*U,(y-9)*U,(x+3)*U,y*U],radius=2*U,fill=woodD,outline=oc,width=int(OW*0.7))
    d.line([(50*U,70*U),(50*U,86*U)],fill=oc,width=int(U*1)); d.ellipse([46*U,84*U,54*U,92*U],fill=rgb("#E2B05E"),outline=oc,width=int(OW*0.7))
    d.polygon([(24*U,36*U),(76*U,36*U),(76*U,74*U),(24*U,74*U)],fill=wood,outline=oc); d.rectangle([24*U,36*U,76*U,74*U],outline=oc,width=OW)
    d.polygon([(16*U,40*U),(50*U,12*U),(84*U,40*U)],fill=rgb(SAGE)); d.line([(16*U,40*U),(50*U,12*U),(84*U,40*U),(16*U,40*U)],fill=oc,width=OW,joint="curve")
    for k in range(5): d.ellipse([(22+k*12)*U,36*U,(30+k*12)*U,44*U],fill=rgb("#7FA07A"),outline=oc,width=int(OW*0.6))
    d.rounded_rectangle([44*U,22*U,56*U,34*U],radius=2*U,fill=woodD,outline=oc,width=int(OW*0.7))   # closed little door
    d.ellipse([34*U,46*U,66*U,72*U],fill=rgb(CREAM),outline=oc,width=OW)
    d.line([(50*U,59*U),(50*U,50*U)],fill=oc,width=int(OW*0.8)); d.line([(50*U,59*U),(58*U,62*U)],fill=oc,width=int(OW*0.8))
    for k in range(12):
        a=2*math.pi*k/12; d.ellipse([50*U+13*U*math.cos(a)-0.8*U,59*U+10.5*U*math.sin(a)-0.8*U,50*U+13*U*math.cos(a)+0.8*U,59*U+10.5*U*math.sin(a)+0.8*U],fill=oc)
    return finish_decor(im,97)
def kettle():
    im,d=canvas(); cu=rgb("#C7794A"); cuL=rgb("#E4A274"); cuD=rgb("#9C5634")
    d.polygon([(26*U,70*U),(6*U,46*U),(10*U,42*U),(30*U,60*U)],fill=cu); d.line([(26*U,70*U),(6*U,46*U),(10*U,42*U),(30*U,60*U)],fill=oc,width=OW,joint="curve")
    d.arc([28*U,14*U,72*U,58*U],180,360,fill=oc,width=int(OW*2.8)); d.arc([29*U,15*U,71*U,57*U],180,360,fill=rgb("#3E2A2F"),width=int(OW*1.2))
    d.chord([16*U,38*U,84*U,110*U],180,360,fill=cu,outline=oc,width=OW); d.rounded_rectangle([16*U,72*U,84*U,94*U],radius=6*U,fill=cu,outline=oc,width=OW)
    d.rectangle([18*U,70*U,82*U,78*U],fill=cu); d.line([(17*U,74*U),(83*U,74*U)],fill=cuD,width=int(U*1.2))
    d.chord([36*U,30*U,64*U,46*U],180,360,fill=cuD,outline=oc,width=OW); d.ellipse([46*U,26*U,54*U,34*U],fill=cuD,outline=oc,width=OW)
    d.ellipse([26*U,50*U,40*U,70*U],fill=cuL); d.ellipse([28*U,52*U,34*U,60*U],fill=(255,255,255,170))
    return finish_decor(im,93)
def bunting_square():
    im,d=canvas(); cols=[REGD[n][0] for n in ("strawberry","butter","pistachio","lavender","blueberry")]
    pts=[(x*U,(30+14*math.sin(math.pi*x/100))*U) for x in range(4,97,2)]
    d.line(pts,fill=oc,width=int(OW*0.8),joint="curve")
    for i,x in enumerate(np.linspace(14,86,5)):
        y=30+14*math.sin(math.pi*x/100); c=cols[i]
        tri=[((x-9)*U,y*U),((x+9)*U,y*U),(x*U,(y+26)*U)]
        d.polygon(tri,fill=rgb(c)); d.line(tri+[tri[0]],fill=oc,width=OW,joint="curve")
    return im
DEC=[(1,"teapot",teapot),(2,"cake_stand",cakestand),(3,"gingham",gingham_folded),(4,"doily_teacups",teacups),
     (5,"sweet_peas",vase),(6,"bunting",bunting_square),(7,"cuckoo_clock",cuckoo),(8,"copper_kettle",kettle)]
for i,n,fn in DEC:
    im=fn()
    for suf,S in (("",96),("@2x",192)): save(down(im,(S,S)),f"{DECOR}/decor_{i}_{n}{suf}.png",optimize=True)

# ---------------- counter shelf (360x160 1x) + shelf variants of gingham (drape) and bunting (garland) ----------------
SW,SH=360,160; KS=4
def shelf(S):
    K=KS*S; im=Image.new("RGBA",(SW*K,SH*K),(0,0,0,0)); d=ImageDraw.Draw(im); u=K
    for x in (40,320):  # brackets
        d.polygon([(x-6)*u and ((x-6)*u,140*u),((x+6)*u,140*u),((x+6)*u,158*u),((x-6)*u,150*u)],fill=rgb("#E6D5C0")); d.line([((x-6)*u,140*u),((x+6)*u,140*u),((x+6)*u,158*u),((x-6)*u,150*u),((x-6)*u,140*u)],fill=oc,width=int(1.5*u))
    sh=Image.new("RGBA",im.size,(0,0,0,0)); ImageDraw.Draw(sh).rectangle([6*u,136*u,354*u,150*u],fill=rgb(INK,60)); im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(3*u))); d=ImageDraw.Draw(im)
    d.rounded_rectangle([4*u,126*u,356*u,140*u],radius=3*u,fill=rgb("#F7EEDF"),outline=oc,width=int(1.6*u))
    d.line([(8*u,129*u),(352*u,129*u)],fill=rgb("#FFFFFF",180),width=int(1.4*u))
    for x in np.arange(10*u,352*u,14*u): d.chord([x-0*u,136*u,x+14*u,148*u],0,180,fill=rgb("#F1C9CF"),outline=oc,width=int(1.2*u))
    return down(im,(SW*S,SH*S))
def drape(S):   # gingham cloth over the shelf front (draw ABOVE shelf, BELOW decor)
    K=KS*S; im=Image.new("RGBA",(SW*K,SH*K),(0,0,0,0)); d=ImageDraw.Draw(im); u=K
    pts=[(2*u,124*u),(358*u,124*u)]+[(x*u,(150+4*math.sin(x/9))*u) for x in range(358,1,-2)]
    d.polygon(pts,fill=rgb("#FFFDF8"))
    g=Image.new("RGBA",im.size,(0,0,0,0)); gd=ImageDraw.Draw(g)
    for x in range(0,SW,8): gd.rectangle([x*u,120*u,(x+4)*u,160*u],fill=rgb("#B8DFA6",150))
    for y in range(124,160,8): gd.rectangle([0,y*u,SW*u,(y+4)*u],fill=rgb("#B8DFA6",120))
    m=Image.new("L",im.size,0); ImageDraw.Draw(m).polygon(pts,fill=255)
    im.alpha_composite(Image.composite(g,Image.new("RGBA",im.size,(0,0,0,0)),m)); d=ImageDraw.Draw(im)
    d.line(pts+[pts[0]],fill=oc,width=int(1.6*u),joint="curve")
    return down(im,(SW*S,SH*S))
def garland(S):
    K=KS*S; im=Image.new("RGBA",(SW*K,SH*K),(0,0,0,0)); d=ImageDraw.Draw(im); u=K
    cols=[h for _,h,_ in REG]
    yf=lambda x:4+14*math.sin(math.pi*x/SW)
    d.line([(x*u,yf(x)*u) for x in range(0,SW+1,3)],fill=oc,width=int(1.4*u),joint="curve")
    for i,x in enumerate(np.linspace(20,340,13)):
        y=yf(x); tri=[((x-10)*u,y*u),((x+10)*u,y*u),(x*u,(y+22)*u)]
        d.polygon(tri,fill=rgb(cols[i%9])); d.line(tri+[tri[0]],fill=oc,width=int(1.4*u),joint="curve")
    return down(im,(SW*S,SH*S))
for suf,S in (("",1),("@2x",2)):
    save(shelf(S),f"{DECOR}/shelf_counter{suf}.png",optimize=True)
    save(drape(S),f"{DECOR}/shelf_gingham_drape{suf}.png",optimize=True)
    save(garland(S),f"{DECOR}/shelf_bunting_garland{suf}.png",optimize=True)
# shelf slots (1x px, in the 360x160 shelf space): decor bottom-centre at (x, 128), drawn at size
SLOTS={1:{"x":34,"size":56},2:{"x":92,"size":72},4:{"x":152,"size":60},5:{"x":210,"size":68},7:{"x":266,"size":64},8:{"x":324,"size":58},
       3:{"overlay":"shelf_gingham_drape"},6:{"overlay":"shelf_bunting_garland"}}
json.dump({"shelf_size":[SW,SH],"baseline_y":128,"anchor":"decor sprite bottom-centre; decor canvas baseline is at 0.94 of its height","slots":SLOTS},open(f"{DECOR}/shelf_slots.json","w"),indent=1)
written.append(f"{DECOR}/shelf_slots.json")

# ---------------- backdrops ----------------
def wide_backdrop():
    im=ttland.backdrop(1920,1080,2)
    return im.transpose(Image.FLIP_LEFT_RIGHT)   # window + dresser on the right (the board covers the left in the wide layout)
def portrait_backdrop(W=1080,H=2340):
    # same tea-room wall at portrait proportions: window + lamp in view, wainscot from 64% height, gingham floor band
    big=ttland.backdrop(1500,H,2)
    return big.crop((0,0,W,H))
wb=wide_backdrop().convert("RGB"); pb=portrait_backdrop().convert("RGB")
save(wb,f"{BACK}/backdrop_landscape.webp",quality=82,method=6)
save(pb,f"{BACK}/backdrop_portrait.webp",quality=82,method=6)
tot=sum(os.path.getsize(p) for p in written)
json.dump({"files":[os.path.relpath(p,ROOT) for p in written],"bytes":tot},open(os.path.join(os.path.dirname(__file__),"p2_files.json"),"w"),indent=1)
print(len(written),"files",tot,"bytes")
