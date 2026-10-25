#!/usr/bin/env python3
"""SPEC v0.3.1 §13.1 BR-1..BR-3 browser checks. usage: br_smoke.py <debug_url> <release_url> <out_dir>
BR-1 (release AND debug): after boot and after each "New tray" tap, exactly one console line each of
  'pkd:perf pkd:transition_start|transition_end|board_interactive <ms 1 decimal>' (QA-A08 PERF_RE), matching
  performance.getEntriesByType('mark'); board_interactive mark carries {board_id}; no other console lines in release
  except the starter boot markers '[PKD] main ready' / '[PKD] intro finished'.
BR-2 (debug ?qa=1): PKD_QA.set_date() runtime date via the day-change path; V9 (open 11-03 daily, set_date 11-04, finish
  -> counts for 11-03, 11-04 still open); V8 PKD_QA.retry_daily() rejected, streak/total unchanged.
BR-3 (debug ?qa=1): PKD_QA.set_session_s(N); every decision in dump().ads_decisions[] {t,session_s,origin,allowed,reason};
  edges 299/300 s (SPEC v1.0 floor) and 179/180 s gap; no decision without a chapter-end slot (nothing on a timer)."""
import json, os, re, sys
from playwright.sync_api import sync_playwright
dbg, rel, out = sys.argv[1].rstrip("/"), sys.argv[2].rstrip("/"), sys.argv[3]; os.makedirs(out, exist_ok=True)
PERF_RE = re.compile(r"^pkd:perf pkd:(transition_start|transition_end|board_interactive) \d+\.\d$")
BOOT_OK = re.compile(r"^(\[PKD\] (main ready|intro finished)|Godot Engine v4\.3\..*|OpenGL API .*)$")   # starter boot markers + engine banner
res, notes = {}, {}
def boot(br, url, q, **kw):
    ctx = br.new_context(viewport={"width": 390, "height": 844}, **kw); pg = ctx.new_page(); logs = []
    pg.on("console", lambda m: logs.append(m.text))
    pg.goto(f"{url}/index.html{q}")
    pg.wait_for_function("() => performance.getEntriesByName('pkd:board_interactive').length >= 1", timeout=90000)
    pg.wait_for_timeout(300)
    return ctx, pg, logs
def perf_counts(lines):
    c = {"transition_start": 0, "transition_end": 0, "board_interactive": 0}
    for l in lines:
        m = PERF_RE.match(l)
        if m: c[m.group(1)] += 1
    return c
def dump(pg): return json.loads(pg.evaluate("window.PKD_QA.dump()"))
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=os.environ.get("PKD_CHROME", "/usr/bin/google-chrome"), headless=True,
                           args=["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"])
    # ---- BR-1 release
    ctx, pg, logs = boot(br, rel, "", device_scale_factor=2, has_touch=True, is_mobile=True)
    perf = [l for l in logs if l.startswith("pkd:perf")]
    res["br1_release_boot_one_line_each"] = perf_counts(logs) == {"transition_start": 1, "transition_end": 1, "board_interactive": 1}
    res["br1_release_lines_exact_format"] = bool(perf) and all(PERF_RE.match(l) for l in perf)
    n0 = len(logs)
    # tap "New tray" via its rect is debug-only info; use the play button position measured on the debug build below
    marks = pg.evaluate("performance.getEntriesByType('mark').filter(m => m.name.startsWith('pkd:')).map(m => [m.name, m.detail])")
    res["br1_release_marks_match_lines"] = [m[0] for m in marks] == ["pkd:transition_start", "pkd:transition_end", "pkd:board_interactive"]
    res["br1_release_board_id_detail"] = bool(marks) and (marks[-1][1] or {}).get("board_id") == "c1-b1"
    notes["release_console"] = logs
    rel_pg, rel_ctx = pg, ctx
    # ---- debug: find the New tray button, then BR-1 on a transition (debug + release)
    ctx, pg, logs = boot(br, dbg, "?qa=1&intro=0", device_scale_factor=2, has_touch=True, is_mobile=True)
    g = dump(pg)["game"]; play = next(u for u in g["ui"] if u["name"] == "Play"); x, y = play["rect"][0] + play["rect"][2] / 2, play["rect"][1] + play["rect"][3] / 2
    k0 = len(logs); pg.touchscreen.tap(x, y); pg.wait_for_function("() => performance.getEntriesByName('pkd:board_interactive').length >= 2", timeout=20000); pg.wait_for_timeout(300)
    res["br1_debug_transition_one_line_each"] = perf_counts(logs[k0:]) == {"transition_start": 1, "transition_end": 1, "board_interactive": 1}
    r0 = len(notes["release_console"]); rel_pg.touchscreen.tap(x, y)
    rel_pg.wait_for_function("() => performance.getEntriesByName('pkd:board_interactive').length >= 2", timeout=20000); rel_pg.wait_for_timeout(300)
    rl = notes["release_console"]
    res["br1_release_transition_one_line_each"] = perf_counts(rl[r0:]) == {"transition_start": 1, "transition_end": 1, "board_interactive": 1}
    res["br1_release_console_only_perf_and_boot"] = all(PERF_RE.match(l) or BOOT_OK.match(l) for l in rl)
    rel_ctx.close()
    # ---- BR-3: session clock + decisions
    ev = lambda js: pg.evaluate(js)
    res["br3_no_decision_without_slot"] = dump(pg)["ads_decisions"] == []
    ev("window.PKD_QA.set_session_s(299)"); ev("window.PKD_QA.show('chapter_end:1')")   # floor: denied session_s<300
    ev("window.PKD_QA.set_session_s(300)"); ev("window.PKD_QA.show('chapter_end:1')")   # allowed
    ev("window.PKD_QA.set_session_s(479)"); ev("window.PKD_QA.show('chapter_end:2')")   # 179 s: gap<180s
    ev("window.PKD_QA.set_session_s(480)"); ev("window.PKD_QA.show('chapter_end:2')")   # 180 s: ok
    pg.wait_for_timeout(300); d = dump(pg)["ads_decisions"]; notes["ads_decisions"] = d
    res["br3_entry_shape"] = bool(d) and all(sorted(e.keys()) == ["allowed", "origin", "reason", "session_s", "t"] for e in d)
    res["br3_299_denied_300_allowed"] = len(d) >= 2 and d[0]["reason"] == "session_s<300" and not d[0]["allowed"] and d[1]["reason"] == "ok" and d[1]["allowed"]
    res["br3_179_gap_180_ok"] = len(d) == 4 and d[2]["reason"] == "gap<180s" and d[3]["reason"] == "ok"
    res["br3_set_session_s_runtime"] = abs(dump(pg)["game"]["session_s"] - 480) < 5
    # ---- BR-2: V9 + V8
    ev("window.PKD_QA.set_date('2026-11-02')"); ev("window.PKD_QA.show('daily:2026-11-02')"); ev("window.PKD_QA.show('solve')")
    ev("window.PKD_QA.set_date('2026-11-03T23:58')"); ev("window.PKD_QA.show('daily:2026-11-03')")
    ev("window.PKD_QA.set_date('2026-11-04T00:03')"); pg.wait_for_timeout(200); ev("window.PKD_QA.show('solve')"); pg.wait_for_timeout(200)
    g = dump(pg)["game"]; notes["v9"] = {k: g[k] for k in ("bakes", "streak", "total_bakes", "date", "daily_done_today")}
    res["br2_v9_counts_for_board_date"] = g["bakes"] == ["2026-11-02", "2026-11-03"] and g["streak"] == 2 and g["date"] == "2026-11-04" and g["daily_done_today"] is False
    ev("window.PKD_QA.set_date('2026-11-03')"); ev("window.PKD_QA.retry_daily()"); pg.wait_for_timeout(200)
    g2 = dump(pg)["game"]; notes["v8"] = {k: g2[k] for k in ("bakes", "streak", "total_bakes", "last_daily")}
    res["br2_v8_retry_rejected_streak_unchanged"] = g2["last_daily"].get("counted") is False and g2["total_bakes"] == 2 and g2["streak"] == 2
    res["br2_day_change_path"] = any("day change" in h for h in dump(pg)["hitlog"])
    dd = dump(pg); notes["net_calls"] = dd.get("net_calls")
    res["ac53_runtime_zero_game_network_calls"] = dd.get("net_calls_from_game") == 0 and isinstance(dd.get("net_calls"), list)
    res["ac53_analytics_sink_noop_ring_filled"] = dd["game"]["analytics_sink"] == "noop" and any(e["event"] == "board_start" for e in dd["game"]["analytics"])
    ctx.close(); br.close()
json.dump({"checks": res, "notes": notes}, open(f"{out}/br_smoke.json", "w"), indent=1)
for k, v in res.items(): print(("PASS " if v else "FAIL ") + k)
sys.exit(0 if all(res.values()) else 1)
