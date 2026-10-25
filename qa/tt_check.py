#!/usr/bin/env python3
"""Independent cross-language checker (pattern: sudoku-dash qa/sd_check.py). Shares NO code with the GDScript.
usage: qa/tt_check.py FILE...   (pack_*.json {"boards":[...]} or JSONL from tools/export_boards.gd)
Per board: regions are n patches 0..n-1 (or letters), each 4-connected; solution (col per row) has one cake per row/col/
patch and no two cakes touch (8-neighbourhood); brute-force solution count == 1 (stops at 2). Exit 1 on any failure."""
import json, sys
def load(path):
    t = open(path).read().strip()
    if t.startswith("{") and '"boards"' in t[:400]: return json.loads(t)["boards"]
    return [json.loads(l) for l in t.splitlines() if l.strip()]
def grid(e):
    n = int(e["n"]); r = e["regions"]
    if isinstance(r[0], str): r = [ord(ch) - 97 for row in r for ch in row]
    return n, [int(x) for x in r]
def connected(n, reg):
    for g in range(n):
        cells = [i for i in range(n * n) if reg[i] == g]
        if not cells: return False
        seen = {cells[0]}; st = [cells[0]]
        while st:
            i = st.pop(); r, c = divmod(i, n)
            for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                rr, cc = r + dr, c + dc
                j = rr * n + cc
                if 0 <= rr < n and 0 <= cc < n and reg[j] == g and j not in seen: seen.add(j); st.append(j)
        if len(seen) != len(cells): return False
    return True
def valid(n, reg, sol):
    if len(sol) != n or sorted(sol) != list(range(n)): return "row/col"
    if sorted(reg[r * n + sol[r]] for r in range(n)) != list(range(n)): return "patch"
    for r in range(n - 1):
        if abs(sol[r] - sol[r + 1]) <= 1: return f"touch rows {r},{r+1}"
    return None
def count(n, reg, cap=2):
    found = 0; usedc = [False] * n; usedg = [False] * n
    def go(r, prev):
        nonlocal found
        if r == n: found += 1; return found >= cap
        for c in range(n):
            g = reg[r * n + c]
            if usedc[c] or usedg[g] or (prev >= 0 and abs(c - prev) <= 1): continue
            usedc[c] = usedg[g] = True
            if go(r + 1, c): return True
            usedc[c] = usedg[g] = False
        return False
    go(0, -1); return found
bad = 0; total = 0
for f in sys.argv[1:]:
    for e in load(f):
        total += 1; n, reg = grid(e); sol = [int(x) for x in e["solution"]]; tag = e.get("id", f"{f}:n{n}s{e.get('seed')}")
        errs = []
        if len(reg) != n * n or sorted(set(reg)) != list(range(n)) or not connected(n, reg): errs.append("regions")
        v = valid(n, reg, sol)
        if v: errs.append("solution " + v)
        k = count(n, reg)
        if k != 1: errs.append(f"count={k}")
        if errs: bad += 1; print("FAIL", tag, errs)
print(f"tt_check: {total - bad}/{total} boards OK in {len(sys.argv) - 1} files")
sys.exit(1 if bad or not total else 0)
