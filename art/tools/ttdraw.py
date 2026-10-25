"""Game #4 (tea-bakery) procedural art-direction renderer (Pillow + numpy). All original, no outside art."""
import math, numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageChops
import ttcolor as T

FD="/usr/share/fonts/truetype/sand-box/google/"
import os
_HERE=os.path.dirname(os.path.abspath(__file__))
UI_FONT=os.environ.get("TT_UI_FONT","lexend")  # "atkinson" = Atkinson Hyperlegible Next (static, from SD @a795a1a)
def font(kind,size,w=None):
    if kind=="ui" and UI_FONT=="atkinson":
        wt=700 if (w or 400)>=650 else (500 if (w or 400)>=450 else 400)
        return ImageFont.truetype(os.path.join(_HERE,"fonts","AtkinsonHyperlegibleNext-%s.ttf"%{400:"Regular",500:"Medium",700:"Bold"}[wt]),int(size))
    p={"display":FD+"DM Serif Display/DMSerifDisplay-Regular.ttf",
       "ui":FD+"Lexend/Lexend-VariableFont_wght.ttf",
       "script":FD+"Dancing Script/DancingScript-VariableFont_wght.ttf"}[kind]
    f=ImageFont.truetype(p,int(size))
    if w is not None:
        try: f.set_variation_by_axes([w])
        except Exception: pass
    return f

UI={n:h for n,h,_ in T.UI}
REG=[(n,h,p) for n,h,p in T.REGIONS]
def rgb(h,a=255):
    c=tuple(int(h.lstrip('#')[i:i+2],16) for i in (0,2,4)); return c+(a,)
def shade(h,f):  # f<1 darker, >1 lighter (mix to white)
    c=np.array(rgb(h)[:3],float)
    c = c*f if f<=1 else c+(255-c)*(f-1)
    return tuple(int(x) for x in np.clip(c,0,255))+(255,)
def mix(h1,h2,t):
    a=np.array(rgb(h1)[:3]);b=np.array(rgb(h2)[:3]);return tuple(int(x) for x in a*(1-t)+b*t)+(255,)

# ---------------- puzzle generation ----------------
def gen_board(n,seed):
    rng=np.random.default_rng(seed)
    for _ in range(5000):
        q=[];ok=True;cols=set()
        def bt(r):
            if r==n: return True
            cs=list(range(n)); rng.shuffle(cs)
            for c in cs:
                if c in cols: continue
                if q and abs(q[-1]-c)<=1: continue
                q.append(c);cols.add(c)
                if bt(r+1): return True
                q.pop();cols.discard(c)
            return False
        if bt(0): break
    reg=-np.ones((n,n),int)
    front=[]
    for r,c in enumerate(q): reg[r,c]=r; front.append((r,c))
    while (reg<0).any():
        r,c=front[rng.integers(len(front))]
        nb=[(r+dr,c+dc) for dr,dc in((1,0),(-1,0),(0,1),(0,-1)) if 0<=r+dr<n and 0<=c+dc<n and reg[r+dr,c+dc]<0]
        if not nb: continue
        rr,cc=nb[rng.integers(len(nb))]; reg[rr,cc]=reg[r,c]; front.append((rr,cc))
    # shuffle region->colour so neighbours vary
    perm=rng.permutation(n); reg=perm[reg]
    return reg,[(r,c) for r,c in enumerate(q)]

# ---------------- patterns ----------------
def pattern_layer(kind,W,H,unit,ink,rng_seed=1):
    """RGBA layer of the pattern in ink colour, transparent background. unit ~ cell/4"""
    im=Image.new("RGBA",(W,H),(0,0,0,0)); d=ImageDraw.Draw(im)
    u=max(4,unit); lw=max(1,int(u*0.22))
    rng=np.random.default_rng(rng_seed)
    if kind=="dots":
        r=u*0.20
        for y in range(0,H+u,u):
            off=(u//2) if (y//u)%2 else 0
            for x in range(-u,W+u,u): d.ellipse([x+off-r,y-r,x+off+r,y+r],fill=ink)
    elif kind=="stripes":
        for x in range(-H,W+H,u): d.line([(x,0),(x+H,H)],fill=ink,width=lw)
    elif kind=="pinstripe":
        for x in range(0,W,u): d.line([(x,0),(x,H)],fill=ink,width=max(1,lw//1))
    elif kind=="gingham":
        a=ink[:3]+(int(ink[3]*0.55),)
        g=Image.new("RGBA",(W,H),(0,0,0,0)); gd=ImageDraw.Draw(g)
        for x in range(0,W,u*2): gd.rectangle([x,0,x+u-1,H],fill=a)
        g2=Image.new("RGBA",(W,H),(0,0,0,0)); gd2=ImageDraw.Draw(g2)
        for y in range(0,H,u*2): gd2.rectangle([0,y,W,y+u-1],fill=a)
        im=Image.alpha_composite(g,g2)
        # overlap darker
        return im
    elif kind=="lattice":
        s=int(u*1.6); w=max(2,int(u*0.32))
        for x in range(-H,W+H,s):
            d.line([(x,0),(x+H,H)],fill=ink,width=w); d.line([(x+H,0),(x,H)],fill=ink,width=w)
    elif kind=="crumb":
        for _ in range(int(W*H/(u*u)*1.6)):
            x,y=rng.uniform(0,W),rng.uniform(0,H); r=rng.uniform(0.08,0.2)*u
            d.ellipse([x-r,y-r*0.8,x+r,y+r*0.8],fill=ink)
    elif kind=="shortbread":  # offset brick outline
        bh=u; bw=u*2
        for y in range(0,H+bh,bh):
            d.line([(0,y),(W,y)],fill=ink,width=lw)
            off=u if (y//bh)%2 else 0
            for x in range(-bw+off,W+bw,bw): d.line([(x,y),(x,y+bh)],fill=ink,width=lw)
    elif kind=="diamond":  # argyle-style outlined diamonds
        s_=int(u*1.8); h_=s_/2
        for y in range(0,H+s_,s_):
            for x in range(0,W+s_,s_):
                xo=x+(h_ if (y//s_)%2 else 0)
                d.polygon([(xo,y-h_*0.55),(xo+h_*0.45,y),(xo,y+h_*0.55),(xo-h_*0.45,y)],outline=ink,width=max(1,lw))
    elif kind=="sprig":
        s=int(u*1.5); r=u*0.16
        for y in range(0,H+s,s):
            off=s//2 if (y//s)%2 else 0
            for x in range(-s,W+s,s):
                cx,cy=x+off,y
                for k in range(4):
                    a=k*math.pi/2+math.pi/4
                    px,py=cx+math.cos(a)*r*1.3,cy+math.sin(a)*r*1.3
                    d.ellipse([px-r,py-r,px+r,py+r],fill=ink)
    return im

# ---------------- pieces ----------------
def piece(kind,size,style,_raw=False):
    """Return RGBA icon of a bakery piece rendered big then reduced.
    Berry v2 approved for option B (2026-10-25): style B berry/tart -> berry2 unless _raw=True."""
    if not _raw and style=="B" and kind in ("berry","tart"): kind="berry2"
    B=256; im=Image.new("RGBA",(B,B),(0,0,0,0)); d=ImageDraw.Draw(im)
    ink=rgb(UI["earl_grey_ink"]); jam=rgb(UI["raspberry_jam"]); crust=rgb("#E2A35C"); crustD=rgb("#B9783A")
    cream=rgb("#FFF6E8"); gold=rgb("#C99A3B")
    ow={"A":0,"B":12,"C":9}[style]
    oc= ink if style!="C" else rgb("#7A3F5C")
    def poly(pts,fill):
        if ow: d.polygon(pts,fill=fill,outline=oc,width=ow)
        else: d.polygon(pts,fill=fill)
    def ell(b,fill,w=None):
        d.ellipse(b,fill=fill,outline=oc if ow else None,width=(w or ow) if ow else 0)
    v2 = (kind=="berry2")
    if v2:
        kind="berry"; crust=rgb("#F2C584"); crustD=rgb("#DDA766")
    if kind in ("tart","berry","lattice","lemon"):
        cx=cy=B/2; R=104; n=18
        pts=[]
        for i in range(n*8):
            a=2*math.pi*i/(n*8); rr=R-7+7*abs(math.cos(n*a/2))
            pts.append((cx+rr*math.cos(a),cy+rr*math.sin(a)))
        poly(pts,crust)
        d.ellipse([cx-86,cy-86,cx+86,cy+86],fill=crustD)  # inner rim shadow
        fill=rgb("#F3CF4E") if kind=="lemon" else jam
        ell([cx-78,cy-78,cx+78,cy+78],fill,max(ow-4,0) if ow else None)
        if kind in("tart","berry"):
            rng=np.random.default_rng(2)
            berries=[(0,0)]+[(46*math.cos(k*math.pi/3),46*math.sin(k*math.pi/3)) for k in range(6)]
            for bx,by in berries:
                br=24
                d.ellipse([cx+bx-br,cy+by-br,cx+bx+br,cy+by+br],fill=rgb("#B83A5E" if v2 else "#8E1F3F"),outline=oc if ow else None,width=max(ow//3,0) if ow else 0)
                d.ellipse([cx+bx-br*0.55,cy+by-br*0.6,cx+bx-br*0.05,cy+by-br*0.15],fill=(255,255,255,110))
        elif kind=="lattice":
            lw_=16
            for k in (-50,0,50):
                d.line([(cx+k-60,cy-70),(cx+k+60,cy+70)] if False else [(cx+k,cy-math.sqrt(max(0,78**2-k**2))),(cx+k,cy+math.sqrt(max(0,78**2-k**2)))],fill=crust,width=lw_)
                d.line([(cx-math.sqrt(max(0,78**2-k**2)),cy+k),(cx+math.sqrt(max(0,78**2-k**2)),cy+k)],fill=crust,width=lw_)
            if ow:
                for k in (-50,0,50):
                    L_=math.sqrt(78**2-k**2)
                    for o in (-lw_/2,lw_/2):
                        d.line([(cx+k+o,cy-L_),(cx+k+o,cy+L_)],fill=oc,width=max(2,ow//4))
        elif kind=="lemon":
            # piped cream swirl centre
            for r_,a_ in ((34,255),(22,255)):
                d.ellipse([cx-r_,cy-r_,cx+r_,cy+r_],fill=cream,outline=oc if ow else rgb("#E8D9B8"),width=max(ow//3,3))
            d.ellipse([cx-40,cy-58,cx-4,cy-44],fill=(255,255,255,120))
    elif kind=="slice":
        # wedge side view: point at left
        sp=rgb("#F6D88E")
        top=[(30,150),(226,96),(226,128),(30,174)]
        body=[(30,150),(226,128),(226,214),(30,190)]
        poly(body,sp)
        d.polygon([(30,168),(226,160),(226,176),(30,178)],fill=jam)  # jam layer
        poly([(30,148),(226,92),(226,128),(30,152)],rgb("#FAD3DD"))  # frosting top
        if ow: d.line([(30,150),(226,128)],fill=oc,width=ow//2)
        ell([170,52,214,96],jam)  # cherry
        d.ellipse([180,60,192,72],fill=(255,255,255,150))
        d.line([(196,56),(214,30)],fill=rgb("#55724E"),width=8)
    elif kind=="cupcake":
        wr=rgb("#F3B7C5")
        poly([(64,130),(192,130),(172,226),(84,226)],wr)
        for x in (100,128,156): d.line([(x,134),(x-4+ (x-128)*-0.0,222)],fill=shade("#F3B7C5",0.75),width=7)
        ell([48,70,208,150],cream)
        ell([78,40,178,110],cream)
        ell([108,8,148,48],jam)
        d.ellipse([116,16,126,26],fill=(255,255,255,150))
    if style=="A":
        # watercolour: soft edges, slight bleed + granulation
        a=im.split()[3]
        blur=im.filter(ImageFilter.GaussianBlur(3))
        noise=Image.fromarray((np.random.default_rng(3).normal(0,10,(B,B))).clip(-30,30).astype(np.int16).astype(np.uint8)+128) if False else None
        arr=np.array(blur).astype(float)
        g=np.random.default_rng(7).normal(1,0.05,(B,B,1))
        arr[...,:3]=np.clip(arr[...,:3]*g,0,255)
        # darker pigment edge
        edge=np.array(a.filter(ImageFilter.FIND_EDGES).filter(ImageFilter.GaussianBlur(2))).astype(float)/255
        arr[...,:3]*= (1-0.25*edge[...,None])
        im=Image.fromarray(arr.astype(np.uint8),"RGBA")
    if v2:
        # cream halo outside the ink outline so the piece pops off dark/busy patches
        a=im.split()[3]
        halo=a.filter(ImageFilter.MaxFilter(25))
        g=Image.new("RGBA",(B,B),rgb("#FFF8EC")); g.putalpha(halo)
        im=Image.alpha_composite(g,im)
    if style=="C":
        # gilded rim: thin gold outline outside
        a=im.split()[3]
        rim=a.filter(ImageFilter.MaxFilter(9))
        g=Image.new("RGBA",(B,B),gold); g.putalpha(rim)
        im=Image.alpha_composite(g,im)
    # soft drop shadow
    a=im.split()[3]
    sh=Image.new("RGBA",(B+24,B+24),(0,0,0,0))
    s=Image.new("RGBA",(B,B),rgb(UI["earl_grey_ink"],0)); s.putalpha(a.point(lambda v:int(v*0.35)))
    sh.paste(s,(14,18),s); sh=sh.filter(ImageFilter.GaussianBlur(7))
    sh.alpha_composite(im,(12,12))
    return sh.resize((size,size),Image.LANCZOS)

# ---------------- icons ----------------
def icon(d,kind,cx,cy,s,col,w,bg=(255,248,236,255)):
    if kind=="undo":
        d.arc([cx-s,cy-s*0.8,cx+s,cy+s*0.9],200,90,fill=col,width=w)
        d.polygon([(cx-s*1.15,cy-s*0.6),(cx-s*0.35,cy-s*0.75),(cx-s*0.95,cy+s*0.05)],fill=col)
    elif kind=="x":
        d.line([(cx-s*0.7,cy-s*0.7),(cx+s*0.7,cy+s*0.7)],fill=col,width=w)
        d.line([(cx-s*0.7,cy+s*0.7),(cx+s*0.7,cy-s*0.7)],fill=col,width=w)
    elif kind=="mold":  # empty fluted tart tin
        n=12; pts=[]
        for i in range(n*8+1):
            a=2*math.pi*i/(n*8); rr=s*(0.82+0.14*abs(math.cos(n*a/2)))
            pts.append((cx+rr*math.cos(a),cy+rr*math.sin(a)))
        d.line(pts,fill=col,width=w,joint="curve")
        d.ellipse([cx-s*0.48,cy-s*0.48,cx+s*0.48,cy+s*0.48],outline=col,width=max(1,int(w*0.7)))
    elif kind=="hint":  # sparkle
        pts=[]
        for i in range(8):
            a=i*math.pi/4-math.pi/2; r=s if i%2==0 else s*0.32
            pts.append((cx+r*math.cos(a),cy+r*math.sin(a)))
        d.polygon(pts,fill=col)
    elif kind=="erase":
        d.rounded_rectangle([cx-s*0.9,cy-s*0.45,cx+s*0.9,cy+s*0.45],radius=s*0.2,outline=col,width=w)
        d.line([(cx-s*0.1,cy-s*0.45),(cx-s*0.1,cy+s*0.45)],fill=col,width=w)
    elif kind=="back":
        d.line([(cx+s*0.6,cy),(cx-s*0.6,cy)],fill=col,width=w)
        d.line([(cx-s*0.6,cy),(cx-s*0.05,cy-s*0.55)],fill=col,width=w)
        d.line([(cx-s*0.6,cy),(cx-s*0.05,cy+s*0.55)],fill=col,width=w)
    elif kind=="sound":
        d.polygon([(cx-s*0.8,cy-s*0.3),(cx-s*0.35,cy-s*0.3),(cx+s*0.15,cy-s*0.75),(cx+s*0.15,cy+s*0.75),(cx-s*0.35,cy+s*0.3),(cx-s*0.8,cy+s*0.3)],fill=col)
        d.arc([cx-s*0.2,cy-s*0.6,cx+s*0.8,cy+s*0.6],-50,50,fill=col,width=w)
    elif kind=="gear":
        for i in range(8):
            a=i*math.pi/4
            d.line([(cx+math.cos(a)*s*0.4,cy+math.sin(a)*s*0.4),(cx+math.cos(a)*s*0.95,cy+math.sin(a)*s*0.95)],fill=col,width=int(w*1.6))
        d.ellipse([cx-s*0.7,cy-s*0.7,cx+s*0.7,cy+s*0.7],fill=col)
        d.ellipse([cx-s*0.3,cy-s*0.3,cx+s*0.3,cy+s*0.3],fill=bg)
    elif kind=="star":
        pts=[]
        for i in range(10):
            a=i*math.pi/5-math.pi/2; r=s if i%2==0 else s*0.45
            pts.append((cx+r*math.cos(a),cy+r*math.sin(a)))
        d.polygon(pts,fill=col)
    elif kind=="check":
        d.line([(cx-s*0.6,cy),(cx-s*0.15,cy+s*0.5),(cx+s*0.7,cy-s*0.55)],fill=col,width=w,joint="curve")
    elif kind=="teacup":
        d.chord([cx-s,cy-s*0.6,cx+s*0.7,cy+s*0.9],0,180,fill=col)
        d.rectangle([cx-s,cy+s*0.12,cx+s*0.7,cy+s*0.16],fill=col)
        d.arc([cx+s*0.45,cy,cx+s*1.05,cy+s*0.55],-90,90,fill=col,width=w)
        d.ellipse([cx-s*1.2,cy+s*0.75,cx+s*0.9,cy+s*0.95],fill=col)

def teapot(d,cx,cy,s,body,lid,ink,ow):
    d.polygon([(cx+s*0.7,cy),(cx+s*1.35,cy-s*0.55),(cx+s*1.45,cy-s*0.5),(cx+s*0.85,cy+s*0.3)],fill=body,outline=ink,width=ow)
    d.arc([cx-s*1.35,cy-s*0.45,cx-s*0.55,cy+s*0.45],90,270,fill=ink if ow else body,width=max(ow,int(s*0.14))+2)
    d.ellipse([cx-s,cy-s*0.75,cx+s,cy+s*0.85],fill=body,outline=ink,width=ow)
    d.chord([cx-s*0.55,cy-s*1.0,cx+s*0.55,cy-s*0.45],180,360,fill=lid,outline=ink,width=ow)
    d.ellipse([cx-s*0.14,cy-s*1.18,cx+s*0.14,cy-s*0.92],fill=lid,outline=ink,width=ow)
    d.rectangle([cx-s*0.95,cy+s*0.05,cx+s*0.95,cy+s*0.2],fill=lid)

def cakestand(d,cx,cy,s,plate,cakes,ink,ow):
    d.rectangle([cx-s*0.06,cy-s*1.6,cx+s*0.06,cy],fill=plate)
    for i,(yy,ww) in enumerate([(cy,1.0),(cy-s*0.8,0.7)]):
        for k in range(3 if i==0 else 2):
            off=(k-(1 if i==0 else 0.5))*s*0.55
            c=cakes[(i+k)%len(cakes)]
            d.chord([cx+off-s*0.22,yy-s*0.36,cx+off+s*0.22,yy+s*0.08],180,360,fill=c,outline=ink,width=ow)
        d.ellipse([cx-s*ww,yy-s*0.08,cx+s*ww,yy+s*0.1],fill=plate,outline=ink,width=ow)
    d.ellipse([cx-s*0.12,cy-s*1.78,cx+s*0.12,cy-s*1.56],fill=plate,outline=ink,width=ow)
    d.ellipse([cx-s*0.45,cy+s*0.5,cx+s*0.45,cy+s*0.62],fill=plate,outline=ink,width=ow)
    d.rectangle([cx-s*0.06,cy,cx+s*0.06,cy+s*0.55],fill=plate)
