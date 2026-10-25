import math, numpy as np
from PIL import Image, ImageDraw, ImageFilter
from ttdraw import *
from ttmock import mock
INK=UI["earl_grey_ink"]
def backdrop(W=1920,H=1080,K=2):
    W2,H2=W*K,H*K
    im=Image.new("RGBA",(W2,H2),rgb(UI["rosewater_bg"])); d=ImageDraw.Draw(im)
    # wallpaper stripes + small sprigs
    for x in range(0,W2,64*K): d.rectangle([x,0,x+30*K,H2],fill=rgb("#F1D6D2"))
    for y in range(30*K,int(H2*0.62),90*K):
        for x in range(47*K,W2,128*K):
            xo=x+(64*K if (y//(90*K))%2 else 0)
            for k in range(4):
                a=k*math.pi/2+math.pi/4; px,py=xo+math.cos(a)*6*K,y+math.sin(a)*6*K
                d.ellipse([px-4*K,py-4*K,px+4*K,py+4*K],fill=rgb("#E2B7BE"))
    # wainscot
    wy=int(H2*0.64)
    d.rectangle([0,wy,W2,H2],fill=rgb("#F7EEDF")); d.rectangle([0,wy,W2,wy+14*K],fill=rgb("#EAD8C4"))
    for x in range(20*K,W2,180*K): d.rounded_rectangle([x,wy+40*K,x+150*K,H2-60*K],radius=8*K,outline=rgb("#E2CDB5"),width=3*K)
    # window (left) with inland countryside
    wx0,wy0,wx1,wy1=110*K,120*K,560*K,560*K
    d.rounded_rectangle([wx0-18*K,wy0-18*K,wx1+18*K,wy1+30*K],radius=10*K,fill=rgb("#FFF8EC"),outline=rgb("#D9C3B0"),width=3*K)
    sky=Image.new("RGBA",(wx1-wx0,wy1-wy0)); sd=ImageDraw.Draw(sky)
    for i in range(wy1-wy0): 
        t=i/(wy1-wy0); c=tuple(int(a*(1-t)+b*t) for a,b in zip((246,231,214),(250,240,226)))
        sd.line([(0,i),(wx1-wx0,i)],fill=c+(255,))
    hw,hh=sky.size
    for j,(yy,col) in enumerate([(0.55,"#C9D7A8"),(0.66,"#AFC48C"),(0.78,"#97B178"),(0.9,"#86A26A")]):
        pts=[(0,hh)]+[(x,hh*yy+math.sin(x/(hw*0.18)+j*1.7)*hh*0.05) for x in range(0,hw+1,8)]+[(hw,hh)]
        sd.polygon(pts,fill=rgb(col))
    # hedgerow trees
    for tx in (0.2,0.32,0.7,0.84):
        sd.ellipse([hw*tx-22*K,hh*0.5,hw*tx+22*K,hh*0.5+40*K],fill=rgb("#6F8B5E"))
    # village church spire far away (inland)
    sd.polygon([(hw*0.55,hh*0.38),(hw*0.565,hh*0.55),(hw*0.535,hh*0.55)],fill=rgb("#B9A79A"))
    im.alpha_composite(sky,(wx0,wy0)); d=ImageDraw.Draw(im)
    d.line([((wx0+wx1)//2,wy0),((wx0+wx1)//2,wy1)],fill=rgb("#FFF8EC"),width=10*K)
    d.line([(wx0,(wy0+wy1)//2),(wx1,(wy0+wy1)//2)],fill=rgb("#FFF8EC"),width=10*K)
    # lace curtains
    for side in (0,1):
        cx0=wx0-30*K if side==0 else wx1-60*K
        cur=Image.new("RGBA",(90*K,wy1-wy0+60*K),(0,0,0,0)); cd=ImageDraw.Draw(cur)
        cd.rectangle([0,0,90*K,cur.height],fill=(255,253,247,200))
        for y in range(0,cur.height,18*K):
            for x in range(0,90*K,18*K): cd.ellipse([x+5*K,y+5*K,x+12*K,y+12*K],outline=rgb("#EADFD3"),width=K)
        im.alpha_composite(cur,(cx0,wy0-30*K))
    d=ImageDraw.Draw(im)
    # windowsill potted herb + teacup
    d.rectangle([wx0-40*K,wy1+30*K,wx1+40*K,wy1+48*K],fill=rgb("#EAD8C4"))
    d.polygon([(200*K,wy1+30*K),(250*K,wy1+30*K),(242*K,wy1-20*K),(208*K,wy1-20*K)],fill=rgb("#C77B5A"))
    for k in range(7): d.ellipse([195*K+k*9*K,wy1-60*K-(k%3)*12*K,215*K+k*9*K,wy1-30*K-(k%3)*12*K],fill=rgb(UI["sage_leaf"]))
    teapot(d,450*K,wy1-2*K,34*K,rgb("#F6C7CF"),rgb(UI["raspberry_jam"]),rgb(INK),2*K)
    # dresser (right)
    dx0,dx1=1380*K,1840*K; dtop=110*K
    d.rectangle([dx0,dtop,dx1,wy+260*K],fill=rgb("#EFE3D3"),outline=rgb("#D5C0A8"),width=3*K)
    d.rectangle([dx0-20*K,dtop-24*K,dx1+20*K,dtop],fill=rgb("#E6D5C0"))
    for sy in (260,420): d.rectangle([dx0,sy*K,dx1,sy*K+12*K],fill=rgb("#D9C5AE"))
    # plates on top shelf
    for i in range(5):
        px=dx0+50*K+i*90*K; d.ellipse([px-38*K,160*K,px+38*K,258*K],fill=rgb("#FFFDF7"),outline=rgb("#D79AA8"),width=4*K)
        d.ellipse([px-20*K,190*K,px+20*K,228*K],outline=rgb("#E9B8C4"),width=3*K)
    # teapots + caddies middle shelf
    teapot(d,dx0+90*K,380*K,36*K,rgb("#FFFDF7"),rgb("#E9B8C4"),rgb("#7A3F5C"),2*K)
    teapot(d,dx0+250*K,380*K,32*K,rgb("#C8B5E6"),rgb("#7A3F5C"),rgb(INK),2*K)
    for i,c in enumerate(["#55724E","#B0365A","#C9803A"]):
        x=dx0+340*K+i*40*K; d.rounded_rectangle([x,350*K,x+32*K,418*K],radius=4*K,fill=rgb(c))
    # counter with cake stand + tarts under a glass dome
    cty=wy+40*K
    d.rectangle([dx0-30*K,cty,dx1+30*K,cty+24*K],fill=rgb("#E6D5C0"))
    cakestand(d,dx0+120*K,cty,60*K,rgb("#FFFDF7"),[rgb("#FA93AC"),rgb("#FDE87D"),rgb("#B8DFA6")],rgb(INK),2*K)
    dome=Image.new("RGBA",im.size,(0,0,0,0)); dd=ImageDraw.Draw(dome)
    gx=dx0+330*K
    for i,kind in enumerate(["berry","lattice","lemon"]):
        p=piece(kind,70*K,"B"); im.alpha_composite(p,(gx-110*K+i*70*K,cty-62*K))
    dd.chord([gx-130*K,cty-200*K,gx+130*K,cty+60*K],180,360,fill=(255,255,255,60),outline=(255,255,255,200),width=3*K)
    im.alpha_composite(dome); d=ImageDraw.Draw(im)
    d.ellipse([gx-145*K,cty-12*K,gx+145*K,cty+8*K],fill=rgb("#D9C5AE"))
    # bunting? (no) — pendant lamp
    for lx in (760*K,1160*K):
        d.line([(lx,0),(lx,70*K)],fill=rgb(INK),width=2*K)
        d.chord([lx-50*K,60*K,lx+50*K,140*K],180,360,fill=rgb("#B8DFA6"),outline=rgb(INK),width=2*K)
    # floor-level table runner (gingham) under the column
    gy=H2-110*K
    d.rectangle([0,gy,W2,H2],fill=rgb("#E9D6C8"))
    for x in range(0,W2,30*K): d.rectangle([x,gy,x+15*K,H2],fill=rgb("#F1C9CF",160))
    for y in range(gy,H2,30*K): d.rectangle([0,y,W2,y+15*K],fill=rgb("#F1C9CF",110))
    im=im.resize((W,H),Image.LANCZOS)
    # soft depth: slight blur + wash so the board wins
    im=im.filter(ImageFilter.GaussianBlur(1.6))
    wash=Image.new("RGBA",im.size,rgb("#FBF1EC",70)); im.alpha_composite(wash)
    return im

def landscape(style="B",W=1920,H=1080):
    bg=backdrop(W,H)
    small,big=mock(style)
    ch=H; cw=round(390*ch/844)
    col=big.resize((cw,ch),Image.LANCZOS).convert("RGBA")
    sh=Image.new("RGBA",bg.size,(0,0,0,0)); sd=ImageDraw.Draw(sh)
    x0=(W-cw)//2; sd.rectangle([x0-6,0,x0+cw+6,H],fill=rgb(UI["earl_grey_ink"],90))
    bg.alpha_composite(sh.filter(ImageFilter.GaussianBlur(18)))
    bg.alpha_composite(col,(x0,0))
    return bg.convert("RGB")
