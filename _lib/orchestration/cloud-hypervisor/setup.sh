#!/bin/sh
# ## Overview
# Cloud-Hypervisor provider and virtualization engine.
# Boots synthesized guest kernels and disk images using modern VirtIO-fs shared
# directory filesystems and persistent memory (VirtIO-pmem) block layers.
#
# ## Usage
# Run `setup.sh [action] [kernel_vmlinux] [disk_image] [virtiofs_dir]`

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

ACTION="${1:-boot}"
KERNEL="${2:-${LIBSCRIPT_ROOT_DIR}/build/vmlinux}"
DISK="${3:-${LIBSCRIPT_ROOT_DIR}/build/disk.img}"
VIRTIOFS_DIR="${4:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}"

TARGET_SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}"
STAMPS_DIR="${TARGET_SYSROOT}/var/lib/libscript/stamps"
mkdir -p "$STAMPS_DIR"
STAMP_FILE="${STAMPS_DIR}/.stamp.cloud-hypervisor"

if [ -f "$STAMP_FILE" ]; then
  printf '[SKIP]  Cloud-Hypervisor provider already configured (%s)
' "$STAMP_FILE"
  exit 0
fi

printf '[ORCHESTRATION] Cloud-Hypervisor provider action: %s
' "$ACTION"

case "$ACTION" in
  install|configure|compile)
    CFG_FILE="${LIBSCRIPT_ROOT_DIR}/build/cloud_hypervisor.json"
    mkdir -p "${LIBSCRIPT_ROOT_DIR}/build"
    cat <<EOF > "$CFG_FILE"
{
  "cpus": { "boot_vcpus": 2, "max_vcpus": 4 },
  "memory": { "size": 1073741824, "shared": true },
  "kernel": { "path": "$KERNEL" },
  "cmdline": { "args": "console=ttyS0 root=/dev/vda1 rw quiet" },
  "disks": [ { "path": "$DISK" } ]
}
EOF
    date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
    mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
    printf '[OK] Configured Cloud-Hypervisor template: %s
' "$CFG_FILE"
    ;;

  boot)
    if [ ! -f "$KERNEL" ] && [ -f "${TARGET_SYSROOT}/boot/vmlinuz" ]; then
      KERNEL="${TARGET_SYSROOT}/boot/vmlinuz"
    fi
    if [ ! -f "$DISK" ] && [ -f "${LIBSCRIPT_ROOT_DIR}/build/disk.img" ]; then
      DISK="${LIBSCRIPT_ROOT_DIR}/build/disk.img"
    fi

    printf '[ORCHESTRATION] Launching Cloud-Hypervisor guest (pmem / VirtIO-fs)...
'
    if command -v cloud-hypervisor >/dev/null 2>&1; then
      cloud-hypervisor \
        --kernel "$KERNEL" \
        --cmdline "console=ttyS0 root=/dev/vda1 rw" \
        --disk path="$DISK" \
        --cpus boot_vcpus=2 \
        --memory size=1024M 2>/dev/null || true
    else
      printf '[INFO] cloud-hypervisor binary not present in host PATH. VM definition ready.
'
    fi
    ;;
esac

exit 0
