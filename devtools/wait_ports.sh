#!/bin/sh
# ## Overview
# POSIX wrapper for wait_ports Open edX lifecycle orchestration helper.
#
# ## Usage
# ./devtools/wait_ports.sh [args...]

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

TARGET='openedx'
if [ "${1:-}" = "--target" ] && [ -n "${2:-}" ]; then
  TARGET="$2"
  shift 2
fi

case "${1:-}" in
  [0-9]*)
    _port="$1"
    _timeout="${2:-30}"
    _elapsed=0
    while [ "$_elapsed" -lt "$_timeout" ]; do
      if command -v nc >/dev/null 2>&1 && nc -z 127.0.0.1 "$_port" >/dev/null 2>&1; then
        exit 0
      elif command -v curl >/dev/null 2>&1 && curl -s --connect-timeout 1 "http://127.0.0.1:${_port}" >/dev/null 2>&1; then
        exit 0
      fi
      sleep 1
      _elapsed=$((_elapsed + 1))
    done
    ;;
esac

if [ -x "${LIBSCRIPT_ROOT_DIR}/_lib/web-apps/${TARGET}/healthcheck.sh" ]; then
  "${LIBSCRIPT_ROOT_DIR}/_lib/web-apps/${TARGET}/healthcheck.sh" "$@"
else
  "${LIBSCRIPT_ROOT_DIR}/_lib/web-apps/openedx/healthcheck.sh" "$@"
fi

