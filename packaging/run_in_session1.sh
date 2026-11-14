#!/bin/sh
# ## Overview
# Executes a target command inside the active interactive desktop session on POSIX
# (Wayland/X11 user session) or delegates to run_in_session1.cmd on Windows without pwsh.
#
# ## Usage
# ./packaging/run_in_session1.sh [command...]

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

# ## show_help
# Displays usage instructions for interactive desktop session command dispatch.
show_help() {
  printf 'Usage: %s [-Command <cmd> | <cmd> [args...]]\n' "$(basename "$THIS_FILE")"
  printf 'Runs a command inside the active interactive GUI session.\n'
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  show_help
  exit 0
fi

if [ "${1:-}" = "-Command" ] || [ "${1:-}" = "--command" ]; then
  shift
fi

if [ $# -eq 0 ]; then
  printf '[INFO] No command supplied to run_in_session1.sh; nothing to execute.\n'
  exit 0
fi

if command -v cmd.exe >/dev/null 2>&1 && [ "${OS:-}" = "Windows_NT" ]; then
  cmd.exe /c "${SCRIPT_DIR}/run_in_session1.cmd" "$@"
  exit $?
fi

: "${DISPLAY:=:0}"
export DISPLAY
if [ -z "${XDG_RUNTIME_DIR:-}" ] && [ -d "/run/user/$(id -u)" ]; then
  XDG_RUNTIME_DIR="/run/user/$(id -u)"
  export XDG_RUNTIME_DIR
fi

exec "$@"
