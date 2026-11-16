#!/bin/sh
# ## Overview
# Smoke and 2-pass idempotency test suite for the rosbe cross-toolchain component.
# Verifies isolated installation, version reporting, and target-add idempotency.
#
# ## Usage
# ./_lib/toolchains/rosbe/test.sh

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

_tmp_home=$(mktemp -d)
trap 'rm -rf "$_tmp_home"' EXIT INT TERM HUP
export LIBSCRIPT_HOME="${_tmp_home}/home"
unset LIBSCRIPT_ROSBE_INSTALL_DIR || true
export LIBSCRIPT_OFFLINE=1

ACTION='install' STACK='' "${SCRIPT_DIR}/setup.sh"
_pass2=$(ACTION='install' STACK='' "${SCRIPT_DIR}/setup.sh" 2>&1)
printf '%s\n' "$_pass2" | grep -q '\[SKIP\]'

"${LIBSCRIPT_HOME}/bin/rosbe" --version | grep -q 'RosBE 2.2.1'

STACK='' "${SCRIPT_DIR}/cli.sh" target-add x86_64-w64-mingw32
grep -qx 'x86_64-w64-mingw32' "${LIBSCRIPT_HOME}/rosbe/2.2.1/targets.list"
_t_pass2=$(STACK='' "${SCRIPT_DIR}/cli.sh" target-add x86_64-w64-mingw32)
printf '%s\n' "$_t_pass2" | grep -q '\[SKIP\]'

printf '[PASS] rosbe component tests passed.\n'
