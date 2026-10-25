import os,json
from PIL import Image, ImageDraw
from ttdraw import font
R="/workspace/tea-and-tarts/assets"
W=1200; im=Image.new("RGBA",(W,900),"#F6E3DE"); d=ImageDraw.Draw(im)
L=lambda p: Image.open(f"{R}/{p}").convert("RGBA")
ic=["home","back","close","settings","undo","reset","hint","rewarded","sound_on","sound_off","music_on","music_off","lock","streak","check","book","play","help"]
for i,n in enumerate(ic):
    x=20+i*64; im.alpha_composite(L(f"ui/icons/icon_{n}@2x.png").resize((48,48)),(x,20))
    d.rounded_rectangle([x-4,80,x+52,136],radius=12,fill="#B0365A"); im.alpha_composite(L(f"ui/icons/icon_{n}_cream.png"),(x,84))
    d.text((x+24,142),n[:8],fill="#43283A",font=font("ui",10),anchor="mt")
y=170;x=20
for k in ("primary","secondary","tool"):
    for s in ("normal","pressed","disabled"):
        b=L(f"ui/btn_{k}_{s}.png"); im.alpha_composite(b,(x,y)); x+=104
for n in ("btn_round_normal","btn_round_pressed","toggle_on","toggle_off","chip_honey","progress_dot_on","progress_dot_off","badge_rewarded","badge_free_hint"):
    b=L(f"ui/{n}.png"); im.alpha_composite(b,(x if x<1150 else 20,y if x<1150 else y+80)); x+=b.width+12
    if x>1150: x=20; y+=80
y=330; x=20
for n in ("panel_card","panel_modal","coach_bubble"):
    b=L(f"ui/{n}.png"); im.alpha_composite(b,(x,y)); x+=120
im.alpha_composite(L("ui/coach_tail@2x.png"),(x,y)); x+=90
im.alpha_composite(L("ui/pointer_hand@2x.png"),(x,y-20)); x+=210
for n in ("tray_frame","tray_frame_solved"): im.alpha_composite(L(f"board/{n}@2x.png"),(x,y)); x+=200
y=560;x=20
for t in range(9):
    tl=L(f"board/{sorted(os.listdir(R+'/board'))[0] and ''}tile_{t}_{['strawberry','butter','pistachio','lavender','honey','blueberry','cocoa','rhubarb','vanilla'][t]}.png")
    for j,ov in enumerate([None,"overlay_hint_unit","overlay_hint_target","overlay_conflict_unit","steam_puff"]):
        c=tl.copy()
        if ov: c.alpha_composite(L(f"board/{ov}.png"))
        if ov in ("overlay_hint_target","steam_puff"): pass
        im.alpha_composite(c.resize((64,64)),(x+t*70,y+j*66))
im.save("/tmp/tt_p1_sheet_v2.png")
