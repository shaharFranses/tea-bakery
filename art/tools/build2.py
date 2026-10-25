import os, json, numpy as np
from PIL import Image, ImageDraw
from ttdraw import *
from ttboard import render_board
import ttcolor as T
OUT="/workspace/tea-and-tarts/art"; M=OUT+"/mocks"
INK=rgb(UI["earl_grey_ink"]); BG=rgb("#FBF4EE"); G=28
def title(d,xy,t,sz=30): d.text(xy,t,fill=INK,font=font("display",sz))
def lab(d,xy,t,sz=15,w=500,col=INK,anchor="la"): d.text(xy,t,fill=col,font=font("ui",sz,w),anchor=anchor)
REC="B"

def swatch_tile(k,sz,style=REC):
    return render_board(1,np.array([[k]]),{},style,sz*3,outer_w=3).resize((sz,sz),Image.LANCZOS)

# palette.png
pal=Image.new("RGBA",(1620,900),BG); d=ImageDraw.Draw(pal)
title(d,(G,20),"Game #4 (working name tea-bakery) — palette v1 (PROPOSED, pending Shahar)",32)
lab(d,(G,68),"UI / base colours",18,700)
for i,(n,h,use) in enumerate(T.UI):
    x=G+i*172; d.rounded_rectangle([x,100,x+160,200],radius=14,fill=rgb(h),outline=INK,width=2)
    lab(d,(x,210),n,14,700); lab(d,(x,230),h,14,500)
    words=use.split(); line="";yy=250
    for w_ in words:
        if len(line+w_)>23: lab(d,(x,yy),line,11,400); yy+=15; line=""
        line+=w_+" "
    lab(d,(x,yy),line,11,400)
lab(d,(G,350),"Dough-patch region colours — each has its own pattern (never colour-only). 9 patches so 9×9 boards are covered.",18,700)
for i,(n,h,p) in enumerate(T.REGIONS):
    x=G+i*172; pal.alpha_composite(swatch_tile(i,150),(x,385))
    lab(d,(x,545),n,15,700); lab(d,(x,566),h,14,500); lab(d,(x,586),"pattern: "+p,13,500)
lab(d,(G,640),"Contrast (WCAG): ink on cream %.1f:1 · ink on rosewater %.1f:1 · cream on raspberry %.1f:1 · cream on sage %.1f:1 · ink on rhubarb %.1f:1 (≥3:1 non-text) · ink on honey chip %.1f:1"%(
  T.contrast(UI["earl_grey_ink"],UI["clotted_cream"]),T.contrast(UI["earl_grey_ink"],UI["rosewater_bg"]),T.contrast(UI["clotted_cream"],UI["raspberry_jam"]),T.contrast(UI["clotted_cream"],UI["sage_leaf"]),T.contrast(UI["earl_grey_ink"],"#CB6F91"),T.contrast(UI["earl_grey_ink"],UI["honey_chip"])),13,500)
lab(d,(G,680),"Type: DM Serif Display (titles) · Lexend (UI, numbers) · Dancing Script (recipe-card names only). All SIL OFL. SD uses Fraunces + Atkinson Hyperlegible, so no font overlap.",13,500)
d.text((G,720),"Recipe Book",fill=rgb(UI["raspberry_jam"]),font=font("display",56))
d.text((420,730),"Victoria Sponge",fill=rgb(UI["raspberry_jam"]),font=font("script",46,700))
d.text((820,740),"Board 3 of 5 · 1 per row · column · patch",fill=INK,font=font("ui",26,500))
lab(d,(G,860),"Avoided on purpose: SD navy #2E4A5C/#1E2B38, teal #2C6E73, sea #2F7FA6/#6BB8C9, sky #BFE3EF, wood #8A5A3B, linen #F4EBDC; coffee browns as a dominant.",13,500)
pal.convert("RGB").save(OUT+"/palette.png")

# colourblind sheet
rep=T.pair_report()
mockB=Image.open(f"{M}/mock_{REC}_390x844.png").convert("RGB")
kinds=["normal","deuteranopia","protanopia","tritanopia"]
cb=Image.new("RGB",(G+9*96+40+4*0+300, 120+4*260),tuple(BG[:3]))
cb=Image.new("RGB",(1600,1180),tuple(BG[:3])); d=ImageDraw.Draw(cb)
title(d,(G,18),"Colour-vision check — Machado 2009 (severity 1.0), dE2000 between every pair of the 9 patches",28)
lab(d,(G,60),"Left: patch tiles (style B) simulated. Right: recommended mock simulated. Patterns + thick ink borders carry identity even where hues merge.",14)
tiles=Image.new("RGB",(9*96,96),"white")
for i in range(9): tiles.paste(swatch_tile(i,92).convert("RGB"),(i*96,2))
def sim_img(img,k):
    if k=="normal": return img
    a=np.asarray(img).astype(float)/255; s=T.simulate(a,k); return Image.fromarray((np.clip(s,0,1)*255).round().astype(np.uint8))
for r,k in enumerate(kinds):
    y=100+r*265
    lab(d,(G,y),k.upper(),16,700)
    cb.paste(sim_img(tiles,k),(G,y+26))
    worst=rep[k][:3]
    lab(d,(G,y+132),"closest pairs: "+" · ".join(f"{a}/{b} ΔE {v:.1f}" for v,a,b in worst),13,500)
    flag=min(v for v,_,_ in rep[k])
    lab(d,(G,y+152),("all pairs ≥ 10 ΔE00 (distinct)" if flag>=10 else "pairs <10 ΔE00 rely on pattern"),13,700,col=rgb(UI["sage_leaf"]) if flag>=10 else rgb(UI["cherry_alert"]))
    m=sim_img(mockB,k).resize((112,242),Image.LANCZOS); cb.paste(m,(980+r*150,100+26))
    lab(d,(980+r*150,100+275),k[:12],12,600)
# legend under
lab(d,(980,420),"Recommended mock (B) under each condition",13,700)
cb.save(OUT+"/colorblind_check.png")
json.dump({k:[[a,b,round(v,2)] for v,a,b in rep[k]] for k in rep},open(OUT+"/tools/cvd_pairs.json","w"),indent=1)

# SD side-by-side
sd=Image.open("/workspace/sd_art/theme_preview.png").convert("RGB").resize((475,844),Image.LANCZOS)
sb=Image.new("RGB",(G*3+475+390+G,844+130),tuple(BG[:3])); d=ImageDraw.Draw(sb)
title(d,(G,16),"Sudoku Dash (game #3) vs game #4 tea-bakery (option B, title area left blank)",26)
sb.paste(sd,(G,70)); sb.paste(mockB,(G*2+475,70))
lab(d,(G,70+844+12),"SD: seaside harbour, sea/sky blues, teal + navy UI, Fraunces",13,600)
lab(d,(G*2+475,70+844+12),"Game #4: inland tea room, rose + raspberry + plum ink",13,600)
lab(d,(G,70+844+34),"SD theme_preview.png shown unmodified for comparison only (studio-internal asset).",11,400)
sb.save(OUT+"/sd_side_by_side.png")

# overview board (presentation comparable to SD moodboard)
ov=Image.new("RGB",(1700,1200),tuple(BG[:3])); d=ImageDraw.Draw(ov)
title(d,(G,18),"Game #4 (tea-bakery) — Art Direction Board",34)
lab(d,(1100,32),"PROPOSED · pending Shahar approval · 2026-10-25",14,600)
for i,s in enumerate("ABC"):
    m=Image.open(f"{M}/mock_{s}_390x844.png").convert("RGB"); x=G+i*420
    ov.paste(m,(x,80))
    nm={"A":"A · Watercolour Tea Room","B":"B · Crisp Pastry Flat (RECOMMENDED)","C":"C · Vintage China & Stitch"}[s]
    lab(d,(x,932),nm,15,700,col=rgb(UI["raspberry_jam"]) if s==REC else INK)
pt=Image.open(OUT+"/palette.png").convert("RGB"); 
px=G+3*420
for i,(n,h,u) in enumerate(T.UI):
    y=90+i*40; d.rounded_rectangle([px,y,px+40,y+36],radius=8,fill=rgb(h),outline=INK,width=1)
    lab(d,(px+50,y+4),n,13,700); lab(d,(px+50,y+21),h,12,400)
for i,(n,h,p) in enumerate(T.REGIONS):
    y=470+i*50; ov.paste(swatch_tile(i,44).convert("RGB"),(px,y))
    lab(d,(px+52,y+6),f"{n} · {p}",13,700); lab(d,(px+52,y+24),h,12,400)
d.text((G,975),"Recipe Book",fill=rgb(UI["raspberry_jam"]),font=font("display",48))
lab(d,(330,985),"Display: DM Serif Display (OFL) — headings only, not a logo",13,500)
d.text((620,968),"Victoria Sponge",fill=rgb(UI["raspberry_jam"]),font=font("script",44,700))
lab(d,(930,985),"Recipe names: Dancing Script (OFL)",13,500)
d.text((G,1050),"Board 3 of 5 · 1 per row · column · patch",fill=INK,font=font("ui",28,500))
lab(d,(700,1062),"UI / numbers: Lexend (OFL)",13,500)
lab(d,(G,1120),"No sea, harbour, boats or coffee. No game title/wordmark (title TBD) and no studio logo. All art procedurally drawn in-house (tools/*.py); fonts SIL OFL.",14,600)
ov.save(OUT+"/art_direction_board.png")
print("done")
