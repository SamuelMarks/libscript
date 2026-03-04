#!/bin/sh
. "$NETCTL_DIR/lib/prelude.sh"

NETCTL_STATE_FILE="${NETCTL_STATE_FILE:-.netctl.json}"

netctl_init() {
  if [ ! -s "$NETCTL_STATE_FILE" ]; then
    echo '{"listen":[],"routes":{}}' > "$NETCTL_STATE_FILE"
  fi
}

netctl_state_write() {
  # Write stdin to state file safely
  cat > "${NETCTL_STATE_FILE}.tmp"
  mv "${NETCTL_STATE_FILE}.tmp" "$NETCTL_STATE_FILE"
}

netctl_add_listen() {
  port="$1"
  netctl_init
  jq --arg p "$port" '.listen += [$p] | .listen |= unique' "$NETCTL_STATE_FILE" | netctl_state_write
}

netctl_add_static() {
  path="$1"
  target="$2"
  netctl_init
  jq --arg p "$path" --arg t "$target" '.routes[$p] = {"type": "static", "target": $t}' "$NETCTL_STATE_FILE" | netctl_state_write
}

netctl_add_proxy() {
  path="$1"
  target="$2"
  netctl_init
  jq --arg p "$path" --arg t "$target" '.routes[$p] = {"type": "proxy", "target": $t}' "$NETCTL_STATE_FILE" | netctl_state_write
}

netctl_add_rewrite() {
  path="$1"
  pattern="$2"
  netctl_init
  jq --arg p "$path" --arg pt "$pattern" '.routes[$p] = {"type": "rewrite", "pattern": $pt}' "$NETCTL_STATE_FILE" | netctl_state_write
}
