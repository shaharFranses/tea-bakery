#!/usr/bin/env bash
# usage: tools/serve_unit.sh start <dir> <port> | stop <port> | status <port>
# Persistent static server for gate ports: setsid + a watchdog loop restarts it if it dies.
# (Box restarts kill plain http.server; rerun `start` after a restart: ci/run.sh does this.)
# Serves .wasm as application/wasm and .gz with Content-Encoding off (plain files).
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd); CMD=$1
PIDDIR=${PKD_SERVE_DIR:-${PKD_WORK_DIR:-/workspace/tea-and-tarts-work}/serve}; mkdir -p "$PIDDIR"
case $CMD in
start) DIR=$(realpath "$2"); PORT=$3
  "$0" stop "$PORT" >/dev/null 2>&1 || true
  setsid bash -c "while true; do python3 '$ROOT/tools/serve.py' '$DIR' '$PORT' >>'$PIDDIR/$PORT.log' 2>&1; sleep 1; done" >/dev/null 2>&1 < /dev/null &
  echo $! > "$PIDDIR/$PORT.pid"; echo "$DIR" > "$PIDDIR/$PORT.dir"
  for i in $(seq 1 50); do curl -sf -o /dev/null "http://127.0.0.1:$PORT/index.html" && { echo "serving $DIR on :$PORT"; exit 0; }; sleep 0.2; done
  echo "serve failed on :$PORT"; exit 1;;
stop) PORT=$2; [ -f "$PIDDIR/$PORT.pid" ] && { kill -- -"$(cat "$PIDDIR/$PORT.pid")" 2>/dev/null || kill "$(cat "$PIDDIR/$PORT.pid")" 2>/dev/null || true; rm -f "$PIDDIR/$PORT.pid"; }
  pkill -f "tools/serve.py .* $PORT\$" 2>/dev/null || true; echo "stopped :$PORT";;
status) PORT=$2; curl -sf -o /dev/null "http://127.0.0.1:$PORT/index.html" && echo "up :$PORT $(cat "$PIDDIR/$PORT.dir" 2>/dev/null)" || { echo "down :$PORT"; exit 1; };;
esac
