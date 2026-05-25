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

log "cleaning agent symlinks in $TARGET_ROOT"
for p in "${AGENT_PATHS[@]}"; do
  target="$TARGET_ROOT/$p"
  if [[ -L "$target" ]]; then
    rm -f "$target"
    log "removed symlink $p"
  elif [[ -e "$target" ]]; then
    log "skipping $p (not a symlink, left untouched)"
  fi
done

if [[ -d "$TARGET_ROOT/.agents" ]] && [[ -z "$(ls -A "$TARGET_ROOT/.agents" 2>/dev/null)" ]]; then
  rmdir "$TARGET_ROOT/.agents"
  log "removed empty .agents/"
fi

if [[ -d "$MS" ]]; then
  rm -rf "$MS"
  log "removed tmpfs clone at $MS"
fi

log "cleanup complete"
