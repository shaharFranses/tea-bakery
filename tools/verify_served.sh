#!/usr/bin/env bash
# usage: tools/verify_served.sh <url> [expected_pck_sha256 | dir with SHA256SUMS (default web)]
# Post-deploy check: fetches <url>/index.pck (cache-busted) and compares its sha256 with the frozen one; also checks
# index.html/index.js/index.wasm against SHA256SUMS when a dir is given. Exit 0 = served bytes are the gated bytes.
set -euo pipefail
U=${1%/}; REF=${2:-web}; BUST="nocache=$(date +%s)"
if [ -f "$REF/SHA256SUMS" ]; then SUMS="$REF/SHA256SUMS"; WANT=$(grep ' index.pck$' "$SUMS" | cut -d' ' -f1); else SUMS=""; WANT=$REF; fi
fail=0
GOT=$(curl -sfL "$U/index.pck?$BUST" | sha256sum | cut -d' ' -f1)
echo "index.pck served $GOT"; echo "index.pck frozen $WANT"; [ "$GOT" = "$WANT" ] || fail=1
if [ -n "$SUMS" ]; then for f in index.html index.js index.wasm; do
  w=$(grep " $f\$" "$SUMS" | cut -d' ' -f1); g=$(curl -sfL "$U/$f?$BUST" | sha256sum | cut -d' ' -f1)
  [ "$w" = "$g" ] && echo "$f MATCH" || { echo "$f MISMATCH ($g)"; fail=1; }; done; fi
[ $fail = 0 ] && echo "SERVED == FROZEN" || { echo "SERVED != FROZEN"; exit 1; }
