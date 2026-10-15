#!/bin/sh
# ## Overview
# Captures pixel-perfect screenshots of every step and enumeration in the Open edX
# Windows Installer (.msi) wizard using Vagrant Windows 11 and QEMU screendump.
#
# ## Usage
# ./devtools/capture_openedx_screenshots.sh [OPTIONS]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
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

# ## show_help
# Displays usage and option information.
show_help() {
  printf '%s\n' "Usage: $(basename "$THIS_FILE") [--help]"
  printf '%s\n' "Automates capturing screenshots of the Open edX MSI installer."
  exit 0
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  show_help
fi

# ## main
# Executes primary screenshot routine by delegating to capture_openedx_vagrant_screenshots.sh.
main() {
  "${SCRIPT_DIR}/capture_openedx_vagrant_screenshots.sh" "$@"
}

main "$@"
