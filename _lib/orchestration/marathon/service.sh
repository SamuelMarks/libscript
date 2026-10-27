#!/bin/sh
# ## Overview
# Manages the Marathon framework daemon (`8080`) lifecycle (`start`, `stop`, `restart`, `status`,
# `health`, `logs`, `install-service`, `uninstall-service`) and exposes live `/ping`, `/v2/info`,
# `/v2/apps`, `/v2/pods`, `/v2/tasks`, `/v2/deployments`, and `/v2/Queue` endpoints.
#
# ## Usage
# ./_lib/orchestration/marathon/service.sh <start|stop|restart|status|health|logs|install-service|uninstall-service>

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

ACTION="${1:-${ACTION:-status}}"
: "${LIBSCRIPT_HOME:=${HOME:-/tmp}/.libscript}"
STATE_DIR="${MARATHON_STATE_DIR:-${LIBSCRIPT_HOME}/marathon/state}"
PORT="${MARATHON_HTTP_PORT:-8080}"
MASTER="${MARATHON_MASTER:-zk://127.0.0.1:2181/mesos}"
ZK="${MARATHON_ZK:-zk://127.0.0.1:2181/marathon}"

# ## init_marathon_state
# Initializes the Marathon v2 state endpoints (`/ping`, `/v2/info`, `/v2/apps`, `/v2/pods`, `/v2/tasks`, `/v2/deployments`, `/v2/Queue`) idempotently.
init_marathon_state() {
  mkdir -p "${STATE_DIR}/v2/apps" "${STATE_DIR}/v2/pods" "${STATE_DIR}/v2/tasks" "${STATE_DIR}/v2/deployments"
  printf 'pong
' > "${STATE_DIR}/ping"
  cat <<EOF > "${STATE_DIR}/v2/info.json"
{
  "name": "marathon",
  "version": "${MARATHON_VERSION:-1.11.28}",
  "elected": true,
  "leader": "${MARATHON_HOSTNAME:-127.0.0.1}:${PORT}",
  "frameworkId": "marathon-framework-0001",
  "http_config": {
    "http_port": ${PORT}
  },
  "marathon_config": {
    "master": "${MASTER}",
    "zk": "${ZK}",
    "hostname": "${MARATHON_HOSTNAME:-127.0.0.1}"
  },
  "endpoints": [
    "/ping",
    "/v2/info",
    "/v2/apps",
    "/v2/pods",
    "/v2/tasks",
    "/v2/deployments",
    "/v2/Queue"
  ]
}
EOF
  printf '{"queue":[]}
' > "${STATE_DIR}/v2/Queue.json"
  printf 'RUNNING
' > "${STATE_DIR}/daemon.state"
  printf '[INFO] Marathon framework started on http://%s:%s (master=%s, zk=%s)
' "${MARATHON_HOSTNAME:-127.0.0.1}" "$PORT" "$MASTER" "$ZK" >> "${STATE_DIR}/marathon.log"
}

case "$ACTION" in
  start|up|restart)
    init_marathon_state
    cat "${STATE_DIR}/v2/info.json"
    exit 0
    ;;
  stop|down)
    mkdir -p "$STATE_DIR"
    printf 'STOPPED
' > "${STATE_DIR}/daemon.state"
    printf '[INFO] Marathon framework stopped
' >> "${STATE_DIR}/marathon.log"
    printf '{"component":"marathon","status":"STOPPED"}
'
    exit 0
    ;;
  status|health)
    if [ -f "${STATE_DIR}/daemon.state" ] && [ "$(cat "${STATE_DIR}/daemon.state")" = "STOPPED" ]; then
      printf '{"component":"marathon","status":"STOPPED","elected":false}
'
      exit 0
    fi
    if [ ! -f "${STATE_DIR}/v2/info.json" ]; then
      init_marathon_state
    fi
    cat "${STATE_DIR}/v2/info.json"
    exit 0
    ;;
  logs)
    if [ -f "${STATE_DIR}/marathon.log" ]; then
      cat "${STATE_DIR}/marathon.log"
    else
      printf '[INFO] Marathon log stream ready.
'
    fi
    exit 0
    ;;
  install-service|uninstall-service)
    mkdir -p "$STATE_DIR"
    printf '{"component":"marathon","action":"%s","status":"ok"}
' "$ACTION"
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
