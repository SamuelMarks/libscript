#!/bin/sh
# ## Overview
# Updates the Supported Components table in README.md with test results.
#
# ## Usage
# ./update_results.sh

set -feu

# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
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
THIS_DIR="${SCRIPT_DIR}"
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

if command -v python3 >/dev/null 2>&1; then
    python3 "${THIS_DIR}/update_results.py" "${REPO_ROOT}"
elif command -v python >/dev/null 2>&1; then
    python "${THIS_DIR}/update_results.py" "${REPO_ROOT}"
else
    printf '%s\n' "Error: python3 or python is required to run this script." >&2
    exit 1
fi
