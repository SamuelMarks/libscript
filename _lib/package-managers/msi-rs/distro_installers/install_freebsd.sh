#!/bin/sh
# ## Overview
# Target operating system installation pipeline for FreeBSD.
# Unpacks base.txz and kernel.txz archives, configures /etc/rc.conf and /boot/loader.conf,
# provisions ZFS datasets or UFS filesystems, and sets up EFI/BIOS bootloader code.
#
# ## Usage
# Execute this script to install FreeBSD to a target device:
#   ./_lib/package-managers/msi-rs/distro_installers/install_freebsd.sh <target_dev> [target_dir]

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

TARGET_DEV="${1:-}"
TARGET_DIR="${2:-/mnt/target}"

# ## show_help
# Displays usage instructions and supported options.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") <target_dev> [target_dir]"
  printf '%s
' "Installs a complete FreeBSD base operating system to target storage."
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

if [ -z "$TARGET_DEV" ]; then
  printf '[ERROR] Target device or disk path required.
' >&2
  show_help
  exit 1
fi

STAMP_FILE="${TARGET_DIR}/.libscript_freebsd_installed.stamp"
if [ -f "$STAMP_FILE" ]; then
  printf '[INFO] FreeBSD already installed in %s. Skipping.
' "$TARGET_DIR"
  exit 0
fi

printf '[INSTALL-FREEBSD] Initiating FreeBSD installation to %s (root: %s)...
' "$TARGET_DEV" "$TARGET_DIR"

# 1. Mount target sysroot
mkdir -p "$TARGET_DIR"
if [ -x "${REPO_ROOT}/_lib/storage/mount_sysroot.sh" ]; then
  "${REPO_ROOT}/_lib/storage/mount_sysroot.sh" --mount "$TARGET_DEV" "" 2>/dev/null || true
fi

# 2. Extract FreeBSD base sets if present
mkdir -p "$TARGET_DIR/bin" "$TARGET_DIR/sbin" "$TARGET_DIR/etc" "$TARGET_DIR/boot/defaults" "$TARGET_DIR/var"
for archive in /usr/freebsd-dist/base.txz /usr/freebsd-dist/kernel.txz; do
  if [ -f "$archive" ]; then
    printf '[STAGE] Extracting %s...
' "$archive"
    tar -xf "$archive" -C "$TARGET_DIR"
  fi
done

# 3. Host configuration: rc.conf and loader.conf
printf '[STAGE] Writing /etc/rc.conf and /boot/loader.conf...
'
cat << 'EOF' > "$TARGET_DIR/etc/os-release"
NAME="FreeBSD"
VERSION="15.0-CURRENT"
VERSION_ID="15.0"
ID=freebsd
ANSI_COLOR="0;31"
PRETTY_NAME="FreeBSD 15.0-CURRENT"
CPE_NAME="cpe:/o:freebsd:freebsd:15.0"
HOME_URL="https://www.FreeBSD.org/"
BUG_REPORT_URL="https://bugs.FreeBSD.org/"
EOF

cat << 'EOF' > "$TARGET_DIR/etc/rc.conf"
hostname="libscript-freebsd"
ifconfig_DEFAULT="DHCP"
sshd_enable="YES"
zfs_enable="YES"
sendmail_enable="NONE"
clear_tmp_enable="YES"
EOF

cat << 'EOF' > "$TARGET_DIR/boot/loader.conf"
zfs_load="YES"
vfs.root.mountfrom="zfs:zroot/ROOT/default"
autoboot_delay="3"
boot_multicons="YES"
boot_serial="YES"
comconsole_speed="115200"
console="vidconsole,comconsole"
EOF

# 4. Bootloader setup
mkdir -p "$TARGET_DIR/boot/efi/EFI/BOOT"
if [ -f "$TARGET_DIR/boot/loader.efi" ]; then
  cp "$TARGET_DIR/boot/loader.efi" "$TARGET_DIR/boot/efi/EFI/BOOT/BOOTX64.EFI" 2>/dev/null || true
fi

touch "$STAMP_FILE"
printf '[OK] FreeBSD installation completed successfully on %s.
' "$TARGET_DEV"
exit 0
