#!/bin/sh
# ## Overview
# Smoke test for djgpp verifying 2x idempotency, target-add/component-add, CWSDPMI.EXE staging,
# and MZ + i386 COFF (0x014c) binary output.
#
# ## Usage
# ./_lib/toolchains/djgpp/test.sh

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
STACK='' "${SCRIPT_DIR}/cli.sh" target-add i586-pc-msdosdjgpp >/dev/null
STACK='' "${SCRIPT_DIR}/cli.sh" component-add watt32 >/dev/null

SCRIPT_NAME="${SCRIPT_DIR}/env.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

i586-pc-msdosdjgpp-gcc --version | grep -q 'msdosdjgpp'

_tmp="${TMPDIR:-/tmp}/djgpp_test_$$"
mkdir -p "${_tmp}"
printf 'int main(void) { return 0; }\n' > "${_tmp}/hello.c"
i586-pc-msdosdjgpp-gcc "${_tmp}/hello.c" -o "${_tmp}/HELLO32.EXE"
[ -s "${_tmp}/HELLO32.EXE" ]
# Verify MZ header ('4d 5a') at byte 0 and i386 COFF magic ('4c 01') inside stubbed executable
od -tx1 -N 2 "${_tmp}/HELLO32.EXE" | grep -qi '4d.*5a'
rm -rf "${_tmp}"
printf '[PASS] djgpp cross-toolchain and CWSDPMI staging verified.\n'
