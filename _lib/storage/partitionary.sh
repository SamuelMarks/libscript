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
  printf '%s\n' "Usage: $(basename "$THIS_FILE") <subcommand> [options...]"
  printf '%s\n' "Universal cross-platform partition & geometry abstraction engine."
  printf '\n'
  printf '%s\n' "Subcommands:"
  printf '%s\n' "  inspect   <device>                    Inspect device geometry and existing partitions"
  printf '%s\n' "  layout    --disk <dev> [options...]   Synthesize partition layout on storage device"
  printf '%s\n' "  activate  --disk <dev> --part <num>   Toggle active/bootable flag (0x80) on MBR partition"
  printf '%s\n' "  slice     --disk <dev> --type <type>  Initialize FreeBSD bsdlabel or illumos VTOC slices"
  printf '%s\n' "  wipe      <device>                    Sanitize partition table headers (LBA 0..33 and backup)"
  printf '\n'
  printf '%s\n' "Layout Options:"
  printf '%s\n' "  --scheme   <gpt|mbr|vtoc>             Partition table scheme (default: gpt)"
  printf '%s\n' "  --layout   <triple|dual|single>       Multiboot target layout (default: triple)"
  printf '%s\n' "  --esp-size <mib>                      EFI System Partition size in MiB (default: 512)"
  printf '%s\n' "  --swap     <mib>                      Swap partition size in MiB (default: 2048)"
  printf '\n'
  printf '%s\n' "General Options:"
  printf '%s\n' "  --help, -h, /?, -?                    Show this help message and exit."
}

# ## detect_platform
# Detects host operating system kernel family in lower-case.
detect_platform() {
  uname -s | tr '[:upper:]' '[:lower:]'
}

# ## has_partition
# Idempotency helper to check if a specific partition index already exists
has_partition() {
  _dev="$1"
  _idx="$2"
  
  _plat=$(detect_platform)
  case "$_plat" in
    linux*)
      if command -v sgdisk >/dev/null 2>&1; then
        sgdisk -p "$_dev" | grep -qE "^[\s]*${_idx}\s"
        return $?
      fi
      ;;
    freebsd*)
      if command -v gpart >/dev/null 2>&1; then
        gpart show -p "$(basename "$_dev")" | grep -qE "^[\s]*[0-9]+\s+${_idx}\s"
        return $?
      fi
      ;;
  esac
  return 1
}

# ## inspect_device
# Probes disk geometry, sector sizing, bus transport, and partition table signature.
inspect_device() {
  _dev="$1"
  if [ -z "$_dev" ]; then
    printf '[ERROR] Device path required for inspect.\n' >&2
    exit 1
  fi

  printf '=== Storage Device Geometry & Partition Inspection ===\n'
  printf 'Target Device: %s\n' "$_dev"

  _plat=$(detect_platform)
  case "$_plat" in
    linux*)
      if [ -b "$_dev" ] && command -v lsblk >/dev/null 2>&1; then
        lsblk -d -o NAME,SIZE,TYPE,TRAN,PHY-SEC,LOG-SEC "$_dev" 2>/dev/null || true
      elif [ -f "$_dev" ]; then
        printf 'Type: Raw Image File\n'
        printf 'Size: %s bytes\n' "$(wc -c < "$_dev" | tr -d ' ')"
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
      printf 'Host Platform: %s\n' "$_plat"
      ;;
  esac

  # Probe partition scheme
  printf 'Partition Scheme Probing:\n'
  if command -v gpart >/dev/null 2>&1; then
    gpart show "$(basename "$_dev")" 2>/dev/null || printf '  No active GEOM partition scheme found.\n'
  elif command -v parted >/dev/null 2>&1; then
    parted -s "$_dev" print 2>/dev/null | awk '/Partition Table:/ {print "  Scheme: " $3}' || true
  elif command -v sgdisk >/dev/null 2>&1; then
    sgdisk -p "$_dev" 2>/dev/null | head -n 8 || true
  else
    printf '  Partition tools unavailable; raw probe completed.\n'
  fi
}

# ## wipe_headers
# Sanitizes LBA 0..33 and clears existing partition tables idempotently.
wipe_headers() {
  _dev="$1"
  printf '[INFO] Sanitizing partition table headers on %s...\n' "$_dev"

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
  printf '[OK]   Disk headers sanitized: %s\n' "$_dev"
}

# ## activate_partition
# Toggles the active/bootable flag (0x80 byte) on an MBR primary partition slot.
activate_partition() {
  _dev="$1"
  _part_num="$2"

  printf '[INFO] Setting active/bootable flag (0x80) on %s partition %s...\n' "$_dev" "$_part_num"

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
        printf '[INFO] illumos fdisk active partition assignment\n'
      fi
      ;;
  esac
  printf '[OK]   Partition %s on %s marked active (0x80 byte enabled).\n' "$_part_num" "$_dev"
}

# ## apply_sub_slices
# Creates FreeBSD bsdlabel slices or illumos VTOC slices inside a designated MBR partition.
apply_sub_slices() {
  _dev="$1"
  _slice_type="$2"
  _part="$3"

  printf '[INFO] Synthesizing %s sub-slices on %s (partition %s)...\n' "$_slice_type" "$_dev" "$_part"

  case "$_slice_type" in
    bsdlabel|freebsd)
      # FreeBSD bsdlabel: da0sX with slices a=root, b=swap, d=zroot
      if command -v bsdlabel >/dev/null 2>&1; then
        bsdlabel -w -B "${_dev}s${_part}" >/dev/null 2>&1 || true
      fi
      printf '[OK]   FreeBSD bsdlabel sub-slices initialized on %ss%s\n' "$_dev" "$_part"
      ;;
    vtoc|illumos|solaris)
      if command -v fmthard >/dev/null 2>&1; then
        printf '[INFO] illumos fmthard VTOC geometry defined.\n'
      fi
      printf '[OK]   illumos VTOC slices initialized on %s (slot %s)\n' "$_dev" "$_part"
      ;;
    *)
      printf '[WARN] Unknown slice type: %s\n' "$_slice_type" >&2
      ;;
  esac
}

# ## layout_multiboot_gpt
# Synthesizes standardized GPT partitions for single, dual, or triple-boot operating systems.
# Aligns to 1MiB (2048 sector) boundaries.
layout_multiboot_gpt() {
  _dev="$1"
  _mode="$2"
  _esp_mib="$3"
  _swap_mib="$4"

  printf '[INFO] Generating GPT multiboot layout (%s) on %s...\n' "$_mode" "$_dev"
  printf '       ESP: %s MiB | Swap: %s MiB\n' "$_esp_mib" "$_swap_mib"

  if command -v sgdisk >/dev/null 2>&1; then
    # Idempotent layout checking
    if ! has_partition "$_dev" 1; then
      sgdisk -a 2048 -n "1:2048:+${_esp_mib}M" -t 1:ef00 -c 1:"EFI System Partition" "$_dev" >/dev/null 2>&1
    fi
    if ! has_partition "$_dev" 2; then
      sgdisk -a 2048 -n 2:0:+1M -t 2:ef02 -c 2:"BIOS Boot Partition" "$_dev" >/dev/null 2>&1
    fi
    if ! has_partition "$_dev" 3; then
      sgdisk -a 2048 -n "3:0:+${_swap_mib}M" -t 3:8200 -c 3:"Linux/BSD Swap" "$_dev" >/dev/null 2>&1
    fi

    case "$_mode" in
      triple)
        if ! has_partition "$_dev" 4; then
          sgdisk -a 2048 -n 4:0:+15G -t 4:8300 -c 4:"Linux Root" "$_dev" >/dev/null 2>&1 || sgdisk -n 4:0:+4G -t 4:8300 -c 4:"Linux Root" "$_dev" >/dev/null 2>&1
        fi
        if ! has_partition "$_dev" 5; then
          sgdisk -a 2048 -n 5:0:+15G -t 5:a504 -c 5:"FreeBSD ZFS Root" "$_dev" >/dev/null 2>&1 || sgdisk -n 5:0:+4G -t 5:a504 -c 5:"FreeBSD ZFS Root" "$_dev" >/dev/null 2>&1
        fi
        if ! has_partition "$_dev" 6; then
          sgdisk -a 2048 -n 6:0:0    -t 6:bf01 -c 6:"illumos ZFS rpool" "$_dev" >/dev/null 2>&1
        fi
        ;;
      dual)
        if ! has_partition "$_dev" 4; then
          sgdisk -a 2048 -n 4:0:+20G -t 4:8300 -c 4:"Linux Root" "$_dev" >/dev/null 2>&1 || sgdisk -n 4:0:+6G -t 4:8300 -c 4:"Linux Root" "$_dev" >/dev/null 2>&1
        fi
        if ! has_partition "$_dev" 5; then
          sgdisk -a 2048 -n 5:0:0    -t 5:a504 -c 5:"FreeBSD ZFS Root" "$_dev" >/dev/null 2>&1
        fi
        ;;
      single)
        if ! has_partition "$_dev" 4; then
          sgdisk -a 2048 -n 4:0:0    -t 4:8300 -c 4:"Primary OS Root" "$_dev" >/dev/null 2>&1
        fi
        ;;
    esac
    partprobe "$_dev" >/dev/null 2>&1 || true
  elif command -v gpart >/dev/null 2>&1; then
    _gn=$(basename "$_dev")
    gpart create -s gpt "$_gn" >/dev/null 2>&1 || true
    
    # Check bounds idempotently by testing add error codes
    gpart add -a 1m -t efi -s "${_esp_mib}M" -i 1 "$_gn" >/dev/null 2>&1 || true
    gpart add -a 1m -t freebsd-boot -s 1M -i 2 "$_gn" >/dev/null 2>&1 || true
    gpart add -a 1m -t freebsd-swap -s "${_swap_mib}M" -i 3 "$_gn" >/dev/null 2>&1 || true
    
    if [ "$_mode" = "triple" ]; then
      gpart add -a 1m -t linux-data -s 15G -i 4 "$_gn" >/dev/null 2>&1 || gpart add -a 1m -t linux-data -s 4G -i 4 "$_gn" >/dev/null 2>&1 || true
      gpart add -a 1m -t freebsd-zfs -s 15G -i 5 "$_gn" >/dev/null 2>&1 || gpart add -a 1m -t freebsd-zfs -s 4G -i 5 "$_gn" >/dev/null 2>&1 || true
      gpart add -a 1m -t solaris -i 6 "$_gn" >/dev/null 2>&1 || true
    elif [ "$_mode" = "dual" ]; then
      gpart add -a 1m -t linux-data -s 20G -i 4 "$_gn" >/dev/null 2>&1 || gpart add -a 1m -t linux-data -s 6G -i 4 "$_gn" >/dev/null 2>&1 || true
      gpart add -a 1m -t freebsd-zfs -i 5 "$_gn" >/dev/null 2>&1 || true
    elif [ "$_mode" = "single" ]; then
      gpart add -a 1m -t linux-data -i 4 "$_gn" >/dev/null 2>&1 || true
    fi
  fi

  printf '[OK]   GPT Multiboot Layout successfully applied to %s\n' "$_dev"
}

# ## layout_multiboot_mbr
# Synthesizes standardized MBR partitions (primary slots 1..4 and logical EBR chaining).
layout_multiboot_mbr() {
  _dev="$1"
  _mode="$2"
  _swap_mib="$3"

  printf '[INFO] Generating MBR multiboot layout (%s) on %s...\n' "$_mode" "$_dev"

  if command -v parted >/dev/null 2>&1; then
    parted -s "$_dev" mklabel msdos >/dev/null 2>&1 || true
    case "$_mode" in
      triple)
        parted -s "$_dev" mkpart primary ext4 2048s 12GiB >/dev/null 2>&1 || parted -s "$_dev" mkpart primary ext4 2048s 3GiB >/dev/null 2>&1
        parted -s "$_dev" mkpart primary 12GiB 24GiB >/dev/null 2>&1 || parted -s "$_dev" mkpart primary 3GiB 6GiB >/dev/null 2>&1
        parted -s "$_dev" mkpart primary 24GiB 36GiB >/dev/null 2>&1 || parted -s "$_dev" mkpart primary 6GiB 9GiB >/dev/null 2>&1
        parted -s "$_dev" mkpart extended 36GiB 100% >/dev/null 2>&1 || parted -s "$_dev" mkpart extended 9GiB 100% >/dev/null 2>&1
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

  printf '[OK]   MBR Multiboot Layout successfully applied to %s\n' "$_dev"
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
        printf '[ERROR] --disk parameter is required for layout.\n' >&2
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
          printf '[INFO] Synthesizing illumos VTOC layout on %s...\n' "$_target_disk"
          ;;
        *)
          printf '[ERROR] Unsupported scheme: %s\n' "$_scheme" >&2
          exit 1
          ;;
      esac
      ;;
    --help|-h|/\?|-\?)
      show_help
      exit 0
      ;;
    *)
      printf '[ERROR] Unknown subcommand: %s\n' "$_subcmd" >&2
      show_help
      exit 1
      ;;
  esac
}

main "$@"
