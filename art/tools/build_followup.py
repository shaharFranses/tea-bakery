import numpy as np, math
from PIL import Image, ImageDraw, ImageFilter
from ttdraw import *
from ttboard import render_board, x_mark
from ttland import backdrop
import ttcolor as T
OUT="/workspace/tea-and-tarts/art"; M=OUT+"/mocks"
INK=UI["earl_grey_ink"]

# ---------- 1) wide desktop 9x9 ----------
def wide(Wout,Hout,SS=2,board_fn=None,mark_icon="x",mark_label="Mark",tray_inner="#D6D0CE"):
    K=Wout/800*SS; W,H=int(800*K),int(450*K)
    def P(*v): return [v_*K for v_ in v]
    im=backdrop(W,H).convert("RGBA")
    d=ImageDraw.Draw(im)
    # board tray, left-centre, full height
    ty0,ty1=8,442; tsz=ty1-ty0; tx0=40
    sh=Image.new("RGBA",im.size,(0,0,0,0)); sd=ImageDraw.Draw(sh)
    sd.rounded_rectangle(P(tx0,ty0+4,tx0+tsz,ty1+4),radius=18*K,fill=rgb(INK,90)); im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(8*K)))
    d=ImageDraw.Draw(im)
    d.rounded_rectangle(P(tx0,ty0,tx0+tsz,ty1),radius=18*K,fill=rgb(UI["pewter_tray"]),outline=rgb(INK),width=max(1,int(1.5*K)))
    d.rounded_rectangle(P(tx0+5,ty0+5,tx0+tsz-5,ty1-5),radius=14*K,fill=rgb(tray_inner),outline=rgb(INK,120),width=max(1,int(K*0.7)))
    m=12; bsz=int((tsz-2*m)*K)
    n=9; reg,q=gen_board(n,109)
    cells={q[0]:"cake",q[2]:"cake",q[4]:"cake",q[6]:"cake",(q[1][0],(q[1][1]+3)%n):"x",(q[3][0],(q[3][1]+4)%n):"x",(1,q[0][1]):"x",(q[5][0],(q[5][1]+2)%n):"x",(q[7][0],(q[7][1]+5)%n):"x"}
    b=board_fn(n,reg,cells,bsz,109) if board_fn else render_board(n,reg,cells,"B",bsz,seed=109)
    im.alpha_composite(b,(int((tx0+m)*K),int((ty0+m)*K)))
    cell_px=(tsz-2*m)*(Wout/800)/n
    # right column panel
    cx0,cx1=tx0+tsz+28,772
    sh=Image.new("RGBA",im.size,(0,0,0,0)); sd=ImageDraw.Draw(sh)
    sd.rounded_rectangle(P(cx0,ty0+4,cx1,ty1+4),radius=16*K,fill=rgb(INK,70)); im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(8*K)))
    d=ImageDraw.Draw(im)
    d.rounded_rectangle(P(cx0,ty0,cx1,ty1),radius=16*K,fill=rgb("#FBF1EC",235),outline=rgb(INK),width=max(1,int(1.5*K)))
    # top: back / logo placeholder / sound+settings
    icon(d,"back",*P(cx0+20,32,8),rgb(INK),max(2,int(2*K)))
    lx0,lx1,ly0,ly1=cx0+42,cx1-62,18,46
    col=rgb(INK,70); t=lx0
    while t<lx1:
        d.line(P(t,ly0,min(t+5,lx1),ly0),fill=col,width=max(1,int(K*0.8))); d.line(P(t,ly1,min(t+5,lx1),ly1),fill=col,width=max(1,int(K*0.8))); t+=9
    t=ly0
    while t<ly1:
        d.line(P(lx0,t,lx0,min(t+5,ly1)),fill=col,width=max(1,int(K*0.8))); d.line(P(lx1,t,lx1,min(t+5,ly1)),fill=col,width=max(1,int(K*0.8))); t+=9
    icon(d,"sound",*P(cx1-42,32,7.5),rgb(INK),max(2,int(1.8*K))); icon(d,"gear",*P(cx1-18,32,7.5),rgb(INK),max(2,int(1.8*K)),bg=rgb("#FBF1EC"))
    # recipe card
    rc=P(cx0+12,58,cx1-12,170)
    d.rounded_rectangle(rc,radius=12*K,fill=rgb(UI["clotted_cream"]),outline=rgb(INK),width=max(1,int(1.5*K)))
    for y in range(118,166,13): d.line(P(cx0+24,y,cx1-24,y),fill=rgb("#E7B9C2",150),width=max(1,int(K*0.7)))
    d.ellipse(P(cx0+22,68,cx0+76,122),fill=rgb("#FBE3E3"),outline=rgb(INK),width=max(1,int(1.5*K)))
    pc=piece("slice",int(42*K),"B"); im.alpha_composite(pc,(int((cx0+27)*K),int(73*K))); d=ImageDraw.Draw(im)
    d.text(P(cx0+86,76),"RECIPE · CH. 6",fill=rgb(INK,200),font=font("ui",10*K,600),anchor="lm")
    d.text(P(cx0+84,100),"Lemon Tart",fill=rgb(UI["raspberry_jam"]),font=font("script",24*K,700),anchor="lm")
    d.text(P(cx0+24,140),"Board 4 of 5",fill=rgb(INK),font=font("ui",12.5*K,500),anchor="lm")
    for i in range(5):
        x=cx0+128+i*22
        if i<3: im.alpha_composite(piece("berry2",int(18*K),"B"),(int((x-9)*K),int(131*K)))
        elif i==3: d.ellipse(P(x-8,132,x+8,148),outline=rgb(UI["raspberry_jam"]),width=max(1,int(2*K)))
        else: d.ellipse(P(x-7,133,x+7,147),outline=rgb(INK,110),width=max(1,int(1.4*K)))
        d=ImageDraw.Draw(im)
    d.rounded_rectangle(P(cx1-62,64,cx1-20,84),radius=10*K,fill=rgb(UI["honey_chip"]),outline=rgb(INK),width=max(1,int(K)))
    icon(d,"star",*P(cx1-50,74,6),rgb(INK),1); d.text(P(cx1-34,74),"31",fill=rgb(INK),font=font("ui",11*K,700),anchor="mm")
    # rules chip
    d.rounded_rectangle(P(cx0+12,182,cx1-12,206),radius=12*K,fill=rgb(UI["clotted_cream"]),outline=rgb(INK,90),width=max(1,int(K*0.8)))
    d.text(P((cx0+cx1)/2,194),"1 per row · column · patch — never touching",fill=rgb(INK),font=font("ui",11*K,500),anchor="mm")
    # 2x2 tool buttons
    tools=[("undo","Undo"),(mark_icon,mark_label),("erase","Clear"),("hint","Hint")]
    bw=(cx1-cx0-24-12)/2
    for i,(k,lab) in enumerate(tools):
        x0=cx0+12+(i%2)*(bw+12); y0=220+(i//2)*72; box=P(x0,y0,x0+bw,y0+60)
        prim=k=="hint"; fill=UI["raspberry_jam"] if prim else UI["clotted_cream"]; fg=rgb("#FFF8EC") if prim else rgb(INK)
        d.rounded_rectangle(box,radius=12*K,fill=rgb(fill),outline=rgb(INK),width=max(1,int(1.5*K)))
        icon(d,k,(x0+bw/2)*K,(y0+22)*K,9*K,fg,max(2,int(2.4*K)),bg=rgb(fill))
        d.text(P(x0+bw/2,y0+46),lab,fill=fg,font=font("ui",12.5*K,600),anchor="mm")
        if prim:
            d.ellipse(P(x0+bw-14,y0-8,x0+bw+8,y0+14),fill=rgb(UI["sage_leaf"]),outline=rgb("#FFF8EC"),width=max(1,int(K)))
            d.text(P(x0+bw-3,y0+3),"2",fill=rgb("#FFF8EC"),font=font("ui",11*K,700),anchor="mm")
    d.text(P((cx0+cx1)/2,420),"Bake of the Day · 4-day streak",fill=rgb(INK,220),font=font("ui",11.5*K,500),anchor="mm")
    out=im.convert("RGB").resize((Wout,Hout),Image.LANCZOS)
    return out,cell_px
if __name__=="__main__":
    for (w,h) in ((1920,1080),(800,450)):
        im,cp=wide(w,h,SS=2 if w>1000 else 3)
        im.save(f"{M}/desktop_wide_9x9_{w}x{h}.png"); print(w,h,"cell px %.1f"%cp)

    # ---------- 2) berry v2 comparison ----------
    sizes=[48,32,24]
    def tile(k,sz,kind):
        cell=sz+12
        t=render_board(1,np.array([[k]]),{},"B",cell*3,outer_w=3).resize((cell,cell),Image.LANCZOS)
        p=piece(kind,sz,"B",_raw=True); t.alpha_composite(p,(cell//2-p.width//2,cell//2-p.height//2)); return t
    blocks=[]
    GAP=6
    def block():
        rows=[]
        for kind,label in (("berry","OLD berry"),("berry2","NEW berry v2")):
            for sz in sizes:
                rows.append((label,sz,[tile(k,sz,kind) for k in range(9)]))
        return rows
    rows=block()
    LW=190; colw=max(r[2][0].width for r in rows)+GAP
    Wd=LW+9*72+40; rowh=[r[2][0].height+GAP for r in rows]
    Hblock=sum(rowh)
    Hd=120+2*Hblock+50+70
    sheet=Image.new("RGB",(Wd,Hd),(251,244,238)); d=ImageDraw.Draw(sheet)
    d.text((24,18),"Berry tart: OLD vs NEW v2 on every patch (style B, true px)",fill=rgb(INK),font=font("display",28))
    d.text((24,58),"v2 = lighter crust #F2C584 + lighter berries #B83A5E + cream halo outside the ink outline.",fill=rgb(INK),font=font("ui",14,500))
    for i,(n,h,p) in enumerate(T.REGIONS):
        d.text((LW+i*72+30,100),n,fill=rgb(INK),font=font("ui",11,600),anchor="mm")
    blk=Image.new("RGB",(Wd,Hblock),(251,244,238)); bd=ImageDraw.Draw(blk)
    y=0
    for (label,sz,ts),rh in zip(rows,rowh):
        bd.text((10,y+rh/2),f"{label} · {sz}px",fill=rgb(INK),font=font("ui",13,700 if "NEW" in label else 500),anchor="lm")
        for i,t in enumerate(ts): blk.paste(t.convert("RGB"),(LW+i*72+30-t.width//2,y))
        y+=rh
    sheet.paste(blk,(0,120))
    d.text((24,120+Hblock+22),"DEUTERANOPIA (Machado 2009, severity 1.0) — same rows simulated",fill=rgb(INK),font=font("ui",15,700))
    a=np.asarray(blk).astype(float)/255; s=T.simulate(a,"deuteranopia")
    sheet.paste(Image.fromarray((np.clip(s,0,1)*255).round().astype(np.uint8)),(0,120+Hblock+50))
    # metric: contrast of outermost ring vs patch
    def ring_contrast(ringhex):
        out=[]
        for n,h,p in T.REGIONS: out.append((T.contrast(ringhex,h),n))
        return min(out)
    oc=ring_contrast("#E2A35C"); nc=ring_contrast("#FFF8EC")
    # also deut
    def ring_contrast_deut(ringhex):
        r=T.simulate(T.hex2rgb(ringhex),"deuteranopia"); out=[]
        for n,h,p in T.REGIONS:
            out.append((T.contrast(T.rgb2hex(r),T.rgb2hex(T.simulate(T.hex2rgb(h),"deuteranopia"))),n))
        return min(out)
    txt="Outer edge vs dark patches (WCAG): rhubarb OLD crust %.2f:1 -> NEW halo %.2f:1 · cocoa %.2f -> %.2f · blueberry %.2f -> %.2f. Light patches are carried by the ink outline in both."%(T.contrast("#E2A35C","#CB6F91"),T.contrast("#FFF8EC","#CB6F91"),T.contrast("#E2A35C","#AE906C"),T.contrast("#FFF8EC","#AE906C"),T.contrast("#E2A35C","#8E9CC9"),T.contrast("#FFF8EC","#8E9CC9"))
    parts=txt.split(" · ",1); d.text((24,Hd-58),parts[0]+" ·",fill=rgb(INK),font=font("ui",13,600)); d.text((24,Hd-36),parts[1],fill=rgb(INK),font=font("ui",13,600))
    sheet.save(OUT+"/small_size_test_berry_v2.png"); print(txt)
    # per-patch contrast table
    for n,h,p in T.REGIONS: print(n, round(T.contrast("#E2A35C",h),2), round(T.contrast("#FFF8EC",h),2), round(T.contrast("#8E1F3F",h),2))
