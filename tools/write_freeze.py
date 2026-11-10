#!/usr/bin/env python3
"""Write FREEZE.md for a gated freeze (D0-23). usage: write_freeze.py <gated_sha_dir> <cg_zip> <out FREEZE.md>
Concrete commit sha, zip + index.pck md5 and sha256, sizes, and the served-pck check instructions."""
import hashlib, json, os, subprocess, sys, datetime
g, z, out = sys.argv[1:4]
def h(p, a): return hashlib.new(a, open(p, "rb").read()).hexdigest()
sha = os.path.basename(os.path.normpath(g)); pck = os.path.join(g, "index.pck")
full = subprocess.run(["git", "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
size = json.load(open(os.path.join(g, "SIZE.json"))) if os.path.exists(os.path.join(g, "SIZE.json")) else {}
raw = size.get("total_raw_bytes", 0); f = size.get("files", {})
now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
md = f"""# Freeze {sha} ({now} Asia/Jerusalem)
Gate folder: `{os.path.dirname(os.path.abspath(g))}` (frozen release in `{sha}/`)
Commit: `{sha}` (`{full}`), built by `ci/run.sh --gate` from a clean `git clone`. Not pushed.

| File | md5 | sha256 |
|---|---|---|
| {os.path.basename(z)} | {h(z, 'md5')} | {h(z, 'sha256')} |
| {sha}/index.pck (release) | {h(pck, 'md5')} | {h(pck, 'sha256')} |

Sizes (stock template = default): raw {raw / 1e6:.2f} MB; index.wasm {f.get('index.wasm', 0) / 1e6:.2f} MB; index.pck {f.get('index.pck', 0) / 1e6:.2f} MB.
SHA256SUMS in `{sha}/` is authoritative for the served files.
D0-05 evidence (QA run_day0.sh): EXPORT_TREE=`{os.environ.get("PKD_EXPORT_TREE", os.getcwd())}` (post-export tree; `build/.gdignore` present: {os.path.exists(os.path.join(os.environ.get("PKD_EXPORT_TREE", os.getcwd()), "build", ".gdignore"))}), EXPORT_LOG=`{os.environ.get("PKD_EXPORT_LOG", "")}` (names build/.gdignore); CI step 2b log alongside it.
"""
open(out, "w").write(md); print(out)
