#!/usr/bin/env bash

set -euo pipefail

# Determine script location to access bundled dotfiles.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Allow overriding the target home (useful for configuring other users).
TARGET_HOME="${TARGET_HOME:-$HOME}"

# Default tool set if none provided as arguments.
DEFAULT_TOOLS=(git curl tmux vim neovim zsh)
TOOLS=("$@")
if [[ ${#TOOLS[@]} -eq 0 ]]; then
  TOOLS=("${DEFAULT_TOOLS[@]}")
fi

log() {
  printf '[setup] %s\n' "$*"
}

abort() {
  printf '[setup][error] %s\n' "$*" >&2
  exit 1
}

need_sudo() {
  if [[ $EUID -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then
      printf 'sudo '
    else
      abort "This script must run as root or have sudo available."
    fi
  fi
}

detect_package_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    PACKAGE_MANAGER="apt"
  elif command -v dnf >/dev/null 2>&1; then
    PACKAGE_MANAGER="dnf"
  elif command -v yum >/dev/null 2>&1; then
    PACKAGE_MANAGER="yum"
  elif command -v pacman >/dev/null 2>&1; then
    PACKAGE_MANAGER="pacman"
  elif command -v apk >/dev/null 2>&1; then
    PACKAGE_MANAGER="apk"
  elif command -v brew >/dev/null 2>&1; then
    PACKAGE_MANAGER="brew"
  else
    abort "Unsupported environment: no known package manager found."
  fi
}

install_tools() {
  detect_package_manager
  local manager="$PACKAGE_MANAGER"
  local sudo_cmd=""
  log "Installing tools (${TOOLS[*]}) via $manager"

  if [[ "$manager" != "brew" ]]; then
    sudo_cmd="$(need_sudo)"
  fi

  case "$manager" in
    apt)
      ${sudo_cmd}apt-get update -y
      ${sudo_cmd}apt-get install -y "${TOOLS[@]}"
      ;;
    dnf)
      ${sudo_cmd}dnf install -y "${TOOLS[@]}"
      ;;
    yum)
      ${sudo_cmd}yum install -y "${TOOLS[@]}"
      ;;
    pacman)
      ${sudo_cmd}pacman -Sy --noconfirm "${TOOLS[@]}"
      ;;
    apk)
      ${sudo_cmd}apk add --no-cache "${TOOLS[@]}"
      ;;
    brew)
      brew update >/dev/null
      brew install "${TOOLS[@]}"
      ;;
    *)
      abort "Installer for $manager is not implemented."
      ;;
  esac
}

copy_dotfile() {
  local relative_src="$1"
  local relative_dest="${2:-$relative_src}"
  local src="$SCRIPT_DIR/$relative_src"
  local dest="$TARGET_HOME/$relative_dest"

  if [[ ! -e "$src" ]]; then
    log "Skipping $relative_src (not found in repository)."
    return
  fi

  if [[ -e "$dest" ]]; then
    local backup="$dest.bak.$(date +%s)"
    log "Backing up existing $dest to $backup"
    if [[ -d "$dest" && ! -L "$dest" ]]; then
      cp -R "$dest" "$backup"
    else
      cp "$dest" "$backup"
    fi
  fi

  log "Transferring $relative_src to $dest"
  mkdir -p "$(dirname "$dest")"
  # Ensure replacement instead of nesting when copying directories.
  if [[ -d "$dest" && ! -L "$dest" ]]; then
    rm -rf "$dest"
  else
    rm -f "$dest"
  fi

  if [[ -d "$src" && ! -L "$src" ]]; then
    cp -R "$src" "$dest"
  else
    cp "$src" "$dest"
  fi
}

install_mise() {
  curl https://mise.run | sh
  eval "$(mise activate bash)"
  eval "$(mise activate zsh)"
  mise use --global neovim
}

main() {
  install_tools
  copy_dotfile ".bashrc"
  copy_dotfile ".zshrc"
  copy_dotfile "nvim" ".config/nvim"
  copy_dotfile ".tmux.conf"
  install_mise
  log "Devpod setup complete."
}

main "$@"
