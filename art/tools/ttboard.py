import math, numpy as np
from PIL import Image, ImageDraw, ImageFilter
from ttdraw import *

STYLES={
 "A":{"name":"Watercolour Tea Room","fill_mix":0.12,"pat_f":0.80,"pat_a":105,"border_w":0.055,"border_a":175},
 "B":{"name":"Crisp Pastry Flat","fill_mix":0.0,"pat_f":0.82,"pat_a":150,"border_w":0.07,"border_a":255},
 "C":{"name":"Vintage China & Stitch","fill_mix":0.08,"pat_f":0.72,"pat_a":120,"border_w":0.05,"border_a":255},
}
PLUM="#7A3F5C"

def x_mark(d,cx,cy,cell,style,alpha=200):
    s=cell*0.17; w=max(2,int(cell*0.075))
    ink=rgb(UI["earl_grey_ink"],alpha)
    if style=="C":
        col=rgb(PLUM,235)
        for sgn in (1,-1):
            d.line([(cx-s,cy-sgn*s),(cx+s,cy+sgn*s)],fill=col,width=w)
        for (px,py) in [(cx-s,cy-s),(cx+s,cy+s),(cx-s,cy+s),(cx+s,cy-s)]:
            d.ellipse([px-w*0.35,py-w*0.35,px+w*0.35,py+w*0.35],fill=rgb("#FFF8EC",200))
    else:
        d.line([(cx-s,cy-s),(cx+s,cy+s)],fill=ink,width=w)
        d.line([(cx-s,cy+s),(cx+s,cy-s)],fill=ink,width=w)

def render_board(n,reg,cells,style,size,piece_kind="berry",baked=False,seed=1,outer_w=None):
    st=STYLES[style]; cell=size/n
    im=Image.new("RGBA",(size,size),rgb("#FFF8EC"))
    unit=max(6,int(cell*0.27))
    # region fills + patterns
    for k in [int(v) for v in np.unique(reg)]:
        name,hx,pat=REG[k]
        base=mix(hx,"#FFF8EC",st["fill_mix"])
        mask=Image.new("L",(size,size),0); md=ImageDraw.Draw(mask)
        for r in range(n):
            for c in range(n):
                if reg[r,c]==k: md.rectangle([c*cell,r*cell,(c+1)*cell,(r+1)*cell],fill=255)
        layer=Image.new("RGBA",(size,size),base)
        if style=="A":
            nz=np.random.default_rng(k+seed).normal(0,1,(size//24+2,size//24+2))
            nzi=Image.fromarray(((nz*12)+128).clip(0,255).astype(np.uint8)).resize((size,size),Image.BICUBIC)
            arr=np.array(layer).astype(float); f=(np.array(nzi).astype(float)-128)/255*0.35+1
            arr[...,:3]=np.clip(arr[...,:3]*f[...,None],0,255); layer=Image.fromarray(arr.astype(np.uint8))
        ink=shade(hx,st["pat_f"])[:3]+(st["pat_a"],)
        pl=pattern_layer(pat,size,size,unit,ink,rng_seed=k+3)
        if style=="A": pl=pl.filter(ImageFilter.GaussianBlur(unit*0.06))
        layer.alpha_composite(pl)
        im.paste(layer,(0,0),mask)
    d=ImageDraw.Draw(im)
    ink=UI["earl_grey_ink"]
    # thin grid
    gw=max(1,int(cell*0.022))
    for i in range(1,n):
        d.line([(i*cell,0),(i*cell,size)],fill=rgb(ink,60),width=gw)
        d.line([(0,i*cell),(size,i*cell)],fill=rgb(ink,60),width=gw)
    # region borders
    bw=max(3,int(cell*st["border_w"]+size*0.004))
    bl=Image.new("RGBA",(size,size),(0,0,0,0)); bd=ImageDraw.Draw(bl)
    col=rgb(ink,st["border_a"]) if style!="C" else rgb(PLUM,255)
    segs=[]
    for r in range(n):
        for c in range(n):
            if c<n-1 and reg[r,c]!=reg[r,c+1]: segs.append(((c+1)*cell,r*cell,(c+1)*cell,(r+1)*cell))
            if r<n-1 and reg[r,c]!=reg[r+1,c]: segs.append((c*cell,(r+1)*cell,(c+1)*cell,(r+1)*cell))
    for x0,y0,x1,y1 in segs:
        if style=="C":
            # running stitch: dashed thick + thin solid underline
            bd.line([(x0,y0),(x1,y1)],fill=rgb(PLUM,110),width=max(1,bw//3))
            L=math.hypot(x1-x0,y1-y0); dash=cell/5
            t=dash*0.25
            while t<L:
                a=t/L; b=min(L,t+dash*0.6)/L
                bd.line([(x0+(x1-x0)*a,y0+(y1-y0)*a),(x0+(x1-x0)*b,y0+(y1-y0)*b)],fill=col,width=bw+1)
                t+=dash
        else:
            bd.line([(x0,y0),(x1,y1)],fill=col,width=bw)
            r_=bw/2
            for (px,py) in((x0,y0),(x1,y1)): bd.ellipse([px-r_,py-r_,px+r_,py+r_],fill=col)
    if style=="A": bl=bl.filter(ImageFilter.GaussianBlur(bw*0.18))
    im.alpha_composite(bl)
    d=ImageDraw.Draw(im)
    # contents
    pc=piece(piece_kind,int(cell*0.9),style)
    for (r,c),state in cells.items():
        cx,cy=(c+0.5)*cell,(r+0.5)*cell
        x0,y0=c*cell,r*cell
        if state=="x": x_mark(d,cx,cy,cell,style)
        elif state in("cake","conflict","solved"):
            if state=="solved":
                gl=Image.new("RGBA",(int(cell),int(cell)),(0,0,0,0)); gd=ImageDraw.Draw(gl)
                gd.ellipse([cell*0.04,cell*0.04,cell*0.96,cell*0.96],fill=rgb(UI["toasted_crust"],150))
                gl=gl.filter(ImageFilter.GaussianBlur(cell*0.08)); im.alpha_composite(gl,(int(x0),int(y0)))
            if state=="conflict":
                hl=Image.new("RGBA",(int(cell)+1,int(cell)+1),(0,0,0,0)); hd=ImageDraw.Draw(hl)
                for t in range(-int(cell),int(cell)*2,max(4,int(cell/6))):
                    hd.line([(t,0),(t-cell,cell)],fill=rgb(UI["cherry_alert"],120),width=max(2,int(cell*0.05)))
                im.alpha_composite(hl,(int(x0),int(y0)))
            im.alpha_composite(pc,(int(cx-pc.width/2),int(cy-pc.height/2)))
            d=ImageDraw.Draw(im)
            if state=="conflict":
                w=max(3,int(cell*0.07))
                d.rounded_rectangle([x0+w/2,y0+w/2,x0+cell-w/2,y0+cell-w/2],radius=cell*0.12,outline=rgb(UI["cherry_alert"]),width=w)
                br=cell*0.17; bx,by=x0+cell-br*1.05,y0+br*1.05
                d.ellipse([bx-br,by-br,bx+br,by+br],fill=rgb(UI["cherry_alert"]),outline=rgb("#FFF8EC"),width=max(1,int(br*0.18)))
                f=font("ui",br*1.5,800); d.text((bx,by),"!",fill=rgb("#FFF8EC"),font=f,anchor="mm")
            if state=="solved":
                br=cell*0.15; bx,by=x0+cell-br*1.1,y0+cell-br*1.1
                d.ellipse([bx-br,by-br,bx+br,by+br],fill=rgb(UI["sage_leaf"]),outline=rgb("#FFF8EC"),width=max(1,int(br*0.15)))
                icon(d,"check",bx,by,br*0.75,rgb("#FFF8EC"),max(2,int(br*0.3)))
    if baked:
        ov=Image.new("RGBA",(size,size),rgb(UI["toasted_crust"],55)); im.alpha_composite(ov)
    # outer border
    ob=max(4,int(bw*1.3)) if outer_w is None else outer_w
    d.rectangle([ob/2,ob/2,size-ob/2,size-ob/2],outline=rgb(ink) if style!="C" else rgb(PLUM),width=ob)
    return im
