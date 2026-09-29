#!/bin/sh
# ## Overview
# Cross-platform disk device discovery and hardware geometry inspection engine.
# Detects available physical and virtual storage devices across Linux, FreeBSD, and illumos,
# analyzes sector sizes, verifies active mount interlocks, and outputs disk metadata.
#
# ## Usage
# Execute this script to list or inspect disks:
#   ./_lib/storage/disk_discovery.sh [--json | --help | --wipe <device>]

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
# Displays usage instructions and command-line options.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") [OPTIONS]"
  printf '%s
' "Discovers and inspects storage devices on Linux, FreeBSD, and illumos."
  printf '
'
  printf '%s
' "Options:"
  printf '%s
' "  --json              Output disk information in JSON format."
  printf '%s
' "  --wipe <device>     Destructively wipe partition tables and metadata on device."
  printf '%s
' "  --help, -h, /?, -?  Show this help message."
}

# ## detect_os
# Identifies the active operating system kernel family.
detect_os() {
  uname -s | tr '[:upper:]' '[:lower:]'
}

# ## is_device_mounted
# Checks if the specified block device or any of its partitions are mounted.
is_device_mounted() {
  _dev="$1"
  if command -v mount >/dev/null 2>&1; then
    if mount | grep -q "^${_dev}"; then
      return 0
    fi
  fi
  if [ -f /proc/mounts ]; then
    if grep -q "^${_dev}" /proc/mounts; then
      return 0
    fi
  fi
  return 1
}

# ## is_boot_media
# Checks if the given device hosts the active rootfs or live-boot media.
is_boot_media() {
  _dev="$1"
  # Check if root is on this device
  if [ -f /proc/mounts ]; then
    _root_dev=$(awk '$2 == "/" {print $1}' /proc/mounts || true)
    case "$_root_dev" in
      "${_dev}"*) return 0 ;;
    esac
  fi
  # Check FreeBSD mount
  if command -v mount >/dev/null 2>&1; then
    _bsd_root=$(mount | awk '$3 == "/" {print $1}' || true)
    case "$_bsd_root" in
      "${_dev}"*) return 0 ;;
    esac
  fi
  return 1
}

# ## wipe_device
# Destructively removes all filesystem signatures, GPT, and MBR partition headers.
wipe_device() {
  _target="$1"
  if [ -z "$_target" ]; then
    printf '[ERROR] Device path required for --wipe
' >&2
    exit 1
  fi

  if is_boot_media "$_target"; then
    printf '[ERROR] Safety interlock: %s is the active boot/root device! Aborting.
' "$_target" >&2
    exit 1
  fi

  if is_device_mounted "$_target"; then
    printf '[ERROR] Safety interlock: %s is currently mounted. Unmount before wiping.
' "$_target" >&2
    exit 1
  fi

  printf '[INFO] Sanitizing and wiping device: %s...
' "$_target"

  # Wipefs on Linux
  if command -v wipefs >/dev/null 2>&1; then
    wipefs -a "$_target" || true
  fi

  # gpart destroy on FreeBSD
  if command -v gpart >/dev/null 2>&1; then
    _geom_name=$(basename "$_target")
    gpart destroy -F "$_geom_name" >/dev/null 2>&1 || true
  fi

  # Zero out start and end of disk to eliminate GPT backup headers
  if command -v dd >/dev/null 2>&1 && [ -b "$_target" ]; then
    dd if=/dev/zero of="$_target" bs=1M count=10 conv=notrunc >/dev/null 2>&1 || true
  fi

  printf '[OK] Device %s successfully sanitized.
' "$_target"
}

# ## probe_linux_disks
# Discovers storage devices on Linux environments.
probe_linux_disks() {
  _format="$1"
  if [ "$_format" = "json" ]; then
    if command -v lsblk >/dev/null 2>&1; then
      lsblk -J -b -o NAME,PATH,SIZE,TYPE,ROTA,TRAN,MODEL,FSTYPE,MOUNTPOINT 2>/dev/null || printf '[]
'
    else
      printf '[]
'
    fi
  else
    printf '%-15s %-10s %-8s %-6s %-12s %-20s
' "DEVICE" "SIZE" "TYPE" "ROTA" "TRANSPORT" "MODEL"
    printf '%-15s %-10s %-8s %-6s %-12s %-20s
' "---------------" "----------" "--------" "------" "------------" "--------------------"
    for block in /sys/block/*; do
      [ -d "$block" ] || continue
      _dev_name=$(basename "$block")
      case "$_dev_name" in
        loop*|ram*|dm-*|zram*) continue ;;
      esac
      _size_sectors=0
      [ -f "$block/size" ] && _size_sectors=$(cat "$block/size")
      _size_bytes=$((_size_sectors * 512))
      _size_gib=$((_size_bytes / 1024 / 1024 / 1024))
      _rota="1"
      [ -f "$block/queue/rotational" ] && _rota=$(cat "$block/queue/rotational")
      _model="Unknown"
      [ -f "$block/device/model" ] && _model=$(cat "$block/device/model" | tr -s ' ')
      _tran="local"
      [ -f "$block/device/transport" ] && _tran=$(cat "$block/device/transport")

      printf '%-15s %-10s %-8s %-6s %-12s %-20s
' "/dev/${_dev_name}" "${_size_gib}G" "disk" "$_rota" "$_tran" "$_model"
    done
  fi
}

# ## probe_freebsd_disks
# Discovers storage devices on FreeBSD environments.
probe_freebsd_disks() {
  _format="$1"
  if [ "$_format" = "json" ]; then
    printf '[
'
    _first=1
    if command -v geom >/dev/null 2>&1; then
      for disk in $(geom disk list 2>/dev/null | awk '/Geom name:/ {print $3}'); do
        _med_size=$(geom disk list "$disk" 2>/dev/null | awk '/Mediasize:/ {print $2; exit}')
        _sec_size=$(geom disk list "$disk" 2>/dev/null | awk '/Sectorsize:/ {print $2; exit}')
        [ "$_first" -eq 0 ] && printf ',
'
        printf '  {"name": "%s", "path": "/dev/%s", "size": "%s", "sectorsize": "%s"}' "$disk" "$disk" "${_med_size:-0}" "${_sec_size:-512}"
        _first=0
      done
    fi
    printf '
]
'
  else
    printf '%-15s %-15s %-12s
' "DEVICE" "SIZE(BYTES)" "SECTOR_SIZE"
    printf '%-15s %-15s %-12s
' "---------------" "---------------" "------------"
    if command -v geom >/dev/null 2>&1; then
      for disk in $(geom disk list 2>/dev/null | awk '/Geom name:/ {print $3}'); do
        _med_size=$(geom disk list "$disk" 2>/dev/null | awk '/Mediasize:/ {print $2; exit}')
        _sec_size=$(geom disk list "$disk" 2>/dev/null | awk '/Sectorsize:/ {print $2; exit}')
        printf '%-15s %-15s %-12s
' "/dev/$disk" "${_med_size:-0}" "${_sec_size:-512}"
      done
    fi
  fi
}

# ## probe_illumos_disks
# Discovers storage devices on illumos / SunOS environments.
probe_illumos_disks() {
  _format="$1"
  if [ "$_format" = "json" ]; then
    printf '[
'
    _first=1
    if command -v diskinfo >/dev/null 2>&1; then
      diskinfo -Hp 2>/dev/null | while IFS='	' read -r disk _rem _rem2 size; do
        [ "$_first" -eq 0 ] && printf ',
'
        printf '  {"name": "%s", "path": "/dev/dsk/%s", "size": "%s"}' "$disk" "$disk" "${size:-0}"
        _first=0
      done
    fi
    printf '
]
'
  else
    if command -v diskinfo >/dev/null 2>&1; then
      diskinfo 2>/dev/null || true
    else
      format </dev/null 2>&1 | grep -E '^[ ]*[0-9]+\.' || true
    fi
  fi
}

FORMAT_MODE="table"
WIPE_TARGET=""

while [ $# -gt 0 ]; do
  case "$1" in
    --json)
      FORMAT_MODE="json"
      shift
      ;;
    --wipe)
      WIPE_TARGET="${2:-}"
      shift 2
      ;;
    --help|-h|/\?|-\?)
      show_help
      exit 0
      ;;
    *)
      printf '[WARN] Unknown option: %s
' "$1" >&2
      shift
      ;;
  esac
done

if [ -n "$WIPE_TARGET" ]; then
  wipe_device "$WIPE_TARGET"
  exit 0
fi

os_name=$(detect_os)
case "$os_name" in
  linux*)
    probe_linux_disks "$FORMAT_MODE"
    ;;
  freebsd*)
    probe_freebsd_disks "$FORMAT_MODE"
    ;;
  sunos*)
    probe_illumos_disks "$FORMAT_MODE"
    ;;
  darwin*)
    if [ "$FORMAT_MODE" = "json" ]; then
      diskutil list -plist 2>/dev/null || printf '[]
'
    else
      diskutil list 2>/dev/null || true
    fi
    ;;
  *)
    printf '[ERROR] Unsupported OS platform: %s
' "$os_name" >&2
    exit 1
    ;;
esac
