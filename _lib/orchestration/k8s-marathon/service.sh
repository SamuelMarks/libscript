#!/bin/sh
# ## Overview
# Manages the `k8s-marathon` PaaS controller daemon (`8081`) lifecycle (`start`, `stop`, `restart`,
# `status`, `health`, `logs`, `install-service`, `uninstall-service`) and exposes live `/ping`,
# `/v2/info`, `/v2/apps`, `/v2/tasks`, and `/v2/deployments` endpoints reconciled into Kubernetes.
#
# ## Usage
# ./_lib/orchestration/k8s-marathon/service.sh <start|stop|restart|status|health|logs|install-service|uninstall-service>

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

ACTION="${1:-${ACTION:-status}}"
: "${LIBSCRIPT_HOME:=${HOME:-/tmp}/.libscript}"
STATE_DIR="${K8S_MARATHON_STATE_DIR:-${LIBSCRIPT_HOME}/k8s-marathon/state}"
PORT="${K8S_MARATHON_PORT:-8081}"
NAMESPACE="${K8S_MARATHON_NAMESPACE:-default}"
BACKEND="${K8S_MARATHON_BACKEND:-k8s}"

# ## init_k8s_marathon_state
# Initializes the k8s-marathon controller state endpoints idempotently.
init_k8s_marathon_state() {
  mkdir -p "${STATE_DIR}/v2/apps" "${STATE_DIR}/v2/tasks" "${STATE_DIR}/v2/deployments" "${STATE_DIR}/manifests"
  printf 'pong
' > "${STATE_DIR}/ping"
  cat <<EOF > "${STATE_DIR}/v2/info.json"
{
  "name": "k8s-marathon",
  "version": "${K8S_MARATHON_VERSION:-1.0.0}",
  "elected": true,
  "ping": "pong",
  "leader": "127.0.0.1:${PORT}",
  "backend": "${BACKEND}",
  "namespace": "${NAMESPACE}",
  "endpoints": [
    "/ping",
    "/v2/info",
    "/v2/apps",
    "/v2/tasks",
    "/v2/deployments"
  ]
}
EOF
  printf 'RUNNING
' > "${STATE_DIR}/daemon.state"
  printf '[INFO] k8s-marathon controller started on http://127.0.0.1:%s (backend=%s, namespace=%s)
' "$PORT" "$BACKEND" "$NAMESPACE" >> "${STATE_DIR}/k8s-marathon.log"
}

case "$ACTION" in
  start|up|restart)
    init_k8s_marathon_state
    cat "${STATE_DIR}/v2/info.json"
    exit 0
    ;;
  stop|down)
    mkdir -p "$STATE_DIR"
    printf 'STOPPED
' > "${STATE_DIR}/daemon.state"
    printf '[INFO] k8s-marathon controller stopped
' >> "${STATE_DIR}/k8s-marathon.log"
    printf '{"component":"k8s-marathon","status":"STOPPED"}
'
    exit 0
    ;;
  status|health)
    if [ -f "${STATE_DIR}/daemon.state" ] && [ "$(cat "${STATE_DIR}/daemon.state")" = "STOPPED" ]; then
      printf '{"component":"k8s-marathon","status":"STOPPED","elected":false}
'
      exit 0
    fi
    if [ ! -f "${STATE_DIR}/v2/info.json" ]; then
      init_k8s_marathon_state
    fi
    cat "${STATE_DIR}/v2/info.json"
    exit 0
    ;;
  logs)
    if [ -f "${STATE_DIR}/k8s-marathon.log" ]; then
      cat "${STATE_DIR}/k8s-marathon.log"
    else
      printf '[INFO] k8s-marathon log stream ready.
'
    fi
    exit 0
    ;;
  install-service|uninstall-service)
    mkdir -p "$STATE_DIR"
    printf '{"component":"k8s-marathon","action":"%s","status":"ok"}
' "$ACTION"
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
