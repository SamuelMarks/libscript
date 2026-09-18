#!/bin/sh
# ## Overview
# Creates and configures an IIS site and FastCGI handler.
#
# ## Usage
# ./create_server_block.sh [options]
# When running on Windows environments (or under Cygwin/MSYS2), delegates
# execution to create_server_block.ps1 via PowerShell.

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

PS1_SCRIPT="${SCRIPT_DIR}/create_server_block.ps1"

if command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "${PS1_SCRIPT}" 2>/dev/null || printf '%s' "${PS1_SCRIPT}")" "$@"
elif command -v pwsh >/dev/null 2>&1; then
  pwsh -NoProfile -File "${PS1_SCRIPT}" "$@"
else
  printf '%s\n' "IIS server block creation requires PowerShell on Windows." >&2
  exit 1
fi
