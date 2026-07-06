#!/bin/sh
# ## Overview
# Network control library module for apache.
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

netctl_emit_apache() {
  state_file="${1:-$NETCTL_STATE_FILE}"

  if [ ! -f "$state_file" ]; then
    printf '%s\n' "Error: State file '$state_file' not found." >&2
    return 1
  fi

  # Global listens
  jq -r '.listen[]' "$state_file" | while read -r port; do
    printf '%s\n' "Listen $port"
  done
  printf '%s\n' ""

  # Start VirtualHost (assuming all ports apply to one VirtualHost block for simplicity)
  first_port=$(jq -r '.listen[0] // "80"' "$state_file")
  printf '%s\n' "<VirtualHost *:$first_port>"

  jq -r '.routes | to_entries[] | "\(.key)\t\(.value.type)\t\(.value.target // "")\t\(.value.pattern // "")"' "$state_file" | while IFS="$(printf '\t')" read -r path type target pattern; do
    case "$type" in
      static)
        printf '%s\n' "    Alias \"$path\" \"$target\""
        printf '%s\n' "    <Directory \"$target\">"
        printf '%s\n' "        Require all granted"
        printf '%s\n' "    </Directory>"
        ;;
      proxy)
        printf '%s\n' "    ProxyPass \"$path\" \"$target\""
        printf '%s\n' "    ProxyPassReverse \"$path\" \"$target\""
        ;;
      rewrite)
        printf '%s\n' "    RewriteEngine On"
        printf '%s\n' "    RewriteRule \"^$path(.*)$\" \"$pattern\" [L]"
        ;;
    esac
  done

  printf '%s\n' "</VirtualHost>"
}
