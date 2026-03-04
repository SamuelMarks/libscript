#!/bin/sh
. "$NETCTL_DIR/lib/prelude.sh"

netctl_emit_dockerfile() {
  state_file="${1:-$NETCTL_STATE_FILE}"
  
  if [ ! -f "$state_file" ]; then
    echo "Error: State file '$state_file' not found." >&2
    return 1
  fi

  # Extract listen ports, filter out unix: and address:port formats, keep only ports
  jq -r '.listen[]' "$state_file" | while read -r listen_str; do
    if echo "$listen_str" | grep -q '^unix:'; then
      continue
    elif echo "$listen_str" | grep -q ':'; then
      port="${listen_str##*:}"
      echo "EXPOSE $port"
    else
      echo "EXPOSE $listen_str"
    fi
  done | sort -u
}
