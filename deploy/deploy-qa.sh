#!/bin/bash
#
# Deploy the Mercado Mío stack to the sonnora-qa server (192.168.1.88).
#
# Syncs the backend/frontend source + docker config to /opt/qa/mercadomio on the
# QA host, then builds and starts the QA compose stack.
#
# Usage:
#   ./deploy/deploy-qa.sh

set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"

HOST="sonnora-qa"
REMOTE_DIR="/opt/qa/mercadomio"
COMPOSE_REMOTE="docker compose -f $REMOTE_DIR/docker/docker-compose.qa.yml"

# Try SSH; fallback to ProxyJump via the sonnora VPS when unreachable, mirroring
# deploy-astro.sh behavior.
SSH_JUMP=""
if ! ssh -o ConnectTimeout=5 "$HOST" "echo connected" 2>/dev/null; then
  if ssh -J sonnora -o ConnectTimeout=5 "$HOST" "echo connected" 2>/dev/null; then
    SSH_JUMP="-J sonnora"
  else
    echo "Cannot reach $HOST directly or via sonnora jump host"
    exit 1
  fi
fi

ssh ${SSH_JUMP} "$HOST" "mkdir -p $REMOTE_DIR"

# Push source + docker configuration. Exclude build artifacts, caches, and secrets.
rsync -azz \
  ${SSH_JUMP:+-e "ssh $SSH_JUMP"} \
  --delete \
  --exclude 'backend/local.env' \
  --exclude 'backend/.env' \
  --exclude 'frontend/.dart_tool' \
  --exclude 'frontend/build' \
  --exclude 'admin_console/.dart_tool' \
  --exclude 'admin_console/build' \
  --exclude '.git' \
  --exclude 'network-cache' \
  ./backend/ ./frontend/ ./docker/ ./docs/ "$HOST:$REMOTE_DIR/" >/dev/null

echo "Building and starting QA stack on $HOST..."
ssh ${SSH_JUMP} "$HOST" "$COMPOSE_REMOTE build && $COMPOSE_REMOTE up -d"

# Smoke test: wait for backend health, then ping it.
echo "Waiting for backend health endpoint..."
for i in $(seq 1 30); do
  if ssh ${SSH_JUMP} "$HOST" "curl -sf http://localhost:8083/health" >/dev/null 2>&1; then
    echo "Backend healthy at http://192.168.1.88:8083/health"
    break
  fi
  if [[ $i -eq 30 ]]; then
    echo "Backend did not become healthy. Check: $COMPOSE_REMOTE logs -f backend"
    exit 1
  fi
  sleep 2
done

echo ""
echo "Deployed Mercado Mío QA:"
echo "  Backend:   http://192.168.1.88:8083"
echo "  Frontend:  http://192.168.1.88:8084"
echo "  Directus:  http://192.168.1.88:8055 (admin@mercadomio.mx / admin123)"
echo "  RedisInsight: http://192.168.1.88:8001"
echo ""
echo "Logs:   ssh sonnora-qa \"$COMPOSE_REMOTE logs -f\""
echo "Stop:   ssh sonnora-qa \"$COMPOSE_REMOTE down\""