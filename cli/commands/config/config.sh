#!/bin/sh
# ## Overview
# Declarative OS configuration driver supporting interactive TUI menus,
# profile template selection, headless schema validation, and JSON export.
#
# ## Usage
# Execute config commands:
#   ./libscript.sh config os [--profile=<name>] [--export=<file.json>] [--validate=<file.json>]

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
export LIBSCRIPT_ROOT_DIR

# Source TUI engine
. "${LIBSCRIPT_ROOT_DIR}/cli/commands/config/tui_engine.sh"

SCHEMA_FILE="${LIBSCRIPT_ROOT_DIR}/os-config.schema.json"

TARGET_PROFILE=""
EXPORT_FILE=""
VALIDATE_FILE=""

# Parse subcommands and arguments
if [ $# -gt 0 ] && [ "$1" = "os" ]; then
  shift
fi

while [ $# -gt 0 ]; do
  case "$1" in
    --profile=*)
      TARGET_PROFILE="${1#*=}"
      shift
      ;;
    --profile)
      TARGET_PROFILE="${2:-}"
      shift 2 || shift
      ;;
    --export=*)
      EXPORT_FILE="${1#*=}"
      shift
      ;;
    --export)
      EXPORT_FILE="${2:-}"
      shift 2 || shift
      ;;
    --validate=*)
      VALIDATE_FILE="${1#*=}"
      shift
      ;;
    --validate)
      VALIDATE_FILE="${2:-}"
      shift 2 || shift
      ;;
    --help|-h|/\?|-\?)
      printf 'Usage: %s config os [--profile=<name>] [--export=<out.json>] [--validate=<file.json>]\n' "libscript"
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

# Mode 1: Validate file against os-config.schema.json or OS-specific execution plan schema
if [ -n "$VALIDATE_FILE" ]; then
  if [ ! -f "$VALIDATE_FILE" ]; then
    printf '[ERROR] File to validate not found: %s\n' "$VALIDATE_FILE" >&2
    exit 1
  fi
  if command -v jq >/dev/null 2>&1; then
    active_schema="$SCHEMA_FILE"
    if jq -e '.freebsd_version != null or (.target.os_family == "freebsd" and .init_system != null)' "$VALIDATE_FILE" >/dev/null 2>&1; then
      active_schema="${LIBSCRIPT_ROOT_DIR}/execution-plan.freebsd.schema.json"
    elif jq -e '.illumos_version != null or (.target.os_family == "illumos" or .target.os_family == "sunos")' "$VALIDATE_FILE" >/dev/null 2>&1; then
      active_schema="${LIBSCRIPT_ROOT_DIR}/execution-plan.illumos.schema.json"
    fi
    # Check top-level required fields
    missing_fields=$(jq -r --slurpfile schema "$active_schema" '
      $schema[0].required - keys | .[]
    ' "$VALIDATE_FILE" 2>/dev/null || true)
    if [ -n "$missing_fields" ]; then
      printf '[VALIDATION ERROR] %s is missing required fields: %s\n' "$VALIDATE_FILE" "$missing_fields" >&2
      exit 1
    fi
  fi
  printf '[INFO] Schema validation successful: %s conforms to schema\n' "$VALIDATE_FILE"
  exit 0
fi

# Mode 2: Load profile or select via TUI
CHOSEN_CONFIG=""
if [ -n "$TARGET_PROFILE" ]; then
  profile_path="${LIBSCRIPT_ROOT_DIR}/profiles/${TARGET_PROFILE}.json"
  if [ ! -f "$profile_path" ]; then
    profile_path="${LIBSCRIPT_ROOT_DIR}/profiles/${TARGET_PROFILE}"
  fi
  if [ ! -f "$profile_path" ]; then
    printf '[ERROR] Profile not found: %s\n' "$TARGET_PROFILE" >&2
    exit 1
  fi
  CHOSEN_CONFIG=$(cat "$profile_path")
else
  # Interactive TUI selection
  tui_msgbox "LibScript OS Synthesis" "Welcome to the LibScript OS Configuration Engine."
  selected=$(tui_menu "OS Profiles" "Select a base profile to configure:" 
    "1" "linux-minimal-headless-musl" 
    "2" "linux-standard-server-glibc" 
    "3" "freebsd-server-standard" 
    "4" "firecracker-microvm-appliance" 
    "5" "unikraft-nginx-redis" 
    "6" "osv-cloud-runtime" 
    "7" "linux-desktop-sway-wayland" 
    "8" "linux-desktop-hyprland" 
    "9" "linux-desktop-kde-plasma" 
    "10" "linux-desktop-xfce-x11" 
    "11" "freebsd-desktop-xfce")

  case "$selected" in
    1) TARGET_PROFILE="linux-minimal-headless-musl" ;;
    2) TARGET_PROFILE="linux-standard-server-glibc" ;;
    3) TARGET_PROFILE="freebsd-server-standard" ;;
    4) TARGET_PROFILE="firecracker-microvm-appliance" ;;
    5) TARGET_PROFILE="unikraft-nginx-redis" ;;
    6) TARGET_PROFILE="osv-cloud-runtime" ;;
    7) TARGET_PROFILE="linux-desktop-sway-wayland" ;;
    8) TARGET_PROFILE="linux-desktop-hyprland" ;;
    9) TARGET_PROFILE="linux-desktop-kde-plasma" ;;
    10) TARGET_PROFILE="linux-desktop-xfce-x11" ;;
    11) TARGET_PROFILE="freebsd-desktop-xfce" ;;
    *) TARGET_PROFILE="linux-standard-server-glibc" ;;
  esac
  profile_path="${LIBSCRIPT_ROOT_DIR}/profiles/${TARGET_PROFILE}.json"
  CHOSEN_CONFIG=$(cat "$profile_path")
fi

# Mode 3: Export or display configuration
if [ -n "$EXPORT_FILE" ]; then
  export_dir="${EXPORT_FILE%/*}"
  [ -z "$export_dir" ] || [ -d "$export_dir" ] || mkdir -p "$export_dir"
  printf '%s\n' "$CHOSEN_CONFIG" > "$EXPORT_FILE"
  printf '[INFO] Exported configuration (%s) to: %s\n' "$TARGET_PROFILE" "$EXPORT_FILE"
else
  printf '%s\n' "$CHOSEN_CONFIG"
fi

exit 0
