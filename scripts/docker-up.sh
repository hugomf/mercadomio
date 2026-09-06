#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."
COMPOSE_DIR="$REPO_ROOT/docker"
COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"

SENTINEL="/tmp/mercadomio-docker-ready"

compose() { docker compose -f "$COMPOSE_FILE" --env-file "$COMPOSE_DIR/.env" "$@"; }

echo "🐳 Starting Docker stack (app infra)..."
echo "   (stopping app containers first — backend/frontend run on the host)"
compose stop backend frontend 2>/dev/null || true
compose up -d --build postgres mongo redis directus 2>&1

echo "⏳ Waiting for Postgres..."
until compose exec -T postgres pg_isready -U admin -d mercadomio > /dev/null 2>&1; do
  sleep 0.5
done
echo "✅ Postgres ready on :5432"

echo "⏳ Waiting for MongoDB..."
until compose exec -T mongo mongosh --quiet --eval "db.adminCommand('ping').ok" > /dev/null 2>&1; do
  sleep 0.5
done
echo "✅ MongoDB ready on :27017"

echo "⏳ Waiting for Redis..."
until compose exec -T redis redis-cli ping | grep -q PONG > /dev/null 2>&1; do
  sleep 0.5
done
echo "✅ Redis ready on :6379"

touch "$SENTINEL"
echo "✅ Docker stack fully ready — backend, frontend and admin can start"
