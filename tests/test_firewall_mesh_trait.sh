#!/bin/sh
# ## Overview
# Verifies anti-lockout SSH/WinRM protection, nftables/pf compilation, and WireGuard peer config for traits/firewall and traits/mesh.
#
# ## Usage
# ./tests/test_firewall_mesh_trait.sh

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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

FM_TMP="$(mktemp -d "${TMPDIR:-/tmp}/libscript-fm-test.XXXXXX")"
# ## cleanup_fm_test
# Removes temporary firewall and mesh test directory on exit.
cleanup_fm_test() {
  rm -rf "$FM_TMP"
}
trap cleanup_fm_test EXIT INT TERM

export LIBSCRIPT_TARGET_SYSROOT="$FM_TMP"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/traits/firewall/compile.sh" sh "${LIBSCRIPT_ROOT_DIR}/traits/firewall/compile.sh" postgres nginx
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/traits/firewall/compile.sh" sh "${LIBSCRIPT_ROOT_DIR}/traits/firewall/compile.sh" postgres nginx

grep -q 'LibScript-Anti-Lockout' "${FM_TMP}/etc/nftables.conf"
grep -q 'LibScript-Trait-postgres-5432' "${FM_TMP}/etc/nftables.conf"
grep -q 'LibScript-Trait-nginx-80' "${FM_TMP}/etc/nftables.conf"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/traits/mesh/wireguard.sh" sh "${LIBSCRIPT_ROOT_DIR}/traits/mesh/wireguard.sh" 1
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/traits/mesh/wireguard.sh" sh "${LIBSCRIPT_ROOT_DIR}/traits/mesh/wireguard.sh" 1
grep -q '100.64.0.1/24' "${FM_TMP}/etc/wireguard/wg0.conf"

printf '[PASS] Firewall anti-lockout and WireGuard mesh traits verified.\n'
