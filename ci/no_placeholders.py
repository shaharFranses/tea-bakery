#!/usr/bin/env python3
"""D0-23: fail if a file contains placeholder text like <sha>, <md5>, <yes/no, ...>, <PASS/FAIL, date>.
HTML comments (<!-- ... -->) are allowed. usage: no_placeholders.py FILE... ; --selftest"""
import re, sys
PAT = re.compile(r"<(?!!--)[A-Za-z][^<>\n]*>")
def hits(text): return [m.group(0) for m in PAT.finditer(text)]
if sys.argv[1:] == ["--selftest"]:
    assert hits("x `<sha>` y") == ["`<sha>`"[1:-1]] and hits("<yes/no, checked date>") and hits("<!-- ci:begin -->") == []
    print("selftest ok"); sys.exit(0)
bad = 0
for f in sys.argv[1:]:
    for i, line in enumerate(open(f, encoding="utf-8"), 1):
        for h in hits(line): print(f"{f}:{i}: placeholder {h}"); bad += 1
print(f"placeholder check: {'FAIL' if bad else 'PASS'} ({bad} hits)"); sys.exit(1 if bad else 0)
