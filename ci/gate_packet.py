#!/usr/bin/env python3
"""Writes the QA gate packet (Playbook v1 standing rule 3) + updates CURRENT_BUILD.md 'Last CI' + metrics/gates.csv.
usage: gate_packet.py <results_dir> <PASS|FAIL> <port> <slug> <gate 0|1>"""
import csv, datetime, json, os, re, subprocess, sys
R, verdict, port, slug, gate = sys.argv[1:6]
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(root)
sh = lambda *a: subprocess.run(a, capture_output=True, text=True).stdout.strip()
sha, branch = sh("git", "rev-parse", "--short", "HEAD"), sh("git", "branch", "--show-current")
now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")  # box clock = Asia/Jerusalem
dirty = os.environ.get("PKD_DIRTY_AT_START", "1") != "0"  # tracked changes at CI start (CI itself edits CURRENT_BUILD.md/metrics)
gates_csv = "metrics/gates.csv"
prev = None
if os.path.exists(gates_csv):
    rows = [r for r in csv.DictReader(open(gates_csv)) if r.get("gate") == "1" and r.get("commit") != sha]
    prev = rows[-1]["commit"] if rows else None
log = sh("git", "log", "--format=- %h %s", f"{prev}..HEAD") if prev else sh("git", "log", "--format=- %h %s", "-15")
size = lambda v: json.load(open(f"build/web-{v}/SIZE.json")) if os.path.exists(f"build/web-{v}/SIZE.json") else {}
rel, dbg = size("release"), size("debug")
mb = lambda b: f"{b/1e6:.2f} MB" if b else "?"
smoke = []
for v in ("debug", "release"):
    p = os.path.join(R, f"smoke_{v}.json")
    if os.path.exists(p): smoke += [(v, r) for r in json.load(open(p))]
steps = open(os.path.join(R, "steps.txt")).read().strip() if os.path.exists(os.path.join(R, "steps.txt")) else ""
gated = open(os.path.join(R, "GATED_DIR")).read().strip() if os.path.exists(os.path.join(R, "GATED_DIR")) else ""
zipf = sorted([f for f in os.listdir("dist") if f.endswith(f"-cg-{sha}.zip")]) if os.path.isdir("dist") else []
zipline = ""
if zipf:
    z = os.path.join("dist", zipf[0]); zipline = f"| CG zip | `{z}` {os.path.getsize(z)} B, md5 `{open(z + '.md5').read().strip()}` |"
toggles = """- `?qa=1` on-screen hitlog + `window.PKD_QA.dump()` (debug build only)
- `?qa=1&<key>=<value>` game tunables via `Dbg.toggle(key)` (list the game's keys in the spec)
- `?intro=0` skip the PKD intro, `?audio=0` boot with audio muted (feature-off toggles, also in release)
- Keys: F7 dumps state to the console (debug)"""
import hashlib
gated_sha = hashlib.sha256(open(os.path.join(gated, "index.pck"), "rb").read()).hexdigest() if gated and os.path.exists(os.path.join(gated, "index.pck")) else ""
template = "pkd slim" if "slim" in open("export_presets.cfg").read().split("custom_template/release=")[1].split("\n")[0] else "stock"
L = [f"# Gate packet: {slug} @ `{sha}` ({branch}): CI {verdict}", "",
     f"Generated {now} Asia/Jerusalem by ci/run.sh. {'**Working tree dirty: not gateable.**' if dirty else 'Working tree clean.'}", "",
     "| Field | Value |", "|---|---|",
     f"| Commit | `{sha}` on `{branch}` |",
     f"| Local ports | debug :{port} (`?qa=1`), release :{int(port)+1} (tools/serve_unit.sh) |",
     f"| Gated dir | `{gated or '(not frozen; run ci/run.sh --gate)'}` |",
     f"| Release index.pck sha256 (authoritative, SM3-4) | `{rel.get('sha256', {}).get('index.pck', '?')}` · md5 `{rel.get('md5', {}).get('index.pck', '?')}` (INFO) ({mb(rel.get('pck_bytes'))}) |",
     f"| Gated index.pck sha256 (served copy) | `{gated_sha or '(not frozen)'}` {'== release build' if gated_sha and gated_sha == rel.get('sha256', {}).get('index.pck') else ('!= release build: FAIL' if gated_sha else '')} |",
     f"| Release wasm sha256 · md5 | `{rel.get('sha256', {}).get('index.wasm', '?')}` · `{rel.get('md5', {}).get('index.wasm', '?')}` ({mb(rel.get('wasm_bytes'))}, gz {mb(rel.get('wasm_gz_bytes'))}) |",
     f"| Release total | {mb(rel.get('total_raw_bytes'))} vs 20 MB budget: {'OVER' if rel.get('over_budget') else 'ok'} (engine template: {template}) |",
     f"| Debug build id | `{dbg.get('build_id', '?')}` (wasm {mb(dbg.get('wasm_bytes'))}) |",
     f"| Release build id | `{rel.get('build_id', '?')}` |"] + ([zipline] if zipline else []) + [
     "", "## Steps", "```", steps, "```", "", "## Boot smoke / console-zero / screenshots", "| Build | Cell | Boot s | Checks | Screenshot |", "|---|---|---|---|---|"]
for v, r in smoke:
    ck = ", ".join(f"{k} {'ok' if x else 'FAIL'}" for k, x in r["checks"].items())
    L.append(f"| {v} | {r['cell']} | {r['boot_s']} | {ck} | `{os.path.relpath(r['screenshot'], root)}` |")
L += ["", f"## Changelog since last gate ({prev or 'no previous gate: last 15 commits'})", log or "(none)", "",
      "## QA toggles", toggles, "",
      "## Unverified (box cannot check these; QA/Shahar must)",
      "- Real iPhone Safari / Android Chrome boot, rotation, safe-area on a notch device (box has no real device)",
      "- Real touch input and audio by ear (box has no touch screen or audio out)",
      "- Hardware GL performance / frame timing (box renders with SwiftShader)",
      "- CrazyGames SDK on the portal (only testable on CG hosts)",
      "- Full viewport x input matrix (deferred to thin slice)", "",
      "## What PASS unlocks",
      "- QA PASS on this exact sha → SM runs tools/publish_web.sh on the gated dir, commits web/, pushes → Pages deploys → `ci/run.sh --live <url>` (hash match) → CURRENT_BUILD.md → Shahar.",
      "- Nothing reaches Shahar without QA PASS."]
open(os.path.join(R, "GATE_PACKET.md"), "w").write("\n".join(L) + "\n")
# CURRENT_BUILD.md Last CI block
cb = "CURRENT_BUILD.md"
if os.path.exists(cb):
    s = open(cb).read()
    block = f"<!-- ci:begin -->\n{now}: CI **{verdict}** on `{sha}` · release {mb(rel.get('total_raw_bytes'))} (wasm {mb(rel.get('wasm_bytes'))}) · packet `{R}/GATE_PACKET.md`{' · gated ' + gated if gated else ''}\n<!-- ci:end -->"
    s = re.sub(r"<!-- ci:begin -->.*?<!-- ci:end -->", block, s, flags=re.S); open(cb, "w").write(s)
os.makedirs("metrics", exist_ok=True); new = not os.path.exists(gates_csv)
with open(gates_csv, "a", newline="") as f:
    w = csv.writer(f)
    if new: w.writerow(["datetime_asia_jerusalem", "commit", "branch", "ci_verdict", "gate", "release_total_bytes", "wasm_bytes", "fails", "qa_verdict", "stage"])
    fails = ";".join(l.split(":")[0] for l in steps.splitlines() if "FAIL" in l)
    w.writerow([now, sha, branch, verdict, gate, rel.get("total_raw_bytes", ""), rel.get("wasm_bytes", ""), fails, "", ""])
print(f"gate packet: {R}/GATE_PACKET.md")
