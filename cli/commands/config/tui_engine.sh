#!/bin/sh
# ## Overview
# Modular Text User Interface (TUI) engine supporting whiptail, dialog,
# and portable ANSI VT100 POSIX terminal fallbacks for interactive configuration.
#
# ## Usage
# Source this engine in config scripts:
#   . "${LIBSCRIPT_ROOT_DIR}/cli/commands/config/tui_engine.sh"
#   choice=$(tui_menu "Title" "Select an option" "1" "Option One" "2" "Option Two")

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
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
export LIBSCRIPT_ROOT_DIR

# Backend detection
TUI_BACKEND="vt100"
if command -v whiptail >/dev/null 2>&1; then
  TUI_BACKEND="whiptail"
elif command -v dialog >/dev/null 2>&1; then
  TUI_BACKEND="dialog"
fi

# ## tui_msgbox
# Displays an informational message box.
tui_msgbox() {
  _title="$1"
  _text="$2"
  case "$TUI_BACKEND" in
    whiptail)
      whiptail --title "$_title" --msgbox "$_text" 12 70
      ;;
    dialog)
      dialog --title "$_title" --msgbox "$_text" 12 70
      ;;
    *)
      printf '
=== %s ===
%s

Press ENTER to continue...' "$_title" "$_text"
      read -r _dummy || true
      ;;
  esac
}

# ## tui_menu
# Displays a single-choice menu and returns the selected tag to stdout.
tui_menu() {
  _title="$1"
  _text="$2"
  shift 2
  case "$TUI_BACKEND" in
    whiptail)
      whiptail --title "$_title" --menu "$_text" 20 74 10 "$@" 3>&1 1>&2 2>&3
      ;;
    dialog)
      dialog --title "$_title" --menu "$_text" 20 74 10 "$@" 3>&1 1>&2 2>&3
      ;;
    *)
      printf '
=== %s ===
%s
' "$_title" "$_text" >&2
      _idx=1
      _tags=""
      while [ $# -gt 0 ]; do
        _tag="$1"
        _desc="$2"
        shift 2
        printf '  [%s] %s
' "$_tag" "$_desc" >&2
        _tags="${_tags} ${_tag}"
      done
      printf 'Select option: ' >&2
      read -r _choice || true
      printf '%s
' "$_choice"
      ;;
  esac
}

# ## tui_input
# Prompts for text input and returns the value to stdout.
tui_input() {
  _title="$1"
  _prompt="$2"
  _default="${3:-}"
  case "$TUI_BACKEND" in
    whiptail)
      whiptail --title "$_title" --inputbox "$_prompt" 10 65 "$_default" 3>&1 1>&2 2>&3
      ;;
    dialog)
      dialog --title "$_title" --inputbox "$_prompt" 10 65 "$_default" 3>&1 1>&2 2>&3
      ;;
    *)
      printf '%s [%s]: ' "$_prompt" "$_default" >&2
      read -r _val || true
      if [ -z "$_val" ]; then
        printf '%s
' "$_default"
      else
        printf '%s
' "$_val"
      fi
      ;;
  esac
}
