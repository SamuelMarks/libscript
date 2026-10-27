#!/bin/sh
# ## Overview
# Smoke test suite for the Marathon component (`marathon`), verifying `marathon --version`,
# `/ping`, `/v2/info`, and live `/v2/apps` CRUD lifecycle.
#
# ## Usage
# ./_lib/orchestration/marathon/test.sh

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
  . "${SCRIPT_DIR}/env.sh"
fi

if ! command -v marathon >/dev/null 2>&1; then
  unset SCRIPT_NAME || true
  ACTION="install" sh "${SCRIPT_DIR}/setup.sh" install marathon latest >/dev/null
  unset SCRIPT_NAME || true
  # shellcheck disable=SC1091
  . "${SCRIPT_DIR}/env.sh"
fi

marathon --version >/dev/null
[ "$(marathon ping)" = "pong" ]
marathon put-app smoke-test-app >/dev/null
marathon get-app smoke-test-app | grep -q "TASK_RUNNING"
marathon scale-app smoke-test-app 0 | grep -q '"instances":0'
marathon delete-app smoke-test-app >/dev/null

unset SCRIPT_NAME || true
sh "${SCRIPT_DIR}/service.sh" status | grep -q '"elected": true'
printf '[PASS] Marathon framework component verified (version, /ping, /v2/info, /v2/apps CRUD).
'
exit 0
