#!/bin/sh
# ## Overview
# T5 Topology State Machine & Choreography Engine executing real UTC checkpointing,
# TFRC zero-cost enforcement, dynamic `scale` reconciliation, and idempotent choreography hooks.
#
# ## Usage
# ./infrastructure/clusters/engine.sh <up|status|scale|drain|failover|upgrade|destroy> <topology.json> [--live|--mock|--dry-run] [args...]

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
export LIBSCRIPT_ROOT_DIR

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf 'Usage: %s <up|status|scale|drain|failover|upgrade|destroy> <topology.json> [--live|--mock|--dry-run] [args...]\n' "${THIS_FILE}"
  exit 0
fi

_te_this="${THIS_FILE}"; _te_dir="${SCRIPT_DIR}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/tfrc_guard.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true
THIS_FILE="${_te_this}"; SCRIPT_DIR="${_te_dir}"

CMD="${1:-status}"
TOPO_FILE="${2:-}"
shift 2 2>/dev/null || shift $#

EXEC_MODE='staged'
[ "${LIBSCRIPT_TOPOLOGY_LIVE:-0}" = "1" ] && EXEC_MODE='live'
EXTRA_POS=''
while [ $# -gt 0 ]; do
  case "$1" in
    --live) EXEC_MODE='live'; shift ;;
    --mock|--dry-run) EXEC_MODE='mock'; shift ;;
    *) [ -z "$EXTRA_POS" ] && EXTRA_POS="$1"; shift ;;
  esac
done

[ -n "$TOPO_FILE" ] && [ -f "$TOPO_FILE" ] || { printf '[ERROR] Valid topology.json path required.\n' >&2; exit 1; }

TOPO_NAME=$(jq -r '.name' "$TOPO_FILE")
case "$TOPO_NAME" in
  *gke*)
    if [ "$CMD" != "status" ] && libscript_tfrc_is_enabled; then
      ML_TARGET='gcp-gke-tpu-cluster'
      export ML_TARGET
      libscript_tfrc_require_config "$(dirname -- "$TOPO_FILE")"
      libscript_tfrc_enforce_zero_cost_env
    fi
    ;;
esac

TOPO_DIR=$(cd -- "$(dirname -- "$TOPO_FILE")" && pwd)
if [ -n "${LIBSCRIPT_TOPOLOGY_STATE_FILE:-}" ]; then
  STATE_FILE="$LIBSCRIPT_TOPOLOGY_STATE_FILE"
  STATE_BASE=$(dirname -- "$STATE_FILE")
  mkdir -p "$STATE_BASE"
else
  STATE_BASE="${LIBSCRIPT_TOPOLOGY_STATE_DIR:-$TOPO_DIR}"
  mkdir -p "$STATE_BASE"
  STATE_FILE="${STATE_BASE}/.topology_state.json"
fi
LOCK_DIR="${STATE_FILE}.lock"

# ## now_utc
# Returns the current ISO-8601 UTC timestamp.
now_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# ## acquire_lock
# Acquires an atomic directory lease lock for concurrent state-file safety.
acquire_lock() {
  _tries=0
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    _tries=$((_tries + 1))
    [ "$_tries" -gt 50 ] && { printf '[ERROR] Lease lock held: %s\n' "$LOCK_DIR" >&2; exit 1; }
    sleep 1
  done
  printf '%s\n' "$$" > "${LOCK_DIR}/owner.pid"
}

# ## release_lock
# Releases the topology state lease lock.
release_lock() {
  rm -rf "$LOCK_DIR" 2>/dev/null || true
}
trap release_lock EXIT INT TERM

# ## checkpoint_state
# Atomically mutates .topology_state.json using jq and updates updated_at.
checkpoint_state() {
  _expr="$1"
  _ts=$(now_utc)
  jq --arg ts "$_ts" "($_expr) | .updated_at = \$ts" "$STATE_FILE" > "${STATE_FILE}.tmp"
  mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

# ## init_or_resume_state
# Initializes .topology_state.json from topology.json if not already present.
init_or_resume_state() {
  if [ ! -f "$STATE_FILE" ]; then
    _ts=$(now_utc)
    jq --arg ts "$_ts" --arg mode "$EXEC_MODE" '{
      topology: .name,
      version: .version,
      mode: $mode,
      quorum_strategy: .quorum_strategy,
      fencing_policy: .fencing_policy,
      status: "INIT",
      updated_at: $ts,
      completed_hooks: [],
      nodes: [
        .node_groups[] as $g | range(0; ($g.count // $g.replicas // 1)) | {
          id: "\($g.name)-\(.)",
          group: $g.name,
          role: $g.role,
          provider: $g.provider,
          region: $g.region,
          size: $g.size,
          state: "PENDING",
          private_ip: "172.30.\((. / 250 | floor) + 1).\((. % 250) + 10)"
        }
      ]
    }' "$TOPO_FILE" > "${STATE_FILE}.tmp"
    mv "${STATE_FILE}.tmp" "$STATE_FILE"
  fi
}

# ## run_choreography_phase
# Executes choreography hooks for a lifecycle phase idempotently once per topology run.
run_choreography_phase() {
  _phase="$1"
  if jq -e --arg p "$_phase" '(.completed_hooks // []) | index($p) != null' "$STATE_FILE" >/dev/null 2>&1; then
    return 0
  fi
  if [ "$EXEC_MODE" = "live" ]; then
    jq -r --arg p "$_phase" '.choreography[$p][]? // empty' "$TOPO_FILE" | while IFS= read -r _hcmd; do
      [ -z "$_hcmd" ] && continue
      sh -c "$_hcmd" >&2
    done
  fi
  checkpoint_state ".completed_hooks = (((.completed_hooks // []) + [\"${_phase}\"]) | unique)"
}

case "$CMD" in
  up)
    acquire_lock
    init_or_resume_state
    run_choreography_phase "pre_provision"
    checkpoint_state '.status = "PROVISIONING" | .nodes = (.nodes | map(if .state == "PENDING" then .state = "PROVISIONED" else . end))'
    if [ "$EXEC_MODE" = "live" ]; then
      for _tr in $(jq -r '[.node_groups[].traits[]? // empty] | unique | .[]' "$TOPO_FILE"); do
        STACK='' sh "${LIBSCRIPT_ROOT_DIR}/traits/engine.sh" apply "$_tr" >&2
      done
    fi
    run_choreography_phase "substrate_prep"
    checkpoint_state '.nodes = (.nodes | map(if .state == "PROVISIONED" then .state = "SUBSTRATE_READY" else . end))'
    run_choreography_phase "leader_bootstrap"
    checkpoint_state '.nodes = (.nodes | map(if (.role == "leader" and .state == "SUBSTRATE_READY") then .state = "HEALTHY" else . end))'
    run_choreography_phase "follower_join"
    checkpoint_state '.nodes = (.nodes | map(if .state == "SUBSTRATE_READY" then .state = "HEALTHY" else . end))'
    run_choreography_phase "post_cluster"
    checkpoint_state '.status = "HEALTHY"'
    release_lock
    cat "$STATE_FILE"
    ;;
  status)
    if [ ! -f "$STATE_FILE" ]; then
      printf '{"topology":"%s","status":"UNINITIALIZED"}\n' "$TOPO_NAME"
    else
      cat "$STATE_FILE"
    fi
    ;;
  scale)
    acquire_lock
    init_or_resume_state
    GROUP_SPEC="$EXTRA_POS"
    GROUP_NAME="${GROUP_SPEC%%=*}"
    GROUP_COUNT="${GROUP_SPEC#*=}"
    _ts=$(now_utc)
    jq --arg gn "$GROUP_NAME" --argjson gc "$GROUP_COUNT" --arg ts "$_ts" --slurpfile topo "$TOPO_FILE" '
      (([ $topo[0].node_groups[] | select(.name == $gn) ][0]) // {}) as $group_def
      | (.nodes | map(select(.group != $gn))) as $other
      | (.nodes | map(select(.group == $gn))) as $cur
      | .updated_at = $ts
      | .status = "HEALTHY"
      | .nodes = (
          $other + [
            range(0; $gc) as $i
            | if ($i < ($cur | length)) then $cur[$i]
              else {
                id: "\($gn)-\($i)",
                group: $gn,
                role: ($group_def.role // "worker"),
                provider: ($group_def.provider // "gcp"),
                region: ($group_def.region // "us-central1"),
                size: ($group_def.size // "standard"),
                state: "HEALTHY",
                private_ip: "172.30.10.\($i + 10)"
              } end
          ]
        )
    ' "$STATE_FILE" > "${STATE_FILE}.tmp"
    mv "${STATE_FILE}.tmp" "$STATE_FILE"
    release_lock
    cat "$STATE_FILE"
    ;;
  drain)
    acquire_lock
    init_or_resume_state
    NODE_ID="$EXTRA_POS"
    run_choreography_phase "pre_drain"
    checkpoint_state "(.nodes[] | select(.id == \"$NODE_ID\")).state = \"DRAINED\""
    release_lock
    cat "$STATE_FILE"
    ;;
  failover)
    acquire_lock
    init_or_resume_state
    DEAD_LEADER="$EXTRA_POS"
    "${LIBSCRIPT_ROOT_DIR}/engine/consensus/fence.sh" "$DEAD_LEADER" 'cloud-api-poweroff' "$STATE_FILE" >/dev/null || true
    checkpoint_state "(.nodes[] | select(.id == \"$DEAD_LEADER\")) |= (.state = \"FENCED\" | .role = \"fenced\")"
    NEW_LEADER=$(jq -r '[.nodes[] | select(.role == "follower" and .state == "HEALTHY")][0].id // empty' "$STATE_FILE")
    [ -n "$NEW_LEADER" ] && checkpoint_state "(.nodes[] | select(.id == \"$NEW_LEADER\")).role = \"leader\""
    release_lock
    cat "$STATE_FILE"
    ;;
  upgrade)
    acquire_lock
    init_or_resume_state
    for nid in $(jq -r '.nodes[] | select(.role != "leader") | .id' "$STATE_FILE"); do
      checkpoint_state "(.nodes[] | select(.id == \"$nid\")).upgraded = true"
    done
    for nid in $(jq -r '.nodes[] | select(.role == "leader") | .id' "$STATE_FILE"); do
      checkpoint_state "(.nodes[] | select(.id == \"$nid\")).upgraded = true"
    done
    checkpoint_state '.status = "HEALTHY"'
    release_lock
    cat "$STATE_FILE"
    ;;
  destroy)
    acquire_lock
    if [ -f "$STATE_FILE" ]; then
      run_choreography_phase "post_destroy"
      checkpoint_state '.status = "DESTROYED" | .nodes = (.nodes | map(.state = "DESTROYED"))'
      release_lock
      cat "$STATE_FILE"
    else
      release_lock
      printf '{"topology":"%s","status":"DESTROYED"}\n' "$TOPO_NAME"
    fi
    ;;
  *)
    printf '[ERROR] Unknown topology engine command: %s\n' "$CMD" >&2
    exit 1
    ;;
esac
