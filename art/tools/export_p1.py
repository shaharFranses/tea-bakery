"""P1 game-ready export (B2): regions/tray/hint overlays + UI (icons, buttons, panels, chips, toggles,
coach bubble, pointer hand) + fonts + Godot palette. Original art drawn here (Pillow); fonts SIL OFL."""
import os, json, math, shutil, numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops
from ttdraw import rgb as _rgb, shade as _shade, UI, REG, font
def rgb(h,a=255): return (tuple(h[:3])+(a if len(h)==3 or a!=255 else h[3],)) if isinstance(h,tuple) else _rgb(h,a)
def shade(h,f): return _shade(h if isinstance(h,str) else "#%02X%02X%02X"%h[:3],f)
ROOT="/workspace/tea-and-tarts"
BOARD=f"{ROOT}/assets/board"; UIO=f"{ROOT}/assets/ui"; ICO=f"{UIO}/icons"; FNT=f"{ROOT}/assets/fonts"
for d in (BOARD,UIO,ICO,FNT): os.makedirs(d,exist_ok=True)
INK=UI["earl_grey_ink"]; CREAM="#FFF8EC"; RASP=UI["raspberry_jam"]; SAGE=UI["sage_leaf"]
CRUST=UI["toasted_crust"]; HONEY=UI["honey_chip"]; PEWTER=UI["pewter_tray"]; CHERRY=UI["cherry_alert"]; BG=UI["rosewater_bg"]
SS=4; written=[]
def save(im,path):
    im.save(path,optimize=True); written.append(path)
def both(fn,name,base,folder):   # fn(S) -> RGBA image at S scale factor
    for suf,k in (("",1),("@2x",2)): save(fn(base*k if isinstance(base,int) else tuple(b*k for b in base)),f"{folder}/{name}{suf}.png")
def down(im,size): return im.resize(size,Image.LANCZOS)
def blur(im,r): return im.filter(ImageFilter.GaussianBlur(r))
def solid(mask,col):
    im=Image.new("RGBA",mask.size,rgb(col)[:3]+(0,)); a=np.array(mask,float)*(rgb(col)[3]/255)
    im.putalpha(Image.fromarray(a.astype(np.uint8))); return im
def dilate(mask,r):
    r=max(1,int(r)); return mask.filter(ImageFilter.MaxFilter(2*r+1)) if r<12 else blur(mask,r/2).point(lambda v:255 if v>20 else 0)

# ---------------- icons (mono, stroke style, 48 px 1x) ----------------
def stroke(d,pts,w,col):
    d.line(pts,fill=col,width=int(w),joint="curve")
    for p in (pts[0],pts[-1]): d.ellipse([p[0]-w/2,p[1]-w/2,p[0]+w/2,p[1]+w/2],fill=col)
def arcpts(cx,cy,r,a0,a1,n=48): return [(cx+r*math.cos(math.radians(a0+(a1-a0)*i/n)),cy+r*math.sin(math.radians(a0+(a1-a0)*i/n))) for i in range(n+1)]
def arrowhead(d,tip,ang,s,col):
    a=math.radians(ang); L=[(tip[0]-s*math.cos(a-0.6),tip[1]-s*math.sin(a-0.6)),tip,(tip[0]-s*math.cos(a+0.6),tip[1]-s*math.sin(a+0.6))]
    d.polygon(L,fill=col)
def draw_icon(name,S,col):
    B=S*SS; im=Image.new("RGBA",(B,B),(0,0,0,0)); d=ImageDraw.Draw(im); c=rgb(col)
    u=B/2*0.78; cx=cy=B/2; w=B*0.085
    P=lambda x,y:(cx+x*u,cy+y*u)
    if name=="home":
        stroke(d,[P(-0.95,0.05),P(0,-0.8),P(0.95,0.05)],w,c)
        stroke(d,[P(-0.65,-0.15),P(-0.65,0.85),P(0.65,0.85),P(0.65,-0.15)],w,c)
        d.rounded_rectangle([*P(-0.18,0.3),*P(0.18,0.85)],radius=w*0.3,fill=c)
    elif name=="back":
        stroke(d,[P(0.2,-0.7),P(-0.5,0),P(0.2,0.7)],w*1.1,c)
    elif name=="close":
        stroke(d,[P(-0.6,-0.6),P(0.6,0.6)],w*1.1,c); stroke(d,[P(0.6,-0.6),P(-0.6,0.6)],w*1.1,c)
    elif name=="settings":
        r0,r1,n=u*0.62,u*0.92,8; pts=[]
        for i in range(n*4):
            a=2*math.pi*i/(n*4)+math.pi/(n*4); rr=r1 if (i%4) in (1,2) else r0
            pts.append((cx+rr*math.cos(a),cy+rr*math.sin(a)))
        d.polygon(pts,fill=c); d.ellipse([cx-u*0.3,cy-u*0.3,cx+u*0.3,cy+u*0.3],fill=(0,0,0,0))
        hole=Image.new("L",(B,B),0); ImageDraw.Draw(hole).ellipse([cx-u*0.3,cy-u*0.3,cx+u*0.3,cy+u*0.3],fill=255)
        im.putalpha(ImageChops.subtract(im.split()[3],hole))
    elif name=="undo":
        pts=arcpts(cx+u*0.05,cy+u*0.15,u*0.62,200,400+20); stroke(d,pts[:-6],w,c)
        stroke(d,[P(-0.95,-0.35),P(-0.6,0.12),P(-0.15,-0.2)],w,c)
    elif name=="reset":
        pts=arcpts(cx,cy+u*0.05,u*0.68,-30,270); stroke(d,pts[6:],w,c)
        e=pts[6]; arrowhead(d,(e[0]+u*0.02,e[1]-u*0.32),-70,u*0.5,c)
    elif name=="hint":   # lightbulb
        d.ellipse([*P(-0.6,-0.95),*P(0.6,0.25)],outline=c,width=int(w))
        cut=Image.new("L",(B,B),0); ImageDraw.Draw(cut).rectangle([*P(-0.26,0.0),*P(0.26,0.4)],fill=255)
        im.putalpha(ImageChops.subtract(im.split()[3],cut)); d=ImageDraw.Draw(im)
        stroke(d,[P(-0.3,0.12),P(-0.3,0.5),P(0.3,0.5),P(0.3,0.12)],w,c)
        stroke(d,[P(-0.18,0.82),P(0.18,0.82)],w,c)
        stroke(d,[P(-0.2,-0.2),P(0.0,-0.02),P(0.2,-0.2)],w*0.7,c); stroke(d,[P(0.0,-0.02),P(0.0,0.35)],w*0.7,c)
    elif name=="rewarded":   # clapperboard
        d.rounded_rectangle([*P(-0.85,-0.2),*P(0.85,0.8)],radius=u*0.12,fill=c)
        top=[P(-0.88,-0.32),P(0.78,-0.72),P(0.84,-0.46),P(-0.82,-0.06)]
        d.polygon(top,fill=c)
        clear=(0,0,0,0)
        for t in (0.15,0.45,0.75):
            a=(top[0][0]+(top[1][0]-top[0][0])*t, top[0][1]+(top[1][1]-top[0][1])*t)
            d.polygon([a,(a[0]+u*0.16,a[1]-u*0.04),(a[0]+u*0.24,a[1]+u*0.26),(a[0]+u*0.08,a[1]+u*0.3)],fill=clear)
        d.polygon([P(-0.25,0.05),P(0.35,0.3),P(-0.25,0.55)],fill=clear)
    elif name in ("sound_on","sound_off"):
        d.polygon([P(-0.85,-0.3),P(-0.45,-0.3),P(0.05,-0.75),P(0.05,0.75),P(-0.45,0.3),P(-0.85,0.3)],fill=c)
        if name=="sound_on":
            stroke(d,arcpts(cx+u*0.05,cy,u*0.42,-45,45,20),w*0.9,c); stroke(d,arcpts(cx+u*0.05,cy,u*0.8,-50,50,24),w*0.9,c)
        else:
            stroke(d,[P(0.35,-0.35),P(0.95,0.35)],w,c); stroke(d,[P(0.95,-0.35),P(0.35,0.35)],w,c)
    elif name in ("music_on","music_off"):
        d.ellipse([*P(-0.8,0.35),*P(-0.3,0.8)],fill=c); d.ellipse([*P(0.2,0.2),*P(0.7,0.65)],fill=c)
        stroke(d,[P(-0.35,0.55),P(-0.35,-0.6)],w,c); stroke(d,[P(0.65,0.4),P(0.65,-0.75)],w,c)
        d.polygon([P(-0.4,-0.62),P(0.7,-0.88),P(0.7,-0.5),P(-0.4,-0.24)],fill=c)
        if name=="music_off":
            stroke(d,[P(-0.95,-0.95),P(0.95,0.95)],w*1.3,(0,0,0,0)); stroke(d,[P(-0.9,-0.9),P(0.9,0.9)],w*0.8,c)
    elif name=="lock":
        stroke(d,arcpts(cx,cy-u*0.2,u*0.42,180,360),w,c); stroke(d,[P(-0.42,-0.2),P(-0.42,0.05)],w,c); stroke(d,[P(0.42,-0.2),P(0.42,0.05)],w,c)
        d.rounded_rectangle([*P(-0.72,0.0),*P(0.72,0.9)],radius=u*0.16,fill=c)
        d.ellipse([*P(-0.12,0.28),*P(0.12,0.52)],fill=(0,0,0,0)); stroke(d,[P(0,0.45),P(0,0.65)],w*0.7,(0,0,0,0))
    elif name=="streak":   # teacup with steam
        d.chord([*P(-0.8,-0.35),*P(0.55,0.75)],0,180,fill=c); d.rectangle([*P(-0.8,0.18),*P(0.55,0.22)],fill=c)
        d.ellipse([*P(0.38,0.02),*P(0.92,0.48)],outline=c,width=int(w*0.85))
        stroke(d,[P(-0.95,0.88),P(0.75,0.88)],w*0.9,c)
        for x in (-0.38,0.08):
            stroke(d,[P(x,-0.15),P(x-0.12,-0.4),P(x+0.06,-0.62),P(x-0.05,-0.88)],w*0.7,c)
    elif name=="check":
        stroke(d,[P(-0.7,0.05),P(-0.2,0.55),P(0.75,-0.55)],w*1.15,c)
    elif name=="book":   # recipe book
        for s_ in (-1,1):
            d.polygon([P(0,-0.55),P(s_*0.9,-0.75),P(s_*0.9,0.6),P(0,0.8)],outline=None,fill=c)
            d.polygon([P(s_*0.12,-0.4),P(s_*0.74,-0.55),P(s_*0.74,0.42),P(s_*0.12,0.58)],fill=(0,0,0,0))
    elif name=="play":
        d.polygon([P(-0.45,-0.7),P(0.75,0),P(-0.45,0.7)],fill=c)
    elif name=="help":
        d.ellipse([*P(-0.9,-0.9),*P(0.9,0.9)],outline=c,width=int(w))
        d.text((cx,cy+u*0.05),"?",fill=c,font=font("ui",u*1.3,700),anchor="mm")
    return down(im,(S,S))
ICONS=["home","back","close","settings","undo","reset","hint","rewarded","sound_on","sound_off","music_on","music_off","lock","streak","check","book","play","help"]
for n in ICONS:
    both(lambda S,n=n: draw_icon(n,S,INK),f"icon_{n}",48,ICO)
    both(lambda S,n=n: draw_icon(n,S,CREAM),f"icon_{n}_cream",48,ICO)

# ---------------- 9-slice pieces ----------------
def padded(W,H,r,fill,lip,outline=None,ow=0,shadow=True,hl=True):
    """padded rounded rect, shadow + bottom lip; returns RGBA at SS scale; caller downsamples."""
    B=SS; w,h=W*B,H*B; im=Image.new("RGBA",(w,h),(0,0,0,0))
    pad=int(3*B)
    if shadow:
        sh=Image.new("L",(w,h),0); ImageDraw.Draw(sh).rounded_rectangle([pad,pad+2*B,w-pad,h-pad+1*B],radius=r*B,fill=255)
        im.alpha_composite(solid(blur(sh,2*B),rgb(INK,60)))
    d=ImageDraw.Draw(im)
    if lip: d.rounded_rectangle([pad,pad+2*B,w-pad,h-pad],radius=r*B,fill=rgb(lip))
    d.rounded_rectangle([pad,pad,w-pad,h-pad-(2*B if lip else 0)],radius=r*B,fill=rgb(fill),outline=rgb(outline) if outline else None,width=int(ow*B))
    if hl:
        g=Image.new("L",(w,h),0); ImageDraw.Draw(g).rounded_rectangle([pad+r*B*0.5,pad+2*B,w-pad-r*B*0.5,pad+min(h*0.22,10*B)],radius=4*B,fill=70)
        im.alpha_composite(solid(blur(g,2*B),"#FFFFFF"))
    return im
def nine(name,W,H,r,fill,lip,folder=UIO,**kw):
    for suf,k in (("",1),("@2x",2)):
        im=padded(W*k,H*k,r*k,fill,lip,ow=kw.get("ow",0)*k,outline=kw.get("outline"),shadow=kw.get("shadow",True),hl=kw.get("hl",True))
        save(down(im,(W*k,H*k)),f"{folder}/{name}{suf}.png")
BTN={"primary":(RASP,shade(RASP,0.72)),"secondary":(SAGE,shade(SAGE,0.72)),"tool":(CREAM,shade("#E9D8C4",1.0))}
def hx(c): return '#%02X%02X%02X'%c[:3] if isinstance(c,tuple) else c
for kind,(f,lip) in BTN.items():
    ol=INK if kind=="tool" else None
    nine(f"btn_{kind}_normal",96,64,20,f,hx(lip),outline=ol,ow=2 if ol else 0)
    nine(f"btn_{kind}_pressed",96,64,20,hx(shade(f,0.9)),None,outline=ol,ow=2 if ol else 0,hl=False)
    nine(f"btn_{kind}_disabled",96,64,20,"#E6DCD6" if kind!="tool" else "#F3ECE6",None,outline="#B9AAA9" if ol else None,ow=2 if ol else 0,shadow=False,hl=False)
nine("btn_round_normal",56,56,25,CREAM,"#E2CFBB",outline=INK,ow=2)
nine("btn_round_pressed",56,56,25,hx(shade(CREAM,0.92)),None,outline=INK,ow=2,hl=False)
nine("panel_card",96,96,24,CREAM,None,outline="#E7D3C3",ow=2,hl=False)
nine("panel_modal",96,96,28,CREAM,None,outline=INK,ow=2,hl=False)
nine("chip_honey",64,40,18,HONEY,hx(shade(HONEY,0.8)),hl=True)
nine("coach_bubble",96,72,22,CREAM,None,outline=INK,ow=2,hl=False)
def coach_tail(S):  # downward-pointing tail, attach to bubble bottom (overlaps the 2 px outline)
    B=S*SS; W,H=B,int(B*0.75); im=Image.new("RGBA",(W,H),(0,0,0,0)); d=ImageDraw.Draw(im)
    o=0.0625*B; d.polygon([(0,0),(W,0),(W/2,H-o)],fill=rgb(INK)); d.polygon([(o*1.6,0),(W-o*1.6,0),(W/2,H-o*3.2)],fill=rgb(CREAM))
    d.rectangle([0,0,W,o*0.5],fill=(0,0,0,0)); d.rectangle([o*1.6,0,W-o*1.6,o*1.2],fill=rgb(CREAM))
    return down(im,(S,int(S*0.75)))
both(coach_tail,"coach_tail",32,UIO)
def toggle(on,S):
    W,H=64,36; B=SS*S//64; im=Image.new("RGBA",(W*B,H*B),(0,0,0,0)); d=ImageDraw.Draw(im)
    d.rounded_rectangle([B,B,W*B-B,H*B-B],radius=H*B/2-B,fill=rgb(SAGE if on else "#CBBFBE"),outline=rgb(INK),width=2*B)
    kx=(W-H/2-1) if on else (H/2+1); r=H/2-5
    sh=Image.new("L",im.size,0); ImageDraw.Draw(sh).ellipse([(kx-r)*B,(H/2-r+1.5)*B,(kx+r)*B,(H/2+r+1.5)*B],fill=110)
    im.alpha_composite(solid(blur(sh,B*1.2),rgb(INK)))
    d.ellipse([(kx-r)*B,(H/2-r)*B,(kx+r)*B,(H/2+r)*B],fill=rgb(CREAM),outline=rgb(INK),width=2*B)
    if on:
        ix=H/2+1; d.line([((ix-6)*B,(H/2)*B),((ix-2)*B,(H/2+4)*B),((ix+6)*B,(H/2-5)*B)],fill=rgb(CREAM),width=3*B,joint="curve")
    return down(im,(W*S//64,H*S//64))
both(lambda S: toggle(True,S),"toggle_on",64,UIO); both(lambda S: toggle(False,S),"toggle_off",64,UIO)
def dot(on,S):
    B=S*SS; im=Image.new("RGBA",(B,B),(0,0,0,0)); d=ImageDraw.Draw(im)
    d.ellipse([B*0.1,B*0.1,B*0.9,B*0.9],fill=rgb(CRUST if on else CREAM),outline=rgb(INK),width=int(B*0.1)); return down(im,(S,S))
both(lambda S: dot(True,S),"progress_dot_on",16,UIO); both(lambda S: dot(False,S),"progress_dot_off",16,UIO)
def rewarded_badge(S):   # small round 🎬 badge for the Hint button corner
    B=S*SS; im=Image.new("RGBA",(B,B),(0,0,0,0)); d=ImageDraw.Draw(im)
    d.ellipse([B*0.04,B*0.04,B*0.96,B*0.96],fill=rgb(RASP),outline=rgb(CREAM),width=int(B*0.08))
    ic=draw_icon("rewarded",S*SS//2,CREAM); im.alpha_composite(ic,(B//4,B//4)); return down(im,(S,S))
both(rewarded_badge,"badge_rewarded",24,UIO)
def free_badge(S):
    B=S*SS; im=Image.new("RGBA",(B,B),(0,0,0,0)); d=ImageDraw.Draw(im)
    d.ellipse([B*0.04,B*0.04,B*0.96,B*0.96],fill=rgb(SAGE),outline=rgb(CREAM),width=int(B*0.08))
    d.text((B/2,B/2+B*0.02),"1",fill=rgb(CREAM),font=font("ui",B*0.5,700),anchor="mm"); return down(im,(S,S))
both(free_badge,"badge_free_hint",24,UIO)

# ---------------- pointer hand (tutorial) ----------------
def hand(S):
    B=S*SS; m=Image.new("L",(B,B),0); d=ImageDraw.Draw(m); u=B/100
    d.rounded_rectangle([34*u,6*u,50*u,62*u],radius=8*u,fill=255)            # index finger, pointing up
    d.rounded_rectangle([30*u,42*u,78*u,84*u],radius=14*u,fill=255)           # palm + folded-finger block (low knuckles)
    d.rounded_rectangle([46*u,40*u,78*u,58*u],radius=9*u,fill=255)
    m=blur(m,u*0.8).point(lambda v:255 if v>128 else 0)
    out=dilate(m,int(3*u)); im=Image.new("RGBA",(B,B),(0,0,0,0))
    im.alpha_composite(solid(blur(out,3*u),rgb(INK,70)),(int(2*u),int(3*u)))
    im.alpha_composite(solid(out,INK)); im.alpha_composite(solid(m,"#FFF1E4"))
    d2=ImageDraw.Draw(im); lw=int(2.4*u)
    for x in (57,67): d2.arc([(x-5)*u,40*u,(x+5)*u,56*u],200,340,fill=rgb(INK),width=lw)   # knuckle lines (folded fingers)
    d2.line([(56*u,49*u),(56*u,58*u)],fill=rgb(INK),width=lw); d2.line([(67*u,49*u),(67*u,58*u)],fill=rgb(INK),width=lw)
    d2.rounded_rectangle([24*u,58*u,62*u,72*u],radius=7*u,fill=rgb("#FFF1E4"),outline=rgb(INK),width=lw)   # thumb across the front
    d2.rounded_rectangle([30*u,84*u,78*u,96*u],radius=4*u,fill=rgb(RASP),outline=rgb(INK),width=int(2.6*u))   # cuff
    d2.ellipse([38*u,9*u,46*u,14*u],fill=rgb("#FFFFFF",150))
    im=im.rotate(12,resample=Image.BICUBIC,center=(B*0.5,B*0.6))
    return down(im,(S,S))
both(hand,"pointer_hand",96,UIO)

# ---------------- board: tray frame, hint, unit tint, steam ----------------
def tray(S,solved=False):
    B=S*SS; im=Image.new("RGBA",(B,B),(0,0,0,0)); d=ImageDraw.Draw(im); u=B/96
    sh=Image.new("L",(B,B),0); ImageDraw.Draw(sh).rounded_rectangle([3*u,6*u,B-3*u,B-1*u],radius=22*u,fill=255)
    im.alpha_composite(solid(blur(sh,3*u),rgb(INK,70)))
    rim,rim_dk,lining=(("#E2B05E","#B98235","#FCEBD0") if solved else (PEWTER,hx(shade(PEWTER,0.78)),CREAM))
    d.rounded_rectangle([2*u,2*u,B-2*u,B-3*u],radius=22*u,fill=rgb(rim_dk))
    d.rounded_rectangle([2*u,2*u,B-2*u,B-5*u],radius=22*u,fill=rgb(rim))
    g=Image.new("L",(B,B),0); ImageDraw.Draw(g).rounded_rectangle([12*u,4*u,B-12*u,8*u],radius=2*u,fill=120)
    im.alpha_composite(solid(blur(g,1.5*u),"#FFFFFF"))
    d.rounded_rectangle([10*u,10*u,B-10*u,B-12*u],radius=14*u,fill=rgb(lining),outline=rgb(rim_dk),width=int(1.5*u))
    return down(im,(S,S))
both(tray,"tray_frame",96,BOARD); both(lambda S: tray(S,True),"tray_frame_solved",96,BOARD)
def cellrect_overlay(S,fill_a,ring=None,glow=None):
    B=S*SS; im=Image.new("RGBA",(B,B),(0,0,0,0)); r=B*0.22
    if glow:
        g=Image.new("L",(B,B),0); ImageDraw.Draw(g).rounded_rectangle([0,0,B-1,B-1],radius=r,outline=255,width=int(B*0.16))
        mask=Image.new("L",(B,B),0); ImageDraw.Draw(mask).rounded_rectangle([0,0,B-1,B-1],radius=r,fill=255)
        g=ImageChops.multiply(blur(g,B*0.06),mask); im.alpha_composite(solid(g.point(lambda v:int(v*glow)),fill_a[0]))
    ImageDraw.Draw(im).rounded_rectangle([0,0,B-1,B-1],radius=r,fill=rgb(fill_a[0],fill_a[1]))
    return down(im,(S,S))
both(lambda S: cellrect_overlay(S,("#F2C14E",105),glow=1.0),"overlay_hint_unit",128,BOARD)
both(lambda S: cellrect_overlay(S,(CHERRY,40)),"overlay_conflict_unit",128,BOARD)
def hint_target(S):
    B=S*SS; im=Image.new("RGBA",(B,B),(0,0,0,0)); d=ImageDraw.Draw(im); r=B*0.22; lw=B*0.07
    g=Image.new("L",(B,B),0); ImageDraw.Draw(g).rounded_rectangle([lw,lw,B-lw,B-lw],radius=r,outline=255,width=int(lw*2))
    im.alpha_composite(solid(blur(g,B*0.03).point(lambda v:int(v*0.7)),"#FFE7A3"))
    d.rounded_rectangle([lw*0.5,lw*0.5,B-lw*0.5,B-lw*0.5],radius=r,outline=rgb(INK),width=int(lw*1.6))
    d.rounded_rectangle([lw*0.8,lw*0.8,B-lw*0.8,B-lw*0.8],radius=r*0.95,outline=rgb("#F2C14E"),width=int(lw*1.0))
    return down(im,(S,S))
both(hint_target,"overlay_hint_target",128,BOARD)
def steam(S):
    B=S*SS; m=Image.new("L",(B,B),0); d=ImageDraw.Draw(m); u=B/100
    for x0,ph,h in ((30,0.0,62),(50,0.6,76),(70,0.0,58)):
        n=h*2; pts=[(x0*u+8*u*math.sin(ph+t/7.0), (94-t)*u) for t in np.linspace(0,h,n)]
        for i,(x,y) in enumerate(pts):
            f=i/n; w=(3.6-1.8*f)*u; d.ellipse([x-w,y-w,x+w,y+w],fill=int(255*min(1,(1-f)*1.6)*min(1,f*6+0.3)))
    m=blur(m,1.2*u); im=Image.new("RGBA",(B,B),(0,0,0,0))
    edge=dilate(m.point(lambda v:255 if v>40 else 0),int(1.6*u)); edge=blur(edge,u).point(lambda v:int(v*0.35))
    im.alpha_composite(solid(ImageChops.multiply(edge,blur(m,3*u).point(lambda v:min(255,v*3))),INK)); im.alpha_composite(solid(m,"#FFFFFF"))
    return down(im,(S,S))
both(steam,"steam_puff",128,BOARD)

# ---------------- fonts ----------------
FD="/usr/share/fonts/truetype/sand-box/google/"
for src,dst in ((FD+"Lexend/Lexend-VariableFont_wght.ttf","Lexend-VariableFont_wght.ttf"),(FD+"DM Serif Display/DMSerifDisplay-Regular.ttf","DMSerifDisplay-Regular.ttf")):
    shutil.copy(src,f"{FNT}/{dst}"); written.append(f"{FNT}/{dst}")
tot=sum(os.path.getsize(p) for p in written)
json.dump({"files":[os.path.relpath(p,ROOT) for p in written],"bytes":tot},open(os.path.join(os.path.dirname(__file__),"p1_files.json"),"w"),indent=1)
print(len(written),"files",tot,"bytes")
