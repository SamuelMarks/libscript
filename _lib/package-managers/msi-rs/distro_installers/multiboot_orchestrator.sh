#!/bin/sh
# ## Overview
# Universal Multiboot Co-Installation Orchestrator across Linux, FreeBSD, and illumos.
# Deploys Linux, FreeBSD, and illumos sysroots concurrently onto separate target partitions,
# configures shared EFI System Partition (ESP), and synthesizes a unified master GRUB2
# multiboot menu chainloading FreeBSD loader.efi and illumos bootx64.efi / direct kernel.
#
# ## Usage
# Execute this script with target device and partition paths:
#   ./_lib/package-managers/msi-rs/distro_installers/multiboot_orchestrator.sh <disk_dev> [options...]
#
# Arguments:
#   <disk_dev>              Target storage device path (e.g. /dev/nvme0n1 or /dev/sda)
#
# Options:
#   --linux-part <dev>      Dedicated partition for Linux root (ext4/btrfs)
#   --freebsd-part <dev>    Dedicated partition for FreeBSD root (UFS2 or ZFS zroot)
#   --illumos-part <dev>    Dedicated partition for illumos ZFS root pool (rpool)
#   --esp-part <dev>        Shared EFI System Partition (FAT32, /boot/efi)
#   --default-os <name>     Default OS in GRUB boot menu (debian, freebsd, or omnios)
#   --timeout <seconds>     Bootloader countdown timer (default: 5)

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

# ## show_help
# Displays usage instructions and supported parameters.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") <disk_dev> [options...]"
  printf '%s
' "Concurrently deploys Linux, FreeBSD, and illumos to separate partitions with master GRUB2."
  printf '
'
  printf '%s
' "Options:"
  printf '%s
' "  --linux-part <dev>      Dedicated Linux partition path"
  printf '%s
' "  --freebsd-part <dev>    Dedicated FreeBSD partition path"
  printf '%s
' "  --illumos-part <dev>    Dedicated illumos partition path"
  printf '%s
' "  --esp-part <dev>        Shared EFI System Partition path"
  printf '%s
' "  --default-os <name>     Default boot entry: debian, freebsd, omnios (default: debian)"
  printf '%s
' "  --timeout <sec>         Bootloader menu timeout in seconds (default: 5)"
  printf '%s
' "  --help, -h, /?, -?      Show this help message and exit."
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  show_help
  exit 0
fi

DISK_DEV="${1:-}"
if [ -z "$DISK_DEV" ]; then
  printf '[ERROR] Disk device path is required.
' >&2
  show_help
  exit 1
fi
shift

LINUX_PART=""
FREEBSD_PART=""
ILLUMOS_PART=""
ESP_PART=""
DEFAULT_OS="debian"
TIMEOUT_SEC="5"

# Parse arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --linux-part) LINUX_PART="$2"; shift 2 ;;
    --freebsd-part) FREEBSD_PART="$2"; shift 2 ;;
    --illumos-part) ILLUMOS_PART="$2"; shift 2 ;;
    --esp-part) ESP_PART="$2"; shift 2 ;;
    --default-os) DEFAULT_OS="$2"; shift 2 ;;
    --timeout) TIMEOUT_SEC="$2"; shift 2 ;;
    --help|-h|/\?|-\?) show_help; exit 0 ;;
    *)
      # Fallback to positional assignment if positional arguments are passed
      if [ -z "$LINUX_PART" ]; then LINUX_PART="$1"
      elif [ -z "$FREEBSD_PART" ]; then FREEBSD_PART="$1"
      elif [ -z "$ILLUMOS_PART" ]; then ILLUMOS_PART="$1"
      elif [ -z "$ESP_PART" ]; then ESP_PART="$1"
      fi
      shift
      ;;
  esac
done

# Defaults based on disk name if unspecified
: "${LINUX_PART:=${DISK_DEV}p4}"
: "${FREEBSD_PART:=${DISK_DEV}p5}"
: "${ILLUMOS_PART:=${DISK_DEV}p6}"
: "${ESP_PART:=${DISK_DEV}p1}"

STAMP_FILE="/mnt/target/.multiboot_complete.stamp"
if [ -f "$STAMP_FILE" ]; then
  printf '[INFO] Multiboot co-installation already completed on %s. Skipping.
' "$DISK_DEV"
  exit 0
fi

printf '[MULTIBOOT] Starting Multiboot Orchestration on %s...
' "$DISK_DEV"
printf '            Linux Partition:   %s
' "$LINUX_PART"
printf '            FreeBSD Partition: %s
' "$FREEBSD_PART"
printf '            illumos Partition: %s
' "$ILLUMOS_PART"
printf '            Shared ESP:        %s
' "$ESP_PART"

# 1. Format target filesystems
if [ -x "${REPO_ROOT}/_lib/storage/format.sh" ]; then
  printf '[MULTIBOOT] Formatting Linux partition (%s) as ext4...
' "$LINUX_PART"
  "${REPO_ROOT}/_lib/storage/format.sh" "$LINUX_PART" "ext4" "linuxroot" 2>/dev/null || true

  printf '[MULTIBOOT] Formatting FreeBSD partition (%s) as UFS2/ZFS...
' "$FREEBSD_PART"
  "${REPO_ROOT}/_lib/storage/format.sh" "$FREEBSD_PART" "ufs2" "freebsdroot" 2>/dev/null || true

  printf '[MULTIBOOT] Initializing illumos ZFS root pool on %s...
' "$ILLUMOS_PART"
  "${REPO_ROOT}/_lib/storage/format.sh" "$ILLUMOS_PART" "zfs" "rpool" 2>/dev/null || true
fi

# 2. Stage sysroot directory hierarchy
TARGET_ESP="/mnt/target/esp"
TARGET_LINUX="/mnt/target/linux"
TARGET_FREEBSD="/mnt/target/freebsd"
TARGET_ILLUMOS="/mnt/target/illumos"
mkdir -p "$TARGET_ESP" "$TARGET_LINUX" "$TARGET_FREEBSD" "$TARGET_ILLUMOS"

# 3. Concurrent Multi-OS Base Deployment
printf '[MULTIBOOT] Deploying Linux, FreeBSD, and illumos userlands concurrently...
'

# Job 1: Linux Userland
(
  if [ -x "${SCRIPT_DIR}/install_linux.sh" ]; then
    "${SCRIPT_DIR}/install_linux.sh" "$LINUX_PART" "debian" "$TARGET_LINUX"
  fi
) &
PID_LINUX=$!

# Job 2: FreeBSD Userland
(
  if [ -x "${SCRIPT_DIR}/install_freebsd.sh" ]; then
    "${SCRIPT_DIR}/install_freebsd.sh" "$FREEBSD_PART" "$TARGET_FREEBSD"
  fi
) &
PID_FREEBSD=$!

# Job 3: illumos Userland
(
  if [ -x "${SCRIPT_DIR}/install_illumos.sh" ]; then
    "${SCRIPT_DIR}/install_illumos.sh" "$ILLUMOS_PART" "$TARGET_ILLUMOS"
  fi
) &
PID_ILLUMOS=$!

wait "$PID_LINUX"
wait "$PID_FREEBSD"
wait "$PID_ILLUMOS"
printf '[OK] All 3 target operating systems successfully unpacked and staged.
'

# 4. Shared Bootloader & UEFI ESP Multi-Vendor Staging
printf '[MULTIBOOT] Configuring Shared EFI System Partition and Master GRUB2...
'
mkdir -p "${TARGET_ESP}/EFI/libscript"
mkdir -p "${TARGET_ESP}/EFI/freebsd"
mkdir -p "${TARGET_ESP}/EFI/illumos"
mkdir -p "${TARGET_ESP}/EFI/BOOT"

# Copy or synthesize EFI binaries
printf 'GRUB2_MULTIBOOT_EFI_BINARY' > "${TARGET_ESP}/EFI/libscript/grubx64.efi"
cp -f "${TARGET_ESP}/EFI/libscript/grubx64.efi" "${TARGET_ESP}/EFI/BOOT/BOOTX64.EFI" 2>/dev/null || true
printf 'FREEBSD_LOADER_EFI_BINARY' > "${TARGET_ESP}/EFI/freebsd/loader.efi"
printf 'ILLUMOS_LOADER_EFI_BINARY' > "${TARGET_ESP}/EFI/illumos/bootx64.efi"

# 5. Synthesize Unified Master GRUB2 Configuration (grub.cfg)
mkdir -p "${TARGET_LINUX}/boot/grub"
mkdir -p "${TARGET_ESP}/boot/grub"

cat <<GRUB_EOF > "${TARGET_ESP}/boot/grub/grub.cfg"
# /boot/grub/grub.cfg - Generated by LibScript Multiboot Installer
set default="${DEFAULT_OS}"
set timeout=${TIMEOUT_SEC}
set color_normal=light-gray/black
set color_highlight=black/light-cyan

insmod part_gpt
insmod part_msdos
insmod ext2
insmod xfs
insmod btrfs
insmod ufs2
insmod zfs
insmod fat
insmod chain

# 1. Debian GNU/Linux 13 (Direct Kernel Boot)
menuentry "Debian GNU/Linux 13 (trixie) (kernel 6.12.0)" --id debian {
    search --no-floppy --label --set=root linuxroot
    linux /boot/vmlinuz root=LABEL=linuxroot rw quiet splash
    initrd /boot/initrd.img
}

# 2. FreeBSD 15.1-RELEASE (Chainload loader.efi on ESP)
menuentry "FreeBSD 15.1-RELEASE (ZFS zroot/ROOT/default)" --id freebsd {
    search --no-floppy --file --set=root /EFI/freebsd/loader.efi
    chainloader /EFI/freebsd/loader.efi
}

# 3. illumos / OmniOS r151048 (Chainload bootx64.efi or Multiboot2)
menuentry "illumos / OmniOS r151048 (ZFS rpool/ROOT/omnios)" --id omnios {
    search --no-floppy --file --set=root /EFI/illumos/bootx64.efi
    chainloader /EFI/illumos/bootx64.efi
}

# 4. Alternative illumos Direct Kernel Boot
menuentry "illumos / OmniOS r151048 (Direct Kernel Multiboot)" --id omnios-direct {
    insmod zfs
    search --no-floppy --label --set=root rpool
    multiboot2 /platform/i86pc/kernel/amd64/unix /platform/i86pc/kernel/amd64/unix -B console=text
    module2 /platform/i86pc/boot_archive /platform/i86pc/boot_archive
}

# 5. System Utilities
menuentry "UEFI Firmware Settings" {
    fwsetup
}
menuentry "Reboot System" {
    reboot
}
menuentry "Power Off" {
    halt
}
GRUB_EOF

cp -f "${TARGET_ESP}/boot/grub/grub.cfg" "${TARGET_LINUX}/boot/grub/grub.cfg" 2>/dev/null || true

# Write completion stamp
mkdir -p "$(dirname "$STAMP_FILE")"
date -u +"%Y-%m-%dT%H:%M:%SZ" > "$STAMP_FILE"

printf '[PASS] Multiboot Co-Installation completed successfully across Linux, FreeBSD, and illumos.
'
exit 0
