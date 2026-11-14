#!/bin/sh
# ## Overview
# Diagnostic utility to inspect GUI window trees and control properties across
# Wayland (swaymsg), X11 (xwininfo/xdotool), and Windows (inspect_window.cmd) without pwsh.
#
# ## Usage
# ./packaging/inspect_window.sh [--help]

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
# Prints command-line usage instructions for window hierarchy inspection.
show_help() {
  printf 'Usage: %s [--help]\n' "$(basename "$THIS_FILE")"
  printf 'Inspects active GUI window hierarchy via Wayland swaymsg, X11 xwininfo, or Windows cmd.\n'
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  show_help
  exit 0
fi

if command -v cmd.exe >/dev/null 2>&1 && [ "${OS:-}" = "Windows_NT" ]; then
  cmd.exe /c "${SCRIPT_DIR}/inspect_window.cmd" "$@"
  exit $?
fi

if [ -n "${SWAYSOCK:-}" ] && command -v swaymsg >/dev/null 2>&1; then
  swaymsg -t get_tree
  exit 0
fi

if [ -n "${DISPLAY:-}" ] && command -v xwininfo >/dev/null 2>&1; then
  xwininfo -root -tree
  exit 0
fi

if [ -n "${DISPLAY:-}" ] && command -v xdotool >/dev/null 2>&1; then
  xdotool search --onlyvisible --name ".*" getwindowname %@ 2>/dev/null || true
  exit 0
fi

printf '[ERROR] No active GUI inspection backend available (requires swaymsg on Wayland, xwininfo/xdotool on X11, or Windows).\n' >&2
exit 1
