#!/usr/bin/env bash
set -e

PORT="${1:-5201}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/../frontend"
SENTINEL="/tmp/mercadomio-docker-ready"

echo "⏳ Waiting for Docker stack to be ready..."
until [ -f "$SENTINEL" ]; do
  sleep 1
done
echo "✅ Docker stack ready"

echo "🛒 Starting storefront (Flutter web) on port $PORT..."
cd "$APP_DIR"
exec flutter run -d web-server --web-port="$PORT" --web-hostname=0.0.0.0