#!/usr/bin/env bash
# usage: tools/freeze_gate.sh <build_dir> [game_slug] -> /workspace/<slug>-gated/<sha>/ with SHA256SUMS (read-only)
# Gate rule: QA tests this frozen dir; Pages serves a copy of it (tools/publish_web.sh). Never re-export after a gate.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd); SRC=$(realpath "$1"); SLUG=${2:-$(tr -d "[:space:]" < "$ROOT/SLUG")}   # default: ./SLUG (never the folder name)
SHA=$(git -C "$ROOT" rev-parse --short HEAD)
G=${PKD_GATED_ROOT:-/workspace/$SLUG-gated}/$SHA
if [ -d "$G" ]; then echo "already frozen: $G (not overwriting)"; else
  mkdir -p "$G"; cp -a "$SRC"/. "$G"/; (cd "$G" && sha256sum $(ls index.* | grep -v "\.gz$") > SHA256SUMS); chmod -R a-w "$G"; fi
echo "$G"
