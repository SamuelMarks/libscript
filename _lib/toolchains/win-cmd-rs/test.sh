#!/bin/sh
# ## Overview
# Test suite for the win-cmd-rs component (wincheck batch static analyzer and wincmd interpreter).
#
# ## Usage
# Execute this script to perform a component-specific smoke test.

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

SCRIPT_NAME="${SCRIPT_DIR}/env.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

wincheck --version

_WCR_TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/win-cmd-rs-smoke.XXXXXX")
trap 'rm -rf "${_WCR_TEST_DIR}"' EXIT INT TERM

printf '@echo off\r\nsetlocal EnableDelayedExpansion\r\necho(ok\r\nexit /b 0\r\n' > "${_WCR_TEST_DIR}/clean.cmd"
wincheck --severity error "${_WCR_TEST_DIR}/clean.cmd"
printf '%s\n' '[PASS] wincheck accepted valid .cmd script'

printf '@echo off\r\nif 1==1 (\r\n    :: illegal block comment\r\n    echo bad\r\n)\r\n' > "${_WCR_TEST_DIR}/broken.cmd"
if wincheck --severity error "${_WCR_TEST_DIR}/broken.cmd" >/dev/null 2>&1; then
  printf '%s\n' '[FAIL] wincheck failed to flag CMD1001 broken .cmd script' >&2
  exit 1
fi
printf '%s\n' '[PASS] wincheck detected CMD1001 defect in broken .cmd script'

if command -v wincmd >/dev/null 2>&1; then
  wincmd --version
  _wcmd_out=$(wincmd /V:ON /C '@SET /A "X=6*7" >NUL & @ECHO !X!' 2>/dev/null | tr -d '\r\n' || true)
  if [ "${_wcmd_out}" != '42' ]; then
    printf '[FAIL] Expected wincmd arithmetic output 42, got "%s"\n' "${_wcmd_out}" >&2
    exit 1
  fi
  printf '%s\n' '[PASS] wincmd arithmetic evaluation (6*7=42) verified'
fi
