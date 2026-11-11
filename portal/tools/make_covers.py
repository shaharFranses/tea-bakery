#!/usr/bin/env python3
"""CrazyGames covers for Teacake Lane (launch cover A "Golden tray", art/COVERS_PLAN.md) from the real in-game board.
usage: make_covers.py <board.png from render_cover_board.gd> <out_dir> <build_sha>
Writes cover-landscape-1920x1080_<sha>.png, cover-portrait-800x1200_<sha>.png, cover-square-800x800_<sha>.png.
Rules followed (portal/PORTAL_ASSET_SPECS.md): the title is the only text; no logos, borders, badges; consistent art
across the three; not a bare screenshot; built from shipped sprites + the game's title font (DM Serif Display)."""
import json, math, os, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
board_png, out_dir, sha = sys.argv[1:4]
meta = json.load(open(os.path.splitext(board_png)[0] + ".json"))
BOARD = Image.open(board_png).convert("RGBA")
STEAM = Image.open(f"{ROOT}/assets/board/steam_puff@2x.png").convert("RGBA")
FONT = f"{ROOT}/assets/fonts/DMSerifDisplay-Regular.ttf"
TITLE = "Teacake Lane"
CREAM, INK, GOLD, CRUST = (255, 248, 236), (67, 40, 58), (242, 193, 78), (201, 128, 58)
SS = 2   # supersample factor

def background(W, H, centre):
    """Raspberry vignette (lighter rose behind the tray, deep raspberry at the edges) + a faint cream lattice."""
    im = Image.new("RGB", (W, H)); px = im.load()
    c0, c1 = (236, 172, 190), (139, 40, 76)
    cx, cy = centre; rmax = math.hypot(max(cx, W - cx), max(cy, H - cy))
    for y in range(H):
        for x in range(W):
            t = min(1.0, math.hypot(x - cx, y - cy) / rmax) ** 1.25
            px[x, y] = tuple(int(c0[i] + (c1[i] - c0[i]) * t) for i in range(3))
    im = im.convert("RGBA")
    lat = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(lat)
    step = max(W, H) // 22
    for k in range(-H, W + H, step):
        d.line([(k, 0), (k + H, H)], fill=(255, 248, 236, 26), width=max(2, step // 26))
        d.line([(k, H), (k + H, 0)], fill=(255, 248, 236, 26), width=max(2, step // 26))
    im.alpha_composite(lat)
    return im

def tray(size):
    """The in-game board on a golden tray plate, with steam over three cakes. Returns an RGBA image (size + rim)."""
    rim = int(size * 0.035); W = size + 2 * rim
    t = Image.new("RGBA", (W, W), (0, 0, 0, 0)); d = ImageDraw.Draw(t)
    d.rounded_rectangle([0, 0, W - 1, W - 1], radius=int(size * 0.06), fill=CRUST)
    d.rounded_rectangle([rim // 3, rim // 3, W - 1 - rim // 3, W - 1 - rim // 2], radius=int(size * 0.055), fill=GOLD)
    b = BOARD.resize((size, size), Image.LANCZOS)
    t.alpha_composite(b, (rim, rim))
    n = meta["n"]; k = size / meta["px"]; m = meta["margin"] * k; cell = (size - 2 * m) / n
    for r in (0, 2, 4):
        c = meta["solution"][r]; s = int(cell * 1.15)
        st = STEAM.resize((s, s), Image.LANCZOS)
        st.putalpha(st.split()[3].point(lambda v: int(v * 0.9)))
        t.alpha_composite(st, (int(rim + m + c * cell + (cell - s) / 2), max(0, int(rim + m + r * cell - s * 0.72))))
    return t

def place(im, sp, centre, angle):
    sp = sp.rotate(angle, resample=Image.BICUBIC, expand=True)
    x, y = int(centre[0] - sp.width / 2), int(centre[1] - sp.height / 2)
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
    a = sp.split()[3].point(lambda v: int(v * 0.55))
    blk = Image.new("RGBA", sp.size, (60, 16, 40, 255)); blk.putalpha(a)
    off = int(sp.width * 0.022)
    sh.alpha_composite(blk, (max(0, x + off), max(0, y + int(off * 1.6))))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(sp.width * 0.022)))
    im.alpha_composite(sp, (x, y))

def title(im, lines, centre, size, align="center"):
    """Cream DM Serif title with an ink drop shadow (the only text on the cover)."""
    f = ImageFont.truetype(FONT, size); d = ImageDraw.Draw(im)
    lh = int(size * 1.02); y = centre[1] - lh * len(lines) / 2
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0)); ds = ImageDraw.Draw(sh)
    pos = []
    for ln in lines:
        w = d.textlength(ln, font=f)
        x = centre[0] - w / 2 if align == "center" else centre[0]
        pos.append((x, y, ln)); y += lh
    o = max(3, size // 16)
    for x, yy, ln in pos: ds.text((x + o * 0.5, yy + o), ln, font=f, fill=INK + (235,))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(max(1, size // 40))))
    d = ImageDraw.Draw(im)
    for x, yy, ln in pos:
        d.text((x, yy), ln, font=f, fill=CREAM, stroke_width=max(2, size // 28), stroke_fill=INK)

def cover(W, H, kind):
    w, h = W * SS, H * SS
    if kind == "landscape":
        bc = (int(w * 0.705), int(h * 0.51)); im = background(w, h, bc)
        place(im, tray(int(h * 0.74)), bc, -6)
        title(im, ["Teacake", "Lane"], (int(w * 0.235), int(h * 0.50)), int(h * 0.165))
    elif kind == "portrait":
        bc = (int(w * 0.5), int(h * 0.635)); im = background(w, h, bc)
        place(im, tray(int(w * 0.80)), bc, -6)
        title(im, ["Teacake", "Lane"], (int(w * 0.5), int(h * 0.135)), int(w * 0.17))
    else:
        bc = (int(w * 0.5), int(h * 0.585)); im = background(w, h, bc)
        place(im, tray(int(h * 0.60)), bc, -6)
        title(im, [TITLE], (int(w * 0.5), int(h * 0.095)), int(w * 0.125))
    return im.resize((W, H), Image.LANCZOS).convert("RGB")

os.makedirs(out_dir, exist_ok=True)
for kind, (W, H) in {"landscape": (1920, 1080), "portrait": (800, 1200), "square": (800, 800)}.items():
    p = f"{out_dir}/cover-{kind}-{W}x{H}_{sha}.png"
    cover(W, H, kind).save(p, optimize=True); print("cover:", p, os.path.getsize(p), "B")
# opening frame of the portrait preview video (same layout as the portrait cover, at the video size; not uploaded)
p = f"{out_dir}/preview-open-portrait-1080x1620_{sha}.png"
cover(1080, 1620, "portrait").save(p); print("preview opening frame:", p)
