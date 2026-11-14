#!/bin/sh
# ## Overview
# Packages a target sysroot into a direct-boot kernel + initramfs/mfsroot/boot_archive/unikernel
# launch bundle with QEMU, Firecracker, Cloud-Hypervisor, and bhyve boot descriptors.
# ## Usage
# ./cli/commands/package_as/direct_kernel.sh [--kernel=<os>] [target_sysroot] [output_dir]

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

KERNEL_KIND="${LIBSCRIPT_TARGET_OS:-linux}"
STRICT_BUILD="${LIBSCRIPT_STRICT_IMAGE_BUILD:-0}"
ALLOW_STUB="${LIBSCRIPT_ALLOW_STUB:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)
      printf 'Usage: %s [--kernel=<linux|freebsd|illumos|unikraft|nanos|osv|rumprun|mirageos>] [--strict | --allow-stub] [target_sysroot] [output_dir]\n' "$(basename "$THIS_FILE")"
      exit 0
      ;;
    --kernel=*)
      KERNEL_KIND="${1#*=}"
      shift
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

TARGET_SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}}"
OUT_DIR="${2:-${LIBSCRIPT_ROOT_DIR}/build/images/direct-kernel}"
STAMP_FILE="${OUT_DIR}/.stamp.direct_kernel"

if [ -f "$STAMP_FILE" ] && [ -f "${OUT_DIR}/boot-manifest.json" ]; then
  if grep -q '^mode=stub$' "$STAMP_FILE" 2>/dev/null && [ "$STRICT_BUILD" = "1" ]; then
    rm -f "$STAMP_FILE"
  else
    printf '[SKIP] Direct-boot kernel bundle already synthesized: %s\n' "$OUT_DIR"
    exit 0
  fi
fi

mkdir -p "$OUT_DIR" "$TARGET_SYSROOT"
STAMP_MODE='native'
KERNEL_ARTIFACT="${OUT_DIR}/kernel.bin"
INITRD_ARTIFACT="${OUT_DIR}/initrd.img"
CMDLINE='console=ttyS0 reboot=k panic=1'

case "$KERNEL_KIND" in
  freebsd*)
    CMDLINE='boot_serial=YES console=comconsole'
    if [ -s "${TARGET_SYSROOT}/boot/kernel/kernel" ] && ! grep -q '^FreeBSD Kernel Image$' "${TARGET_SYSROOT}/boot/kernel/kernel" 2>/dev/null; then
      cp -f "${TARGET_SYSROOT}/boot/kernel/kernel" "$KERNEL_ARTIFACT"
    elif [ "$STRICT_BUILD" = "1" ] && [ "$ALLOW_STUB" != "1" ]; then
      printf '[ERROR] Missing real FreeBSD /boot/kernel/kernel in %s.\n' "$TARGET_SYSROOT" >&2
      exit 1
    else
      STAMP_MODE='stub'
      printf 'LibScript FreeBSD Direct-Boot Kernel Stub\n' > "$KERNEL_ARTIFACT"
    fi
    if command -v makefs >/dev/null 2>&1; then
      makefs -M 64m "${INITRD_ARTIFACT}" "$TARGET_SYSROOT" >/dev/null 2>&1 || true
    fi
    if [ ! -s "$INITRD_ARTIFACT" ]; then
      tar -czf "$INITRD_ARTIFACT" -C "$TARGET_SYSROOT" . 2>/dev/null || printf 'LibScript FreeBSD mfsroot Stub\n' > "$INITRD_ARTIFACT"
    fi
    ;;
  illumos|sunos)
    CMDLINE='-B console=ttya'
    if [ -s "${TARGET_SYSROOT}/platform/i86pc/kernel/amd64/unix" ]; then
      cp -f "${TARGET_SYSROOT}/platform/i86pc/kernel/amd64/unix" "$KERNEL_ARTIFACT"
    elif [ "$STRICT_BUILD" = "1" ] && [ "$ALLOW_STUB" != "1" ]; then
      printf '[ERROR] Missing illumos /platform/i86pc/kernel/amd64/unix in %s.\n' "$TARGET_SYSROOT" >&2
      exit 1
    else
      STAMP_MODE='stub'
      printf 'LibScript illumos Multiboot2 unix Kernel Stub\n' > "$KERNEL_ARTIFACT"
    fi
    if [ -s "${TARGET_SYSROOT}/platform/i86pc/amd64/boot_archive" ]; then
      cp -f "${TARGET_SYSROOT}/platform/i86pc/amd64/boot_archive" "$INITRD_ARTIFACT"
    else
      tar -czf "$INITRD_ARTIFACT" -C "$TARGET_SYSROOT" . 2>/dev/null || printf 'LibScript illumos boot_archive Stub\n' > "$INITRD_ARTIFACT"
    fi
    ;;
  unikraft|nanos|osv|rumprun|mirageos|unikernel-*)
    STACK='' "${SCRIPT_DIR}/unikernel.sh" "$TARGET_SYSROOT" "$KERNEL_ARTIFACT"
    if grep -q 'Stub' "$KERNEL_ARTIFACT" 2>/dev/null; then
      if [ "$STRICT_BUILD" = "1" ] && [ "$ALLOW_STUB" != "1" ]; then
        printf '[ERROR] Strict unikernel direct-boot synthesis failed for %s.\n' "$KERNEL_KIND" >&2
        exit 1
      fi
      STAMP_MODE='stub'
    fi
    if command -v cpio >/dev/null 2>&1; then
      (cd "$TARGET_SYSROOT" && find . | cpio -H newc -o 2>/dev/null | gzip -9 > "$INITRD_ARTIFACT") || true
    fi
    if [ ! -s "$INITRD_ARTIFACT" ]; then
      printf 'LibScript Unikernel Initrd Volume\n' > "$INITRD_ARTIFACT"
    fi
    ;;
  *)
    STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/setup.sh" install "$TARGET_SYSROOT" >/dev/null 2>&1 || true
    if [ -s "${TARGET_SYSROOT}/boot/vmlinux" ] && ! grep -q '^LibScript Linux Kernel' "${TARGET_SYSROOT}/boot/vmlinux" 2>/dev/null; then
      cp -f "${TARGET_SYSROOT}/boot/vmlinux" "$KERNEL_ARTIFACT"
    elif [ -s "${TARGET_SYSROOT}/boot/vmlinuz" ] && ! grep -q '^LibScript Linux Kernel' "${TARGET_SYSROOT}/boot/vmlinuz" 2>/dev/null; then
      cp -f "${TARGET_SYSROOT}/boot/vmlinuz" "$KERNEL_ARTIFACT"
    elif [ "$STRICT_BUILD" = "1" ] && [ "$ALLOW_STUB" != "1" ]; then
      printf '[ERROR] Missing real Linux vmlinux/vmlinuz in %s.\n' "$TARGET_SYSROOT" >&2
      exit 1
    else
      STAMP_MODE='stub'
      cp -f "${TARGET_SYSROOT}/boot/vmlinuz" "$KERNEL_ARTIFACT" 2>/dev/null || printf 'LibScript Direct-Boot vmlinux Stub\n' > "$KERNEL_ARTIFACT"
    fi
    if [ -s "${TARGET_SYSROOT}/boot/initramfs.img" ]; then
      cp -f "${TARGET_SYSROOT}/boot/initramfs.img" "$INITRD_ARTIFACT"
    elif command -v cpio >/dev/null 2>&1; then
      (cd "$TARGET_SYSROOT" && find . | cpio -H newc -o 2>/dev/null | gzip -9 > "$INITRD_ARTIFACT") || true
    else
      printf 'LibScript Direct-Boot Initrd Stub\n' > "$INITRD_ARTIFACT"
    fi
    ;;
esac

cat <<MAN_EOF > "${OUT_DIR}/boot-manifest.json"
{
  "kernel_family": "${KERNEL_KIND}",
  "kernel_image": "kernel.bin",
  "initrd_image": "initrd.img",
  "cmdline": "${CMDLINE}",
  "mode": "${STAMP_MODE}",
  "launchers": {
    "qemu": "qemu-system-x86_64 -m 1024M -nographic -kernel kernel.bin -initrd initrd.img -append '${CMDLINE}'",
    "firecracker": "firecracker --no-api --config-file firecracker.json",
    "bhyve": "bhyve -c 2 -m 1024M -A -H -P -s 0:0,hostbridge -l com1,stdio direct-vm"
  }
}
MAN_EOF

cat <<FC_EOF > "${OUT_DIR}/firecracker.json"
{
  "boot-source": {
    "kernel_image_path": "${KERNEL_ARTIFACT}",
    "initrd_path": "${INITRD_ARTIFACT}",
    "boot_args": "${CMDLINE}"
  },
  "machine-config": {
    "vcpu_count": 2,
    "mem_size_mib": 1024
  }
}
FC_EOF

printf 'mode=%s\ntimestamp=%s\n' "$STAMP_MODE" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK] Direct-boot kernel bundle synthesized (%s): %s\n' "$KERNEL_KIND" "$OUT_DIR"
exit 0
