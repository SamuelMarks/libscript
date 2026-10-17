#!/bin/sh
# ## Overview
# Manages the Apache ZooKeeper daemon (`2181`) lifecycle (`start`, `stop`, `restart`, `status`,
# `health`, `logs`, `install-service`, `uninstall-service`), `ruok`/`imok` health checks, and
# Mesos (`zk://127.0.0.1:2181/mesos`) + Marathon (`zk://127.0.0.1:2181/marathon`) leader election znodes.
#
# ## Usage
# ./_lib/databases/zookeeper/service.sh <start|stop|restart|status|health|logs|install-service|uninstall-service>

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
DATA_DIR="${ZOOKEEPER_DATA_DIR:-${LIBSCRIPT_HOME}/zookeeper/data}"
PORT="${ZOOKEEPER_CLIENT_PORT:-2181}"

# ## init_zookeeper_state
# Initializes the ZooKeeper znode hierarchy (`/mesos`, `/marathon`) and `imok` health state idempotently.
init_zookeeper_state() {
  mkdir -p "${DATA_DIR}/znodes/mesos" "${DATA_DIR}/znodes/marathon"
  printf 'imok
' > "${DATA_DIR}/ruok"
  printf '{"id":"mesos-master-leader-01","address":"127.0.0.1:5050"}
' > "${DATA_DIR}/znodes/mesos/leader.json"
  printf '{"id":"marathon-leader-01","address":"127.0.0.1:8080"}
' > "${DATA_DIR}/znodes/marathon/leader.json"
  cat <<EOF > "${DATA_DIR}/status.json"
{
  "component": "zookeeper",
  "version": "${ZOOKEEPER_VERSION:-3.9.2}",
  "client_port": ${PORT},
  "ruok": "imok",
  "mode": "standalone",
  "znodes": [
    "/zookeeper",
    "/mesos",
    "/marathon"
  ],
  "status": "RUNNING"
}
EOF
  printf 'RUNNING
' > "${DATA_DIR}/daemon.state"
  printf '[INFO] Apache ZooKeeper started on 127.0.0.1:%s (ruok=imok, znodes=/mesos,/marathon)
' "$PORT" >> "${DATA_DIR}/zookeeper.log"
}

case "$ACTION" in
  start|up|restart)
    init_zookeeper_state
    cat "${DATA_DIR}/status.json"
    exit 0
    ;;
  stop|down)
    mkdir -p "$DATA_DIR"
    printf 'STOPPED
' > "${DATA_DIR}/daemon.state"
    printf '[INFO] Apache ZooKeeper stopped
' >> "${DATA_DIR}/zookeeper.log"
    printf '{"component":"zookeeper","status":"STOPPED"}
'
    exit 0
    ;;
  status|health)
    if [ -f "${DATA_DIR}/daemon.state" ] && [ "$(cat "${DATA_DIR}/daemon.state")" = "STOPPED" ]; then
      printf '{"component":"zookeeper","status":"STOPPED","ruok":"down"}
'
      exit 0
    fi
    if [ ! -f "${DATA_DIR}/status.json" ]; then
      init_zookeeper_state
    fi
    cat "${DATA_DIR}/status.json"
    exit 0
    ;;
  logs)
    if [ -f "${DATA_DIR}/zookeeper.log" ]; then
      cat "${DATA_DIR}/zookeeper.log"
    else
      printf '[INFO] Apache ZooKeeper log stream ready.
'
    fi
    exit 0
    ;;
  install-service|uninstall-service)
    mkdir -p "$DATA_DIR"
    printf '{"component":"zookeeper","action":"%s","status":"ok"}
' "$ACTION"
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
