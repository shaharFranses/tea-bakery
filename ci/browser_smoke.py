#!/usr/bin/env python3
"""Boot smoke + console-zero + minimal screenshots for a served PKD web build (Playwright + system Chrome).
usage: browser_smoke.py <base_url> <out_dir> <debug|release>
Cells: phone 390x844 (touch, DPR 2), desktop 1280x800 (mouse, DPR 1), and a hidden-tab-at-load boot (phone).
PASS needs: '[PKD] main ready' within the timeout, 0 console errors/warnings/page errors not in ci/console_allowlist.txt,
and (debug) PKD_QA.dump(): scene Main, frames drawn > 0, tree not paused; hidden boot mutes with reason 'hidden'
and still reaches main (tree never paused, FF lesson). Full viewport x input matrix: deferred to thin slice."""
import json, os, re, sys, time
from playwright.sync_api import sync_playwright

base, out, variant = sys.argv[1], sys.argv[2], sys.argv[3]
os.makedirs(out, exist_ok=True)
HERE = os.path.dirname(os.path.abspath(__file__))
allow = [re.compile(l.strip()) for l in open(os.path.join(HERE, "console_allowlist.txt")) if l.strip() and not l.startswith("#")]
CHROME = os.environ.get("PKD_CHROME", "/usr/bin/google-chrome")
TIMEOUT = float(os.environ.get("PKD_BOOT_TIMEOUT", "45"))
HIDE_JS = """(() => { window.__pkdHidden = true;
  Object.defineProperty(document, 'hidden', {configurable: true, get: () => window.__pkdHidden});
  Object.defineProperty(document, 'visibilityState', {configurable: true, get: () => window.__pkdHidden ? 'hidden' : 'visible'});
  window.__pkdShow = () => { window.__pkdHidden = false; document.dispatchEvent(new Event('visibilitychange')); }; })();"""
cells = [
    {"name": "phone_390x844", "viewport": {"width": 390, "height": 844}, "dpr": 2, "touch": True, "mobile": True},
    {"name": "desktop_1280x800", "viewport": {"width": 1280, "height": 800}, "dpr": 1, "touch": False, "mobile": False},
    {"name": "phone_hidden_boot", "viewport": {"width": 390, "height": 844}, "dpr": 2, "touch": True, "mobile": True, "hidden": True},
]
results = []
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME, headless=True,
                           args=["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"])
    for c in cells:
        ctx = br.new_context(viewport=c["viewport"], device_scale_factor=c["dpr"], has_touch=c["touch"], is_mobile=c["mobile"])
        if c.get("hidden"): ctx.add_init_script(HIDE_JS)
        pg = ctx.new_page()
        logs, bad = [], []
        def on_console(m, logs=logs, bad=bad):
            line = f"{m.type}: {m.text}"; logs.append(line)
            if m.type in ("error", "warning") and not any(a.search(m.text) for a in allow): bad.append(line)
        pg.on("console", on_console)
        pg.on("pageerror", lambda e, bad=bad, logs=logs: (logs.append(f"pageerror: {e}"), bad.append(f"pageerror: {e}")))
        url = base + ("/index.html?qa=1" if variant == "debug" else "/index.html")
        t0 = time.time(); r = {"cell": c["name"], "url": url}
        pg.goto(url)
        ready = False
        while time.time() - t0 < TIMEOUT:
            if any("[PKD] main ready" in l for l in logs): ready = True; break
            pg.wait_for_timeout(250)
        r["boot_s"] = round(time.time() - t0, 1) if ready else None
        if c.get("hidden"):
            dump_hidden = json.loads(pg.evaluate("window.PKD_QA ? window.PKD_QA.dump() : '{}'") or "{}") if variant == "debug" else {}
            r["hidden_mute_reasons"] = dump_hidden.get("mute_reasons")
            pg.evaluate("window.__pkdShow()"); pg.wait_for_timeout(1000)
        # wait for the intro to finish (time-based 1.93 s; software GL on the box is slower)
        t1 = time.time()
        while time.time() - t1 < 15 and not any("[PKD] intro finished" in l for l in logs): pg.wait_for_timeout(250)
        r["intro_finished_log"] = any("[PKD] intro finished" in l for l in logs)
        pg.wait_for_timeout(500)
        dump = {}
        if variant == "debug":
            try: dump = json.loads(pg.evaluate("window.PKD_QA ? window.PKD_QA.dump() : '{}'") or "{}")
            except Exception as e: dump = {"error": str(e)}
        shot = os.path.join(out, f"{variant}_{c['name']}.png"); pg.screenshot(path=shot)
        checks = {"boot_ready": ready, "intro_finished_log": r["intro_finished_log"], "console_zero": not bad}
        if variant == "debug":
            checks["scene_main"] = dump.get("scene") == "Main"
            checks["frames_drawn"] = (dump.get("frames") or 0) > 0
            checks["tree_not_paused"] = dump.get("paused") is False
            checks["intro_finished"] = (dump.get("game") or {}).get("intro_done") is True
            if c.get("hidden"):
                checks["hidden_muted"] = "hidden" in (r.get("hidden_mute_reasons") or [])
                checks["unmuted_after_show"] = dump.get("mute_reasons") is not None and "hidden" not in dump["mute_reasons"]
        r.update({"checks": checks, "pass": all(checks.values()), "console_bad": bad, "screenshot": shot, "dump": dump})
        open(os.path.join(out, f"{variant}_{c['name']}_console.log"), "w").write("\n".join(logs))
        results.append(r); ctx.close()
    br.close()
json.dump(results, open(os.path.join(out, f"smoke_{variant}.json"), "w"), indent=1)
for r in results:
    print(f"{'PASS' if r['pass'] else 'FAIL'} {variant} {r['cell']} boot={r['boot_s']}s " + " ".join(f"{k}={'ok' if v else 'NO'}" for k, v in r["checks"].items()))
    for b in r["console_bad"][:5]: print("   console:", b)
sys.exit(0 if all(r["pass"] for r in results) else 1)
