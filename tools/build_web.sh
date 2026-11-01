#!/usr/bin/env bash
# usage: tools/build_web.sh [debug|release] [out_dir]
# Godot 4.3 Web export: single-thread preset, 512MB heap patch, ?v= cache-bust, brand, build id,
# gzip -9 copies, size report (build/<variant>/SIZE.json). Lifted from dl-web-export/build_web.sh.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd); cd "$ROOT"
mkdir -p build && : > build/.gdignore   # D0-05: keep Godot from importing ANY export output under build/ (top level)
VAR=${1:-release}; OUT=$(realpath -m "${2:-build/web-$VAR}")
GODOT=${GODOT:-godot}
case $VAR in debug) PRESET="Web"; MODE=--export-debug;; release) PRESET="Web Release"; MODE=--export-release;; *) echo "variant?"; exit 2;; esac
python3 tools/sync_presets.py
rm -rf "$OUT" && mkdir -p "$OUT"
$GODOT --headless --path "$ROOT" --import >/dev/null 2>&1 || true
$GODOT --headless --path "$ROOT" $MODE "$PRESET" "$OUT/index.html" 2>&1 | grep -v '^\s*$' | tail -5
test -s "$OUT/index.wasm" && test -s "$OUT/index.pck" || { echo "export failed"; exit 1; }
python3 - "$OUT/index.js" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
assert s.count('getHeapMax=()=>2147483648') == 1, 'heap pattern not found'
open(p, 'w').write(s.replace('getHeapMax=()=>2147483648', 'getHeapMax=()=>536870912'))
print('heap patch applied (512MB)')
PY
python3 tools/postexport_brand.py "$ROOT" "$OUT"
python3 tools/postexport_cachebust.py "$OUT"
SHA=$(git rev-parse --short HEAD 2>/dev/null || echo nogit)
BID=$(grep -o "__PKD_V__ = '?v=[0-9a-f]*'" "$OUT/index.js" | grep -o '[0-9a-f]\{12\}')
python3 - "$OUT/index.html" "$SHA-$BID" <<'PY'
import sys
p, bid = sys.argv[1], sys.argv[2]; s = open(p).read()
s = s.replace('<head>', '<head>\n<script>window.__PKD_BUILD = %r;</script>' % bid, 1)
open(p, 'w').write(s); print('build id', bid)
PY
touch "$OUT/.nojekyll"; : > "$OUT/.gdignore"
gzip -9 -k -f "$OUT/index.wasm" "$OUT/index.pck"
python3 - "$OUT" "$VAR" "$SHA" "$BID" <<'PY'
import json, os, sys, hashlib
d, var, sha, bid = sys.argv[1:5]
f = {n: os.path.getsize(os.path.join(d, n)) for n in sorted(os.listdir(d)) if os.path.isfile(os.path.join(d, n))}
raw = sum(v for k, v in f.items() if not k.endswith('.gz'))
md5 = lambda n: hashlib.md5(open(os.path.join(d, n), 'rb').read()).hexdigest()
rep = {"variant": var, "commit": sha, "build_id": bid, "files": f, "total_raw_bytes": raw,
       "wasm_bytes": f.get("index.wasm"), "wasm_gz_bytes": f.get("index.wasm.gz"),
       "pck_bytes": f.get("index.pck"), "pck_gz_bytes": f.get("index.pck.gz"),
       "md5": {n: md5(n) for n in ("index.wasm", "index.pck", "index.js", "index.html")},
       "sha256": {n: hashlib.sha256(open(os.path.join(d, n), 'rb').read()).hexdigest() for n in ("index.wasm", "index.pck", "index.js", "index.html")},
       "budget_bytes": 20 * 1000 * 1000, "over_budget": raw > 20 * 1000 * 1000}
json.dump(rep, open(os.path.join(d, "SIZE.json"), "w"), indent=1)
mb = lambda b: f"{b/1e6:.2f} MB"
print(f"size: total {mb(raw)} | wasm {mb(rep['wasm_bytes'])} (gz {mb(rep['wasm_gz_bytes'])}) | pck {mb(rep['pck_bytes'])} | budget 20 MB {'OVER' if rep['over_budget'] else 'ok'}")
PY
