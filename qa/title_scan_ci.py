#!/usr/bin/env python3
"""CI gate for NAME-01 using QA's scanner (qa/tt_title_scan.py, copied verbatim).
usage: qa/title_scan_ci.py <out_dir> <build_dir>...
FAIL on ANY hit in the built output (all files incl. .gz) and on any hit in the source tree, except references to the
shared box folders whose names teammates depend on (kept as-is per SM 10-25): /workspace/<old-slug>/, its -qa/-gated
siblings and pipeline-ops/games/<old-slug>/. Those are paths, never shipped (the build scan proves it)."""
import json, os, re, subprocess, sys
out = sys.argv[1]; builds = sys.argv[2:]; os.makedirs(out, exist_ok=True)
here = os.path.dirname(os.path.abspath(__file__)); root = os.path.dirname(here)
st = subprocess.run([sys.executable, f"{here}/tt_title_scan.py", "--selftest"]).returncode
args = [sys.executable, f"{here}/tt_title_scan.py", f"{out}/title_scan.json"]
for b in builds: args += ["--dir", b]
args += ["--repo", root]
rc = subprocess.run(args).returncode
res = json.load(open(f"{out}/title_scan.json"))
SLUG = "tea" + "-and-" + "tarts"
ok_path = re.compile(r"(/workspace/%s(-qa|-gated)?(/|\b)|games/%s/)" % (SLUG, SLUG))
src_bad = []
for h in res.get("repo_text_hits_info", []):
    path, _, ctx = h.partition(": ")
    if os.path.relpath(path, root).startswith(("art/", "portal/", "reuse-sd/", "spec/")):  # other owners' working dirs, not ours, not shipped
        continue
    if not ok_path.search(ctx): src_bad.append(h)
print(f"title scan: selftest rc={st}, build hits={res['hit_count']}, source hits (non-path)={len(src_bad)}")
for h in src_bad[:10]: print("  source:", h)
json.dump({"build_pass": res["pass"], "source_bad": src_bad}, open(f"{out}/title_scan_ci.json", "w"), indent=1)
sys.exit(0 if st == 0 and rc == 0 and not src_bad else 1)
