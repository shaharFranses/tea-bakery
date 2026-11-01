#!/usr/bin/env python3
"""Boot smoke for the slim-template release variant. usage: slim_smoke.py <base_url> <out_dir>
390x844 DPR2 touch + 800x450: '[PKD] main ready' and '[PKD] intro finished' within 90 s, zero console errors/warnings."""
import json, os, re, sys, time
from playwright.sync_api import sync_playwright
base, out = sys.argv[1].rstrip("/"), sys.argv[2]; os.makedirs(out, exist_ok=True)
HERE = os.path.dirname(os.path.abspath(__file__))
allow = [re.compile(l.strip()) for l in open(os.path.join(HERE, "console_allowlist.txt")) if l.strip() and not l.startswith("#")]
res = {}
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=os.environ.get("PKD_CHROME", "/usr/bin/google-chrome"), headless=True,
                           args=["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"])
    for tag, kw in [("phone_390x844", dict(viewport={"width": 390, "height": 844}, device_scale_factor=2, has_touch=True, is_mobile=True)),
                    ("embed_800x450", dict(viewport={"width": 800, "height": 450}))]:
        ctx = br.new_context(**kw); pg = ctx.new_page(); logs, bad = [], []
        pg.on("console", lambda m: (logs.append(m.text), bad.append(m.text) if m.type in ("error", "warning") and not any(a.search(m.text) for a in allow) else None))
        pg.on("pageerror", lambda e: bad.append(str(e)))
        t0 = time.time(); pg.goto(f"{base}/index.html")
        try: pg.wait_for_function("() => true", timeout=1000)
        except Exception: pass
        while time.time() - t0 < 90 and not any("[PKD] intro finished" in l for l in logs): pg.wait_for_timeout(200)
        r = {"main_ready": any("[PKD] main ready" in l for l in logs), "intro_finished": any("[PKD] intro finished" in l for l in logs),
             "boot_s": round(time.time() - t0, 1), "console_bad": bad}
        r["pass"] = r["main_ready"] and r["intro_finished"] and not bad
        pg.screenshot(path=f"{out}/slim_{tag}.png"); res[tag] = r; ctx.close()
        print(("PASS " if r["pass"] else "FAIL ") + tag, r)
    br.close()
json.dump(res, open(f"{out}/slim_smoke.json", "w"), indent=1)
sys.exit(0 if all(r["pass"] for r in res.values()) else 1)
