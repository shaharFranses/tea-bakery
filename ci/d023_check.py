# COPY of /workspace/tea-and-tarts-qa/d023_check.py (QA-owned; md5 48e95da8ccd90313df32cf843f926d6b, copied 2026-11-01). Do not edit here; re-copy from QA.
"""D0-23 (SM 11-01 + SM 12:00): CURRENT_BUILD.md rows in scope must be filled.
usage: d023_check.py CURRENT_BUILD.md GATED_DIR SHA FREEZE.md SCOPE(pre|all) -> prints 'PASS|FAIL <detail>', exit 0/1.
A row passes with a concrete value OR an explicit 'see FREEZE.md' pointer (no <placeholder>), provided FREEZE.md holds the
concrete value and it matches the gated artefacts. Checked values: commit sha, index.pck sha256, gate folder. Release size row:
stated MB within 10% of SIZE.json total_raw_bytes (else FAIL)."""
import hashlib, json, os, re, sys
cb, G, SHA, FZ, scope = sys.argv[1:6]
POST = re.compile(r"^\| *(Pages URL|Live |Shahar phone|CG zip|Submission|QA verdict)")
PH = re.compile(r"<[A-Za-z][A-Za-z0-9 |/_.-]*>|\{\{[A-Z_]+\}\}")
SEE = re.compile(r"see\s+`?FREEZE\.md`?", re.I)
rows = [l for l in open(cb).read().splitlines() if l.startswith("|") and not l.startswith("|---")]
rows = [l for l in rows if scope == "all" or not POST.search(l)]
fz = open(FZ).read() if os.path.exists(FZ) else ""
pck = hashlib.sha256(open(os.path.join(G, "index.pck"), "rb").read()).hexdigest()
folder = os.path.dirname(os.path.abspath(G)).rstrip("/")
raw = json.load(open(os.path.join(G, "SIZE.json"))).get("total_raw_bytes") or sum(os.path.getsize(os.path.join(G, f)) for f in os.listdir(G) if not f.endswith(".gz"))
fails, notes = [], []
def cells(l): c = [x.strip() for x in l.strip().strip("|").split("|")]; return c[0], " | ".join(c[1:])
def value_ok(key, val, need):   # need(text)->bool on concrete values
    if PH.search(val): return f"{key}: <placeholder> syntax"
    if need(val): return None
    if SEE.search(val):
        if not fz: return f"{key}: points to FREEZE.md but {FZ} missing"
        return None if need(fz) else f"{key}: points to FREEZE.md but FREEZE.md lacks the matching value"
    return f"{key}: no concrete matching value and no 'see FREEZE.md' pointer"
for l in rows:
    k, v = cells(l); kl = k.lower()
    if kl in ("field",): continue
    if kl.startswith("commit"): e = value_ok(k, v, lambda t: re.search(rf"\b{SHA[:7]}", t) is not None)
    elif "pck sha256" in kl: e = value_ok(k, v, lambda t: pck in t or (pck[:8] in t and pck[-4:] in t))
    elif kl.startswith("gate folder"): e = value_ok(k, v, lambda t: folder in t or folder + "/" in t)
    elif kl.startswith("release size"):
        m = re.search(r"(\d+(?:\.\d+)?)\s*MB", v)
        if PH.search(v): e = f"{k}: <placeholder> syntax"
        elif not m: e = value_ok(k, v, lambda t: False) if not SEE.search(v) else (None if re.search(rf"{raw/1e6:.2f}", fz) else f"{k}: FREEZE.md lacks {raw/1e6:.2f} MB")
        else:
            st = float(m.group(1)); act = raw / 1e6; dev = abs(st - act) / act
            e = None if dev <= 0.10 else f"{k}: states {st} MB vs actual {act:.2f} MB ({dev:.1%} > 10%)"
            notes.append(f"size {st} vs {act:.2f} MB ({dev:.1%})")
    else: e = f"{k}: <placeholder> syntax" if PH.search(v) else None
    if e: fails.append(e)
print(("FAIL " if fails else "PASS ") + f"[{scope} rows; sha {SHA[:7]}, pck {pck[:8]}…, folder {folder}; {'; '.join(notes)}] " + "; ".join(fails))
sys.exit(1 if fails else 0)
