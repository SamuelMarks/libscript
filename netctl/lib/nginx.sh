#!/bin/sh
. "$NETCTL_DIR/lib/prelude.sh"

netctl_emit_nginx() {
  state_file="${1:-$NETCTL_STATE_FILE}"
  
  if [ ! -f "$state_file" ]; then
    echo "Error: State file '$state_file' not found." >&2
    return 1
  fi

  echo "server {"

  # Extract listen ports
  jq -r '.listen[]' "$state_file" | while read -r port; do
    echo "    listen $port;"
  done

  # Extract routes
  jq -r '.routes | to_entries[] | "\(.key)\t\(.value.type)\t\(.value.target // "")\t\(.value.pattern // "")"' "$state_file" | while IFS="$(printf '\t')" read -r path type target pattern; do
    echo ""
    echo "    location $path {"
    case "$type" in
      static)
        echo "        alias $target/;"
        ;;
      proxy)
        echo "        proxy_pass $target;"
        echo "        proxy_set_header Host \$host;"
        echo "        proxy_set_header X-Real-IP \$remote_addr;"
        ;;
      rewrite)
        echo "        rewrite $pattern break;"
        ;;
    esac
    echo "    }"
  done

  echo "}"
}
