#!/usr/bin/env python3
"""Writes export_presets.cfg from html/head_include.html (single source for the page glue).
Presets: "Web" (debug, QA hooks) and "Web Release" (debug/ tests/ tools/ qa/ ci/ addons/gut excluded).
Both: thread_support=false, extensions_support=false (Playbook D0-07).
Release uses the PKD slim template when engine/pkd_web_release_slim.zip exists (PKD_STOCK=1 forces stock)."""
import json, os, sys
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
head = open(os.path.join(root, "html", "head_include.html")).read()
slim = os.path.join(root, "engine", "pkd_web_release_slim.zip")
rel_tpl = slim if (os.path.exists(slim) and os.environ.get("PKD_STOCK") != "1") else ""
dbg_tpl = os.environ.get("PKD_DEBUG_TEMPLATE", "")
q = lambda s: json.dumps(s)  # Godot cfg strings accept JSON-style escapes
EXC = "tests/*, tools/*, qa/*, ci/*, addons/gut/*, build/*, web/*, engine/*, metrics/*, docs/*, spec/*, *.md"
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
