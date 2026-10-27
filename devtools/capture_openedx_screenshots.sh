#!/bin/sh
# ## Overview
# Thin declarative caller that captures Open edX .msi wizard stages and post-install
# browser verification screenshots via devtools/capture_running_system.sh.
#
# ## Usage
# ./devtools/capture_openedx_screenshots.sh [OPTIONS]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
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

# ## show_help
# Displays usage and option information.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") [--help]"
  printf '%s
' "Automates capturing screenshots of the Open edX MSI installer and browser interfaces."
  exit 0
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  show_help
fi

# ## main
# Delegates Open edX screenshot capture to capture_running_system.sh.
main() {
  "${SCRIPT_DIR}/capture_running_system.sh" --target _lib/web-apps/openedx "$@"
}

main "$@"
