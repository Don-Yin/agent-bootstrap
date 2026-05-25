#!/usr/bin/env bash
set -euo pipefail

MS="${MS:-/dev/shm/ms}"

log() { printf '>>> %s\n' "$*"; }

install_gh() {
  case "$(uname -s)" in
    Darwin)
      command -v brew >/dev/null 2>&1 || { echo "need Homebrew: https://brew.sh" >&2; exit 1; }
      brew install gh ;;
    Linux)
      if   command -v nix >/dev/null 2>&1; then nix profile install nixpkgs#gh
      elif command -v apt-get >/dev/null 2>&1; then sudo apt-get update && sudo apt-get install -y gh
      elif command -v dnf     >/dev/null 2>&1; then sudo dnf install -y gh
      elif command -v yum     >/dev/null 2>&1; then sudo yum install -y gh
      elif command -v pacman  >/dev/null 2>&1; then sudo pacman -S --needed --noconfirm github-cli
      else echo "install gh manually: https://cli.github.com" >&2; exit 1; fi ;;
    *) echo "unsupported OS: $(uname -s)" >&2; exit 1 ;;
  esac
}

install_git() {
  case "$(uname -s)" in
    Darwin) brew install git ;;
    Linux)
      if   command -v nix >/dev/null 2>&1; then nix profile install nixpkgs#git
      elif command -v apt-get >/dev/null 2>&1; then sudo apt-get update && sudo apt-get install -y git
      elif command -v dnf     >/dev/null 2>&1; then sudo dnf install -y git
      elif command -v yum     >/dev/null 2>&1; then sudo yum install -y git
      elif command -v pacman  >/dev/null 2>&1; then sudo pacman -S --needed --noconfirm git
      else echo "install git manually" >&2; exit 1; fi ;;
  esac
}

command -v git >/dev/null 2>&1 || { log "installing git"; install_git; }
command -v gh >/dev/null 2>&1 || { log "installing GitHub CLI"; install_gh; }

if ! gh auth status >/dev/null 2>&1; then
  log "GitHub CLI not authenticated"
  if [[ -r /dev/tty ]]; then
    gh auth login < /dev/tty
  else
    echo "no TTY for gh auth login. run 'gh auth login' first, then rerun." >&2; exit 1
  fi
fi

if [[ -d "$MS/agents-configurations" ]]; then
  log "already cloned at $MS; pulling latest"
  cd "$MS" && git pull --ff-only 2>/dev/null && cd -
else
  log "cloning machine-setup to $MS (tmpfs)"
  gh repo clone Don-Yin/machine-setup "$MS" -- --depth 1
  cd "$MS" && git sparse-checkout init --cone && git sparse-checkout set agents-configurations rules-compiled utils && cd -
fi

log "running pull-agents.sh"
export MS
DIR_AGENTS_CONFIGURATIONS="$MS/agents-configurations" bash "$MS/utils/pull-agents.sh"

log "done. add to .bashrc if not already set:"
log "  export MS=$MS"
