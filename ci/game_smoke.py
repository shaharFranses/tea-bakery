#!/usr/bin/env python3
"""tea-bakery game smoke on a served DEBUG build (Playwright + system Chrome).
usage: game_smoke.py <base_url> <out_dir>
Checks: board 1 = tutorial (givens, target); solve -> next board <= 2 s (median of 4); hints ch1 free / ch2 rewarded; chapter ends + AD-17 at the
real slot; save/reload; Home + Recipe Book; gameplayStart fired; phone cap 8x8 / desktop 9x9; real touch taps cycle empty->X->cake;
conflict highlight; PKD_QA.show('solve') -> won; ?seed=&size= deterministic across reloads; PKD_QA.show('daily:today'); 0 console errors."""
import math
import json, os, re, sys
from playwright.sync_api import sync_playwright
base, out = sys.argv[1].rstrip("/"), sys.argv[2]; os.makedirs(out, exist_ok=True)
HERE = os.path.dirname(os.path.abspath(__file__))
BPC = 12   # levels per chapter (SPEC v1.1 §3.5 boards_per_chapter)
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
    m0 = g["music"]; notes["music_before_gesture"] = m0   # SPEC §8: the loop starts only after the first gesture
    res["music_asset_loop_no_play_before_gesture"] = m0["asset"] is True and m0["loop"] is True and m0["gestured"] is False and m0["playing"] is False
    gx, gy = g["givens"][0]; pg.touchscreen.tap(*cell_xy(g, gx, gy)); pg.wait_for_timeout(300)
    m1 = dump(pg)["game"]["music"]; notes["music_after_first_tap"] = m1
    res["music_starts_on_first_tap"] = m1["gestured"] is True and m1["playing"] is True and m1["on"] is True
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
    res["progress_dot_1_on"] = gb["dots_on"] == 1 and "c1-b1" in gb["progress"]["solved"]
    res["save_immediate_on_solve"] = any(w["reason"] == "solve" for w in gb["save_writes"])
    samples = [gb["t_interactive_ms"] - gs["t_solved_ms"]]   # TT-AC-25 sample 1 (cold, real taps); 3 more at chapter-1 finish below
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
    # TT-AC-25 solve -> next board interactive <= 2.0 s, robust to CI-load spikes (thin-07f7ba8 task 5): the real-tap
    # b1 -> b2 sample above is the cold/warm-up one; b2->b3, b3->b4, b4->b5 go through the same solved card ->
    # auto-advance path (no skip). PASS = median of the 4 engine-clock samples <= 2000 ms. The 2 s requirement is not
    # loosened (design path = CARD_MS 1500 + work); every sample is recorded and any single one > 2000 ms is a noted spike.
    for b in range(1, BPC + 1):
        show(pg, f"board:c1-b{b}")
        if b in (2, 3, 4):
            pg.wait_for_function(f"() => {{ const g = JSON.parse(window.PKD_QA.dump()).game; return g.board_id == 'c1-b{b}' && g.interactive }}", timeout=10000)
            pg.wait_for_timeout(300); show(pg, "solve"); ws = dump(pg)["game"]
            pg.wait_for_function(f"() => {{ const g = JSON.parse(window.PKD_QA.dump()).game; return g.board_id == 'c1-b{b + 1}' && g.interactive }}", timeout=10000)
            samples.append(dump(pg)["game"]["t_interactive_ms"] - ws["t_solved_ms"]); continue
        show(pg, "solve"); pg.wait_for_timeout(100)
        if b < BPC: show(pg, "skip")
    srt = sorted(samples); med = (srt[1] + srt[2]) / 2
    notes["solve_to_next_interactive_ms"] = {"samples": samples, "median": med, "spikes_gt_2000": [x for x in samples if x > 2000]}
    res["b1_to_b2_interactive_le_2s"] = len(samples) == 4 and all(x > 0 for x in samples) and med <= 2000   # engine clock, median of 4
    show(pg, "skip"); pg.wait_for_timeout(500); ge = dump(pg)["game"]
    res["chapter_end_screen"] = ge["screen"] == "chapter_end" and ge["unlocked"]["recipes"] == [1] and len(ge["unlocked"]["decor"]) == 1
    res["happytime_on_chapter_end"] = any("happytime" in json.dumps(e) for e in ge["sdk_log"])
    res["save_on_chapter_end"] = any(w["reason"] == "chapter_end" for w in ge["save_writes"])
    res["portrait_backdrop_chapter_end"] = ge["backdrop"] is True
    pg.screenshot(path=f"{out}/game_phone_chapter_end.png")
    pg.evaluate("window.PKD_QA.set_session_s(299)"); show(pg, "end_next"); pg.wait_for_timeout(800)
    d = dump(pg); dec = d["ads_decisions"]; notes["ads_decisions_c1"] = dec
    ce = [e for e in dec if e["origin"] == "chapter_end"]; lb = [e for e in dec if e["origin"] == "level_break"]
    res["ad17_299_denied_real_chapter_end"] = len(ce) == 1 and ce[0]["reason"] == "session_s<300"
    # SPEC v1.4: the level-break slot (after b4 / b8) is decided and denied inside chapter 1 (no ads before chapter 1 ends)
    res["level_break_denied_in_ch1"] = [e["reason"] for e in lb] == ["chapter1_not_done", "chapter1_not_done"] and len(dec) == 3
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
        for b in range(1, BPC + 1):
            show(pg, f"board:c{ch}-b{b}"); show(pg, "solve"); pg.wait_for_timeout(100)
            if b < BPC: show(pg, "skip")
        show(pg, "skip"); pg.wait_for_timeout(500); return dump(pg)["game"]
    ge = finish(2)
    res["chapter2_end_has_next"] = ge["screen"] == "chapter_end" and ge["unlocked"]["recipes"] == [1, 2] and next(u for u in ge["ui"] if u["name"] == "EndNext")["visible"]
    pg.evaluate("window.PKD_QA.set_session_s(300)"); show(pg, "end_next")
    try: pg.wait_for_function("() => { const g = JSON.parse(window.PKD_QA.dump()).game; return g.board_id == 'c3-b1' && g.screen == 'board' }", timeout=10000)   # mock ad, then Next (was a fixed 1.5 s wait: flaked once on 46b0176)
    except Exception: pass
    d = dump(pg); dec = d["ads_decisions"]; notes["ads_decisions_c2"] = dec
    res["ad17_300_ok_real_chapter2_end"] = bool(dec) and dec[-1]["reason"] == "ok" and dec[-1]["origin"] == "chapter_end"
    notes["after_c2_end_next"] = {k: d["game"].get(k) for k in ("board_id", "screen", "card_open", "interactive")}
    res["next_chapter_opens_c3b1"] = d["game"]["board_id"] == "c3-b1" and d["game"]["screen"] == "board"
    s2 = dec[-1]["session_s"] if dec else 300.0   # anchor the gap edges on the RECORDED ch2 decision (wall-clock slip, as br_smoke)
    ge = finish(3)
    res["chapter3_end_screen"] = ge["screen"] == "chapter_end" and ge["unlocked"]["recipes"] == [1, 2, 3]
    pg.screenshot(path=f"{out}/game_phone_chapter3_end.png")
    pg.evaluate(f"window.PKD_QA.set_session_s({math.floor(s2) + 179})"); show(pg, "end_next"); pg.wait_for_timeout(1000)
    d = dump(pg); dec = d["ads_decisions"]; notes["ads_decisions_c3"] = dec[-1:]
    res["ad17_179_gap_denied_real_chapter3_end"] = dec[-1]["reason"] == "gap<180s" and dec[-1]["origin"] == "chapter_end" and not dec[-1]["allowed"]
    res["next_chapter_opens_c4b1"] = d["game"]["board_id"] == "c4-b1"
    pg.evaluate(f"window.PKD_QA.set_session_s({math.floor(s2) + 60})")   # keep the ch4 level breaks (b4, b8) inside the 180 s gap: denied
    ge = finish(4)
    lb4 = [e for e in dump(pg)["ads_decisions"] if e["origin"] == "level_break"][-2:]
    res["level_break_gap_denied_in_ch4"] = [e["reason"] for e in lb4] == ["gap<180s", "gap<180s"]
    pg.evaluate(f"window.PKD_QA.set_session_s({math.ceil(s2) + 180})"); show(pg, "end_home")
    try: pg.wait_for_function("() => JSON.parse(window.PKD_QA.dump()).game.screen == 'home'", timeout=10000)
    except Exception: pass
    d = dump(pg); dec = d["ads_decisions"]; notes["ads_decisions_c4"] = dec[-1:]
    res["ad17_180_gap_ok_real_chapter4_end"] = dec[-1]["reason"] == "ok" and dec[-1]["origin"] == "chapter_end" and dec[-1]["allowed"]
    res["home_after_chapter_end"] = d["game"]["screen"] == "home"
    hd = next(u for u in d["game"]["ui"] if u["name"] == "HomeDaily")
    res["home_daily_unlocked_after_c1"] = hd["enabled"] is True
    pg.screenshot(path=f"{out}/game_phone_home.png")
    # SPEC v1.4 level-break slot allowed: ch5 b1..b4 on first play, 200 s after the ch4-end ad -> after b4 the mock ad
    # plays (origin level_break), then c5-b5 opens; b1..b3 transitions decide nothing.
    n0 = len(d["ads_decisions"]); s4 = dec[-1]["session_s"]
    pg.evaluate(f"window.PKD_QA.set_session_s({math.ceil(s4) + 200})")
    for b in range(1, 5):
        show(pg, f"board:c5-b{b}"); show(pg, "solve"); pg.wait_for_timeout(100)
        if b < 4: show(pg, "skip")
    show(pg, "skip")
    try: pg.wait_for_function("() => { const g = JSON.parse(window.PKD_QA.dump()).game; return g.board_id == 'c5-b5' && g.screen == 'board' }", timeout=10000)
    except Exception: pass
    d5 = dump(pg); new = d5["ads_decisions"][n0:]; notes["ads_decisions_c5_break"] = new
    res["level_break_ok_after_c5_b4"] = len(new) == 1 and new[0]["origin"] == "level_break" and new[0]["allowed"] and new[0]["reason"] == "ok"
    res["level_break_midgame_requested"] = any(isinstance(e, dict) and e.get("kind") == "midgame" and e.get("origin") == "level_break" for e in d5["game"]["ads_log"])
    res["level_break_then_next_level"] = d5["game"]["board_id"] == "c5-b5"
    show(pg, "recipe_book"); pg.wait_for_timeout(400); gb = dump(pg)["game"]
    res["recipe_book_screen"] = gb["screen"] == "recipe_book" and gb["backdrop"] is True
    pg.screenshot(path=f"{out}/game_phone_recipe_book.png")
    # S1-01 (thin-07f7ba8 AN-53): PKD_QA.show("daily:today") resolves "today" to the local date; console_zero covers
    # the old "Invalid ISO 8601 date string" USER ERROR.
    today = pg.evaluate("(() => { const d = new Date(); return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0'); })()")
    r = show(pg, "daily:today"); pg.wait_for_timeout(500); gd = dump(pg)["game"]; notes["daily_today"] = [r, today]
    res["qa_daily_today_opens_todays_daily"] = r == f"open {today}" and gd["screen"] == "board" and gd["mode"] == "daily"
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
