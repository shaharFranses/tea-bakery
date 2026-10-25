#!/usr/bin/env python3
"""Release audit (QA-A13 / D0-18). Lists the Web Release pck, fails if debug/test/tool files shipped or any hook string
appears in the release pck (decompressed .gdc incl. identifiers, via qa/pck_strings.py), index.js or index.html.
Control: the same patterns must be FOUND in the debug build (proves the grep works).
usage: release_audit.py <release_dir> [report.txt] [debug_dir]"""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pck_strings
d = sys.argv[1]; rep = sys.argv[2] if len(sys.argv) > 2 else None; dbg = sys.argv[3] if len(sys.argv) > 3 else None
BAD_PATH = re.compile(r"res://(debug|tests|tools|qa|ci|addons/gut|build|web|engine|metrics)/")
# QA_TEST_PLAN v0.4 QA-A13 list + starter's + BR-2/BR-3 hook commands
HOOKS = ["PKD_QA", "__pkdDump", "QA hooks enabled", "qa_hooks", "ads_mock", "mock_available", "mock_unavailable", "mock_error",
         "mock_timeout", "qa_state", "qa_show", "session_offset_s", "solve_next", "seed_sweep", "validate_boards", "gut_cmdln",
         "force_daily_complete", "tt_qa_game", "set_date", "retry_daily", "set_session_s", "ads_decisions"]   # + QA v0.6 BR-2/BR-3
PAT = re.compile("|".join(re.escape(h) for h in HOOKS).encode())
def scan(dirn):
    ver, fl = pck_strings.files(f"{dirn}/index.pck"); hits = {}
    for p, data in fl:
        for m in PAT.finditer(pck_strings.text_of(p, data)): hits[f"pck:{p}:{m.group().decode()}"] = hits.get(f"pck:{p}:{m.group().decode()}", 0) + 1
    for f in ("index.js", "index.html"):
        for m in PAT.finditer(open(f"{dirn}/{f}", "rb").read()): hits[f"{f}:{m.group().decode()}"] = hits.get(f"{f}:{m.group().decode()}", 0) + 1
    return ver, fl, hits
ver, fl, hits = scan(d)
bad = [p for p, _ in fl if BAD_PATH.match(p)]
lines = [f"pck engine {ver[0]}.{ver[1]}.{ver[2]}: {len(fl)} files"] + [f"{len(x):>10} {p}" for p, x in fl]
lines += ["## forbidden paths in release pck: " + (", ".join(bad) or "(none)"), "## hook strings (release): " + (str(hits) if hits else "(none)")]
ctrl_ok = True
if dbg and os.path.exists(f"{dbg}/index.pck"):
    _, _, ch = scan(dbg); found = sorted({k.rsplit(":", 1)[1] for k in ch})
    ctrl_ok = len(found) >= 5
    lines.append(f"## control (debug build {dbg}): {len(found)} distinct hook strings found: {found}")
if rep: open(rep, "w").write("\n".join(lines) + "\n")
ok = not bad and not hits and ctrl_ok
print(f"release audit: {'PASS' if ok else 'FAIL'} ({len(fl)} files; forbidden {len(bad)}; hook hits {len(hits)}; control {'ok' if ctrl_ok else 'FAILED'})")
for k in list(hits)[:10]: print("  ", k)
sys.exit(0 if ok else 1)
