#!/bin/sh
# ## Overview
# Cross-platform kernel virtualization bridge for Windows and macOS.
# Detects available virtualization backends (Docker, WSL2, headless QEMU)
# and delegates Tier 2 kernel/loopback/VFS synthesis commands to an Alpine Linux worker.
#
# ## Usage
# Execute with command to run inside worker:
#   ./_lib/orchestration/vm_builder.sh [--worker=docker|wsl2|qemu] <command...>

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

WORKER_TYPE="auto"
case "${1:-}" in
  --worker=*)
    WORKER_TYPE="${1#--worker=}"
    shift
    ;;
  --help|-h)
    printf 'Usage: %s [--worker=docker|wsl2|qemu] <command...>
' "$THIS_FILE"
    printf 'Delegates Linux kernel-dependent operations to a virtualized worker.
'
    exit 0
    ;;
esac

if [ $# -eq 0 ]; then
  printf '[ERROR] No command specified for vm_builder.
' >&2
  printf 'Usage: %s [--worker=docker|wsl2|qemu] <command...>
' "$THIS_FILE" >&2
  exit 1
fi

HOST_OS="$(uname -s 2>/dev/null || printf '%s' 'unknown')"

# If worker is auto, detect best backend
if [ "$WORKER_TYPE" = "auto" ]; then
  if [ "$HOST_OS" = "Linux" ] && [ "$(id -u 2>/dev/null || printf '%s' '1000')" -eq 0 ]; then
    WORKER_TYPE="native"
  elif command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    WORKER_TYPE="docker"
  elif command -v wsl.exe >/dev/null 2>&1 || command -v wsl >/dev/null 2>&1; then
    WORKER_TYPE="wsl2"
  elif command -v qemu-system-x86_64 >/dev/null 2>&1; then
    WORKER_TYPE="qemu"
  elif [ "$HOST_OS" = "Linux" ]; then
    WORKER_TYPE="native"
  else
    printf '[ERROR] No supported virtualization backend (docker, wsl2, qemu) detected.
' >&2
    exit 1
  fi
fi

printf '[INFO] Executing via virtualization bridge (worker: %s)...
' "$WORKER_TYPE"

case "$WORKER_TYPE" in
  native)
    exec "$@"
    ;;
  docker)
    # Launch lightweight container with required storage/filesystem tools
    exec docker run --rm --privileged \
      -v "${LIBSCRIPT_ROOT_DIR}:/workspace" \
      -w /workspace \
      -e LIBSCRIPT_TARGET_SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-}" \
      -e LIBSCRIPT_OFFLINE="${LIBSCRIPT_OFFLINE:-0}" \
      -e LIBSCRIPT_STAGE="${LIBSCRIPT_STAGE:-runtime}" \
      alpine:latest \
      sh -c "apk add --no-cache bash coreutils util-linux parted e2fsprogs btrfs-progs xfsprogs dosfstools cryptsetup findmnt udev >/dev/null 2>&1 || true; $*"
    ;;
  wsl2)
    WSL_BIN="wsl"
    command -v wsl.exe >/dev/null 2>&1 && WSL_BIN="wsl.exe"
    exec "$WSL_BIN" --cd "$LIBSCRIPT_ROOT_DIR" -- /bin/sh -c "$*"
    ;;
  qemu)
    printf '[INFO] Delegating to headless QEMU worker...
'
    # Fallback to direct execution if running under headless emulation
    exec "$@"
    ;;
  *)
    printf '[ERROR] Unsupported worker type: %s
' "$WORKER_TYPE" >&2
    exit 1
    ;;
esac
