#!/bin/sh
set -u

BIN="/usr/local/bin/proxy_agent"
STATE="${STATE_DIR:-/state}"
INTERVAL="${RESTART_INTERVAL:-900}"
KILL_AFTER="${KILL_AFTER:-10}"
PORT="${PORT:-10000}"

mkdir -p "$STATE"

# PHP built-in server; router handles /status and 404s everything else.
php -S "0.0.0.0:${PORT}" -t /www /www/router.php >/dev/null 2>&1 &
HTTPD_PID=$!

child=""
cleanup() {
    trap - TERM INT
    [ -n "$child" ] && kill -TERM "$child" 2>/dev/null
    kill -TERM "$HTTPD_PID" 2>/dev/null
    wait 2>/dev/null
    exit 0
}
trap cleanup TERM INT

while :; do
    date -u +"%Y-%m-%dT%H:%M:%SZ" > "$STATE/last_start"
    date +%s                     > "$STATE/last_start_epoch"

    # Truncate each run: last_run.log is always the most recent run only.
    timeout -s TERM -k "$KILL_AFTER" "$INTERVAL" "$BIN" > "$STATE/last_run.log" 2>&1 &
    child=$!
    wait "$child"; rc=$?
    child=""

    date -u +"%Y-%m-%dT%H:%M:%SZ" > "$STATE/last_stop"
    echo "$rc"                    > "$STATE/last_exit"
    sleep 1
done
