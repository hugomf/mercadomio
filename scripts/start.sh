#!/bin/bash
#
# Start the Mercado Mío backend server (Go/Fiber).
#
# Loads backend/local.env, brings up the full dependent stack via
# scripts/docker-up.sh (postgres, mongo, redis, directus) with healthchecks,
# then runs the backend with `go run .`.
#
# Usage:
#   ./scripts/start.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
BACKEND_DIR="$ROOT_DIR/backend"

cd "$BACKEND_DIR"

# Load local.env so the server gets the real MONGO_URI/REDIS_ADDR/PORT
# (godotenv in main.go only reads .env, which is not committed locally).
if [[ -f local.env ]]; then
  set -a
  # shellcheck disable=SC1091
  source local.env
  set +a
  echo "Loaded local.env"
else
  echo "Warning: backend/local.env not found, using defaults (localhost:27017 / 6379 / 5200)"
fi

if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  echo "Error: docker daemon not reachable. Start Docker Desktop or run 'colima start'." >&2
  exit 1
fi

# Bring up every dependent service (postgres, mongo, redis, directus).
# Userbrew, imgvault, and minio are provided by the local platform stack
# (sonnora-deploy platform/docker/docker-compose.local.yml); start it first.
"$SCRIPT_DIR/docker-up.sh"

# Compile check before serving.
echo "Building backend..."
go build ./...

PORT="${PORT:-5200}"
echo "Starting backend on port $PORT..."
exec go run .