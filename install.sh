#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="konair"
REPO_NAME="skill-manager"
BRANCH="main"

RAW_BASE="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}"
SKILLS_URL="${RAW_BASE}/skills.sh"

INSTALL_DIR="${HOME}/.local/bin"
INSTALL_PATH="${INSTALL_DIR}/skills"

if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
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
  printf '%b[skills]%b %s\n' "${GREEN}" "${NC}" "$*"
}

warn() {
  printf '%b[skills]%b %s\n' "${YELLOW}" "${NC}" "$*" >&2
}

error() {
  printf '%b[skills]%b %s\n' "${RED}" "${NC}" "$*" >&2
}

info() {
  printf '%b[skills]%b %s\n' "${BLUE}" "${NC}" "$*"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    error "Missing dependency: $1"
    exit 1
  fi
}

main() {
  log "Checking dependencies..."
  require_cmd curl
  require_cmd chmod
  require_cmd mkdir
  require_cmd mktemp

  mkdir -p "${INSTALL_DIR}"

  tmp_file="$(mktemp)"
  trap 'rm -f "${tmp_file}"' EXIT

  log "Downloading skills script from GitHub..."
  if ! curl -fL --connect-timeout 15 --retry 3 --retry-delay 1 "${SKILLS_URL}" -o "${tmp_file}"; then
    error "Download failed. Check the URL: ${SKILLS_URL}"
    exit 1
  fi

  if [ ! -s "${tmp_file}" ]; then
    error "Downloaded file is empty: ${SKILLS_URL}"
    exit 1
  fi

  chmod +x "${tmp_file}"
  mv "${tmp_file}" "${INSTALL_PATH}"
  trap - EXIT

  log "Installed to ${INSTALL_PATH}"

  case ":${PATH}:" in
    *":${HOME}/.local/bin:"*)
      log "PATH already contains ${HOME}/.local/bin"
      ;;
    *)
      warn "${HOME}/.local/bin is not in your PATH"
      info "Add this line to your shell config:"
      printf '  export PATH="%s/.local/bin:$PATH"\n' "${HOME}"
      ;;
  esac

  log "Done. Run: skills --help"
}

main "$@"
