#!/bin/sh
# ## Overview
# Configures canonical illumos ZFS root pool (rpool) layout, dataset hierarchies,
# /etc/vfstab entries, boot environment definitions (beadm), and loader configuration.
#
# ## Usage
# Configure ZFS root pool and datasets:
#   _lib/illumos/distro/zfs.sh [sysroot_path] [pool_name] [compression]

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
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${REPO_ROOT}/build/illumos-sysroot}}"
POOL_NAME="${2:-rpool}"
COMPRESSION="${3:-lz4}"

STAMP_DIR="${SYSROOT}/.libscript_stamps"
STAMP_FILE="${STAMP_DIR}/zfs.stamp"

mkdir -p "${STAMP_DIR}"
mkdir -p "${SYSROOT}/etc"
mkdir -p "${SYSROOT}/boot"
mkdir -p "${SYSROOT}/rpool"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     illumos ZFS storage layout already configured in %s
' "${SYSROOT}"
  exit 0
fi

printf '[ZFS]      Configuring illumos ZFS dataset hierarchy (pool: %s, compression: %s)...
' "${POOL_NAME}" "${COMPRESSION}"

# 1. ZFS dataset hierarchy manifest (for synthesis / packaging)
cat << EOF > "${SYSROOT}/etc/zfs-datasets.conf"
# Illumos ZFS Root Pool Layout (managed by LibScript)
# pool: ${POOL_NAME}
# compression: ${COMPRESSION}
${POOL_NAME}                    mountpoint=none,canmount=off
${POOL_NAME}/ROOT               mountpoint=none,canmount=off
${POOL_NAME}/ROOT/illumos       mountpoint=legacy,canmount=noauto,compression=${COMPRESSION},bootfs=yes
${POOL_NAME}/export             mountpoint=/export,canmount=off
${POOL_NAME}/export/home        mountpoint=/export/home,canmount=on,compression=${COMPRESSION}
${POOL_NAME}/dump               volsize=2G,canmount=off
${POOL_NAME}/swap               volsize=2G,canmount=off
EOF

# 2. Solaris / illumos /etc/vfstab
cat << EOF > "${SYSROOT}/etc/vfstab"
# /etc/vfstab: Virtual File System Table (managed by LibScript)
#
#device         device          mount           FS      fsck    mount   mount
#to mount       to fsck         point           type    pass    at boot options
#
/devices        -               /devices        devfs   -       no      -
/proc           -               /proc           proc    -       no      -
ctfs            -               /system/contract ctfs   -       no      -
objfs           -               /system/object  objfs   -       no      -
swap            -               /tmp            tmpfs   -       yes     -
/dev/zfs        -               /               zfs     -       yes     -
/dev/zvol/dsk/${POOL_NAME}/swap - -             swap    -       no      -
EOF

# 3. Boot environment configuration (beadm metadata)
mkdir -p "${SYSROOT}/etc/be"
cat << EOF > "${SYSROOT}/etc/be/be.conf"
# LibScript Boot Environment Specification
ACTIVE_BE="illumos"
ACTIVE_POOL="${POOL_NAME}"
BE_DATASET="${POOL_NAME}/ROOT/illumos"
EOF

# 4. Loader configuration for ZFS root mount
cat << EOF >> "${SYSROOT}/boot/loader.conf"
zfs_load="YES"
vfs.root.mountfrom="zfs:${POOL_NAME}/ROOT/illumos"
EOF

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"

printf '[OK]       illumos ZFS storage layout configured successfully: %s
' "${SYSROOT}"
