#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_DIR="$SCRIPT_DIR/../docker"
COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"

echo "🛑 Stopping everything..."

docker compose -f "$COMPOSE_FILE" --env-file "$COMPOSE_DIR/.env" down -v 2>/dev/null || true
echo "   Stack stopped."

echo "   Stopping backend (go run)..."
BACKEND_PIDS="$(pgrep -f 'go run \.' || true; pgrep -f 'mercadomio-backend' || true)"
if [ -n "$BACKEND_PIDS" ]; then
  kill $BACKEND_PIDS 2>/dev/null || true
  sleep 1
  BACKEND_PIDS="$(pgrep -f 'go run \.' || true; pgrep -f 'mercadomio-backend' || true)"
  [ -n "$BACKEND_PIDS" ] && kill -9 $BACKEND_PIDS 2>/dev/null || true
fi

echo "   Stopping flutter (frontend / admin)..."
FLUTTER_PIDS="$(pgrep -f 'flutter.*web-server' || true)"
if [ -n "$FLUTTER_PIDS" ]; then
  kill $FLUTTER_PIDS 2>/dev/null || true
  sleep 1
  FLUTTER_PIDS="$(pgrep -f 'flutter.*web-server' || true)"
  [ -n "$FLUTTER_PIDS" ] && kill -9 $FLUTTER_PIDS 2>/dev/null || true
fi

echo "✅ All services stopped."