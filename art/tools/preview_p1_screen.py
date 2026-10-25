"""P1 verification mock: 390x844 portrait board + settings modal built ONLY from shipped sprites (rendered @2x).
Applies SPEC v1.0.1 sec.10 mock deltas: no star chip, D-02 rules text, Undo/Hint/Reset, 358 px board."""
import numpy as np
from PIL import Image, ImageDraw
from ttdraw import font, gen_board
from ttb2 import render_board_b2
A="/workspace/tea-and-tarts/assets"; K=2
INK=(67,40,58,255)
def L(p): return Image.open(f"{A}/{p}@2x.png").convert("RGBA")
def nine(img,w,h,m):
    m=m*K; W,H=img.size; out=Image.new("RGBA",(w,h),(0,0,0,0))
    xs=[0,m,W-m,W]; ys=[0,m,H-m,H]; xd=[0,m,w-m,w]; yd=[0,m,h-m,h]
    for i in range(3):
        for j in range(3):
            tw,th=xd[i+1]-xd[i],yd[j+1]-yd[j]
            if tw<=0 or th<=0: continue
            out.alpha_composite(img.crop((xs[i],ys[j],xs[i+1],ys[j+1])).resize((tw,th),Image.LANCZOS),(xd[i],yd[j]))
    return out
def put(im,sp,x,y,w=None,h=None):
    if w: sp=sp.resize((int(w*K),int((h or w)*K)),Image.LANCZOS)
    im.alpha_composite(sp,(int(x*K),int(y*K)))
def text(d,xy,s,size,w=500,col=INK,anchor="la",kind="ui"):
    d.text((xy[0]*K,xy[1]*K),s,fill=col,font=font(kind,size*K,w),anchor=anchor)
def wrap(s,size,maxw,w=400):
    f=font("ui",size*K,w); out=[];cur=""
    for word in s.split():
        t=(cur+" "+word).strip()
        if f.getlength(t)>maxw*K and cur: out.append(cur); cur=word
        else: cur=t
    return out+[cur]
def board_screen():
    im=Image.new("RGBA",(390*K,844*K),(246,227,222,255)); d=ImageDraw.Draw(im)
    put(im,L("ui/btn_round_normal"),12,0,56); put(im,L("ui/icons/icon_home"),24,12,32)
    put(im,L("ui/btn_round_normal"),322,0,56); put(im,L("ui/icons/icon_settings"),334,12,32)
    text(d,(195,20),"Chapter 2 · Tray 3/5",17,600,anchor="mm")
    for i in range(5): put(im,L("ui/progress_dot_on" if i<2 else "ui/progress_dot_off"),155+i*16,34,12)
    # coach bubble (hint)
    bb=nine(L("ui/coach_bubble"),358*K,64*K,28); im.alpha_composite(bb,(16*K,60*K)); put(im,L("ui/coach_tail"),180,121,24,18)
    for i,ln in enumerate(wrap("Hint: the lavender patch has only one row left. Its cake must go there.",15,326)):
        text(d,(30,70+i*20),ln,15,400)
    n=8; reg,sol=gen_board(n,11); BS=358; cell=BS/n
    put(im,nine(L("board/tray_frame"),(BS+20)*K,(BS+22)*K,32),6,146)
    brd=render_board_b2(n,reg,{},BS*K); im.alpha_composite(brd,(16*K,156*K))
    cells={sol[0]:"cake",sol[3]:"cake",(sol[3][0],sol[3][1]+1 if sol[3][1]<n-1 else sol[3][1]-1):"conflict_pair",(1,1):"mold",(1,2):"auto",(2,2):"auto",(5,6):"mold"}
    hint_r=sol[5][0]
    for c in range(n): put(im,L("board/overlay_hint_unit"),16+c*cell+cell*0.0375,156+hint_r*cell+cell*0.0375,cell*0.925)
    put(im,L("board/overlay_hint_target"),16+sol[5][1]*cell+cell*0.0375,156+hint_r*cell+cell*0.0375,cell*0.925)
    for (r,c),st in cells.items():
        x0=16+c*cell; y0=156+r*cell; t=cell*0.925; o=cell*0.0375
        if st in("cake","conflict_pair") and (r,c)!=sol[0]:
            put(im,L("board/overlay_conflict"),x0+o,y0+o,t)
        if st in("cake","conflict_pair"):
            put(im,L("board/cake_berry"),x0,y0+cell*0.02,cell)
            if (r,c)!=sol[0]: put(im,L("board/badge_conflict"),x0+o,y0+o,t)
        else:
            m=L("board/mold"); s=cell*0.70
            if st=="auto": a=np.array(m); a[...,3]=(a[...,3]*0.5).astype(np.uint8); m=Image.fromarray(a)
            put(im,m,x0+(cell-s)/2,y0+(cell-s)/2,s)
    # tools
    y=530; bw=(358-2*10)/3
    for i,(ic,lab) in enumerate((("undo","Undo"),("hint","Hint"),("reset","Reset"))):
        x=16+i*(bw+10); put(im,nine(L("ui/btn_tool_normal"),int(bw*K),60*K,24),x,y)
        put(im,L(f"ui/icons/icon_{ic}"),x+18,y+14,28); text(d,(x+52,y+28),lab,17,600,anchor="lm")
        if ic=="hint": put(im,L("ui/badge_free_hint"),x+bw-26,y-6,24)
    # rules card (D-02)
    rc=nine(L("ui/panel_card"),358*K,140*K,32); im.alpha_composite(rc,(16*K,606*K))
    yy=622
    for s in ("One cake in every row, column and color.","Cakes can't touch — not even corners — or they'll stick in the oven!"):
        for ln in wrap(s,16,326): text(d,(32,yy),ln,16,400); yy+=22
        yy+=6
    ch=nine(L("ui/chip_honey"),190*K,40*K,18); im.alpha_composite(ch,(100*K,766*K)); put(im,L("ui/icons/icon_streak"),116,773,24)
    text(d,(146,786),"Bake of the Day · 4",15,600,anchor="lm")
    put(im,L("ui/pointer_hand"),16+sol[5][1]*cell+cell*0.3,156+hint_r*cell+cell*0.45,56)
    return im,yy
def settings_screen(bg):
    im=bg.copy(); ov=Image.new("RGBA",im.size,(67,40,58,115)); im.alpha_composite(ov); d=ImageDraw.Draw(im)
    im.alpha_composite(nine(L("ui/panel_modal"),342*K,470*K,32),(24*K,170*K))
    text(d,(195,206),"Settings",28,400,anchor="mm",kind="display")
    put(im,L("ui/btn_round_normal"),318,180,48); put(im,L("ui/icons/icon_close"),330,192,24)
    rows=[("sound_on","Sound",True),("music_off","Music",False),("check","Auto-molds",True),("undo","Tap order: cake first",False)]
    for i,(ic,lab,on) in enumerate(rows):
        y=250+i*64; put(im,L(f"ui/icons/icon_{ic}"),48,y+6,28); text(d,(88,y+20),lab,17,500,anchor="lm")
        put(im,L("ui/toggle_on" if on else "ui/toggle_off"),278,y+2,64,36)
        d.line([(48*K,(y+52)*K),(342*K,(y+52)*K)],fill=(231,211,195,255),width=2*K)
    put(im,nine(L("ui/btn_tool_normal"),294*K,56*K,24),48,520); text(d,(195,546),"Reset progress",17,600,anchor="mm")
    put(im,nine(L("ui/btn_primary_normal"),294*K,56*K,24),48,580); text(d,(195,606),"Done",17,600,col=(255,248,236,255),anchor="mm")
    return im
a,yy=board_screen(); b=settings_screen(a)
sheet=Image.new("RGBA",(a.width*2+40,a.height),(255,255,255,255)); sheet.alpha_composite(a,(0,0)); sheet.alpha_composite(b,(a.width+40,0))
sheet.save("/workspace/tea-and-tarts/art/p1_preview.png"); sheet.resize((sheet.width//2,sheet.height//2),Image.LANCZOS).save("/tmp/tt_p1_screen_a.png")
print("rules text bottom y",yy)
