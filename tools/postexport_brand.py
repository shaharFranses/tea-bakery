#!/usr/bin/env python3
"""Lifted from dl-web-export/postexport_brand.py. Puts brand/ files (PKD brand kit) into a Godot web export.
Optional files: brand/icon_192.png, brand/apple-touch-icon_180.png, brand/favicon.ico, brand/boot_splash_800x600.png.
Godot derives index.icon.png / index.apple-touch-icon.png from project config/icon with
its own resize; replace them with the exact integer-scaled pixel files, add favicon.ico
(linked via the preset's html/head_include), and check index.png is the brand splash."""
import os, shutil, sys, hashlib
src, out = sys.argv[1], sys.argv[2]
b = lambda n: os.path.join(src, 'brand', n)
o = lambda n: os.path.join(out, n)
if not os.path.exists(b('icon_192.png')):
    print('brand: no brand/icon_192.png, Godot icon from config/icon (brand/icon.svg) kept'); sys.exit(0)
shutil.copyfile(b('icon_192.png'), o('index.icon.png'))
shutil.copyfile(b('apple-touch-icon_180.png'), o('index.apple-touch-icon.png'))
shutil.copyfile(b('favicon.ico'), o('favicon.ico'))
html = open(o('index.html')).read()
for need in ('index.icon.png', 'index.apple-touch-icon.png'):
    assert need in html, f'{need} not referenced in index.html'
print('brand: icon/apple-touch/favicon copied')
