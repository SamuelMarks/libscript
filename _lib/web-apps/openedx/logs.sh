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
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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

TARGET="install"
LINES="50"
FOLLOW=0

while [ $# -gt 0 ]; do
  case "$1" in
    -n|--lines|--tail) LINES="$2"; shift 2 ;;
    -f|--follow) FOLLOW=1; shift ;;
    help|--help|-h)
      printf "Usage: logs.sh [install|lms|cms|worker] [-n NUM|--tail NUM] [-f|--follow]\n"
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
  if [ "$FOLLOW" -eq 1 ]; then
    tail -n "$LINES" -f "$LOG_FILE"
  else
    tail -n "$LINES" "$LOG_FILE"
  fi
else
  printf "Log file not found: %s\n" "$LOG_FILE" >&2
  exit 0
fi
