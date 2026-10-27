#!/bin/sh
# ## Overview
# Automates stepping through every stage of .msi GUI installers built with SamuelMarks/msi-rs
# and capturing post-install desktop and browser verification views across Windows, Linux,
# macOS, FreeBSD, and illumos (OmniOS) by delegating to the schema-driven
# devtools/capture_running_system.sh engine.
#
# ## Usage
# ./devtools/capture_msi_vagrant_matrix.sh [--target <name|dir|all>] [--os <windows|linux|macos|freebsd|illumos|all>] [--variant <online|offline|both>] [--flow <quick|custom|both>] [--out-dir <path>]

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
# Prints usage instructions for capture_msi_vagrant_matrix.sh.
show_help() {
  "${SCRIPT_DIR}/capture_running_system.sh" --help
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  show_help
fi

# ## main
# Delegates multi-OS wizard and running-system screenshot capture to capture_running_system.sh.
main() {
  "${SCRIPT_DIR}/capture_running_system.sh" "$@"
}

main "$@"
