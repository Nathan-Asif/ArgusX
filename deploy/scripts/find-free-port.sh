#!/usr/bin/env bash
# Picks a free TCP port by scanning listeners (ss/netstat) — skips ports already in use.
set -euo pipefail

START_PORT="${1:-3100}"
END_PORT="${2:-8999}"
PREFERRED_PORT="${3:-}"

is_port_free() {
  local port="$1"
  if command -v ss >/dev/null 2>&1; then
    ! ss -lnt 2>/dev/null | awk '{print $4}' | grep -qE ":${port}$"
  elif command -v netstat >/dev/null 2>&1; then
    ! netstat -lnt 2>/dev/null | awk '{print $4}' | grep -qE ":${port}$"
  else
    ! (echo >/dev/tcp/127.0.0.1/"$port") 2>/dev/null
  fi
}

if [ -n "$PREFERRED_PORT" ] && is_port_free "$PREFERRED_PORT"; then
  echo "$PREFERRED_PORT"
  exit 0
fi

for ((port = START_PORT; port <= END_PORT; port++)); do
  if is_port_free "$port"; then
    echo "$port"
    exit 0
  fi
done

echo "No free port between $START_PORT and $END_PORT" >&2
exit 1
