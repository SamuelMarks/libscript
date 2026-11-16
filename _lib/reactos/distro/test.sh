#!/bin/sh
# ## Overview
# Component smoke and 2-pass idempotency test suite for reactos-distro.
# Verifies profile assembly, unattend.inf generation, RAPPS staging, and PE header arch enforcement.
#
# ## Usage
# ./_lib/reactos/distro/test.sh

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

_tmp=$(mktemp -d)
trap 'rm -rf "$_tmp"' EXIT INT TERM HUP
export LIBSCRIPT_HOME="${_tmp}/home"
export LIBSCRIPT_OFFLINE=1
export LIBSCRIPT_ALLOW_STUB=1

ACTION='install' STACK='' "${SCRIPT_DIR}/setup.sh"
_sys="${_tmp}/sysroot"
STACK='' "${SCRIPT_DIR}/assemble.sh" "${LIBSCRIPT_ROOT_DIR}/profiles/reactos/desktop-classic-i686.json" "$_sys"
[ -f "${_sys}/iso_root/reactos/unattend.inf" ]
[ -f "${_sys}/iso_root/libscript/firstboot.cmd" ]
[ -f "${_sys}/iso_root/libscript/cache/rapps/7zip.i686.stamp" ]

_pass2=$(STACK='' "${SCRIPT_DIR}/assemble.sh" "${LIBSCRIPT_ROOT_DIR}/profiles/reactos/desktop-classic-i686.json" "$_sys" 2>&1)
printf '%s\n' "$_pass2" | grep -q '\[SKIP\]'

# Verify PE header inspector rejects x86_64 PE against i686 expectation
printf 'MZ\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\100\000\000\000PE\000\000\144\206' > "${_tmp}/bad64.exe"
if STACK='' "${SCRIPT_DIR}/pkg.sh" --check-pe "${_tmp}/bad64.exe" i686 2>/dev/null; then
  printf '[FAIL] pkg.sh failed to reject x86_64 PE binary under i686 check!\n' >&2
  exit 1
fi
STACK='' "${SCRIPT_DIR}/pkg.sh" --check-pe "${_tmp}/bad64.exe" x86_64

printf '[PASS] reactos-distro component tests passed.\n'
