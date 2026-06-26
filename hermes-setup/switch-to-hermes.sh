#!/usr/bin/env bash
#
# switch-to-hermes.sh — Deactivate NanoClaw and bring up Hermes on the Mac mini.
#
# WHY THIS IS A SCRIPT YOU RUN (not something the web session did for you):
# The Claude Code web/cloud session runs in an ephemeral Linux container that
# CANNOT see your Mac mini's Docker daemon. This script must run *on the Mac
# mini itself* (Terminal, or a Claude session running locally on that machine).
#
# Design goals:
#   - Reversible: NanoClaw is STOPPED + DISABLED (restart policy removed), not
#     deleted. Roll back with ./rollback-to-nanoclaw.sh.
#   - Idempotent: safe to run more than once.
#   - Loud + honest: it prints what it actually did, and fails clearly.
#
# ---------------------------------------------------------------------------
# CONFIG — edit these to match your real setup, or override via env vars:
#   NANOCLAW_NAME   the running NanoClaw container's name (see: docker ps)
#   HERMES_COMPOSE  path to your Hermes docker-compose file (preferred), OR
#   HERMES_NAME     a container name if you start Hermes via `docker run`
# ---------------------------------------------------------------------------
set -euo pipefail

NANOCLAW_NAME="${NANOCLAW_NAME:-nanoclaw}"                 # TODO: confirm with `docker ps`
HERMES_COMPOSE="${HERMES_COMPOSE:-./docker-compose.hermes.yml}"
HERMES_NAME="${HERMES_NAME:-hermes}"

log()  { printf '\033[1;36m[switch]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn ]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[fail ]\033[0m %s\n' "$*" >&2; exit 1; }

# 0. Sanity: are we actually on a machine with a live Docker daemon?
command -v docker >/dev/null 2>&1 || die "docker not found in PATH. Run this on the Mac mini."
docker info >/dev/null 2>&1 || die "Docker daemon not reachable. Is Docker Desktop running on the Mac mini? \
This is the #1 sign you're NOT on the machine that hosts your containers."

# 1. Show current state so you can confirm names before anything changes.
log "Current containers:"
docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
echo

# 2. Deactivate NanoClaw (stop + disable auto-restart; keep the container).
if docker ps -a --format '{{.Names}}' | grep -qx "$NANOCLAW_NAME"; then
  log "Disabling auto-restart on '$NANOCLAW_NAME' (so it stays down across reboots)..."
  docker update --restart=no "$NANOCLAW_NAME" >/dev/null || warn "could not update restart policy"
  if docker ps --format '{{.Names}}' | grep -qx "$NANOCLAW_NAME"; then
    log "Stopping '$NANOCLAW_NAME'..."
    docker stop "$NANOCLAW_NAME" >/dev/null
    log "NanoClaw stopped. (Container kept for rollback — use rollback-to-nanoclaw.sh.)"
  else
    log "NanoClaw '$NANOCLAW_NAME' already stopped."
  fi
else
  warn "No container named '$NANOCLAW_NAME' found. Set NANOCLAW_NAME=... and re-run, \
or confirm NanoClaw is already gone. Continuing to start Hermes."
fi
echo

# 3. Bring up Hermes — prefer compose, fall back to a hint if no compose file.
if [[ -f "$HERMES_COMPOSE" ]]; then
  log "Starting Hermes via compose: $HERMES_COMPOSE"
  if docker compose version >/dev/null 2>&1; then
    docker compose -f "$HERMES_COMPOSE" up -d
  else
    docker-compose -f "$HERMES_COMPOSE" up -d   # legacy v1 fallback
  fi
else
  die "No Hermes compose file at '$HERMES_COMPOSE'. Either:
   - put your Hermes docker-compose there, or
   - set HERMES_COMPOSE=/path/to/your-compose.yml, or
   - start Hermes your usual way (docker run ...) and re-run this with that done.
  I left a template at ./docker-compose.hermes.yml — fill in the TODO markers."
fi
echo

# 4. Verify Hermes is actually up and healthy.
log "Post-switch state:"
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
echo
if docker ps --format '{{.Names}}' | grep -q "$HERMES_NAME"; then
  log "✅ Hermes appears to be running. Tail its logs with:"
  echo "     docker logs -f \$(docker ps --format '{{.Names}}' | grep '$HERMES_NAME' | head -1)"
else
  warn "Could not confirm a running container matching '$HERMES_NAME'. \
Check 'docker ps' and the compose service name."
fi

log "Done. NanoClaw is down (recoverable); Hermes start attempted. Verify above."
