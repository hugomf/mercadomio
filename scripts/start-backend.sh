#!/bin/bash
#
# Start the Mercado Mío backend server (Go/Fiber).
#
# Loads backend/local.env (real local config: MONGO_URI, REDIS_ADDR, PORT, ...).
# Ensures MongoDB and Redis are reachable — starting them via docker compose when
# they are not — then runs the backend with `go run .`.
#
# Usage:
#   ./scripts/start-backend.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
BACKEND_DIR="$ROOT_DIR/backend"
COMPOSE_FILE="$ROOT_DIR/docker/docker-compose.yml"

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
  echo "Warning: backend/local.env not found, using defaults (localhost:27017 / 6379 / 8080)"
fi

# Resolve effective values (defaults mirror main.go)
MONGO_URI="${MONGO_URI:-mongodb://localhost:27017}"
REDIS_ADDR="${REDIS_ADDR:-localhost:6379}"
PORT="${PORT:-8080}"

# Extract host:port from Mongo URI for a quick reachability check.
MONGO_HOST="${MONGO_URI#mongodb://}"
MONGO_HOST="${MONGO_HOST%%/*}"
if [[ -z "${MONGO_HOST##*@*}" ]]; then
  MONGO_HOST="${MONGO_HOST##*@}"
fi
MONGO_HOST="${MONGO_HOST%:*}"

check_port() {
  local host="$1"
  local port="$2"
  nc -z -G 2 -w 2 "$host" "$port" 2>/dev/null
}

ensure_up() {
  local host="$1"
  local port="$2"
  local name="$3"
  local service="$4"

  if check_port "$host" "$port"; then
    echo "$name already running at $host:$port"
    return
  fi

  echo "$name not running at $host:$port — starting via docker compose..."
  docker compose -f "$COMPOSE_FILE" up -d "$service"

  echo "Waiting for $name to be ready..."
  local i
  for i in $(seq 1 30); do
    if check_port "$host" "$port"; then
      echo "$name ready at $host:$port"
      return
    fi
    sleep 2
  done

  echo "Error: $name did not become reachable at $host:$port."
  echo "Check the container with: docker compose -f $COMPOSE_FILE logs $service"
  exit 1
}

ensure_up "$MONGO_HOST" "27017" "MongoDB" "mongo"
ensure_up "${REDIS_ADDR%:*}" "${REDIS_ADDR##*:}" "Redis" "redis"

# Compile check before serving.
echo "Building backend..."
go build ./...

echo "Starting backend on port $PORT..."
exec go run .