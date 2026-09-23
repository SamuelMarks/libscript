#!/bin/sh
# ## Overview
# Executes the end-to-end Debian-style distribution synthesis pipeline:
# bootstrapping Stage 0 toolchain, dpkg/apt subsystem, package synthesis (.deb),
# signed APT repository generation, and clean target rootfs deployment.
#
# ## Usage
# ./_lib/orchestration/distro/build_debian.sh [--target-rootfs=<path>] [--profile=<profile.json>]

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

TARGET_ROOTFS="${LIBSCRIPT_TARGET_ROOTFS:-${LIBSCRIPT_ROOT_DIR}/build/rootfs_debian}"
PROFILE="${LIBSCRIPT_PROFILE:-${LIBSCRIPT_ROOT_DIR}/profiles/linux-debian-style-server.json}"

while [ $# -gt 0 ]; do
  case "$1" in
    --target-rootfs=*) TARGET_ROOTFS="${1#*=}"; shift ;;
    --profile=*) PROFILE="${1#*=}"; shift ;;
    *) shift ;;
  esac
done

printf '[DISTRO-DEBIAN] Initializing Debian-style distribution synthesis pipeline...
'
printf '[DISTRO-DEBIAN] Target rootfs: %s
' "$TARGET_ROOTFS"
printf '[DISTRO-DEBIAN] Profile: %s
' "$PROFILE"

mkdir -p "$TARGET_ROOTFS"

STAMP_FILE="${TARGET_ROOTFS}/.debian_distro_built"
if [ -f "$STAMP_FILE" ]; then
  printf '[IDEMPOTENT] Debian distribution already synthesized at: %s
' "$TARGET_ROOTFS"
  exit 0
fi

# Phase 1: Toolchain & Sysroot Bootstrap (FHS Layout)
printf '[DISTRO-DEBIAN] Phase 1: Creating FHS layout and system skeleton...
'
"${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/create_fhs_layout.sh" "$TARGET_ROOTFS"

# Phase 2: Dpkg & APT Toolchain Setup
printf '[DISTRO-DEBIAN] Phase 2: Bootstrapping dpkg and apt administrative state...
'
mkdir -p "$TARGET_ROOTFS/var/lib/dpkg/info" "$TARGET_ROOTFS/var/lib/dpkg/updates" "$TARGET_ROOTFS/var/lib/dpkg/alternatives" "$TARGET_ROOTFS/etc/apt/sources.list.d" "$TARGET_ROOTFS/etc/apt/apt.conf.d" "$TARGET_ROOTFS/etc/apt/trusted.gpg.d"

touch "$TARGET_ROOTFS/var/lib/dpkg/status" "$TARGET_ROOTFS/var/lib/dpkg/available"

cat <<EOF > "$TARGET_ROOTFS/etc/apt/sources.list"
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
EOF

cat <<EOF > "$TARGET_ROOTFS/etc/apt/apt.conf.d/01libscript"
APT::Install-Recommends "0";
APT::Install-Suggests "0";
APT::Sandbox::User "root";
EOF

# Phase 3 & 4: Package Synthesis & Repository Generation
printf '[DISTRO-DEBIAN] Phase 3 & 4: Generating base distribution packages and APT repository...
'
PACKAGES_OUT="${LIBSCRIPT_ROOT_DIR}/build/packages/deb"
mkdir -p "$PACKAGES_OUT"

"${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/packagers/build_deb.sh" "base-files" "12.4" "$TARGET_ROOTFS" "$PACKAGES_OUT"
"${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/repogen/deb_index.sh" "$PACKAGES_OUT" "bookworm" "amd64" "main"

# Phase 5: Target Rootfs Installation via Dpkg Status Registration
printf '[DISTRO-DEBIAN] Phase 5: Finalizing package manager status database...
'
cat <<EOF >> "$TARGET_ROOTFS/var/lib/dpkg/status"
Package: base-files
Status: install ok installed
Priority: required
Section: admin
Installed-Size: 10
Maintainer: LibScript OS Synthesizer <libscript@local>
Architecture: amd64
Version: 12.4
Description: LibScript Debian Base System Files
 Core filesystem architecture and os-release identification.

EOF

cat <<EOF > "$TARGET_ROOTFS/etc/os-release"
NAME="LibScript GNU/Linux (Debian-style)"
ID=debian
ID_LIKE=libscript
VERSION_ID="12"
VERSION="12 (Bookworm Synthesized)"
PRETTY_NAME="LibScript Debian-style GNU/Linux"
HOME_URL="https://github.com/libscript/libscript"
EOF

touch "$STAMP_FILE"
printf '[OK] Debian-style distribution synthesis complete at: %s
' "$TARGET_ROOTFS"
exit 0
