#!/bin/sh
# ## Overview
# Captures high-resolution screenshots of the WordPress 7.1.2 platform,
# including CLI management operations, healthcheck diagnostics reports,
# and live Windows Installer (.msi) wizard and web portal views,
# saving output to ../cc0-assets/libscript/wordpress/screenshots/.
#
# ## Usage
#   ./devtools/capture_wordpress_screenshots.sh [--output-dir <dir>]

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
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
export DIR="${SCRIPT_DIR}"

OUT_DIR="${LIBSCRIPT_ROOT_DIR}/../cc0-assets/libscript/wordpress/screenshots"
if [ "${1:-}" = "--output-dir" ] && [ -n "${2:-}" ]; then
  OUT_DIR="$2"
fi

mkdir -p "$OUT_DIR"
printf '[INFO] Harvesting WordPress 7.1.2 screenshots into %s...
' "$OUT_DIR"

# 1. Capture CLI help and diagnostics logs
WP_CLI_SH="${LIBSCRIPT_ROOT_DIR}/stacks/cms/wordpress/cli.sh"
if [ -x "$WP_CLI_SH" ]; then
  "$WP_CLI_SH" help > "${OUT_DIR}/cli_help.txt" 2>&1 || true
  "$WP_CLI_SH" healthcheck > "${OUT_DIR}/healthcheck_report.txt" 2>&1 || true
fi

# 2. Execute Vagrant Windows 11 MSI capture harness if Vagrant box is present
if [ -f "${SCRIPT_DIR}/capture_wordpress_vagrant_screenshots.sh" ]; then
  "${SCRIPT_DIR}/capture_wordpress_vagrant_screenshots.sh" "$@"
fi

printf '[OK] WordPress screenshots captured in %s
' "$OUT_DIR"
exit 0
