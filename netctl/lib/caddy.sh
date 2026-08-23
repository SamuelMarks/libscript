#!/bin/sh
# ## Overview
# Network control library module for caddy.
# 
# ## Usage
# This script provides internal functions and should not be executed directly.


set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
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

# ## netctl_emit_caddy
# Executes netctl_emit_caddy functionality.
netctl_emit_caddy() {
  state_file="${1:-$NETCTL_STATE_FILE}"

  if [ ! -f "$state_file" ]; then
    printf '%s\n' "Error: State file '$state_file' not found." >&2
    return 1
  fi

  # Combine all listen ports separated by comma, prefixed with ':'
  ports=$(jq -r '.listen | map(":" + .) | join(", ")' "$state_file")

  if [ -n "$ports" ] && [ "$ports" != '""' ]; then
    printf '%s\n' "$ports {"
  else
    printf '%s\n' "localhost {"
  fi

  jq -r '.routes | to_entries[] | "\(.key)\t\(.value.type)\t\(.value.target // "")\t\(.value.pattern // "")"' "$state_file" | while IFS="$(printf '\t')" read -r path type target pattern; do
    printf '%s\n' ""
    case "$type" in
      static)
        printf '%s\n' "    handle $path* {"
        printf '%s\n' "        root * $target"
        printf '%s\n' "        file_server"
        printf '%s\n' "    }"
        ;;
      proxy)
        printf '%s\n' "    reverse_proxy $path* $target"
        ;;
      rewrite)
        printf '%s\n' "    rewrite $path* $pattern"
        ;;
    esac
  done

  printf '%s\n' "}"
}
