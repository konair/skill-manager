#!/usr/bin/env bash
set -euo pipefail

SKILLS_FILE="${SKILLS_FILE:-.skills}"
SKILLS_IMAGE="node:current-alpine"

# Run npx skills inside Docker, mounting the current working directory
_skills_cmd() {
  docker run --rm \
    -v "$(pwd):/workspace" \
    -w /workspace \
    "$SKILLS_IMAGE" \
    npx --yes skills "$@"
}

# Parse "owner/repo@skill-name" into $REPO and $SKILL
_parse() {
  REPO="${1%@*}"
  SKILL="${1#*@}"
}

# Call a function for each non-empty, non-comment line in .skills
_each_skill() {
  local fn=$1
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*# || -z "${line// }" ]] && continue
    _parse "$line"
    $fn "$REPO" "$SKILL"
  done < "$SKILLS_FILE"
}

_do_install() {
  echo "→ Installing $2 from $1"
  _skills_cmd add "$1" --skill "$2" --yes
}

cmd_install() {
  [[ ! -f "$SKILLS_FILE" ]] && { echo "ERROR: $SKILLS_FILE not found"; exit 1; }
  echo "Installing skills from $SKILLS_FILE..."
  _each_skill _do_install
  echo "Done."
}

cmd_update() {
  echo "Updating all installed skills..."
  _skills_cmd update
}

cmd_outdated() {
  echo "Checking for outdated skills..."
  _skills_cmd check
}

case "${1:-}" in
  install|i)  cmd_install ;;
  update|up)  cmd_update ;;
  outdated)   cmd_outdated ;;
  *)
    echo "Usage: $(basename "$0") [install|update|outdated]"
    echo ""
    echo "  install   Install all skills listed in $SKILLS_FILE"
    echo "  update    Update all installed skills to the latest version"
    echo "  outdated  Show skills that have a newer version available"
    exit 1 ;;
esac
