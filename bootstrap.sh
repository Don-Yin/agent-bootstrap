#!/usr/bin/env bash
set -euo pipefail

AGENT_SETUP_REPO="${AGENT_SETUP_REPO:-Don-Yin/agent-setup}"
AGENT_SETUP_BRANCH="${AGENT_SETUP_BRANCH:-main}"
AGENT_SETUP_PROFILE="${AGENT_SETUP_PROFILE:-remote-minimal}"
WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/agent-setup.XXXXXX")"

cleanup() {
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

log() {
  printf '>>> %s\n' "$*"
}

install_gh_macos() {
  if ! command -v brew >/dev/null 2>&1; then
    printf 'agent-setup: Homebrew is required to install GitHub CLI on macOS. install from https://brew.sh, then rerun.\n' >&2
    exit 1
  fi
  brew install gh
}

install_gh_linux() {
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y gh
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y gh
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y gh
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm github-cli
  else
    printf 'agent-setup: could not auto-install GitHub CLI. install gh from https://cli.github.com, then rerun.\n' >&2
    exit 1
  fi
}

ensure_gh() {
  if command -v gh >/dev/null 2>&1; then
    return
  fi

  case "$(uname -s)" in
    Darwin)
      log "GitHub CLI not found; installing with Homebrew"
      install_gh_macos
      ;;
    Linux)
      log "GitHub CLI not found; installing with system package manager"
      install_gh_linux
      ;;
    *)
      printf 'agent-setup: unsupported OS for automatic gh install: %s\n' "$(uname -s)" >&2
      printf 'install gh from https://cli.github.com, then rerun.\n' >&2
      exit 1
      ;;
  esac
}

ensure_auth() {
  if gh auth status >/dev/null 2>&1; then
    return
  fi
  log "GitHub CLI is not authenticated; starting gh auth login"
  if [[ -r /dev/tty ]]; then
    gh auth login < /dev/tty
  else
    printf 'agent-setup: no TTY available for gh auth login. set GH_TOKEN or run gh auth login, then rerun.\n' >&2
    exit 1
  fi
  gh auth status >/dev/null
}

fetch_private_payload() {
  local archive="$WORKDIR/agent-setup.tar.gz"
  log "downloading private agent payload $AGENT_SETUP_REPO@$AGENT_SETUP_BRANCH"
  gh api \
    -H "Accept: application/vnd.github+json" \
    "/repos/$AGENT_SETUP_REPO/tarball/$AGENT_SETUP_BRANCH" > "$archive"
  mkdir -p "$WORKDIR/src"
  tar -xzf "$archive" -C "$WORKDIR/src" --strip-components 1
}

main() {
  ensure_gh
  ensure_auth
  fetch_private_payload
  AGENT_SETUP_MODE=copy AGENT_SETUP_PROFILE="$AGENT_SETUP_PROFILE" "$WORKDIR/src/pull-agents.sh" "$@"
}

main "$@"
