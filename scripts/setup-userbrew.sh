#!/usr/bin/env bash
# Bootstraps the userbrew IdP for MercadoMío (idempotent) by delegating to the
# userbrew blueprint applier (deploy/local/apply-blueprint.py) with the
# MercadoMío blueprint (scripts/blueprints/idp.yaml).
#
# The blueprint reconciles:
#   1. First-run setup (admin user + RSA signing keys)
#   2. The `mercadomio-admin` role, assigned to the admin user
#   3. The OAuth clients used by storefront and admin console
#
# Usage: scripts/setup-userbrew.sh [--env {local|dev|qa|prod}]
#
# Environment (can be overridden per env):
#   USERBREW_URL            Base URL of the IdP        (default http://localhost:8090)
#   STOREFRONT_REDIRECT     Storefront OAuth redirect  (env-specific default)
#   ADMIN_REDIRECT          Admin console OAuth redirect (env-specific default)
#   USERBREW_ADMIN_EMAIL    Bootstrap admin email      (default admin@mercadomio.mx)
#   USERBREW_ADMIN_PASSWORD Bootstrap admin password   (default ChangeMe123!)
#   USERBREW_ADMIN_TOKEN    Admin API key (ub_sk_...) or admin JWT for the IdP.
#                           When set, admin operations authenticate via
#                           X-API-Key (key) or Authorization: Bearer (JWT)
#                           and no username/password login is performed.
#   USERBREW_REPO_DIR       Path to the userbrew checkout (default ../userbrew
#                           relative to this repo).
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
    APP_ORIGIN="http://localhost:3000"
    ;;
  dev)
    USERBREW_URL="${USERBREW_URL:-https://userbrew.dev.sonnora.mx}"
    STOREFRONT_REDIRECT="${STOREFRONT_REDIRECT:-https://mercadomio.dev.sonnora.mx/auth/callback}"
    ADMIN_REDIRECT="${ADMIN_REDIRECT:-https://mercadomio.dev.sonnora.mx/admin/auth/callback}"
    APP_ORIGIN="https://mercadomio.dev.sonnora.mx"
    ;;
  qa)
    USERBREW_URL="${USERBREW_URL:-https://userbrew.qa.sonnora.mx}"
    STOREFRONT_REDIRECT="${STOREFRONT_REDIRECT:-https://mercadomio.qa.sonnora.mx/auth/callback}"
    ADMIN_REDIRECT="${ADMIN_REDIRECT:-https://mercadomio.qa.sonnora.mx/admin/auth/callback}"
    APP_ORIGIN="https://mercadomio.qa.sonnora.mx"
    ;;
  prod)
    USERBREW_URL="${USERBREW_URL:-https://userbrew.sonnora.mx}"
    STOREFRONT_REDIRECT="${STOREFRONT_REDIRECT:-https://mercadomio.sonnora.mx/auth/callback}"
    ADMIN_REDIRECT="${ADMIN_REDIRECT:-https://mercadomio.sonnora.mx/admin/auth/callback}"
    APP_ORIGIN="https://mercadomio.sonnora.mx"
    ;;
  *)
    echo "invalid --env: $ENV (use local|dev|qa|prod)"
    exit 1
    ;;
esac

export USERBREW_URL STOREFRONT_REDIRECT ADMIN_REDIRECT APP_ORIGIN
export USERBREW_ADMIN_EMAIL="${USERBREW_ADMIN_EMAIL:-admin@mercadomio.mx}"
export USERBREW_ADMIN_PASSWORD="${USERBREW_ADMIN_PASSWORD:-ChangeMe123!}"
export USERBREW_ADMIN_USERNAME="mercadomio-admin"

MERCADOMIO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
USERBREW_DIR="${USERBREW_REPO_DIR:-$MERCADOMIO_DIR/../userbrew}"
APPLIER="$USERBREW_DIR/deploy/local/apply-blueprint.py"
BLUEPRINT="$MERCADOMIO_DIR/scripts/blueprints/idp.yaml"

if [ ! -f "$APPLIER" ]; then
  echo "ERROR: applier no encontrado en $APPLIER (ajusta USERBREW_REPO_DIR)"
  exit 1
fi
if [ ! -f "$BLUEPRINT" ]; then
  echo "ERROR: blueprint no encontrado en $BLUEPRINT"
  exit 1
fi

echo "==> Waiting for userbrew at $USERBREW_URL ..."
for i in $(seq 1 60); do
  if curl -fsS "$USERBREW_URL/health" >/dev/null 2>&1; then break; fi
  [[ $i -eq 60 ]] && { echo "userbrew did not become healthy"; exit 1; }
  sleep 2
done

python3 "$APPLIER" "$BLUEPRINT" "$USERBREW_URL"

echo ""
echo "Setup complete."
echo "Google login prereq (if enabled): set OAUTH_GOOGLE_* in docker/.env with callback URL:"
echo "  $USERBREW_URL/auth/social/google/callback"