#!/usr/bin/env bash
set -euo pipefail

REPO="your-username/your-repo"
BRANCH="main"
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="skills"
RAW_URL="<https://raw.githubusercontent.com/$REPO/$BRANCH/$SCRIPT_NAME>"

# Colors
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
NC='\\033[0m'

info()    { echo -e "${GREEN}[skills]${NC} $*"; }
warning() { echo -e "${YELLOW}[skills]${NC} $*"; }
error()   { echo -e "${RED}[skills]${NC} $*" >&2; exit 1; }

# Check OS
if [[ "$(uname -s)" != "Linux" ]]; then
  error "This installer currently supports Linux only."
fi

# Check dependencies
info "Checking dependencies..."

if ! command -v docker &>/dev/null; then
  error "Docker is not installed. Install it first: <https://docs.docker.com/engine/install/ubuntu/>"
fi

if ! command -v curl &>/dev/null; then
  error "curl is not installed. Run: sudo apt-get install -y curl"
fi

# Determine install directory (no sudo needed if ~/.local/bin)
if [[ -w "$INSTALL_DIR" ]]; then
  TARGET="$INSTALL_DIR/$SCRIPT_NAME"
elif [[ -n "${SUDO_USER:-}" ]] || command -v sudo &>/dev/null; then
  TARGET="$INSTALL_DIR/$SCRIPT_NAME"
  USE_SUDO=true
else
  INSTALL_DIR="$HOME/.local/bin"
  mkdir -p "$INSTALL_DIR"
  TARGET="$INSTALL_DIR/$SCRIPT_NAME"
  warning "No sudo available, installing to $INSTALL_DIR"
fi

# Download
info "Downloading skills script from GitHub..."
TMP=$(mktemp)
curl -fsSL "$RAW_URL" -o "$TMP" || error "Download failed. Check the URL: $RAW_URL"
chmod +x "$TMP"

# Install
if [[ "${USE_SUDO:-false}" == "true" ]]; then
  sudo mv "$TMP" "$TARGET"
else
  mv "$TMP" "$TARGET"
fi

# PATH check
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
  warning "$INSTALL_DIR is not in your PATH."
  warning "Add this to your ~/.bashrc or ~/.zshrc:"
  echo ""
  echo "  export PATH=\\"$INSTALL_DIR:\\$PATH\\""
  echo ""
fi

info "Installed successfully → $TARGET"
info "Run 'skills install' in any project with a .skills file."
