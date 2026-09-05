#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."

fail() { echo "❌ $*" >&2; exit 1; }

echo "🔍 Preflight checks..."
if ! command -v docker >/dev/null 2>&1; then
  fail "docker not found. Install Docker Desktop, or use a runtime like colima."
fi
if ! docker info >/dev/null 2>&1; then
  if command -v colima >/dev/null 2>&1 && colima status >/dev/null 2>&1; then
    fail "docker daemon not reachable. Run 'colima start' and retry."
  fi
  fail "docker daemon not reachable. Run 'colima start' and retry."
fi
echo "  ✅ docker daemon reachable"

if ! command -v zellij >/dev/null 2>&1; then
  fail "zellij not found. Install: brew install zellij"
fi
echo "  ✅ zellij present"

cd "$REPO_ROOT"

rm -f /tmp/mercadomio-docker-ready
zellij delete-session mercadomio 2>/dev/null || true

echo "🚀 Launching Zellij with 4 panes (Docker + Backend + Frontend + Admin)..."
zellij --new-session-with-layout "$SCRIPT_DIR/layout.kdl" --session mercadomio