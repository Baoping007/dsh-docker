#!/bin/sh
set -eu

DSH_PORT="${DSH_PORT:-3079}"
PROXY_PORT="${PROXY_PORT:-3080}"
DSH_WEB_LOG="${DSH_WEB_LOG:-/app/.dsh-web.log}"
DSH_PID=''
PROXY_PID=''
TAIL_PID=''

if [ "$DSH_PORT" = "$PROXY_PORT" ]; then
  echo "[dsh] DSH_PORT and PROXY_PORT must be different" >&2
  exit 1
fi

cleanup() {
  trap - EXIT INT TERM
  [ -z "$PROXY_PID" ] || kill "$PROXY_PID" 2>/dev/null || true
  [ -z "$TAIL_PID" ] || kill "$TAIL_PID" 2>/dev/null || true
  [ -z "$DSH_PID" ] || kill "$DSH_PID" 2>/dev/null || true
  [ -z "$PROXY_PID" ] || wait "$PROXY_PID" 2>/dev/null || true
  [ -z "$TAIL_PID" ] || wait "$TAIL_PID" 2>/dev/null || true
  [ -z "$DSH_PID" ] || wait "$DSH_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "[dsh] Starting on 127.0.0.1:${DSH_PORT}"
dsh web --no-open --port "$DSH_PORT" >"$DSH_WEB_LOG" 2>&1 &
DSH_PID=$!
tail -n +1 -F "$DSH_WEB_LOG" &
TAIL_PID=$!

ready=0
i=0
while [ "$i" -lt 120 ]; do
  if node -e "fetch('http://127.0.0.1:${DSH_PORT}/').then(() => process.exit(0)).catch(() => process.exit(1))" 2>/dev/null; then
    ready=1
    break
  fi
  if ! kill -0 "$DSH_PID" 2>/dev/null; then
    echo "[dsh] DSH exited before becoming ready" >&2
    exit 1
  fi
  i=$((i + 1))
  sleep 1
done

if [ "$ready" != "1" ]; then
  echo "[dsh] Timed out waiting for DSH on 127.0.0.1:${DSH_PORT}" >&2
  exit 1
fi

echo "[proxy] Listening on 0.0.0.0:${PROXY_PORT} -> 127.0.0.1:${DSH_PORT}"
node /app/proxy/index.js &
PROXY_PID=$!
wait "$PROXY_PID"
