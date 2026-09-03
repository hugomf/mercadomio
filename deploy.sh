#!/usr/bin/env bash
#
# deploy.sh — Unified deployment for mercadomio across all environments.
#
# Usage:
#   ./deploy.sh --env {local|dev|qa|prod} [--skip-dns-check] [--register-vps]
#
# Environments:
#   local  — Docker Compose stack on macOS (docker/docker-compose.yml)
#   dev    — mercadomio.dev.sonnora.mx  → sonnora-dev app server
#   qa     — mercadomio.qa.sonnora.mx   → sonnora-qa app server
#   prod   — mercadomio.sonnora.mx      → sonnora-prod app server
#
# Remote environments deploy:
#   1. Upload shared configs (docker-compose, nginx, .env) to the app server
#   2. docker compose pull (images already published to the Gitea registry)
#   3. Start infra (postgres/mongo/redis/directus/imgvault/minio) + app
#      (backend/frontend/admin) + app-nginx via compose
#   4. With --register-vps: install nginx block + TLS cert on the sonnora VPS

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE_WORK="/tmp/mercadomio-deploy"
REGISTRY="gitea.sonnora.mx/sonnora-mx/mercadomio"

# ------------------------- small helpers -------------------------------
say() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
die() { printf '\n\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# ------------------------- parse arguments -----------------------------
ENV=""
SKIP_DNS_CHECK=0
REGISTER_VPS=0

while [ $# -gt 0 ]; do
  case "$1" in
    --env)
      [ "${2:-}" != "" ] || die "--env requires a value: local, dev, qa, or prod"
      ENV="$2"
      shift 2
      ;;
    --env=*)
      ENV="${1#--env=}"
      shift
      ;;
    --skip-dns-check) SKIP_DNS_CHECK=1; shift ;;
    --register-vps) REGISTER_VPS=1; shift ;;
    -h|--help)
      sed -n '2,/^$/s/^# \{0,1\}//p' "$0"
      exit 0
      ;;
    -*)
      die "unknown flag: $1"
      ;;
    *)
      if [ -z "$ENV" ]; then
        # positional argument = env (backward compat with old ./deploy.sh qa)
        case "$1" in
          local|dev|qa|prod) ENV="$1" ;;
          *) die "unknown argument: $1 (use --env {local|dev|qa|prod})" ;;
        esac
      else
        die "unknown argument: $1"
      fi
      shift
      ;;
  esac
done

[ -n "$ENV" ] || die "missing --env {local|dev|qa|prod}"

# ------------------------- load environment ----------------------------
ENV_FILE="$SCRIPT_DIR/deploy/$ENV/.env"
[ -f "$ENV_FILE" ] || die "env file not found: $ENV_FILE"
say "Loading environment: $ENV ($ENV_FILE)"

# Source .env — export all vars so they're available to the script
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

# Validate required vars
if [ "$ENV" != "local" ]; then
  for var in APP_HOST VPS_HOST DOMAIN APP_HOST_IP APP_DIR WEB_ROOT REGISTRY_IMAGE_TAG; do
    eval "val=\${$var:-}"
    [ -n "$val" ] || die "missing required var $var in $ENV_FILE"
  done
fi

# ------------------------- local mode ----------------------------------
if [ "$ENV" = "local" ]; then
  say "Starting local development stack"
  cd "$SCRIPT_DIR"

  say "Starting Docker services (docker/docker-compose.yml)"
  ( cd docker && docker compose up -d )
  say "Local stack is up."
  printf '  Backend :  http://localhost:%s\n' "${BACKEND_PORT:-8080}"
  printf '  Frontend:  http://localhost:%s\n' "${FRONTEND_PORT:-3000}"
  printf '  Directus:  http://localhost:%s\n' "${DIRECTUS_PORT:-8055}"
  exit 0
fi

# ------------------------- preflight (remote) --------------------------
say "Preflight ($ENV)"
command -v ssh >/dev/null || die "openssh client not found"
command -v rsync >/dev/null || die "rsync not found locally"
cd "$SCRIPT_DIR"

ssh -o ConnectTimeout=10 -o BatchMode=yes "$APP_HOST" true || die "cannot ssh to '$APP_HOST'"
ssh -o ConnectTimeout=10 -o BatchMode=yes "$VPS_HOST" true || die "cannot ssh to '$VPS_HOST'"
ssh "$APP_HOST" "command -v docker >/dev/null && command -v docker >/dev/null" || die "docker not installed on '$APP_HOST'"
ssh "$APP_HOST" "sudo -n true" 2>/dev/null || die "passwordless sudo required on '$APP_HOST'"

if [ "$SKIP_DNS_CHECK" = "0" ]; then
  if command -v dig >/dev/null 2>&1; then
    SERVER_IP="$(dig +short "$VPS_HOST" | head -1)"
    [ -n "$SERVER_IP" ] || die "cannot resolve $VPS_HOST"
    resolved="$(dig +short "$DOMAIN" | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' || true)"
    if [ -z "$resolved" ]; then
      die "no A record for $DOMAIN yet. Add  A  $DOMAIN -> $SERVER_IP  at your DNS provider."
    fi
    case "$resolved" in
      *"$SERVER_IP"*) say "DNS ok: $DOMAIN -> $SERVER_IP" ;;
      *) die "$DOMAIN resolves to [$resolved], not $SERVER_IP. Fix DNS before continuing." ;;
    esac
  else
    say "dig not found; skipping DNS check (--skip-dns-check implied)"
  fi
fi

# ------------------------- upload (app server) -------------------------
say "Uploading shared configs to $APP_HOST"
ssh "$APP_HOST" "mkdir -p '$REMOTE_WORK' && sudo mkdir -p '$APP_DIR' '$WEB_ROOT'"

scp -q "$SCRIPT_DIR/deploy/shared/docker/docker-compose.infra.yml" "$APP_HOST:$REMOTE_WORK/docker-compose.infra.yml"
scp -q "$SCRIPT_DIR/deploy/shared/docker/docker-compose.app.yml"   "$APP_HOST:$REMOTE_WORK/docker-compose.app.yml"
scp -q "$SCRIPT_DIR/deploy/shared/docker/docker-compose.nginx.yml" "$APP_HOST:$REMOTE_WORK/docker-compose.nginx.yml"
scp -q "$SCRIPT_DIR/deploy/shared/nginx/app-server.conf"           "$APP_HOST:$REMOTE_WORK/app-server.conf"

ssh "$APP_HOST" "sudo install -o root -g root -m 0644 '$REMOTE_WORK/docker-compose.infra.yml' '$APP_DIR/docker-compose.infra.yml'"
ssh "$APP_HOST" "sudo install -o root -g root -m 0644 '$REMOTE_WORK/docker-compose.app.yml'   '$APP_DIR/docker-compose.app.yml'"
ssh "$APP_HOST" "sudo install -o root -g root -m 0644 '$REMOTE_WORK/docker-compose.nginx.yml' '$APP_DIR/docker-compose.nginx.yml'"

# ------------------------- write .env (app server) ---------------------
say "Writing mercadomio.env on $APP_HOST"
ENV_FILE_REMOTE="$REMOTE_WORK/mercadomio.env"
{
  echo "REGISTRY=$REGISTRY"
  echo "REGISTRY_IMAGE_TAG=$REGISTRY_IMAGE_TAG"
  echo "BACKEND_PORT=${BACKEND_PORT:-8083}"
  echo "FRONTEND_PORT=${FRONTEND_PORT:-8084}"
  echo "ADMIN_PORT=${ADMIN_PORT:-8085}"
  echo "DIRECTUS_PORT=${DIRECTUS_PORT:-8055}"
  echo "IMGVAULT_PORT=${IMGVAULT_PORT:-8081}"
  echo "MINIO_PORT=${MINIO_PORT:-9000}"
  echo "DOMAIN=$DOMAIN"
  echo "USERBREW_ISSUER=${USERBREW_ISSUER}"
  echo "USERBREW_DISCOVERY_URL=${USERBREW_DISCOVERY_URL}"
  echo "MONGO_URI=${MONGO_URI:-mongodb://mongo:27017/mercadomio}"
  echo "REDIS_ADDR=${REDIS_ADDR:-redis:6379}"
  echo "REDIS_URI=${REDIS_URI:-redis://redis:6379}"
  echo "DIRECTUS_URL=${DIRECTUS_URL:-http://127.0.0.1:8055}"
  echo "IMGVAULT_URL=${IMGVAULT_URL:-http://127.0.0.1:8081}"
  echo "IMGVAULT_API_KEY="REDACTED"
  echo "CORS_ORIGINS=${CORS_ORIGINS:-https://$DOMAIN}"
} > "/tmp/mercadomio.env.$ENV"
scp -q "/tmp/mercadomio.env.$ENV" "$APP_HOST:$ENV_FILE_REMOTE"
ssh "$APP_HOST" "sudo install -o root -g root -m 0600 '$ENV_FILE_REMOTE' '$APP_DIR/mercadomio.env'"

# ------------------------- pull + start infra --------------------------
say "Ensuring shared network + starting infra (postgres/mongo/redis/directus/imgvault/minio)"
ssh "$APP_HOST" "sudo docker network inspect mercadomio-net >/dev/null 2>&1 || sudo docker network create mercadomio-net"
ssh "$APP_HOST" "sudo sh -c 'set -a; . $APP_DIR/mercadomio.env; set +a; docker compose -f $APP_DIR/docker-compose.infra.yml pull; docker compose -f $APP_DIR/docker-compose.infra.yml up -d'"

# ------------------------- pull + start app ----------------------------
say "Pulling + starting app (backend/frontend/admin) from Gitea registry"
ssh "$APP_HOST" "sudo sh -c 'set -a; . $APP_DIR/mercadomio.env; set +a; docker compose -f $APP_DIR/docker-compose.app.yml pull; docker compose -f $APP_DIR/docker-compose.app.yml up -d'"

# ------------------------- app nginx (:8080) ----------------------------
say "Deploying app-nginx (:8080) on $APP_HOST"
NGINX_DIR="$APP_DIR/nginx"
ssh "$APP_HOST" "sudo mkdir -p '$NGINX_DIR'"

# Render app-server.conf with envsubst (ports baked in)
envsubst '${BACKEND_PORT} ${FRONTEND_PORT} ${ADMIN_PORT} ${DIRECTUS_PORT} ${IMGVAULT_PORT}' \
  < "$SCRIPT_DIR/deploy/shared/nginx/app-server.conf" > "/tmp/mercadomio-app-nginx.conf"
scp -q "/tmp/mercadomio-app-nginx.conf" "$APP_HOST:$REMOTE_WORK/mercadomio-nginx.conf"
ssh "$APP_HOST" "sudo install -o root -g root -m 0644 '$REMOTE_WORK/mercadomio-nginx.conf' '$NGINX_DIR/mercadomio-nginx.conf'"

scp -q "$SCRIPT_DIR/deploy/shared/docker/docker-compose.nginx.yml" "$APP_HOST:$REMOTE_WORK/docker-compose.nginx.yml"
ssh "$APP_HOST" "sudo install -o root -g root -m 0644 '$REMOTE_WORK/docker-compose.nginx.yml' '$NGINX_DIR/docker-compose.nginx.yml'"

ssh "$APP_HOST" "sudo sh -c 'set -a; . $APP_DIR/mercadomio.env; set +a; cd $NGINX_DIR && docker compose -f docker-compose.nginx.yml pull; docker compose -f docker-compose.nginx.yml up -d'"

# ------------------------- storefront SPA (app server) ------------------
# The storefront SPA is served statically by app-nginx from WEB_ROOT. If a web
# build exists locally, sync it; otherwise it's expected to be provided out of
# band (e.g. built in CI and synced).
WEB_BUILD="$SCRIPT_DIR/frontend/build/web"
if [ -f "$WEB_BUILD/index.html" ]; then
  say "Syncing storefront web build -> $APP_HOST:$WEB_ROOT"
  rsync -az --delete -e ssh --rsync-path="sudo rsync" "$WEB_BUILD/" "$APP_HOST:$WEB_ROOT/"
  ssh "$APP_HOST" "sudo ls '$WEB_ROOT/index.html' >/dev/null" || die "web files did not land on $APP_HOST"
else
  say "No local web build at $WEB_BUILD; skipping SPA sync (serve from container or pre-provisioned webroot)"
fi

# ------------------------- smoke test (app server) ----------------------
say "Smoke test: app-nginx answering on :8080"
ok=0
for _ in $(seq 1 30); do
  st="$(ssh "$APP_HOST" "curl -sf -m 3 'http://127.0.0.1:8080/' >/dev/null && echo up" 2>/dev/null || true)"
  [ "$st" = "up" ] && ok=1 && break
  sleep 3
done
[ "$ok" = "1" ] || die "app-nginx not answering on :8080; check 'sudo docker logs $ENV-mercadomio-nginx' on $APP_HOST"

# ------------------------- VPS (optional) ------------------------------
if [ "$REGISTER_VPS" = "1" ]; then
  say "Registering on $VPS_HOST (nginx block + TLS cert)"

  VPS_NGINX_DIR="/root/sonnora-compose/nginx"
  VPS_COMPOSE="/root/sonnora-compose/docker-compose.yml"
  VPS_ACME_WEBROOT="/var/www/astro"
  VPS_CONF_SRC="$SCRIPT_DIR/deploy/$ENV/sonnora/vps.conf"

  [ -f "$VPS_CONF_SRC" ] || die "VPS nginx config not found: $VPS_CONF_SRC"

  # Upload VPS nginx block into the sonnora-nginx compose mounts
  ssh "$VPS_HOST" "sudo mkdir -p '$VPS_NGINX_DIR'"
  scp -q "$VPS_CONF_SRC" "$VPS_HOST:$REMOTE_WORK/vps.conf"
  ssh "$VPS_HOST" "sudo install -o root -g root -m 0644 '$REMOTE_WORK/vps.conf' '$VPS_NGINX_DIR/$ENV.conf'"

  # Ensure the compose mounts the env conf + serves the SPA root
  if ssh "$VPS_HOST" "grep -q './nginx/$ENV.conf:/etc/nginx/conf.d/$ENV.conf:ro' '$VPS_COMPOSE' && grep -q '/var/www/mercadomio:/var/www/mercadomio' '$VPS_COMPOSE'"; then
    echo "mounts already present in $VPS_COMPOSE"
  else
    cat > "/tmp/edit_compose_mounts_$ENV.py" <<'PYEOF'
#!/usr/bin/env python3
import re, shutil, sys

COMPOSE_PATH = sys.argv[1]
CONF_NAME = sys.argv[2]

NEW_MOUNTS = [
    f"./nginx/{CONF_NAME}.conf:/etc/nginx/conf.d/{CONF_NAME}.conf:ro",
    "/var/www/mercadomio:/var/www/mercadomio",
]

text = open(COMPOSE_PATH).read()
if all(m in text for m in NEW_MOUNTS):
    print("mounts already present")
    sys.exit(0)

lines = text.split("\n")
nginx_idx = None
for i, l in enumerate(lines):
    if re.match(r"^\s+nginx:\s*$", l):
        nginx_idx = i
        break
if nginx_idx is None:
    print("ERROR: nginx service not found in compose file", file=sys.stderr)
    sys.exit(1)

volumes_idx = None
for i in range(nginx_idx + 1, len(lines)):
    if re.match(r"^\s+volumes:\s*$", lines[i]):
        volumes_idx = i
        break
if volumes_idx is None:
    print("ERROR: no volumes key under nginx service", file=sys.stderr)
    sys.exit(1)

item_re = re.compile(r"^(\s+)-\s")
items = []
start = None
for i in range(volumes_idx + 1, len(lines)):
    l = lines[i]
    m = item_re.match(l)
    if m:
        ind = m.group(1)
        if start is None:
            start = ind
        if ind == start:
            items.append(i)
        else:
            break
    elif l.strip() == "":
        continue
    elif start is not None:
        break
if not items:
    print("ERROR: no volume items under nginx service", file=sys.stderr)
    sys.exit(1)

uid = items[-1]
add_lines = [start + "- " + m for m in NEW_MOUNTS if not any(m.split(":")[0] in l for l in lines)]
if add_lines:
    shutil.copyfile(COMPOSE_PATH, COMPOSE_PATH + ".bak")
    new = lines[: uid + 1] + add_lines + lines[uid + 1:]
    open(COMPOSE_PATH, "w").write("\n".join(new))
    print("inserted mounts: " + ", ".join(NEW_MOUNTS))
else:
    print("nothing to insert")
PYEOF
    scp -q "/tmp/edit_compose_mounts_$ENV.py" "$VPS_HOST:$REMOTE_WORK/edit_compose_mounts.py"
    ssh "$VPS_HOST" "sudo python3 '$REMOTE_WORK/edit_compose_mounts.py' '$VPS_COMPOSE' '$ENV'"
    ssh "$VPS_HOST" "cd '$(dirname "$VPS_COMPOSE")' && sudo docker compose config --quiet" ||
      { ssh "$VPS_HOST" "sudo cp '$VPS_COMPOSE.bak' '$VPS_COMPOSE'"; die "compose edit invalid; restored backup"; }
  fi

  # Recreate nginx and reload
  ssh "$VPS_HOST" "sudo docker compose -f '$VPS_COMPOSE' up -d nginx"
  ssh "$VPS_HOST" "sudo docker exec sonnora-nginx nginx -t" || die "nginx -t failed on sonnora-nginx"
  ssh "$VPS_HOST" "sudo docker exec sonnora-nginx nginx -s reload"

  # TLS cert
  say "Ensuring Let's Encrypt certificate for $DOMAIN"
  if ssh "$VPS_HOST" "sudo test -f '/etc/letsencrypt/live/$DOMAIN/fullchain.pem'"; then
    say "Certificate for $DOMAIN already exists"
  else
    ssh "$VPS_HOST" "sudo certbot certonly --webroot -w '$VPS_ACME_WEBROOT' -d '$DOMAIN' --non-interactive --agree-tos --register-unsafely-without-email --keep-until-expiring"
  fi
  ssh "$VPS_HOST" "sudo test -f '/etc/letsencrypt/live/$DOMAIN/fullchain.pem'" || die "cert not issued for $DOMAIN"
fi

# ------------------------- done ----------------------------------------
say "Done."
printf '  Env     :  %s\n' "$ENV"
printf '  Web UI  :  https://%s\n' "$DOMAIN"
printf '  Backend :  http://%s:%s\n' "$APP_HOST" "$BACKEND_PORT"
printf '  Frontend:  http://%s:%s\n' "$APP_HOST" "$FRONTEND_PORT"
printf '  Admin   :  http://%s:%s\n' "$APP_HOST" "$ADMIN_PORT"
if [ "$REGISTER_VPS" = "1" ]; then
  printf '  VPS     :  %s nginx block + TLS cert installed\n' "$VPS_HOST"
fi
