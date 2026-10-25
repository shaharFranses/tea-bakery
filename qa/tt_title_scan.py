#!/usr/bin/env python3
# COPIED VERBATIM from QA: /workspace/tea-and-tarts-qa/tt_title_scan.py (sha256 60155994347a050e, 2026-10-25). Do not edit here; re-copy when QA updates it.
"""NAME-01 (QA-A10): the title 'Tea & Tarts' is dropped (trademark risk; working name 'tea-bakery').
SM ruling 2026-10-25: FAIL only on the OLD TITLE / BRANDING strings, case-insensitive: 'Tea & Tarts' (incl. '&amp;'),
'Tea and Tarts', 'teaandtarts', 'tea-and-tarts' (separators space/_/- and none are all matched, e.g. 'Tea&Tarts', 'tea_and_tarts').
Plain 'tarts' is ALLOWED (e.g. the ch4 recipe card 'Jam tarts').
usage: tt_title_scan.py <out_json> [--dir D]... [--zip Z]... [--shots DIR]... [--live URL] [--repo R]
       tt_title_scan.py --selftest        (exit 0 iff the regex passes 'Jam tarts' and fails each banned string)
  --dir   build dir: index.html <title>/meta + raw strings in every file (pck, js, wasm, html, .gz decompressed)
  --zip   CG zip: member names + contents
  --shots dir of PNG screenshots: tesseract OCR of each (boot / intro / menu / mobile)
  --live  Pages URL: the URL itself, live index.html (<title>, meta, og tags) and live index.pck/js strings
  --repo  INFO only: user-facing text files in the repo (not built output)"""
import gzip, io, json, os, re, subprocess, sys, urllib.request, zipfile
PAT = re.compile(rb"tea[\s_\-]*(?:&amp;|&|and)[\s_\-]*tarts", re.I)
def selftest():
    must_fail = ["Tea & Tarts", "tea &amp; tarts", "Tea and Tarts", "TEA AND TARTS", "teaandtarts", "TeaAndTarts",
                 "tea-and-tarts", "https://shaharfranses.github.io/tea-and-tarts/", "tea_and_tarts", "Tea&Tarts"]
    must_pass = ["Jam tarts", "Jam Tarts", "tarts", "Tarts on a tray", "tea-bakery", "tea party with jam tarts",
                 "Tea time: tarts", "https://shaharfranses.github.io/tea-bakery/"]
    bad = [f"should FAIL but passed: {t!r}" for t in must_fail if not PAT.search(t.encode())]
    bad += [f"should PASS but failed: {t!r}" for t in must_pass if PAT.search(t.encode())]
    print("NAME-01 selftest " + ("PASS" if not bad else "FAIL") + f" ({len(must_fail)} banned, {len(must_pass)} allowed)")
    for b in bad: print("  " + b)
    sys.exit(0 if not bad else 1)
if len(sys.argv) > 1 and sys.argv[1] == "--selftest": selftest()
args = sys.argv[2:]; out = sys.argv[1]
def opt(k): return [args[i + 1] for i, a in enumerate(args) if a == k]
hits, info, scanned = [], [], []
def scan_bytes(where, b, cat):
    for m in PAT.finditer(b):
        ctx = b[max(0, m.start() - 40): m.end() + 40].decode("utf-8", "replace").replace("\n", " ")
        hits.append({"where": where, "category": cat, "match": m.group().decode("utf-8", "replace"), "context": ctx})
        if sum(1 for h in hits if h["where"] == where) >= 20: break
def html_meta(where, b):
    s = b.decode("utf-8", "replace"); t = re.search(r"<title>(.*?)</title>", s, re.S | re.I)
    metas = re.findall(r"<meta[^>]+>", s, re.I)
    info.append({"where": where, "title": t.group(1).strip() if t else None, "meta_with_content": [m for m in metas if "content=" in m][:12]})
for d in opt("--dir"):
    for f in sorted(os.listdir(d)):
        p = os.path.join(d, f)
        if not os.path.isfile(p): continue
        b = open(p, "rb").read()
        if f.endswith(".gz"): b = gzip.decompress(b)
        scanned.append(p); scan_bytes(p, b, "build-file")
        if f == "index.html": html_meta(p, b)
for z in opt("--zip"):
    zf = zipfile.ZipFile(z); scanned.append(z)
    for n in zf.namelist():
        scan_bytes(f"{z}::{n} (name)", n.encode(), "zip-member-name"); scan_bytes(f"{z}::{n}", zf.read(n), "zip-content")
    scan_bytes(f"{z} (zip file name)", os.path.basename(z).encode(), "zip-file-name")
for sd in opt("--shots"):
    for root, _, files in os.walk(sd):
        for f in sorted(files):
            if not f.endswith(".png"): continue
            p = os.path.join(root, f); txt = subprocess.run(["tesseract", p, "-", "--psm", "11"], capture_output=True, text=True).stdout
            scanned.append(p); scan_bytes(p, txt.encode(), "ocr-screenshot")
for u in opt("--live"):
    u = u.rstrip("/") + "/"; scan_bytes(f"{u} (URL)", u.encode(), "live-url-slug")
    for f in ("index.html", "index.js", "index.pck"):
        try: b = urllib.request.urlopen(urllib.request.Request(u + f + "?qa_nocache=1", headers={"Cache-Control": "no-cache"}), timeout=120).read()
        except Exception as e: hits.append({"where": u + f, "category": "live-fetch-error", "match": "", "context": str(e)}); continue
        scanned.append(u + f); scan_bytes(u + f, b, "live-page" if f == "index.html" else "live-build-file")
        if f == "index.html": html_meta(u + f, b)
repo_hits = []
for r in opt("--repo"):
    for root, dirs, files in os.walk(r):
        dirs[:] = [x for x in dirs if x not in (".git", ".godot", "build", "qa", "addons", "node_modules")]
        for f in files:
            if f.endswith((".md", ".cfg", ".godot", ".tscn", ".gd", ".html", ".json", ".txt")):
                p = os.path.join(root, f)
                try: b = open(p, "rb").read()
                except Exception: continue
                for m in PAT.finditer(b): repo_hits.append(f"{p}: {b[max(0, m.start()-30):m.end()+30].decode('utf-8','replace')!r}"); break
res = {"check": "NAME-01 no old title/branding ('Tea & Tarts', 'Tea and Tarts', 'teaandtarts', 'tea-and-tarts'); plain 'tarts' allowed", "pass": not hits, "hits": hits, "hit_count": len(hits),
       "by_category": {c: sum(1 for h in hits if h["category"] == c) for c in sorted({h["category"] for h in hits})},
       "html_meta": info, "scanned": len(scanned), "repo_text_hits_info": repo_hits[:50]}
json.dump(res, open(out, "w"), indent=1)
print(f"NAME-01 {'PASS' if not hits else 'FAIL'}: {len(hits)} hits {res['by_category']} in {len(scanned)} files/pages/screenshots; repo text hits (info) {len(repo_hits)}")
for h in hits[:8]: print(f"  {h['category']}: {h['where']}: ...{h['context']}...")
sys.exit(0 if not hits else 1)
