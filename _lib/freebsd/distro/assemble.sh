#!/bin/sh
# ## Overview
# Orchestrates FreeBSD distribution synthesis from a JSON profile specification.
# Invokes base, config, pkg, users, init, display, desktop, and audio modules
# deterministically with full idempotency guarantees.
#
# ## Usage
# Assemble FreeBSD distribution:
#   _lib/freebsd/distro/assemble.sh [profile_json_path] [target_sysroot]

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

PROFILE="${1:-${REPO_ROOT}/profiles/freebsd/minimal-server.json}"
SYSROOT="${2:-${REPO_ROOT}/build/freebsd-sysroot}"

if [ ! -f "${PROFILE}" ]; then
  printf '[ERROR]    Profile configuration "%s" not found!
' "${PROFILE}" >&2
  exit 1
fi

STAMP_DIR="${SYSROOT}/.libscript_stamps"
STAMP_FILE="${STAMP_DIR}/assembled.stamp"

mkdir -p "${STAMP_DIR}"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     FreeBSD distribution already assembled in %s
' "${SYSROOT}"
  exit 0
fi

printf '[ASSEMBLE] Synthesizing FreeBSD distribution using profile: %s...
' "${PROFILE}"

# Extract key profile fields via python / sh helper
PROFILE_NAME=$(awk -F'"' '/"profile_name":/ { print $4 }' "${PROFILE}" | head -n 1)
FBSD_VERSION=$(awk -F'"' '/"freebsd_version":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${FBSD_VERSION:=14.1-RELEASE}"
ARCH=$(awk -F'"' '/"arch":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${ARCH:=amd64}"
INIT_SYS=$(awk -F'"' '/"provider":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${INIT_SYS:=bsd-rc}"
DISP_PROTO=$(awk -F'"' '/"protocol":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${DISP_PROTO:=none}"
DESKTOP_ENV=$(awk -F'"' '/"environment":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${DESKTOP_ENV:=none}"
DM=$(awk -F'"' '/"display_manager":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${DM:=none}"
FILESYSTEM=$(awk -F'"' '/"filesystem":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${FILESYSTEM:=ufs2}"
AUDIO_SUB=$(awk -F'"' '/"subsystem":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${AUDIO_SUB:=none}"
HOSTNAME=$(awk -F'"' '/"hostname":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${HOSTNAME:=freebsd-distro}"
PRIMARY_USER=$(awk -F'"' '/"username":/ { print $4 }' "${PROFILE}" | head -n 1)
: "${PRIMARY_USER:=vagrant}"

printf '[ASSEMBLE] Profile: %s | Init: %s | Desktop: %s | DM: %s | FS: %s\n' \
  "${PROFILE_NAME}" "${INIT_SYS}" "${DESKTOP_ENV}" "${DM}" "${FILESYSTEM}"

# Step 1: Base userland bootstrap
"${SCRIPT_DIR}/base.sh" "${SYSROOT}" "${FBSD_VERSION}" "${ARCH}"

# Step 2: Core configuration
"${SCRIPT_DIR}/config.sh" "${SYSROOT}" "${HOSTNAME}" "${FILESYSTEM}"

# Step 3: Package repository configuration
"${SCRIPT_DIR}/pkg.sh" "${SYSROOT}" "quarterly"

# Step 4: User accounts and authentication
"${SCRIPT_DIR}/users.sh" "${SYSROOT}" "${PRIMARY_USER}"

# Step 5: Init system configuration
"${SCRIPT_DIR}/init.sh" "${SYSROOT}" "${INIT_SYS}" "sshd,cron,devd"

# Step 6: Display protocol configuration
"${SCRIPT_DIR}/display.sh" "${SYSROOT}" "${DISP_PROTO}" "drm-kmod"

# Step 7: Desktop environment staging
"${SCRIPT_DIR}/desktop.sh" "${SYSROOT}" "${DESKTOP_ENV}" "${PRIMARY_USER}"

# Step 8: Display manager configuration
"${SCRIPT_DIR}/dm.sh" "${SYSROOT}" "${DM}" "${PRIMARY_USER}"

# Step 9: Audio subsystem configuration
"${SCRIPT_DIR}/audio.sh" "${SYSROOT}" "${AUDIO_SUB}"

# Final assembly stamp
date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       FreeBSD distribution assembly complete for %s.
' "${PROFILE_NAME}"
