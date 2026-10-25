#!/usr/bin/env bash
# Cross-process determinism: two separate headless Godot processes export the same seeds; outputs must be byte-identical
# (plus test_vectors.gd pins RNG literals + golden boards, and game_smoke checks ?seed= in the web build across reloads).
set -e; cd "$(dirname "$0")/.."
for i in 1 2; do godot --headless --path . -s tools/export_boards.gd -- size=${1:-7} seeds=0-24 band=2 out=/tmp/tt_det_$i.jsonl >/dev/null 2>&1; done
a=$(sha256sum < /tmp/tt_det_1.jsonl | cut -c1-16); b=$(sha256sum < /tmp/tt_det_2.jsonl | cut -c1-16)
echo "determinism n=${1:-7}: run1 $a run2 $b lines $(wc -l < /tmp/tt_det_1.jsonl)"; [ "$a" = "$b" ] && [ -s /tmp/tt_det_1.jsonl ] && python3 qa/tt_check.py /tmp/tt_det_1.jsonl
