#!/usr/bin/env bash
set -euo pipefail

TARGET_ROOT="${TARGET_ROOT:-$PWD}"
MANIFEST="$TARGET_ROOT/.agents-managed.json"
MANAGED_START="# begin agent-setup managed"
MANAGED_END="# end agent-setup managed"
ALLOW_BROAD_CLEANUP="${AGENT_CLEANUP_ALL:-0}"

BROAD_AGENT_PATHS=(
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

load_manifest_paths() {
  if [[ ! -f "$MANIFEST" ]]; then
    return 1
  fi

  /usr/bin/python3 - "$MANIFEST" <<'PY'
import json
import sys
from pathlib import PurePosixPath

manifest_path = sys.argv[1]
try:
    data = json.load(open(manifest_path, encoding="utf-8"))
except Exception as exc:
    print(f"cleanup: invalid manifest: {exc}", file=sys.stderr)
    sys.exit(2)

if data.get("tool") != "agent-setup":
    print("cleanup: refusing manifest whose tool is not agent-setup", file=sys.stderr)
    sys.exit(2)

paths = data.get("owned_paths")
if not isinstance(paths, list):
    print("cleanup: manifest missing owned_paths list", file=sys.stderr)
    sys.exit(2)

for raw in paths:
    if not isinstance(raw, str) or not raw:
        print(f"cleanup: invalid owned path: {raw!r}", file=sys.stderr)
        sys.exit(2)
    p = PurePosixPath(raw)
    if p.is_absolute() or ".." in p.parts:
        print(f"cleanup: unsafe owned path: {raw}", file=sys.stderr)
        sys.exit(2)
    print(raw)
PY
}

remove_paths() {
  local path
  for path in "$@"; do
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
  local paths=()

  log "cleaning agent setup files in $TARGET_ROOT"

  local manifest_output=""
  if manifest_output="$(load_manifest_paths)"; then
    while IFS= read -r path; do
      [[ -n "$path" ]] || continue
      paths+=("$path")
    done <<EOF
$manifest_output
EOF
    remove_paths "${paths[@]}"
  elif [[ "$ALLOW_BROAD_CLEANUP" == "1" ]]; then
    log "manifest missing/invalid; AGENT_CLEANUP_ALL=1 set, using broad cleanup"
    remove_paths "${BROAD_AGENT_PATHS[@]}"
  else
    printf 'agent-cleanup: no valid %s found; refusing broad cleanup.\n' "$MANIFEST" >&2
    printf 'agent-cleanup: set AGENT_CLEANUP_ALL=1 only if you intentionally want to remove common agent paths.\n' >&2
    exit 1
  fi

  remove_gitignore_block
  log "agent setup cleanup complete"
}

main "$@"
