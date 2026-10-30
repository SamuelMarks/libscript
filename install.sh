#!/bin/sh
# ## Overview
# Global installer for the libscript framework.
# 
# ## Usage
# Execute this script to install libscript on the local system.

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
LIBSCRIPT_CLI_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
SCRIPT_DIR="${LIBSCRIPT_CLI_DIR}"
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

case "${1:-}" in
  --help|-h|"-?"|"/?")
    printf '%s\n' "Usage: ${THIS_FILE##*/}"
    printf '%s\n' 'Bootstraps the LibScript environment.'
    exit 0
    ;;
esac

printf '%s\n' '========================================'
printf '%s\n' ' LibScript Environment Bootstrap'
printf '%s\n' '========================================'

if ! command -v libscript.sh >/dev/null 2>&1; then
  printf '%s\n' 'To use LibScript, add the following directory to your PATH:'
  printf '%s\n' "  export PATH=\"${LIBSCRIPT_ROOT_DIR}:\$PATH\""
  printf '\n'
  printf '%s\n' 'Alternatively, symlink libscript.sh to /usr/local/bin or similar.'
else
  printf '%s\n' 'libscript.sh is already available in your PATH.'
fi

printf '%s\n' 'Bootstrap complete.'
exit 0
