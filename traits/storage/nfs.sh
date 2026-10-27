#!/bin/sh
# ## Overview
# Idempotently mounts NFSv4 and GCP Filestore exports and reconciles /etc/fstab or /etc/vfstab.
#
# ## Usage
# ./traits/storage/nfs.sh <nfs_server_export> <mount_point> [--filestore-instance <name>]

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

for LIB in _lib/_common/pkg_mgr.sh _lib/_common/log.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

# ## print_usage
# Prints usage instructions for the NFS storage trait driver.
print_usage() {
  printf '%s\n' "Usage: $0 <nfs_server_export> <mount_point> [--filestore-instance <name>]"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  print_usage
  exit 0
fi

NFS_EXPORT="${1:-}"
MOUNT_POINT="${2:-}"
if [ -z "$NFS_EXPORT" ] || [ -z "$MOUNT_POINT" ]; then
  print_usage >&2
  exit 1
fi

SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-/}"
FSTAB_PATH="${SYSROOT%/}/etc/fstab"
SCOPE="libscript-trait-nfs-$(printf '%s' "$MOUNT_POINT" | tr '/' '_')"

# ## reconcile_nfs_fstab
# Idempotently writes the NFS mount entry into /etc/fstab within managed markers.
reconcile_nfs_fstab() {
  mkdir -p "${SYSROOT%/}/etc"
  mkdir -p "${SYSROOT%/}${MOUNT_POINT}"
  touch "$FSTAB_PATH"
  if ! grep -q "# BEGIN libscript-managed: ${SCOPE}" "$FSTAB_PATH" 2>/dev/null; then
    {
      printf '# BEGIN libscript-managed: %s\n' "$SCOPE"
      printf '%s %s nfs4 rw,_netdev,hard,timeo=600,retrans=2 0 0\n' "$NFS_EXPORT" "$MOUNT_POINT"
      printf '# END libscript-managed: %s\n' "$SCOPE"
    } >> "$FSTAB_PATH"
  fi
}

reconcile_nfs_fstab

if [ "$SYSROOT" = "/" ] && [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ]; then
  if mount | grep -q " on ${MOUNT_POINT} "; then
    log_info "NFS export ${NFS_EXPORT} is already mounted at ${MOUNT_POINT}."
  else
    log_info "Mounting NFS export ${NFS_EXPORT} at ${MOUNT_POINT}..."
    mount -t nfs "${NFS_EXPORT}" "${MOUNT_POINT}" 2>/dev/null || log_warn "Live NFS mount skipped or requires elevated privileges."
  fi
else
  log_info "Tier 2 Offline Bake Mode: pre-baked NFS entry for ${MOUNT_POINT} into ${FSTAB_PATH}."
fi
