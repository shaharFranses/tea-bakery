#!/usr/bin/env python3
"""Lifted from dl-web-export/postexport_cachebust.py.
Cache-bust a Godot 4.3 web export in place: versions index.js, index.wasm,
index.pck and index.audio.worklet.js with ?v=<build id>.

Run once on a fresh export (after the heap patch). The build id is a hash of
the exported wasm, pck and (unpatched) js, so it changes whenever the game does.
The pck keeps its virtual-FS name (index.pck), so --main-pack and the
fileSizes keys are untouched; only the fetch URLs gain the query string.
"""
import hashlib, os, sys

d = sys.argv[1] if len(sys.argv) > 1 else '.'
p = lambda n: os.path.join(d, n)
js, html = open(p('index.js')).read(), open(p('index.html')).read()
if '__PKD_V__' in js or 'index.js?v=' in html:
    sys.exit('already cache-busted; re-export first')

h = hashlib.sha256()
for n in ('index.wasm', 'index.pck'):
    h.update(open(p(n), 'rb').read())
h.update(js.encode())
bid = h.hexdigest()[:12]

def sub(s, old, new):
    assert s.count(old) == 1, f'expected exactly one {old!r}'
    return s.replace(old, new)

js = sub(js, "const Engine = (function () {", "const __PKD_V__ = '?v=%s';\nconst Engine = (function () {" % bid)
js = sub(js, "loadPromise = preloader.loadPromise(`${loadPath}.wasm`, size, true);",
         "loadPromise = preloader.loadPromise(`${loadPath}.wasm${__PKD_V__}`, size, true);")
js = sub(js, "return `${loadPath}.audio.worklet.js`;", "return `${loadPath}.audio.worklet.js${__PKD_V__}`;")
js = sub(js, "this.preloadFile(pack, pack),", "this.preloadFile(`${pack}${__PKD_V__}`, pack),")
html = sub(html, '<script src="index.js"></script>', '<script src="index.js?v=%s"></script>' % bid)
open(p('index.js'), 'w').write(js)
open(p('index.html'), 'w').write(html)
print('cache-bust build id', bid)
