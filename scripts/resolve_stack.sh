#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: $0 [OPTIONS]"
  echo "See script source or documentation for more details."
  exit 0
fi


# resolve_stack.sh
# A portable wrapper for the SAT/Constraint solver using jq.
# Usage: ./scripts/resolve_stack.sh <path_to_install.json>

if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_install.json>"
    exit 1
fi

INSTALL_JSON="$1"
SCRIPT_DIR=$(dirname "$0")

# Determine OS
if [ -z "$LIBSCRIPT_TARGET_OS" ]; then
    OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
    case "$OS_NAME" in
        linux*) TARGET_OS="linux" ;;
        darwin*) TARGET_OS="darwin" ;;
        msys*|cygwin*|mingw*) TARGET_OS="windows" ;;
        *) TARGET_OS="$OS_NAME" ;;
    esac
else
    TARGET_OS="$LIBSCRIPT_TARGET_OS"
fi

# Find all manifests. We use basic find for POSIX compliance.
MANIFESTS=$(find "${SCRIPT_DIR}/../_lib" -name manifest.json)

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not installed." >&2
    exit 1
fi

# Run the resolution engine
# shellcheck disable=SC2086
jq --arg target_os "$TARGET_OS" -n '{install: input, manifests: [inputs]}' "$INSTALL_JSON" $MANIFESTS | jq -L "${SCRIPT_DIR}" --arg target_os "$TARGET_OS" -r -f "${SCRIPT_DIR}/resolve_stack.jq"

