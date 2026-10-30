#!/bin/sh
set -u

BIN="/usr/local/bin/proxy_agent"
INTERVAL=900        # 15 minutes, in seconds
KILL_AFTER=10       # seconds to wait after SIGTERM before SIGKILL

child=""

cleanup() {
    trap - TERM INT
    if [ -n "$child" ]; then
        kill -TERM "$child" 2>/dev/null || true
        wait "$child" 2>/dev/null || true
    fi
    exit 0
}
trap cleanup TERM INT

while :; do
    # Run the agent; SIGTERM it after INTERVAL, SIGKILL 10 s later.
    timeout -s TERM -k "$KILL_AFTER" "$INTERVAL" "$BIN" &
    child=$!
    wait "$child" 2>/dev/null || true
    child=""
    # Guard against hot-looping if the binary exits immediately.
    sleep 1
done
