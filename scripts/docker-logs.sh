#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."
COMPOSE_DIR="$REPO_ROOT/docker"
COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"

SENTINEL="/tmp/mercadomio-docker-ready"

cleanup() { rm -f "$SENTINEL"; }
trap cleanup EXIT

# Bring the app infra stack up (compose + healthchecks).
"$SCRIPT_DIR/docker-up.sh"

echo ""
echo "📋 Following Docker container logs (Ctrl-C to stop)..."
docker compose -f "$COMPOSE_FILE" --env-file "$COMPOSE_DIR/.env" logs --tail=20 -f