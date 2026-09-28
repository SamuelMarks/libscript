#!/bin/sh
# ## Overview
# Bootstraps the illumos base system directory layout, device nodes,
# release metadata, and proto-area root structure into target sysroot.
#
# ## Usage
# Bootstrap illumos base system:
#   _lib/illumos/distro/base.sh [sysroot_path] [illumos_version] [arch]

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
VERSION="${2:-r151048}"
ARCH="${3:-amd64}"

STAMP_DIR="${SYSROOT}/.libscript_stamps"
STAMP_FILE="${STAMP_DIR}/base.stamp"

mkdir -p "${STAMP_DIR}"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     illumos base system already bootstrapped in %s
' "${SYSROOT}"
  exit 0
fi

printf '[BASE]     Bootstrapping illumos %s (%s) sysroot into %s...
' "${VERSION}" "${ARCH}" "${SYSROOT}"

# Canonical illumos / SunOS root directory hierarchy
for d in boot dev devices etc export export/home home kernel lib mnt opt platform proc root sbin system tmp usr var; do
  mkdir -p "${SYSROOT}/${d}"
done

# Standard /usr subdirectories
for d in bin sbin lib lib/64 kernel share; do
  mkdir -p "${SYSROOT}/usr/${d}"
done

# Standard /var subdirectories
for d in adm log run svc svc/manifest tmp; do
  mkdir -p "${SYSROOT}/var/${d}"
done

# Standard /system subdirectories (contract, object, volatile)
for d in contract object volatile; do
  mkdir -p "${SYSROOT}/system/${d}"
done

# Write release metadata marker
printf 'illumos %s (%s)
' "${VERSION}" "${ARCH}" > "${SYSROOT}/etc/release"
printf '%s
' "${VERSION}" > "${SYSROOT}/etc/libscript-illumos-version"

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"

printf '[OK]       illumos base system bootstrap complete: %s
' "${SYSROOT}"
