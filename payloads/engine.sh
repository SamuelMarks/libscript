#!/bin/sh
# ## Overview
# Tier 4 Payload Router dispatching compile, submit, status, logs, stop, and destroy to pluggable schedulers.
#
# ## Usage
# ./payloads/engine.sh <compile|submit|status|logs|stop|destroy> <payload.json_or_id> [--scheduler <name>]

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
export LIBSCRIPT_ROOT_DIR

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 <compile|submit|status|logs|stop|destroy> <payload.json_or_id> [--scheduler <name>]"
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" ]; then
    _pe_saved_this="${THIS_FILE}"
    _pe_saved_dir="${SCRIPT_DIR}"
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
    unset SCRIPT_NAME || true
    THIS_FILE="${_pe_saved_this}"
    SCRIPT_DIR="${_pe_saved_dir}"
  fi
  if ! command -v jq >/dev/null 2>&1 && [ -x "${LIBSCRIPT_ROOT_DIR}/libscript.sh" ]; then
    "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install jq >/dev/null 2>&1 || true
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" ]; then
      _pe_saved_this="${THIS_FILE}"
      _pe_saved_dir="${SCRIPT_DIR}"
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh"
      export SCRIPT_NAME
      # shellcheck disable=SC1090
      . "${SCRIPT_NAME}"
      unset SCRIPT_NAME || true
      THIS_FILE="${_pe_saved_this}"
      SCRIPT_DIR="${_pe_saved_dir}"
    fi
  fi
fi

ACTION="${1:-compile}"
TARGET="${2:-}"
SCHEDULER="${LIBSCRIPT_SCHEDULER:-kubernetes}"
shift 2 2>/dev/null || shift $#

EXTRA_ARGS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --scheduler) SCHEDULER="$2"; shift 2 ;;
    --scheduler=*) SCHEDULER="${1#*=}"; shift ;;
    *) EXTRA_ARGS="${EXTRA_ARGS} $1"; shift ;;
  esac
done

SCHED_SCRIPT="${SCRIPT_DIR}/schedulers/${SCHEDULER}.sh"
if [ ! -f "$SCHED_SCRIPT" ]; then
  printf '[ERROR] Unknown scheduler driver: %s\n' "$SCHEDULER" >&2
  exit 1
fi

SCRIPT_NAME="$SCHED_SCRIPT"
export SCRIPT_NAME
# shellcheck disable=SC2086
exec sh "$SCHED_SCRIPT" "$ACTION" "$TARGET" $EXTRA_ARGS
