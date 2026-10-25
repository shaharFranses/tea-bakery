#!/usr/bin/env python3
"""CI step 7: no banned user-visible text in the web export (QA ruling 10-25 (3), SPEC §3.5 banned_user_text, TT-AC-39)
combined with QA's NAME-01 scanner (qa/tt_title_scan.py, copied verbatim).
Patterns: data/banned_user_text.json = synced copy of SPEC §3.5 (if the spec is on the box and its list differs -> FAIL
"resync"), plus tt_title_scan.PAT. Scanned per build dir: HTML <title> + all index.html text, every string in index.pck
(decompressed scripts incl. identifiers, scenes, project.binary config/name, resources), index.js; plus the source tree
(INFO for paths of shared box folders). usage: user_text_scan.py <out_dir> <build_dir>..."""
import json, os, re, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__)); root = os.path.dirname(here); sys.path.insert(0, here)
import pck_strings
out = sys.argv[1]; builds = sys.argv[2:]; os.makedirs(out, exist_ok=True)
SPEC = "/workspace/pipeline-ops/games/tea-and-tarts/SPEC.md"
synced = json.load(open(f"{root}/data/banned_user_text.json"))["banned_user_text"]
fails = []
if os.path.exists(SPEC):
    m = re.search(r'"banned_user_text":\s*(\[.*?\])\s*\n', open(SPEC).read())
    if m and json.loads(m.group(1)) != synced: fails.append("data/banned_user_text.json out of sync with SPEC §3.5: resync")
pats = [(f"spec:{p}", re.compile(p.encode(), re.I)) for p in synced]
pats.append(("qa:tt_title_scan.PAT", re.compile(rb"tea[\s_\-]*(?:&amp;|&|and)[\s_\-]*tarts", re.I)))
hits = []; titles = {}
def scan(where, b):
    for name, p in pats:
        for m in p.finditer(b):
            hits.append({"where": where, "pattern": name, "match": m.group().decode("utf-8", "replace"),
                         "context": b[max(0, m.start() - 40): m.end() + 40].decode("utf-8", "replace").replace("\n", " ")})
for d in builds:
    html = open(f"{d}/index.html", "rb").read()
    t = re.search(rb"<title>(.*?)</title>", html, re.S | re.I); titles[d] = t.group(1).decode() if t else None
    scan(f"{d}/index.html", html); scan(f"{d}/index.js", open(f"{d}/index.js", "rb").read())
    _, fl = pck_strings.files(f"{d}/index.pck")
    for p, data in fl: scan(f"{d}/index.pck::{p}", pck_strings.text_of(p, data))
# QA's own scanner too (selftest + its --dir scan)
st = subprocess.run([sys.executable, f"{here}/tt_title_scan.py", "--selftest"]).returncode
args = [sys.executable, f"{here}/tt_title_scan.py", f"{out}/title_scan.json"]
for d in builds: args += ["--dir", d]
qa_rc = subprocess.run(args).returncode
if st: fails.append("tt_title_scan selftest failed")
if qa_rc: fails.append("tt_title_scan --dir found hits")
fails += [f"{h['where']}: /{h['pattern']}/ '{h['match']}' ...{h['context']}..." for h in hits]
json.dump({"pass": not fails, "titles": titles, "patterns": [n for n, _ in pats], "hits": hits, "fails": fails}, open(f"{out}/user_text_scan.json", "w"), indent=1)
print(f"user-text scan: {'PASS' if not fails else 'FAIL'}: {len(hits)} banned hits in {len(builds)} builds; titles {titles}")
for f in fails[:12]: print("  ", f)
sys.exit(1 if fails else 0)
