"""Mock CrazyGames-style browse grid (6x3, 230x130 tiles) with concepts A and B among self-drawn placeholder covers.
Placeholders are plain original drawings (no real game covers). Output art/covers/grid_test.png (actual size + 'glance')."""
import math, random
from PIL import Image, ImageDraw, ImageFilter
OUT="/workspace/tea-and-tarts/art/covers"; TW,TH,G=230,130,14
random.seed(5)
def ph(kind,seed):
    r=random.Random(seed); im=Image.new("RGB",(TW*2,TH*2)); d=ImageDraw.Draw(im); W,H=im.size
    bgs={"sudoku":"#2F5D8C","blocks":"#3B2A5C","word":"#F2E6C9","jigsaw":"#6FA6C8","cupcake":"#F7C6D9","pancake":"#FFE2A8","cookie":"#C9E4D6","bubble":"#1E2240","mahjong":"#2E6B4F","ramen":"#F3D9B1","donut":"#BFE3F2","kitchen":"#F6B38E"}
    d.rectangle([0,0,W,H],fill=bgs[kind])
    if kind=="sudoku":
        x0,y0,s=W*0.3,H*0.12,H*0.76
        d.rectangle([x0,y0,x0+s,y0+s],fill="#FFFFFF")
        for i in range(10): w=4 if i%3==0 else 1; d.line([(x0+i*s/9,y0),(x0+i*s/9,y0+s)],fill="#222",width=w); d.line([(x0,y0+i*s/9),(x0+s,y0+i*s/9)],fill="#222",width=w)
    elif kind=="blocks":
        cols=["#FF5C8A","#FFD23F","#3EC1D3","#7BE495","#B388FF"]
        for i in range(26): x=r.randrange(0,W-40); y=r.randrange(H//3,H-40); d.rounded_rectangle([x,y,x+38,y+38],radius=6,fill=r.choice(cols),outline="#111",width=2)
    elif kind=="word":
        for i,cx in enumerate(range(70,W-40,64)): d.rounded_rectangle([cx,H*0.42,cx+54,H*0.42+54],radius=8,fill="#FFFFFF",outline="#6B4E2E",width=3); d.ellipse([cx+20,H*0.42+20,cx+34,H*0.42+34],fill="#6B4E2E")
    elif kind=="jigsaw":
        for i in range(3):
            for j in range(5): d.rounded_rectangle([40+j*76,30+i*70,110+j*76,94+i*70],radius=10,fill=r.choice(["#F4A259","#BC4B51","#5B8E7D","#F4E285"]))
    elif kind=="cupcake":
        cx=W/2; d.polygon([(cx-60,H*0.55),(cx+60,H*0.55),(cx+44,H*0.9),(cx-44,H*0.9)],fill="#E58FB1",outline="#7A3B55")
        for k in range(3): d.ellipse([cx-70+k*10,H*0.3-k*25,cx+70-k*10,H*0.62-k*25],fill="#FFF4F8",outline="#C98AA4",width=3)
        d.ellipse([cx-14,H*0.12,cx+14,H*0.24],fill="#D72638")
    elif kind=="pancake":
        for k in range(5): d.ellipse([W*0.25,H*0.75-k*24,W*0.75,H*0.92-k*24],fill="#E0A458",outline="#9C6B30",width=3)
        d.ellipse([W*0.4,H*0.4,W*0.6,H*0.5],fill="#FFF3B0")
    elif kind=="cookie":
        d.rounded_rectangle([W*0.32,H*0.22,W*0.68,H*0.9],radius=30,fill="#E8F1F2",outline="#6C8EA4",width=4)
        for k in range(3): d.ellipse([W*0.38+k*28,H*0.5+k*8,W*0.38+k*28+60,H*0.5+k*8+60],fill="#C68B59",outline="#7A4E2D",width=3)
    elif kind=="bubble":
        for i in range(40): x=r.randrange(0,W); y=r.randrange(0,H); rr=r.randrange(12,26); d.ellipse([x-rr,y-rr,x+rr,y+rr],fill=r.choice(["#FF4D6D","#4CC9F0","#F9C74F","#90BE6D"]))
    elif kind=="mahjong":
        for i in range(4):
            for j in range(6): d.rounded_rectangle([50+j*62,40+i*50,104+j*62,84+i*50],radius=6,fill="#FAF3E0",outline="#2B2B2B",width=2); d.ellipse([70+j*62,52+i*50,84+j*62,66+i*50],fill=r.choice(["#C0392B","#1E8449","#2471A3"]))
    elif kind=="ramen":
        d.chord([W*0.2,H*0.25,W*0.8,H*1.1],0,180,fill="#D1495B",outline="#5A1A22",width=4); d.ellipse([W*0.2,H*0.42,W*0.8,H*0.62],fill="#F6D6A8",outline="#5A1A22",width=3)
    elif kind=="donut":
        d.ellipse([W*0.3,H*0.15,W*0.7,H*0.95],fill="#F28FB5",outline="#7A3B55",width=4); d.ellipse([W*0.44,H*0.43,W*0.56,H*0.67],fill="#BFE3F2",outline="#7A3B55",width=3)
    elif kind=="kitchen":
        d.rectangle([0,H*0.65,W,H],fill="#8C5A3C")
        for k in range(3): d.ellipse([60+k*130,H*0.42,160+k*130,H*0.7],fill="#3D3D3D")
    # generic title bar (no readable text) like most portal covers
    if r.random()<0.75:
        d.rounded_rectangle([W*0.08,H*0.05,W*0.08+W*r.uniform(0.35,0.6),H*0.05+30],radius=8,fill=r.choice(["#FFFFFF","#FFE66D","#111111"]))
    return im.resize((TW,TH),Image.LANCZOS)
def ours(n):
    im=Image.open(f"{OUT}/concept_{n}_960x540.jpg").convert("RGB")
    return im.resize((TW,TH),Image.LANCZOS)
kinds=["sudoku","cupcake","blocks","pancake","word","jigsaw","cookie","bubble","mahjong","ramen","donut","kitchen","sudoku","cupcake","blocks","pancake"]
cells=[]; k=0
import sys
V2=len(sys.argv)>1 and sys.argv[1]=="v2"
POS={3:"A",13:"B"} if not V2 else {1:"A2",10:"B2",12:"A",16:"B"}
for i in range(18):
    if i in POS: cells.append((POS[i],ours(POS[i])))
    else: cells.append((kinds[k],ph(kinds[k],i))); k+=1
GW,GH=6*TW+7*G,3*TH+4*G
grid=Image.new("RGB",(GW,GH),"#0C0D14")   # CG dark browse background
m=Image.new("L",(TW,TH),0); ImageDraw.Draw(m).rounded_rectangle([0,0,TW-1,TH-1],radius=10,fill=255)
for i,(n,t) in enumerate(cells):
    x=G+(i%6)*(TW+G); y=G+(i//6)*(TH+G); grid.paste(t,(x,y),m)
glance=grid.resize((GW//4,GH//4),Image.LANCZOS).filter(ImageFilter.GaussianBlur(1.2)).resize((GW,GH),Image.BILINEAR)
sheet=Image.new("RGB",(GW,GH*2+60),"#FFFFFF"); d=ImageDraw.Draw(sheet)
from ttdraw import font
sheet.paste(grid,(0,30)); sheet.paste(glance,(0,GH+60))
cap=("Actual size (230x130 tiles on CG-style dark grid). Ours: row 1 col 4 = A 'Golden tray'; row 3 col 2 = B 'Recipe book table'. Others = self-drawn placeholders." if not V2 else
     "v2 test, actual size (230x130). Ours: row1 col2 = A2, row2 col5 = B2 (v2); row3 col1 = A, row3 col5 = B (v1, for comparison). Others = self-drawn placeholders.")
d.text((8,6),cap,fill="#43283A",font=font("ui",15,500))
d.text((8,GH+36),"Glance: downscaled to 1/4 + blurred (peripheral read while scrolling)",fill="#43283A",font=font("ui",15,500))
fn="grid_test_v2.png" if V2 else "grid_test.png"
sheet.save(f"{OUT}/{fn}",optimize=True); sheet.save(f"/tmp/tt_{fn}")
print(sheet.size)
