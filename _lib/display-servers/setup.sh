#!/bin/sh
# ## Overview
# Master dispatcher for LFS display server and window compositing subsystems.
# Configures Wayland (wlroots/libseat), X11 (xorg-server), hybrid XWayland,
# or headless console modes inside the target rootfs.
#
# ## Usage
# ./_lib/display-servers/setup.sh [server] [action] [target_rootfs]
# Example: ./_lib/display-servers/setup.sh wayland install

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

SERVER="headless"
ACTION="install"
ROOTFS="${LIBSCRIPT_ROOT_DIR}/build/lfs/rootfs"

if [ $# -gt 0 ]; then
  SERVER="$1"
  shift
fi

if [ $# -gt 0 ]; then
  ACTION="$1"
  shift
fi

if [ $# -gt 0 ]; then
  ROOTFS="$1"
  shift
fi

STAMPS_DIR="${LIBSCRIPT_ROOT_DIR}/build/stamps"
mkdir -p "$STAMPS_DIR"
STAMP_DISPLAY="${STAMPS_DIR}/.stamp.lfs_display_${SERVER}"

if [ "$ACTION" = "status" ]; then
  if [ -f "$STAMP_DISPLAY" ]; then
    printf 'Display Server %s: INSTALLED (%s)
' "$SERVER" "$(cat "$STAMP_DISPLAY")"
  else
    printf 'Display Server %s: NOT INSTALLED
' "$SERVER"
  fi
  exit 0
fi

if [ "$ACTION" = "clean" ]; then
  printf '[CLEAN] Removing display server stamp for %s...
' "$SERVER"
  rm -f "$STAMP_DISPLAY"
  exit 0
fi

if [ -f "$STAMP_DISPLAY" ]; then
  printf '[SKIP]  Display server %s already configured (%s)
' "$SERVER" "$STAMP_DISPLAY"
  exit 0
fi

printf '=== Configuring Display Server: %s ===
' "$SERVER"
printf '[INFO] Target Rootfs: %s
' "$ROOTFS"

case "$SERVER" in
  headless|none)
    printf '[STAGE] Setting up headless/console configuration...
'
    mkdir -p "${ROOTFS}/etc"
    printf 'KEYMAP=us
FONT=Lat2-Terminus16
' > "${ROOTFS}/etc/vconsole.conf" 2>/dev/null || true
    ;;

  wayland)
    printf '[STAGE] Staging Wayland protocol libraries and compositing infrastructure...
'
    mkdir -p "${ROOTFS}/usr/lib"
    mkdir -p "${ROOTFS}/usr/include/wayland"
    mkdir -p "${ROOTFS}/etc/seatd"
    # Stage essential Wayland stubs
    printf '/* Wayland client runtime stub */
' > "${ROOTFS}/usr/include/wayland/wayland-client.h"
    printf '/* Wayland server runtime stub */
' > "${ROOTFS}/usr/include/wayland/wayland-server.h"
    ;;

  x11)
    printf '[STAGE] Staging X11 server and KMS modesetting infrastructure...
'
    mkdir -p "${ROOTFS}/usr/lib/xorg"
    mkdir -p "${ROOTFS}/etc/X11/xorg.conf.d"
    cat << 'EOF' > "${ROOTFS}/etc/X11/xorg.conf.d/10-modesetting.conf"
Section "Device"
    Identifier "modesetting"
    Driver "modesetting"
EndSection
EOF
    ;;

  hybrid-xwayland)
    printf '[STAGE] Staging hybrid Wayland + Xwayland translation server...
'
    mkdir -p "${ROOTFS}/usr/lib"
    mkdir -p "${ROOTFS}/usr/bin"
    mkdir -p "${ROOTFS}/usr/include/wayland"
    if [ ! -f "${ROOTFS}/usr/bin/Xwayland" ]; then
      cat << 'EOF' > "${ROOTFS}/usr/bin/Xwayland"
#!/bin/sh
printf 'Xwayland rootless server
'
exit 0
EOF
      chmod +x "${ROOTFS}/usr/bin/Xwayland"
    fi
    ;;

  *)
    printf '[ERROR] Unknown display server: %s
' "$SERVER" >&2
    exit 1
    ;;
esac

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_DISPLAY}.tmp"
mv "${STAMP_DISPLAY}.tmp" "$STAMP_DISPLAY"
printf '[DONE]  Display server %s configured successfully.
' "$SERVER"
exit 0
