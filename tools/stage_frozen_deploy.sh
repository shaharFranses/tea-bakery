#!/usr/bin/env bash
# usage: tools/stage_frozen_deploy.sh <gate-folder> [out_dir=web]
# Stages a QA-gated freeze for GitHub Pages BYTE-FOR-BYTE (no export, no edits): copies exactly the files listed in the
# frozen release dir's SHA256SUMS, plus SHA256SUMS itself and .nojekyll, into web/ (committed; .github/workflows/pages.yml
# uploads web/ as-is). Writes web/FROZEN_FROM.txt (gate folder, commit, pck sha256) and verifies the result.
# <gate-folder> = /workspace/tea-and-tarts-gates/day0-ed57fce (the release dir inside is the one holding SHA256SUMS).
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd); GF=$(realpath "$1"); OUT=$(realpath -m "${2:-$ROOT/web}")
REL=$(dirname "$(ls "$GF"/*/SHA256SUMS | head -1)"); SHA=$(basename "$REL")
test -f "$REL/SHA256SUMS" || { echo "no <sha>/SHA256SUMS under $GF"; exit 1; }
(cd "$REL" && sha256sum -c --quiet SHA256SUMS) || { echo "gate folder fails its own SHA256SUMS"; exit 1; }
find "$OUT" -mindepth 1 ! -name README.md -delete 2>/dev/null || true; mkdir -p "$OUT"
while read -r _ f; do cp --preserve=timestamps "$REL/$f" "$OUT/$f"; done < "$REL/SHA256SUMS"
cp "$REL/SHA256SUMS" "$OUT/SHA256SUMS"; chmod u+w "$OUT"/*; : > "$OUT/.nojekyll"; : > "$OUT/.gdignore"
PCK=$(grep ' index.pck$' "$REL/SHA256SUMS" | cut -d' ' -f1)
printf 'gate_folder=%s\ncommit=%s\npck_sha256=%s\nstaged=%s\n' "$GF" "$SHA" "$PCK" "$(date '+%Y-%m-%d %H:%M %Z')" > "$OUT/FROZEN_FROM.txt"
"$ROOT/tools/verify_frozen_snapshot.sh" "$OUT" "$PCK"
echo "staged $GF ($SHA, pck $PCK) -> $OUT; commit it with: git add -f $OUT && git commit"
