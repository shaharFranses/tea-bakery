"""Writes docs/art/ASSET_MANIFEST.json + .md for every shipped art file (paths, px size, bytes, purpose, scene/node, states)."""
import os, re, json, glob
from PIL import Image
ROOT="/workspace/tea-and-tarts"
DIRS=["assets/board","assets/ui","assets/ui/icons","assets/fonts","assets/recipes","assets/decor","assets/backdrop"]
REC={1:"Scones & clotted cream",2:"Victoria sponge",3:"Lemon drizzle",4:"Jam tarts",5:"Cherry Bakewell",6:"Strawberry shortcake",7:"Apple crumble",8:"Macarons"}
def meta(rel):
    n=os.path.basename(rel); b=re.sub(r"(@2x)?\.(png|webp|ttf|txt|json|gd)$","",n)
    R=lambda p,s,st,drop="P0": (p,s,st,drop)
    if rel.startswith("ui/theme"): return R("ArtPalette constants (colours, region seams/rims, board geometry)","global class ArtPalette (board_view.gd, theme)","—","P1")
    if b=="mold": return R("Empty cake mold (note mark)","BoardView cell, drawn 0.70×cell","MOLD (alpha 1.0), MOLD_AUTO (alpha 0.5)")
    if b=="cake_berry": return R("v1 cake: berry v2 (D-03)","BoardView cell, drawn 1.0×cell","CAKE, given, conflict, solved")
    if b.startswith("cake_"): return R(f"B2 cake '{b[5:]}' (not on the v1 board, D-03; reserve)","— (post-v1 / promo)","—")
    if b.startswith("tile_"): return R(f"Padded cookie tile, region {b.split('_')[1]} {b.split('_')[2]}","BoardView cell face (tile rect = 0.925×cell)","EMPTY (base for all states)")
    if b=="overlay_conflict": return R("Conflict hatch + dashed cherry ring (under cake)","BoardView cell","conflict")
    if b=="badge_conflict": return R("Conflict '!' badge (over cake)","BoardView cell","conflict")
    if b=="overlay_solved": return R("Toasted glow (under cake)","BoardView cell","solved")
    if b=="badge_solved": return R("Sage tick (over cake)","BoardView cell","solved")
    if b=="given_plate": return R("Plate under a given cake","BoardView cell","given")
    if b=="overlay_hint_unit": return R("Gold glow per cell of hinted unit","BoardView cell","hint","P1")
    if b=="overlay_hint_target": return R("Pulsing gold ring on hint target","BoardView cell (tweened)","hint","P1")
    if b=="overlay_conflict_unit": return R("Cherry tint per cell of the shared conflict unit (D-10)","BoardView cell","conflict","P1")
    if b=="steam_puff": return R("Solved steam wisp (tweened up + fade)","BoardView solved FX","solved","P1")
    if b.startswith("tray_frame"): return R("9-slice baking tray (margins 32)"+(" golden" if "solved" in b else ""),"Board tray NinePatchRect","solved" if "solved" in b else "in-progress","P1")
    if b.startswith("btn_"):
        k=b.split("_"); return R(f"9-slice button '{k[1]}' (margins 24)" if k[1]!="round" else "Round icon button 56 px","Button StyleBoxTexture",k[-1],"P1")
    if b.startswith("icon_"): return R(f"Icon '{b[5:].replace('_cream','')}'"+(" (cream, on coloured buttons)" if b.endswith("_cream") else " (ink)"),"TextureRect / Button.icon","—","P1")
    if b in("panel_card","panel_modal"): return R(f"9-slice {b[6:]} panel (margins 32)","PanelContainer StyleBoxTexture","—","P1")
    if b=="chip_honey": return R("Info chip (margins 20/18); no star chip","Label bg (Bake of the Day, Board n of 5)","—","P1")
    if b=="coach_bubble": return R("Coach / hint / rules bubble 9-slice (margins 24; 72→88 px for 3 lines)","Coach bubble PanelContainer","coach, hint, rules","P1")
    if b=="coach_tail": return R("Bubble tail","Coach bubble child","—","P1")
    if b.startswith("toggle_"): return R(f"Settings toggle {b[7:]}","CheckButton icons","on/off","P1")
    if b.startswith("progress_dot"): return R("Chapter progress dot","Top bar / right panel","on/off","P1")
    if b.startswith("badge_free") or b=="badge_rewarded": return R("Hint button corner badge","Hint button","free / rewarded","P1")
    if b=="pointer_hand": return R("Tutorial pointer hand (no face)","Tutorial overlay","tutorial c1-b1..b3","P1")
    if n.endswith(".ttf"): return R(f"Font {b}","Theme default font / headings","—","P1")
    if n.startswith("OFL"): return R("SIL OFL 1.1 licence text (must ship with font)","—","—","P1")
    if b=="recipe_locked": return R("Recipe card back (locked)","Recipe Book card","locked","P2")
    if b.startswith("recipe_"): i=int(b.split("_")[1]); return R(f"Recipe card ch{i}: {REC[i]} (name drawn by label)","Recipe Book / Chapter end card","unlocked","P2")
    if b.startswith("decor_"): return R(f"Décor ch{b.split('_')[1]}: {' '.join(b.split('_')[2:])}","Home counter shelf / Chapter end drop","owned","P2")
    if b=="shelf_counter": return R("Counter shelf (360×160)","Home + Chapter end + All recipes baked","—","P2")
    if b.startswith("shelf_"): return R(f"Shelf variant: {b[6:]}","Counter shelf overlay","owned ch3/ch6","P2")
    if b.startswith("backdrop_"): return R(f"Tea-room backdrop ({b[9:]})","main.gd Backdrop TextureRect","—","P2")
    return R("?","?","?","?")
rows=[]
files=[f for d in DIRS for f in sorted(glob.glob(f"{ROOT}/{d}/*")) if os.path.isfile(f) and not f.endswith((".import","README.txt"))]+[f"{ROOT}/ui/theme/art_palette.gd"]
for f in files:
    rel=os.path.relpath(f,ROOT); px=""
    if f.endswith((".png",".webp")): w,h=Image.open(f).size; px=f"{w}x{h}"
    p,s,st,drop=meta(rel.replace("assets/","",1))
    rows.append({"path":"res://"+rel,"px":px,"bytes":os.path.getsize(f),"purpose":p,"scene_node":s,"states":st,"drop":drop,"scale":"@2x" if "@2x" in f else ("1x" if f.endswith(".png") else "")})
tot=sum(r["bytes"] for r in rows); t2=sum(r["bytes"] for r in rows if r["scale"]!="1x")
json.dump({"generated_by":"art/tools/gen_manifest.py","count":len(rows),"bytes_total":tot,"bytes_if_2x_only":t2,"assets":rows},open(f"{ROOT}/docs/art/ASSET_MANIFEST.json","w"),indent=1,ensure_ascii=False)
L=["# Asset manifest: shipped art (tea-bakery)","Generated by `art/tools/gen_manifest.py`; do not hand-edit. The JSON twin is `ASSET_MANIFEST.json`. Integration notes: `art/HANDOFF_GODOT.md`.",
   f"**{len(rows)} files, {tot/1e6:.2f} MB** on disk ({t2/1e6:.2f} MB if only the `@2x` PNGs ship). The manifest has no coffee, sea or harbour assets (TT-AC-38).","",
   "Rows list the 1x file; the `@2x` twin has the same purpose at double the px.","",
   "| Path | px (1x) | bytes 1x / @2x | Purpose | Scene / node | States | Drop |","|---|---|---|---|---|---|---|"]
by={r["path"]:r for r in rows}
for r in rows:
    if r["scale"]=="@2x": continue
    tw=by.get(r["path"].replace(".png","@2x.png")) if r["scale"]=="1x" else None
    L.append(f"| `{r['path']}` | {r['px']} | {r['bytes']}{' / '+str(tw['bytes']) if tw else ''} | {r['purpose']} | {r['scene_node']} | {r['states']} | {r['drop']} |")
open(f"{ROOT}/docs/art/ASSET_MANIFEST.md","w").write("\n".join(L)+"\n")
print(len(rows),tot,t2, [r["path"] for r in rows if r["purpose"]=="?"])
