#!/bin/sh
# ## Overview
# Stages the selected base DOS kernel (_lib/kernel/freedos or _lib/kernel/msdos) and win-cmd-asm
# shell/utilities into LIBSCRIPT_TARGET_SYSROOT according to the active DOS stratum.
#
# ## Usage
# ./synthesis/distro/dos/base.sh [sysroot_dir]

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
DOS_OS="${LIBSCRIPT_TARGET_OS:-freedos}"
DOS_VER="${LIBSCRIPT_DOS_VERSION:-1.4}"
STRATUM="${LIBSCRIPT_DOS_STRATUM:-dos32-dpmi}"

mkdir -p "${SYSROOT}"
if [ "${DOS_OS}" = 'freedos' ]; then
  LIBSCRIPT_TARGET_SYSROOT="${SYSROOT}" FREEDOS_VERSION="${DOS_VER}" ACTION='install' \
    STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/freedos/setup.sh"
else
  LIBSCRIPT_TARGET_SYSROOT="${SYSROOT}" MSDOS_VERSION="${DOS_VER}" ACTION='install' \
    STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/msdos/setup.sh"
fi

LIBSCRIPT_IMAGE_BUILD='1' LIBSCRIPT_TARGET_SYSROOT="${SYSROOT}" LIBSCRIPT_DOS_STRATUM="${STRATUM}" \
  ACTION='install' STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/win-cmd-asm/setup.sh"
