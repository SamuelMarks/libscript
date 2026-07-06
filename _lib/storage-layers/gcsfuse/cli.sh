#!/bin/sh
# ## Overview
# Command-line interface entrypoint for the gcsfuse component.
# It initializes the lifecycle, resolves the package name, and delegates execution
# to the shared component_core.sh script.
#
# ## Usage
# Execute this script directly to run the CLI functionality for the component.

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
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
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"

for LIB in _lib/_common/pkg_mgr.sh _lib/_common/log.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 <action> [args...]"
  printf '%s\n' "See README.md for details."
  exit 0
fi

# Ensure gcsfuse is available
if ! command -v gcsfuse >/dev/null 2>&1; then
  if [ -x "${LIBSCRIPT_ROOT_DIR}/installed/gcsfuse/bin/gcsfuse" ]; then
    export PATH="${LIBSCRIPT_ROOT_DIR}/installed/gcsfuse/bin:${PATH}"
  else
    log_error "gcsfuse not found. Please install the storage-layers/gcsfuse component first."
    exit 1
  fi
fi

ACTION="${1:-}"
BUCKET_NAME="${2:-}"
MOUNT_POINT="${3:-}"

case "$ACTION" in
  mount)
    if [ -z "$BUCKET_NAME" ] || [ -z "$MOUNT_POINT" ]; then
      log_error "Usage: gcsfuse mount <bucket_name> <mount_point>"
      exit 1
    fi
    # Strip gs:// prefix if present
    BUCKET_NAME=$(printf '%s\n' "$BUCKET_NAME" | sed 's/^gs:\/\///')
    
    mkdir -p "$MOUNT_POINT"
    log_info "Mounting bucket $BUCKET_NAME to $MOUNT_POINT..."
    # If not running on GCP metadata server, it will use application default credentials.
    gcsfuse --implicit-dirs "$BUCKET_NAME" "$MOUNT_POINT"
    log_info "Mounted successfully."
    ;;
  unmount)
    if [ -z "$BUCKET_NAME" ]; then
      # Here bucket name acts as the mount point
      log_error "Usage: gcsfuse unmount <mount_point>"
      exit 1
    fi
    log_info "Unmounting $BUCKET_NAME..."
    fusermount -u "$BUCKET_NAME"
    log_info "Unmounted."
    ;;
  *)
    log_error "Unknown action: $ACTION. Supported: mount, unmount."
    exit 1
    ;;
esac
