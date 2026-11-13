"""Cake side + top views (request: CAKE_VIEWS.md). For each of the 8 chapter cakes, draws the view it does not
have yet and writes `cake_<name>_side` / `cake_<name>_top` at 1x (128 px) and @2x (256 px) into assets/board/.
The existing view is copied pixel-for-pixel under its `_side` / `_top` name; `cake_<name>` itself is untouched.
Same conventions as ttb2.cake: 256 canvas, plum ink outline, cream sticker halo, flat fills, one small highlight.
usage (from art/tools): python3 export_views.py [preview.png]"""
import os, sys, math, shutil, hashlib, random, numpy as np
from PIL import Image, ImageDraw, ImageFilter
from ttdraw import rgb, shade, UI
from ttb2 import _finish

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "assets", "board")
INK = UI["earl_grey_ink"]; SAGE = UI["sage_leaf"]; RASP = UI["raspberry_jam"]
OC = rgb(INK); OW = 10; HL = (255, 255, 255, 130)
CRUST = rgb("#F2C584"); CRUST_D = rgb("#DDA766"); CREAMY = rgb("#FFF6E8")
SS = 3   # supersample; shapes are authored in 256-px units
LEGACY = {"scone": "side", "victoria": "side", "lemon": "top", "apricot": "top", "bakewell": "top", "berry": "top",
          "custard": "top", "macaron": "side", "chocolate": "top"}


class Pen:
    """ImageDraw in 256-px units on an SS-times larger canvas."""
    def __init__(self):
        self.im = Image.new("RGBA", (256 * SS, 256 * SS), (0, 0, 0, 0)); self.d = ImageDraw.Draw(self.im)
    @staticmethod
    def _s(v):
        if isinstance(v, (list, tuple)): return [Pen._s(x) for x in v] if isinstance(v[0], (list, tuple)) else [x * SS for x in v]
        return v * SS
    @staticmethod
    def _pts(p): return [(x * SS, y * SS) for x, y in p]
    def _w(self, kw):
        if kw.get("width"): kw["width"] = int(round(kw["width"] * SS))
        if "radius" in kw: kw["radius"] = kw["radius"] * SS
        return kw
    def ellipse(self, b, **kw): self.d.ellipse(self._s(b), **self._w(kw))
    def circle(self, x, y, r, **kw): self.ellipse([x - r, y - r, x + r, y + r], **kw)
    def chord(self, b, a0, a1, **kw): self.d.chord(self._s(b), a0, a1, **self._w(kw))
    def arc(self, b, a0, a1, **kw): self.d.arc(self._s(b), a0, a1, **self._w(kw))
    def rect(self, b, **kw): self.d.rectangle(self._s(b), **self._w(kw))
    def rrect(self, b, **kw): self.d.rounded_rectangle(self._s(b), **self._w(kw))
    def poly(self, p, **kw): self.d.polygon(self._pts(p), **self._w(kw))
    def line(self, p, **kw):
        kw = self._w(kw); p = self._pts(p); self.d.line(p, joint="curve", **kw)
        r = kw.get("width", 1) / 2   # round caps
        for x, y in (p[0], p[-1]): self.d.ellipse([x - r, y - r, x + r, y + r], fill=kw.get("fill"))
    def layer(self, im2): self.im.alpha_composite(im2); self.d = ImageDraw.Draw(self.im)
    def done(self): return self.im.resize((256, 256), Image.LANCZOS)


def fluted_pts(cx, cy, R, n, depth):
    return [(cx + (R - depth + depth * abs(math.cos(n * a / 2))) * math.cos(a), cy + (R - depth + depth * abs(math.cos(n * a / 2))) * math.sin(a))
            for a in (2 * math.pi * i / (n * 8) for i in range(n * 8))]


# ---------------------------------------------------------------- side views (tarts in profile)
TOP_Y, BASE_Y = 150, 222          # crust wall: rim line and plate line
XT0, XT1, XB0, XB1 = 26, 230, 48, 208

def dome(p, fill, h, inset=14, w=7):
    """Filling seen above the rim: half-ellipse of height h sitting on the rim line."""
    p.chord([XT0 + inset, TOP_Y - h, XT1 - inset, TOP_Y + h], 180, 360, fill=fill, outline=OC, width=w)

def crust_wall(p, flutes=9, crimp=False, plain=False):
    """Pastry case in profile: wall wider at the rim, scalloped (fluted) rim, vertical flute shading."""
    body = [(XT0, TOP_Y), (XT1, TOP_Y), (XB1, BASE_Y - 10), (XB1 - 10, BASE_Y), (XB0 + 10, BASE_Y), (XB0, BASE_Y - 10)]
    if plain:
        p.poly(body, fill=CRUST, outline=OC, width=OW)
        p.rrect([XT0 - 4, TOP_Y - 12, XT1 + 4, TOP_Y + 14], radius=13, fill=CRUST, outline=OC, width=OW)   # smooth rolled rim
        p.line([(XT0 + 16, TOP_Y + 26), (XT1 - 16, TOP_Y + 26)], fill=CRUST_D, width=5)
        return
    n = flutes * 2 if crimp else flutes
    step = (XT1 - XT0) / n; r = step / 2 + (1 if crimp else 2)
    p.poly(body, fill=CRUST, outline=OC, width=OW)
    for i in range(n):   # scallops, outlined; lower halves are merged into the wall
        x = XT0 + step * (i + 0.5); p.ellipse([x - r, TOP_Y - r * (1.5 if crimp else 1.1), x + r, TOP_Y + r], fill=CRUST, outline=OC, width=OW - 3)
    p.rect([XT0 + OW - 1, TOP_Y + 1, XT1 - OW + 1, TOP_Y + r + 2], fill=CRUST)   # join scallops to the wall
    for i in range(1, n):   # flute grooves, converging slightly towards the base
        xt = XT0 + step * i; xb = XB0 + (XB1 - XB0) * i / n
        p.line([(xt, TOP_Y + 4), (xb, BASE_Y - 13)], fill=CRUST_D, width=5 if crimp else 6)

def ball(p, x, y, r, fill, w=5, hl=(255, 255, 255, 120)):
    p.circle(x, y, r, fill=fill, outline=OC, width=w)
    p.ellipse([x - r * 0.55, y - r * 0.6, x - r * 0.05, y - r * 0.15], fill=hl)

def lemon_side():
    p = Pen()
    X, Y, r = 150, 104, 40     # lemon slice standing in the curd (same slice as the top view)
    p.ellipse([92, 76, 134, 100], fill=rgb(SAGE), outline=OC, width=5)   # leaf
    p.circle(X, Y, r, fill=rgb("#FFF3B8"), outline=OC, width=7)
    p.circle(X, Y, r - 7, fill=rgb("#FFF3B8"), outline=rgb("#D9B52E"), width=6)
    for k in range(8):
        a = k * math.pi / 4 + 0.2; p.line([(X, Y), (X + math.cos(a) * (r - 13), Y + math.sin(a) * (r - 13))], fill=rgb("#E8C640"), width=4)
    dome(p, rgb("#F6D453"), 40)
    for x, y0, y1 in ((108, 116, 132), (126, 118, 126), (176, 122, 134), (194, 128, 136)):
        p.line([(x, y0), (x, y1)], fill=rgb("#FFFDF5"), width=8)   # drizzle
    p.ellipse([56, 122, 86, 132], fill=HL)
    crust_wall(p, flutes=9)
    return p.done()

def apricot_side():
    p = Pen(); ap = rgb("#EE8A2E")
    for x in (92, 164): ball(p, x, 108, 27, ap, hl=(255, 236, 200, 170))   # back row
    ball(p, 128, 96, 27, ap, hl=(255, 236, 200, 170))
    dome(p, rgb("#F7CB7A"), 22)
    for x in (62, 128, 194): ball(p, x, 128, 27, ap, hl=(255, 236, 200, 170))   # front row
    ball(p, 95, 132, 25, ap, hl=(255, 236, 200, 170)); ball(p, 161, 132, 25, ap, hl=(255, 236, 200, 170))
    crust_wall(p, flutes=9)
    return p.done()

def berry_side():
    p = Pen(); be = rgb("#B83A5E")
    ball(p, 128, 70, 25, be)                                   # top of the pile
    for x in (100, 156): ball(p, x, 100, 25, be)
    dome(p, rgb(RASP), 24)
    for x in (64, 128, 192): ball(p, x, 128, 25, be)
    for x in (96, 160): ball(p, x, 132, 24, be)
    crust_wall(p, flutes=9)
    return p.done()

def custard_side():
    p = Pen()
    dome(p, rgb("#EDBE5E"), 58, inset=12)
    g = Image.new("RGBA", p.im.size, (0, 0, 0, 0)); gd = ImageDraw.Draw(g)   # baked golden-brown crown
    gd.chord([62 * SS, 92 * SS, 194 * SS, 190 * SS], 180, 360, fill=rgb("#C98A3A", 170))
    m = Image.new("L", p.im.size, 0); ImageDraw.Draw(m).chord([(XT0 + 19) * SS, (TOP_Y - 51) * SS, (XT1 - 19) * SS, (TOP_Y + 51) * SS], 180, 360, fill=255)
    g = g.filter(ImageFilter.GaussianBlur(9 * SS)); g.putalpha(Image.fromarray(np.minimum(np.array(g.split()[3]), np.array(m)))); p.layer(g)
    rng = np.random.default_rng(9)
    for _ in range(60):   # nutmeg / crumb specks, as on the top view
        a = rng.uniform(math.pi, 2 * math.pi); t = rng.uniform(0, 1) ** 0.6; s = rng.uniform(2.5, 4.5)
        x = 128 + 74 * t * math.cos(a); y = TOP_Y - 10 + 36 * t * math.sin(a)
        p.circle(x, y, s, fill=rgb("#7A4A26", 210))
    p.ellipse([72, 108, 104, 120], fill=HL)
    crust_wall(p, flutes=9, crimp=True)
    return p.done()

def chocolate_side():
    p = Pen(); choc = rgb("#5A3230")
    dome(p, choc, 60, inset=12)                                  # glossy ganache dome
    p.ellipse([60, 106, 104, 122], fill=(255, 255, 255, 70))
    for x, y0, y1 in ((52, 140, 158), (84, 144, 170), (150, 144, 164), (196, 140, 172)):   # ganache drips over the rim
        p.line([(x, y0), (x, y1)], fill=OC, width=22); p.line([(x, y0), (x, y1)], fill=choc, width=12)
    bx, by, br = 136, 82, 24                                     # raspberry + gold leaf, as on the top view
    p.poly([(96, 98), (116, 84), (112, 108)], fill=rgb("#E7C46A"), outline=OC, width=4)
    p.circle(bx, by, br, fill=rgb("#C2335A"), outline=OC, width=5)
    for k in range(5):
        a = k * 2 * math.pi / 5 - 0.3; p.circle(bx + math.cos(a) * 11, by + math.sin(a) * 11, 6, fill=rgb("#E0607F"))
    p.circle(bx, by, 5, fill=rgb("#E0607F"))
    crust_wall(p, flutes=9)
    for x, y0, y1 in ((52, 150, 158), (84, 150, 170), (150, 150, 164), (196, 150, 172)):   # drips sit in front of the crust
        p.line([(x, y0), (x, y1)], fill=OC, width=22); p.line([(x, y0 - 6), (x, y1)], fill=choc, width=12)
    return p.done()

def bakewell_side():
    p = Pen()
    p.line([(134, 66), (158, 26)], fill=OC, width=12); p.line([(134, 66), (158, 26)], fill=rgb(SAGE), width=7)   # stem
    ice = rgb("#FFFFFF")
    p.chord([XT0 + 10, TOP_Y - 44, XT1 - 10, TOP_Y + 40], 180, 360, fill=ice, outline=OC, width=7)   # domed white icing
    pts = [(56 + k * 4, 136 + 7 * math.sin(k / 5.0)) for k in range(37)]
    p.line(pts, fill=rgb("#D9839A"), width=7)                    # the feather line
    p.ellipse([70, 116, 100, 126], fill=rgb("#E6DCD0"))
    ball(p, 128, 92, 34, rgb("#C21D3A"), w=7, hl=(255, 255, 255, 170))   # glacé cherry
    crust_wall(p, plain=True)
    return p.done()


# ---------------------------------------------------------------- top views
def scone_top():
    p = Pen(); cx = cy = 128
    rng = np.random.default_rng(3); n = 96; off = rng.normal(0, 1, n)
    off = np.convolve(np.concatenate([off, off, off]), np.ones(17) / 17, "same")[n:2 * n] * 14   # hand-shaped, slightly lumpy edge
    ring = lambda R, f=1.0: [(cx + (R + off[i] * f) * math.cos(2 * math.pi * i / n), cy + (R + off[i] * f) * math.sin(2 * math.pi * i / n)) for i in range(n)]
    p.poly(ring(104), fill=OC); p.poly(ring(94), fill=rgb("#E7B36E"))
    p.poly(ring(80, 0.7), fill=OC); p.poly(ring(73, 0.7), fill=rgb("#D99A52"))       # golden baked top
    p.arc([cx - 62, cy - 62, cx + 62, cy + 62], 200, 250, fill=rgb("#E7B36E"), width=6)
    blob = [(cx + (50 + 5 * math.cos(5 * a + 0.6)) * math.cos(a), cy + (50 + 5 * math.cos(5 * a + 0.6)) * math.sin(a)) for a in (2 * math.pi * i / 80 for i in range(80))]
    p.poly([(cx + (x - cx) * 1.13, cy + (y - cy) * 1.13) for x, y in blob], fill=OC); p.poly(blob, fill=CREAMY)              # clotted-cream dollop
    p.circle(cx, cy, 27, fill=rgb("#B5243F"), outline=OC, width=6)   # cherry / jam
    p.ellipse([cx - 16, cy - 18, cx - 2, cy - 7], fill=HL)
    return p.done()

def victoria_top():
    p = Pen(); cx = cy = 128; R = 104
    p.circle(cx, cy, R, fill=rgb("#F2CF87"), outline=OC, width=OW)          # sponge edge
    p.circle(cx, cy, R - 16, fill=rgb("#FDF7EC"))                           # sugar-dusted top
    sp = [(cx + (10 + 62 * t) * math.cos(t * 4.6 * math.pi), cy + (10 + 62 * t) * math.sin(t * 4.6 * math.pi)) for t in (i / 160 for i in range(161))]
    p.line(sp, fill=rgb(RASP), width=7)                                     # jam spiral
    a0, a1 = math.radians(-78), math.radians(-28)                           # slice cut out (upper right)
    for k in range(7):                                                      # strawberries round the edge, one per slice
        a = math.radians(-53 + k * 360 / 7)
        if k == 0: continue
        x, y = cx + 68 * math.cos(a), cy + 68 * math.sin(a)
        p.circle(x, y, 17, fill=rgb("#D8344F"), outline=OC, width=5)
        p.poly([(x - 8, y - 5), (x, y - 13), (x + 8, y - 5), (x, y - 1)], fill=rgb(SAGE))
    im = p.im; far = 150 * SS
    wedge = [(cx * SS, cy * SS)] + [(cx * SS + far * math.cos(a0 + (a1 - a0) * i / 12), cy * SS + far * math.sin(a0 + (a1 - a0) * i / 12)) for i in range(13)]
    hole = Image.new("L", im.size, 0); ImageDraw.Draw(hole).polygon(wedge, fill=255)
    im.putalpha(Image.fromarray(np.where(np.array(hole) > 0, 0, np.array(im.split()[3])).astype(np.uint8)))
    p.d = ImageDraw.Draw(im)
    for a in (a0, a1):                                                      # cut faces: cream + jam line, inked
        ex, ey = cx + (R - 4) * math.cos(a), cy + (R - 4) * math.sin(a)
        p.line([(cx, cy), (ex, ey)], fill=OC, width=OW)
    return p.done()

def macaron_top():
    p = Pen(); cx = cy = 128; shell = rgb("#EC93AA"); foot = shade("#EC93AA", 0.80)
    p.poly(fluted_pts(cx, cy, 106, 22, 7), fill=foot, outline=OC, width=OW)   # ruffled foot peeking round the shell
    p.circle(cx, cy, 88, fill=shell, outline=OC, width=7)                     # smooth dome shell
    p.arc([cx - 70, cy - 70, cx + 70, cy + 70], 20, 80, fill=shade("#EC93AA", 0.90), width=7)
    p.ellipse([cx - 58, cy - 62, cx - 14, cy - 40], fill=HL)
    return p.done()


NEW = {"scone": ("top", scone_top), "victoria": ("top", victoria_top), "lemon": ("side", lemon_side), "apricot": ("side", apricot_side),
       "bakewell": ("side", bakewell_side), "berry": ("side", berry_side), "custard": ("side", custard_side), "chocolate": ("side", chocolate_side), "macaron": ("top", macaron_top)}

IMPORT_TMPL = open(os.path.join(OUT, "cake_scone.png.import")).read()
def write_import(name):
    """Sidecar with Art's sprite import params (lossless, mipmaps, fix alpha border); keeps an existing uid."""
    path = os.path.join(OUT, name + ".import")
    if os.path.exists(path): return
    rnd = random.Random(name); uid = "".join(rnd.choice("abcdefghijklmnopqrstuvwxy012345678") for _ in range(13))
    h = hashlib.md5(f"res://assets/board/{name}".encode()).hexdigest()
    s = IMPORT_TMPL.replace("uid://dfn2gqbttem3e", "uid://" + uid).replace("cake_scone.png-1e702bf462dee56a9d143100f1565204", f"{name}-{h}").replace("cake_scone.png", name)
    open(path, "w").write(s)

def main():
    written = []
    for k, (view, fn) in NEW.items():
        art = _finish(fn())
        for suf, S in (("", 128), ("@2x", 256)):
            n = f"cake_{k}_{view}{suf}.png"; art.resize((S, S), Image.LANCZOS).save(os.path.join(OUT, n), optimize=True); written.append(n)
            n2 = f"cake_{k}_{LEGACY[k]}{suf}.png"; shutil.copyfile(os.path.join(OUT, f"cake_{k}{suf}.png"), os.path.join(OUT, n2)); written.append(n2)
    for n in written: write_import(n)
    print(len(written), "files", sum(os.path.getsize(os.path.join(OUT, n)) for n in written), "bytes")
    if len(sys.argv) > 1:   # preview sheet (not shipped): top row = top views, bottom row = side views on a plate line
        ks = list(NEW); W = 20 + 276 * len(ks); sheet = Image.new("RGBA", (W, 600), rgb("#F6E3DE"))
        d = ImageDraw.Draw(sheet); d.rounded_rectangle([10, 547, W - 10, 559], radius=6, fill=rgb("#FFFDF8"), outline=OC, width=3)
        for i, k in enumerate(ks):
            for j, v in enumerate(("top", "side")):
                c = Image.open(os.path.join(OUT, f"cake_{k}_{v}@2x.png")).convert("RGBA"); sheet.alpha_composite(c, (20 + i * 276, 20 + j * 296))
        sheet.convert("RGB").save(sys.argv[1])

if __name__ == "__main__": main()
