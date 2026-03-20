#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="konair"
REPO_NAME="skill-manager"
BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}"
SKILLS_URL="${RAW_BASE}/skills.sh"

if [ -t 1 ]; then
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
else
  GREEN=''
  RED=''
  YELLOW=''
  BLUE=''
  NC=''
fi

log() {
  printf '%b[skills]%b %s\n' "$GREEN" "$NC" "$*"
}

warn() {
  printf '%b[skills]%b %s\n' "$YELLOW" "$NC" "$*" >&2
}

error() {
  printf '%b[skills]%b %s\n' "$RED" "$NC" "$*" >&2
}

info() {
  printf '%b[skills]%b %s\n' "$BLUE" "$NC" "$*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    error "Missing dependency: $1"
    exit 1
  }
}

path_contains() {
  case ":$PATH:" in
    *":$1:"*) return 0 ;;
    *) return 1 ;;
  esac
}

ensure_line_in_file() {
  local file="$1"
  local line="$2"

  mkdir -p "$(dirname "$file")"
  touch "$file"

  if ! grep -Fqx "$line" "$file"; then
    printf '\n%s\n' "$line" >> "$file"
  fi
}

choose_install_dir() {
  local dir

  for dir in "$HOME/.local/bin" "$HOME/bin" "/usr/local/bin"; do
    if [ -d "$dir" ] && [ -w "$dir" ] && path_contains "$dir"; then
      printf '%s\n' "$dir"
      return 0
    fi
  done

  if [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
    printf '%s\n' "/usr/local/bin"
    return 0
  fi

  printf '%s\n' "$HOME/.local/bin"
}

persist_path_if_needed() {
  local dir="$1"
  local line="export PATH=\"$dir:\$PATH\""
  local shell_name="${SHELL##*/}"

  path_contains "$dir" && return 0

  case "$shell_name" in
    bash)
      ensure_line_in_file "$HOME/.bashrc" "$line"
      ensure_line_in_file "$HOME/.profile" "$line"
      info "Added $dir to PATH in ~/.bashrc and ~/.profile"
      ;;
    zsh)
      ensure_line_in_file "$HOME/.zshrc" "$line"
      info "Added $dir to PATH in ~/.zshrc"
      ;;
    *)
      ensure_line_in_file "$HOME/.profile" "$line"
      info "Added $dir to PATH in ~/.profile"
      ;;
  esac
}

main() {
  require_cmd curl
  require_cmd chmod
  require_cmd mkdir
  require_cmd mktemp
  require_cmd mv

  log "Checking dependencies..."

  local tmp_file install_dir install_path
  tmp_file="$(mktemp)"
  trap 'rm -f "$tmp_file"' EXIT

  log "Downloading skills script from GitHub..."
  if ! curl -fL --connect-timeout 15 --retry 3 --retry-delay 1 "$SKILLS_URL" -o "$tmp_file"; then
    error "Download failed. Check the URL: $SKILLS_URL"
    exit 1
  fi

  if [ ! -s "$tmp_file" ]; then
    error "Downloaded file is empty: $SKILLS_URL"
    exit 1
  fi

  install_dir="$(choose_install_dir)"
  install_path="${install_dir%/}/skills"

  mkdir -p "$install_dir"
  chmod +x "$tmp_file"
  mv "$tmp_file" "$install_path"
  trap - EXIT

  log "Installed to $install_path"

  if path_contains "$install_dir"; then
    log "Command should already be available in this shell: skills"
  else
    persist_path_if_needed "$install_dir"
    warn "Open a new terminal, or run one of these commands:"
    case "${SHELL##*/}" in
      bash)
        printf '  source ~/.bashrc\n'
        ;;
      zsh)
        printf '  source ~/.zshrc\n'
        ;;
      *)
        printf '  source ~/.profile\n'
        ;;
    esac
  fi

  log "Done."
}

main "$@"
