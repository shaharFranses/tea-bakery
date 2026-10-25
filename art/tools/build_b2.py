import os, json, numpy as np
from PIL import Image, ImageDraw
from ttdraw import rgb, UI, REG, font, gen_board
from ttb2 import cake, mold, render_board_b2, CAKE_FOR_REGION, CAKE_NAMES, TRAY_GAP
from ttmock import mock
import ttcolor as T
OUT="/workspace/tea-and-tarts/art"; M=OUT+"/mocks"
INK=rgb(UI["earl_grey_ink"]); BG=(251,244,238)
def lab(d,xy,t,sz=14,w=500,anchor="la",col=INK): d.text(xy,t,fill=col,font=font("ui",sz,w),anchor=anchor)
def title(d,xy,t,sz=28): d.text(xy,t,fill=INK,font=font("display",sz))
def bf(n,reg,cells,bsz,seed): return render_board_b2(n,reg,cells,bsz,seed=seed)
def sim(img,k):
    if k=="normal": return img
    a=np.asarray(img.convert("RGB")).astype(float)/255
    return Image.fromarray((np.clip(T.simulate(a,k),0,1)*255).round().astype(np.uint8))

# --- 1) portrait mock, 8x8
n=8; reg,q=gen_board(n,21)
cells={q[0]:"cake",q[3]:"cake",q[5]:"cake",q[7]:"cake",
       (0,(q[0][1]+3)%n):"x",(q[3][0],(q[3][1]+2)%n):"x",(q[5][0]-1,(q[5][1]+4)%n):"x",(q[7][0],(q[7][1]+3)%n):"x",(1,q[0][1]):"x"}
small,big=mock("B",n=8,seed=21,cells=cells,board_fn=bf,mark_icon="mold",mark_label="Empty",tray_inner=TRAY_GAP)
small.save(f"{M}/mock_B2_390x844.png"); big.resize((780,1688),Image.LANCZOS).save(f"{M}/mock_B2_390x844@2x.png")
print("mock ok")

# --- 2) cakes close-up
kinds=["berry","lemon","victoria","scone","bakewell","chocolate","macaron","custard","apricot"]
items=[(k,CAKE_NAMES[k]) for k in kinds]+[("mold","Empty mold (marks 'no cake')")]
sizes=[("8×8 mobile",36),("9×9 desktop 800×450",42),("24 px",24)]   # cake drawn at ~0.86-0.92 of cell
patches=[("vanilla",8),("butter",1),("rhubarb",7),("cocoa",6),("blueberry",5)]
COLW=136; LW=200
def cell_tile(kidx,cellpx,item):
    t=render_board_b2(1,np.array([[kidx]]),{},cellpx*3).resize((cellpx,cellpx),Image.LANCZOS)
    if item=="mold": p=mold(int(cellpx*0.62))
    else: p=cake(item,int(cellpx*0.92))
    t.alpha_composite(p,(cellpx//2-p.width//2,cellpx//2-p.height//2)); return t
rowsH=[180]+[ (max(s for _,s in sizes)//1+20) ]*0
H=150+175+len(sizes)*len(patches)*0+ (len(sizes)*62+30)*2 + 60
img=Image.new("RGBA",(LW+len(items)*COLW+30, 150+175+len(sizes)*(len(patches)*0+1)*0+ 3*130 + 3*130 + 120),BG); d=ImageDraw.Draw(img)
title(d,(24,16),"B2 cakes + empty mold: 160 px, then real cell sizes on light and dark patches")
lab(d,(24,56),"Real sizes: 8×8 on a 390-px phone = 42 px cell (cake ~38 px) · 9×9 wide desktop at 800×450 = 46 px cell · 24 px stress test. Patches per size: vanilla, butter, rhubarb, cocoa, blueberry.",13)
for i,(k,nm) in enumerate(items):
    x=LW+i*COLW
    big_=mold(150) if k=="mold" else cake(k,150)
    if k=="mold":
        bgt=render_board_b2(1,np.array([[3]]),{},150*3).resize((150,150),Image.LANCZOS); bgt.alpha_composite(big_); big_=bgt
    img.alpha_composite(big_,(x-10,90))
    words=nm.split(); l1=" ".join(words[:2]); l2=" ".join(words[2:])
    lab(d,(x+65,250),l1,12,700,"mm"); lab(d,(x+65,266),l2,12,700,"mm")
y=290
def block(y0,simk=None):
    y=y0
    for sname,cellpx in [("8×8 mobile · 42 px cell",42),("9×9 desktop · 46 px cell",46),("24 px",28)]:
        lab(d,(24,y+14),sname,13,700)
        for i,(k,nm) in enumerate(items):
            x=LW+i*COLW-8
            for j,(pn,pidx) in enumerate(patches):
                t=cell_tile(pidx,cellpx,k)
                if k!="mold" and cellpx==28:
                    t=render_board_b2(1,np.array([[pidx]]),{},cellpx*3).resize((cellpx,cellpx),Image.LANCZOS); p=cake(k,24); t.alpha_composite(p,(cellpx//2-12,cellpx//2-12))
                if k=="mold" and cellpx==28:
                    t=render_board_b2(1,np.array([[pidx]]),{},cellpx*3).resize((cellpx,cellpx),Image.LANCZOS); p=mold(18); t.alpha_composite(p,(5,5))
                img.alpha_composite(t,(x+(j%3)*(cellpx+2),y+(j//3)*(cellpx+2)))
        y+=2*(cellpx+2)+16
    return y
y=block(y)
yd=y+10
lab(d,(24,yd),"DEUTERANOPIA (Machado 2009, severity 1.0): rows above, simulated",15,700)
y2=block(yd+30)
# simulate the second block region
reg_box=(0,yd+30,img.width,y2)
crop=img.crop(reg_box).convert("RGB"); img.paste(sim(crop,"deuteranopia").convert("RGBA"),(0,yd+30))
img=img.crop((0,0,img.width,y2+20))
img.convert("RGB").save(OUT+"/cakes_closeup_B2.png"); print("closeup ok")

# --- 3) cell states strip B2
states=[("empty","Empty"),("x","Empty mold"),("cake","Cake"),("conflict","Conflict"),("solved","Solved")]
C1,C2=42,130
st=Image.new("RGBA",(24+5*(C2+40)+20,560),BG); d=ImageDraw.Draw(st)
title(d,(24,16),"B2 cell states: large + true 8×8 mobile size (42 px)",24)
lab(d,(24,52),"Conflict = cherry ring + hatch + ! badge (shape, not colour). Solved = toasted glow + tick. Mold = outline only, no halo, no shadow.",13)
for row,(pidx,pn) in enumerate([(2,"pistachio patch"),(7,"rhubarb patch (dark)")]):
    y=86+row*235
    lab(d,(24,y),pn,14,700)
    for i,(s_,lb) in enumerate(states):
        x=24+i*(C2+40)
        cells={} if s_=="empty" else {(0,0):s_}
        bigt=render_board_b2(1,np.array([[pidx]]),cells,C2*3).resize((C2,C2),Image.LANCZOS)
        sm=render_board_b2(1,np.array([[pidx]]),cells,C1*3).resize((C1,C1),Image.LANCZOS)
        st.alpha_composite(bigt,(x,y+22)); st.alpha_composite(sm,(x+C2//2-C1//2,y+30+C2))
        lab(d,(x+C2//2,y+C2+C1+44),lb,13,600,"mm")
st.convert("RGB").save(OUT+"/cell_states_strip_B2.png"); print("strip ok")

# --- 4) wide desktop B2
import build_followup as BF
for (w,h) in ((1920,1080),(800,450)):
    im,cp=BF.wide(w,h,SS=2 if w>1000 else 3,board_fn=bf,mark_icon="mold",mark_label="Empty",tray_inner=TRAY_GAP)
    im.save(f"{M}/desktop_wide_9x9_B2_{w}x{h}.png"); print(w,h,"cell %.1f"%cp)

# --- 5) colour-blind sheet for B2 + checks
mk=Image.open(f"{M}/mock_B2_390x844.png").convert("RGB")
cb=Image.new("RGB",(24+4*410,844//1+140),BG); d=ImageDraw.Draw(cb)
title(d,(24,14),"B2 mock under colour-vision simulation (Machado 2009, severity 1.0)",24)
for i,k in enumerate(["normal","deuteranopia","protanopia","tritanopia"]):
    s_=sim(mk,k).resize((370,800),Image.LANCZOS); cb.paste(s_,(24+i*410,60)); lab(d,(24+i*410,868),k,14,700)
cb.save(OUT+"/colorblind_check_B2.png")
rep=T.pair_report()
res={"region_pair_min_dE2000":{k:[v[0][1],v[0][2],round(v[0][0],2)] for k,v in rep.items()}}
gap=TRAY_GAP
res["region_face_vs_tray_gap_contrast"]={n:round(T.contrast(h,gap),2) for n,h,_ in T.REGIONS}
def blend(fg,a,bg):
    f=T.hex2rgb(fg); b=T.hex2rgb(bg); return T.rgb2hex(f*a+b*(1-a))
res["mold_stroke_vs_patch_contrast(ink@84%)"]={n:round(T.contrast(blend(UI["earl_grey_ink"],0.84,h),h),2) for n,h,_ in T.REGIONS}
res["best_of_face_or_rim_vs_gap"]={n:round(max(T.contrast(h,gap),T.contrast(T.rgb2hex(T.hex2rgb(h)*0.72),gap)),2) for n,h,_ in T.REGIONS}
res["rim_vs_tray_gap_contrast"]={n:round(T.contrast(T.rgb2hex(np.array([int(h[i:i+2],16) for i in (1,3,5)])*0.72/255),gap),2) for n,h,_ in T.REGIONS}
json.dump(res,open(OUT+"/tools/b2_checks.json","w"),indent=1)
print(json.dumps(res,indent=0))
