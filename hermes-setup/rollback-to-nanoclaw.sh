#!/usr/bin/env bash
#
# rollback-to-nanoclaw.sh — Undo the switch: stop Hermes, bring NanoClaw back.
# Safe because switch-to-hermes.sh only STOPPED NanoClaw, never deleted it.
#
set -euo pipefail

NANOCLAW_NAME="${NANOCLAW_NAME:-nanoclaw}"
HERMES_COMPOSE="${HERMES_COMPOSE:-./docker-compose.hermes.yml}"

log()  { printf '\033[1;36m[rollback]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[fail ]\033[0m %s\n' "$*" >&2; exit 1; }

command -v docker >/dev/null 2>&1 || die "docker not found. Run on the Mac mini."
docker info >/dev/null 2>&1 || die "Docker daemon not reachable on this machine."

if [[ -f "$HERMES_COMPOSE" ]]; then
  log "Stopping Hermes (compose down)..."
  if docker compose version >/dev/null 2>&1; then
    docker compose -f "$HERMES_COMPOSE" down
  else
    docker-compose -f "$HERMES_COMPOSE" down
  fi
fi

if docker ps -a --format '{{.Names}}' | grep -qx "$NANOCLAW_NAME"; then
  log "Restarting NanoClaw '$NANOCLAW_NAME' and restoring auto-restart..."
  docker start "$NANOCLAW_NAME" >/dev/null
  docker update --restart=unless-stopped "$NANOCLAW_NAME" >/dev/null || true
  log "✅ NanoClaw is back up."
else
  die "No container named '$NANOCLAW_NAME' to restore. Set NANOCLAW_NAME=... if it differs."
fi

docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
