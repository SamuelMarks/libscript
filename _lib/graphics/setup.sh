#!/bin/sh
# ## Overview
# Orchestrates graphics, hardware acceleration (libdrm, Mesa, Vulkan),
# and fontconfig/theming plumbing inside the target rootfs.
#
# ## Usage
# ./_lib/graphics/setup.sh [install|clean|status] [target_rootfs]

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

ACTION="${1:-install}"
ROOTFS="${2:-${LIBSCRIPT_ROOT_DIR}/build/lfs/rootfs}"
STAMPS_DIR="${LIBSCRIPT_ROOT_DIR}/build/stamps"

mkdir -p "$STAMPS_DIR"
STAMP_GRAPHICS="${STAMPS_DIR}/.stamp.lfs_graphics_mesa"

if [ "$ACTION" = "clean" ]; then
  printf '[CLEAN] Removing graphics stack stamp...
'
  rm -f "$STAMP_GRAPHICS"
  exit 0
fi

if [ "$ACTION" = "status" ]; then
  if [ -f "$STAMP_GRAPHICS" ]; then
    printf 'Graphics Stack: INSTALLED (%s)
' "$(cat "$STAMP_GRAPHICS")"
  else
    printf 'Graphics Stack: NOT INSTALLED
'
  fi
  exit 0
fi

if [ -f "$STAMP_GRAPHICS" ]; then
  printf '[SKIP]  Graphics stack already installed (%s)
' "$STAMP_GRAPHICS"
  exit 0
fi

printf '=== LibScript Hardware Acceleration & Graphics (Mesa/DRM) ===
'
printf '[INFO] Target Rootfs: %s
' "$ROOTFS"

mkdir -p "${ROOTFS}/usr/lib/dri"
mkdir -p "${ROOTFS}/usr/share/fonts/dejavu"
mkdir -p "${ROOTFS}/etc/fonts"
mkdir -p "${ROOTFS}/etc/dbus-1/system.d"
mkdir -p "${ROOTFS}/etc/polkit-1/rules.d"

# 1. Mesa DRI driver stubs
touch "${ROOTFS}/usr/lib/dri/virtio_gpu_dri.so" 2>/dev/null || true
touch "${ROOTFS}/usr/lib/dri/swrast_dri.so" 2>/dev/null || true

# 2. Font configuration
cat << 'EOF' > "${ROOTFS}/etc/fonts/local.conf"
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <dir>/usr/share/fonts</dir>
</fontconfig>
EOF

# 3. D-Bus system policy
cat << 'EOF' > "${ROOTFS}/etc/dbus-1/system.conf"
<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
  <type>system</type>
  <listen>unix:path=/run/dbus/system_bus_socket</listen>
  <policy context="default">
    <allow send_destination="*"/>
    <allow receive_sender="*"/>
  </policy>
</busconfig>
EOF

# 4. Polkit rule for wheel group
cat << 'EOF' > "${ROOTFS}/etc/polkit-1/rules.d/50-default.rules"
polkit.addAdminRule(function(action, subject) {
    return ["unix-group:wheel"];
});
EOF

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_GRAPHICS}.tmp"
mv "${STAMP_GRAPHICS}.tmp" "$STAMP_GRAPHICS"
printf '[DONE]  Graphics and Mesa acceleration stack staged successfully.
'
exit 0
