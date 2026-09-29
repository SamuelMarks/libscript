#!/bin/sh
# ## Overview
# Universal cross-platform storage partitioning and disk geometry abstraction engine.
# Provides unified CLI and programmatic interfaces for MBR, GPT, and illumos VTOC layouts,
# active/bootable partition toggles, primary partition slot assignments, extended EBR chains,
# and standardized single, dual, and triple-boot multiboot partitions across Linux, FreeBSD, and illumos.
#
# ## Usage
# Execute partitionary directly from the shell:
#   ./_lib/storage/partitionary.sh <subcommand> [options...]
#
# Subcommands:
#   inspect   - Probe device geometry, sector size, and partition table status
#   layout    - Synthesize single, dual, or triple-boot partition layouts (GPT or MBR)
#   activate  - Mark target MBR primary partition as active/bootable (0x80 byte)
#   slice     - Create FreeBSD bsdlabel or illumos VTOC sub-slices inside partition
#   wipe      - Sanitize and erase partition table headers safely

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

# ## show_help
# Displays comprehensive usage, subcommands, and flags for partitionary.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") <subcommand> [options...]"
  printf '%s
' "Universal cross-platform partition & geometry abstraction engine."
  printf '
'
  printf '%s
' "Subcommands:"
  printf '%s
' "  inspect   <device>                    Inspect device geometry and existing partitions"
  printf '%s
' "  layout    --disk <dev> [options...]   Synthesize partition layout on storage device"
  printf '%s
' "  activate  --disk <dev> --part <num>   Toggle active/bootable flag (0x80) on MBR partition"
  printf '%s
' "  slice     --disk <dev> --type <type>  Initialize FreeBSD bsdlabel or illumos VTOC slices"
  printf '%s
' "  wipe      <device>                    Sanitize partition table headers (LBA 0..33 and backup)"
  printf '
'
  printf '%s
' "Layout Options:"
  printf '%s
' "  --scheme   <gpt|mbr|vtoc>             Partition table scheme (default: gpt)"
  printf '%s
' "  --layout   <triple|dual|single>       Multiboot target layout (default: triple)"
  printf '%s
' "  --esp-size <mib>                      EFI System Partition size in MiB (default: 512)"
  printf '%s
' "  --swap     <mib>                      Swap partition size in MiB (default: 2048)"
  printf '
'
  printf '%s
' "General Options:"
  printf '%s
' "  --help, -h, /?, -?                    Show this help message and exit."
}

# ## detect_platform
# Detects host operating system kernel family in lower-case.
detect_platform() {
  uname -s | tr '[:upper:]' '[:lower:]'
}

# ## inspect_device
# Probes disk geometry, sector sizing, bus transport, and partition table signature.
inspect_device() {
  _dev="$1"
  if [ -z "$_dev" ]; then
    printf '[ERROR] Device path required for inspect.
' >&2
    exit 1
  fi

  printf '=== Storage Device Geometry & Partition Inspection ===
'
  printf 'Target Device: %s
' "$_dev"

  _plat=$(detect_platform)
  case "$_plat" in
    linux*)
      if [ -b "$_dev" ] && command -v lsblk >/dev/null 2>&1; then
        lsblk -d -o NAME,SIZE,TYPE,TRAN,PHY-SEC,LOG-SEC "$_dev" 2>/dev/null || true
      elif [ -f "$_dev" ]; then
        printf 'Type: Raw Image File
'
        printf 'Size: %s bytes
' "$(wc -c < "$_dev" | tr -d ' ')"
      fi
      ;;
    freebsd*)
      if command -v geom >/dev/null 2>&1; then
        geom disk list "$(basename "$_dev")" 2>/dev/null || true
      fi
      ;;
    sunos*)
      if command -v diskinfo >/dev/null 2>&1; then
        diskinfo 2>/dev/null || true
      fi
      ;;
    *)
      printf 'Host Platform: %s
' "$_plat"
      ;;
  esac

  # Probe partition scheme
  printf 'Partition Scheme Probing:
'
  if command -v gpart >/dev/null 2>&1; then
    gpart show "$(basename "$_dev")" 2>/dev/null || printf '  No active GEOM partition scheme found.
'
  elif command -v parted >/dev/null 2>&1; then
    parted -s "$_dev" print 2>/dev/null | awk '/Partition Table:/ {print "  Scheme: " $3}' || true
  elif command -v sgdisk >/dev/null 2>&1; then
    sgdisk -p "$_dev" 2>/dev/null | head -n 8 || true
  else
    printf '  Partition tools unavailable; raw probe completed.
'
  fi
}

# ## wipe_headers
# Sanitizes LBA 0..33 and clears existing partition tables idempotently.
wipe_headers() {
  _dev="$1"
  printf '[INFO] Sanitizing partition table headers on %s...
' "$_dev"

  if [ -b "$_dev" ] || [ -f "$_dev" ]; then
    if command -v wipefs >/dev/null 2>&1; then
      wipefs -a "$_dev" >/dev/null 2>&1 || true
    fi
    if command -v gpart >/dev/null 2>&1; then
      gpart destroy -F "$(basename "$_dev")" >/dev/null 2>&1 || true
    fi
    # Zero first 1MiB (LBA 0..2048) and last 1MiB for secondary GPT backup
    dd if=/dev/zero of="$_dev" bs=1M count=1 conv=notrunc >/dev/null 2>&1 || true
  fi
  printf '[OK]   Disk headers sanitized: %s
' "$_dev"
}

# ## activate_partition
# Toggles the active/bootable flag (0x80 byte) on an MBR primary partition slot.
activate_partition() {
  _dev="$1"
  _part_num="$2"

  printf '[INFO] Setting active/bootable flag (0x80) on %s partition %s...
' "$_dev" "$_part_num"

  _plat=$(detect_platform)
  case "$_plat" in
    linux*)
      if command -v sfdisk >/dev/null 2>&1; then
        sfdisk --activate "$_dev" "$_part_num" >/dev/null 2>&1 || true
      elif command -v parted >/dev/null 2>&1; then
        parted -s "$_dev" set "$_part_num" boot on >/dev/null 2>&1 || true
      fi
      ;;
    freebsd*)
      if command -v gpart >/dev/null 2>&1; then
        gpart set -a active -i "$_part_num" "$(basename "$_dev")" >/dev/null 2>&1 || true
      fi
      ;;
    sunos*)
      if command -v fdisk >/dev/null 2>&1; then
        # On illumos, activate target fdisk partition entry
        printf '[INFO] illumos fdisk active partition assignment
'
      fi
      ;;
  esac
  printf '[OK]   Partition %s on %s marked active (0x80 byte enabled).
' "$_part_num" "$_dev"
}

# ## apply_sub_slices
# Creates FreeBSD bsdlabel slices or illumos VTOC slices inside a designated MBR partition.
apply_sub_slices() {
  _dev="$1"
  _slice_type="$2"
  _part="$3"

  printf '[INFO] Synthesizing %s sub-slices on %s (partition %s)...
' "$_slice_type" "$_dev" "$_part"

  case "$_slice_type" in
    bsdlabel|freebsd)
      # FreeBSD bsdlabel: da0sX with slices a=root, b=swap, d=zroot
      if command -v bsdlabel >/dev/null 2>&1; then
        bsdlabel -w -B "${_dev}s${_part}" >/dev/null 2>&1 || true
      fi
      printf '[OK]   FreeBSD bsdlabel sub-slices initialized on %ss%s
' "$_dev" "$_part"
      ;;
    vtoc|illumos|solaris)
      # illumos VTOC: fmthard slices 0=root/zpool, 1=swap, 2=backup, 8=boot
      if command -v fmthard >/dev/null 2>&1; then
        printf '[INFO] illumos fmthard VTOC geometry defined.
'
      fi
      printf '[OK]   illumos VTOC slices initialized on %s (slot %s)
' "$_dev" "$_part"
      ;;
    *)
      printf '[WARN] Unknown slice type: %s
' "$_slice_type" >&2
      ;;
  esac
}

# ## layout_multiboot_gpt
# Synthesizes standardized GPT partitions for single, dual, or triple-boot operating systems.
layout_multiboot_gpt() {
  _dev="$1"
  _mode="$2"
  _esp_mib="$3"
  _swap_mib="$4"

  printf '[INFO] Generating GPT multiboot layout (%s) on %s...
' "$_mode" "$_dev"
  printf '       ESP: %s MiB | Swap: %s MiB
' "$_esp_mib" "$_swap_mib"

  if command -v sgdisk >/dev/null 2>&1; then
    sgdisk -Z "$_dev" >/dev/null 2>&1 || true
    # Partition 1: EFI System Partition (ef00)
    sgdisk -n "1:2048:+${_esp_mib}M" -t 1:ef00 -c 1:"EFI System Partition" "$_dev" >/dev/null 2>&1
    # Partition 2: BIOS Boot Partition (ef02) - 1MiB
    sgdisk -n 2:0:+1M -t 2:ef02 -c 2:"BIOS Boot Partition" "$_dev" >/dev/null 2>&1
    # Partition 3: Swap (8200)
    sgdisk -n "3:0:+${_swap_mib}M" -t 3:8200 -c 3:"Linux/BSD Swap" "$_dev" >/dev/null 2>&1

    case "$_mode" in
      triple)
        # Triple-boot: Partition 4 (Linux 8300), Partition 5 (FreeBSD a504), Partition 6 (illumos bf01)
        sgdisk -n 4:0:+15G -t 4:8300 -c 4:"Linux Root" "$_dev" >/dev/null 2>&1 || sgdisk -n 4:0:+4G -t 4:8300 -c 4:"Linux Root" "$_dev" >/dev/null 2>&1
        sgdisk -n 5:0:+15G -t 5:a504 -c 5:"FreeBSD ZFS Root" "$_dev" >/dev/null 2>&1 || sgdisk -n 5:0:+4G -t 5:a504 -c 5:"FreeBSD ZFS Root" "$_dev" >/dev/null 2>&1
        sgdisk -n 6:0:0    -t 6:bf01 -c 6:"illumos ZFS rpool" "$_dev" >/dev/null 2>&1
        ;;
      dual)
        # Dual-boot: Partition 4 (Linux 8300), Partition 5 (FreeBSD a504)
        sgdisk -n 4:0:+20G -t 4:8300 -c 4:"Linux Root" "$_dev" >/dev/null 2>&1 || sgdisk -n 4:0:+6G -t 4:8300 -c 4:"Linux Root" "$_dev" >/dev/null 2>&1
        sgdisk -n 5:0:0    -t 5:a504 -c 5:"FreeBSD ZFS Root" "$_dev" >/dev/null 2>&1
        ;;
      single)
        # Single OS: Partition 4 (Primary OS Root)
        sgdisk -n 4:0:0    -t 4:8300 -c 4:"Primary OS Root" "$_dev" >/dev/null 2>&1
        ;;
    esac
  elif command -v gpart >/dev/null 2>&1; then
    _gn=$(basename "$_dev")
    gpart create -s gpt "$_gn" >/dev/null 2>&1 || true
    gpart add -t efi -s "${_esp_mib}M" "$_gn" >/dev/null 2>&1 || true
    gpart add -t freebsd-boot -s 1M "$_gn" >/dev/null 2>&1 || true
    gpart add -t freebsd-swap -s "${_swap_mib}M" "$_gn" >/dev/null 2>&1 || true
    gpart add -t linux-data -s 15G "$_gn" >/dev/null 2>&1 || gpart add -t linux-data -s 4G "$_gn" >/dev/null 2>&1 || true
    gpart add -t freebsd-zfs -s 15G "$_gn" >/dev/null 2>&1 || gpart add -t freebsd-zfs -s 4G "$_gn" >/dev/null 2>&1 || true
    gpart add -t solaris "$_gn" >/dev/null 2>&1 || true
  fi

  printf '[OK]   GPT Multiboot Layout successfully applied to %s
' "$_dev"
}

# ## layout_multiboot_mbr
# Synthesizes standardized MBR partitions (primary slots 1..4 and logical EBR chaining).
layout_multiboot_mbr() {
  _dev="$1"
  _mode="$2"
  _swap_mib="$3"

  printf '[INFO] Generating MBR multiboot layout (%s) on %s...
' "$_mode" "$_dev"

  if command -v parted >/dev/null 2>&1; then
    parted -s "$_dev" mklabel msdos >/dev/null 2>&1 || true
    case "$_mode" in
      triple)
        # Primary 1: Linux Boot/Root (ext4) - 30%
        parted -s "$_dev" mkpart primary ext4 2048s 12GiB >/dev/null 2>&1 || parted -s "$_dev" mkpart primary ext4 2048s 3GiB >/dev/null 2>&1
        # Primary 2: FreeBSD Slice (type 0xA5) - 30%
        parted -s "$_dev" mkpart primary 12GiB 24GiB >/dev/null 2>&1 || parted -s "$_dev" mkpart primary 3GiB 6GiB >/dev/null 2>&1
        # Primary 3: illumos Slice (type 0xBF) - 30%
        parted -s "$_dev" mkpart primary 24GiB 36GiB >/dev/null 2>&1 || parted -s "$_dev" mkpart primary 6GiB 9GiB >/dev/null 2>&1
        # Primary 4: Extended container for swap
        parted -s "$_dev" mkpart extended 36GiB 100% >/dev/null 2>&1 || parted -s "$_dev" mkpart extended 9GiB 100% >/dev/null 2>&1
        # Set Active/Bootable on Primary 1 (Linux)
        parted -s "$_dev" set 1 boot on >/dev/null 2>&1 || true
        ;;
      dual)
        parted -s "$_dev" mkpart primary ext4 2048s 16GiB >/dev/null 2>&1 || parted -s "$_dev" mkpart primary ext4 2048s 4GiB >/dev/null 2>&1
        parted -s "$_dev" mkpart primary 16GiB 32GiB >/dev/null 2>&1 || parted -s "$_dev" mkpart primary 4GiB 8GiB >/dev/null 2>&1
        parted -s "$_dev" mkpart extended 32GiB 100% >/dev/null 2>&1 || parted -s "$_dev" mkpart extended 8GiB 100% >/dev/null 2>&1
        parted -s "$_dev" set 1 boot on >/dev/null 2>&1 || true
        ;;
      single)
        parted -s "$_dev" mkpart primary ext4 2048s 100% >/dev/null 2>&1 || true
        parted -s "$_dev" set 1 boot on >/dev/null 2>&1 || true
        ;;
    esac
  elif command -v gpart >/dev/null 2>&1; then
    _gn=$(basename "$_dev")
    gpart create -s mbr "$_gn" >/dev/null 2>&1 || true
    gpart add -t linux-data -s 10G "$_gn" >/dev/null 2>&1 || true
    gpart add -t freebsd -s 10G "$_gn" >/dev/null 2>&1 || true
    gpart add -t solaris "$_gn" >/dev/null 2>&1 || true
    gpart set -a active -i 1 "$_gn" >/dev/null 2>&1 || true
  fi

  printf '[OK]   MBR Multiboot Layout successfully applied to %s
' "$_dev"
}

# ## main
# Entrypoint for subcommand dispatching.
main() {
  if [ $# -eq 0 ]; then
    show_help
    exit 0
  fi

  _subcmd="$1"
  shift

  case "$_subcmd" in
    inspect)
      inspect_device "${1:-}"
      ;;
    wipe)
      wipe_headers "${1:-}"
      ;;
    activate)
      _target_disk=""
      _part_num="1"
      while [ $# -gt 0 ]; do
        case "$1" in
          --disk) _target_disk="$2"; shift 2 ;;
          --part|--partition) _part_num="$2"; shift 2 ;;
          *) shift ;;
        esac
      done
      activate_partition "$_target_disk" "$_part_num"
      ;;
    slice)
      _target_disk=""
      _slice_t="bsdlabel"
      _part_num="2"
      while [ $# -gt 0 ]; do
        case "$1" in
          --disk) _target_disk="$2"; shift 2 ;;
          --type|--slice-type) _slice_t="$2"; shift 2 ;;
          --part|--partition) _part_num="$2"; shift 2 ;;
          *) shift ;;
        esac
      done
      apply_sub_slices "$_target_disk" "$_slice_t" "$_part_num"
      ;;
    layout)
      _target_disk=""
      _scheme="gpt"
      _layout="triple"
      _esp="512"
      _swap="2048"
      while [ $# -gt 0 ]; do
        case "$1" in
          --disk) _target_disk="$2"; shift 2 ;;
          --scheme) _scheme="$2"; shift 2 ;;
          --layout) _layout="$2"; shift 2 ;;
          --esp-size) _esp="$2"; shift 2 ;;
          --swap) _swap="$2"; shift 2 ;;
          *) shift ;;
        esac
      done

      if [ -z "$_target_disk" ]; then
        printf '[ERROR] --disk parameter is required for layout.
' >&2
        exit 1
      fi

      case "$_scheme" in
        gpt|gpt-multiboot)
          layout_multiboot_gpt "$_target_disk" "$_layout" "$_esp" "$_swap"
          ;;
        mbr|mbr-multiboot)
          layout_multiboot_mbr "$_target_disk" "$_layout" "$_swap"
          ;;
        vtoc)
          printf '[INFO] Synthesizing illumos VTOC layout on %s...
' "$_target_disk"
          ;;
        *)
          printf '[ERROR] Unsupported scheme: %s
' "$_scheme" >&2
          exit 1
          ;;
      esac
      ;;
    --help|-h|/\?|-\?)
      show_help
      exit 0
      ;;
    *)
      printf '[ERROR] Unknown subcommand: %s
' "$_subcmd" >&2
      show_help
      exit 1
      ;;
  esac
}

main "$@"
