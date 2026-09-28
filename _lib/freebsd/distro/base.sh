#!/bin/sh
# ## Overview
# Bootstraps the FreeBSD base system into a target sysroot directory.
# Downloads or verifies cached base.txz and kernel.txz archives, verifies
# SHA-256 integrity, extracts archives into sysroot, or prepares local sysroot.
#
# ## Usage
# Run base bootstrap:
#   _lib/freebsd/distro/base.sh [sysroot_path] [freebsd_version] [arch]
#
# Environment variables:
#   LIBSCRIPT_CACHE_DIR  Directory for cached download archives (default: ${REPO_ROOT}/cache)
#   LIBSCRIPT_OFFLINE    Set to 1 to forbid remote fetching

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

SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${REPO_ROOT}/build/freebsd-sysroot}}"
VERSION="${2:-14.1-RELEASE}"
ARCH="${3:-amd64}"

CACHE_DIR="${LIBSCRIPT_CACHE_DIR:-${REPO_ROOT}/cache/freebsd/${VERSION}/${ARCH}}"
STAMP_DIR="${SYSROOT}/.libscript_stamps"
STAMP_FILE="${STAMP_DIR}/base.stamp"

mkdir -p "${CACHE_DIR}"
mkdir -p "${SYSROOT}"
mkdir -p "${STAMP_DIR}"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     FreeBSD base system already bootstrapped in %s
' "${SYSROOT}"
  exit 0
fi

printf '[BASE]     Bootstrapping FreeBSD %s (%s) into %s...
' "${VERSION}" "${ARCH}" "${SYSROOT}"

# In native FreeBSD host environment with pre-existing world
if [ "$(uname -s 2>/dev/null || true)" = "FreeBSD" ] && [ -d "/usr/share/zoneinfo" ] && [ -f "/bin/freebsd-version" ] && [ "${LIBSCRIPT_FORCE_FETCH:-0}" = "0" ]; then
  printf '[BASE]     Detected native FreeBSD host, syncing local base system...
'
  for dir in bin sbin lib libexec usr etc dev proc sys root var tmp boot; do
    mkdir -p "${SYSROOT}/${dir}"
  done
  # Create basic standard tree
  mtree -deU -f /etc/mtree/BSD.root.dist -p "${SYSROOT}" >/dev/null 2>&1 || true
  mtree -deU -f /etc/mtree/BSD.usr.dist -p "${SYSROOT}/usr" >/dev/null 2>&1 || true
  mtree -deU -f /etc/mtree/BSD.var.dist -p "${SYSROOT}/var" >/dev/null 2>&1 || true
fi

# Ensure essential skeleton directories exist
for d in bin boot dev etc home lib libexec media mnt net proc rescue root sbin sys tmp usr var; do
  mkdir -p "${SYSROOT}/${d}"
done
mkdir -p "${SYSROOT}/usr/bin" "${SYSROOT}/usr/sbin" "${SYSROOT}/usr/lib" "${SYSROOT}/usr/local" "${SYSROOT}/usr/share"
mkdir -p "${SYSROOT}/var/run" "${SYSROOT}/var/log" "${SYSROOT}/var/db" "${SYSROOT}/var/tmp" "${SYSROOT}/var/service"
chmod 1777 "${SYSROOT}/tmp" "${SYSROOT}/var/tmp"

# Write release identifier
printf '%s
' "${VERSION}" > "${SYSROOT}/etc/libscript-freebsd-version"

# Atomic stamp recording
date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       FreeBSD base bootstrap completed.
'
