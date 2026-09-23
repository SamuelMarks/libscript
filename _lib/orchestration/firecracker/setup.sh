#!/bin/sh
# ## Overview
# Firecracker MicroVM provider and orchestration engine.
# Configures the microVM socket API, sets up TAP network devices,
# and boots uncompressed vmlinux kernels with minimal rootfs disk images in milliseconds.
#
# ## Usage
# Run `setup.sh [action] [kernel_vmlinux] [rootfs_img] [socket_path] [tap_device]`

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
ROOTFS="${3:-${LIBSCRIPT_ROOT_DIR}/build/rootfs.img}"
SOCKET="${4:-/tmp/firecracker.socket}"
TAP_DEV="${5:-tap0}"

TARGET_SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}"
STAMPS_DIR="${TARGET_SYSROOT}/var/lib/libscript/stamps"
mkdir -p "$STAMPS_DIR"
STAMP_FILE="${STAMPS_DIR}/.stamp.firecracker"

if [ "$ACTION" = "install" ] && [ -f "$STAMP_FILE" ]; then
  printf '[SKIP]  Firecracker provider already configured (%s)
' "$STAMP_FILE"
  exit 0
fi

printf '[ORCHESTRATION] Firecracker MicroVM provider action: %s
' "$ACTION"

case "$ACTION" in
  install|configure)
    # Generate microVM configuration JSON
    CFG_FILE="${LIBSCRIPT_ROOT_DIR}/build/firecracker_vm.json"
    mkdir -p "${LIBSCRIPT_ROOT_DIR}/build"
    cat <<EOF > "$CFG_FILE"
{
  "boot-source": {
    "kernel_image_path": "$KERNEL",
    "boot_args": "console=ttyS0 reboot=k panic=1 pci=off root=/dev/vda rw"
  },
  "drives": [
    {
      "drive_id": "rootfs",
      "path_on_host": "$ROOTFS",
      "is_root_device": true,
      "is_read_only": false
    }
  ],
  "machine-config": {
    "vcpu_count": 2,
    "mem_size_mib": 512
  }
}
EOF
    date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
    mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
    printf '[OK] Configured Firecracker microVM template: %s
' "$CFG_FILE"
    ;;

  boot)
    if [ ! -f "$KERNEL" ] && [ -f "${TARGET_SYSROOT}/boot/vmlinuz" ]; then
      KERNEL="${TARGET_SYSROOT}/boot/vmlinuz"
    fi
    if [ ! -f "$ROOTFS" ] && [ -f "${LIBSCRIPT_ROOT_DIR}/build/disk.img" ]; then
      ROOTFS="${LIBSCRIPT_ROOT_DIR}/build/disk.img"
    fi

    printf '[ORCHESTRATION] Starting microVM with kernel %s and rootfs %s...
' "$KERNEL" "$ROOTFS"
    if command -v firecracker >/dev/null 2>&1; then
      rm -f "$SOCKET"
      # Configure TAP network if ip tool is present and running as root
      if [ "$(id -u 2>/dev/null || printf '%s' '1000')" -eq 0 ] && command -v ip >/dev/null 2>&1; then
        ip tuntap add dev "$TAP_DEV" mode tap 2>/dev/null || true
        ip addr add 172.16.0.1/24 dev "$TAP_DEV" 2>/dev/null || true
        ip link set dev "$TAP_DEV" up 2>/dev/null || true
      fi
      # Launch Firecracker in background with API socket
      firecracker --api-sock "$SOCKET" --config-file "${LIBSCRIPT_ROOT_DIR}/build/firecracker_vm.json" 2>/dev/null || true
    else
      printf '[INFO] firecracker binary not present in host PATH. MicroVM definition staged.
'
    fi
    ;;

  stop)
    if [ -S "$SOCKET" ] && command -v curl >/dev/null 2>&1; then
      curl --unix-socket "$SOCKET" -i -X PUT 'http://localhost/actions' -H 'Accept: application/json' -d '{"action_type": "SendCtrlAltDel"}' 2>/dev/null || true
      rm -f "$SOCKET"
    fi
    printf '[OK] MicroVM stopped: %s
' "$SOCKET"
    ;;
esac

exit 0
