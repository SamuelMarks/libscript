#!/bin/sh
# ## Overview
# Configures display server subsystems (Wayland, X11, or none/headless) and
# kernel graphics drivers (drm-kmod, scfb) inside FreeBSD target sysroot.
#
# ## Usage
# Configure display subsystem:
#   _lib/freebsd/distro/display.sh [sysroot_path] [protocol] [driver]

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

SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${REPO_ROOT}/build/freebsd-sysroot}}"
PROTOCOL="${2:-none}"
DRIVER="${3:-drm-kmod}"

STAMP_DIR="${SYSROOT}/.libscript_stamps"
STAMP_FILE="${STAMP_DIR}/display_${PROTOCOL}.stamp"

mkdir -p "${STAMP_DIR}"
mkdir -p "${SYSROOT}/etc"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     FreeBSD display protocol %s already configured in %s
' "${PROTOCOL}" "${SYSROOT}"
  exit 0
fi

printf '[DISPLAY]  Configuring display protocol: %s (driver: %s)...
' "${PROTOCOL}" "${DRIVER}"

if [ "${PROTOCOL}" = "none" ]; then
  printf '[DISPLAY]  Headless mode active, zero display packages staged.
'
  date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
  mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
  exit 0
fi

# Kernel DRM driver loading in rc.conf
if [ "${DRIVER}" = "drm-kmod" ]; then
  printf 'kld_list="${kld_list:-} /boot/modules/virtio_gpu.ko"
' >> "${SYSROOT}/etc/rc.conf"
fi

# devfs rules for graphics and input devices (/dev/dri, /dev/input)
cat << 'EOF' > "${SYSROOT}/etc/devfs.rules"
[system=10]
add path 'dri/*' mode 0666 group video
add path 'drm/*' mode 0666 group video
add path 'input/*' mode 0660 group video
EOF
printf 'devfs_system_ruleset="system"
' >> "${SYSROOT}/etc/rc.conf"

if [ "${PROTOCOL}" = "wayland" ]; then
  # Wayland session configuration & seatd daemon
  printf 'seatd_enable="YES"
' >> "${SYSROOT}/etc/rc.conf"
  # Environment profile for XDG_RUNTIME_DIR
  mkdir -p "${SYSROOT}/etc/profile.d"
  cat << 'EOF' > "${SYSROOT}/etc/profile.d/wayland.sh"
if [ -z "${XDG_RUNTIME_DIR:-}" ]; then
  export XDG_RUNTIME_DIR="/var/run/user/$(id -u)"
  mkdir -p -m 0700 "${XDG_RUNTIME_DIR}"
fi
EOF
elif [ "${PROTOCOL}" = "x11" ]; then
  # X11 configuration directory
  mkdir -p "${SYSROOT}/usr/local/etc/X11/xorg.conf.d"
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       Display protocol %s configured.
' "${PROTOCOL}"
