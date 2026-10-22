#!/bin/sh
# ## Overview
# POSIX wrapper for wait_install Open edX lifecycle orchestration helper.
#
# ## Usage
# ./devtools/wait_install.sh [args...]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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

TARGET_COMPONENT="${1:-openedx}"
_tries=0
while pgrep -f "libscript.sh install ${TARGET_COMPONENT}" >/dev/null 2>&1 && [ "$_tries" -lt 120 ]; do
  sleep 5
  _tries=$((_tries + 1))
done

"${LIBSCRIPT_ROOT_DIR}/libscript.sh" status "${TARGET_COMPONENT}" >/dev/null 2>&1 || true
exit 0

