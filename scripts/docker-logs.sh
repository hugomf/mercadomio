#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."
COMPOSE_DIR="$REPO_ROOT/docker"
COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"
BLUEPRINT_FILE="$COMPOSE_DIR/self-host.yaml"

SENTINEL="/tmp/mercadomio-docker-ready"
IDP_URL=""

cleanup() { rm -f "$SENTINEL"; }
trap cleanup EXIT

py() { python3 -c "import sys,json;d=json.load(sys.stdin);print($1)"; }

set -a
[ -f "$COMPOSE_DIR/.env" ] && { # shellcheck disable=SC1091
  source "$COMPOSE_DIR/.env"
}
[ -f "$COMPOSE_DIR/.env.local" ] && { # shellcheck disable=SC1091
  source "$COMPOSE_DIR/.env.local"
}
set +a

IDP_URL="${USERBREW_PUBLIC_URL:-http://localhost:8090}"
ADMIN_USERNAME="${USERBREW_ADMIN_USERNAME:-mercadomio-admin}"
ADMIN_EMAIL="${USERBREW_ADMIN_EMAIL:-admin@mercadomio.mx}"
ADMIN_PASSWORD="${USERBREW_ADMIN_PASSWORD:?set USERBREW_ADMIN_PASSWORD in docker/.env.local (see .env.local.example)}"

echo "🐳 Starting Docker stack (infra + userbrew sidecar)..."
echo "   (stopping app containers first — backend/frontend run on the host)"
docker compose -f "$COMPOSE_FILE" stop backend frontend 2>/dev/null || true
docker compose -f "$COMPOSE_FILE" --env-file "$COMPOSE_DIR/.env" up -d --build postgres mongo redis directus userbrew 2>&1

echo ""
echo "⏳ Waiting for Postgres..."
until docker compose -f "$COMPOSE_FILE" exec -T postgres pg_isready -U admin -d mercadomio > /dev/null 2>&1; do
  sleep 0.5
done
echo "✅ Postgres ready on :5432"

echo "⏳ Waiting for MongoDB..."
until docker compose -f "$COMPOSE_FILE" exec -T mongo mongosh --quiet --eval "db.adminCommand('ping').ok" > /dev/null 2>&1; do
  sleep 0.5
done
echo "✅ MongoDB ready on :27017"

echo "⏳ Waiting for Redis..."
until docker compose -f "$COMPOSE_FILE" exec -T redis redis-cli ping | grep -q PONG > /dev/null 2>&1; do
  sleep 0.5
done
echo "✅ Redis ready on :6379"

echo "⏳ Waiting for Userbrew..."
until curl -sf "${IDP_URL}/health" > /dev/null 2>&1; do
  sleep 1
done
echo "✅ Userbrew ready on ${IDP_URL}"

# ---- Idempotent bootstrap: setup the IdP if needed, then apply the blueprint.
SETUP="$(curl -sf "${IDP_URL}/setup/status" 2>/dev/null || echo '{}')"
if printf '%s' "$SETUP" | grep -q '"setup_completed":false'; then
  echo "==> setup del IdP (primera ejecucion)"
  curl -fsS -X POST "${IDP_URL}/setup/complete" -H 'Content-Type: application/json' \
    -d "{\"database\":{\"url\":\"sqlite:///data/idp.db\"},\"admin_email\":\"$ADMIN_EMAIL\",\"admin_username\":\"$ADMIN_USERNAME\",\"admin_password\":\"$ADMIN_PASSWORD\",\"server_host\":\"0.0.0.0\",\"server_port\":3000,\"base_url\":\"$IDP_URL\",\"jwt_algorithm\":\"HS256\",\"generate_rsa_keys\":true}" \
    > /dev/null
  echo "   setup/complete OK"
else
  echo "==> setup del IdP ya completado -> login"
fi

echo "==> login como $ADMIN_USERNAME"
CONSOLE_APP_ID="$(curl -fsS "${IDP_URL}/setup/console-app" | py "d.get('application_id') or ''")"
LOGIN="$(curl -fsS -X POST "${IDP_URL}/auth/login" -H 'Content-Type: application/json' \
  -d "{\"identifier\":\"$ADMIN_USERNAME\",\"password\":\"$ADMIN_PASSWORD\",\"application_id\":\"$CONSOLE_APP_ID\"}")"
ADMIN_TOKEN="$(printf '%s' "$LOGIN" | py "d['access_token']")"
[ -n "$ADMIN_TOKEN" ] || { echo "❌ no se obtuvo access_token" >&2; exit 1; }

echo "==> aplicando blueprint ($BLUEPRINT_FILE)"
PAYLOAD="$(python3 -c 'import json,sys;print(json.dumps({"yaml":sys.stdin.read()}))' < "$BLUEPRINT_FILE")"
REPORT="$(curl -fsS -X POST "${IDP_URL}/admin/blueprints/apply" -H 'Content-Type: application/json' -H "Authorization: Bearer $ADMIN_TOKEN" -d "$PAYLOAD")"
APP_ID="$(printf '%s' "$REPORT" | py "d.get('application_id') or ''")"
ROLES_CREATED="$(printf '%s' "$REPORT" | py "d.get('created_roles') or []")"
CLIENTS_CREATED="$(printf '%s' "$REPORT" | py "d.get('created_oauth_clients') or []")"
WARNINGS="$(printf '%s' "$REPORT" | py "d.get('warnings') or []")"
echo "   app_id=${APP_ID:-<reused>}"
[ "$ROLES_CREATED" != "[]" ] && echo "   created_roles=$ROLES_CREATED"
[ "$CLIENTS_CREATED" != "[]" ] && echo "   created_oauth_clients=$CLIENTS_CREATED"
[ "$WARNINGS" != "[]" ] && echo "   warnings=$WARNINGS"
unset ADMIN_TOKEN

touch "$SENTINEL"
echo "✅ Docker stack fully ready — backend, frontend and admin can start"

echo ""
echo "📋 Following Docker container logs (Ctrl-C to stop)..."
docker compose -f "$COMPOSE_FILE" --env-file "$COMPOSE_DIR/.env" logs --tail=20 -f