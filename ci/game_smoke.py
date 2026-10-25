#!/usr/bin/env python3
"""tea-bakery game smoke on a served DEBUG build (Playwright + system Chrome).
usage: game_smoke.py <base_url> <out_dir>
Checks: board 1 = tutorial; gameplayStart fired; phone cap 8x8 / desktop 9x9; real touch taps cycle empty->X->cake;
conflict highlight; PKD_QA.show('solve') -> won; ?seed=&size= deterministic across reloads; 0 console errors."""
import json, os, re, sys
from playwright.sync_api import sync_playwright
base, out = sys.argv[1].rstrip("/"), sys.argv[2]; os.makedirs(out, exist_ok=True)
HERE = os.path.dirname(os.path.abspath(__file__))
allow = [re.compile(l.strip()) for l in open(os.path.join(HERE, "console_allowlist.txt")) if l.strip() and not l.startswith("#")]
res, bad = {}, []
def dump(pg):
    return json.loads(pg.evaluate("window.PKD_QA.dump()"))
def boot(ctx, q):
    pg = ctx.new_page()
    pg.on("console", lambda m: bad.append(f"{m.type}: {m.text}") if m.type in ("error", "warning") and not any(a.search(m.text) for a in allow) else None)
    pg.on("pageerror", lambda e: bad.append(f"pageerror: {e}"))
    pg.goto(f"{base}/index.html?{q}")
    pg.wait_for_function("() => window.PKD_QA && window.__pkdDump && JSON.parse(window.PKD_QA.dump()).game && JSON.parse(window.PKD_QA.dump()).game.intro_done", timeout=60000)
    pg.wait_for_timeout(300)
    return pg
def cell_xy(g, r, c):
    x, y, w, h = g["board_rect"]; n = g["n"]; vw = g.get("_vw", None)
    return x + (c + 0.5) * w / n, y + (r + 0.5) * h / n
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=os.environ.get("PKD_CHROME", "/usr/bin/google-chrome"), headless=True,
                           args=["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"])
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, has_touch=True, is_mobile=True)
    pg = boot(ctx, "qa=1&intro=0"); d = dump(pg); g = d["game"]
    res["phone_tutorial_board1"] = g["tutorial"] is True and g["n"] == 5
    res["phone_gameplay_started"] = g["gameplay_started"] is True and any("gameplayStart" in h for h in d["hitlog"])
    res["phone_max_size_8"] = g["max_size"] == 8
    # canvas px == CSS px at the 390 base (canvas_items/expand, 390 wide)
    x, y = cell_xy(g, 0, 0)
    pg.touchscreen.tap(x, y); pg.wait_for_timeout(400); g1 = dump(pg)["game"]
    res["tap1_marks_X"] = g1["marks"] == [[0, 0]] and g1["cakes"] == []
    pg.touchscreen.tap(x, y); pg.wait_for_timeout(400); g2 = dump(pg)["game"]
    res["tap2_places_cake"] = g2["cakes"] == [[0, 0]] and g2["marks"] == []
    x2, y2 = cell_xy(g, 1, 1)
    for _ in range(2): pg.touchscreen.tap(x2, y2); pg.wait_for_timeout(400)
    g3 = dump(pg)["game"]
    res["conflict_highlight_diagonal"] = sorted(g3["conflicts"]) == [[0, 0], [1, 1]]
    pg.screenshot(path=f"{out}/game_phone_conflict.png")
    pg.evaluate("window.PKD_QA.show('solve')"); pg.wait_for_timeout(400); g4 = dump(pg)["game"]
    res["solve_wins"] = g4["won"] is True and g4["conflicts"] == []
    pg.screenshot(path=f"{out}/game_phone_won.png")
    pg.close()
    regs = []
    for _ in range(2):
        pg = boot(ctx, "qa=1&intro=0&seed=424242&size=8"); g = dump(pg)["game"]; regs.append((g["n"], g["seed"], g["regions"])); pg.close()
    res["seed_deterministic_8x8"] = regs[0] == regs[1] and regs[0][0] == 8 and regs[0][1] == 424242
    pg = boot(ctx, "qa=1&intro=0&seed=1&size=9"); g = dump(pg)["game"]
    res["phone_9x9_request_capped_to_8"] = g["n"] == 8; pg.close(); ctx.close()
    ctx = br.new_context(viewport={"width": 1280, "height": 800})
    pg = boot(ctx, "qa=1&intro=0&seed=7&size=9"); g = dump(pg)["game"]
    res["desktop_9x9_allowed"] = g["n"] == 9 and g["max_size"] == 9
    res["desktop_cells_ge_44"] = g["board_rect"][2] / g["n"] >= 44
    res["desktop_backdrop_placeholder"] = g["backdrop_asset"] is False   # no ART asset yet: flat fill shown
    pg.screenshot(path=f"{out}/game_desktop_9x9.png"); pg.close(); ctx.close()
    br.close()
res["console_zero"] = not bad
json.dump({"checks": res, "console_bad": bad}, open(f"{out}/game_smoke.json", "w"), indent=1)
for k, v in res.items(): print(("PASS " if v else "FAIL ") + k)
for b in bad[:5]: print("  console:", b)
sys.exit(0 if all(res.values()) else 1)
