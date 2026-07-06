#!/bin/sh
# ## Overview
# Command-line interface entry point for TensorBoard.
#
# ## Usage
# Provides a thin wrapper around the `tensorboard` executable. Run `libscript.sh logging/tensorboard start [logdir] [port]`.

set -feu

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
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"

for LIB in _lib/_common/pkg_mgr.sh _lib/_common/log.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 <action> [args...]"
  printf '%s\n' "See README.md for details."
  exit 0
fi

if ! command -v tensorboard >/dev/null 2>&1; then
  if [ -x "${LIBSCRIPT_ROOT_DIR}/installed/tensorboard/bin/tensorboard" ]; then
    export PATH="${LIBSCRIPT_ROOT_DIR}/installed/tensorboard/bin:${PATH}"
  else
    log_error "tensorboard not found. Please install the logging/tensorboard component first."
    exit 1
  fi
fi

ACTION="${1:-}"

case "$ACTION" in
  start)
    LOGDIR="${2:-/tmp/logs}"
    PORT="${3:-6006}"
    log_info "Starting TensorBoard on port $PORT tracking $LOGDIR..."
    tensorboard --logdir="$LOGDIR" --port="$PORT" --host=0.0.0.0
    ;;
  *)
    log_error "Unknown action: $ACTION. Supported: start."
    exit 1
    ;;
esac
