#!/bin/sh
# ## Overview
# Network control library module for emitting Traefik dynamic YAML configurations (traefik.dynamic.yml).
#
# ## Usage
# Sourced by _lib/networking/netctl/cli.sh to provide netctl_emit_traefik.

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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
: "${NETCTL_DIR:=$(cd "$SCRIPT_DIR/.." && pwd)}"
SCRIPT_NAME="${NETCTL_DIR}/lib/prelude.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

# ## netctl_emit_traefik
# Emits Traefik dynamic routing configuration YAML from the active .netctl.json state file.
netctl_emit_traefik() {
  state_file="${1:-$NETCTL_STATE_FILE}"
  if [ ! -f "$state_file" ]; then
    printf '%s\n' "Error: State file '$state_file' not found." >&2
    return 1
  fi
  printf 'http:
  routers:
'
  idx=0
  jq -r '.routes | to_entries[] | "\(.key)	\(.value.type)	\(.value.target // "")"' "$state_file" | while IFS="$(printf '	')" read -r path rtype target; do
    idx=$((idx + 1))
    printf '    route_%d:
      rule: "PathPrefix(`%s`)"
      service: service_%d
' "$idx" "$path" "$idx"
  done
  printf '  services:\n'
  idx=0
  jq -r '.routes | to_entries[] | "\(.key)	\(.value.type)	\(.value.target // "")"' "$state_file" | while IFS="$(printf '	')" read -r path rtype target; do
    idx=$((idx + 1))
    printf '    service_%d:
      loadBalancer:
        servers:
          - url: "%s"
' "$idx" "$target"
  done
}
