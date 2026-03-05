#!/bin/sh
# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145


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
