#!/usr/bin/env bash
# Publishes mercadomio docker images to the Gitea registry (per environment).
#
# Usage:
#   GITEA_TOKEN=... scripts/publish-images.sh --env {dev|qa|prod}
#
# Reads per-env overrides from deploy/{env}/.env (e.g. USERBREW_ISSUER build arg).
#
# Requires: docker with buildx (docker build --push works with default builder
# when credentials are set via `docker login`). Login username: hugomf.
set -euo pipefail

REGISTRY="gitea.sonnora.mx/sonnora-mx/mercadomio"
GITEA_USER="${GITEA_USER:-hugomf}"
ENV=""

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
  dev|qa|prod) ;;
  *) echo "missing/invalid --env {dev|qa|prod}"; exit 1 ;;
esac

[ -f "deploy/$ENV/.env" ] || { echo "missing deploy/$ENV/.env"; exit 1; }
[ -f "deploy/.env" ] && { set -a; source "deploy/.env"; set +a; }
[ -n "${GITEA_TOKEN:-}" ] || { echo "missing GITEA_TOKEN (set it or put it in deploy/.env)"; exit 1; }

USERBREW_ISSUER="https://userbrew.$ENV.sonnora.mx"
API_URL="https://mercadomio.$ENV.sonnora.mx"
WEB_REDIRECT="https://mercadomio.$ENV.sonnora.mx/auth/callback"
ADMIN_REDIRECT="https://mercadomio.$ENV.sonnora.mx/admin/auth/callback"

# shellcheck disable=SC1091
set -a; source "deploy/$ENV/.env"; set +a

echo "==> Login to Gitea registry ($GITEA_USER@$REGISTRY)"
echo "$GITEA_TOKEN" | docker login gitea.sonnora.mx -u "$GITEA_USER" --password-stdin

build() {
  local name="$1" ctx="$2"; shift 2
  local tag="$REGISTRY/$name:$ENV"
  echo "==> Building+push: $tag"
  if docker buildx version >/dev/null 2>&1; then
    docker buildx build --push --platform linux/arm64 -t "$tag" "$@" "$ctx"
  else
    docker build --push --platform linux/arm64 -t "$tag" "$@" "$ctx"
  fi
}

WEB_ARGS=(
  --build-arg API_URL="$API_URL"
  --build-arg USERBREW_ISSUER="$USERBREW_ISSUER"
  --build-arg USERBREW_CLIENT_ID=mercadomio-storefront
  --build-arg USERBREW_REDIRECT_URI="$WEB_REDIRECT"
)
ADMIN_ARGS=(
  --build-arg API_URL="$API_URL"
  --build-arg USERBREW_ISSUER="$USERBREW_ISSUER"
  --build-arg USERBREW_CLIENT_ID=mercadomio-admin
  --build-arg USERBREW_REDIRECT_URI="$ADMIN_REDIRECT"
)

build backend backend
build frontend frontend "${WEB_ARGS[@]}"
build admin admin_console "${ADMIN_ARGS[@]}"

docker logout gitea.sonnora.mx >/dev/null 2>&1 || true

echo ""
echo "==> Published $REGISTRY/{backend,frontend,admin}:$ENV"