#!/bin/sh
# ## Overview
# Bootstraps the FreeBSD base system into a target sysroot directory, downloading and
# SHA-256 verifying official MANIFEST + base.txz + kernel.txz archives via libscript_download.
# ## Usage
# ./_lib/freebsd/distro/base.sh [sysroot_path] [version] [arch]

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
  printf 'Usage: %s [sysroot_path] [version] [arch]\n' "$0"
  exit 0
fi

SYSROOT="${1:-${LIBSCRIPT_ROOT_DIR}/build/freebsd-sysroot}"
VERSION="${2:-14.1-RELEASE}"
ARCH="${3:-amd64}"
case "$ARCH" in
  x86_64) ARCH='amd64'; MACHINE='amd64' ;;
  aarch64|arm64) ARCH='aarch64'; MACHINE='arm64' ;;
  *) MACHINE="$ARCH" ;;
esac

STAMP_DIR="${SYSROOT}/.libscript-stamps"
STAMP_FILE="${STAMP_DIR}/freebsd-base-${VERSION}-${ARCH}.stamp"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     FreeBSD base (%s %s) already bootstrapped at %s\n' "${VERSION}" "${ARCH}" "${SYSROOT}"
  exit 0
fi

printf '[BOOTSTRAP] Preparing FreeBSD %s (%s) sysroot at %s...\n' "${VERSION}" "${ARCH}" "${SYSROOT}"
mkdir -p "${SYSROOT}" "${STAMP_DIR}"
for _d in bin boot/kernel boot/efi dev etc/rc.conf.d lib libexec media mnt net proc rescue root sbin tmp usr/bin usr/sbin usr/local/bin usr/local/etc/pkg/repos usr/local/etc/rc.d var/db/pkg var/log var/run; do
  mkdir -p "${SYSROOT}/${_d}"
done
chmod 1777 "${SYSROOT}/tmp" 2>/dev/null || true

MIRROR="${FREEBSD_MIRROR:-https://download.freebsd.org/releases}"
CACHE_FB="${LIBSCRIPT_CACHE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache}/freebsd/${VERSION}/${ARCH}"
mkdir -p "$CACHE_FB"

if [ "${LIBSCRIPT_FETCH_FREEBSD_BASE:-0}" = "1" ] && [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mgr.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true
  _base_url="${MIRROR}/${MACHINE}/${ARCH}/${VERSION}"
  if [ ! -s "${CACHE_FB}/MANIFEST" ]; then
    libscript_download "${_base_url}/MANIFEST" "${CACHE_FB}/MANIFEST"
  fi
  for _txz in base.txz kernel.txz; do
    _exp_sha=''
    if [ -s "${CACHE_FB}/MANIFEST" ]; then
      _exp_sha=$(awk -v f="$_txz" '$1 == f {print $2}' "${CACHE_FB}/MANIFEST")
    fi
    if [ ! -s "${CACHE_FB}/${_txz}" ]; then
      libscript_download "${_base_url}/${_txz}" "${CACHE_FB}/${_txz}" "$_exp_sha"
    fi
    if command -v bsdtar >/dev/null 2>&1; then
      bsdtar -xpf "${CACHE_FB}/${_txz}" -C "$SYSROOT" 2>/dev/null || bsdtar -xf "${CACHE_FB}/${_txz}" -C "$SYSROOT"
    else
      tar -xf "${CACHE_FB}/${_txz}" -C "$SYSROOT"
    fi
  done
elif [ -s "${CACHE_FB}/base.txz" ]; then
  tar -xf "${CACHE_FB}/base.txz" -C "$SYSROOT" 2>/dev/null || true
  if [ -s "${CACHE_FB}/kernel.txz" ]; then
    tar -xf "${CACHE_FB}/kernel.txz" -C "$SYSROOT" 2>/dev/null || true
  fi
fi

printf 'FreeBSD %s (%s) - Synthesized by LibScript\n' "${VERSION}" "${ARCH}" > "${SYSROOT}/etc/motd.template"
printf '%s\n' "${VERSION}" > "${SYSROOT}/etc/libscript-freebsd-version"

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       FreeBSD base bootstrap completed.\n'
