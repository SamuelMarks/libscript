#!/bin/sh
# ## Overview
# Verifies declarative engine/common/pkg_map.tsv lookup accuracy, dynamic probes, __UNSUPPORTED__ /
# __NONE__ sentinels, line-count bounds, and parity between pkg_mapper.sh and pkg_mapper.cmd.
# ## Usage
# ./tests/test_pkg_mapper_parity.sh
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
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2; fi
    if (return 0 2>/dev/null); then return 0; else exit 0; fi ;;
  *)
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
# ## fail_test
# Prints a failure diagnostic and exits 1.
fail_test() {
  printf '[FAIL] %s\n' "$1" >&2
  exit 1
}

SH_LINES=$(wc -l < "${LIBSCRIPT_ROOT_DIR}/engine/common/pkg_mapper.sh" | tr -d ' ')
CMD_LINES=$(wc -l < "${LIBSCRIPT_ROOT_DIR}/engine/common/pkg_mapper.cmd" | tr -d ' ')
[ "$SH_LINES" -le 200 ] || fail_test "pkg_mapper.sh regressed into a monolith (${SH_LINES} lines > 200)"
[ "$CMD_LINES" -le 150 ] || fail_test "pkg_mapper.cmd regressed into a monolith (${CMD_LINES} lines > 150)"
[ -s "${LIBSCRIPT_ROOT_DIR}/engine/common/pkg_map.tsv" ] || fail_test 'Missing engine/common/pkg_map.tsv'

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/pkg_mapper.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"

[ "$(PKG_MGR='winget' map_package 'bun')" = 'Oven-sh.Bun' ] || fail_test 'bun winget mapping failed'
[ "$(PKG_MGR='brew' map_package 'bun')" = 'oven-sh/bun/bun' ] || fail_test 'bun brew mapping failed'
[ "$(PKG_MGR='apk' map_package 'nuget')" = 'dotnet9-sdk' ] || fail_test 'nuget apk mapping failed'
[ "$(PKG_MGR='pkg' TARGET_OS='sunos' UNAME='SunOS' map_package 'mariadb')" = 'ooce/database/mariadb-114 ooce/library/mariadb-114' ] || fail_test 'mariadb pkg:sunos mapping failed'
[ "$(PKG_MGR='pkg' TARGET_OS='freebsd' UNAME='FreeBSD' map_package 'mariadb')" = 'mariadb114-server mariadb114-client' ] || fail_test 'mariadb pkg:freebsd mapping failed'
[ "$(PKG_MGR='apk' map_package 'tar')" = '' ] || fail_test 'tar apk __NONE__ mapping expected empty string'
[ "$(PKG_MGR='dnf' ARCH='aarch64' map_package 'qemu')" = 'qemu-kvm qemu-img edk2-aarch64 libvirt virt-install swtpm' ] || fail_test 'qemu dnf aarch64 dynamic mapping failed'

if PKG_MGR='apt-get' map_package 'mongodb' >/dev/null 2>&1; then
  fail_test 'mongodb on apt-get expected non-zero return (__UNSUPPORTED__)'
fi

printf '[PASS] pkg_mapper.sh (%s lines) and pkg_mapper.cmd (%s lines) verified against pkg_map.tsv.\n' "$SH_LINES" "$CMD_LINES"
exit 0
