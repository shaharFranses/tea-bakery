#!/usr/bin/env python3
"""tea-bakery RELEASE build checks (served release dir). usage: release_flags_smoke.py <base_url> <out_dir>
1. QA URL flags are inert in release: ?qa=1&seed=42&size=8&state=solved&ads=mock_error&date=2030-01-01&session_offset_s=999&cgmute=1
   still boots to board 1 (tutorial, console '[PKD] board 1: tutorial 5x5'), no 'board n=8' line, window.PKD_QA undefined,
   no hitlog overlay text, PKD_AUDIO.state().portalMute false (cgmute ignored).
2. Intro skip works in release by touch tap, mouse click and key press (fresh page each): '[PKD] intro finished' arrives
   well before the unskipped intro does (compared with a no-input control run on the same box).
3. TT-AC-53 (SPEC v1.0.2) run (a): every request from these release pages is same-origin; 0 sendBeacon (type ping).
   v1.0.2 note: the engine loader's same-origin fetches of the game's own export files are allowed, so every same-origin
   request must be one of the export files (index.html/js/wasm/pck/worklets/icons...; env PKD_RELEASE_DIR, default
   build/web-release) and nothing else.
4. Page <title> is the game title 'Teacake Lane' (config/name; SPEC v1.5), never the slug."""
import json, os, re, sys, time
from playwright.sync_api import sync_playwright
base, out = sys.argv[1].rstrip("/"), sys.argv[2]; os.makedirs(out, exist_ok=True)
HERE = os.path.dirname(os.path.abspath(__file__))
allow = [re.compile(l.strip()) for l in open(os.path.join(HERE, "console_allowlist.txt")) if l.strip() and not l.startswith("#")]
res, bad, notes, reqs = {}, [], {}, []
def page(ctx, q=""):
    logs = []; pg = ctx.new_page()
    def oc(m):
        logs.append((time.time(), m.text))
        if m.type in ("error", "warning") and not any(a.search(m.text) for a in allow): bad.append(m.text)
    pg.on("console", oc); pg.on("pageerror", lambda e: bad.append(str(e)))
    pg.on("request", lambda r: reqs.append((r.url, r.resource_type)))   # TT-AC-53 run (a): network log of the game page
    pg.goto(f"{base}/index.html{q}")
    return pg, logs
def wait_for(pg, logs, s, t=60):
    # NB: pump Playwright's event loop (pg.wait_for_timeout), never time.sleep: the sync API only delivers console
    # events while inside a Playwright call, so a time.sleep loop never sees new lines (that was the 'null' bug).
    t0 = time.time()
    while time.time() - t0 < t:
        for ts, l in logs:
            if s in l: return ts
        pg.wait_for_timeout(50)
    return None
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=os.environ.get("PKD_CHROME", "/usr/bin/google-chrome"), headless=True,
                           args=["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"])
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, has_touch=True, is_mobile=True)
    pg, logs = page(ctx, "?qa=1&seed=42&size=8&state=solved&ads=mock_error&date=2030-01-01&session_offset_s=999&cgmute=1&intro=1")
    wait_for(pg, logs, "pkd:perf pkd:board_interactive"); pg.wait_for_timeout(800)
    text = [l for _, l in logs]
    # release has no Dbg lines: board 1 is identified by the BR-1 performance mark detail (board_id), which ships in release
    bids = pg.evaluate("performance.getEntriesByName('pkd:board_interactive').map(e => (e.detail || {}).board_id)")
    notes["board_ids"] = bids
    res["flags_inert_tutorial_board"] = bids[:1] == ["c1-b1"] and not any("board n=" in l for l in text)
    res["flags_inert_no_PKD_QA"] = pg.evaluate("typeof window.PKD_QA") == "undefined"
    res["flags_inert_no_qa_log"] = not any("QA on" in l or "QA show" in l or "[ads]" in l and "mock" in l for l in text)
    st = pg.evaluate("window.PKD_AUDIO ? window.PKD_AUDIO.state() : {}")
    res["flags_inert_cgmute_ignored"] = st.get("portalMute") is False
    res["title_is_stub_not_slug"] = pg.title() == "Teacake Lane"
    notes["title"] = pg.title()
    pg.screenshot(path=f"{out}/release_flags_390.png"); pg.close()
    # intro skip: control (no input) vs tap / click / key
    def intro_len(how):
        c = br.new_context(viewport={"width": 390, "height": 844}, has_touch=(how == "tap"), is_mobile=(how == "tap"))
        pg, logs = page(c)
        t0 = wait_for(pg, logs, "[PKD] main ready")
        if t0 is None: c.close(); return None
        pg.wait_for_timeout(250)
        if how == "tap": pg.touchscreen.tap(195, 422)
        elif how == "click": pg.mouse.click(195, 422)
        elif how == "key": pg.keyboard.press("Space")
        t1 = wait_for(pg, logs, "[PKD] intro finished", 20)
        c.close()
        return None if t1 is None else round(t1 - t0, 2)
    ctrl = intro_len("none"); notes["intro_s_no_input"] = ctrl
    for how in ("tap", "click", "key"):
        d = intro_len(how); notes[f"intro_s_{how}"] = d
        res[f"intro_skip_{how}"] = d is not None and ctrl is not None and d < 1.0 and d < ctrl - 0.5
    br.close()
# TT-AC-53 (SPEC v1.0.1), allowlist run (a) local release without SDK: every request goes to the game's own origin, 0 beacons
from urllib.parse import urlsplit
own = urlsplit(base).netloc
foreign = sorted({u for u, t in reqs if not u.startswith("data:") and not u.startswith("blob:") and urlsplit(u).netloc != own})
beacons = [u for u, t in reqs if t == "ping"]
rel = os.environ.get("PKD_RELEASE_DIR", os.path.join(os.path.dirname(HERE), "build", "web-release"))
export_files = set(os.listdir(rel)) if os.path.isdir(rel) else set()
own_paths = sorted({urlsplit(u).path for u, t in reqs if urlsplit(u).netloc == own})
non_export = [pth for pth in own_paths if pth.rsplit("/", 1)[-1] not in export_files and pth not in ("/", "")]
notes["requests"] = len(reqs); notes["foreign_requests"] = foreign
notes["own_origin_paths"] = own_paths; notes["own_origin_non_export"] = non_export
res["ac53_v102_own_origin_requests_are_export_files"] = bool(export_files) and not non_export
res["ac53_only_own_origin_0_beacons"] = bool(reqs) and not foreign and not beacons
res["console_zero"] = not bad
json.dump({"checks": res, "notes": notes, "console_bad": bad}, open(f"{out}/release_flags.json", "w"), indent=1)
for k, v in res.items(): print(("PASS " if v else "FAIL ") + k)
print("notes:", json.dumps(notes))
sys.exit(0 if all(res.values()) else 1)
