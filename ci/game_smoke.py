#!/usr/bin/env python3
"""tea-bakery game smoke on a served DEBUG build (Playwright + system Chrome).
usage: game_smoke.py <base_url> <out_dir>
Checks: board 1 = tutorial (givens, target); b1 -> b2 <= 2 s; hints ch1 free / ch2 rewarded; chapter ends + AD-17 at the
real slot; save/reload; Home + Recipe Book; gameplayStart fired; phone cap 8x8 / desktop 9x9; real touch taps cycle empty->X->cake;
conflict highlight; PKD_QA.show('solve') -> won; ?seed=&size= deterministic across reloads; 0 console errors."""
import json, os, re, sys
from playwright.sync_api import sync_playwright
base, out = sys.argv[1].rstrip("/"), sys.argv[2]; os.makedirs(out, exist_ok=True)
HERE = os.path.dirname(os.path.abspath(__file__))
allow = [re.compile(l.strip()) for l in open(os.path.join(HERE, "console_allowlist.txt")) if l.strip() and not l.startswith("#")]
res, bad, notes = {}, [], {}
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
    show = lambda pg, c: pg.evaluate(f"(() => {{ window.__pkdShow = null; window.PKD_QA.show({json.dumps(c)}); return window.__pkdShow; }})()")
    pg = boot(ctx, "qa=1&intro=0"); d = dump(pg); g = d["game"]
    res["phone_tutorial_board1"] = g["tutorial"] is True and g["n"] == 5 and g["board_id"] == "c1-b1" and g["screen"] == "board"
    res["tutorial_givens_and_target"] = len(g["givens"]) >= 3 and len(g["targets"]) == 1 and g["coach"] != ""
    res["phone_gameplay_started"] = g["gameplay_started"] is True and any("gameplayStart" in h for h in d["hitlog"])
    res["phone_max_size_8"] = g["max_size"] == 8
    gx, gy = g["givens"][0]; pg.touchscreen.tap(*cell_xy(g, gx, gy)); pg.wait_for_timeout(300)
    res["given_cake_immutable"] = dump(pg)["game"]["cells"][gx * 5 + gy] == "cake"
    pg.screenshot(path=f"{out}/game_phone_tutorial.png")
    # real taps on the tutorial target: mold, cake -> solved card -> c1-b2 interactive <= 2.0 s
    tr, tc = g["targets"][0]
    for _ in range(2): pg.touchscreen.tap(*cell_xy(g, tr, tc)); pg.wait_for_timeout(150)
    t0 = pg.evaluate("performance.now()"); gs = dump(pg)["game"]
    res["b1_solved_card_steam"] = gs["won"] is True and gs["card_open"] is True and gs["baking"] is True
    pg.screenshot(path=f"{out}/game_phone_baked.png")
    pg.wait_for_function("() => { const g = JSON.parse(window.PKD_QA.dump()).game; return g.board_id == 'c1-b2' && g.interactive }", timeout=10000)
    dt = pg.evaluate("performance.now()") - t0; notes["b1_to_b2_ms"] = dt
    gb = dump(pg)["game"]
    notes["b1_to_b2_engine_ms"] = gb["t_interactive_ms"] - gs["t_solved_ms"]
    res["b1_to_b2_interactive_le_2s"] = 0 < gb["t_interactive_ms"] - gs["t_solved_ms"] <= 2000   # engine clock: solve -> next board interactive
    res["progress_dot_1_on"] = gb["dots_on"] == 1 and "c1-b1" in gb["progress"]["solved"]
    res["save_immediate_on_solve"] = any(w["reason"] == "solve" for w in gb["save_writes"])
    # free-board tap cycle + conflict shake (generated board, no givens)
    show(pg, "gen:5,11"); pg.wait_for_timeout(300); g = dump(pg)["game"]
    x, y = cell_xy(g, 0, 0)
    pg.touchscreen.tap(x, y); pg.wait_for_timeout(400); g1 = dump(pg)["game"]
    res["tap1_sets_mold"] = g1["molds"] == [[0, 0]] and g1["cakes"] == [] and g1["cells"][0] == "mold"
    pg.touchscreen.tap(x, y); pg.wait_for_timeout(400); g2 = dump(pg)["game"]
    res["tap2_places_cake"] = g2["cakes"] == [[0, 0]] and g2["molds"] == []
    x2, y2 = cell_xy(g, 1, 1)
    for _ in range(2): pg.touchscreen.tap(x2, y2); pg.wait_for_timeout(400)
    g3 = dump(pg)["game"]
    res["conflict_highlight_diagonal"] = sorted(g3["conflicts"]) == [[0, 0], [1, 1]]
    res["conflict_shake_started"] = g3["shakes_started"] >= 1
    pg.screenshot(path=f"{out}/game_phone_conflict.png")
    show(pg, "undo"); pg.wait_for_timeout(200)
    res["undo_works"] = len(dump(pg)["game"]["cakes"]) == 1
    show(pg, "solve"); pg.wait_for_timeout(400); g4 = dump(pg)["game"]
    res["solve_wins"] = g4["won"] is True and g4["conflicts"] == []
    show(pg, "undo"); res["undo_blocked_after_solve"] = dump(pg)["game"]["won"] is True
    pg.screenshot(path=f"{out}/game_phone_won.png")
    # ch1 hint: unlimited free
    show(pg, "board:c1-b4"); pg.wait_for_timeout(300)
    h1 = show(pg, "hint"); h2 = show(pg, "hint"); gh = dump(pg)["game"]; notes["hint_c1"] = [h1, h2]
    res["hint_ch1_free_unlimited"] = gh["hint"]["text"] != "" and gh["hint_offer"] == "free" and len(gh["targets"]) >= 1 and h2 != "rewarded modal"
    res["hint_text_rules"] = all(len(h) <= 140 and h.count(".") + h.count("!") + h.count("?") == 1 and not re.search(r"T[1-7]|technique|region|candidate", h, re.I) for h in [h1, h2])
    pg.screenshot(path=f"{out}/game_phone_hint.png")
    # finish chapter 1 -> chapter end (recipe card, décor, happytime); AD-17 floor edge at the REAL chapter-end slot
    for b in range(1, 6):
        show(pg, f"board:c1-b{b}"); show(pg, "solve"); pg.wait_for_timeout(100)
        if b < 5: show(pg, "skip")
    show(pg, "skip"); pg.wait_for_timeout(500); ge = dump(pg)["game"]
    res["chapter_end_screen"] = ge["screen"] == "chapter_end" and ge["unlocked"]["recipes"] == [1] and len(ge["unlocked"]["decor"]) == 1
    res["happytime_on_chapter_end"] = any("happytime" in json.dumps(e) for e in ge["sdk_log"])
    res["save_on_chapter_end"] = any(w["reason"] == "chapter_end" for w in ge["save_writes"])
    res["portrait_backdrop_chapter_end"] = ge["backdrop"] is True
    pg.screenshot(path=f"{out}/game_phone_chapter_end.png")
    pg.evaluate("window.PKD_QA.set_session_s(299)"); show(pg, "end_next"); pg.wait_for_timeout(800)
    d = dump(pg); dec = d["ads_decisions"]; notes["ads_decisions_c1"] = dec
    res["ad17_299_denied_real_chapter_end"] = len(dec) == 1 and dec[0]["reason"] == "session_s<300" and dec[0]["origin"] == "chapter_end"
    res["next_chapter_opens_c2b1"] = d["game"]["board_id"] == "c2-b1" and d["game"]["screen"] == "board"
    # ch2 hints: 1 free, then rewarded confirm (mock ads available)
    pg.close(); pg = boot(ctx, "qa=1&intro=0&ads=mock_available"); g = dump(pg)["game"]
    res["boot_routes_next_unsolved"] = g["board_id"] == "c2-b1"
    show(pg, "hint"); r2 = show(pg, "hint"); notes["hint_c2"] = r2
    res["hint_ch2_second_is_rewarded"] = r2 == "rewarded modal"
    pg.screenshot(path=f"{out}/game_phone_rewarded_modal.png")
    show(pg, "hint_watch"); pg.wait_for_timeout(1500); gw = dump(pg)["game"]
    res["hint_rewarded_granted_after_ad"] = gw["hint"]["kind"] == "rewarded" and any(e.get("kind") == "rewarded" for e in gw["ads_log"] if isinstance(e, dict))
    # save + reload restores marks on the same board (debounced write)
    show(pg, "board:c2-b2"); pg.wait_for_timeout(200); g = dump(pg)["game"]
    free = next([r, c] for r in range(g["n"]) for c in range(g["n"]) if [r, c] not in g["givens"])
    show(pg, f"tap:{free[0]},{free[1]}"); pg.wait_for_timeout(2500)
    res["save_debounced_write"] = any(w["reason"] == "debounce" for w in dump(pg)["game"]["save_writes"])
    pg.close(); pg = boot(ctx, "qa=1&intro=0&ads=mock_available"); g = dump(pg)["game"]
    res["reload_restores_saved_board"] = g["board_id"] == "c2-b2" and g["cells"][free[0] * g["n"] + free[1]] == "mold"
    # AD-17 at REAL chapter ends: ch2 end at session 300 s -> ok (mock ad shown) -> Next -> ch3; ch3 end at 479 s
    # (179 s after the ch2 request) -> gap<180s denied -> Next -> ch4; ch4 end at 480 s (180 s gap) -> ok -> Home.
    def finish(ch):
        for b in range(1, 6):
            show(pg, f"board:c{ch}-b{b}"); show(pg, "solve"); pg.wait_for_timeout(100)
            if b < 5: show(pg, "skip")
        show(pg, "skip"); pg.wait_for_timeout(500); return dump(pg)["game"]
    ge = finish(2)
    res["chapter2_end_has_next"] = ge["screen"] == "chapter_end" and ge["unlocked"]["recipes"] == [1, 2] and next(u for u in ge["ui"] if u["name"] == "EndNext")["visible"]
    pg.evaluate("window.PKD_QA.set_session_s(300)"); show(pg, "end_next"); pg.wait_for_timeout(1500)
    d = dump(pg); dec = d["ads_decisions"]; notes["ads_decisions_c2"] = dec
    res["ad17_300_ok_real_chapter2_end"] = bool(dec) and dec[-1]["reason"] == "ok" and dec[-1]["origin"] == "chapter_end"
    res["next_chapter_opens_c3b1"] = d["game"]["board_id"] == "c3-b1" and d["game"]["screen"] == "board"
    ge = finish(3)
    res["chapter3_end_screen"] = ge["screen"] == "chapter_end" and ge["unlocked"]["recipes"] == [1, 2, 3]
    pg.screenshot(path=f"{out}/game_phone_chapter3_end.png")
    pg.evaluate("window.PKD_QA.set_session_s(479)"); show(pg, "end_next"); pg.wait_for_timeout(1000)
    d = dump(pg); dec = d["ads_decisions"]; notes["ads_decisions_c3"] = dec[-1:]
    res["ad17_179_gap_denied_real_chapter3_end"] = dec[-1]["reason"] == "gap<180s" and dec[-1]["origin"] == "chapter_end" and not dec[-1]["allowed"]
    res["next_chapter_opens_c4b1"] = d["game"]["board_id"] == "c4-b1"
    ge = finish(4)
    pg.evaluate("window.PKD_QA.set_session_s(480)"); show(pg, "end_home"); pg.wait_for_timeout(1500)
    d = dump(pg); dec = d["ads_decisions"]; notes["ads_decisions_c4"] = dec[-1:]
    res["ad17_180_gap_ok_real_chapter4_end"] = dec[-1]["reason"] == "ok" and dec[-1]["origin"] == "chapter_end" and dec[-1]["allowed"]
    res["home_after_chapter_end"] = d["game"]["screen"] == "home"
    hd = next(u for u in d["game"]["ui"] if u["name"] == "HomeDaily")
    res["home_daily_unlocked_after_c1"] = hd["enabled"] is True
    pg.screenshot(path=f"{out}/game_phone_home.png")
    show(pg, "recipe_book"); pg.wait_for_timeout(400); gb = dump(pg)["game"]
    res["recipe_book_screen"] = gb["screen"] == "recipe_book" and gb["backdrop"] is True
    pg.screenshot(path=f"{out}/game_phone_recipe_book.png")
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
    res["desktop_backdrop_landscape"] = g["backdrop_asset"] is True and g["backdrop"] is True   # Art P2 landscape webp on desktop
    pg.screenshot(path=f"{out}/game_desktop_9x9.png"); pg.close(); ctx.close()
    br.close()
res["console_zero"] = not bad
json.dump({"checks": res, "console_bad": bad, "notes": notes}, open(f"{out}/game_smoke.json", "w"), indent=1)
for k, v in res.items(): print(("PASS " if v else "FAIL ") + k)
for b in bad[:5]: print("  console:", b)
sys.exit(0 if all(res.values()) else 1)
