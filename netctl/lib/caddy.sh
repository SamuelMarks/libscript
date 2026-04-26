#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'
. "$NETCTL_DIR/lib/prelude.sh"

netctl_emit_caddy() {
  state_file="${1:-$NETCTL_STATE_FILE}"
  
  if [ ! -f "$state_file" ]; then
    echo "Error: State file '$state_file' not found." >&2
    return 1
  fi

  # Combine all listen ports separated by comma, prefixed with ':'
  ports=$(jq -r '.listen | map(":" + .) | join(", ")' "$state_file")
  
  if [ -n "$ports" ] && [ "$ports" != '""' ]; then
    echo "$ports {"
  else
    echo "localhost {"
  fi

  jq -r '.routes | to_entries[] | "\(.key)\t\(.value.type)\t\(.value.target // "")\t\(.value.pattern // "")"' "$state_file" | while IFS="$(printf '\t')" read -r path type target pattern; do
    echo ""
    case "$type" in
      static)
        echo "    handle $path* {"
        echo "        root * $target"
        echo "        file_server"
        echo "    }"
        ;;
      proxy)
        echo "    reverse_proxy $path* $target"
        ;;
      rewrite)
        echo "    rewrite $path* $pattern"
        ;;
    esac
  done

  echo "}"
}
