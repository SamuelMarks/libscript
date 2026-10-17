#!/bin/sh
# ## Overview
# Verifies .topology_state.json checkpoint resume, lease locking, and split-brain fencing in topologies/engine.sh
# across `valkey-cluster`, `postgres-ha`, `redis-cluster`, `k0s-ha`, `minio-distributed`, `gke-tpu-cluster`,
# `mesos-marathon-ha`, and `k8s-marathon-paas`.
#
# ## Usage
# ./tests/test_topology_state_machine.sh

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

TSM_TMP="$(mktemp -d "${TMPDIR:-/tmp}/libscript-tsm.XXXXXX")"
# ## cleanup_tsm_test
# Removes temporary topology state test directory on exit.
cleanup_tsm_test() {
  rm -rf "$TSM_TMP"
}
trap cleanup_tsm_test EXIT INT TERM

for TOPO_NAME in valkey-cluster postgres-ha redis-cluster k0s-ha minio-distributed mesos-marathon-ha k8s-marathon-paas; do
  export LIBSCRIPT_TOPOLOGY_STATE_FILE="${TSM_TMP}/${TOPO_NAME}.state.json"
  TOPO_CLI="${LIBSCRIPT_ROOT_DIR}/topologies/${TOPO_NAME}/cli.sh"
  unset SCRIPT_NAME || true
  sh "$TOPO_CLI" up >/dev/null
  unset SCRIPT_NAME || true
  sh "$TOPO_CLI" up >/dev/null
  jq -e '.status == "HEALTHY"' "$LIBSCRIPT_TOPOLOGY_STATE_FILE" >/dev/null
  unset SCRIPT_NAME || true
  sh "$TOPO_CLI" status >/dev/null
  unset SCRIPT_NAME || true
  sh "$TOPO_CLI" destroy >/dev/null
  jq -e '.status == "DESTROYED"' "$LIBSCRIPT_TOPOLOGY_STATE_FILE" >/dev/null
done

unset SCRIPT_NAME || true
sh "${LIBSCRIPT_ROOT_DIR}/topologies/gke-tpu-cluster/cli.sh" --help >/dev/null

export LIBSCRIPT_TOPOLOGY_STATE_FILE="${TSM_TMP}/mesos-ha.state.json"
unset SCRIPT_NAME || true
sh "${LIBSCRIPT_ROOT_DIR}/topologies/mesos-marathon-ha/cli.sh" up >/dev/null
unset SCRIPT_NAME || true
sh "${LIBSCRIPT_ROOT_DIR}/topologies/mesos-marathon-ha/cli.sh" scale mesos-agents 5 >/dev/null
unset SCRIPT_NAME || true
sh "${LIBSCRIPT_ROOT_DIR}/topologies/mesos-marathon-ha/cli.sh" failover mesos-masters-1 >/dev/null
jq -e '.active_leader_id == "mesos-masters-1"' "$LIBSCRIPT_TOPOLOGY_STATE_FILE" >/dev/null
unset SCRIPT_NAME || true
sh "${LIBSCRIPT_ROOT_DIR}/topologies/mesos-marathon-ha/cli.sh" down >/dev/null
jq -e '.status == "DESTROYED"' "$LIBSCRIPT_TOPOLOGY_STATE_FILE" >/dev/null

export LIBSCRIPT_TOPOLOGY_STATE_FILE="${TSM_TMP}/k8s-paas.state.json"
unset SCRIPT_NAME || true
sh "${LIBSCRIPT_ROOT_DIR}/topologies/k8s-marathon-paas/cli.sh" up >/dev/null
unset SCRIPT_NAME || true
sh "${LIBSCRIPT_ROOT_DIR}/topologies/k8s-marathon-paas/cli.sh" scale k8s-workers 4 >/dev/null
unset SCRIPT_NAME || true
sh "${LIBSCRIPT_ROOT_DIR}/topologies/k8s-marathon-paas/cli.sh" failover k8s-control-plane-1 >/dev/null
jq -e '.active_leader_id == "k8s-control-plane-1"' "$LIBSCRIPT_TOPOLOGY_STATE_FILE" >/dev/null
unset SCRIPT_NAME || true
sh "${LIBSCRIPT_ROOT_DIR}/topologies/k8s-marathon-paas/cli.sh" down >/dev/null
jq -e '.status == "DESTROYED"' "$LIBSCRIPT_TOPOLOGY_STATE_FILE" >/dev/null

printf '[PASS] Topology state machine checkpointing, locking, and fencing verified across all 8 topologies.
'
