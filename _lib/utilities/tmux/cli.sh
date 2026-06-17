#!/bin/sh
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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"

for LIB in _lib/_common/pkg_mgr.sh _lib/_common/log.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: $0 <action> [args...]"
  echo "See README.md for details."
  exit 0
fi

if ! command -v tmux >/dev/null 2>&1; then
  log_error "tmux not found. Please install the utilities/tmux component first."
  exit 1
fi

ACTION="${1:-}"

case "$ACTION" in
  new-session)
    SESSION_NAME="${2:-ml-session}"
    shift 2
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
      log_info "Session $SESSION_NAME already exists. Attaching..."
      tmux attach-session -t "$SESSION_NAME"
    else
      log_info "Creating new detached session: $SESSION_NAME"
      if [ $# -gt 0 ]; then
        tmux new-session -d -s "$SESSION_NAME" "$@"
      else
        tmux new-session -d -s "$SESSION_NAME"
      fi
      log_info "Started successfully."
    fi
    ;;
  attach)
    SESSION_NAME="${2:-ml-session}"
    log_info "Attaching to session: $SESSION_NAME"
    tmux attach-session -t "$SESSION_NAME"
    ;;
  kill)
    SESSION_NAME="${2:-ml-session}"
    log_info "Killing session: $SESSION_NAME"
    tmux kill-session -t "$SESSION_NAME" || true
    ;;
  list)
    tmux list-sessions || true
    ;;
  *)
    log_error "Unknown action: $ACTION. Supported: new-session, attach, kill, list."
    exit 1
    ;;
esac
