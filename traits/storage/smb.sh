#!/bin/sh
# ## Overview
# Idempotently configures SMB/CIFS network mounts and reconciles /etc/fstab.
#
# ## Usage
# ./traits/storage/smb.sh <smb_share_unc> <mount_point>

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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

# ## print_usage
# Prints usage instructions for traits/storage/smb.sh.
print_usage() {
  printf '%s\n' "Usage: $0 <smb_share_unc> <mount_point>"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  print_usage
  exit 0
fi

SMB_SHARE="${1:-}"
MOUNT_POINT="${2:-}"
if [ -z "$SMB_SHARE" ] || [ -z "$MOUNT_POINT" ]; then
  print_usage >&2
  exit 1
fi

SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-/}"
FSTAB_FILE="${SYSROOT%/}/etc/fstab"
mkdir -p "${SYSROOT%/}/etc" "${SYSROOT%/}${MOUNT_POINT}"
touch "$FSTAB_FILE"
MARKER="libscript-trait-smb:${MOUNT_POINT}"
if ! grep -q "# BEGIN ${MARKER}" "$FSTAB_FILE" 2>/dev/null; then
  {
    printf '# BEGIN %s\n' "$MARKER"
    printf '%s %s cifs _netdev,nofail 0 0\n' "$SMB_SHARE" "$MOUNT_POINT"
    printf '# END %s\n' "$MARKER"
  } >> "$FSTAB_FILE"
fi
printf '[INFO] SMB share %s configured for %s.\n' "$SMB_SHARE" "$MOUNT_POINT"
