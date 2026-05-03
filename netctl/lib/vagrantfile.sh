#!/bin/sh

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
. "$NETCTL_DIR/LIB/prelude.sh"

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
