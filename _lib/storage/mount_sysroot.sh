#!/bin/sh
# ## Overview
# Hierarchical target mount manager and chroot sysroot preparation engine.
# Mounts root filesystems, ESP partitions, and virtual filesystems (/dev, /proc, /sys)
# under /mnt/target, and generates persistent /etc/fstab or /etc/vfstab tables.
#
# ## Usage
# Execute this script to mount or unmount target sysroot:
#   ./_lib/storage/mount_sysroot.sh [--mount <root_dev> [esp_dev] | --unmount | --fstab <target_dir>]

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
# Displays usage instructions and supported options.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") [OPTIONS]"
  printf '%s
' "Manages hierarchical mount operations and sysroot staging under /mnt/target."
  printf '
'
  printf '%s
' "Options:"
  printf '%s
' "  --mount <root_dev> [esp_dev]   Mount root and optional ESP partition."
  printf '%s
' "  --unmount                      Recursively and cleanly unmount all target paths."
  printf '%s
' "  --fstab <target_dir>           Generate /etc/fstab or /etc/vfstab in target dir."
  printf '%s
' "  --help, -h, /?, -?             Show this help message."
}

# ## detect_os
# Identifies the active operating system kernel family.
detect_os() {
  uname -s | tr '[:upper:]' '[:lower:]'
}

TARGET_DIR="/mnt/target"
ACTION="help"
ROOT_DEV=""
ESP_DEV=""

# ## is_mounted
# Checks if the specified mountpoint is currently active.
is_mounted() {
  _dir="$1"
  if command -v mountpoint >/dev/null 2>&1; then
    mountpoint -q "$_dir" 2>/dev/null && return 0
  fi
  if command -v mount >/dev/null 2>&1; then
    if mount | grep -q " on ${_dir} "; then
      return 0
    fi
  fi
  if [ -f /proc/mounts ]; then
    if grep -q " ${_dir} " /proc/mounts; then
      return 0
    fi
  fi
  return 1
}

# ## safe_mount
# Mounts a filesystem only if the destination is not already mounted.
safe_mount() {
  _src="$1"
  _dest="$2"
  _fstype="${3:-}"

  mkdir -p "$_dest"
  if is_mounted "$_dest"; then
    printf '[INFO] Destination %s already mounted. Skipping.
' "$_dest"
    return 0
  fi

  printf '[INFO] Mounting %s on %s...
' "$_src" "$_dest"
  if [ -n "$_fstype" ]; then
    mount -t "$_fstype" "$_src" "$_dest"
  else
    mount "$_src" "$_dest"
  fi
}

# ## mount_virtual_filesystems
# Bind-mounts kernel pseudo-filesystems (/dev, /proc, /sys) into target sysroot.
mount_virtual_filesystems() {
  _tgt="$1"
  _os=$(detect_os)

  case "$_os" in
    linux*)
      safe_mount "/dev" "${_tgt}/dev" "--bind" || safe_mount "udev" "${_tgt}/dev" "devtmpfs"
      safe_mount "/dev/pts" "${_tgt}/dev/pts" "--bind" || safe_mount "devpts" "${_tgt}/dev/pts" "devpts"
      safe_mount "/proc" "${_tgt}/proc" "proc"
      safe_mount "/sys" "${_tgt}/sys" "sysfs"
      ;;
    freebsd*)
      safe_mount "devfs" "${_tgt}/dev" "devfs"
      safe_mount "fdescfs" "${_tgt}/dev/fd" "fdescfs"
      safe_mount "procfs" "${_tgt}/proc" "procfs" || true
      ;;
    sunos*)
      safe_mount "/dev" "${_tgt}/dev" "lofs" || true
      safe_mount "/devices" "${_tgt}/devices" "lofs" || true
      safe_mount "proc" "${_tgt}/proc" "proc"
      ;;
  esac
}

# ## unmount_all
# Cleanly unmounts all target partitions and virtual filesystems in reverse order.
unmount_all() {
  _tgt="$1"
  printf '[INFO] Unmounting target filesystems from %s...
' "$_tgt"

  for sub in /dev/pts /dev/fd /dev /proc /sys /devices /boot/efi /boot ""; do
    _mp="${_tgt}${sub}"
    if is_mounted "$_mp"; then
      printf '       Unmounting %s...
' "$_mp"
      umount "$_mp" 2>/dev/null || umount -f "$_mp" 2>/dev/null || true
    fi
  done
  printf '[OK] All filesystems under %s unmounted.
' "$_tgt"
}

# ## generate_fstab
# Synthesizes persistent fstab or vfstab table for target sysroot.
generate_fstab() {
  _tgt="$1"
  _rdev="${2:-/dev/sda2}"
  _edev="${3:-/dev/sda1}"
  _os=$(detect_os)

  printf '[INFO] Generating filesystem table in %s (%s)...
' "$_tgt" "$_os"
  mkdir -p "${_tgt}/etc"

  case "$_os" in
    sunos*)
      cat << EOF > "${_tgt}/etc/vfstab"
#device         device          mount           FS      fsck    mount   mount
#to mount       to fsck         point           type    pass    at boot options
#
/devices        -               /devices        devfs   -       no      -
/proc           -               /proc           proc    -       no      -
ctfs            -               /system/contract ctfs   -       no      -
objfs           -               /system/object  objfs   -       no      -
swap            -               /tmp            tmpfs   -       yes     -
EOF
      printf '[OK] Generated %s/etc/vfstab
' "$_tgt"
      ;;
    freebsd*)
      cat << EOF > "${_tgt}/etc/fstab"
# Device        Mountpoint      FStype  Options Dump    Pass#
$_rdev          /               ufs     rw,noatime      1       1
EOF
      if [ -n "$_edev" ]; then
        printf '%s          /boot/efi       msdosfs rw              2       2
' "$_edev" >> "${_tgt}/etc/fstab"
      fi
      printf '[OK] Generated %s/etc/fstab
' "$_tgt"
      ;;
    *)
      cat << EOF > "${_tgt}/etc/fstab"
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
$_rdev          /               ext4    errors=remount-ro 0       1
EOF
      if [ -n "$_edev" ]; then
        printf '%s       /boot/efi       vfat    umask=0077      0       1
' "$_edev" >> "${_tgt}/etc/fstab"
      fi
      printf 'tmpfs           /tmp            tmpfs   defaults,nodev,nosuid 0       0
' >> "${_tgt}/etc/fstab"
      printf '[OK] Generated %s/etc/fstab
' "$_tgt"
      ;;
  esac
}

while [ $# -gt 0 ]; do
  case "$1" in
    --mount-dual)
      ACTION="mount_dual"
      ROOT_DEV="${2:-}"
      FREEBSD_DEV="${3:-}"
      ESP_DEV="${4:-}"
      shift $#
      ;;
    --mount)
      ACTION="mount"
      ROOT_DEV="${2:-}"
      ESP_DEV="${3:-}"
      shift $#
      ;;
    --unmount)
      ACTION="unmount"
      shift
      ;;
    --fstab)
      ACTION="fstab"
      TARGET_DIR="${2:-/mnt/target}"
      shift 2
      ;;
    --help|-h|/\?|-\?)
      show_help
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

case "$ACTION" in
  mount_dual)
    if [ -z "$ROOT_DEV" ] || [ -z "${FREEBSD_DEV:-}" ]; then
      printf '[ERROR] Both Linux and FreeBSD devices required for --mount-dual\n' >&2
      exit 1
    fi
    safe_mount "$ROOT_DEV" "${TARGET_DIR}/linux"
    safe_mount "$FREEBSD_DEV" "${TARGET_DIR}/freebsd"
    if [ -n "$ESP_DEV" ]; then
      safe_mount "$ESP_DEV" "${TARGET_DIR}/linux/boot/efi"
    fi
    mount_virtual_filesystems "${TARGET_DIR}/linux"
    printf '[OK] Dual target sysroots mounted under %s/linux and %s/freebsd\n' "$TARGET_DIR" "$TARGET_DIR"
    ;;
  mount)
    if [ -z "$ROOT_DEV" ]; then
      printf '[ERROR] Root device required for --mount
' >&2
      exit 1
    fi
    safe_mount "$ROOT_DEV" "$TARGET_DIR"
    if [ -n "$ESP_DEV" ]; then
      safe_mount "$ESP_DEV" "${TARGET_DIR}/boot/efi"
    fi
    mount_virtual_filesystems "$TARGET_DIR"
    printf '[OK] Target sysroot mounted and ready under %s
' "$TARGET_DIR"
    ;;
  unmount)
    unmount_all "$TARGET_DIR"
    ;;
  fstab)
    generate_fstab "$TARGET_DIR" "$ROOT_DEV" "$ESP_DEV"
    ;;
  *)
    show_help
    exit 0
    ;;
esac
