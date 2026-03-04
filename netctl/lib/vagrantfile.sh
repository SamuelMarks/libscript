#!/bin/sh
. "$NETCTL_DIR/lib/prelude.sh"

netctl_emit_vagrantfile() {
  state_file="${1:-$NETCTL_STATE_FILE}"
  
  if [ ! -f "$state_file" ]; then
    echo "Error: State file '$state_file' not found." >&2
    return 1
  fi

  jq -r '.listen[]' "$state_file" | while read -r listen_str; do
    if echo "$listen_str" | grep -q '^unix:'; then
      continue
    elif echo "$listen_str" | grep -q ':'; then
      port="${listen_str##*:}"
      echo "  config.vm.network \"forwarded_port\", guest: $port, host: $port, auto_correct: true"
    else
      echo "  config.vm.network \"forwarded_port\", guest: $listen_str, host: $listen_str, auto_correct: true"
    fi
  done | sort -u
}
