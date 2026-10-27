#!/bin/sh
# ## Overview
# Lifecycle CLI helper for the mesos-marathon-ha HA topology blueprint.
#
# ## Usage
# ./topologies/mesos-marathon-ha/cli.sh <up|status|scale|drain|failover|upgrade|down|destroy> [args...]

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

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf 'Usage: %s <up|status|scale|drain|failover|upgrade|down|destroy> [args...]
' "$0"
  exit 0
fi

ACTION="${1:-status}"
if [ "$ACTION" = "down" ]; then
  ACTION='destroy'
fi
shift 1 2>/dev/null || true
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/topologies/engine.sh"
export SCRIPT_NAME
exec sh "${LIBSCRIPT_ROOT_DIR}/topologies/engine.sh" "$ACTION" "${SCRIPT_DIR}/topology.json" "$@"
