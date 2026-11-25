#!/bin/sh
# ## Overview
# Smoke test for kvikdos verifying 2x install idempotency and 16-bit 8086 .COM execution.
#
# ## Usage
# ./_lib/toolchains/kvikdos/test.sh

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

STACK='' "${SCRIPT_DIR}/cli.sh" install latest >/dev/null
STACK='' "${SCRIPT_DIR}/cli.sh" install latest >/dev/null

SCRIPT_NAME="${SCRIPT_DIR}/env.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

kvikdos --version | grep -q 'kvikdos'

_tmp_dos="${TMPDIR:-/tmp}/kvikdos_test_$$"
mkdir -p "${_tmp_dos}"
# 8086 .COM: MOV DX,0109h ; MOV AH,09h ; INT 21h ; MOV AX,4C00h ; INT 21h ; "[PASS] DOS16_EXEC\r\n$"
printf '\272\014\001\264\011\315\041\270\000\114\315\041[PASS] DOS16_EXEC\r\n$' > "${_tmp_dos}/HELLO.COM"
_out=$(kvikdos --root="${_tmp_dos}" "${_tmp_dos}/HELLO.COM" | LC_ALL=C tr -d '\r')
rm -rf "${_tmp_dos}"
[ "${_out}" = '[PASS] DOS16_EXEC' ]
printf '[PASS] kvikdos 8086 execution and 2x idempotency verified.\n'
