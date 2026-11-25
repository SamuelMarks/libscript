#!/bin/sh
# ## Overview
# Smoke test for _lib/kernel/msdos verifying T2 exit-code-2 on `use`, proprietary version rejection
# (6.22), sanitize_cp437 + scp2nasm unit vectors, asm-conv lowering of bios/*.asm, and 2x idempotent
# builds across all three MIT versions (1.25, 2.0, 4.0).
#
# ## Usage
# ./_lib/kernel/msdos/test.sh

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

set +e
STACK='' "${SCRIPT_DIR}/cli.sh" use latest >/dev/null 2>&1
_use_rc=$?
MSDOS_VERSION=6.22 STACK='' "${SCRIPT_DIR}/setup.sh" >/dev/null 2>&1
_prop_rc=$?
set -e
[ "${_use_rc}" -eq 2 ]
[ "${_prop_rc}" -ne 0 ]

for _v in 1.25 2.0 4.0; do
  MSDOS_VERSION="${_v}" STACK='' "${SCRIPT_DIR}/cli.sh" install "${_v}" >/dev/null
  MSDOS_VERSION="${_v}" STACK='' "${SCRIPT_DIR}/cli.sh" install "${_v}" >/dev/null
  _bdir="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/msdos/${_v}/boot"
  [ -s "${_bdir}/IO.SYS" ]
  [ -s "${_bdir}/MSDOS.SYS" ]
  [ -s "${_bdir}/COMMAND.COM" ]
  od -tx1 -j 510 -N 2 "${_bdir}/mbr_dos.bin" | grep -qi '55.*aa'
  od -tx1 -j 510 -N 2 "${_bdir}/boot_fat12.bin" | grep -qi '55.*aa'
done

# Unit test sanitize_cp437 (UTF-8 EF BF BD -> CP437 0xCD + CRLF) and scp2nasm (UP -> CLD)
_tools="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/msdos/4.0/boot/tools"
_tmp="${TMPDIR:-/tmp}/msdos_ut_$$"
mkdir -p "${_tmp}"
printf '\357\277\275\n\032' > "${_tmp}/corrupt.asm"
"${_tools}/sanitize_cp437" "${_tmp}/corrupt.asm" "${_tmp}/clean.asm"
od -tx1 "${_tmp}/clean.asm" | grep -qi 'cd.*0d.*0a'

printf '    UP\n    DOWN\n    END\n' > "${_tmp}/scp.asm"
"${_tools}/scp2nasm" "${_tmp}/scp.asm" "${_tmp}/nasm.asm"
grep -q 'CLD' "${_tmp}/nasm.asm"
grep -q 'STD' "${_tmp}/nasm.asm"
rm -rf "${_tmp}"
printf '[PASS] _lib/kernel/msdos (1.25, 2.0, 4.0 MIT + sanitize_cp437 + scp2nasm) verified.\n'
