#!/bin/sh
# ## Overview
# Idempotently formats unformatted block devices via _lib/storage/format_fs.sh, discovers
# cloud data disks (--auto-data-disk), reconciles /etc/fstab or /etc/vfstab, mounts volumes,
# and normalizes directory ownership.
# ## Usage
# ./traits/storage/mount.sh <device_or_uuid|--auto-data-disk> <mount_point> [fstype]

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
export LIBSCRIPT_ROOT_DIR

for _tr_lib in "_lib/_common/priv.sh" "_lib/_common/os_info.sh"; do
  if [ -f "${LIBSCRIPT_ROOT_DIR}/${_tr_lib}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_tr_lib}"
    export SCRIPT_NAME
    # shellcheck disable=SC1090,SC1091
    . "${SCRIPT_NAME}"
    unset SCRIPT_NAME || true
  fi
done

# ## print_usage
# Prints usage instructions for traits/storage/mount.sh.
print_usage() {
  printf '%s\n' "Usage: $0 <device_or_uuid|--auto-data-disk> <mount_point> [fstype]"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  print_usage
  exit 0
fi

AUTO_DISCOVER=0
if [ "${1:-}" = "--auto-data-disk" ]; then
  AUTO_DISCOVER=1
  shift
  MOUNT_POINT="${1:-${DATA_DISK_MOUNT:-${DATA_MOUNT_DIR:-/mnt/data}}}"
  FSTYPE="${2:-ext4}"
  DEVICE=""
else
  DEVICE="${1:-}"
  MOUNT_POINT="${2:-}"
  FSTYPE="${3:-ext4}"
fi

if [ -z "$MOUNT_POINT" ] || { [ "$AUTO_DISCOVER" -eq 0 ] && [ -z "$DEVICE" ]; }; then
  print_usage >&2
  exit 1
fi

SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-/}"
OS_NAME="${UNAME:-Linux}"
if [ "$OS_NAME" = "SunOS" ]; then
  FSTAB_FILE="${SYSROOT%/}/etc/vfstab"
else
  FSTAB_FILE="${SYSROOT%/}/etc/fstab"
fi

# ## restore_ollama_models_ownership
# Restores ollama:ollama ownership and 02775 permissions on ollama_models directories inside the mounted volume.
restore_ollama_models_ownership() {
  _romo_base="${1:-${SYSROOT%/}${MOUNT_POINT}}"
  _romo_user="${2:-${SERVICE_USER:-${REMOTE_USER:-${ADMIN_USER:-${SUDO_USER:-}}}}}"
  _romo_grp="${3:-${SERVICE_GROUP:-${REMOTE_GROUP:-$_romo_user}}}"
  if id ollama >/dev/null 2>&1; then
    if [ -n "$_romo_user" ] && id "$_romo_user" >/dev/null 2>&1; then
      usermod -aG ollama "$_romo_user" 2>/dev/null || priv usermod -aG ollama "$_romo_user" 2>/dev/null || true
    fi
    if [ -n "$_romo_grp" ]; then
      usermod -aG "$_romo_grp" ollama 2>/dev/null || priv usermod -aG "$_romo_grp" ollama 2>/dev/null || true
    fi
    for _romo_dir in "${_romo_base%/}/ollama_models" "${OLLAMA_MODELS_DIR:-}" "${OLLAMA_MODELS:-}"; do
      case "$_romo_dir" in
        /*) ;;
        *) continue ;;
      esac
      if [ -d "$_romo_dir" ]; then
        chown -R ollama:ollama "$_romo_dir" 2>/dev/null || priv chown -R ollama:ollama "$_romo_dir" 2>/dev/null || true
        chmod 02775 "$_romo_dir" 2>/dev/null || priv chmod 02775 "$_romo_dir" 2>/dev/null || true
        chmod -R u+rwX,g+rwXs,o+rX "$_romo_dir" 2>/dev/null || priv chmod -R u+rwX,g+rwXs,o+rX "$_romo_dir" 2>/dev/null || true
      fi
    done
  fi
}

# ## restore_service_data_ownership
# Restores postgres:postgres (0700) and valkey:valkey or redis:redis (0750) ownership on persistent service directories inside the mounted volume.
restore_service_data_ownership() {
  _rsdo_base="${1:-${SYSROOT%/}${MOUNT_POINT}}"
  chmod 0755 "$_rsdo_base" 2>/dev/null || priv chmod 0755 "$_rsdo_base" 2>/dev/null || true

  if id postgres >/dev/null 2>&1; then
    for _rsdo_pg in "${_rsdo_base%/}/postgres" "${_rsdo_base%/}/postgresql" "${POSTGRES_DATA_DIR:-}" "${PGDATA:-}"; do
      case "$_rsdo_pg" in
        /*) ;;
        *) continue ;;
      esac
      if [ -d "$_rsdo_pg" ]; then
        chown -R postgres:postgres "$_rsdo_pg" 2>/dev/null || priv chown -R postgres:postgres "$_rsdo_pg" 2>/dev/null || true
        chmod 0700 "$_rsdo_pg" 2>/dev/null || priv chmod 0700 "$_rsdo_pg" 2>/dev/null || true
      fi
    done
  fi

  _rsdo_vk_user=""
  if id valkey >/dev/null 2>&1; then
    _rsdo_vk_user='valkey'
  elif id redis >/dev/null 2>&1; then
    _rsdo_vk_user='redis'
  fi
  if [ -n "$_rsdo_vk_user" ]; then
    for _rsdo_vk in "${_rsdo_base%/}/valkey" "${VALKEY_DATA_DIR:-}"; do
      case "$_rsdo_vk" in
        /*) ;;
        *) continue ;;
      esac
      if [ -d "$_rsdo_vk" ]; then
        chown -R "${_rsdo_vk_user}:${_rsdo_vk_user}" "$_rsdo_vk" 2>/dev/null || priv chown -R "${_rsdo_vk_user}:${_rsdo_vk_user}" "$_rsdo_vk" 2>/dev/null || true
        chmod 0750 "$_rsdo_vk" 2>/dev/null || priv chmod 0750 "$_rsdo_vk" 2>/dev/null || true
      fi
    done
  fi

  _rsdo_rd_user=""
  if id redis >/dev/null 2>&1; then
    _rsdo_rd_user='redis'
  elif id valkey >/dev/null 2>&1; then
    _rsdo_rd_user='valkey'
  fi
  if [ -n "$_rsdo_rd_user" ]; then
    for _rsdo_rd in "${_rsdo_base%/}/redis" "${REDIS_DATA_DIR:-}"; do
      case "$_rsdo_rd" in
        /*) ;;
        *) continue ;;
      esac
      if [ -d "$_rsdo_rd" ]; then
        chown -R "${_rsdo_rd_user}:${_rsdo_rd_user}" "$_rsdo_rd" 2>/dev/null || priv chown -R "${_rsdo_rd_user}:${_rsdo_rd_user}" "$_rsdo_rd" 2>/dev/null || true
        chmod 0750 "$_rsdo_rd" 2>/dev/null || priv chmod 0750 "$_rsdo_rd" 2>/dev/null || true
      fi
    done
  fi
}

# ## normalize_mount_ownership
# Ensures the mounted directory is owned by SERVICE_USER or REMOTE_USER when configured while excluding and preserving service ownership on ollama_models, postgres, valkey, and redis.
normalize_mount_ownership() {
  _nmo_dir="${SYSROOT%/}${MOUNT_POINT}"
  mkdir -p "$_nmo_dir" 2>/dev/null || priv mkdir -p "$_nmo_dir" 2>/dev/null || true
  _nmo_user="${SERVICE_USER:-${REMOTE_USER:-${ADMIN_USER:-${SUDO_USER:-}}}}"
  _nmo_grp="${SERVICE_GROUP:-${REMOTE_GROUP:-$_nmo_user}}"
  if [ -n "$_nmo_user" ] && id "$_nmo_user" >/dev/null 2>&1; then
    chown "${_nmo_user}:${_nmo_grp}" "$_nmo_dir" 2>/dev/null || priv chown "${_nmo_user}:${_nmo_grp}" "$_nmo_dir" 2>/dev/null || true
    for _nmo_entry in "${_nmo_dir}"/* "${_nmo_dir}"/.[!.]* "${_nmo_dir}"/..*; do
      [ -e "$_nmo_entry" ] || continue
      case "${_nmo_entry##*/}" in
        ollama_models|postgres|postgresql|valkey|redis|certs|lost+found) continue ;;
      esac
      chown -R "${_nmo_user}:${_nmo_grp}" "$_nmo_entry" 2>/dev/null || priv chown -R "${_nmo_user}:${_nmo_grp}" "$_nmo_entry" 2>/dev/null || true
    done
  fi
  restore_ollama_models_ownership "$_nmo_dir" "$_nmo_user" "$_nmo_grp"
  restore_service_data_ownership "$_nmo_dir"
}

# ## is_already_mounted
# Checks whether MOUNT_POINT is already an active mountpoint.
is_already_mounted() {
  if command -v mountpoint >/dev/null 2>&1 && mountpoint -q "${SYSROOT%/}${MOUNT_POINT}" 2>/dev/null; then
    return 0
  fi
  if [ -f /proc/mounts ] && grep -q " ${SYSROOT%/}${MOUNT_POINT} " /proc/mounts 2>/dev/null; then
    return 0
  fi
  if command -v mount >/dev/null 2>&1 && mount | grep -q " on ${SYSROOT%/}${MOUNT_POINT} "; then
    return 0
  fi
  return 1
}

if [ "$AUTO_DISCOVER" -eq 1 ]; then
  if [ "$SYSROOT" = "/" ] && is_already_mounted; then
    normalize_mount_ownership
    printf '[INFO] %s is already mounted; ownership normalized.\n' "$MOUNT_POINT"
    exit 0
  fi
  if [ -x "${LIBSCRIPT_ROOT_DIR}/_lib/storage/disk_discovery.sh" ]; then
    DEVICE=$("${LIBSCRIPT_ROOT_DIR}/_lib/storage/disk_discovery.sh" --auto-data-disk 2>/dev/null || true)
  fi
  if [ -z "$DEVICE" ]; then
    normalize_mount_ownership
    printf '[INFO] No unmounted physical data disk detected; prepared directory %s.\n' "$MOUNT_POINT"
    exit 0
  fi
fi

# ## check_existing_signature
# Checks whether the block device already has a valid filesystem signature to prevent destructive formatting.
check_existing_signature() {
  dev_target="$1"
  if [ -f "$dev_target" ] && grep -q "LIBSCRIPT_FS_SIGNATURE" "$dev_target" 2>/dev/null; then
    return 0
  fi
  if command -v blkid >/dev/null 2>&1 && blkid "$dev_target" >/dev/null 2>&1; then
    return 0
  fi
  if command -v fstyp >/dev/null 2>&1 && fstyp "$dev_target" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# ## reconcile_fstab_entry
# Writes persistent fstab or vfstab entry inside libscript-trait-storage markers idempotently.
reconcile_fstab_entry() {
  mkdir -p "${SYSROOT%/}/etc" 2>/dev/null || priv mkdir -p "${SYSROOT%/}/etc" 2>/dev/null || true
  mkdir -p "${SYSROOT%/}${MOUNT_POINT}" 2>/dev/null || priv mkdir -p "${SYSROOT%/}${MOUNT_POINT}" 2>/dev/null || true
  touch "$FSTAB_FILE" 2>/dev/null || priv touch "$FSTAB_FILE" 2>/dev/null || true
  marker_id="libscript-trait-storage:${MOUNT_POINT}"
  if ! grep -q "# BEGIN ${marker_id}" "$FSTAB_FILE" 2>/dev/null; then
    if [ -w "$FSTAB_FILE" ]; then
      {
        printf '# BEGIN %s\n' "$marker_id"
        printf '%s %s %s defaults,nofail 0 2\n' "$DEVICE" "$MOUNT_POINT" "$FSTYPE"
        printf '# END %s\n' "$marker_id"
      } >> "$FSTAB_FILE"
    else
      priv sh -c "printf '# BEGIN %s\n%s %s %s defaults,nofail 0 2\n# END %s\n' '$marker_id' '$DEVICE' '$MOUNT_POINT' '$FSTYPE' '$marker_id' >> '$FSTAB_FILE'" 2>/dev/null || true
    fi
  fi
}

if check_existing_signature "$DEVICE"; then
  printf '[INFO] Existing filesystem signature detected on %s; skipping format_fs.\n' "$DEVICE"
elif [ "$SYSROOT" = "/" ] && [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ] && [ -b "$DEVICE" ]; then
  "${LIBSCRIPT_ROOT_DIR}/_lib/storage/format_fs.sh" "$DEVICE" "$FSTYPE"
elif [ -f "$DEVICE" ]; then
  printf 'LIBSCRIPT_FS_SIGNATURE=%s\n' "$FSTYPE" > "$DEVICE"
fi

reconcile_fstab_entry

if [ "$SYSROOT" = "/" ] && [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ] && [ -b "$DEVICE" ]; then
  if ! is_already_mounted; then
    mount -t "$FSTYPE" "$DEVICE" "$MOUNT_POINT" 2>/dev/null || priv mount -t "$FSTYPE" "$DEVICE" "$MOUNT_POINT" 2>/dev/null || true
  fi
fi
normalize_mount_ownership
printf '[INFO] Storage trait applied for %s -> %s (%s).\n' "$DEVICE" "$MOUNT_POINT" "$FSTYPE"
