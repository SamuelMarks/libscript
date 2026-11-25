#!/bin/sh
# ## Overview
# Stages 32-bit DPMI runtimes (CWSDPMI.EXE, DJGPP.ENV, BASH.EXE, DOS32A.EXE, and guest LIBSCRIP.BAT)
# into LIBSCRIPT_TARGET_SYSROOT when LIBSCRIPT_DOS_STRATUM is dos32-dpmi.
#
# ## Usage
# ./synthesis/distro/dos/dpmi.sh [sysroot_dir]

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
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

HOST_LS_HOME="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}"
export LIBSCRIPT_HOME="${HOST_LS_HOME}"
SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/dos-sysroot}}"
STRATUM="${LIBSCRIPT_DOS_STRATUM:-dos32-dpmi}"

if [ "${STRATUM}" != 'dos32-dpmi' ]; then
  exit 0
fi

LIBSCRIPT_IMAGE_BUILD='1' LIBSCRIPT_TARGET_SYSROOT="${SYSROOT}" LIBSCRIPT_DOS_STRATUM='dos32-dpmi' \
  ACTION='install' STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/djgpp/setup.sh"

mkdir -p "${SYSROOT}/LIBSCRIP/BIN" "${SYSROOT}/TMP"
_ow_d32="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/openwatcom/default/binw/dos32a.exe"
if [ -f "${_ow_d32}" ]; then
  cp -f "${_ow_d32}" "${SYSROOT}/DOS/DOS32A.EXE"
fi

printf '@ECHO OFF\r\nECHO [LIBSCRIPT] DOS 32-bit DPMI guest runtime active\r\n' > "${SYSROOT}/LIBSCRIP/LIBSCRIP.BAT"
