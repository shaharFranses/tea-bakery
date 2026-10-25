#!/usr/bin/env python3
"""tea-bakery RELEASE build checks (served release dir). usage: release_flags_smoke.py <base_url> <out_dir>
1. QA URL flags are inert in release: ?qa=1&seed=42&size=8&state=solved&ads=mock_error&date=2030-01-01&session_offset_s=999&cgmute=1
   still boots to board 1 (tutorial, console '[PKD] board 1: tutorial 5x5'), no 'board n=8' line, window.PKD_QA undefined,
   no hitlog overlay text, PKD_AUDIO.state().portalMute false (cgmute ignored).
2. Intro skip works in release by touch tap, mouse click and key press (fresh page each): '[PKD] intro finished' arrives
   well before the unskipped intro does (compared with a no-input control run on the same box).
3. Page <title> is the working-name stub 'tea-bakery'."""
import json, os, re, sys, time
from playwright.sync_api import sync_playwright
base, out = sys.argv[1].rstrip("/"), sys.argv[2]; os.makedirs(out, exist_ok=True)
HERE = os.path.dirname(os.path.abspath(__file__))
allow = [re.compile(l.strip()) for l in open(os.path.join(HERE, "console_allowlist.txt")) if l.strip() and not l.startswith("#")]
res, bad, notes = {}, [], {}
def page(ctx, q=""):
    logs = []; pg = ctx.new_page()
    def oc(m):
        logs.append((time.time(), m.text))
        if m.type in ("error", "warning") and not any(a.search(m.text) for a in allow): bad.append(m.text)
    pg.on("console", oc); pg.on("pageerror", lambda e: bad.append(str(e)))
    pg.goto(f"{base}/index.html{q}")
    return pg, logs
def wait_for(logs, s, t=60):
    t0 = time.time()
    while time.time() - t0 < t:
        for ts, l in logs:
            if s in l: return ts
        time.sleep(0.05)
    return None
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=os.environ.get("PKD_CHROME", "/usr/bin/google-chrome"), headless=True,
                           args=["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"])
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, has_touch=True, is_mobile=True)
    pg, logs = page(ctx, "?qa=1&seed=42&size=8&state=solved&ads=mock_error&date=2030-01-01&session_offset_s=999&cgmute=1&intro=1")
    wait_for(logs, "[PKD] intro finished"); pg.wait_for_timeout(800)
    text = [l for _, l in logs]
    res["flags_inert_tutorial_board"] = any("board 1: tutorial 5x5" in l for l in text) and not any("board n=" in l for l in text)
    res["flags_inert_no_PKD_QA"] = pg.evaluate("typeof window.PKD_QA") == "undefined"
    res["flags_inert_no_qa_log"] = not any("QA on" in l or "QA show" in l or "[ads]" in l and "mock" in l for l in text)
    st = pg.evaluate("window.PKD_AUDIO ? window.PKD_AUDIO.state() : {}")
    res["flags_inert_cgmute_ignored"] = st.get("portalMute") is False
    res["title_is_working_name_stub"] = pg.title() == "tea-bakery"
    notes["title"] = pg.title()
    pg.screenshot(path=f"{out}/release_flags_390.png"); pg.close()
    # intro skip: control (no input) vs tap / click / key
    def intro_len(how):
        c = br.new_context(viewport={"width": 390, "height": 844}, has_touch=(how == "tap"), is_mobile=(how == "tap"))
        pg, logs = page(c)
        t0 = wait_for(logs, "[PKD] main ready")
        if t0 is None: c.close(); return None
        pg.wait_for_timeout(250)
        if how == "tap": pg.touchscreen.tap(195, 422)
        elif how == "click": pg.mouse.click(195, 422)
        elif how == "key": pg.keyboard.press("Space")
        t1 = wait_for(logs, "[PKD] intro finished", 20)
        c.close()
        return None if t1 is None else round(t1 - t0, 2)
    ctrl = intro_len("none"); notes["intro_s_no_input"] = ctrl
    for how in ("tap", "click", "key"):
        d = intro_len(how); notes[f"intro_s_{how}"] = d
        res[f"intro_skip_{how}"] = d is not None and ctrl is not None and d < 1.0 and d < ctrl - 0.5
    br.close()
res["console_zero"] = not bad
json.dump({"checks": res, "notes": notes, "console_bad": bad}, open(f"{out}/release_flags.json", "w"), indent=1)
for k, v in res.items(): print(("PASS " if v else "FAIL ") + k)
print("notes:", json.dumps(notes))
sys.exit(0 if all(res.values()) else 1)
