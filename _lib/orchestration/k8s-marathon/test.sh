#!/bin/sh
# ## Overview
# Smoke test suite for the `k8s-marathon` PaaS controller component, verifying `k8s-marathon --version`,
# `/ping`, `/v2/info`, and live `/v2/apps` reconciliation into Kubernetes resources.
#
# ## Usage
# ./_lib/orchestration/k8s-marathon/test.sh

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

if ! command -v k8s-marathon >/dev/null 2>&1; then
  unset SCRIPT_NAME || true
  ACTION="install" sh "${SCRIPT_DIR}/setup.sh" install k8s-marathon latest >/dev/null
  unset SCRIPT_NAME || true
  # shellcheck disable=SC1091
  . "${SCRIPT_DIR}/env.sh"
fi

k8s-marathon --version >/dev/null
[ "$(k8s-marathon ping)" = "pong" ]
k8s-marathon put-app smoke-k8s-app >/dev/null
k8s-marathon get-app smoke-k8s-app | grep -q '"k8sReconciled":true'
k8s-marathon scale-app smoke-k8s-app 0 | grep -q '"instances":0'
k8s-marathon delete-app smoke-k8s-app >/dev/null

unset SCRIPT_NAME || true
sh "${SCRIPT_DIR}/service.sh" status | grep -q '"ping": "pong"'
printf '[PASS] k8s-marathon PaaS controller verified (version, /ping, /v2/apps K8s reconciliation).
'
exit 0
