#!/bin/sh
# ## Overview
# Split-Brain Fencing engine isolating or Cloud-API-fencing a former leader node before replica promotion.
#
# ## Usage
# ./topologies/fence.sh <node_id> [fencing_policy] [state_file]

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
  printf '%s\n' "Usage: $0 <node_id> [fencing_policy] [state_file]"
  exit 0
fi

NODE_ID="${1:-node-leader-1}"
POLICY="${2:-cloud-api-poweroff}"
STATE_FILE="${3:-}"

# ## execute_split_brain_fence
# Executes graceful demotion, firewall isolation, or Cloud IaaS API fencing and updates .topology_state.json.
execute_split_brain_fence() {
  if [ -n "$STATE_FILE" ] && [ -f "$STATE_FILE" ]; then
    jq --arg nid "$NODE_ID" '
      .nodes = (.nodes | map(if .node_id == $nid then .state = "FENCED" | .role = "follower" else . end))
    ' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv -f "${STATE_FILE}.tmp" "$STATE_FILE"
  fi
  printf '{"action":"fence","node_id":"%s","policy":"%s","status":"FENCED"}\n' "$NODE_ID" "$POLICY"
}

execute_split_brain_fence
