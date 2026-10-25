"""Option B2 (B revised per Shahar 2026-10-25): cookie-tile board, empty cake mold, 9 distinct cakes.
Original work (PKD). No rectangular frosted pastry, no sprinkles, no 'pop'."""
import math, numpy as np
from PIL import Image, ImageDraw, ImageFilter
from ttdraw import rgb, shade, mix, UI, REG, pattern_layer, piece, font, icon
import ttcolor as T

INK=UI["earl_grey_ink"]; CREAM="#FFF8EC"
TRAY_GAP="#FFF8EC"   # parchment lining on the pewter tray shows between regions (best min contrast vs all 9 patches incl. rim: 2.3:1)
# region index -> cake (chosen for contrast against its own patch)
CAKE_FOR_REGION=["lemon","berry","victoria","apricot","bakewell","custard","macaron","scone","chocolate"]
CAKE_NAMES={"berry":"Berry tart","lemon":"Lemon tart","victoria":"Victoria sponge slice","scone":"Scone, jam & cream",
 "bakewell":"Cherry Bakewell","chocolate":"Chocolate tart","macaron":"Rose macaron","custard":"Custard tart","apricot":"Apricot tart"}

def _fluted(d,cx,cy,R,n,fill,oc,ow,depth=7):
    pts=[]
    for i in range(n*8):
        a=2*math.pi*i/(n*8); rr=R-depth+depth*abs(math.cos(n*a/2))
        pts.append((cx+rr*math.cos(a),cy+rr*math.sin(a)))
    d.polygon(pts,fill=fill,outline=oc,width=ow)

def _finish(im,B=256,halo=True):
    if halo:
        a=im.split()[3]; h=a.filter(ImageFilter.MaxFilter(23))
        g=Image.new("RGBA",(B,B),rgb(CREAM)); g.putalpha(h); im=Image.alpha_composite(g,im)
    a=im.split()[3]
    sh=Image.new("RGBA",(B+24,B+24),(0,0,0,0))
    s=Image.new("RGBA",(B,B),rgb(INK,0)); s.putalpha(a.point(lambda v:int(v*0.33)))
    sh.paste(s,(14,18),s); sh=sh.filter(ImageFilter.GaussianBlur(7)); sh.alpha_composite(im,(12,12))
    return sh

def cake(kind,size):
    if kind=="berry": return piece("berry2",size,"B",_raw=True)
    B=256; im=Image.new("RGBA",(B,B),(0,0,0,0)); d=ImageDraw.Draw(im)
    oc=rgb(INK); ow=10; cx=cy=B/2
    crust=rgb("#F2C584"); crustD=rgb("#DDA766"); hl=(255,255,255,130)
    if kind in("lemon","chocolate","custard","apricot"):
        if kind=="custard": _fluted(d,cx,cy,106,26,crust,oc,ow,depth=12)   # crimped edge
        else: _fluted(d,cx,cy,104,18,crust,oc,ow)
        d.ellipse([cx-86,cy-86,cx+86,cy+86],fill=crustD)
        fill={"lemon":"#F6D453","chocolate":"#5A3230","custard":"#EDBE5E","apricot":"#F7CB7A"}[kind]
        d.ellipse([cx-78,cy-78,cx+78,cy+78],fill=rgb(fill),outline=oc,width=6)
        if kind=="lemon":
            r=34; d.ellipse([cx-r,cy-r,cx+r,cy+r],fill=rgb("#FFF3B8"),outline=rgb("#D9B52E"),width=6)
            for k in range(8):
                a=k*math.pi/4; d.line([(cx,cy),(cx+math.cos(a)*r*0.85,cy+math.sin(a)*r*0.85)],fill=rgb("#E8C640"),width=4)
            d.ellipse([cx+20,cy-56,cx+58,cy-36],fill=rgb(UI["sage_leaf"]))
            d.ellipse([cx-60,cy-60,cx-28,cy-44],fill=hl)
        elif kind=="chocolate":
            d.ellipse([cx-62,cy-64,cx-10,cy-40],fill=(255,255,255,70))
            br=20; bx,by=cx+18,cy+10
            d.ellipse([bx-br,by-br,bx+br,by+br],fill=rgb("#C2335A"),outline=oc,width=4)
            for k in range(5):
                a=k*2*math.pi/5; d.ellipse([bx+math.cos(a)*9-5,by+math.sin(a)*9-5,bx+math.cos(a)*9+5,by+math.sin(a)*9+5],fill=rgb("#E0607F"))
            d.polygon([(cx-30,cy+24),(cx-14,cy+18),(cx-20,cy+34)],fill=rgb("#E7C46A"))  # gold leaf
        elif kind=="custard":
            g=Image.new("RGBA",(B,B),(0,0,0,0)); gd=ImageDraw.Draw(g)
            gd.ellipse([cx-60,cy-60,cx+60,cy+60],fill=rgb("#C98A3A",150))   # baked golden-brown centre
            g=g.filter(ImageFilter.GaussianBlur(16)); im.alpha_composite(g); d=ImageDraw.Draw(im)
            rng=np.random.default_rng(9)
            for _ in range(70):   # grated-nutmeg dusting: fine brown specks (not coloured sprinkles)
                r_=rng.uniform(0,66); a_=rng.uniform(0,2*math.pi); s_=rng.uniform(2.5,5)
                px,py=cx+r_*math.cos(a_),cy+r_*math.sin(a_)
                d.ellipse([px-s_,py-s_,px+s_,py+s_],fill=rgb("#7A4A26",210))
            d.ellipse([cx-58,cy-62,cx-24,cy-46],fill=hl)
        elif kind=="apricot":
            pos=[(0,0)]+[(48*math.cos(k*math.pi/3+0.5),48*math.sin(k*math.pi/3+0.5)) for k in range(6)]
            for px,py in pos:
                r=25; X,Y=cx+px,cy+py
                d.ellipse([X-r,Y-r,X+r,Y+r],fill=rgb("#EE8A2E"),outline=oc,width=5)
                d.ellipse([X-r*0.55,Y-r*0.6,X-r*0.05,Y-r*0.15],fill=(255,236,200,170))
    elif kind=="bakewell":
        d.ellipse([cx-104,cy-104,cx+104,cy+104],fill=crust,outline=oc,width=ow)       # plain round edge (custard is crimped)
        d.ellipse([cx-90,cy-90,cx+90,cy+90],fill=rgb("#FFFFFF"),outline=rgb("#E6DCD0"),width=4)  # white icing
        # one feathered line: a soft S-curve in raspberry
        pts=[(cx-70+k*4,cy+38+14*math.sin(k/5.0)) for k in range(36)]
        d.line(pts,fill=rgb("#D9839A"),width=7,joint="curve")
        br=40; d.ellipse([cx-br,cy-br-12,cx+br,cy+br-12],fill=rgb("#C21D3A"),outline=oc,width=7)   # prominent glacé cherry
        d.ellipse([cx-24,cy-40,cx-6,cy-24],fill=(255,255,255,170))
        d.line([(cx+6,cy-50),(cx+30,cy-92)],fill=rgb(UI["sage_leaf"]),width=8)
    elif kind=="victoria":
        # ~15% thicker than v1 (avg thickness 99 -> 114 px at 256)
        X0,X1=22,234
        top=lambda t:151-92*t; bot=lambda t:216+6*t
        def band(f0,f1):
            return [(X0,top(0)+(bot(0)-top(0))*f0),(X1,top(1)+(bot(1)-top(1))*f0),(X1,top(1)+(bot(1)-top(1))*f1),(X0,top(0)+(bot(0)-top(0))*f1)]
        body=[(X0,top(0)),(X1,top(1)),(X1,bot(1)),(X0,bot(0))]
        d.polygon(body,fill=rgb("#F2CF87"))
        d.polygon(band(0.0,0.11),fill=rgb("#FDF7EC"))              # sugar-dusted top
        d.polygon(band(0.44,0.58),fill=rgb("#FFF6E8"))             # cream
        d.polygon(band(0.58,0.70),fill=rgb(UI["raspberry_jam"]))   # jam
        d.polygon(body,outline=oc,width=ow)
        d.chord([178,46,234,102],180,360,fill=rgb("#D8344F"),outline=oc,width=5)
        d.polygon([(194,50),(206,36),(218,50)],fill=rgb(UI["sage_leaf"]))
    elif kind=="scone":
        d.chord([36,108,220,236],180,360,fill=rgb("#E7B36E"),outline=oc,width=ow)
        d.rectangle([40,170,216,212],fill=rgb("#E7B36E"))
        d.rounded_rectangle([36,166,220,214],radius=26,fill=rgb("#E7B36E"),outline=oc,width=ow)
        d.ellipse([46,96,210,190],fill=rgb("#D99A52"),outline=oc,width=ow)          # golden top
        d.ellipse([70,70,186,148],fill=rgb("#FFF6E8"),outline=oc,width=7)            # clotted cream
        d.ellipse([96,44,160,100],fill=rgb("#B5243F"),outline=oc,width=6)            # jam
        d.ellipse([110,52,126,66],fill=hl)
    elif kind=="macaron":
        # front-on single macaron, few big shapes: dome shell / ruffled foot / thick cream band / base shell
        shell=rgb("#EC93AA"); foot=shade("#EC93AA",0.80)
        d.chord([28,112,228,226],0,180,fill=shell,outline=oc,width=ow)            # base shell (lower half-ellipse)
        d.rounded_rectangle([40,120,216,174],radius=22,fill=rgb("#FFF6E8"),outline=oc,width=8)  # cream filling
        d.rectangle([38,98,218,116],fill=foot)                                     # foot: one ruffled band
        for x in range(46,214,21): d.ellipse([x-12,104,x+12,126],fill=foot)       # soft scalloped lower edge
        d.chord([28,30,228,170],180,360,fill=shell,outline=oc,width=ow)            # dome top shell
        d.ellipse([70,52,130,78],fill=hl)
    return _finish(im).resize((size,size),Image.LANCZOS)

def mold(size, on_hex=None):
    """Empty fluted tart tin: outline only (patch shows through), no halo, no shadow -> clearly 'no cake here'."""
    B=256; im=Image.new("RGBA",(B,B),(0,0,0,0)); d=ImageDraw.Draw(im)
    cx=cy=B/2; n=16; R=96; depth=10
    pts=[]
    for i in range(n*8+1):
        a=2*math.pi*i/(n*8); rr=R-depth+depth*abs(math.cos(n*a/2))
        pts.append((cx+rr*math.cos(a),cy+rr*math.sin(a)))
    d.line(pts,fill=rgb(INK,215),width=14,joint="curve")
    d.ellipse([cx-58,cy-58,cx+58,cy+58],outline=rgb(INK,170),width=9)
    return im.resize((size,size),Image.LANCZOS)

def _round_mask(mask,r):
    return mask.filter(ImageFilter.GaussianBlur(r)).point(lambda v:255 if v>127 else 0).filter(ImageFilter.GaussianBlur(1))

def render_board_b2(n,reg,cells,size,seed=1,tray=True):
    cell=size/n; gap=max(2,cell*0.075); rad=cell*0.22
    im=Image.new("RGBA",(size,size),rgb(TRAY_GAP))
    unit=max(6,int(cell*0.27))
    for k in [int(v) for v in np.unique(reg)]:
        name,hx,pat=REG[k]
        # region mask: rounded tiles + bridges between same-region neighbours
        m=Image.new("L",(size,size),0); md=ImageDraw.Draw(m)
        tiles=Image.new("L",(size,size),0); td=ImageDraw.Draw(tiles)
        for r in range(n):
            for c in range(n):
                if reg[r,c]!=k: continue
                x0,y0=c*cell+gap/2,r*cell+gap/2; x1,y1=(c+1)*cell-gap/2,(r+1)*cell-gap/2
                md.rounded_rectangle([x0,y0,x1,y1],radius=rad,fill=255); td.rounded_rectangle([x0,y0,x1,y1],radius=rad,fill=255)
                if c<n-1 and reg[r,c+1]==k: md.rectangle([x1-rad,y0+rad*0.5,x1+gap+rad,y1-rad*0.5],fill=255)
                if r<n-1 and reg[r+1,c]==k: md.rectangle([x0+rad*0.5,y1-rad,x1-rad*0.5,y1+gap+rad],fill=255)
                if c<n-1 and r<n-1 and reg[r,c+1]==k and reg[r+1,c]==k and reg[r+1,c+1]==k:
                    md.rectangle([x1-rad,y1-rad,x1+gap+rad,y1+gap+rad],fill=255)
        m=m.filter(ImageFilter.GaussianBlur(0.6))
        # base: darker tint = seams + rim
        rim=shade(hx,0.72); seam=shade(hx,0.93)
        base=Image.new("RGBA",(size,size),seam)
        # tile faces: region colour + pattern, inset slightly so rim shows around region edge
        face=Image.new("RGBA",(size,size),rgb(hx))
        ink=shade(hx,0.82)[:3]+(150,)
        face.alpha_composite(pattern_layer(pat,size,size,unit,ink,rng_seed=k+3))
        # soft top-left highlight per tile (cookie bevel)
        hl=Image.new("RGBA",(size,size),(0,0,0,0)); hd=ImageDraw.Draw(hl)
        for r in range(n):
            for c in range(n):
                if reg[r,c]!=k: continue
                x0,y0=c*cell+gap/2,r*cell+gap/2; x1,y1=(c+1)*cell-gap/2,(r+1)*cell-gap/2
                hd.rounded_rectangle([x0+cell*0.06,y0+cell*0.05,x1-cell*0.25,y0+cell*0.16],radius=cell*0.06,fill=(255,255,255,55))
        hl=hl.filter(ImageFilter.GaussianBlur(cell*0.04)); face.alpha_composite(hl)
        tin=tiles.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.8))
        base.paste(face,(0,0),tin)
        # soft darker-tint rim around the whole region (no ink)
        edge=Image.fromarray(np.clip(np.array(m).astype(int)-np.array(m.filter(ImageFilter.MinFilter(int(max(3,cell*0.08))|1))).astype(int),0,255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.7))
        rl=Image.new("RGBA",(size,size),rim); base.paste(rl,(0,0),edge)
        im.paste(base,(0,0),m)
    # cell contents
    for (r,c),state in cells.items():
        k=int(reg[r,c]); cx,cy=(c+0.5)*cell,(r+0.5)*cell; x0,y0=c*cell+gap/2,r*cell+gap/2; w=cell-gap
        d=ImageDraw.Draw(im)
        if state=="x":
            mm=mold(int(cell*0.62)); im.alpha_composite(mm,(int(cx-mm.width/2),int(cy-mm.height/2)))
            continue
        if state in("cake","conflict","solved"):
            if state=="solved":
                gl=Image.new("RGBA",(int(cell),int(cell)),(0,0,0,0)); gd=ImageDraw.Draw(gl)
                gd.ellipse([cell*0.04,cell*0.04,cell*0.96,cell*0.96],fill=rgb(UI["toasted_crust"],150))
                im.alpha_composite(gl.filter(ImageFilter.GaussianBlur(cell*0.08)),(int(c*cell),int(r*cell)))
            if state=="conflict":
                hl=Image.new("RGBA",(int(w)+1,int(w)+1),(0,0,0,0)); hd=ImageDraw.Draw(hl)
                for t in range(-int(w),int(w)*2,max(4,int(cell/6))):
                    hd.line([(t,0),(t-w,w)],fill=rgb(UI["cherry_alert"],120),width=max(2,int(cell*0.05)))
                mk=Image.new("L",hl.size,0); ImageDraw.Draw(mk).rounded_rectangle([0,0,w,w],radius=rad,fill=255)
                hl.putalpha(Image.fromarray(np.minimum(np.array(hl.split()[3]),np.array(mk))))
                im.alpha_composite(hl,(int(x0),int(y0)))
            ck=cake(CAKE_FOR_REGION[k],int(cell*0.92))
            im.alpha_composite(ck,(int(cx-ck.width/2),int(cy-ck.height/2+cell*0.02)))
            d=ImageDraw.Draw(im)
            if state=="conflict":
                lw=max(3,int(cell*0.075))
                d.rounded_rectangle([x0+lw/2,y0+lw/2,x0+w-lw/2,y0+w-lw/2],radius=rad,outline=rgb(UI["cherry_alert"]),width=lw)
                br=cell*0.17; bx,by=x0+w-br*0.9,y0+br*0.9
                d.ellipse([bx-br,by-br,bx+br,by+br],fill=rgb(UI["cherry_alert"]),outline=rgb(CREAM),width=max(1,int(br*0.18)))
                d.text((bx,by),"!",fill=rgb(CREAM),font=font("ui",br*1.5,800),anchor="mm")
            if state=="solved":
                br=cell*0.15; bx,by=x0+w-br*0.9,y0+w-br*0.9
                d.ellipse([bx-br,by-br,bx+br,by+br],fill=rgb(UI["sage_leaf"]),outline=rgb(CREAM),width=max(1,int(br*0.15)))
                icon(d,"check",bx,by,br*0.75,rgb(CREAM),max(2,int(br*0.3)))
    return im
