#!/bin/sh
# ## Overview
# Configures pkg(8) package manager configuration, repository mirrors,
# and offline package cache integration in FreeBSD target sysroot.
#
# ## Usage
# Configure package repository:
#   _lib/freebsd/distro/pkg.sh [sysroot_path] [branch]
#
# Environment variables:
#   LIBSCRIPT_OFFLINE  Set to 1 for offline operation

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
BRANCH="${2:-quarterly}"

STAMP_DIR="${SYSROOT}/.libscript_stamps"
STAMP_FILE="${STAMP_DIR}/pkg.stamp"

mkdir -p "${STAMP_DIR}"
mkdir -p "${SYSROOT}/usr/local/etc/pkg/repos"
mkdir -p "${SYSROOT}/var/db/pkg"
mkdir -p "${SYSROOT}/var/cache/pkg"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     FreeBSD pkg repository already configured in %s
' "${SYSROOT}"
  exit 0
fi

printf '[PKG]      Configuring FreeBSD pkg repository (%s branch)...
' "${BRANCH}"

# Write FreeBSD.conf
cat << EOF > "${SYSROOT}/usr/local/etc/pkg/repos/FreeBSD.conf"
FreeBSD: {
  url: "pkg+http://pkg.FreeBSD.org/\${ABI}/${BRANCH}",
  mirror_type: "srv",
  signature_type: "fingerprints",
  fingerprints: "/usr/share/keys/pkg",
  enabled: yes
}
EOF

# Write pkg.conf
cat << 'EOF' > "${SYSROOT}/usr/local/etc/pkg.conf"
PKG_DBDIR = "/var/db/pkg";
PKG_CACHEDIR = "/var/cache/pkg";
PORTSDIR = "/usr/ports";
REPO_AUTOUPDATE = YES;
ALIAS {
  all-depends = "query %dn-%dv";
  annotations = "info -A";
  build-depends = "info -qd";
  cinfo = "info -Cx";
  comment = "query -i "%c"";
  desc = "query -i "%e"";
  download = "fetch";
  iinfo = "info -ix";
  installed = "info -q";
  leaf = "query -e "%#r == 0" "%n-%v"";
  list = "info -ql";
  no-repo = "info -rx";
  origin = "info -qo";
  provided-depends = "info -qb";
  raw = "info -R";
  required-depends = "info -qr";
  roptions = "rquery -i "%Ok: %Ov"";
  shared-depends = "info -qB";
  show = "info -f -k";
  size = "info -sq";
  unneeded = "query -e "%#r == 0 && %a == 1" "%n-%v"";
  version = "version -v";
}
EOF

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       FreeBSD pkg configuration complete.
'
