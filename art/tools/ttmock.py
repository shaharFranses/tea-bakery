import math, numpy as np
from PIL import Image, ImageDraw, ImageFilter
from ttdraw import *
from ttboard import render_board, STYLES, PLUM, x_mark

S=3; W,H=390,844
def P(*v): return [x*S for x in v]

def background(style):
    im=Image.new("RGBA",(W*S,H*S),rgb(UI["rosewater_bg"])); d=ImageDraw.Draw(im)
    if style=="A":
        rng=np.random.default_rng(5)
        wash=Image.new("RGBA",im.size,(0,0,0,0)); wd=ImageDraw.Draw(wash)
        for _ in range(40):
            x,y=rng.uniform(0,W*S),rng.uniform(0,H*S); r=rng.uniform(60,220)*S/2
            c=[UI["rosewater_bg"],"#F9EDE4","#EFD3D6","#F3E7D3","#E7E1EF"][rng.integers(5)]
            wd.ellipse([x-r,y-r*0.8,x+r,y+r*0.8],fill=rgb(c,90))
        wash=wash.filter(ImageFilter.GaussianBlur(30*S)); im.alpha_composite(wash)
        # faint painted wallpaper stripes
        st=Image.new("RGBA",im.size,(0,0,0,0)); sd=ImageDraw.Draw(st)
        for x in range(0,W*S,36*S): sd.rectangle([x,0,x+14*S,H*S],fill=rgb("#E9C9CC",55))
        im.alpha_composite(st.filter(ImageFilter.GaussianBlur(3*S)))
        g=np.random.default_rng(1).normal(1,0.025,(H*S,W*S,1)); a=np.array(im).astype(float); a[...,:3]*=g
        im=Image.fromarray(np.clip(a,0,255).astype(np.uint8))
    elif style=="B":
        for x in range(0,W*S,30*S): d.rectangle([x,0,x+15*S,H*S],fill=rgb("#F1D6D2"))
        for x in range(0,W*S,30*S): d.line([(x+22*S,0),(x+22*S,H*S)],fill=rgb("#E3C3C0"),width=S)
    else:  # chintz: tiny roses on cream
        im=Image.new("RGBA",(W*S,H*S),rgb("#FBF1E6")); d=ImageDraw.Draw(im)
        for y in range(10*S,H*S,46*S):
            for x in range(0,W*S+46*S,46*S):
                xo=x+(23*S if (y//(46*S))%2 else 0)
                for k in range(5):
                    a=k*2*math.pi/5; r=4*S
                    d.ellipse([xo+math.cos(a)*r-4*S,y+math.sin(a)*r-4*S,xo+math.cos(a)*r+4*S,y+math.sin(a)*r+4*S],fill=rgb("#EBC3CB"))
                d.ellipse([xo-3*S,y-3*S,xo+3*S,y+3*S],fill=rgb("#D79AA8"))
                d.ellipse([xo+7*S,y+6*S,xo+15*S,y+10*S],fill=rgb("#B9CDA9"))
    return im

def shadow(im,box,radius,blur=8,alpha=70,off=4):
    sh=Image.new("RGBA",im.size,(0,0,0,0)); sd=ImageDraw.Draw(sh)
    x0,y0,x1,y1=box; sd.rounded_rectangle([x0,y0+off*S,x1,y1+off*S],radius=radius,fill=rgb(UI["earl_grey_ink"],alpha))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(blur*S)))

def panel(im,box,style,radius=16,fill=None):
    fill=fill or UI["clotted_cream"]; shadow(im,[v for v in box],radius*S)
    d=ImageDraw.Draw(im); ink=UI["earl_grey_ink"]
    if style=="B": d.rounded_rectangle(box,radius=radius*S,fill=rgb(fill),outline=rgb(ink),width=2*S)
    elif style=="A": d.rounded_rectangle(box,radius=radius*S,fill=rgb(fill,240),outline=rgb("#D9A7B0",200),width=int(1.5*S))
    else:
        d.rounded_rectangle(box,radius=radius*S,fill=rgb(fill),outline=rgb(PLUM),width=int(1.5*S))
        x0,y0,x1,y1=box; i=4*S
        d.rounded_rectangle([x0+i,y0+i,x1-i,y1-i],radius=(radius-4)*S,outline=rgb(UI["toasted_crust"],200),width=S)

def doily(im,cx,cy,R):
    d=ImageDraw.Draw(im); n=48
    pts=[]
    for i in range(n*6):
        a=2*math.pi*i/(n*6); rr=R+R*0.035*abs(math.sin(n*a/2))
        pts.append((cx+rr*math.cos(a),cy+rr*math.sin(a)))
    d.polygon(pts,fill=rgb("#FFFDF7"))
    for k in range(n):
        a=2*math.pi*k/n; px,py=cx+math.cos(a)*R*0.93,cy+math.sin(a)*R*0.93; r=R*0.022
        d.ellipse([px-r,py-r,px+r,py+r],fill=rgb("#EAD9CF"))

def mock(style,n=7,seed=11,cells=None,piece_kind="berry",board_fn=None,mark_icon="x",mark_label="Mark",tray_inner=None):
    im=background(style); ink=UI["earl_grey_ink"]
    d=ImageDraw.Draw(im)
    # --- top bar
    if style=="B":
        d.rectangle(P(0,0,W,54),fill=rgb(UI["clotted_cream"])); d.line(P(0,54,W,54),fill=rgb(ink),width=2*S)
    else:
        shadow(im,P(0,-20,W,54),0,6,40,2); d=ImageDraw.Draw(im)
        d.rectangle(P(0,0,W,54),fill=rgb(UI["clotted_cream"],235 if style=="A" else 255))
        if style=="C":
            for x in range(0,W,10): d.chord(P(x,48,x+10,60),0,180,fill=rgb(UI["clotted_cream"]))
    icon(d,"back",*P(26,27,11),rgb(ink),int(2.6*S))
    # neutral logo placeholder (title TBD): dashed outline only, no text
    lx0,ly0,lx1,ly1=P(125,12,265,42); col=rgb(UI["earl_grey_ink"],70); t=lx0
    while t<lx1: d.line([(t,ly0),(min(t+6*S,lx1),ly0)],fill=col,width=S); d.line([(t,ly1),(min(t+6*S,lx1),ly1)],fill=col,width=S); t+=11*S
    t=ly0
    while t<ly1: d.line([(lx0,t),(lx0,min(t+6*S,ly1))],fill=col,width=S); d.line([(lx1,t),(lx1,min(t+6*S,ly1))],fill=col,width=S); t+=11*S
    icon(d,"sound",*P(330,27,10),rgb(ink),int(2.2*S)); icon(d,"gear",*P(364,27,10),rgb(ink),int(2.2*S))
    # --- recipe card
    cb=P(14,66,376,170); panel(im,cb,style,14); d=ImageDraw.Draw(im)
    if style!="C":
        for y in range(108,166,15): d.line(P(110,y,364,y),fill=rgb("#E7B9C2",150),width=S)
        d.line(P(14,80,376,80),fill=rgb(UI["raspberry_jam"],160),width=S) if style=="A" else None
    # little sponge illustration in round frame
    d.ellipse(P(26,78,100,152),fill=rgb("#FBE3E3" if style!="C" else "#FFFDF7"),outline=rgb(ink if style=="B" else "#D9A7B0" if style=="A" else PLUM),width=2*S)
    pc=piece("slice",58*S,style); im.alpha_composite(pc,(int(34*S),int(84*S))); d=ImageDraw.Draw(im)
    d.text(P(112,90),"RECIPE CARD · CHAPTER 2",fill=rgb(ink,200),font=font("ui",10.5*S,600),anchor="lm")
    d.text(P(110,116),"Victoria Sponge",fill=rgb(UI["raspberry_jam"] if style!="C" else PLUM),font=font("script",27*S,700),anchor="lm")
    d.text(P(112,148),"Board 3 of 5",fill=rgb(ink),font=font("ui",13*S,500),anchor="lm")
    for i in range(5):
        cx=226+i*26
        if i<2: im.alpha_composite(piece("berry",22*S,style),(int((cx-11)*S),int(137*S)))
        elif i==2:
            d.ellipse(P(cx-9,139,cx+9,157),outline=rgb(UI["raspberry_jam"]),width=int(2.4*S))
        else: d.ellipse(P(cx-8,140,cx+8,156),outline=rgb(ink,110),width=int(1.6*S))
        d=ImageDraw.Draw(im)
    # star chip
    d.rounded_rectangle(P(316,76,368,100),radius=12*S,fill=rgb(UI["honey_chip"]) ,outline=rgb(ink) if style=="B" else None,width=int(1.5*S))
    icon(d,"star",*P(331,88,7),rgb(UI["earl_grey_ink"]),S); d.text(P(352,88),"24",fill=rgb(UI["earl_grey_ink"]),font=font("ui",13*S,700),anchor="mm")
    # --- tray + board
    tb=P(8,184,382,558)
    if style=="C":
        doily(im,195*S,371*S,190*S); d=ImageDraw.Draw(im)
    shadow(im,tb,26*S,10,80,6); d=ImageDraw.Draw(im)
    if style=="A":
        d.rounded_rectangle(tb,radius=26*S,fill=rgb("#D8CFCB"),outline=rgb("#B9AEAB"),width=2*S)
        d.rounded_rectangle(P(14,190,376,552),radius=22*S,fill=rgb("#EDE6E2"))
    elif style=="B":
        d.rounded_rectangle(tb,radius=26*S,fill=rgb(UI["pewter_tray"]),outline=rgb(ink),width=2*S)
        d.rounded_rectangle(P(15,191,375,551),radius=20*S,fill=rgb(tray_inner or "#D6D0CE"),outline=rgb(ink,120),width=S)
    else:
        d.rounded_rectangle(tb,radius=26*S,fill=rgb("#FFFDF7"),outline=rgb(PLUM),width=2*S)
        d.rounded_rectangle(P(14,190,376,552),radius=22*S,outline=rgb(UI["toasted_crust"]),width=2*S)
        for k in range(0,360,12):
            a=math.radians(k); 
        d.rounded_rectangle(P(19,195,371,547),radius=18*S,outline=rgb(PLUM,90),width=S)
    reg,q=gen_board(n,seed)
    if cells is None:
        cells={q[0]:"cake",q[2]:"cake",q[4]:"cake",(q[0][0],(q[0][1]+3)%n):"x",(1,q[0][1]):"x",(q[2][0]+1,q[2][1]):"x",(q[2][0]-1 ,(q[2][1]+1)%n):"x"}
    bsz=334*S
    bd=board_fn(n,reg,cells,bsz,seed) if board_fn else render_board(n,reg,cells,style,bsz,piece_kind=piece_kind,seed=seed)
    im.alpha_composite(bd,(28*S,204*S)); d=ImageDraw.Draw(im)
    # --- rules chip
    rc=P(36,568,354,594); 
    d.rounded_rectangle(rc,radius=13*S,fill=rgb(UI["clotted_cream"],230),outline=rgb(ink,90) if style!="C" else rgb(PLUM,140),width=S)
    d.text(P(195,581),"1 per row · column · patch  —  never touching",fill=rgb(ink),font=font("ui",12*S,500),anchor="mm")
    # --- tool buttons
    tools=[("undo","Undo"),(mark_icon,mark_label),("erase","Clear"),("hint","Hint")]
    for i,(k,lab) in enumerate(tools):
        x0=18+i*90; box=P(x0,606,x0+84,670); primary=(k=="hint")
        fill=UI["raspberry_jam"] if primary else UI["clotted_cream"]
        fg=rgb("#FFF8EC") if primary else rgb(ink)
        shadow(im,box,14*S,4,50,3); d=ImageDraw.Draw(im)
        if style=="B": d.rounded_rectangle(box,radius=14*S,fill=rgb(fill),outline=rgb(ink),width=2*S)
        elif style=="A": d.rounded_rectangle(box,radius=18*S,fill=rgb(fill,245))
        else:
            d.rounded_rectangle(box,radius=14*S,fill=rgb(fill),outline=rgb(PLUM),width=int(1.5*S))
            d.rounded_rectangle([box[0]+3*S,box[1]+3*S,box[2]-3*S,box[3]-3*S],radius=11*S,outline=rgb(UI["toasted_crust"],180),width=S)
        icon(d,k,(x0+42)*S,628*S,10*S,fg,int(2.8*S))
        d.text(P(x0+42,655),lab,fill=fg,font=font("ui",13*S,600),anchor="mm")
        if k=="hint":
            d.ellipse(P(x0+66,600,x0+90,624),fill=rgb(UI["sage_leaf"]),outline=rgb("#FFF8EC"),width=S)
            d.text(P(x0+78,612),"2",fill=rgb("#FFF8EC"),font=font("ui",12*S,700),anchor="mm")
    # --- tea-room shelf vignette (no coffee: teapot + cake stand + tea caddy)
    shelf_y=800
    ow=int(2*S) if style=="B" else (int(1.5*S) if style=="C" else 0)
    oc=rgb(ink) if style=="B" else rgb(PLUM)
    sh=Image.new("RGBA",im.size,(0,0,0,0)); sd=ImageDraw.Draw(sh)
    teapot(sd,92*S,758*S,34*S,rgb("#F6C7CF") if style!="C" else rgb("#FFFDF7"),rgb(UI["raspberry_jam"]) if style!="C" else rgb("#E9B8C4"),oc,ow)
    if style=="C":
        for k in range(6):
            a=k*math.pi/3; sd.ellipse([92*S+math.cos(a)*10*S-5*S,762*S+math.sin(a)*10*S-5*S,92*S+math.cos(a)*10*S+5*S,762*S+math.sin(a)*10*S+5*S],fill=rgb("#E9A3B3"))
    cakestand(sd,250*S,782*S,40*S,rgb("#F3EEE9") if style!="C" else rgb("#FFFDF7"),[rgb("#FA93AC"),rgb("#FDE87D"),rgb("#B8DFA6"),rgb("#D5BCF1")],oc,ow)
    # tea caddy tin
    sd.rounded_rectangle([322*S,742*S,366*S,shelf_y*S],radius=4*S,fill=rgb(UI["sage_leaf"]),outline=oc if ow else None,width=ow)
    sd.rounded_rectangle([318*S,734*S,370*S,746*S],radius=3*S,fill=rgb("#46613F"),outline=oc if ow else None,width=ow)
    sd.text((344*S,772*S),"TEA",fill=rgb("#FFF8EC"),font=font("display",13*S),anchor="mm")
    if style=="A":
        sh=sh.filter(ImageFilter.GaussianBlur(1.2*S))
    im.alpha_composite(sh); d=ImageDraw.Draw(im)
    # shelf
    if style=="C":
        d.rectangle(P(0,shelf_y,W,shelf_y+10),fill=rgb("#FFFDF7")); 
        for x in range(0,W,10): d.chord(P(x,shelf_y+4,x+10,shelf_y+16),0,180,fill=rgb("#FFFDF7"),outline=rgb(PLUM,120),width=S)
        d.line(P(0,shelf_y,W,shelf_y),fill=rgb(PLUM),width=S)
    else:
        d.rectangle(P(0,shelf_y,W,shelf_y+12),fill=rgb("#E9C1B8" if style=="A" else "#D79AA0"),outline=rgb(ink) if style=="B" else None,width=2*S)
    # footer: daily
    d.text(P(195,830),"Bake of the Day · 4-day streak",fill=rgb(ink,220),font=font("ui",12*S,500),anchor="mm")
    full=im.convert("RGB")
    return full.resize((W,H),Image.LANCZOS), full
