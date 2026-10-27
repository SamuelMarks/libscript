#!/bin/sh
# ## Overview
# Network control library module for vagrantfile.
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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
: "${NETCTL_DIR:=$(cd "$SCRIPT_DIR/.." && pwd)}"
SCRIPT_NAME="${NETCTL_DIR}/lib/prelude.sh"
export SCRIPT_NAME
. "${SCRIPT_NAME}"

# ## netctl_emit_vagrantfile
# Performs the netctl_emit_vagrantfile operation and updates component state.
netctl_emit_vagrantfile() {
  state_file="${1:-$NETCTL_STATE_FILE}"

  if [ ! -f "$state_file" ]; then
    printf '%s\n' "Error: State file '$state_file' not found." >&2
    return 1
  fi

  jq -r '.listen[]' "$state_file" | while read -r listen_str; do
    if printf '%s\n' "$listen_str" | grep -q '^unix:'; then
      continue
    elif printf '%s\n' "$listen_str" | grep -q ':'; then
      port="${listen_str##*:}"
      printf '%s\n' "  config.vm.network \"forwarded_port\", guest: $port, host: $port, auto_correct: true"
    else
      printf '%s\n' "  config.vm.network \"forwarded_port\", guest: $listen_str, host: $listen_str, auto_correct: true"
    fi
  done | sort -u
}
