#!/usr/bin/env bash
# Bootstraps the userbrew IdP for MercadoMío (idempotent):
#   1. Completes first-run setup (admin user + RSA signing keys)
#   2. Creates the mercadomio-admin role and assigns it to the admin user
#   3. Registers the OAuth clients used by storefront and admin console
#
# Usage: scripts/setup-userbrew.sh
#
# Environment:
#   USERBREW_URL            Base URL of the IdP        (default http://localhost:8090)
#   USERBREW_ADMIN_EMAIL    Bootstrap admin email      (default admin@mercadomio.mx)
#   USERBREW_ADMIN_PASSWORD Bootstrap admin password   (default changeme123!)
set -euo pipefail

USERBREW_URL="${USERBREW_URL:-http://localhost:8090}"
ADMIN_EMAIL="${USERBREW_ADMIN_EMAIL:-admin@mercadomio.mx}"
ADMIN_PASSWORD="${USERBREW_ADMIN_PASSWORD:-changeme123!}"
ADMIN_USERNAME="mercadomio-admin"
STOREFRONT_REDIRECT="${STOREFRONT_REDIRECT:-http://localhost:3000/auth/callback}"
ADMIN_REDIRECT="${ADMIN_REDIRECT:-http://localhost:3100/auth/callback}"

json() { python3 -c "import sys,json;d=json.load(sys.stdin);print(d$1)"; }
req() {
  local method="$1" url="$2" body="${3:-}" token="${4:-}"
  local args=(-sS -X "$method" -H 'Content-Type: application/json')
  [[ -n "$token" ]] && args+=(-H "Authorization: Bearer $token")
  [[ -n "$body" ]] && args+=(-d "$body")
  curl "${args[@]}" "$url"
}

echo "==> Waiting for userbrew at $USERBREW_URL ..."
for i in $(seq 1 60); do
  if curl -fsS "$USERBREW_URL/health" >/dev/null 2>&1; then break; fi
  [[ $i -eq 60 ]] && { echo "userbrew did not become healthy"; exit 1; }
  sleep 2
done

echo "==> Checking setup status..."
STATUS=$(req GET "$USERBREW_URL/setup/status")

if [[ "$(echo "$STATUS" | json "['setup_completed']")" == "False" ]]; then
  echo "==> Running first-time setup (creates $ADMIN_EMAIL + RSA keys)..."
  SETUP_BODY=$(python3 - "$ADMIN_EMAIL" "$ADMIN_USERNAME" "$ADMIN_PASSWORD" "$USERBREW_URL" <<'EOF'
import json, sys
email, username, password, base_url = sys.argv[1:]
print(json.dumps({
    "database": {"url": ""},
    "admin_email": email,
    "admin_username": username,
    "admin_password": password,
    "server_host": "0.0.0.0",
    "server_port": 8090,
    "base_url": base_url,
    "jwt_algorithm": "RS256",
    "generate_rsa_keys": True,
}))
EOF
)
  RESULT=$(req POST "$USERBREW_URL/setup/complete" "$SETUP_BODY")
  echo "$RESULT" | json "['status']" >/dev/null || true
else
  echo "    Setup already completed."
fi

echo "==> Logging in as $ADMIN_EMAIL..."
LOGIN=$(req POST "$USERBREW_URL/auth/login" "{\"identifier\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}")
TOKEN=$(echo "$LOGIN" | json "['access_token']")
[[ -n "$TOKEN" && "$TOKEN" != "None" ]] || { echo "Login failed: $LOGIN"; exit 1; }

echo "==> Ensuring role 'mercadomio-admin' exists..."
ROLES=$(req GET "$USERBREW_URL/admin/roles" "" "$TOKEN")
if ! echo "$ROLES" | python3 -c "
import sys, json
data = sys.stdin.read()
roles = json.loads(data)
items = roles if isinstance(roles, list) else roles.get('roles') or roles.get('data') or []
sys.exit(0 if any(r.get('name') == 'mercadomio-admin' for r in items) else 1)
"; then
  req POST "$USERBREW_URL/admin/roles" \
    '{"name":"mercadomio-admin","permissions":[],"deny":[]}' "$TOKEN" >/dev/null
  echo "    Role created."
else
  echo "    Role already present."
fi

echo "==> Assigning role to admin user..."
req POST "$USERBREW_URL/admin/users/$ADMIN_EMAIL/roles/mercadomio-admin" "" "$TOKEN" >/dev/null || true

create_client() {
  local name="$1" redirect="$2" origin="$3"
  local clients existing_id
  clients=$(req GET "$USERBREW_URL/admin/oauth-clients" "" "$TOKEN")
  existing_id=$(echo "$clients" | CLIENT_NAME="$name" python3 -c "
import sys, json, os
clients = json.loads(sys.stdin.read())
items = clients if isinstance(clients, list) else clients.get('clients') or clients.get('data') or []
match = [c for c in items if c.get('name') == os.environ['CLIENT_NAME']]
print(match[0].get('id') or match[0].get('client_id') if match else '')
")
  local body="{\"name\":\"$name\",\"redirect_uris\":[\"$redirect\"],\"allowed_origins\":[\"$origin\"],\"require_pkce\":true,\"is_public\":true,\"scopes\":[\"openid\",\"profile\",\"email\",\"offline_access\"]}"
  if [[ -z "$existing_id" ]]; then
    local resp
    resp=$(req POST "$USERBREW_URL/admin/oauth-clients" "$body" "$TOKEN")
    echo "    Created '$name': $(echo "$resp" | json "['client_id']")"
  else
    echo "    Client '$name' already registered ($existing_id)."
  fi
}

echo "==> Registering OAuth clients..."
create_client "mercadomio-storefront" "$STOREFRONT_REDIRECT" "http://localhost:3000"
create_client "mercadomio-admin"      "$ADMIN_REDIRECT"      "http://localhost:3100"

echo ""
echo "Setup complete."
echo "Google login prereq (if enabled): set OAUTH_GOOGLE_* in docker/.env with callback URL:"
echo "  $USERBREW_URL/auth/social/google/callback"
