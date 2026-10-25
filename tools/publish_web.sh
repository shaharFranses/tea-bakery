#!/usr/bin/env bash
# usage: tools/publish_web.sh <gated_dir>  -> replaces web/ with the frozen gated build (QA-PASSed hash).
# Commit web/ and push; .github/workflows/pages.yml uploads web/ as-is (no re-export).
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd); G=$(realpath "$1")
(cd "$G" && sha256sum -c --quiet SHA256SUMS) || { echo "gated dir hash mismatch"; exit 1; }
find "$ROOT/web" -mindepth 1 ! -name README.md -delete 2>/dev/null || true; mkdir -p "$ROOT/web"
cp -a "$G"/. "$ROOT/web"/; chmod -R u+w "$ROOT/web"; rm -f "$ROOT/web/"*.gz
touch "$ROOT/web/.nojekyll"; : > "$ROOT/web/.gdignore"
echo "web/ <- $G ($(grep index.pck "$G/SHA256SUMS" | cut -c1-16)...)"
