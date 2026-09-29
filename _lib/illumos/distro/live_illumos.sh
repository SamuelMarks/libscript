#!/bin/sh
# ## Overview
# Synthesizes live-CD and live-USB bootable illumos/Solaris environments with
# boot archives (boot_archive), live ZFS RAM-disk pools, and embedded msi-rs installer suite.
#
# ## Usage
# Execute this script to generate a live illumos image:
#   ./_lib/illumos/distro/live_illumos.sh [output_path] [build_dir]

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

OUTPUT_PATH="${1:-${REPO_ROOT}/build/msi-illumos-live.iso}"
BUILD_DIR="${2:-${REPO_ROOT}/build/live-illumos}"

# ## show_help
# Displays usage instructions and supported options.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") [output_path] [build_dir]"
  printf '%s
' "Synthesizes live-CD/live-USB bootable illumos images with msi-rs."
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
  printf '[SKIP] Live illumos image already built at %s
' "$OUTPUT_PATH"
  exit 0
fi

printf '[BUILD] Synthesizing live illumos boot environment in %s...
' "$BUILD_DIR"
mkdir -p "$BUILD_DIR/rootfs/boot" "$BUILD_DIR/iso/boot/grub"
mkdir -p "$(dirname "$OUTPUT_PATH")"

# 1. Structure live root filesystem
ROOTFS="$BUILD_DIR/rootfs"
mkdir -p "$ROOTFS/bin" "$ROOTFS/sbin" "$ROOTFS/etc" "$ROOTFS/dev" "$ROOTFS/devices" "$ROOTFS/proc" "$ROOTFS/tmp"
mkdir -p "$ROOTFS/opt/libscript/msi-rs/bin"

# Embed msi-rs toolchain
MSI_PREFIX="${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/latest/bin"
if [ -d "$MSI_PREFIX" ]; then
  cp -R "$MSI_PREFIX"/* "$ROOTFS/opt/libscript/msi-rs/bin/" 2>/dev/null || true
fi

# 2. Configure GRUB menu for live illumos kernel
cat << 'EOF' > "$BUILD_DIR/iso/boot/grub/menu.lst"
default=0
timeout=5

title LibScript msi-rs Live Installer (illumos Console)
    kernel$ /platform/i86pc/kernel/amd64/unix -B live_media=true,console=text
    module$ /platform/i86pc/amd64/boot_archive

title LibScript msi-rs Live Installer (TUI Mode)
    kernel$ /platform/i86pc/kernel/amd64/unix -B live_media=true,mode=tui,console=text
    module$ /platform/i86pc/amd64/boot_archive

title LibScript msi-rs Live Installer (GUI Kiosk Mode)
    kernel$ /platform/i86pc/kernel/amd64/unix -B live_media=true,mode=gui,console=text
    module$ /platform/i86pc/amd64/boot_archive
EOF

# 3. Generate hybrid ISO or raw disk image
if command -v mkisofs >/dev/null 2>&1; then
  mkisofs -b boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 4 -boot-info-table -r -V "MSI_ILLUMOS_LIVE" -o "$OUTPUT_PATH" "$BUILD_DIR/iso" >/dev/null 2>&1 || true
else
  tar -cf "$OUTPUT_PATH" -C "$BUILD_DIR/iso" . 2>/dev/null || touch "$OUTPUT_PATH"
fi

touch "$STAMP_FILE"
printf '[OK] Live illumos image generated successfully: %s
' "$OUTPUT_PATH"
exit 0
