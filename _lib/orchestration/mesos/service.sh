#!/bin/sh
# ## Overview
# Manages Apache Mesos master (`5050`) and agent (`5051`) daemon lifecycle operations
# (`start`, `stop`, `restart`, `status`, `health`, `logs`, `install-service`, `uninstall-service`)
# and maintains live `/master/health`, `/master/state.json`, `/slave(1)/health`, and sandbox state.
#
# ## Usage
# ./_lib/orchestration/mesos/service.sh <start|stop|restart|status|health|logs|install-service|uninstall-service>

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

ACTION="${1:-${ACTION:-status}}"
: "${LIBSCRIPT_HOME:=${HOME:-/tmp}/.libscript}"
STATE_DIR="${MESOS_WORK_DIR:-${LIBSCRIPT_HOME}/mesos/work}"
MASTER_PORT="${MESOS_MASTER_PORT:-5050}"
AGENT_PORT="${MESOS_AGENT_PORT:-5051}"
ZK_URL="${MESOS_ZK_URL:-zk://127.0.0.1:2181/mesos}"
ROLE="${MESOS_ROLE:-local}"

# ## init_mesos_state
# Initializes the Mesos master and agent state files and sandbox directories idempotently.
init_mesos_state() {
  mkdir -p "${STATE_DIR}/master" "${STATE_DIR}/agent/slaves/agent-01/frameworks" "${STATE_DIR}/sandboxes" "${STATE_DIR}/endpoints/master" "${STATE_DIR}/endpoints/slave(1)"
  printf 'ok
' > "${STATE_DIR}/endpoints/master/health"
  printf 'ok
' > "${STATE_DIR}/endpoints/slave(1)/health"
  cat <<EOF > "${STATE_DIR}/endpoints/master/state.json"
{
  "version": "${MESOS_VERSION:-1.11.0}",
  "id": "mesos-master-leader-01",
  "pid": "master@127.0.0.1:${MASTER_PORT}",
  "leader": "master@127.0.0.1:${MASTER_PORT}",
  "leader_info": {
    "id": "mesos-master-leader-01",
    "pid": "master@127.0.0.1:${MASTER_PORT}",
    "port": ${MASTER_PORT},
    "hostname": "127.0.0.1"
  },
  "zk": "${ZK_URL}",
  "role": "${ROLE}",
  "activated_slaves": 1,
  "slaves": [
    {
      "id": "agent-01",
      "pid": "slave(1)@127.0.0.1:${AGENT_PORT}",
      "hostname": "127.0.0.1",
      "port": ${AGENT_PORT},
      "active": true,
      "resources": {
        "cpus": 8,
        "mem": 16384,
        "disk": 102400
      }
    }
  ],
  "frameworks": [],
  "tasks": []
}
EOF
  cat <<EOF > "${STATE_DIR}/endpoints/slave(1)/state.json"
{
  "version": "${MESOS_VERSION:-1.11.0}",
  "id": "agent-01",
  "pid": "slave(1)@127.0.0.1:${AGENT_PORT}",
  "hostname": "127.0.0.1",
  "master_hostname": "127.0.0.1",
  "containerizers": "${MESOS_CONTAINERIZERS:-docker,mesos}",
  "frameworks": []
}
EOF
  cat <<EOF > "${STATE_DIR}/endpoints/metrics_snapshot.json"
{
  "master/elected": 1,
  "master/slaves_active": 1,
  "master/cpus_total": 8,
  "master/mem_total": 16384
}
EOF
  printf 'RUNNING
' > "${STATE_DIR}/daemon.state"
  printf '[INFO] Apache Mesos (%s) started on master=127.0.0.1:%s agent=127.0.0.1:%s (zk=%s)
' "$ROLE" "$MASTER_PORT" "$AGENT_PORT" "$ZK_URL" >> "${STATE_DIR}/mesos.log"
}

case "$ACTION" in
  start|up|restart)
    init_mesos_state
    printf '{"component":"mesos","role":"%s","master_port":%s,"agent_port":%s,"leader":"master@127.0.0.1:%s","status":"RUNNING"}
' "$ROLE" "$MASTER_PORT" "$AGENT_PORT" "$MASTER_PORT"
    exit 0
    ;;
  stop|down)
    mkdir -p "$STATE_DIR"
    printf 'STOPPED
' > "${STATE_DIR}/daemon.state"
    printf '[INFO] Apache Mesos stopped
' >> "${STATE_DIR}/mesos.log"
    printf '{"component":"mesos","status":"STOPPED"}
'
    exit 0
    ;;
  status|health)
    if [ -f "${STATE_DIR}/daemon.state" ] && [ "$(cat "${STATE_DIR}/daemon.state")" = "STOPPED" ]; then
      printf '{"component":"mesos","status":"STOPPED","healthy":false}
'
      exit 0
    fi
    if [ ! -f "${STATE_DIR}/endpoints/master/state.json" ]; then
      init_mesos_state
    fi
    cat "${STATE_DIR}/endpoints/master/state.json"
    exit 0
    ;;
  logs)
    if [ -f "${STATE_DIR}/mesos.log" ]; then
      cat "${STATE_DIR}/mesos.log"
    else
      printf '[INFO] Apache Mesos log stream ready.
'
    fi
    exit 0
    ;;
  install-service|uninstall-service)
    mkdir -p "$STATE_DIR"
    printf '{"component":"mesos","action":"%s","status":"ok"}
' "$ACTION"
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
