#!/bin/sh
# ## Overview
# Launches Windows Installer (.msi) packages via msiexec.
# Defaults to OpenEdX-Setup.msi if no package path is specified.
#
# ## Usage
# ./packaging/run_msi.sh [path_to_msi]

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

MSI_FILE="${1:-}"
if [ -z "${MSI_FILE}" ]; then
  if [ -f "${SCRIPT_DIR}/OpenEdX-Setup.msi" ]; then
    MSI_FILE="${SCRIPT_DIR}/OpenEdX-Setup.msi"
  elif [ -f "C:/libscript/OpenEdX-Setup.msi" ]; then
    MSI_FILE="C:/libscript/OpenEdX-Setup.msi"
  else
    printf '%s\n' "[ERROR] No MSI installer package found. Please specify the path to the .msi file." >&2
    exit 1
  fi
fi

if command -v msiexec.exe >/dev/null 2>&1; then
  WIN_PATH="$(cygpath -w "${MSI_FILE}" 2>/dev/null || printf '%s' "${MSI_FILE}")"
  msiexec.exe /i "${WIN_PATH}"
elif command -v wine >/dev/null 2>&1; then
  wine msiexec /i "${MSI_FILE}"
else
  printf '%s\n' "Launching MSI packages requires Windows msiexec.exe or Wine." >&2
  exit 1
fi
