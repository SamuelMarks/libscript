#!/bin/sh
# ## Overview
# Command-line interface to tail log files for the Open edX stack.
# Supports tailing install logs, web server logs, or worker logs.
#
# ## Usage
#   ./logs.sh [target] [-n NUM]
#
# ## Parameters
# - `target`: Target to tail: 'install' (default), 'lms', 'cms', 'worker'.
# - `-n NUM`: Output the last NUM lines, instead of the default 50.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE[0]-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
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

TARGET="install"
LINES="50"

while [ $# -gt 0 ]; do
  case "$1" in
    -n|--lines) LINES="$2"; shift 2 ;;
    help|--help|-h)
      printf "Usage: logs.sh [install|lms|cms|worker] [-n NUM]\n"
      exit 0
      ;;
    -*) printf "Unknown option %s\n" "$1" >&2; exit 1 ;;
    *) TARGET="$1"; shift ;;
  esac
done

OPENEDX_LOG_DIR="${OPENEDX_INSTALL_DIR:-$HOME/.libscript/openedx}/logs"
case "$TARGET" in
  install) LOG_FILE="${OPENEDX_LOG_DIR}/install.log" ;;
  lms) LOG_FILE="${OPENEDX_LOG_DIR}/lms.log" ;;
  cms) LOG_FILE="${OPENEDX_LOG_DIR}/cms.log" ;;
  worker) LOG_FILE="${OPENEDX_LOG_DIR}/worker.log" ;;
  *) printf "Unknown log target: %s\n" "$TARGET" >&2; exit 1 ;;
esac

if [ -f "$LOG_FILE" ]; then
  tail -n "$LINES" -f "$LOG_FILE"
else
  printf "Log file not found: %s\n" "$LOG_FILE" >&2
  exit 1
fi
