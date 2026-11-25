#!/bin/sh
# ## Overview
# Smoke test for win-cmd-asm verifying 2x idempotency, asm-conv lowering across NASM/JWasm/FASM/LLVM,
# and 16-bit 8086 execution of WINCMD1.COM, WINCMD.COM, and FINDSTR.COM via kvikdos.
#
# ## Usage
# ./_lib/toolchains/win-cmd-asm/test.sh

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
STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install kvikdos latest >/dev/null

SCRIPT_NAME="${SCRIPT_DIR}/env.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true
for _kvd_b in "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/kvikdos/default/bin" "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/kvikdos/latest/bin"; do
  [ -d "$_kvd_b" ] && PATH="${_kvd_b}:${PATH}"
done
export PATH

asm-conv --version | grep -q 'asm-conv'

_tmp="${TMPDIR:-/tmp}/wca_test_$$"
mkdir -p "${_tmp}"
printf 'BITS 16\nORG 0x100\nret\n' > "${_tmp}/in.asm"
for _fmt in nasm jwasm fasm llvm-mc; do
  asm-conv "--to=${_fmt}" "${_tmp}/in.asm" -o "${_tmp}/out_${_fmt}.asm"
  [ -s "${_tmp}/out_${_fmt}.asm" ]
done

_wca_dir="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/win-cmd-asm/default/target-dos"
[ -f "${_wca_dir}/dos125/WINCMD1.COM" ]
[ -f "${_wca_dir}/dos16/WINCMD.COM" ]
[ -f "${_wca_dir}/dos16/FINDSTR.COM" ]
[ -f "${_wca_dir}/dos16/WHERE.COM" ]

kvikdos --dos-ver=1.25 "${_wca_dir}/dos125/WINCMD1.COM" | LC_ALL=C tr -d '\r' | grep -q 'WINCMD1.COM'
kvikdos --dos-ver=2.0 "${_wca_dir}/dos16/WINCMD.COM" | LC_ALL=C tr -d '\r' | grep -q 'WINCMD.COM'
if printf '::other.cmd::\r\n' | kvikdos --dos-ver=2.0 "${_wca_dir}/dos16/FINDSTR.COM" '/I' '/C:":this.cmd:"'; then
  rm -rf "${_tmp}"
  exit 1
fi
printf ':this.cmd:\r\n' | kvikdos --dos-ver=2.0 "${_wca_dir}/dos16/FINDSTR.COM" '/I' '/C:":this.cmd:"'

rm -rf "${_tmp}"
printf '[PASS] win-cmd-asm (WINCMD1.COM, WINCMD.COM, FINDSTR.COM, asm-conv) verified.\n'
