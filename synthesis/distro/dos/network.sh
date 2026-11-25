#!/bin/sh
# ## Overview
# Stages Crynwr packet drivers (dos-pktdrv) and generates C:\ETC\WATTCP.CFG via wattcp_cfg.sh
# for hierarchical DOS strata (dos16-handle and dos32-dpmi).
#
# ## Usage
# ./synthesis/distro/dos/network.sh [sysroot_dir]

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

if [ "${STRATUM}" = 'dos16-fcb' ]; then
  exit 0
fi

LIBSCRIPT_IMAGE_BUILD='1' LIBSCRIPT_TARGET_SYSROOT="${SYSROOT}" LIBSCRIPT_DOS_STRATUM="${STRATUM}" \
  ACTION='install' STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/networking/dos-pktdrv/setup.sh"

mkdir -p "${SYSROOT}/ETC"
if [ -x "${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/wattcp_cfg.sh" ]; then
  STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/wattcp_cfg.sh" --out="${SYSROOT}/ETC/WATTCP.CFG" --mode=dhcp >/dev/null 2>&1 || \
    printf 'my_ip = dhcp\r\npkt.vector = 0x60\r\n' > "${SYSROOT}/ETC/WATTCP.CFG"
else
  printf 'my_ip = dhcp\r\npkt.vector = 0x60\r\n' > "${SYSROOT}/ETC/WATTCP.CFG"
fi
