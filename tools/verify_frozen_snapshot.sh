#!/usr/bin/env bash
# usage: tools/verify_frozen_snapshot.sh [dir=web] [expected_pck_sha256]
# Re-computes the sha256 of EVERY file in the snapshot against its SHA256SUMS; fails on any mismatch, any listed file
# missing, or any extra served file not in SHA256SUMS (only README.md, FROZEN_FROM.txt, SHA256SUMS, .nojekyll, .gdignore
# are allowed extras). Optional 2nd arg: the pck sha256 that must be deployed. Used locally and by pages.yml.
set -euo pipefail
D=${1:-web}; WANT=${2:-}
cd "$D"; test -s SHA256SUMS || { echo "FAIL: no SHA256SUMS in $D"; exit 1; }
sha256sum -c --strict SHA256SUMS || { echo "FAIL: sha256 mismatch"; exit 1; }
EXTRA=$(find . -type f ! -name README.md ! -name FROZEN_FROM.txt ! -name SHA256SUMS ! -name .nojekyll ! -name .gdignore -printf '%P\n' | sort | comm -23 - <(awk '{print $2}' SHA256SUMS | sort))
[ -z "$EXTRA" ] || { echo "FAIL: files not in SHA256SUMS: $EXTRA"; exit 1; }
GOT=$(sha256sum index.pck | cut -d' ' -f1)
if [ -n "$WANT" ] && [ "$GOT" != "$WANT" ]; then echo "FAIL: index.pck $GOT != expected $WANT"; exit 1; fi
echo "PASS: $(wc -l < SHA256SUMS) files match SHA256SUMS, no extras; index.pck sha256 $GOT"
