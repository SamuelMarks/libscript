#!/bin/sh
# ## Overview
# Automates launching Microsoft Edge with LMS and Studio tabs, toggling tab focus, and signaling screenshot capture.
# Invokes capture_browser_tabs.ps1 via PowerShell on Windows.
#
# ## Usage
# ./packaging/capture_browser_tabs.sh [-LmsUrl <url>] [-StudioUrl <url>]

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

PS_SCRIPT="${SCRIPT_DIR}/capture_browser_tabs.ps1"
if [ ! -f "${PS_SCRIPT}" ] && [ -f "C:/libscript/capture_browser_tabs.ps1" ]; then
  PS_SCRIPT="C:/libscript/capture_browser_tabs.ps1"
fi

if command -v powershell.exe >/dev/null 2>&1; then
  WIN_PS_SCRIPT="$(cygpath -w "${PS_SCRIPT}" 2>/dev/null || printf '%s' "${PS_SCRIPT}")"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${WIN_PS_SCRIPT}" "$@"
elif command -v pwsh >/dev/null 2>&1; then
  pwsh -NoProfile -ExecutionPolicy Bypass -File "${PS_SCRIPT}" "$@"
else
  printf '%s
' "Browser tab automation requires PowerShell on Windows." >&2
  exit 1
fi
