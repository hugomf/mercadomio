#!/usr/bin/env bash
# Reconciles the MercadoMío OAuth clients on a shared userbrew IdP instance
# (idempotent). Self-contained: uses only curl + jq against the userbrew admin
# API, so it needs no userbrew repo checkout and no python.
#
# It REPLACES the previous implementation, which delegated to userbrew's
# deploy/local/apply-blueprint.py; that applier was removed from userbrew
# (superseded by the native /admin/blueprints/apply engine, which CANNOT manage
# OAuth clients).
#
# LOCAL instance: the local platform stack (sonnora-platform/local,
# bootstrap --env local) now owns the IdP and publishes userbrew at
# http://localhost:8090 (and UI at :5174) on the shared `infra` network.
# First-run setup (admin user, app, RSA keys) is NOT done here — run the
# platform bootstrap (Task 6: ./platform/scripts/bootstrap.sh --env local)
# on a fresh checkout; this script remains the target of the OAuth
# reconciliations at http://localhost:8090. Remote instances
# (userbrew.*.sonnora.mx) are likewise shared and pre-initialized.
#
# It reconciles the two OAuth clients the frontends use:
#   mercadomio-storefront  -> STOREFRONT_REDIRECT
#   mercadomio-admin       -> ADMIN_REDIRECT
# both with require_pkce=true, is_public=true (public PKCE clients, no secret),
# scopes [openid, profile, email, offline_access].
#
# NOTE on auto-generated client ids: the admin API does not let callers choose a
# client_id (it generates "ub_client_<base64>") and forbids renaming one. The
# dev/qa/prod instances already carry the canonical ids above (they were created
# while the legacy applier still existed), so reconciliation matches by
# client_id. On an instance where a client must be created from scratch the
# script prints the generated id and warns that the frontends are built with a
# fixed USERBREW_CLIENT_ID.
#
# Usage: scripts/setup-userbrew.sh [--env {local|dev|qa|prod}]
#
# Environment (can be overridden per env):
#   USERBREW_URL            Base URL of the IdP        (env-specific default)
#   STOREFRONT_REDIRECT     Storefront OAuth redirect  (env-specific default)
#   ADMIN_REDIRECT          Admin console OAuth redirect (env-specific default)
#   APP_ORIGIN              Allowed origin             (env-specific default)
#   USERBREW_ADMIN_EMAIL    Bootstrap admin email      (default admin@mercadomio.mx)
#   USERBREW_ADMIN_PASSWORD Bootstrap admin password   (default ChangeMe123!)
#   USERBREW_ADMIN_USERNAME Admin username             (default mercadomio-admin)
#   USERBREW_ADMIN_TOKEN    Admin API key (ub_sk_...) or admin JWT for the IdP.
#                           When set, admin operations authenticate via
#                           X-API-Key (key) or Authorization: Bearer (JWT)
#                           and no username/password login is performed.
set -euo pipefail

ENV="local"
while [ $# -gt 0 ]; do
  case "$1" in
    --env)
      ENV="$2"
      shift 2
      ;;
    --env=*)
      ENV="${1#--env=}"
      shift
      ;;
    *)
      echo "unknown flag: $1"
      exit 1
      ;;
  esac
done

case "$ENV" in
  local)
    USERBREW_URL="${USERBREW_URL:-http://localhost:8090}"
    STOREFRONT_REDIRECT="${STOREFRONT_REDIRECT:-http://localhost:3000/auth/callback}"
    ADMIN_REDIRECT="${ADMIN_REDIRECT:-http://localhost:3100/auth/callback}"
    APP_ORIGIN="${APP_ORIGIN:-http://localhost:3000}"
    ;;
  dev)
    USERBREW_URL="${USERBREW_URL:-https://userbrew.dev.sonnora.mx}"
    STOREFRONT_REDIRECT="${STOREFRONT_REDIRECT:-https://mercadomio.dev.sonnora.mx/auth/callback}"
    ADMIN_REDIRECT="${ADMIN_REDIRECT:-https://mercadomio.dev.sonnora.mx/admin/auth/callback}"
    APP_ORIGIN="${APP_ORIGIN:-https://mercadomio.dev.sonnora.mx}"
    ;;
  qa)
    USERBREW_URL="${USERBREW_URL:-https://userbrew.qa.sonnora.mx}"
    STOREFRONT_REDIRECT="${STOREFRONT_REDIRECT:-https://mercadomio.qa.sonnora.mx/auth/callback}"
    ADMIN_REDIRECT="${ADMIN_REDIRECT:-https://mercadomio.qa.sonnora.mx/admin/auth/callback}"
    APP_ORIGIN="${APP_ORIGIN:-https://mercadomio.qa.sonnora.mx}"
    ;;
  prod)
    USERBREW_URL="${USERBREW_URL:-https://userbrew.sonnora.mx}"
    STOREFRONT_REDIRECT="${STOREFRONT_REDIRECT:-https://mercadomio.sonnora.mx/auth/callback}"
    ADMIN_REDIRECT="${ADMIN_REDIRECT:-https://mercadomio.sonnora.mx/admin/auth/callback}"
    APP_ORIGIN="${APP_ORIGIN:-https://mercadomio.sonnora.mx}"
    ;;
  *)
    echo "invalid --env: $ENV (use local|dev|qa|prod)"
    exit 1
    ;;
esac

USERBREW_ADMIN_EMAIL="${USERBREW_ADMIN_EMAIL:-admin@mercadomio.mx}"
USERBREW_ADMIN_PASSWORD="${USERBREW_ADMIN_PASSWORD:-ChangeMe123!}"
USERBREW_ADMIN_USERNAME="${USERBREW_ADMIN_USERNAME:-mercadomio-admin}"

for tool in curl jq; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: $tool is required but not installed"
    exit 1
  fi
done

echo "==> Waiting for userbrew at $USERBREW_URL ..."
for _ in $(seq 1 60); do
  if curl -fsS "$USERBREW_URL/health" >/dev/null 2>&1; then break; fi
  echo "    not healthy yet (retrying in 2s)..."
  sleep 2
done
if ! curl -fsS "$USERBREW_URL/health" >/dev/null 2>&1; then
  echo "ERROR: userbrew did not become healthy at $USERBREW_URL"
  exit 1
fi

# --- Authenticate -------------------------------------------------------------
AUTH_HDR=""
if [[ -n "${USERBREW_ADMIN_TOKEN:-}" ]]; then
  if [[ "$USERBREW_ADMIN_TOKEN" == ub_sk_* ]]; then
    AUTH_HDR="X-API-Key: $USERBREW_ADMIN_TOKEN"
  else
    AUTH_HDR="Authorization: Bearer $USERBREW_ADMIN_TOKEN"
  fi
  echo "==> Authenticating with USERBREW_ADMIN_TOKEN"
else
  echo "==> Authenticating as $USERBREW_ADMIN_USERNAME / $USERBREW_ADMIN_EMAIL"
  APP_ID=""
  for _ in $(seq 1 5); do
    APP_ID="$(curl -fsS "$USERBREW_URL/setup/console-app" 2>/dev/null | jq -r '.application_id // empty' 2>/dev/null || true)"
    [[ -n "$APP_ID" ]] && break
    sleep 2
  done
  if [[ -z "$APP_ID" ]]; then
    echo "ERROR: could not resolve console application_id at $USERBREW_URL/setup/console-app"
    exit 1
  fi
  LOGIN_PAYLOAD="$(jq -cn --arg i "$USERBREW_ADMIN_USERNAME" --arg p "$USERBREW_ADMIN_PASSWORD" --arg a "$APP_ID" '{identifier:$i,password:$p,application_id:$a}')"
  TOKEN_JSON=""
  for _ in $(seq 1 5); do
    if TOKEN_JSON="$(curl -fsS -H 'Content-Type: application/json' -d "$LOGIN_PAYLOAD" "$USERBREW_URL/auth/login" 2>&1)"; then
      break
    fi
    echo "    login failed, retrying in 2s..."
    sleep 2
  done
  TOKEN="$(jq -r '.access_token // empty' <<<"${TOKEN_JSON:-}" 2>/dev/null || true)"
  if [[ -z "$TOKEN" ]]; then
    echo "ERROR: login failed (POST /auth/login). Raw response:"
    echo "${TOKEN_JSON:-}"
    exit 1
  fi
  AUTH_HDR="Authorization: Bearer $TOKEN"
fi

# --- Reconcile OAuth clients ---------------------------------------------------
# Desired state per client. allowed_origins is intentionally omitted: the admin
# API accepts it but does not persist or return it.
GRANT_TYPES='["authorization_code","refresh_token"]'
RESPONSE_TYPES='["code"]'
SCOPES='["openid","profile","email","offline_access"]'

reconcile_client() {
  local want_id="$1" want_redirect="$2"
  local list existing by_name actual_id needs_update body resp new_id

  list="$(curl -fsS -H "$AUTH_HDR" "$USERBREW_URL/admin/oauth-clients")"
  existing="$(jq -c --arg id "$want_id" '.[] | select(.client_id==$id)' <<<"$list" | head -n1)"

  if [[ -n "$existing" ]]; then
    if jq -e --arg n "$want_id" --arg r "$want_redirect" \
         --argjson g "$GRANT_TYPES" --argjson rp "$RESPONSE_TYPES" --argjson s "$SCOPES" \
         '(.name==$n) and ((.redirect_uris|sort)==([$r]|sort)) and ((.grant_types|sort)==($g|sort)) and ((.response_types|sort)==($rp|sort)) and ((.scopes|sort)==($s|sort)) and .require_pkce==true and .is_public==true and .enabled==true' \
         <<<"$existing" >/dev/null 2>&1; then
      echo "==> $want_id: already in desired state"
    else
      echo "==> $want_id: updating (found by client_id)"
      body="$(jq -cn --arg id "$want_id" --arg n "$want_id" --arg r "$want_redirect" \
        --argjson g "$GRANT_TYPES" --argjson rp "$RESPONSE_TYPES" --argjson s "$SCOPES" \
        '{client_id:$id,name:$n,redirect_uris:[$r],grant_types:$g,response_types:$rp,scopes:$s,require_pkce:true,is_public:true,enabled:true}')"
      curl -fsS -X PUT -H 'Content-Type: application/json' -H "$AUTH_HDR" -d "$body" \
        "$USERBREW_URL/admin/oauth-clients/$want_id" >/dev/null
    fi
    return 0
  fi

  by_name="$(jq -c --arg n "$want_id" '.[] | select(.name==$n)' <<<"$list" | head -n1)"
  if [[ -n "$by_name" ]]; then
    actual_id="$(jq -r '.client_id' <<<"$by_name")"
    echo "==> $want_id: found by name but client_id=$actual_id != $want_id"
    echo "    > updating attributes of $actual_id (frontends are built with client_id=$want_id)"
    body="$(jq -cn --arg id "$actual_id" --arg n "$want_id" --arg r "$want_redirect" \
      --argjson g "$GRANT_TYPES" --argjson rp "$RESPONSE_TYPES" --argjson s "$SCOPES" \
      '{client_id:$id,name:$n,redirect_uris:[$r],grant_types:$g,response_types:$rp,scopes:$s,require_pkce:true,is_public:true,enabled:true}')"
    curl -fsS -X PUT -H 'Content-Type: application/json' -H "$AUTH_HDR" -d "$body" \
      "$USERBREW_URL/admin/oauth-clients/$actual_id" >/dev/null
    echo "    > WARNING: mirror client_id (rename) is not possible via the admin API"
    return 1
  fi

  echo "==> $want_id: creating"
  body="$(jq -cn --arg n "$want_id" --arg r "$want_redirect" \
    --argjson g "$GRANT_TYPES" --argjson rp "$RESPONSE_TYPES" --argjson s "$SCOPES" \
    '{name:$n,redirect_uris:[$r],grant_types:$g,response_types:$rp,scopes:$s,require_pkce:true,is_public:true}')"
  resp="$(curl -fsS -H 'Content-Type: application/json' -H "$AUTH_HDR" -d "$body" \
    "$USERBREW_URL/admin/oauth-clients")"
  new_id="$(jq -r '.client.client_id' <<<"$resp")"
  echo "    > created client_id=$new_id (auto-generated; cannot be chosen via the API)"
  echo "    > WARNING: frontends are built with USERBREW_CLIENT_ID=$want_id; set it to $new_id at build time or mirror the row in the userbrew DB/console."
  return 1
}

STATUS=0
reconcile_client "mercadomio-storefront" "$STOREFRONT_REDIRECT" || STATUS=1
reconcile_client "mercadomio-admin" "$ADMIN_REDIRECT" || STATUS=1

echo ""
if [[ "$STATUS" == 0 ]]; then
  echo "Setup complete. OAuth clients for $USERBREW_URL are in desired state:"
  echo "  mercadomio-storefront -> $STOREFRONT_REDIRECT"
  echo "  mercadomio-admin      -> $ADMIN_REDIRECT"
else
  echo "Setup finished with warnings (see above)."
  echo "Google login prereq (if enabled): set OAUTH_GOOGLE_* in docker/.env with callback URL:"
  echo "  $USERBREW_URL/auth/social/google/callback"
fi
exit "$STATUS"