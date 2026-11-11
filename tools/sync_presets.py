#!/usr/bin/env python3
"""Writes export_presets.cfg from html/head_include.html (single source for the page glue).
Presets: "Web" (debug, QA hooks) and "Web Release" (debug/ tests/ tools/ qa/ ci/ addons/gut excluded).
Both: thread_support=false, extensions_support=false (Playbook D0-07).
Release uses the PKD slim template when engine/pkd_web_release_slim.zip exists (PKD_STOCK=1 forces stock)."""
import json, os, sys
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
head = open(os.path.join(root, "html", "head_include.html")).read()
# ASCII only: json.dumps escapes non-ASCII as \uXXXX and Godot 4.3's cfg parser mangles it at import
# ("Unicode parsing error ... leading byte (a7)" from a section sign); CI step 1b catches any recurrence.
assert head.isascii(), "html/head_include.html must be ASCII-only: " + repr(sorted({c for c in head if not c.isascii()}))
slim = os.path.join(root, "engine", "pkd_web_release_slim.zip")
rel_tpl = slim if (os.path.exists(slim) and os.environ.get("PKD_STOCK") != "1") else ""
# PKD_SLIM=1: Pipeline Ops' prebuilt slim template (not the default until QA passes a slim build). Never built here.
PO_SLIM = "/workspace/pipeline-ops/engine-templates/godot-4.3-web-slim/web_nothreads_release.zip"
PO_SLIM_SHA256 = "0572db172ec58a3abeef1a3e17aec6ef14fca6a8e597799febdc8e65efa52e75"
if os.environ.get("PKD_SLIM") == "1":
    import hashlib
    rel_tpl = os.environ.get("PKD_SLIM_TEMPLATE", PO_SLIM)
    got = hashlib.sha256(open(rel_tpl, "rb").read()).hexdigest()
    want = os.environ.get("PKD_SLIM_SHA256", PO_SLIM_SHA256)
    assert got == want, f"slim template sha256 {got} != {want}"
    print("slim template sha256 ok:", got)
dbg_tpl = os.environ.get("PKD_DEBUG_TEMPLATE", "")
q = lambda s: json.dumps(s)  # Godot cfg strings accept JSON-style escapes
EXC = "tests/*, tools/*, qa/*, ci/*, addons/gut/*, build/*, web/*, engine/*, metrics/*, docs/*, spec/*, *.md, art/*, portal/*, data/*, qa_shots/*, reuse-sd/*"   # data/ = test vectors + synced spec lists (tests/CI only)
# Art ships 1x + @2x; the game loads only @2x (art/HANDOFF_GODOT.md), so the 1x PNGs stay out of the pck.
import glob
ONE_X = sorted(os.path.relpath(f, root) for f in glob.glob(os.path.join(root, "assets", "**", "*.png"), recursive=True) if "@2x" not in f)
# SPEC v1.2 (D-03 revised): every cake_*@2x is a shipped piece (one per chapter + chocolate daily + berry debug), so
# none is excluded any more. (SM ruling 2026-11-01 had kept the 8 non-berry cakes out of the pck while berry was the
# only v1 cake; that exclusion made the exported game fail to load them.) tests/test_export_presets.gd guards this.
SHIPPED_CAKES = ["berry", "scone", "victoria", "lemon", "apricot", "bakewell", "custard", "macaron", "chocolate"]
EXTRA_CAKES = sorted(os.path.relpath(f, root) for f in glob.glob(os.path.join(root, "assets", "board", "cake_*@2x.png"))
                     if os.path.basename(f)[len("cake_"):-len("@2x.png")] not in SHIPPED_CAKES)
EXC = EXC + ", assets/backdrop/README.txt" + "".join(", " + f for f in ONE_X + EXTRA_CAKES)
def preset(i, name, path, excl, release_tpl, debug_tpl):
    return f'''[preset.{i}]

name="{name}"
platform="Web"
runnable={"true" if i == 0 else "false"}
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter="{excl}"
export_path="{path}"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.{i}.options]

custom_template/debug={q(debug_tpl)}
custom_template/release={q(release_tpl)}
variant/extensions_support=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/export_icon=true
html/custom_html_shell=""
html/head_include={q(head)}
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
html/experimental_virtual_keyboard=false
progressive_web_app/enabled=false
'''
out = preset(0, "Web", "build/web/index.html", EXC, rel_tpl, dbg_tpl) + "\n" + \
      preset(1, "Web Release", "build/web-release/index.html", EXC + ", debug/*", rel_tpl, dbg_tpl)
open(os.path.join(root, "export_presets.cfg"), "w").write(out)
print("export_presets.cfg written; release template:", rel_tpl or "stock")
