#!/usr/bin/env python3
"""TT-AC-53 (SPEC v1.0.1): game code makes ZERO sendBeacon / fetch / XHR calls; only the CrazyGames SDK may beacon.
Static half (CI): greps OUR code in each export for network APIs: every script/resource in index.pck (decompressed
.gdc incl. identifiers, qa/pck_strings.py) and our HTML head glue (the part of index.html between the PKD markers /
html/head_include.html). The engine loader index.js is not ours (it fetches the game's own wasm/pck) and is not scanned.
usage: net_calls_scan.py <out_json> <build_dir>..."""
import json, os, re, sys
here = os.path.dirname(os.path.abspath(__file__)); root = os.path.dirname(here); sys.path.insert(0, here)
import pck_strings
PAT = re.compile(rb"sendBeacon|\bfetch\s*\(|XMLHttpRequest|WebSocket|EventSource|HTTPRequest|HTTPClient|StreamPeerTCP|PacketPeerUDP|WebSocketPeer")
assert all(PAT.search(x) for x in [b"navigator.sendBeacon(u)", b"fetch (url)", b"new XMLHttpRequest()", b"var h = HTTPRequest.new()"]), "selftest"
hits = []
def scan(where, b):
    for m in PAT.finditer(b):
        hits.append({"where": where, "match": m.group().decode(), "context": b[max(0, m.start() - 50): m.end() + 50].decode("utf-8", "replace")})
scan("html/head_include.html", open(f"{root}/html/head_include.html", "rb").read())
for d in sys.argv[2:]:
    html = open(f"{d}/index.html", "rb").read()
    head = html.split(b"</head>")[0]
    # only our injected head (the engine's index.html template has no network code of its own)
    scan(f"{d}/index.html<head>", head)
    _, fl = pck_strings.files(f"{d}/index.pck")
    for p, data in fl:
        if p.startswith("res://debug/"): continue   # debug-only QA tooling (incl. the TT-AC-53 runtime counter); absent from release (QA-A13 audit)
        scan(f"{d}/index.pck::{p}", pck_strings.text_of(p, data))
json.dump({"pass": not hits, "hits": hits}, open(sys.argv[1], "w"), indent=1)
print(f"net-calls scan (TT-AC-53 v1.0.1): {'PASS' if not hits else 'FAIL'}: {len(hits)} network API references in our code")
for h in hits[:10]: print("  ", h["where"], h["match"], "...", h["context"].replace("\n", " ")[:120])
sys.exit(0 if not hits else 1)
