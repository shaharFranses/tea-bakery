#!/usr/bin/env python3
"""Release audit (adapted from sudoko_dash qa/release_audit.sh): lists the Web Release pck directory and fails if
debug/test/tool files or QA hook strings shipped. usage: release_audit.py <release_build_dir> [report.txt]"""
import re, struct, sys
d = sys.argv[1]; rep = sys.argv[2] if len(sys.argv) > 2 else None
b = open(f"{d}/index.pck", "rb").read()
assert b[:4] == b"GDPC", "not a Godot pck"
o = 4; ver, ma, mi, pa, flags = struct.unpack_from("<5I", b, o); o += 20; base = struct.unpack_from("<Q", b, o)[0]; o += 8 + 64
n = struct.unpack_from("<I", b, o)[0]; o += 4; files = []
for _ in range(n):
    l = struct.unpack_from("<I", b, o)[0]; o += 4; p = b[o:o + l].rstrip(b"\0").decode(); o += l
    off, sz = struct.unpack_from("<QQ", b, o); o += 16 + 16 + 4; files.append((p, sz))
BAD_PATH = re.compile(r"res://(debug|tests|tools|qa|ci|addons/gut|build|web|engine|metrics)/")
HOOKS = [b"PKD_QA", b"__pkdDump", b"QA hooks enabled", b"qa_hooks", b"ads_mock"]
bad = [p for p, _ in files if BAD_PATH.match(p)]
hits = {}
for f in ("index.pck", "index.js", "index.html"):
    raw = open(f"{d}/{f}", "rb").read()
    for h in HOOKS:
        c = raw.count(h)
        if c: hits[f"{f}:{h.decode()}"] = c
lines = [f"pck v{ver} engine {ma}.{mi}.{pa}: {n} files"] + [f"{sz:>10} {p}" for p, sz in files]
lines += ["## forbidden paths in release pck: " + (", ".join(bad) or "(none)"), "## hook strings: " + (str(hits) or "(none)")]
if rep: open(rep, "w").write("\n".join(lines) + "\n")
ok = not bad and not hits
print(f"release audit: {'PASS' if ok else 'FAIL'} ({n} files; forbidden {len(bad)}; hook hits {len(hits)})")
sys.exit(0 if ok else 1)
