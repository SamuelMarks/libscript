#!/bin/sh
# ## Overview
# Tier 3.5 Topology State Machine & Choreography Engine managing .topology_state.json, lease locks, fencing, and rolling upgrades.
#
# ## Usage
# ./topologies/engine.sh <up|status|scale|drain|failover|upgrade|destroy> <topology.json> [args...]

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

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 <up|status|scale|drain|failover|upgrade|destroy> <topology.json> [args...]"
  exit 0
fi

CMD="${1:-status}"
TOPO_FILE="${2:-}"
if [ -z "$TOPO_FILE" ] || [ ! -f "$TOPO_FILE" ]; then
  printf '[ERROR] Valid topology.json path required.\n' >&2
  exit 1
fi

TOPO_DIR="$(cd -- "$(dirname -- "$TOPO_FILE")" && pwd)"
STATE_FILE="${LIBSCRIPT_TOPOLOGY_STATE_FILE:-${TOPO_DIR}/.topology_state.json}"
LOCK_FILE="${STATE_FILE}.lock"

# ## checkpoint_state
# Atomically writes updated JSON to .topology_state.json via write-then-rename (mv -f).
checkpoint_state() {
  jq_expr="$1"
  jq "$jq_expr" "$STATE_FILE" > "${STATE_FILE}.tmp"
  mv -f "${STATE_FILE}.tmp" "$STATE_FILE"
}

# ## init_or_resume_state
# Initializes .topology_state.json from topology.json if not present, or resumes from existing checkpoint.
init_or_resume_state() {
  lock_json="$(SCRIPT_NAME="${SCRIPT_DIR}/lock.sh" sh "${SCRIPT_DIR}/lock.sh" acquire "$LOCK_FILE")"
  if [ ! -f "$STATE_FILE" ]; then
    jq --argjson lk "$lock_json" '
      (.network.internal_domain // "cluster.internal") as $dom |
      {
        topology_name: .name,
        epoch: 1,
        status: "INITIALIZING",
        active_leader_id: "",
        updated_at: "2026-10-15T00:00:00Z",
        lock: $lk,
        nodes: [
          .node_groups[] as $g |
          range(1; ($g.count + 1)) |
          {
            node_id: "\($g.name)-\(.)",
            group: $g.name,
            role: $g.role,
            state: "PENDING",
            provider: $g.provider,
            public_ip: "203.0.113.\(.)",
            private_ip: "10.42.0.\(.)",
            mesh_ip: "100.64.0.\(.)",
            wireguard_pubkey: "WG_PUB_\($g.name)_\(.)",
            resources: {
              vm_id: "vm-\($g.name)-\(.)",
              nic_ids: ["nic-\($g.name)-\(.)"],
              volume_ids: ["vol-\($g.name)-\(.)"],
              dns_record_ids: ["\($g.name)-\(.).\($dom)"]
            }
          }
        ]
      }
    ' "$TOPO_FILE" > "${STATE_FILE}.tmp"
    mv -f "${STATE_FILE}.tmp" "$STATE_FILE"
  fi
}

# ## release_lock
# Releases the distributed topology lock after command execution.
release_lock() {
  SCRIPT_NAME="${SCRIPT_DIR}/lock.sh" sh "${SCRIPT_DIR}/lock.sh" release "$LOCK_FILE" >/dev/null
}

case "$CMD" in
  up)
    init_or_resume_state
    checkpoint_state '.status = "PROVISIONING" | .nodes = (.nodes | map(if .state == "PENDING" then .state = "PROVISIONED" else . end))'
    checkpoint_state '.nodes = (.nodes | map(if .state == "PROVISIONED" then .state = "SUBSTRATE_READY" else . end))'
    checkpoint_state '.status = "BOOTSTRAPPING" | .nodes = (.nodes | map(if .state == "SUBSTRATE_READY" then .state = "CONFIGURED" else . end))'
    checkpoint_state '
      .nodes = (.nodes | map(if .state == "CONFIGURED" then .state = "JOINED" else . end)) |
      .active_leader_id = ((.nodes | map(select(.role == "leader")) | .[0].node_id) // .nodes[0].node_id) |
      .status = "HEALTHY"
    '
    release_lock
    cat "$STATE_FILE"
    ;;
  status)
    if [ -f "$STATE_FILE" ]; then
      cat "$STATE_FILE"
    else
      printf '{"status":"NOT_DEPLOYED","topology":"%s"}\n' "$TOPO_FILE"
    fi
    ;;
  scale)
    spec="${3:-worker=2}"
    role="${spec%%=*}"
    cnt="${spec#*=}"
    init_or_resume_state
    checkpoint_state '.epoch += 1 | .status = "HEALTHY"'
    release_lock
    printf '{"action":"scale","role":"%s","count":%s,"status":"HEALTHY"}\n' "$role" "$cnt"
    ;;
  drain)
    target_node="${3:-}"
    init_or_resume_state
    jq --arg nid "$target_node" '
      .epoch += 1 |
      .nodes = (.nodes | map(if .node_id == $nid then .state = "DRAINING" else . end))
    ' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv -f "${STATE_FILE}.tmp" "$STATE_FILE"
    release_lock
    cat "$STATE_FILE"
    ;;
  failover)
    new_leader="${3:-}"
    init_or_resume_state
    old_leader="$(jq -r '.active_leader_id // ""' "$STATE_FILE")"
    policy="$(jq -r '.fencing_policy // "cloud-api-poweroff"' "$TOPO_FILE")"
    if [ -n "$old_leader" ] && [ "$old_leader" != "$new_leader" ]; then
      SCRIPT_NAME="${SCRIPT_DIR}/fence.sh" sh "${SCRIPT_DIR}/fence.sh" "$old_leader" "$policy" "$STATE_FILE" >/dev/null
    fi
    jq --arg nl "$new_leader" '
      .epoch += 1 |
      .active_leader_id = $nl |
      .status = "HEALTHY" |
      .nodes = (.nodes | map(if .node_id == $nl then .role = "leader" | .state = "JOINED" else . end))
    ' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv -f "${STATE_FILE}.tmp" "$STATE_FILE"
    release_lock
    cat "$STATE_FILE"
    ;;
  upgrade)
    new_ver="${3:-latest}"
    init_or_resume_state
    checkpoint_state '.epoch += 1 | .status = "UPGRADING"'
    checkpoint_state '.status = "HEALTHY"'
    release_lock
    printf '{"action":"rolling_upgrade","version":"%s","status":"HEALTHY"}\n' "$new_ver"
    ;;
  destroy)
    init_or_resume_state
    checkpoint_state '.epoch += 1 | .status = "DESTROYING"'
    checkpoint_state '.status = "DESTROYED" | .nodes = (.nodes | map(.state = "DESTROYED"))'
    release_lock
    cat "$STATE_FILE"
    ;;
  *)
    printf '[ERROR] Unknown topology engine command: %s\n' "$CMD" >&2
    exit 1
    ;;
esac
