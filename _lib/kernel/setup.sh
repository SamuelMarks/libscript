#!/bin/sh
# ## Overview
# Orchestrates Linux kernel configuration fragment assembly, kernel image staging
# (delegating to _lib/kernel/linux and _lib/kernel/initramfs), module tree population,
# and initramfs generation for target root filesystems.
# ## Usage
# ./_lib/kernel/setup.sh [--strict | --allow-stub] [install|clean|status] [target_rootfs]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

STRICT_BUILD="${LIBSCRIPT_STRICT_IMAGE_BUILD:-0}"
ALLOW_STUB="${LIBSCRIPT_ALLOW_STUB:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)
      printf 'Usage: %s [--strict | --allow-stub] [install|clean|status] [target_rootfs]\n' "$(basename "$THIS_FILE")"
      exit 0
      ;;
    --strict)
      STRICT_BUILD=1
      shift
      ;;
    --allow-stub)
      ALLOW_STUB=1
      shift
      ;;
    *)
      break
      ;;
  esac
done

ACTION="${1:-install}"
ROOTFS="${2:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/lfs/rootfs}}"
STAMPS_DIR="${LIBSCRIPT_ROOT_DIR}/build/stamps"

mkdir -p "$STAMPS_DIR"
STAMP_KERNEL="${STAMPS_DIR}/.stamp.lfs_kernel"

if [ "$ACTION" = "clean" ]; then
  printf '[CLEAN] Removing LFS kernel stamp...\n'
  rm -f "$STAMP_KERNEL"
  exit 0
fi

if [ "$ACTION" = "status" ]; then
  if [ -f "$STAMP_KERNEL" ]; then
    printf 'LFS Kernel: INSTALLED (%s)\n' "$(tr '\n' ' ' < "$STAMP_KERNEL")"
  else
    printf 'LFS Kernel: NOT INSTALLED\n'
  fi
  exit 0
fi

# ## locate_real_vmlinuz
# Searches LIBSCRIPT_HOME/linux and target/host boot directories for a real compiled kernel image.
locate_real_vmlinuz() {
  _lh="${LIBSCRIPT_HOME:-${HOME:-/tmp}/.libscript}/linux"
  if [ -d "$_lh" ]; then
    for _cand in "$_lh"/*/boot/vmlinuz* "$_lh"/*/bzImage "$_lh"/*/Image; do
      if [ -f "$_cand" ] && [ -s "$_cand" ]; then
        printf '%s\n' "$_cand"
        return 0
      fi
    done
  fi
  for _sys_k in "${ROOTFS}/boot/vmlinuz-"* "/boot/vmlinuz-"* "/boot/vmlinuz-lts" "/boot/vmlinuz-virt" "/boot/vmlinuz"; do
    if [ -f "$_sys_k" ] && [ -s "$_sys_k" ]; then
      if ! grep -q '^LibScript Linux Kernel' "$_sys_k" 2>/dev/null; then
        printf '%s\n' "$_sys_k"
        return 0
      fi
    fi
  done
  return 1
}

if [ -f "$STAMP_KERNEL" ] && [ -s "${ROOTFS}/boot/vmlinuz" ] && [ -s "${ROOTFS}/boot/initramfs.img" ]; then
  if grep -q '^mode=stub$' "$STAMP_KERNEL" 2>/dev/null; then
    if [ "$STRICT_BUILD" = "1" ] || locate_real_vmlinuz >/dev/null 2>&1; then
      rm -f "$STAMP_KERNEL"
    else
      printf '[SKIP]  LFS kernel and initramfs already built (stub: %s)\n' "$STAMP_KERNEL"
      exit 0
    fi
  else
    printf '[SKIP]  LFS kernel and initramfs already built (%s)\n' "$STAMP_KERNEL"
    exit 0
  fi
fi

printf '=== LibScript LFS Kernel & Initramfs Assembler ===\n'
printf '[INFO] Target Rootfs: %s\n' "$ROOTFS"

mkdir -p "${ROOTFS}/boot"
mkdir -p "${ROOTFS}/lib/modules"

cat << 'KCFG' > "${ROOTFS}/boot/config"
CONFIG_VIRTIO=y
CONFIG_VIRTIO_PCI=y
CONFIG_VIRTIO_BLK=y
CONFIG_VIRTIO_NET=y
CONFIG_VIRTIO_BALLOON=y
CONFIG_VIRTIO_CONSOLE=y
CONFIG_BLK_DEV_NVME=y
CONFIG_SATA_AHCI=y
CONFIG_EXT4_FS=y
CONFIG_BTRFS_FS=m
CONFIG_XFS_FS=m
CONFIG_OVERLAY_FS=y
CONFIG_VFAT_FS=y
CONFIG_EFI_PARTITION=y
CONFIG_DRM=y
CONFIG_DRM_VIRTIO_GPU=y
CONFIG_FB=y
CONFIG_DRM_SIMPLEDRM=y
CONFIG_NAMESPACES=y
CONFIG_CGROUPS=y
CONFIG_SECCOMP=y
CONFIG_DEVTMPFS=y
CONFIG_DEVTMPFS_MOUNT=y
CONFIG_BINFMT_ELF=y
KCFG

STAMP_MODE='native'
FOUND_K=""
if FOUND_K=$(locate_real_vmlinuz); then
  printf '[STAGE] Staging real kernel image from %s...\n' "$FOUND_K"
  cp -f "$FOUND_K" "${ROOTFS}/boot/vmlinuz"
elif [ "${LIBSCRIPT_BUILD_KERNEL_FROM_SOURCE:-0}" = "1" ] && [ -x "${SCRIPT_DIR}/linux/setup.sh" ]; then
  printf '[STAGE] Compiling Linux kernel via _lib/kernel/linux/setup.sh...\n'
  STACK="" "${SCRIPT_DIR}/linux/setup.sh"
  if FOUND_K=$(locate_real_vmlinuz); then
    cp -f "$FOUND_K" "${ROOTFS}/boot/vmlinuz"
  fi
fi

if [ ! -s "${ROOTFS}/boot/vmlinuz" ] || grep -q '^LibScript Linux Kernel' "${ROOTFS}/boot/vmlinuz" 2>/dev/null; then
  if [ "$STRICT_BUILD" = "1" ] && [ "$ALLOW_STUB" != "1" ]; then
    printf '[ERROR] Strict kernel staging failed: no compiled Linux kernel found. Run ./libscript.sh install linux first.\n' >&2
    rm -f "$STAMP_KERNEL"
    exit 1
  fi
  STAMP_MODE='stub'
  printf 'LibScript Linux Kernel (x86_64 virtio)\n' > "${ROOTFS}/boot/vmlinuz"
fi

if [ ! -s "${ROOTFS}/boot/vmlinux" ]; then
  cp -f "${ROOTFS}/boot/vmlinuz" "${ROOTFS}/boot/vmlinux"
fi

if [ -x "${SCRIPT_DIR}/initramfs/gen_initramfs.sh" ] && command -v cpio >/dev/null 2>&1; then
  STACK="" "${SCRIPT_DIR}/initramfs/gen_initramfs.sh" "${ROOTFS}" "${ROOTFS}/boot/initramfs.img"
else
  INITRAMFS_TMP="${ROOTFS}/tmp/initramfs_stage_$$"
  mkdir -p "${INITRAMFS_TMP}/bin" "${INITRAMFS_TMP}/dev" "${INITRAMFS_TMP}/proc" "${INITRAMFS_TMP}/sys" "${INITRAMFS_TMP}/mnt" "${INITRAMFS_TMP}/run"
  trap 'rm -rf "$INITRAMFS_TMP"' EXIT INT TERM HUP
  cat << 'INIT_EOF' > "${INITRAMFS_TMP}/init"
#!/bin/sh
mount -t devtmpfs devtmpfs /dev 2>/dev/null || mount -t tmpfs dev /dev
mount -t proc proc /proc
mount -t sysfs sysfs /sys
ROOT_DEV="/dev/vda2"
for opt in $(cat /proc/cmdline); do
  case "$opt" in
    root=*) ROOT_DEV="${opt#root=}" ;;
  esac
done
mount -o ro "$ROOT_DEV" /mnt 2>/dev/null || true
umount /sys 2>/dev/null || true
umount /proc 2>/dev/null || true
exec switch_root /mnt /sbin/init 2>/dev/null || exec /bin/sh
INIT_EOF
  chmod +x "${INITRAMFS_TMP}/init"
  if command -v cpio >/dev/null 2>&1; then
    (
      cd "$INITRAMFS_TMP"
      find . | cpio -H newc -o 2>/dev/null | gzip -9 > "${ROOTFS}/boot/initramfs.img"
    )
  elif [ "$STRICT_BUILD" = "1" ] && [ "$ALLOW_STUB" != "1" ]; then
    printf '[ERROR] cpio is required to synthesize initramfs.img in strict mode.\n' >&2
    rm -rf "$INITRAMFS_TMP" "$STAMP_KERNEL"
    exit 1
  else
    STAMP_MODE='stub'
    printf 'LibScript Initramfs Stub\n' > "${ROOTFS}/boot/initramfs.img"
  fi
  rm -rf "$INITRAMFS_TMP"
fi

printf 'mode=%s\ntimestamp=%s\n' "$STAMP_MODE" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_KERNEL}.tmp"
mv "${STAMP_KERNEL}.tmp" "$STAMP_KERNEL"
printf '[DONE]  LFS Kernel and Initramfs assembled successfully (mode=%s).\n' "$STAMP_MODE"
exit 0
