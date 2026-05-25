#!/usr/bin/env bash
set -euo pipefail

TARGET_ROOT="${TARGET_ROOT:-$PWD}"
MANAGED_START="# begin agent-setup managed"
MANAGED_END="# end agent-setup managed"

AGENT_PATHS=(
  ".cursor"
  ".claude"
  ".codex"
  ".agents"
  ".agent-setup"
  ".mcp.json"
  ".rules-compiled"
  "AGENTS.md"
  "CLAUDE.md"
  ".agents-managed.json"
)

log() {
  printf '>>> %s\n' "$*"
}

remove_paths() {
  local path
  for path in "${AGENT_PATHS[@]}"; do
    if [[ -e "$TARGET_ROOT/$path" || -L "$TARGET_ROOT/$path" ]]; then
      rm -rf "$TARGET_ROOT/$path"
      log "removed $path"
    fi
  done
}

remove_gitignore_block() {
  local gitignore="$TARGET_ROOT/.gitignore"
  local tmp

  [[ -f "$gitignore" ]] || return 0
  tmp="$(mktemp)"
  awk -v start="$MANAGED_START" -v end="$MANAGED_END" '
    $0 == start { skipping = 1; next }
    $0 == end { skipping = 0; next }
    !skipping { print }
  ' "$gitignore" > "$tmp"
  mv "$tmp" "$gitignore"
  log "removed .gitignore managed block"
}

main() {
  log "cleaning agent setup files in $TARGET_ROOT"
  remove_paths
  remove_gitignore_block
  log "agent setup cleanup complete"
}

main "$@"
