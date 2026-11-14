#!/bin/sh
# ## Overview
# Automates finding and clicking GUI controls by label across X11/Wayland (xdotool/ydotool)
# and Windows (click_button.cmd) using pure POSIX shell without pwsh.
#
# ## Usage
# ./packaging/click_button.sh [button_text]

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
# Displays usage syntax for automated GUI button clicking.
show_help() {
  printf 'Usage: %s [button_text]\n' "$(basename "$THIS_FILE")"
  printf 'Triggers GUI button activation on X11, Wayland, or Windows.\n'
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  show_help
  exit 0
fi

TARGET_TEXT="${1:-}"
TMP_BASE="${TEMP:-${TMPDIR:-/tmp}}"
mkdir -p "$TMP_BASE"

if [ -n "$TARGET_TEXT" ]; then
  printf '%s\n' "$TARGET_TEXT" > "${TMP_BASE}/target_btn.txt"
fi

if command -v cmd.exe >/dev/null 2>&1 && [ "${OS:-}" = "Windows_NT" ]; then
  cmd.exe /c "${SCRIPT_DIR}/click_button.cmd" "$@"
  exit $?
fi

LOG_FILE="${TMP_BASE}/libscript_click.log"

if [ -n "${DISPLAY:-}" ] && command -v xdotool >/dev/null 2>&1; then
  if [ -n "$TARGET_TEXT" ]; then
    xdotool search --name "$TARGET_TEXT" windowactivate --sync key Return > "$LOG_FILE" 2>&1 || xdotool key Return >> "$LOG_FILE" 2>&1
  else
    xdotool click 1 > "$LOG_FILE" 2>&1
  fi
  exit 0
fi

if command -v ydotool >/dev/null 2>&1; then
  ydotool key 28:1 28:0 > "$LOG_FILE" 2>&1
  exit 0
fi

printf '[ERROR] GUI control automation requires xdotool (X11), ydotool (Wayland), or Windows.\n' >&2
exit 1
