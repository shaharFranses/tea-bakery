#!/usr/bin/env python3
"""Responsive layout gate (D0-12 / QA Day-0 blocker): on a served DEBUG build, at 390x844 (phone, dpr 2, touch),
800x450 (CrazyGames embed) and 1280x720, every visible Button must be >= 44x44 CSS px, every visible Label/Button font
>= 12 CSS px, all inside the viewport, buttons not overlapping each other or the board, board cells >= 44 CSS px.
Screenshots -> <shots_dir>/layout_<w>x<h>.png. usage: layout_smoke.py <base_url> <out_dir> [shots_dir]"""
import json, os, sys
from playwright.sync_api import sync_playwright
base, out = sys.argv[1].rstrip("/"), sys.argv[2]; shots = sys.argv[3] if len(sys.argv) > 3 else out
os.makedirs(out, exist_ok=True); os.makedirs(shots, exist_ok=True)
CASES = [((390, 844), dict(device_scale_factor=2, has_touch=True, is_mobile=True), "portrait", 8),
         ((800, 450), {}, "wide", 9), ((1280, 720), {}, "wide", 9)]
res, fails = {}, []
def ov(a, b): return a[0] < b[0] + b[2] - 0.5 and b[0] < a[0] + a[2] - 0.5 and a[1] < b[1] + b[3] - 0.5 and b[1] < a[1] + a[3] - 0.5
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=os.environ.get("PKD_CHROME", "/usr/bin/google-chrome"), headless=True,
                           args=["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"])
    for (w, h), extra, want_mode, size in CASES:
        ctx = br.new_context(viewport={"width": w, "height": h}, **extra); pg = ctx.new_page()
        pg.goto(f"{base}/index.html?qa=1&intro=0&seed=7&size={size}")
        pg.wait_for_function("() => window.PKD_QA && JSON.parse(window.PKD_QA.dump()).game && JSON.parse(window.PKD_QA.dump()).game.intro_done", timeout=90000)
        pg.wait_for_timeout(600)
        for scr in ["board", "home", "recipe_book", "chapter_end", "all_baked", "chapter_list", "settings"]:
            if scr == "settings":
                pg.evaluate("window.PKD_QA.show('home')"); pg.evaluate("window.PKD_QA.show('settings')"); pg.wait_for_timeout(500)
            elif scr != "board":
                pg.evaluate(f"window.PKD_QA.show({json.dumps('chapter_end_screen:1' if scr == 'chapter_end' else scr)})"); pg.wait_for_timeout(500)
            g = json.loads(pg.evaluate("window.PKD_QA.dump()"))["game"]
            tag = f"{w}x{h}" + ("" if scr == "board" else "_" + scr); f = []
            if scr == "settings": scr_want = "home"
            else: scr_want = scr
            if g.get("screen") != scr_want: f.append(f"screen {g.get('screen')} != {scr_want}")
            if g.get("layout") != want_mode: f.append(f"layout {g.get('layout')} != {want_mode}")
            vis = [u for u in g["ui"] if u["visible"] and not u.get("scrolled_out")]
            if scr == "settings":   # the modal only (Home sits under the scrim)
                vis = [u for u in vis if u["name"] in ("SettingsTitle", "Sound", "Music", "TapOrder", "AutoMolds", "ResetProgress", "SettingsClose")]
                if len(vis) != 7: f.append(f"settings shows {sorted(u['name'] for u in vis)}")
            btns = [u for u in vis if u["type"] in ("Button", "CheckButton", "TextureButton")]
            for u in vis:
                x, y, uw, uh = u["rect"]
                if u["font"] < 12 - 0.01: f.append(f"{u['name']} font {u['font']:.1f} < 12")
                if x < -0.5 or y < -0.5 or x + uw > w + 0.5 or y + uh > h + 0.5: f.append(f"{u['name']} outside viewport {u['rect']}")
            for u in btns:
                if u["rect"][2] < 44 - 0.01 or u["rect"][3] < 44 - 0.01: f.append(f"{u['name']} {u['rect'][2]:.0f}x{u['rect'][3]:.0f} < 44")
                if scr == "board" and ov(u["rect"], g["board_rect"]): f.append(f"{u['name']} overlaps board")
            for i, a in enumerate(btns):
                for b in btns[i + 1:]:
                    if ov(a["rect"], b["rect"]): f.append(f"{a['name']} overlaps {b['name']}")
            cell = g["board_rect"][2] / g["n"]
            if scr == "board" and cell < 44 - 0.01: f.append(f"cell {cell:.1f} < 44 (n={g['n']})")
            if scr == "board" and want_mode == "portrait":     # SPEC v1.0.2 D-02 on phones
                if g.get("rules_lines", 9) > 3: f.append(f"D-02 rules text {g.get('rules_lines')} lines > 3")
                if g.get("rules_font_css", 0) < 16 - 0.01: f.append(f"D-02 rules font {g.get('rules_font_css')} < 16")
                if g["board_rect"][2] < 352 - 0.01: f.append(f"D-02 board {g['board_rect'][2]:.1f} < 352")
                if g.get("too_small"): f.append("too_small at 390x844")
            res[tag] = {"pass": not f, "fails": f, "layout": g.get("layout"), "css_per_unit": g.get("css_per_unit"), "n": g["n"],
                        "cell_css": round(cell, 1), "board_rect": [round(v, 1) for v in g["board_rect"]],
                        "min_button": [round(min(u["rect"][2] for u in btns), 1), round(min(u["rect"][3] for u in btns), 1)] if btns else None,
                        "min_font": round(min(u["font"] for u in vis), 1),
                        "elements": [{"name": u["name"], "rect": [round(v, 1) for v in u["rect"]], "font": round(u["font"], 1)} for u in vis]}
            pg.screenshot(path=f"{shots}/layout_{tag}.png")
            print(f"{'PASS' if not f else 'FAIL'} {tag}: layout={g.get('layout')} n={g['n']} cell={cell:.1f} min_btn={res[tag]['min_button']} min_font={res[tag]['min_font']}")
            for x in f: print("   ", x)
            fails += f
        if want_mode == "portrait":   # TT-AC-48: 8x8 at 700x360 -> cover within 500 ms; back to 390x844 -> gone within 500 ms
            pg.evaluate("window.PKD_QA.show('board:c6-b2')"); pg.wait_for_timeout(400)
            ts = {}
            for vw, vh, want in [(700, 360, True), (390, 844, False)]:
                pg.set_viewport_size({"width": vw, "height": vh}); pg.wait_for_timeout(500)
                g = json.loads(pg.evaluate("window.PKD_QA.dump()"))["game"]
                ts[f"{vw}x{vh}"] = {"too_small": g.get("too_small"), "n": g["n"], "cell_css": round(g["board_rect"][2] / g["n"], 1)}
                if want: pg.screenshot(path=f"{shots}/layout_too_small_700x360.png")
                if g.get("too_small") != want: fails.append(f"TT-AC-48 {vw}x{vh} too_small={g.get('too_small')} want {want}")
            res["too_small"] = ts; print("too_small:", ts)
        ctx.close()
    br.close()
json.dump(res, open(f"{out}/layout_smoke.json", "w"), indent=1)
sys.exit(1 if fails else 0)
