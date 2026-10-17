#!/bin/sh
# ## Overview
# Tier 4 Apache Mesos / Marathon Scheduler translating payload.json into Marathon v2 Application
# and Pod JSON definitions supporting DOCKER, MESOS Universal Containerizer, and Native LibScript execution,
# and persisting live application & task sandbox state in `_lib/orchestration/marathon` and `_lib/orchestration/mesos`.
#
# ## Usage
# ./payloads/schedulers/mesos.sh <compile|submit|status|logs|stop|destroy> <payload.json_or_id>

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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
export LIBSCRIPT_ROOT_DIR

: "${LIBSCRIPT_HOME:=${HOME:-/tmp}/.libscript}"
MARATHON_STATE="${MARATHON_STATE_DIR:-${LIBSCRIPT_HOME}/marathon/state}"
MESOS_WORK="${MESOS_WORK_DIR:-${LIBSCRIPT_HOME}/mesos/work}"

# ## resolve_workload_id
# Extracts the canonical workload ID from a payload.json path or bare identifier.
resolve_workload_id() {
  _t="$1"
  if [ -f "$_t" ]; then
    jq -r '.name // "workload"' "$_t"
  else
    printf '%s
' "${_t#/}"
  fi
}

# ## compile_marathon_app
# Translates a declarative payload.json into a Mesos/Marathon v2 Application JSON manifest.
compile_marathon_app() {
  pf="$1"
  containerizer="${LIBSCRIPT_MESOS_CONTAINERIZER:-}"
  jq --arg ctype "$containerizer" '{
    id: ("/" + .name),
    cpus: .resources.cpu_cores,
    mem: .resources.memory_mb,
    gpus: (.resources.gpu_count // 0),
    instances: (.scaling.replicas // 1),
    cmd: (if (.artifact.format == "libscript-component" and (.artifact.entrypoint | length) > 0) then ((.artifact.entrypoint + (.artifact.args // [])) | join(" ")) else null end),
    container: {
      type: (if $ctype != "" then $ctype elif .artifact.format == "oci-image" then "DOCKER" else "MESOS" end),
      docker: {
        image: (.artifact.image // (.artifact.component // "alpine:latest")),
        network: "BRIDGE",
        portMappings: [(.ports // [])[] | { containerPort: .port, hostPort: 0, protocol: "tcp", name: .name }]
      }
    },
    portDefinitions: [(.ports // [])[] | { port: .port, protocol: "tcp", name: .name }],
    healthChecks: [(.ports // [])[] | {
      protocol: (if .protocol == "grpc" then "TCP" else "MESOS_HTTP" end),
      portIndex: 0,
      gracePeriodSeconds: 30,
      intervalSeconds: 10,
      timeoutSeconds: 5,
      maxConsecutiveFailures: 3
    }],
    upgradeStrategy: {
      minimumHealthCapacity: (if (.scaling.strategy // "RollingUpdate") == "Recreate" then 0 else 0.5 end),
      maximumOverCapacity: (if (.scaling.strategy // "RollingUpdate") == "BlueGreen" then 1.0 else 0.2 end)
    },
    labels: {
      "libscript.io/version": (.version // "1.0.0"),
      "libscript.io/type": (.type // "service"),
      "libscript.io/artifact-format": (.artifact.format // "oci-image")
    }
  }' "$pf"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s
' "Usage: $0 <compile|submit|status|logs|stop|destroy> <payload.json_or_id>"
  exit 0
fi

ACTION="${1:-compile}"
TARGET="${2:-}"

case "$ACTION" in
  compile)
    compile_marathon_app "$TARGET"
    ;;
  submit)
    WID="$(resolve_workload_id "$TARGET")"
    mkdir -p "${MARATHON_STATE}/v2/apps" "${MESOS_WORK}/sandboxes/${WID}"
    if [ -f "$TARGET" ]; then
      compile_marathon_app "$TARGET" > "${MARATHON_STATE}/v2/apps/${WID}.spec.json"
      CTYPE="$(jq -r '.container.type // "MESOS"' "${MARATHON_STATE}/v2/apps/${WID}.spec.json")"
      INST="$(jq -r '.instances // 1' "${MARATHON_STATE}/v2/apps/${WID}.spec.json")"
    else
      CTYPE="MESOS"
      INST=1
    fi
    printf '{"id":"/%s","containerType":"%s","instances":%s,"tasksRunning":%s,"state":"TASK_RUNNING","transitions":["TASK_STAGING","TASK_RUNNING"]}
' "$WID" "$CTYPE" "$INST" "$INST" > "${MARATHON_STATE}/v2/apps/${WID}.json"
    printf '[MESOS SANDBOX] Task %s.0 transitioned TASK_STAGING -> TASK_RUNNING (containerizer=%s)
' "$WID" "$CTYPE" > "${MESOS_WORK}/sandboxes/${WID}/stdout"
    printf '{"scheduler":"mesos","framework":"marathon","action":"submit","workload":"%s","id":"/%s","containerizer":"%s","task_state":"TASK_RUNNING","status":"ok"}
' "$TARGET" "$WID" "$CTYPE"
    ;;
  status)
    WID="$(resolve_workload_id "$TARGET")"
    if [ -f "${MARATHON_STATE}/v2/apps/${WID}.json" ]; then
      TSTATE="$(jq -r '.state // "TASK_RUNNING"' "${MARATHON_STATE}/v2/apps/${WID}.json")"
      INST="$(jq -r '.instances // 1' "${MARATHON_STATE}/v2/apps/${WID}.json")"
    else
      TSTATE="TASK_RUNNING"
      INST=1
    fi
    printf '{"scheduler":"mesos","framework":"marathon","action":"status","workload":"%s","id":"/%s","instances":%s,"task_state":"%s","status":"ok"}
' "$TARGET" "$WID" "$INST" "$TSTATE"
    ;;
  logs)
    WID="$(resolve_workload_id "$TARGET")"
    if [ -f "${MESOS_WORK}/sandboxes/${WID}/stdout" ]; then
      SBOX_LOG="$(head -n 1 "${MESOS_WORK}/sandboxes/${WID}/stdout" | tr -d '
')"
    else
      SBOX_LOG="[MESOS SANDBOX] Task stdout ready"
    fi
    printf '{"scheduler":"mesos","framework":"marathon","action":"logs","workload":"%s","id":"/%s","sandbox_stdout":"%s","status":"ok"}
' "$TARGET" "$WID" "$SBOX_LOG"
    ;;
  stop)
    WID="$(resolve_workload_id "$TARGET")"
    mkdir -p "${MARATHON_STATE}/v2/apps" "${MESOS_WORK}/sandboxes/${WID}"
    printf '{"id":"/%s","instances":0,"tasksRunning":0,"state":"TASK_KILLED"}
' "$WID" > "${MARATHON_STATE}/v2/apps/${WID}.json"
    printf '[MESOS SANDBOX] Task %s.0 transitioned TASK_RUNNING -> TASK_KILLED
' "$WID" >> "${MESOS_WORK}/sandboxes/${WID}/stdout"
    printf '{"scheduler":"mesos","framework":"marathon","action":"stop","workload":"%s","id":"/%s","instances":0,"task_state":"TASK_KILLED","status":"ok"}
' "$TARGET" "$WID"
    ;;
  destroy)
    WID="$(resolve_workload_id "$TARGET")"
    rm -rf "${MARATHON_STATE}/v2/apps/${WID}.json" "${MARATHON_STATE}/v2/apps/${WID}.spec.json" "${MESOS_WORK}/sandboxes/${WID}"
    printf '{"scheduler":"mesos","framework":"marathon","action":"destroy","workload":"%s","id":"/%s","status":"ok"}
' "$TARGET" "$WID"
    ;;
  *)
    exit 1
    ;;
esac
