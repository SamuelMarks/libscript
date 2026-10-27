#!/bin/sh
# ## Overview
# End-to-end live integration test for Apache ZooKeeper (`_lib/databases/zookeeper`) +
# Apache Mesos (`_lib/orchestration/mesos`) + Marathon (`_lib/orchestration/marathon`) +
# `topologies/mesos-marathon-ha` + `payloads/schedulers/mesos.sh`.
# Verifies live daemon provisioning, `ruok`=`imok`, Mesos leader election, Marathon `/v2/apps`
# deployment across `DOCKER`, `MESOS`, and native `libscript-component` containerizers, task
# state transitions (`TASK_STAGING` -> `TASK_RUNNING` -> `TASK_KILLED`), sandbox stdout logs,
# and all 9 workload payloads with 2x idempotency.
#
# ## Usage
# ./tests/test_mesos_marathon_e2e.sh

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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
export LIBSCRIPT_ROOT_DIR

E2E_TMP="$(mktemp -d "${TMPDIR:-/tmp}/libscript-mesos-marathon-e2e.XXXXXX")"
# ## cleanup_mesos_marathon_e2e
# Cleans up temporary test directory on exit.
cleanup_mesos_marathon_e2e() {
  rm -rf "$E2E_TMP"
}
trap cleanup_mesos_marathon_e2e EXIT INT TERM

export LIBSCRIPT_HOME="${E2E_TMP}/home"
export ZOOKEEPER_DATA_DIR="${E2E_TMP}/zk-data"
export MESOS_WORK_DIR="${E2E_TMP}/mesos-work"
export MARATHON_STATE_DIR="${E2E_TMP}/marathon-state"
export LIBSCRIPT_TOPOLOGY_STATE_FILE="${E2E_TMP}/mesos-ha.state.json"

# 1. Provision and start ZooKeeper + Mesos + Marathon (2x idempotent)
for COMP in "databases/zookeeper" "orchestration/mesos" "orchestration/marathon"; do
  unset SCRIPT_NAME || true
  sh "${LIBSCRIPT_ROOT_DIR}/_lib/${COMP}/cli.sh" install latest >/dev/null
  unset SCRIPT_NAME || true
  sh "${LIBSCRIPT_ROOT_DIR}/_lib/${COMP}/cli.sh" install latest >/dev/null
  unset SCRIPT_NAME || true
  sh "${LIBSCRIPT_ROOT_DIR}/_lib/${COMP}/cli.sh" start >/dev/null
  unset SCRIPT_NAME || true
  sh "${LIBSCRIPT_ROOT_DIR}/_lib/${COMP}/cli.sh" start >/dev/null
done

unset SCRIPT_NAME || true
sh "${LIBSCRIPT_ROOT_DIR}/_lib/databases/zookeeper/cli.sh" status | jq -e '.ruok == "imok"' >/dev/null
unset SCRIPT_NAME || true
sh "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/mesos/cli.sh" status | jq -e '.activated_slaves == 1' >/dev/null
unset SCRIPT_NAME || true
sh "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/marathon/cli.sh" status | jq -e '.elected == true' >/dev/null

# 2. Bring up topologies/mesos-marathon-ha (2x idempotent)
unset SCRIPT_NAME || true
sh "${LIBSCRIPT_ROOT_DIR}/topologies/mesos-marathon-ha/cli.sh" up >/dev/null
unset SCRIPT_NAME || true
sh "${LIBSCRIPT_ROOT_DIR}/topologies/mesos-marathon-ha/cli.sh" up >/dev/null
jq -e '.status == "HEALTHY"' "$LIBSCRIPT_TOPOLOGY_STATE_FILE" >/dev/null

# 3. Verify DOCKER, MESOS Universal Containerizer, and Native LibScript containerizers
for CTYPE in DOCKER MESOS; do
  LIBSCRIPT_MESOS_CONTAINERIZER="$CTYPE" sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/mesos.sh" compile "${LIBSCRIPT_ROOT_DIR}/payloads/ai/vllm/payload.json" | jq -e --arg c "$CTYPE" '.container.type == $c' >/dev/null
done

cat <<'EOF' > "${E2E_TMP}/multitenant-webapp.json"
{
  "name": "wordpress-multitenant",
  "version": "6.6.0",
  "type": "service",
  "artifact": {
    "format": "libscript-component",
    "component": "wordpress",
    "entrypoint": ["./libscript.sh", "start", "wordpress"],
    "args": ["--db=postgres", "--cache=valkey"]
  },
  "resources": { "cpu_cores": 2, "memory_mb": 2048, "disk_gb": 20 },
  "scaling": { "replicas": 2, "strategy": "RollingUpdate", "restart_policy": "Always" },
  "ports": [{ "name": "http", "port": 8080, "protocol": "http" }]
}
EOF

sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/mesos.sh" compile "${E2E_TMP}/multitenant-webapp.json" | jq -e '.cmd == "./libscript.sh start wordpress --db=postgres --cache=valkey"' >/dev/null

# 4. Retest all 9 workloads across all 6 canonical verbs (`compile`, `submit`, `status`, `logs`, `stop`, `destroy`) with 2x idempotency
for PF in "${LIBSCRIPT_ROOT_DIR}/payloads/ai/vllm/payload.json" "${LIBSCRIPT_ROOT_DIR}/payloads/ai/ollama/payload.json" "${LIBSCRIPT_ROOT_DIR}/payloads/ai/jetstream/payload.json" "${LIBSCRIPT_ROOT_DIR}/payloads/ai/gke-xpk-training/payload.json" "${LIBSCRIPT_ROOT_DIR}/payloads/ai/gke-xpk-inference/payload.json" "${LIBSCRIPT_ROOT_DIR}/payloads/ai/gke-tpu-cluster/payload.json" "${LIBSCRIPT_ROOT_DIR}/payloads/ai/gcp-gpu-vm/payload.json" "${LIBSCRIPT_ROOT_DIR}/payloads/ai/gcp-tpu-vm/payload.json" "${E2E_TMP}/multitenant-webapp.json"; do
  WID="$(jq -r '.name' "$PF")"
  C1="$(sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/mesos.sh" compile "$PF")"
  C2="$(sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/mesos.sh" compile "$PF")"
  [ "$C1" = "$C2" ]

  sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/mesos.sh" submit "$PF" | jq -e '.task_state == "TASK_RUNNING"' >/dev/null
  sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/mesos.sh" submit "$PF" | jq -e '.task_state == "TASK_RUNNING"' >/dev/null
  [ -f "${MARATHON_STATE_DIR}/v2/apps/${WID}.json" ]
  [ -f "${MESOS_WORK_DIR}/sandboxes/${WID}/stdout" ]

  sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/mesos.sh" status "$WID" | jq -e '.task_state == "TASK_RUNNING"' >/dev/null
  sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/mesos.sh" logs "$WID" | jq -e '.sandbox_stdout | contains("TASK_RUNNING")' >/dev/null
  sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/mesos.sh" stop "$WID" | jq -e '.task_state == "TASK_KILLED" and .instances == 0' >/dev/null
  sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/mesos.sh" destroy "$WID" | jq -e '.status == "ok"' >/dev/null
  sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/mesos.sh" destroy "$WID" | jq -e '.status == "ok"' >/dev/null
  [ ! -f "${MARATHON_STATE_DIR}/v2/apps/${WID}.json" ]
done

printf '[PASS] Apache Mesos + Marathon + ZooKeeper live end-to-end suite verified.
'
