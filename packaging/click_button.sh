#!/bin/sh
# ## Overview
# Automates finding and clicking UI controls by text in GUI sessions.
# Invokes click_button.ps1 via PowerShell on Windows or provides CLI parity.
#
# ## Usage
# ./packaging/click_button.sh [button_text]

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

PS_SCRIPT="${SCRIPT_DIR}/click_button.ps1"
if [ ! -f "${PS_SCRIPT}" ] && [ -f "C:/libscript/click_button.ps1" ]; then
  PS_SCRIPT="C:/libscript/click_button.ps1"
fi

TARGET_TEXT="${1:-}"
if [ -n "${TARGET_TEXT}" ]; then
  TARGET_FILE="${TEMP:-/tmp}/target_btn.txt"
  printf '%s
' "${TARGET_TEXT}" > "${TARGET_FILE}"
fi

LOG_FILE="${TEMP:-/tmp}/libscript_click.log"

if command -v powershell.exe >/dev/null 2>&1; then
  WIN_PS_SCRIPT="$(cygpath -w "${PS_SCRIPT}" 2>/dev/null || printf '%s' "${PS_SCRIPT}")"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${WIN_PS_SCRIPT}" > "${LOG_FILE}" 2>&1
elif command -v pwsh >/dev/null 2>&1; then
  pwsh -NoProfile -ExecutionPolicy Bypass -File "${PS_SCRIPT}" > "${LOG_FILE}" 2>&1
else
  printf '%s
' "GUI control automation requires PowerShell on Windows." >&2
  exit 1
fi
