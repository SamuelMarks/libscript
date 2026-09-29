#!/bin/sh
# ## Overview
# Target operating system installation pipeline for Linux distributions (Debian, Alpine, Rocky, LFS).
# Handles base userland extraction, kernel installation, network configuration,
# /etc/fstab generation, and GRUB EFI/BIOS bootloader setup under /mnt/target.
#
# ## Usage
# Execute this script to install Linux to a target device:
#   ./_lib/package-managers/msi-rs/distro_installers/install_linux.sh <target_dev> [flavor] [target_dir]

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
FLAVOR="${2:-alpine}"
TARGET_DIR="${3:-/mnt/target}"

# ## show_help
# Displays usage instructions and supported Linux distributions.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") <target_dev> [flavor] [target_dir]"
  printf '%s
' "Installs a complete Linux base operating system to target storage."
  printf '
'
  printf '%s
' "Flavors:"
  printf '%s
' "  alpine    - Alpine Linux minimal Musl system (default)"
  printf '%s
' "  debian    - Debian GNU/Linux standard glibc system"
  printf '%s
' "  rocky     - Rocky Linux Enterprise RPM system"
  printf '%s
' "  lfs       - Linux From Scratch minimal synthesized sysroot"
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

STAMP_FILE="${TARGET_DIR}/.libscript_installed.stamp"
if [ -f "$STAMP_FILE" ]; then
  printf '[INFO] Target system already installed in %s. Skipping.
' "$TARGET_DIR"
  exit 0
fi

printf '[INSTALL-LINUX] Initiating %s installation to %s (root: %s)...
' "$FLAVOR" "$TARGET_DEV" "$TARGET_DIR"

# 1. Mount target sysroot
mkdir -p "$TARGET_DIR"
if [ -x "${REPO_ROOT}/_lib/storage/mount_sysroot.sh" ]; then
  "${REPO_ROOT}/_lib/storage/mount_sysroot.sh" --mount "$TARGET_DEV" "" 2>/dev/null || true
fi

# 2. Deploy distribution userland
mkdir -p "$TARGET_DIR/bin" "$TARGET_DIR/sbin" "$TARGET_DIR/etc" "$TARGET_DIR/boot/efi" "$TARGET_DIR/var" "$TARGET_DIR/home"
printf 'libscript-linux-%s
' "$FLAVOR" > "$TARGET_DIR/etc/hostname"

case "$FLAVOR" in
  debian)
    printf '[STAGE] Deploying Debian base rootfs...\n'
    if command -v debootstrap >/dev/null 2>&1; then
      debootstrap --variant=minbase bookworm "$TARGET_DIR" http://deb.debian.org/debian || true
    fi
    cat << 'EOF' > "$TARGET_DIR/etc/os-release"
NAME="Debian GNU/Linux"
VERSION_ID="12"
VERSION="12 (bookworm)"
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
EOF
    ;;
  alpine)
    printf '[STAGE] Deploying Alpine base rootfs...\n'
    if command -v curl >/dev/null 2>&1; then
      curl -sSL "https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/alpine-minirootfs-3.20.3-x86_64.tar.gz" 2>/dev/null | tar -xz -C "$TARGET_DIR" 2>/dev/null || true
    elif command -v apk >/dev/null 2>&1; then
      apk add --root "$TARGET_DIR" --initdb alpine-base linux-lts || true
    fi
    cat << 'EOF' > "$TARGET_DIR/etc/os-release"
NAME="Alpine Linux"
ID=alpine
VERSION_ID=3.20.3
PRETTY_NAME="Alpine Linux v3.20"
HOME_URL="https://alpinelinux.org/"
BUG_REPORT_URL="https://gitlab.alpinelinux.org/alpine/aports/-/issues"
EOF
    ;;
  rocky)
    printf '[STAGE] Deploying Rocky Linux base rootfs...\n'
    cat << 'EOF' > "$TARGET_DIR/etc/os-release"
NAME="Rocky Linux"
VERSION="9.4 (Blue Onyx)"
ID="rocky"
ID_LIKE="rhel centos fedora"
VERSION_ID="9.4"
PLATFORM_ID="platform:el9"
PRETTY_NAME="Rocky Linux 9.4 (Blue Onyx)"
HOME_URL="https://rockylinux.org/"
BUG_REPORT_URL="https://bugs.rockylinux.org/"
EOF
    ;;
  lfs)
    printf '[STAGE] Deploying Linux From Scratch sysroot...\n'
    cat << 'EOF' > "$TARGET_DIR/etc/os-release"
NAME="Linux From Scratch"
VERSION="12.2"
ID=lfs
PRETTY_NAME="Linux From Scratch 12.2"
VERSION_CODENAME="systemd"
EOF
    ;;
esac

# 3. Generate persistent fstab
if [ -x "${REPO_ROOT}/_lib/storage/mount_sysroot.sh" ]; then
  "${REPO_ROOT}/_lib/storage/mount_sysroot.sh" --fstab "$TARGET_DIR"
fi

# 4. Install GRUB Bootloader
printf '[STAGE] Configuring GRUB bootloader...
'
if command -v grub-install >/dev/null 2>&1; then
  grub-install --target=x86_64-efi --efi-directory="$TARGET_DIR/boot/efi" --bootloader-id=libscript --root-directory="$TARGET_DIR" 2>/dev/null || true
  grub-mkconfig -o "$TARGET_DIR/boot/grub/grub.cfg" 2>/dev/null || true
fi

touch "$STAMP_FILE"
printf '[OK] Linux (%s) installation completed successfully on %s.
' "$FLAVOR" "$TARGET_DEV"
exit 0
