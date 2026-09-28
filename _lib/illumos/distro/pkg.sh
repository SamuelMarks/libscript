#!/bin/sh
# ## Overview
# Configures illumos package managers (IPS pkg(1), Joyent pkgin/pkgsrc, or Tribblix zap)
# and stages publisher authorities and repositories inside the target sysroot.
#
# ## Usage
# Configure package manager:
#   _lib/illumos/distro/pkg.sh [sysroot_path] [provider] [publisher_url]

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
PROVIDER="${2:-ips}"
PUB_URL="${3:-https://pkg.omnios.org/r151048/core}"

STAMP_DIR="${SYSROOT}/.libscript_stamps"
STAMP_FILE="${STAMP_DIR}/pkg.stamp"

mkdir -p "${STAMP_DIR}"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     illumos package manager already configured in %s
' "${SYSROOT}"
  exit 0
fi

printf '[PKG]      Configuring illumos package manager (%s, publisher: %s)...
' "${PROVIDER}" "${PUB_URL}"

case "${PROVIDER}" in
  ips)
    mkdir -p "${SYSROOT}/var/pkg" "${SYSROOT}/etc/pkg"
    cat << EOF > "${SYSROOT}/etc/pkg/publishers.conf"
# IPS Package Publisher Configuration (managed by LibScript)
[publisher]
prefix = omnios
uri = ${PUB_URL}
sticky = true
enabled = true
EOF
    cat << EOF > "${SYSROOT}/etc/pkg/setup_publisher.sh"
#!/bin/sh
# Helper to apply publisher via pkg(1) inside guest
pkg set-publisher -g "${PUB_URL}" -s omnios 2>/dev/null || true
pkg refresh --full 2>/dev/null || true
EOF
    chmod +x "${SYSROOT}/etc/pkg/setup_publisher.sh" 2>/dev/null || true
    ;;

  pkgin|pkgsrc)
    mkdir -p "${SYSROOT}/opt/local/etc/pkgin"
    cat << EOF > "${SYSROOT}/opt/local/etc/pkgin/repositories.conf"
# Joyent / SmartOS pkgin repository catalog (managed by LibScript)
${PUB_URL}
EOF
    ;;

  zap)
    mkdir -p "${SYSROOT}/etc/zap"
    cat << EOF > "${SYSROOT}/etc/zap/zap.conf"
# Tribblix zap package manager configuration (managed by LibScript)
ZAP_URL="${PUB_URL}"
ZAP_CATALOG="main"
EOF
    ;;

  *)
    printf '[WARN]     Unknown package provider: %s
' "${PROVIDER}" >&2
    ;;
esac

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"

printf '[OK]       illumos package manager configuration complete: %s
' "${SYSROOT}"
