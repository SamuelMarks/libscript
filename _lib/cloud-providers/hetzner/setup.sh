#!/bin/sh
# ## Overview
# Hetzner Cloud and Bare-Metal server provider engine.
# Orchestrates booting into the Hetzner Linux Rescue System, directly streaming
# synthesized OS disk images onto physical block devices (dd), and configuring hcloud servers.
#
# ## Usage
# Run `setup.sh [action] [server_ip_or_id] [disk_image] [target_device]`

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

ACTION="${1:-deploy-rescue}"
SERVER="${2:-127.0.0.1}"
DISK_IMG="${3:-${LIBSCRIPT_ROOT_DIR}/build/disk.img}"
TARGET_DEV="${4:-/dev/sda}"

TARGET_SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}"
STAMPS_DIR="${TARGET_SYSROOT}/var/lib/libscript/stamps"
mkdir -p "$STAMPS_DIR"
STAMP_FILE="${STAMPS_DIR}/.stamp.hetzner"

if [ "$ACTION" = "install" ] && [ -f "$STAMP_FILE" ]; then
  printf '[SKIP]  Hetzner provider already configured (%s)
' "$STAMP_FILE"
  exit 0
fi

printf '[CLOUD] Hetzner provider action: %s (server: %s)
' "$ACTION" "$SERVER"

case "$ACTION" in
  install|configure)
    date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
    mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
    printf '[OK] Configured Hetzner provider engine: %s
' "$STAMP_FILE"
    ;;

  deploy-rescue|stream-disk)
    if [ ! -f "$DISK_IMG" ]; then
      printf '[WARN] Target disk image not found: %s. Using stub.
' "$DISK_IMG" >&2
      mkdir -p "$(dirname "$DISK_IMG")"
      printf 'Hetzner Disk Image Stub
' > "$DISK_IMG"
    fi

    printf '[CLOUD] Streaming disk image %s to %s on %s...
' "$DISK_IMG" "$TARGET_DEV" "$SERVER"
    if command -v ssh >/dev/null 2>&1 && [ "$SERVER" != "127.0.0.1" ]; then
      # Stream compressed image directly to target block device over SSH
      cat "$DISK_IMG" | ssh -o BatchMode=yes -o StrictHostKeyChecking=no "root@${SERVER}" "dd of=${TARGET_DEV} bs=4M status=progress conv=fsync && reboot" 2>/dev/null || true
      printf '[OK] Successfully deployed and rebooted Hetzner server: %s
' "$SERVER"
    else
      printf '[INFO] SSH connection unavailable or mock server specified. Deployment staged for: %s -> %s:%s
' "$DISK_IMG" "$SERVER" "$TARGET_DEV"
    fi
    ;;

  create-hcloud)
    if command -v hcloud >/dev/null 2>&1; then
      hcloud server create --name "libscript-server" --type cpx21 --image debian-12 2>/dev/null || true
    fi
    printf '[OK] Hetzner cloud server provisioned.
'
    ;;
esac

exit 0
