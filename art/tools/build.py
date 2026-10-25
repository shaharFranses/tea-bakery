import os, json, numpy as np
from PIL import Image, ImageDraw
from ttdraw import *
from ttboard import render_board, STYLES, x_mark
from ttmock import mock
import ttcolor as T
OUT="/workspace/tea-and-tarts/art"; M=OUT+"/mocks"; os.makedirs(M,exist_ok=True)
INK=rgb(UI["earl_grey_ink"]); BG=rgb("#FBF4EE")
def title(d,xy,t,sz=28): d.text(xy,t,fill=INK,font=font("display",sz))
def lab(d,xy,t,sz=15,w=500,col=INK,anchor="la"): d.text(xy,t,fill=col,font=font("ui",sz,w),anchor=anchor)
names={"A":"A · Watercolour Tea Room","B":"B · Crisp Pastry Flat","C":"C · Vintage China & Stitch"}

# 1) mocks
for s in "B":  # A and C frozen (not re-rendered)
    small,big=mock(s); small.save(f"{M}/mock_{s}_390x844.png")
    big.resize((780,1688),Image.LANCZOS).save(f"{M}/mock_{s}_390x844@2x.png")
print("mocks ok")

# 2) legibility 5x5..9x9 at true 1x size (board = 334 px on a 390-wide phone)
BS=334; G=24
sheet=Image.new("RGBA",(G+5*(BS+G),110+3*(BS+70)),BG); d=ImageDraw.Draw(sheet)
title(d,(G,20),"Legibility 5×5 to 9×9 at true 1× size (390-px-wide phone, board 334 px)")
lab(d,(G,62),"Each board downsampled from 3× render to 1× = worst case (desktop browser at 100%). Cell size shown under each.",14)
for row,s in enumerate("ABC"):
    y=110+row*(BS+70)
    lab(d,(G,y-4),names[s],17,700)
    for i,n in enumerate(range(5,10)):
        reg,q=gen_board(n,100+n)
        cells={q[0]:"cake",q[2]:"cake",(q[1][0],(q[1][1]+2)%n):"x",(q[3][0],(q[3][1]+n-2)%n):"x",(0,(q[0][1]+2)%n):"x"}
        # one conflict: put a cake touching q[2]
        rr,cc=q[2]; cc2=cc+1 if cc+1<n else cc-1; cells[(rr,cc2)]="conflict"; cells[q[2]]="conflict"
        b=render_board(n,reg,cells,s,BS*3,seed=100+n).resize((BS,BS),Image.LANCZOS)
        x=G+i*(BS+G); sheet.alpha_composite(b,(x,y+22))
        lab(d,(x,y+BS+28),f"{n}×{n} · cell {BS/n:.0f} px · piece {BS/n*0.9:.0f} px",13,500)
sheet.convert("RGB").save(f"{OUT}/legibility_5x5_to_9x9.png"); print("legib ok")

# 3) cell-state strip
states=[("empty","Empty"),("x","X-mark"),("cake","Cake placed"),("conflict","Conflict"),("solved","Solved / baked")]
C1=47; C2=120
strip=Image.new("RGBA",(G+5*(C2+40)+60, 100+3*(C2+C1+80)),BG); d=ImageDraw.Draw(strip)
title(d,(G,18),"Cell states (shown 2.5× and at true 1× for a 7×7 board, 47 px)")
lab(d,(G,58),"Conflict = cherry ring + diagonal hatch + ! badge (shape, not colour). Solved = toasted glow + sage tick badge.",14)
for row,s in enumerate("ABC"):
    y=100+row*(C2+C1+80)
    lab(d,(G,y),names[s],16,700)
    for i,(st,lb) in enumerate(states):
        x=G+i*(C2+40)
        cells={} if st=="empty" else {(0,0):st}
        reg=np.array([[2]])
        big=render_board(1,reg,cells,s,C2*3,outer_w=6).resize((C2,C2),Image.LANCZOS)
        sm=render_board(1,reg,cells,s,C1*3,outer_w=4).resize((C1,C1),Image.LANCZOS)
        strip.alpha_composite(big,(x,y+24)); strip.alpha_composite(sm,(x+C2//2-C1//2,y+30+C2))
        lab(d,(x+C2//2,y+C2+C1+40),lb,13,600,anchor="mm")
strip.convert("RGB").save(f"{OUT}/cell_states_strip.png"); print("strip ok")

# 4) small-size test 48 / 32 (+24 for info)
sizes=[48,32,24]; kinds=["berry","lattice","lemon"]
cw=60
sm=Image.new("RGBA",(G+3*(len(kinds)*len(sizes)*cw+60)//1, 520),BG)
sm=Image.new("RGBA",(1720,560),BG); d=ImageDraw.Draw(sm)
title(d,(G,18),"Small-size test: pieces at 48 / 32 / 24 px (true pixels), on cream and on the busiest patches")
lab(d,(G,58),"Rendered at 256 px and reduced (Lanczos). 24 px is below our 9×9 floor (33 px) and shown only as a stress test.",14)
for row,s in enumerate("ABC"):
    y=110+row*145; lab(d,(G,y+50),names[s].split(" · ")[0]+" · "+names[s].split(" · ")[1].split()[0],15,700)
    x=170
    for k in kinds:
        for sz in sizes:
            for bgk in (None,6,7):  # cream, cocoa diamond, rhubarb sprig
                cell=sz+10
                if bgk is None: tile=Image.new("RGBA",(cell,cell),rgb("#FFF8EC"))
                else: tile=render_board(1,np.array([[bgk]]),{},s,cell*3,outer_w=3).resize((cell,cell),Image.LANCZOS)
                p=piece(k,int(sz),s); tile.alpha_composite(p,(cell//2-p.width//2,cell//2-p.height//2))
                sm.alpha_composite(tile,(x,y+(0 if bgk is None else (62 if bgk==6 else 0))) if False else (x,y))
                x+=cell+4
            x+=6
        x+=14
    # second line: X mark at same sizes for confusion check
    xx=170
    for sz in sizes:
        cell=sz+10; t=Image.new("RGBA",(cell,cell),rgb("#FFF8EC")); td=ImageDraw.Draw(t); x_mark(td,cell/2,cell/2,cell/0.9*1.0,s)
        sm.alpha_composite(t,(xx,y+72)); xx+=cell+6
    lab(d,(xx+6,y+80),"X-mark at 48/32/24 for comparison (thin, ink-only, no fill)",12)
# column headers
d=ImageDraw.Draw(sm); x=170
for k in kinds:
    w=sum((sz+10+4)*3+6 for sz in sizes)
    lab(d,(x,92),f"{k}: 48 · 32 · 24  (each: cream / cocoa / rhubarb)",11,600); x+=w+14
sm.convert("RGB").save(f"{OUT}/small_size_test.png"); print("small ok")
