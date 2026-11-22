#!/bin/sh
# ## Overview
# Network, DHCP, Win32 bootstrap curl, and C11 REST API service smoketest for ReactOS distributions.
#
# ## Usage
# ./tests/reactos_network_smoke_test.sh [sysroot_path]

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

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM HUP
export LIBSCRIPT_HOME="${TMP_DIR}/home"
export LIBSCRIPT_OFFLINE=1
export LIBSCRIPT_ALLOW_STUB=1

TARGET="${1:-${TMP_DIR}/net-sysroot}"
if [ ! -d "${TARGET}/iso_root" ]; then
  STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/reactos/assemble.sh" \
    "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/reactos/developer-win32-i686.json" "$TARGET" >/dev/null
fi

grep -q 'dhcp' "${TARGET}/iso_root/libscript/nt_scm_services.conf"
grep -q 'libscript-rest-api' "${TARGET}/iso_root/libscript/nt_scm_services.conf"
grep -q 'ComputerName = REACTOS-DEV' "${TARGET}/iso_root/reactos/unattend.inf"
grep -q 'reactos-dev' "${TARGET}/iso_root/ReactOS/System32/drivers/etc/hosts"
grep -q '1.1.1.1,8.8.8.8' "${TARGET}/iso_root/libscript/hivesft_delta.reg"
[ -f "${TARGET}/iso_root/libscript/bootstrap/bin/curl.exe" ]

printf '[OK]       ReactOS network & service smoketest PASSED.\n'
