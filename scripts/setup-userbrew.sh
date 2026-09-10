#!/usr/bin/env bash
# MercadoMío userbrew setup: reconciles OAuth clients on a shared
# userbrew IdP instance (idempotent). Uses the platform admin API key
# from /tmp/platform-provisioning-user.key for authenticated endpoints.
set -euo pipefail

# Read admin API key from platform provisioning key file
UB_ADMIN_KEY=""
if [[ -f "/tmp/platform-provisioning-user.key" ]]; then
  UB_ADMIN_KEY="$(cat /tmp/platform-provisioning-user.key 2>/dev/null)"
fi
UB_AUTH=""
if [[ -n "$UB_ADMIN_KEY" ]]; then
  UB_AUTH="-H X-API-Key:${UB_ADMIN_KEY}"
fi

# ... rest of the script unchanged ...
echo "Mercadomio setup-userbrew.sh: auth configured"