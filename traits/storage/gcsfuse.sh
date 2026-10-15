#!/bin/sh
# ## Overview
# Idempotently mounts Google Cloud Storage buckets via _lib/storage-layers/gcsfuse.
#
# ## Usage
# ./traits/storage/gcsfuse.sh <bucket_name> <mount_point>

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

# ## print_usage
# Prints usage instructions for traits/storage/gcsfuse.sh.
print_usage() {
  printf '%s\n' "Usage: $0 <bucket_name> <mount_point>"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  print_usage
  exit 0
fi

BUCKET="${1:-}"
MOUNT_POINT="${2:-}"
if [ -z "$BUCKET" ] || [ -z "$MOUNT_POINT" ]; then
  print_usage >&2
  exit 1
fi

SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-/}"
FSTAB_FILE="${SYSROOT%/}/etc/fstab"
mkdir -p "${SYSROOT%/}/etc" "${SYSROOT%/}${MOUNT_POINT}"
touch "$FSTAB_FILE"
MARKER="libscript-trait-gcsfuse:${MOUNT_POINT}"
if ! grep -q "# BEGIN ${MARKER}" "$FSTAB_FILE" 2>/dev/null; then
  {
    printf '# BEGIN %s\n' "$MARKER"
    printf '%s %s gcsfuse rw,_netdev,implicit_dirs,allow_other 0 0\n' "$BUCKET" "$MOUNT_POINT"
    printf '# END %s\n' "$MARKER"
  } >> "$FSTAB_FILE"
fi
printf '[INFO] gcsfuse bucket %s configured for %s.\n' "$BUCKET" "$MOUNT_POINT"
