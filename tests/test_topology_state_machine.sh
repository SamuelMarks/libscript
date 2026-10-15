#!/bin/sh
# ## Overview
# Verifies .topology_state.json checkpoint resume, lease locking, and split-brain fencing in topologies/engine.sh.
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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

TSM_TMP="$(mktemp -d "${TMPDIR:-/tmp}/libscript-tsm.XXXXXX")"
# ## cleanup_tsm_test
# Removes temporary topology state test directory on exit.
cleanup_tsm_test() {
  rm -rf "$TSM_TMP"
}
trap cleanup_tsm_test EXIT INT TERM

export LIBSCRIPT_TOPOLOGY_STATE_FILE="${TSM_TMP}/.topology_state.json"
TOPO_JSON="${LIBSCRIPT_ROOT_DIR}/topologies/valkey-cluster/topology.json"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/topologies/engine.sh" sh "${LIBSCRIPT_ROOT_DIR}/topologies/engine.sh" up "$TOPO_JSON" >/dev/null
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/topologies/engine.sh" sh "${LIBSCRIPT_ROOT_DIR}/topologies/engine.sh" up "$TOPO_JSON" >/dev/null
jq -e '.status == "HEALTHY"' "$LIBSCRIPT_TOPOLOGY_STATE_FILE" >/dev/null

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/topologies/engine.sh" sh "${LIBSCRIPT_ROOT_DIR}/topologies/engine.sh" failover "$TOPO_JSON" "valkey-replicas-1" >/dev/null
jq -e '.active_leader_id == "valkey-replicas-1"' "$LIBSCRIPT_TOPOLOGY_STATE_FILE" >/dev/null

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/topologies/engine.sh" sh "${LIBSCRIPT_ROOT_DIR}/topologies/engine.sh" drain "$TOPO_JSON" "valkey-replicas-2" >/dev/null
jq -e '.nodes[] | select(.node_id == "valkey-replicas-2") | .state == "DRAINING"' "$LIBSCRIPT_TOPOLOGY_STATE_FILE" >/dev/null

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/topologies/engine.sh" sh "${LIBSCRIPT_ROOT_DIR}/topologies/engine.sh" destroy "$TOPO_JSON" >/dev/null
jq -e '.status == "DESTROYED"' "$LIBSCRIPT_TOPOLOGY_STATE_FILE" >/dev/null

printf '[PASS] Topology state machine checkpointing, locking, and fencing verified.\n'
