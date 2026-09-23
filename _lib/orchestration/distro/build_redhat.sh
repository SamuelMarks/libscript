#!/bin/sh
# ## Overview
# Executes the end-to-end Red Hat-inspired distribution synthesis pipeline:
# bootstrapping Glibc/coreutils, RPM database and DNF toolchain, synthesizing
# RPM binary packages, generating repodata, and configuring target rootfs.
#
# ## Usage
# ./_lib/orchestration/distro/build_redhat.sh [--target-rootfs=<path>] [--profile=<profile.json>]

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
export LIBSCRIPT_ROOT_DIR

TARGET_ROOTFS="${LIBSCRIPT_TARGET_ROOTFS:-${LIBSCRIPT_ROOT_DIR}/build/rootfs_redhat}"
PROFILE="${LIBSCRIPT_PROFILE:-${LIBSCRIPT_ROOT_DIR}/profiles/linux-redhat-style-server.json}"

while [ $# -gt 0 ]; do
  case "$1" in
    --target-rootfs=*) TARGET_ROOTFS="${1#*=}"; shift ;;
    --profile=*) PROFILE="${1#*=}"; shift ;;
    *) shift ;;
  esac
done

printf '[DISTRO-REDHAT] Initializing Red Hat-inspired distribution synthesis pipeline...
'
printf '[DISTRO-REDHAT] Target rootfs: %s
' "$TARGET_ROOTFS"
printf '[DISTRO-REDHAT] Profile: %s
' "$PROFILE"

mkdir -p "$TARGET_ROOTFS"

STAMP_FILE="${TARGET_ROOTFS}/.redhat_distro_built"
if [ -f "$STAMP_FILE" ]; then
  printf '[IDEMPOTENT] Red Hat distribution already synthesized at: %s
' "$TARGET_ROOTFS"
  exit 0
fi

# Phase 1: Glibc & Foundation Bootstrap
printf '[DISTRO-REDHAT] Phase 1: Creating FHS directory layout...
'
"${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/create_fhs_layout.sh" "$TARGET_ROOTFS"

# Phase 2: RPM & DNF Toolchain Native Bootstrap
printf '[DISTRO-REDHAT] Phase 2: Initializing RPM database and DNF repository configs...
'
mkdir -p "$TARGET_ROOTFS/var/lib/rpm" "$TARGET_ROOTFS/etc/yum.repos.d" "$TARGET_ROOTFS/etc/dnf"

if command -v rpm >/dev/null 2>&1; then
  rpm --root="$TARGET_ROOTFS" --initdb 2>/dev/null || true
fi

cat <<EOF > "$TARGET_ROOTFS/etc/dnf/dnf.conf"
[main]
gpgcheck=1
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
EOF

cat <<EOF > "$TARGET_ROOTFS/etc/yum.repos.d/libscript.repo"
[libscript-base]
name=LibScript Distribution Base
baseurl=file:///var/lib/libscript/repo/rpm
enabled=1
gpgcheck=0
EOF

# Phase 3 & 4: Package Synthesis & YUM Repository Generation
printf '[DISTRO-REDHAT] Phase 3 & 4: Generating base RPM packages and repodata...
'
PACKAGES_OUT="${LIBSCRIPT_ROOT_DIR}/build/packages/rpm"
mkdir -p "$PACKAGES_OUT"

"${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/packagers/build_rpm.sh" "redhat-release" "9.4" "$TARGET_ROOTFS" "$PACKAGES_OUT"
"${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/repogen/rpm_index.sh" "$PACKAGES_OUT"

# Phase 5: Target Rootfs Registration
printf '[DISTRO-REDHAT] Phase 5: Finalizing Red Hat system identity...
'
cat <<EOF > "$TARGET_ROOTFS/etc/os-release"
NAME="LibScript Enterprise Linux (Red Hat-style)"
ID=rhel
ID_LIKE=fedora
VERSION_ID="9.4"
PRETTY_NAME="LibScript Enterprise Linux 9.4"
HOME_URL="https://github.com/libscript/libscript"
EOF

cat <<EOF > "$TARGET_ROOTFS/etc/redhat-release"
LibScript Enterprise Linux release 9.4
EOF

touch "$STAMP_FILE"
printf '[OK] Red Hat-inspired distribution synthesis complete at: %s
' "$TARGET_ROOTFS"
exit 0
