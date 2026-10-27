#!/bin/sh
# ## Overview
# Smoke test suite for the Apache Mesos component (`mesos`, `mesos-master`, `mesos-agent`),
# verifying binary execution, leader election state, and agent registration.
#
# ## Usage
# ./_lib/orchestration/mesos/test.sh

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

if ! command -v mesos-master >/dev/null 2>&1; then
  unset SCRIPT_NAME || true
  ACTION="install" sh "${SCRIPT_DIR}/setup.sh" install mesos latest >/dev/null
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

mesos --version >/dev/null
mesos-master --version >/dev/null
mesos-agent --version >/dev/null

unset SCRIPT_NAME || true
STATUS_OUT=$(sh "${SCRIPT_DIR}/service.sh" status)
printf '%s
' "$STATUS_OUT" | grep -q '"leader"'
printf '%s
' "$STATUS_OUT" | grep -q '"activated_slaves": 1'
printf '[PASS] Apache Mesos component verified (mesos-master, mesos-agent, leader election, agent registration).
'
exit 0
