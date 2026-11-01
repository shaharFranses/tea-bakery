#!/usr/bin/env bash
# PKD local CI. usage: ci/run.sh [--gate] [--port N] [--slug name] [--no-build] [--live URL]
#   default : preflight, GUT tests, debug+release export (+size), release audit, serve, browser smoke
#             (boot, console-zero, 390x844 + 1280x800 + hidden-tab boot screenshots), gate packet, CURRENT_BUILD + metrics.
#   --gate  : also freeze the release build to /workspace/<slug>-gated/<sha>/ and build the CG zip (needs a clean tree).
#   --live  : live check only: live index.pck sha256 == gated sha256 + boot smoke against the URL.
# Exits non-zero on any FAIL. Results: qa/results/ci-<sha>/. Steps are resumable per sha (step-N.done).
# Full viewport x input matrix: deferred to the thin slice (CoS 2026-10-25).
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd); cd "$ROOT"
GATE=0; PORT=${PKD_PORT:-8900}; SLUG=${PKD_SLUG:-$(tr -d "[:space:]" < SLUG)};   # the ONE slug source: ./SLUG (repo/zip/gated-dir name; may become teacake-lane)
 NOBUILD=0; LIVE=""
while [ $# -gt 0 ]; do case $1 in --gate) GATE=1;; --port) PORT=$2; shift;; --slug) SLUG=$2; shift;; --no-build) NOBUILD=1;; --live) LIVE=$2; shift;; esac; shift; done
PY=${PKD_PY:-/workspace/pwvenv/bin/python}; ZPY=${PKD_ZPY:-/workspace/zvenv/bin/python};   # zvenv: zstandard for pck scripts
 GODOT=${GODOT:-godot}; export GODOT
export PKD_WORK_DIR=${PKD_WORK_DIR:-/workspace/tea-and-tarts-work}; mkdir -p "$PKD_WORK_DIR"   # never /tmp (box rollback 11-01 wiped /tmp)
export PKD_SERVE_DIR=${PKD_SERVE_DIR:-$PKD_WORK_DIR/serve}
mkdir -p build && : > build/.gdignore   # D0-05: top-level build/ never imported (before any import/export step)
export PKD_DIRTY_AT_START=$(git status --porcelain --untracked-files=no | wc -l)
SHA=$(git rev-parse --short HEAD); R="qa/results/ci-$SHA"; mkdir -p "$R"
FAILS=(); STEPS=()
step() { local n=$1 name=$2; shift 2; if [ -f "$R/step-$n.done" ] && [ "${PKD_FORCE:-0}" != 1 ]; then echo "== [$n] $name: done earlier (resume)"; STEPS+=("$name: PASS (cached)"); return 0; fi
  echo "== [$n] $name"; if "$@" > "$R/step-$n.log" 2>&1; then touch "$R/step-$n.done"; STEPS+=("$name: PASS"); tail -3 "$R/step-$n.log";
  else STEPS+=("$name: FAIL (see $R/step-$n.log)"); FAILS+=("$name"); tail -15 "$R/step-$n.log"; fi; }

if [ -n "$LIVE" ]; then
  G=$(ls -d /workspace/$SLUG-gated/$SHA 2>/dev/null || true)
  WANT=$(grep ' index.pck$' "$G/SHA256SUMS" 2>/dev/null | cut -d' ' -f1)
  GOT=$(curl -sfL "$LIVE/index.pck" | sha256sum | cut -d' ' -f1)
  echo "live pck sha256 $GOT"; echo "gated     sha256 ${WANT:-<no gated dir for $SHA>}"
  [ -n "$WANT" ] && [ "$GOT" = "$WANT" ] && echo "LIVE HASH MATCH" || { echo "LIVE HASH MISMATCH"; exit 1; }
  $PY ci/browser_smoke.py "${LIVE%/}" "$R/live" release; exit $?
fi

preflight() {
  echo "commit $SHA branch $(git branch --show-current)"; $GODOT --version
  case "$($GODOT --version)" in 4.3.*) ;; *) echo "need Godot 4.3"; return 1;; esac
  grep -q 'variant/thread_support=false' export_presets.cfg && ! grep -q 'variant/thread_support=true' export_presets.cfg || { echo "thread_support must be false"; return 1; }
  grep -q 'window/size/viewport_width=390' project.godot || { echo "base viewport must be 390x844"; return 1; }
  test -f web/.nojekyll || { echo "web/.nojekyll missing"; return 1; }
  ! grep -rn --include=*.gd 'paused = true' autoload scenes pkd_intro || { echo "lifecycle code pauses the tree"; return 1; }
  if [ $GATE = 1 ] && [ "$PKD_DIRTY_AT_START" != 0 ]; then echo "--gate needs a clean tree"; git status --short; return 1; fi
  python3 ci/no_placeholders.py CURRENT_BUILD.md DEPLOY.md || return 1
  if [ -f web/SHA256SUMS ]; then tools/verify_frozen_snapshot.sh web | tail -1 || return 1; fi   # staged Pages snapshot untouched   # D0-23: no <placeholder> text anywhere in CURRENT_BUILD.md
  echo preflight ok; }
tests() { $GODOT --headless --path "$ROOT" --import >/dev/null 2>&1; out=$($GODOT --headless --path "$ROOT" -s addons/gut/gut_cmdln.gd -gexit 2>&1); echo "$out" | sed 's/\x1b\[[0-9;]*m//g' | tail -20
  echo "$out" | grep -q 'SCRIPT ERROR' && { echo "SCRIPT ERROR counts as FAIL (SD build retro)"; return 1; }
  echo "$out" | grep -q 'All tests passed'; }
# Fresh-checkout headless import of every tracked file (no .godot cache) = what the editor / a clean clone sees. Catches
# warnings-as-errors and unicode problems GUT's runner does not surface (QA 10-25: test_tap_order Variant inference; 0xA7).
importcheck() { local T; T=$(mktemp -d "$PKD_WORK_DIR/tt_import.XXXXXX"); git ls-files -c -z | xargs -0 -I{} sh -c 'test -e "{}" && printf "%s\0" "{}"' | tar --null -T - -cf - | tar -xf - -C "$T"
  $GODOT --headless --path "$T" --import > "$R/import_check.log" 2>&1; local rc=$?
  rm -rf "$T"; echo "import rc=$rc, $(wc -l < "$R/import_check.log") log lines"
  if grep -nE 'Parse Error|SCRIPT ERROR|ERROR:|Unicode parsing error' "$R/import_check.log"; then echo "FAIL: errors in headless import"; return 1; fi
  echo "headless import clean (0 Parse Error / SCRIPT ERROR / ERROR: / Unicode parsing error)"; }
build() { tools/build_web.sh debug build/web-debug && tools/build_web.sh release build/web-release; }
audit() { $ZPY qa/release_audit.py build/web-release "$R/release_audit.txt" build/web-debug; }
serve() { tools/serve_unit.sh start build/web-debug "$PORT" && tools/serve_unit.sh start build/web-release "$((PORT+1))"; }
smoke() { $PY ci/browser_smoke.py "http://127.0.0.1:$PORT" "$R" debug; a=$?; $PY ci/browser_smoke.py "http://127.0.0.1:$((PORT+1))" "$R" release; b=$?; [ $a = 0 ] && [ $b = 0 ]; }
game_smoke() { $PY ci/game_smoke.py "http://127.0.0.1:$PORT" "$R"; }
layout() { $PY ci/layout_smoke.py "http://127.0.0.1:$PORT" "$R" qa_shots; }   # >=44 CSS px targets, >=12 px text at 390x844/800x450/1280x720
netcalls() { $ZPY qa/net_calls_scan.py "$R/net_calls_scan.json" build/web-debug build/web-release; }   # TT-AC-53 v1.0.1 static half
no_old_title() { $ZPY qa/user_text_scan.py "$R" build/web-debug build/web-release && python3 qa/title_scan_ci.py "$R" build/web-debug build/web-release; }   # SPEC §3.5 banned_user_text + QA NAME-01 scanner; source tree too
br() { $PY ci/br_smoke.py "http://127.0.0.1:$PORT" "http://127.0.0.1:$((PORT+1))" "$R"; }   # SPEC §13.1 BR-1..BR-3
release_flags() { $PY ci/release_flags_smoke.py "http://127.0.0.1:$((PORT+1))" "$R"; }
gate() { G=$(tools/freeze_gate.sh build/web-release "$SLUG" | tail -1) && echo "gated: $G" && echo "$G" > "$R/GATED_DIR" && tools/cg_zip.sh "$G" "$SLUG" && python3 tools/write_freeze.py "$G" "dist/$SLUG-cg-$SHA.zip" "$(dirname "$G")/FREEZE.md" && python3 ci/d023_check.py CURRENT_BUILD.md "$G" "$SHA" "$(dirname "$G")/FREEZE.md" pre | tee "$R/d023_check.txt"; }   # QA D0-23 checker (copy)   # D0-23: concrete sha + zip/pck md5+sha256

step 0 preflight preflight
step 1 "GUT tests" tests
step 1b "headless import of all scripts, fresh checkout (fail on Parse Error / SCRIPT ERROR / ERROR:)" importcheck
if [ $NOBUILD = 0 ]; then step 2 "web export (debug+release)" build; fi
step 3 "release audit" audit
step 4 "serve :$PORT/:$((PORT+1))" serve
step 5 "browser smoke + console-zero + screenshots" smoke
step 6 "game smoke (tutorial, taps, conflict, win, seed, 8x8 cap)" game_smoke
step 6b "responsive layout: 44px targets / 12px text at 390x844, 800x450, 1280x720" layout
step 6c "BR-1 perf lines (release+debug), BR-2 set_date/retry_daily, BR-3 set_session_s/ads_decisions" br
step 6d "TT-AC-53 (v1.0.1): no sendBeacon/fetch/XHR in our code (pck + html head)" netcalls
step 7 "banned user text absent (SPEC §3.5 + QA NAME-01) in title/pck/html/js + source" no_old_title
step 8 "release: QA URL flags inert + intro skip by tap/click/key" release_flags
[ $GATE = 1 ] && [ ${#FAILS[@]} = 0 ] && step 9 "freeze gate + CG zip" gate
VERDICT=$([ ${#FAILS[@]} = 0 ] && echo PASS || echo FAIL)
printf '%s\n' "${STEPS[@]}" > "$R/steps.txt"
$PY ci/gate_packet.py "$R" "$VERDICT" "$PORT" "$SLUG" "$GATE"
echo "CI $VERDICT: $R/GATE_PACKET.md"; [ "$VERDICT" = PASS ]
