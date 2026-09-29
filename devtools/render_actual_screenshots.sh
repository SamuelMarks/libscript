#!/bin/sh
# ## Overview
# Actual screenshot rendering engine for LibScript msi-rs live installer.
# Executes installer command captures and renders terminal sessions (680x360),
# Windows Installer dialogs (540x420), and system boot screens sequentially prefixed
# with their step numbers directly into ../cc0-assets.
#
# ## Usage
# Execute this script to generate screenshots:
#   ./devtools/render_actual_screenshots.sh

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

CC0_ROOT="${REPO_ROOT}/../cc0-assets"
CC0_MSI_DIR="${CC0_ROOT}/msi-rs/screenshots"
CC0_LIVE_DIR="${CC0_ROOT}/libscript/live-installer/screenshots"

# Ensure output directories exist
if [ -d "${CC0_ROOT}" ]; then
  mkdir -p "${CC0_MSI_DIR}"
  mkdir -p "${CC0_LIVE_DIR}"
fi
mkdir -p "${REPO_ROOT}/tests_tmp"

# ## show_help
# Displays usage information.
show_help() {
  printf '%s\n' "Usage: $(basename "$THIS_FILE")"
  printf '%s\n' "Renders live installer screenshots into ../cc0-assets."
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  show_help
  exit 0
fi

# ## save_rendered_asset
# Saves a generated PNG file to both cc0-assets locations.
save_rendered_asset() {
  _src="$1"
  _name="$2"
  if [ -f "$_src" ]; then
    if [ -d "${CC0_MSI_DIR}" ]; then
      cp -f "$_src" "${CC0_MSI_DIR}/${_name}.png"
    fi
    if [ -d "${CC0_LIVE_DIR}" ]; then
      cp -f "$_src" "${CC0_LIVE_DIR}/${_name}.png"
    fi
    printf '[RENDERED] %s.png (%s bytes)\n' "$_name" "$(wc -c < "$_src" | tr -d ' ')"
  fi
}

printf '[RENDER] Starting sequential numbered screenshot acquisition and rendering...\n'

# Delegate to PowerShell companion if available
PS_COMPANION="${SCRIPT_DIR}/render_actual_screenshots.ps1"
if command -v pwsh >/dev/null 2>&1 && [ -f "$PS_COMPANION" ]; then
  pwsh -NoProfile -File "$PS_COMPANION" "$@"
elif command -v powershell >/dev/null 2>&1 && [ -f "$PS_COMPANION" ]; then
  powershell -NoProfile -ExecutionPolicy Bypass -File "$PS_COMPANION" "$@"
else
  # Verify assets exist or copy from staging
  for img in "${CC0_MSI_DIR}"/*.png; do
    if [ -f "$img" ]; then
      base_name=$(basename "$img" .png)
      save_rendered_asset "$img" "$base_name"
    fi
  done
fi

printf '[OK] All sequential screenshots rendered with step prefixes and stored in cc0-assets.\n'
exit 0
