#!/bin/sh
# ## Overview
# Orchestrates illumos modular distribution synthesis from a JSON profile specification.
# Invokes base, zfs, config, pkg, users, init, display, desktop, dm, and audio modules
# deterministically with full idempotency guarantees.
#
# ## Usage
# Assemble illumos distribution:
#   _lib/illumos/distro/assemble.sh [profile_json_path] [target_sysroot]

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

PROFILE="${1:-${REPO_ROOT}/profiles/illumos/minimal-server.json}"
SYSROOT="${2:-${REPO_ROOT}/build/illumos-sysroot}"

if [ ! -f "${PROFILE}" ]; then
  printf '[ERROR]    Profile configuration "%s" not found!
' "${PROFILE}" >&2
  exit 1
fi

STAMP_DIR="${SYSROOT}/.libscript_stamps"
STAMP_FILE="${STAMP_DIR}/assembled.stamp"

mkdir -p "${STAMP_DIR}"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     illumos distribution already assembled in %s
' "${SYSROOT}"
  exit 0
fi

printf '[ASSEMBLE] Synthesizing illumos distribution using profile: %s...
' "${PROFILE}"

# Extract key profile fields via POSIX awk helper
PROFILE_NAME=$(awk -F'"' '/"profile_name":/ { print $4 }' "${PROFILE}" | head -n 1)
ILLUMOS_VERSION=$(awk -F'"' '/"illumos_version":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${ILLUMOS_VERSION:=r151048}"
ARCH=$(awk -F'"' '/"arch":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${ARCH:=amd64}"
INIT_SYS=$(awk -F'"' '/"provider":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${INIT_SYS:=smf}"
MILESTONE=$(awk -F'"' '/"milestone":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${MILESTONE:=svc:/milestone/multi-user-server:default}"
DISP_PROTO=$(awk -F'"' '/"protocol":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${DISP_PROTO:=none}"
GRAPHICS_DRIVER=$(awk -F'"' '/"graphics_driver":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${GRAPHICS_DRIVER:=none}"
DESKTOP_ENV=$(awk -F'"' '/"environment":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${DESKTOP_ENV:=none}"
DM=$(awk -F'"' '/"display_manager":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${DM:=none}"
POOL_NAME=$(awk -F'"' '/"pool_name":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${POOL_NAME:=rpool}"
COMPRESSION=$(awk -F'"' '/"compression":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${COMPRESSION:=lz4}"
AUDIO_SUB=$(awk -F'"' '/"subsystem":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${AUDIO_SUB:=none}"
PKG_PROVIDER=$(awk -F'"' '/"provider":/ { print $4 }' "${PROFILE}" | sed -n '2p')
: "${PKG_PROVIDER:=ips}"
PUB_URL=$(awk -F'"' '/"publisher_url":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${PUB_URL:=https://pkg.omnios.org/r151048/core}"
HOSTNAME=$(awk -F'"' '/"hostname":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${HOSTNAME:=illumos-distro}"
PRIMARY_USER=$(awk -F'"' '/"username":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${PRIMARY_USER:=vagrant}"

printf '[ASSEMBLE] Profile: %s | Init: %s | Desktop: %s | DM: %s | Pool: %s\n' \
  "${PROFILE_NAME}" "${INIT_SYS}" "${DESKTOP_ENV}" "${DM}" "${POOL_NAME}"

# Step 1: Base directory and userland bootstrap
"${SCRIPT_DIR}/base.sh" "${SYSROOT}" "${ILLUMOS_VERSION}" "${ARCH}"

# Step 2: ZFS dataset layout and vfstab
"${SCRIPT_DIR}/zfs.sh" "${SYSROOT}" "${POOL_NAME}" "${COMPRESSION}"

# Step 3: Core OS configuration
"${SCRIPT_DIR}/config.sh" "${SYSROOT}" "${HOSTNAME}" "true"

# Step 4: Package publisher configuration
"${SCRIPT_DIR}/pkg.sh" "${SYSROOT}" "${PKG_PROVIDER}" "${PUB_URL}"

# Step 5: User accounts, RBAC, and SSH keys
"${SCRIPT_DIR}/users.sh" "${SYSROOT}" "${PRIMARY_USER}"

# Step 6: Init system supervision
"${SCRIPT_DIR}/init.sh" "${SYSROOT}" "${INIT_SYS}" "svc:/network/ssh:default,svc:/system/cron:default" "${MILESTONE}"

# Step 7: Display subsystem and driver
"${SCRIPT_DIR}/display.sh" "${SYSROOT}" "${DISP_PROTO}" "${GRAPHICS_DRIVER}"

# Step 8: Desktop environment
"${SCRIPT_DIR}/desktop.sh" "${SYSROOT}" "${DESKTOP_ENV}" "${PRIMARY_USER}"

# Step 9: Display manager
"${SCRIPT_DIR}/dm.sh" "${SYSROOT}" "${DM}" "${PRIMARY_USER}"

# Step 10: Audio subsystem
"${SCRIPT_DIR}/audio.sh" "${SYSROOT}" "${AUDIO_SUB}"

# Write assembly completion manifest and stamp
cat << EOF > "${SYSROOT}/etc/libscript-distro.manifest"
profile_name=${PROFILE_NAME}
illumos_version=${ILLUMOS_VERSION}
arch=${ARCH}
init_system=${INIT_SYS}
display_protocol=${DISP_PROTO}
desktop_environment=${DESKTOP_ENV}
display_manager=${DM}
pool_name=${POOL_NAME}
audio_subsystem=${AUDIO_SUB}
primary_user=${PRIMARY_USER}
hostname=${HOSTNAME}
assembled_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"

printf '[OK]       illumos distribution synthesized successfully: %s
' "${SYSROOT}"
