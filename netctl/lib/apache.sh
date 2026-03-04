#!/bin/sh
. "$NETCTL_DIR/lib/prelude.sh"

netctl_emit_apache() {
  state_file="${1:-$NETCTL_STATE_FILE}"
  
  if [ ! -f "$state_file" ]; then
    echo "Error: State file '$state_file' not found." >&2
    return 1
  fi

  # Global listens
  jq -r '.listen[]' "$state_file" | while read -r port; do
    echo "Listen $port"
  done
  echo ""

  # Start VirtualHost (assuming all ports apply to one VirtualHost block for simplicity)
  first_port=$(jq -r '.listen[0] // "80"' "$state_file")
  echo "<VirtualHost *:$first_port>"

  jq -r '.routes | to_entries[] | "\(.key)\t\(.value.type)\t\(.value.target // "")\t\(.value.pattern // "")"' "$state_file" | while IFS="$(printf '\t')" read -r path type target pattern; do
    case "$type" in
      static)
        echo "    Alias \"$path\" \"$target\""
        echo "    <Directory \"$target\">"
        echo "        Require all granted"
        echo "    </Directory>"
        ;;
      proxy)
        echo "    ProxyPass \"$path\" \"$target\""
        echo "    ProxyPassReverse \"$path\" \"$target\""
        ;;
      rewrite)
        echo "    RewriteEngine On"
        echo "    RewriteRule \"^$path(.*)$\" \"$pattern\" [L]"
        ;;
    esac
  done

  echo "</VirtualHost>"
}
