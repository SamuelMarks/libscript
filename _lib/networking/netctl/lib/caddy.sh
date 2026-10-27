#!/bin/sh
# ## Overview
# Network control library module for caddy.
# Supports SPA try_files, WebSockets, and static/proxy routes.
# 
# ## Usage
# This script provides internal functions and should not be executed directly.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
: "${NETCTL_DIR:=$(cd "$SCRIPT_DIR/.." && pwd)}"
SCRIPT_NAME="${NETCTL_DIR}/lib/prelude.sh"
export SCRIPT_NAME
. "${SCRIPT_NAME}"

# ## netctl_emit_caddy
# Performs the netctl_emit_caddy operation and updates component state.
netctl_emit_caddy() {
  state_file="${1:-$NETCTL_STATE_FILE}"

  if [ ! -f "$state_file" ]; then
    printf '%s
' "Error: State file '$state_file' not found." >&2
    return 1
  fi

  ports=$(jq -r '.listen | map(":" + .) | join(", ")' "$state_file")

  if [ -n "$ports" ] && [ "$ports" != '""' ]; then
    printf '%s
' "$ports {"
  else
    printf '%s
' "localhost {"
  fi

  jq -r '.routes | to_entries[] | "\(.key)	\(.value.type)	\(.value.target // "")	\(.value.pattern // "")"' "$state_file" | while IFS="$(printf '	')" read -r path type target pattern; do
    printf '%s
' ""
    case "$type" in
      static)
        printf '%s
' "    handle $path* {"
        printf '%s
' "        root * $target"
        printf '%s
' "        file_server"
        printf '%s
' "    }"
        ;;
      spa)
        printf '%s
' "    handle $path* {"
        printf '%s
' "        root * $target"
        printf '%s
' "        try_files {path} {path}/ /index.html"
        printf '%s
' "        file_server"
        printf '%s
' "    }"
        ;;
      proxy|ws)
        printf '%s
' "    reverse_proxy $path* $target"
        ;;
      rewrite)
        printf '%s
' "    rewrite $path* $pattern"
        ;;
    esac
  done

  printf '%s
' "}"
}
