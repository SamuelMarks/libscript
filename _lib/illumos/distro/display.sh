#!/bin/sh
# ## Overview
# Configures display subsystem (X11 Xorg server, Wayland compositor, or headless serial mode)
# and graphics drivers inside the illumos target sysroot.
#
# ## Usage
# Configure display protocol:
#   _lib/illumos/distro/display.sh [sysroot_path] [protocol] [driver]

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
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${REPO_ROOT}/build/illumos-sysroot}}"
PROTOCOL="${2:-none}"
DRIVER="${3:-none}"

STAMP_DIR="${SYSROOT}/.libscript_stamps"
STAMP_FILE="${STAMP_DIR}/display.stamp"

mkdir -p "${STAMP_DIR}"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     illumos display protocol %s already configured in %s
' "${PROTOCOL}" "${SYSROOT}"
  exit 0
fi

printf '[DISPLAY]  Configuring illumos display protocol %s (driver: %s)...
' "${PROTOCOL}" "${DRIVER}"

case "${PROTOCOL}" in
  none)
    # Headless server: serial console on ttya
    mkdir -p "${SYSROOT}/etc"
    printf 'DISPLAY_MODE="headless"
' > "${SYSROOT}/etc/display.conf"
    ;;

  x11)
    # X11 Xorg server configuration
    mkdir -p "${SYSROOT}/etc/X11" "${SYSROOT}/etc/X11/xorg.conf.d"
    cat << EOF > "${SYSROOT}/etc/X11/xorg.conf"
# Xorg server configuration on illumos (managed by LibScript)
Section "ServerLayout"
    Identifier     "Default Layout"
    Screen      0  "Screen0" 0 0
EndSection

Section "Device"
    Identifier     "Card0"
    Driver         "${DRIVER:-vesa}"
EndSection

Section "Screen"
    Identifier     "Screen0"
    Device         "Card0"
    Monitor        "Monitor0"
    DefaultDepth    24
    SubSection "Display"
        Viewport    0 0
        Depth       24
        Modes      "1920x1080" "1280x720" "1024x768"
    EndSubSection
EndSection

Section "Monitor"
    Identifier     "Monitor0"
    HorizSync       30.0 - 80.0
    VertRefresh     50.0 - 75.0
EndSection
EOF
    printf 'DISPLAY_MODE="x11"
' > "${SYSROOT}/etc/display.conf"
    ;;

  wayland)
    # Experimental Wayland / Weston configuration
    mkdir -p "${SYSROOT}/etc/xdg/weston"
    cat << 'EOF' > "${SYSROOT}/etc/xdg/weston/weston.ini"
# Weston compositor configuration on illumos
[core]
idle-time=0
require-input=false

[shell]
locking=false
animation=zoom
EOF
    printf 'DISPLAY_MODE="wayland"
' > "${SYSROOT}/etc/display.conf"
    ;;

  *)
    printf '[WARN]     Unknown display protocol: %s, defaulting to headless
' "${PROTOCOL}" >&2
    printf 'DISPLAY_MODE="headless"
' > "${SYSROOT}/etc/display.conf"
    ;;
esac

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"

printf '[OK]       illumos display configuration complete: %s
' "${SYSROOT}"
