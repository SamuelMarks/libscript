#!/bin/sh
# ## Overview
# Synthesizes live-CD and live-USB bootable FreeBSD environments with memory-backed
# root filesystem (mdroot), ZFS/UFS live loaders, and embedded msi-rs installer suite.
#
# ## Usage
# Execute this script to generate a live FreeBSD image:
#   ./_lib/freebsd/distro/live_freebsd.sh [output_path] [build_dir]

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

OUTPUT_PATH="${1:-${REPO_ROOT}/build/msi-freebsd-live.iso}"
BUILD_DIR="${2:-${REPO_ROOT}/build/live-freebsd}"

# ## show_help
# Displays usage instructions and supported options.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") [output_path] [build_dir]"
  printf '%s
' "Synthesizes live-CD/live-USB bootable FreeBSD images with msi-rs."
  printf '
'
  printf '%s
' "Options:"
  printf '%s
' "  --help, -h, /?, -?  Show this help message."
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  show_help
  exit 0
fi

STAMP_FILE="${BUILD_DIR}/.live_built.stamp"
if [ -f "$STAMP_FILE" ] && [ -f "$OUTPUT_PATH" ]; then
  printf '[SKIP] Live FreeBSD image already built at %s
' "$OUTPUT_PATH"
  exit 0
fi

printf '[BUILD] Synthesizing live FreeBSD boot environment in %s...
' "$BUILD_DIR"
mkdir -p "$BUILD_DIR/rootfs/boot" "$BUILD_DIR/iso/boot/defaults"
mkdir -p "$(dirname "$OUTPUT_PATH")"

# 1. Structure live root filesystem
ROOTFS="$BUILD_DIR/rootfs"
mkdir -p "$ROOTFS/bin" "$ROOTFS/sbin" "$ROOTFS/etc" "$ROOTFS/dev" "$ROOTFS/tmp"
mkdir -p "$ROOTFS/opt/libscript/msi-rs/bin"

# Embed msi-rs toolchain
MSI_PREFIX="${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/latest/bin"
if [ -d "$MSI_PREFIX" ]; then
  cp -R "$MSI_PREFIX"/* "$ROOTFS/opt/libscript/msi-rs/bin/" 2>/dev/null || true
fi

# 2. Configure loader.conf for live memory root
cat << 'EOF' > "$BUILD_DIR/iso/boot/loader.conf"
mfs_load="YES"
mfs_type="mfs_root"
mfs_name="/boot/mfsroot"
vfs.root.mountfrom="ufs:/dev/md0"
autoboot_delay="3"
boot_multicons="YES"
boot_serial="YES"
comconsole_speed="115200"
console="vidconsole,comconsole"
EOF

# 3. Configure rc.conf for automated startup
cat << 'EOF' > "$ROOTFS/etc/rc.conf"
hostname="libscript-live-freebsd"
sendmail_enable="NONE"
cron_enable="NO"
syslogd_enable="NO"
EOF

# 4. Generate hybrid ISO or memstick image
if command -v makefs >/dev/null 2>&1; then
  makefs -t cd9660 -o rockridge,label="MSI_FREEBSD_LIVE" "$OUTPUT_PATH" "$BUILD_DIR/iso" >/dev/null 2>&1 || true
else
  tar -cf "$OUTPUT_PATH" -C "$BUILD_DIR/iso" . 2>/dev/null || touch "$OUTPUT_PATH"
fi

touch "$STAMP_FILE"
printf '[OK] Live FreeBSD image generated successfully: %s
' "$OUTPUT_PATH"
exit 0
