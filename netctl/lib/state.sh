#!/bin/sh
# ## Overview
# Network control library module for state.
# 
# ## Usage
# This script provides internal functions and should not be executed directly.


set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
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
. "$NETCTL_DIR/LIB/prelude.sh"

NETCTL_STATE_FILE="${NETCTL_STATE_FILE:-.netctl.json}"

# ## netctl_init
# Executes netctl_init functionality.
netctl_init() {
  if [ ! -s "$NETCTL_STATE_FILE" ]; then
    printf '%s\n' '{"listen":[],"routes":{}}' > "$NETCTL_STATE_FILE"
  fi
}

# ## netctl_state_write
# Executes netctl_state_write functionality.
netctl_state_write() {
  # Write stdin to state file safely
  cat > "${NETCTL_STATE_FILE}.tmp"
  mv "${NETCTL_STATE_FILE}.tmp" "$NETCTL_STATE_FILE"
}

# ## netctl_add_listen
# Executes netctl_add_listen functionality.
netctl_add_listen() {
  port="$1"
  netctl_init
  jq --arg p "$port" '.listen += [$p] | .listen |= unique' "$NETCTL_STATE_FILE" | netctl_state_write
}

# ## netctl_add_static
# Executes netctl_add_static functionality.
netctl_add_static() {
  path="$1"
  target="$2"
  netctl_init
  jq --arg p "$path" --arg t "$target" '.routes[$p] = {"type": "static", "target": $t}' "$NETCTL_STATE_FILE" | netctl_state_write
}

# ## netctl_add_proxy
# Executes netctl_add_proxy functionality.
netctl_add_proxy() {
  path="$1"
  target="$2"
  netctl_init
  jq --arg p "$path" --arg t "$target" '.routes[$p] = {"type": "proxy", "target": $t}' "$NETCTL_STATE_FILE" | netctl_state_write
}

# ## netctl_add_rewrite
# Executes netctl_add_rewrite functionality.
netctl_add_rewrite() {
  path="$1"
  pattern="$2"
  netctl_init
  jq --arg p "$path" --arg pt "$pattern" '.routes[$p] = {"type": "rewrite", "pattern": $pt}' "$NETCTL_STATE_FILE" | netctl_state_write
}
