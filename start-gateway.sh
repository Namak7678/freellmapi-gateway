#!/bin/bash
# FreeLLMAPI gateway supervisor — ensures the local gateway stays up.
# Usage: ./start-gateway.sh [--daemon]
# If --daemon, keeps restarting the server if it crashes. Otherwise starts once if down.
set -u
DIR="/app/conversations/6ab593e77f5a926229634a4d/work/freellmapi"
CFG="$DIR/freellmapi.config.json"
LOG="/tmp/fll-server.log"

is_up() { curl -s -o /dev/null -m 5 http://localhost:3001/api/health; }

start_once() {
  cd "$DIR" || return 1
  FREEAPI_CONFIG_PATH="$CFG" nohup npm run dev -w server >> "$LOG" 2>&1 &
  sleep 12
  if is_up; then echo "gateway UP (pid group started)"; return 0; else echo "gateway FAILED to start"; return 1; fi
}

if is_up; then
  echo "gateway already UP — nothing to do"
  exit 0
fi
pkill -9 -f "tsx watch src/index.ts" 2>/dev/null
sleep 2

if [ "${1:-}" = "--daemon" ]; then
  while true; do
    start_once || true
    sleep 30
    if is_up; then sleep 120; else echo "restarting crashed gateway..."; fi
  done
else
  start_once
fi
