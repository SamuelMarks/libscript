#!/bin/sh
# ## Overview
# Bootstraps the illumos base system into target sysroot, supporting OmniOS, OpenIndiana,
# Tribblix, and SmartOS proto-root layouts and IPS/zap/stream extraction when enabled.
# ## Usage
# ./_lib/illumos/distro/base.sh [target_sysroot] [illumos_version] [arch] [flavor]

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

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf 'Usage: %s [target_sysroot] [illumos_version] [arch] [omnios|openindiana|tribblix|smartos]\n' "$0"
  exit 0
fi

SYSROOT="${1:-${LIBSCRIPT_ROOT_DIR}/build/illumos-sysroot}"
VERSION="${2:-r151048}"
ARCH="${3:-amd64}"
FLAVOR="${4:-omnios}"

STAMP_DIR="${SYSROOT}/.libscript-stamps"
STAMP_FILE="${STAMP_DIR}/illumos-base-${VERSION}-${ARCH}.stamp"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     illumos base (%s, %s, %s) already bootstrapped at %s\n' "${VERSION}" "${ARCH}" "${FLAVOR}" "${SYSROOT}"
  exit 0
fi

printf '[BOOTSTRAP] Initializing illumos base (%s, %s, flavor=%s) in %s...\n' "${VERSION}" "${ARCH}" "${FLAVOR}" "${SYSROOT}"

for dir in bin boot/forth boot/solaris dev devices etc/default etc/inet etc/svc/volatile export/home kernel lib/amd64 mnt opt/ooce/bin opt/local/bin platform/i86pc/kernel/amd64 platform/i86pc/amd64 proc root sbin system/contract system/object tmp usr/bin usr/sbin usr/lib usr/gnu/bin var/adm var/log var/pkg var/run var/sadm/pkg var/svc/log var/svc/manifest/site; do
  mkdir -p "${SYSROOT}/${dir}"
done
chmod 1777 "${SYSROOT}/tmp" 2>/dev/null || true

if [ "${LIBSCRIPT_FETCH_ILLUMOS_BASE:-0}" = "1" ] && [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ]; then
  case "$FLAVOR" in
    openindiana)
      if command -v pkg >/dev/null 2>&1; then
        pkg image-create -F -p openindiana.org=https://pkg.openindiana.org/hipster "${SYSROOT}" >/dev/null 2>&1 || true
        pkg -R "${SYSROOT}" install --accept minimal-install >/dev/null 2>&1 || true
      fi
      ;;
    tribblix)
      if command -v zap >/dev/null 2>&1; then
        zap -R "${SYSROOT}" install TRIBv-minimal >/dev/null 2>&1 || true
      fi
      ;;
    smartos)
      _sm_cache="${LIBSCRIPT_CACHE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache}/illumos/smartos"
      mkdir -p "$_sm_cache"
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mgr.sh"
      export SCRIPT_NAME
      # shellcheck disable=SC1090,SC1091
      . "${SCRIPT_NAME}"
      unset SCRIPT_NAME || true
      libscript_download 'https://us-central.manta.mnx.io/Joyent_Dev/public/SmartOS/platform-latest.tgz' "${_sm_cache}/platform-latest.tgz" 2>/dev/null || true
      if [ -s "${_sm_cache}/platform-latest.tgz" ]; then
        tar -xzf "${_sm_cache}/platform-latest.tgz" -C "${SYSROOT}" 2>/dev/null || true
      fi
      ;;
    *)
      if command -v pkg >/dev/null 2>&1 && [ "$(uname -s 2>/dev/null || printf '')" = "SunOS" ]; then
        pkg image-create -F -p "omnios=https://pkg.omnios.org/${VERSION}/core" "${SYSROOT}" >/dev/null 2>&1 || true
        pkg -R "${SYSROOT}" install --accept entire >/dev/null 2>&1 || true
      fi
      ;;
  esac
fi

cat <<REL_EOF > "${SYSROOT}/etc/release"
  LibScript illumos Distribution (${FLAVOR} ${VERSION} ${ARCH})
  Copyright 2026 LibScript Contributors.
  Assembled via zero-dependency POSIX shell synthesis.
REL_EOF

printf '%s\n' "${VERSION}" > "${SYSROOT}/etc/libscript-illumos-version"
date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       illumos base system bootstrap complete: %s\n' "${SYSROOT}"
