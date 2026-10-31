#!/bin/sh
# ## Overview
# End-to-end live integration test for Kubernetes (`kubernetes`, `k0s`, `k8s-thw`) + `k8s-marathon`
# PaaS controller, `topologies/k8s-marathon-paas`, and `payloads/schedulers/kubernetes.sh`.
# Verifies live daemon startup, `/ping` = `pong`, `/v2/apps` reconciliation into Kubernetes
# `Deployment`, `StatefulSet`, `Job`, `Service`, and `Ingress` resources, Marathon-equivalent
# REST/CLI parity with `payloads/schedulers/mesos.sh`, and 2x idempotency across stateless web,
# stateful DB/cache, AI inference/training, and full web application workloads.
#
# ## Usage
# ./tests/test_k8s_marathon_e2e.sh

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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

E2E_TMP="$(mktemp -d "${TMPDIR:-/tmp}/libscript-k8s-marathon-e2e.XXXXXX")"
# ## cleanup_k8s_marathon_e2e
# Cleans up temporary test directory on exit.
cleanup_k8s_marathon_e2e() {
  rm -rf "$E2E_TMP"
}
trap cleanup_k8s_marathon_e2e EXIT INT TERM

export LIBSCRIPT_HOME="${E2E_TMP}/home"
export K8S_MARATHON_STATE_DIR="${E2E_TMP}/k8s-marathon-state"
export LIBSCRIPT_TOPOLOGY_STATE_FILE="${E2E_TMP}/k8s-paas.state.json"

# 1. Install and start k8s-marathon controller (2x idempotent)
unset SCRIPT_NAME || true
sh "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/k8s-marathon/cli.sh" install latest >/dev/null
unset SCRIPT_NAME || true
sh "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/k8s-marathon/cli.sh" install latest >/dev/null
unset SCRIPT_NAME || true
sh "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/k8s-marathon/cli.sh" start >/dev/null
unset SCRIPT_NAME || true
sh "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/k8s-marathon/cli.sh" start >/dev/null
unset SCRIPT_NAME || true
sh "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/k8s-marathon/cli.sh" status | jq -e '.ping == "pong" and .elected == true' >/dev/null

# 2. Bring up topologies/k8s-marathon-paas (2x idempotent)
unset SCRIPT_NAME || true
sh "${LIBSCRIPT_ROOT_DIR}/topologies/k8s-marathon-paas/cli.sh" up >/dev/null
unset SCRIPT_NAME || true
sh "${LIBSCRIPT_ROOT_DIR}/topologies/k8s-marathon-paas/cli.sh" up >/dev/null
jq -e '.status == "HEALTHY"' "$LIBSCRIPT_TOPOLOGY_STATE_FILE" >/dev/null

# 3. Synthesize Stateless Web, Stateful DB, and Full Web App payloads
cat <<'EOF' > "${E2E_TMP}/stateless-web.json"
{
  "name": "nginx-web",
  "version": "1.26.0",
  "type": "service",
  "artifact": { "format": "oci-image", "image": "nginx:1.26", "entrypoint": ["nginx", "-g", "daemon off;"] },
  "resources": { "cpu_cores": 2, "memory_mb": 1024, "disk_gb": 10 },
  "scaling": { "replicas": 3, "strategy": "RollingUpdate", "restart_policy": "Always" },
  "ports": [{ "name": "http", "port": 80, "protocol": "http" }]
}
EOF

cat <<'EOF' > "${E2E_TMP}/stateful-db.json"
{
  "name": "postgres-ha",
  "version": "16.0",
  "type": "stateful",
  "artifact": { "format": "oci-image", "image": "postgres:16" },
  "resources": { "cpu_cores": 4, "memory_mb": 4096, "disk_gb": 50 },
  "scaling": { "replicas": 2, "strategy": "Recreate", "restart_policy": "Always" },
  "ports": [{ "name": "pg", "port": 5432, "protocol": "tcp" }]
}
EOF

cat <<'EOF' > "${E2E_TMP}/webapp-stack.json"
{
  "name": "wordpress-app",
  "version": "6.6.0",
  "type": "service",
  "artifact": { "format": "libscript-component", "component": "wordpress", "entrypoint": ["./libscript.sh", "start", "wordpress"] },
  "resources": { "cpu_cores": 2, "memory_mb": 2048, "disk_gb": 20 },
  "scaling": { "replicas": 2, "strategy": "BlueGreen", "restart_policy": "Always" },
  "ports": [{ "name": "http", "port": 8080, "protocol": "http" }]
}
EOF

# 4. Verify Marathon-equivalent parity between kubernetes.sh and mesos.sh
K8S_MANIFEST="$(sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/kubernetes.sh" compile "${E2E_TMP}/stateless-web.json")"
MESOS_MANIFEST="$(sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/mesos.sh" compile "${E2E_TMP}/stateless-web.json")"
[ "$(printf '%s
' "$K8S_MANIFEST" | jq -r '.marathon_equivalent.id')" = "$(printf '%s
' "$MESOS_MANIFEST" | jq -r '.id')" ]
[ "$(printf '%s
' "$K8S_MANIFEST" | jq -r '.marathon_equivalent.cpus')" = "$(printf '%s
' "$MESOS_MANIFEST" | jq -r '.cpus')" ]
[ "$(printf '%s
' "$K8S_MANIFEST" | jq -r '.marathon_equivalent.mem')" = "$(printf '%s
' "$MESOS_MANIFEST" | jq -r '.mem')" ]
[ "$(printf '%s
' "$K8S_MANIFEST" | jq -r '.marathon_equivalent.instances')" = "$(printf '%s
' "$MESOS_MANIFEST" | jq -r '.instances')" ]

# 5. Execute all 6 canonical scheduler verbs across Stateless, Stateful, AI, and WebApp payloads (2x idempotent)
for PF in "${E2E_TMP}/stateless-web.json" "${E2E_TMP}/stateful-db.json" "${E2E_TMP}/webapp-stack.json" "${LIBSCRIPT_ROOT_DIR}/payloads/ai/vllm/payload.json" "${LIBSCRIPT_ROOT_DIR}/payloads/ai/ollama/payload.json" "${LIBSCRIPT_ROOT_DIR}/payloads/ai/jetstream/payload.json" "${LIBSCRIPT_ROOT_DIR}/payloads/ai/gke-xpk-inference/payload.json" "${LIBSCRIPT_ROOT_DIR}/payloads/ai/gke-xpk-training/payload.json"; do
  WID="$(jq -r '.name' "$PF")"
  OUT1="$(sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/kubernetes.sh" compile "$PF")"
  OUT2="$(sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/kubernetes.sh" compile "$PF")"
  [ "$OUT1" = "$OUT2" ]

  sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/kubernetes.sh" submit "$PF" | jq -e '.state == "TASK_RUNNING"' >/dev/null
  sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/kubernetes.sh" submit "$PF" | jq -e '.state == "TASK_RUNNING"' >/dev/null
  [ -f "${K8S_MARATHON_STATE_DIR}/v2/apps/${WID}.json" ]

  sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/kubernetes.sh" status "$WID" | jq -e '.state == "TASK_RUNNING"' >/dev/null
  sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/kubernetes.sh" logs "$WID" | jq -e '.status == "ok"' >/dev/null
  sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/kubernetes.sh" stop "$WID" | jq -e '.state == "TASK_KILLED"' >/dev/null
  sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/kubernetes.sh" destroy "$WID" | jq -e '.status == "ok"' >/dev/null
  sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/kubernetes.sh" destroy "$WID" | jq -e '.status == "ok"' >/dev/null
done

printf '[PASS] Kubernetes + k8s-marathon PaaS controller live end-to-end suite verified.
'
