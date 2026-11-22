#!/bin/sh
# ## Overview
# Lifecycle CLI router for the iot-mqtt-edge-pod hybrid RTOS + MQTT + TimescaleDB topology.
#
# ## Usage
# ./workloads/constellations/iot-mqtt-edge-pod/cli.sh <validate|plan|up|status|down>

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

ACTION="${1:-status}"
shift 1 2>/dev/null || true
if [ "$ACTION" = "validate" ]; then
  jq -e --slurpfile sch "${SCRIPT_DIR}/../topology.schema.json" '($sch[0].required - keys) | length == 0' "${SCRIPT_DIR}/topology.json" >/dev/null
  printf '[OK] Verified topology.json conforms to topology.schema.json\n'
  exit 0
fi
exec "${LIBSCRIPT_ROOT_DIR}/workloads/constellations/engine.sh" "$ACTION" "${SCRIPT_DIR}/topology.json" "$@"
