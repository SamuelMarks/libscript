#!/bin/sh
# ## Overview
# Executes commands within a target rootfs using Linux isolation namespaces
# (mount, uts, ipc, pid, user) and chroot environments.
#
# ## Usage
# Execute with target sysroot and command:
#   ./_lib/orchestration/runner/runner.sh <target_sysroot> <command> [args...]

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

TARGET_DIR="${1:-}"
if [ -z "$TARGET_DIR" ]; then
  printf '[ERROR] Target sysroot directory required.
' >&2
  printf 'Usage: %s <target_sysroot> <command> [args...]
' "$THIS_FILE" >&2
  exit 1
fi
shift

if [ $# -eq 0 ]; then
  CMD="/bin/sh"
else
  CMD="$*"
fi

if [ ! -d "$TARGET_DIR" ]; then
  printf '[ERROR] Target sysroot directory does not exist: %s\n' "$TARGET_DIR" >&2
  exit 1
fi

# Foreign architecture QEMU runner support
HOST_ARCH="$(uname -m 2>/dev/null || printf '%s' 'unknown')"
TARGET_ARCH="${LIBSCRIPT_TARGET_ARCH:-$HOST_ARCH}"
case "$TARGET_ARCH" in
  x86_64|amd64) QEMU_ARCH="x86_64" ;;
  aarch64|arm64) QEMU_ARCH="aarch64" ;;
  armv7*|armhf) QEMU_ARCH="arm" ;;
  riscv64) QEMU_ARCH="riscv64" ;;
  i386|i686) QEMU_ARCH="i386" ;;
  *) QEMU_ARCH="$TARGET_ARCH" ;;
esac

if [ "$HOST_ARCH" != "$TARGET_ARCH" ] && [ -n "${LIBSCRIPT_TARGET_ARCH:-}" ]; then
  if command -v "qemu-${QEMU_ARCH}-static" >/dev/null 2>&1; then
    QEMU_BIN="$(command -v "qemu-${QEMU_ARCH}-static")"
    mkdir -p "$TARGET_DIR/usr/bin"
    if [ ! -f "$TARGET_DIR/usr/bin/qemu-${QEMU_ARCH}-static" ]; then
      cp -f "$QEMU_BIN" "$TARGET_DIR/usr/bin/" 2>/dev/null || true
    fi
  fi
fi

# Determine runner strategy
if command -v unshare >/dev/null 2>&1; then
  # Try root namespace runner
  if [ "$(id -u 2>/dev/null || printf '%s' '1000')" -eq 0 ]; then
    exec unshare --mount --uts --ipc --pid --fork chroot "$TARGET_DIR" /bin/sh -c "$CMD"
  else
    # Rootless user namespace runner
    exec unshare -U -r --mount chroot "$TARGET_DIR" /bin/sh -c "$CMD"
  fi
elif command -v chroot >/dev/null 2>&1; then
  exec chroot "$TARGET_DIR" /bin/sh -c "$CMD"
else
  printf '[ERROR] Neither unshare nor chroot available on this system.
' >&2
  exit 1
fi
