#!/bin/bash
#
# Stop the Mercado Mío backend server and optionally the docker infra
# (MongoDB / Redis) that start-backend.sh may have brought up.
#
# Usage:
#   ./scripts/stop.sh            # stop backend only
#   ./scripts/stop.sh --infra    # also stop mongo + redis containers

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
COMPOSE_FILE="$ROOT_DIR/docker/docker-compose.yml"

STOP_INFRA=false
if [[ "${1:-}" == "--infra" ]]; then
  STOP_INFRA=true
fi

echo "Stopping backend server..."

# Kill the `go run .` parent and the compiled binary it spawned.
BACKEND_PIDS="$(pgrep -f 'go run \.' || true; pgrep -f 'mercadomio-backend' || true)"
if [[ -n "$BACKEND_PIDS" ]]; then
  kill $BACKEND_PIDS 2>/dev/null || true
  sleep 1
  BACKEND_PIDS="$(pgrep -f 'go run \.' || true; pgrep -f 'mercadomio-backend' || true)"
  if [[ -n "$BACKEND_PIDS" ]]; then
    kill -9 $BACKEND_PIDS 2>/dev/null || true
  fi
fi

# Confirm nothing is bound to :5200 anymore.
if lsof -nP -iTCP:5200 -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Warning: something is still listening on :5200"
else
  echo "Backend stopped. Port 5200 is free."
fi

if $STOP_INFRA; then
  echo "Stopping docker infra (mongo + redis)..."
  docker compose -f "$COMPOSE_FILE" stop mongo redis || true
fi

echo "Done."