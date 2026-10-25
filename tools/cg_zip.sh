#!/usr/bin/env bash
# usage: tools/cg_zip.sh <build_dir> [game_slug]  ->  dist/<slug>-cg-<sha>.zip (+ .md5, .listing.txt)
# CrazyGames layout: index.html at the zip root, no .gz duplicates, no dotfiles. (FF retro: zip was hand-built.)
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SRC=$(realpath "$1"); SLUG=${2:-$(basename "$ROOT")}
SHA=$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo nogit)
mkdir -p "$ROOT/dist"; Z="$ROOT/dist/$SLUG-cg-$SHA.zip"; rm -f "$Z"
test -f "$SRC/index.html" || { echo "no index.html in $SRC"; exit 1; }
python3 - "$SRC" "$Z" <<'PY'
import os, sys, zipfile
src, z = sys.argv[1:3]
with zipfile.ZipFile(z, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as f:
    for n in sorted(os.listdir(src)):
        p = os.path.join(src, n)
        if os.path.isfile(p) and not n.startswith('.') and not n.endswith('.gz') and n not in ('SIZE.json', 'SHA256SUMS'):
            f.write(p, n)
PY
md5sum "$Z" | cut -d' ' -f1 > "$Z.md5"
python3 -c "import zipfile,sys; z=zipfile.ZipFile(sys.argv[1]); [print(f'{i.file_size:>10} {i.filename}') for i in z.infolist()]; assert 'index.html' in z.namelist()" "$Z" > "$Z.listing.txt"
echo "cg zip: $Z  $(stat -c %s "$Z") B  md5 $(cat "$Z.md5")"; cat "$Z.listing.txt"
