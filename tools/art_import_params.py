#!/usr/bin/env python3
"""Applies Art's import table (art/HANDOFF_GODOT.md, "Import settings (all drops)") to every assets/**/*.png|webp .import.
Sprites: Lossless, mipmaps ON, fix alpha border. 9-slices (tray_frame*, btn_*, panel_*, chip_honey, coach_bubble):
Lossless, mipmaps OFF. Backdrops (.webp): Lossy (keeps the source webp quality), mipmaps OFF.
usage: tools/art_import_params.py [--check]   (--check: exit 1 if any file differs; used by tests/CI)"""
import glob, os, re, sys
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NINE = re.compile(r"^(tray_frame|btn_|panel_|chip_honey|coach_bubble)")
def want(path):
    base = os.path.basename(path)[:-len(".import")]
    if base.endswith(".webp"): return {"compress/mode": "1", "compress/lossy_quality": "0.82", "mipmaps/generate": "false"}
    return {"compress/mode": "0", "mipmaps/generate": "false" if NINE.match(base) else "true", "process/fix_alpha_border": "true",
            "process/premult_alpha": "false"}
bad = 0
for p in sorted(glob.glob(os.path.join(root, "assets", "**", "*.import"), recursive=True)):
    if not p.endswith((".png.import", ".webp.import")): continue
    s = open(p).read(); t = s
    for k, v in want(p).items():
        t, n = re.subn(r"(?m)^%s=.*$" % re.escape(k), f"{k}={v}", t)
        if n != 1: sys.exit(f"{p}: key {k} not found")
    if t != s:
        bad += 1
        if "--check" not in sys.argv: open(p, "w").write(t)
print(("differ: %d" if "--check" in sys.argv else "updated: %d") % bad)
sys.exit(1 if bad and "--check" in sys.argv else 0)
