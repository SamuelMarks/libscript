#!/bin/sh
# ## Overview
# Smoke test for _lib/kernel/freedos verifying T2 exit-code-2 on `use`, 2x idempotency,
# KERNEL.SYS/COMMAND.COM staging, and 0x55 0xAA boot-sector signatures on FAT12/16/32 VBRs.
#
# ## Usage
# ./_lib/kernel/freedos/test.sh

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
_rc=$?
set -e
[ "${_rc}" -eq 2 ]

STACK='' "${SCRIPT_DIR}/cli.sh" install 1.4 >/dev/null
STACK='' "${SCRIPT_DIR}/cli.sh" install 1.4 >/dev/null

_bdir="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/freedos/1.4/boot"
[ -s "${_bdir}/KERNEL.SYS" ]
[ -s "${_bdir}/COMMAND.COM" ]
for _vbr in fat12.bin fat16.bin fat32lba.bin; do
  [ -f "${_bdir}/${_vbr}" ]
  od -tx1 -j 510 -N 2 "${_bdir}/${_vbr}" | grep -qi '55.*aa'
done
printf '[PASS] _lib/kernel/freedos 1.4 verified.\n'
