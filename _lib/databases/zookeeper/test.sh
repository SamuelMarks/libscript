#!/bin/sh
# ## Overview
# Smoke test suite for the Apache ZooKeeper component (`zookeeper`), verifying `ruok` -> `imok`
# four-letter health check and Mesos + Marathon leader election znodes (`/mesos` and `/marathon`).
#
# ## Usage
# ./_lib/databases/zookeeper/test.sh

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

if [ -f "${SCRIPT_DIR}/env.sh" ]; then
  unset SCRIPT_NAME || true
  # shellcheck disable=SC1091
  _ls_src_this="${THIS_FILE:-}"; _ls_src_dir="${SCRIPT_DIR:-}"
  SCRIPT_NAME="${SCRIPT_DIR}/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true
  [ -n "${_ls_src_this:-}" ] && THIS_FILE="$_ls_src_this"
  [ -n "${_ls_src_dir:-}" ] && SCRIPT_DIR="$_ls_src_dir"
fi

if ! command -v zookeeper >/dev/null 2>&1; then
  unset SCRIPT_NAME || true
  ACTION="install" sh "${SCRIPT_DIR}/setup.sh" install zookeeper latest >/dev/null
  unset SCRIPT_NAME || true
  # shellcheck disable=SC1091
  _ls_src_this="${THIS_FILE:-}"; _ls_src_dir="${SCRIPT_DIR:-}"
  SCRIPT_NAME="${SCRIPT_DIR}/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true
  [ -n "${_ls_src_this:-}" ] && THIS_FILE="$_ls_src_this"
  [ -n "${_ls_src_dir:-}" ] && SCRIPT_DIR="$_ls_src_dir"
fi

zookeeper --version >/dev/null
[ "$(zookeeper ruok)" = "imok" ]

unset SCRIPT_NAME || true
STATUS_OUT=$(sh "${SCRIPT_DIR}/service.sh" status)
printf '%s
' "$STATUS_OUT" | grep -q '"ruok": "imok"'
printf '%s
' "$STATUS_OUT" | grep -q '"/mesos"'
printf '%s
' "$STATUS_OUT" | grep -q '"/marathon"'
printf '[PASS] Apache ZooKeeper component verified (ruok=imok, /mesos and /marathon znodes).
'
exit 0
