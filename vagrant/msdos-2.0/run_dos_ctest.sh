#!/bin/sh
# ## Overview
# Stages `DOS32A.EXE` / `DOS4GW.EXE` and `LE`/`MZ` test binaries into the `bento/msdos-2.0`
# Vagrant guest over `COM1` (`:freedos` / `:msdos`), restores `vanilla` snapshot idempotently,
# and emits structured `CTest` JSON results.
#
# ## Usage
# ./vagrant/msdos-2.0/run_dos_ctest.sh [--suite=<name>] [--le-bin=<path>] [--out=<json>] [--dry-run]

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
export LIBSCRIPT_ROOT_DIR

DOS_VAGRANT_DIR="${SCRIPT_DIR}"
DOS_BOX_NAME='msdos-2.0'
export DOS_VAGRANT_DIR DOS_BOX_NAME

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/vagrant/_common/dos_ctest_common.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

parse_dos_ctest_args "$@"
run_dos_com1_harness
