#!/bin/sh
# ## Overview
# Validates declarative Linux From Scratch (LFS) profile specifications against
# os-config.schema.json, checking modular init, display, desktop, and bootloader
# combinations and resolving subsystem dependencies.
#
# ## Usage
# ./cli/commands/config/validate_lfs_profile.sh <path_to_profile.json>

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

SCHEMA_FILE="${LIBSCRIPT_ROOT_DIR}/os-config.schema.json"

if [ $# -lt 1 ]; then
  printf 'Usage: %s <profile.json>
' "$0" >&2
  exit 1
fi

PROFILE_FILE="$1"
if [ ! -f "$PROFILE_FILE" ]; then
  # Try relative to profiles/
  if [ -f "${LIBSCRIPT_ROOT_DIR}/profiles/${PROFILE_FILE}" ]; then
    PROFILE_FILE="${LIBSCRIPT_ROOT_DIR}/profiles/${PROFILE_FILE}"
  elif [ -f "${LIBSCRIPT_ROOT_DIR}/profiles/${PROFILE_FILE}.json" ]; then
    PROFILE_FILE="${LIBSCRIPT_ROOT_DIR}/profiles/${PROFILE_FILE}.json"
  else
    printf '[ERROR] Profile not found: %s
' "$1" >&2
    exit 1
  fi
fi

printf '=== LibScript LFS Profile Validator ===
'
printf '[INFO] Validating profile: %s
' "$PROFILE_FILE"

# Top-level required keys check
if command -v jq >/dev/null 2>&1; then
  # Check top-level required fields per schema
  missing_fields=$(jq -r --slurpfile schema "$SCHEMA_FILE" '
    $schema[0].required - keys | .[]
  ' "$PROFILE_FILE" 2>/dev/null || true)
  if [ -n "$missing_fields" ]; then
    printf '[ERROR] Missing required top-level schema fields: %s
' "$missing_fields" >&2
    exit 1
  fi

  INIT_PROVIDER=$(jq -r '.init_system.provider // "none"' "$PROFILE_FILE")
  DISPLAY_SERVER=$(jq -r '.display.server // "headless"' "$PROFILE_FILE")
  COMPOSITOR=$(jq -r '.display.compositor // "none"' "$PROFILE_FILE")
  DESKTOP_SUITE=$(jq -r '.desktop.desktop_suite // "none"' "$PROFILE_FILE")
  GREETER=$(jq -r '.desktop.greeter // "none"' "$PROFILE_FILE")
  BOOTLOADER=$(jq -r '.storage.bootloader // "grub2-efi"' "$PROFILE_FILE")
  TARGET_LIBC=$(jq -r '.target.libc // "glibc"' "$PROFILE_FILE")
else
  # Minimal fallback parser using grep and sed
  INIT_PROVIDER=$(grep -o '"init_system"[^}]*' "$PROFILE_FILE" | grep -o '"provider"[^,}]*' | sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "none")
  DISPLAY_SERVER=$(grep -o '"display"[^}]*' "$PROFILE_FILE" | grep -o '"server"[^,}]*' | sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "headless")
  COMPOSITOR=$(grep -o '"display"[^}]*' "$PROFILE_FILE" | grep -o '"compositor"[^,}]*' | sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "none")
  DESKTOP_SUITE=$(grep -o '"desktop"[^}]*' "$PROFILE_FILE" | grep -o '"desktop_suite"[^,}]*' | sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "none")
  GREETER=$(grep -o '"desktop"[^}]*' "$PROFILE_FILE" | grep -o '"greeter"[^,}]*' | sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "none")
  BOOTLOADER=$(grep -o '"bootloader"[^,}]*' "$PROFILE_FILE" | sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "grub2-efi")
  TARGET_LIBC=$(grep -o '"libc"[^,}]*' "$PROFILE_FILE" | sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "glibc")
fi

printf '[CHECK] Target Libc:       %s
' "$TARGET_LIBC"
printf '[CHECK] Init System:       %s
' "$INIT_PROVIDER"
printf '[CHECK] Display Server:    %s
' "$DISPLAY_SERVER"
printf '[CHECK] Compositor:        %s
' "$COMPOSITOR"
printf '[CHECK] Desktop Suite:     %s
' "$DESKTOP_SUITE"
printf '[CHECK] Greeter:           %s
' "$GREETER"
printf '[CHECK] Bootloader:        %s
' "$BOOTLOADER"

# 1. Validate Init System
case "$INIT_PROVIDER" in
  systemd|openrc|sysvinit|runit|s6|dinit|bsd-init|none)
    printf '[PASS] Init system provider valid: %s
' "$INIT_PROVIDER"
    ;;
  *)
    printf '[ERROR] Unsupported init system provider: %s
' "$INIT_PROVIDER" >&2
    exit 1
    ;;
esac

# 2. Validate Display Server
case "$DISPLAY_SERVER" in
  wayland|x11|hybrid-xwayland|headless|none)
    printf '[PASS] Display server valid: %s
' "$DISPLAY_SERVER"
    ;;
  *)
    printf '[ERROR] Unsupported display server: %s
' "$DISPLAY_SERVER" >&2
    exit 1
    ;;
esac

# 3. Validate Compositor / Window Manager
case "$COMPOSITOR" in
  sway|hyprland|weston|labwc|openbox|none)
    printf '[PASS] Compositor/WM valid: %s
' "$COMPOSITOR"
    ;;
  *)
    printf '[ERROR] Unsupported compositor: %s
' "$COMPOSITOR" >&2
    exit 1
    ;;
esac

# 4. Validate Desktop Suite
case "$DESKTOP_SUITE" in
  gnome|kde-plasma-6|xfce4|lxqt|none)
    printf '[PASS] Desktop suite valid: %s
' "$DESKTOP_SUITE"
    ;;
  *)
    printf '[ERROR] Unsupported desktop suite: %s
' "$DESKTOP_SUITE" >&2
    exit 1
    ;;
esac

# 5. Validate Greeter
case "$GREETER" in
  greetd|sddm|gdm|lightdm|none)
    printf '[PASS] Greeter valid: %s
' "$GREETER"
    ;;
  *)
    printf '[ERROR] Unsupported greeter: %s
' "$GREETER" >&2
    exit 1
    ;;
esac

# 6. Validate Bootloader
case "$BOOTLOADER" in
  grub2-efi|grub2-bios|systemd-boot|limine|freebsd-bootcode|none)
    printf '[PASS] Bootloader valid: %s
' "$BOOTLOADER"
    ;;
  *)
    printf '[ERROR] Unsupported bootloader: %s
' "$BOOTLOADER" >&2
    exit 1
    ;;
esac

# 7. Cross-Subsystem Compatibility Rules
if [ "$COMPOSITOR" = "sway" ] || [ "$COMPOSITOR" = "hyprland" ] || [ "$COMPOSITOR" = "weston" ] || [ "$COMPOSITOR" = "labwc" ]; then
  if [ "$DISPLAY_SERVER" != "wayland" ] && [ "$DISPLAY_SERVER" != "hybrid-xwayland" ]; then
    printf '[ERROR] Compositor %s requires display.server=wayland or hybrid-xwayland
' "$COMPOSITOR" >&2
    exit 1
  fi
fi

if [ "$COMPOSITOR" = "openbox" ]; then
  if [ "$DISPLAY_SERVER" != "x11" ] && [ "$DISPLAY_SERVER" != "hybrid-xwayland" ]; then
    printf '[ERROR] Compositor openbox requires display.server=x11 or hybrid-xwayland
' >&2
    exit 1
  fi
fi

if [ "$BOOTLOADER" = "systemd-boot" ] && [ "$INIT_PROVIDER" != "systemd" ]; then
  printf '[WARN] systemd-boot selected without systemd init provider; ensure systemd-boot standalone binary is packaged.
'
fi

printf '[PASS] All modular axes and compatibility rules satisfied.
'
exit 0
