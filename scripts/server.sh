#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."
BACKEND_DIR="$REPO_ROOT/backend"

BACKEND_PORT="${BACKEND_PORT:-8080}"
SENTINEL="/tmp/mercadomio-docker-ready"

set -a
[ -f "$BACKEND_DIR/local.env" ] && { # shellcheck disable=SC1091
  source "$BACKEND_DIR/local.env"
}
set +a

echo "⏳ Waiting for Docker stack to be ready..."
until [ -f "$SENTINEL" ]; do
  sleep 1
done
echo "✅ Docker stack ready"

echo "📦 Building & running backend (debug) on :${BACKEND_PORT}..."
cd "$BACKEND_DIR"
exec go run .