#!/bin/sh
# ## Overview
# Smoke test suite for the lynx component.
# Verifies lynx version reporting and stdin HTML-to-plaintext conversion.
#
# ## Usage
# ./_lib/utilities/lynx/test.sh

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
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"

if [ -f "${SCRIPT_DIR}/env.sh" ]; then
  _test_saved_this="${THIS_FILE}"
  _test_saved_dir="${SCRIPT_DIR}"
  SCRIPT_NAME="${SCRIPT_DIR}/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
  THIS_FILE="${_test_saved_this}"
  SCRIPT_DIR="${_test_saved_dir}"
fi

lynx -version >/dev/null 2>&1
_out=$(printf '<p>Hello Open edX</p>
' | lynx -assume_charset=UTF-8 -display_charset=UTF-8 -nomargins -stdin -dump -nolist)
case "${_out}" in
  *"Hello Open edX"*)
    printf '[PASS] lynx HTML-to-text conversion verified.
'
    exit 0
    ;;
  *)
    printf '[FAIL] Unexpected lynx output: %s
' "${_out}" >&2
    exit 1
    ;;
esac
