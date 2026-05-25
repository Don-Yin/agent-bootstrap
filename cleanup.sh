#!/usr/bin/env bash
set -euo pipefail

MS="${MS:-/dev/shm/ms}"
TARGET_ROOT="${TARGET_ROOT:-$PWD}"

log() { printf '>>> %s\n' "$*"; }

AGENT_PATHS=(
  ".agents-configurations"
  ".rules-compiled"
  ".cursor"
  ".claude"
  ".codex"
  ".agents"
  ".mcp.json"
  "AGENTS.md"
  "CLAUDE.md"
)

log "cleaning agent files in $TARGET_ROOT"
for p in "${AGENT_PATHS[@]}"; do
  target="$TARGET_ROOT/$p"
  if [[ -L "$target" || -e "$target" ]]; then
    rm -rf "$target"
    log "removed $p"
  fi
done

if [[ -d "$MS" ]]; then
  rm -rf "$MS"
  log "removed tmpfs clone at $MS"
fi

log "cleanup complete"
