#!/bin/sh
# ## Overview
# Executes the end-to-end Alpine Linux-style distribution synthesis pipeline:
# bootstrapping Musl/BusyBox runtime, apk-tools package manager, APK binary
# package synthesis, signed APKINDEX repository generation, and clean rootfs deployment.
#
# ## Usage
# ./_lib/orchestration/distro/build_alpine.sh [--target-rootfs=<path>] [--profile=<profile.json>]

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

TARGET_ROOTFS="${LIBSCRIPT_TARGET_ROOTFS:-${LIBSCRIPT_ROOT_DIR}/build/rootfs_alpine}"
PROFILE="${LIBSCRIPT_PROFILE:-${LIBSCRIPT_ROOT_DIR}/profiles/linux-alpine-style-standard.json}"

while [ $# -gt 0 ]; do
  case "$1" in
    --target-rootfs=*) TARGET_ROOTFS="${1#*=}"; shift ;;
    --profile=*) PROFILE="${1#*=}"; shift ;;
    *) shift ;;
  esac
done

printf '[DISTRO-ALPINE] Initializing Alpine Linux-style distribution synthesis pipeline...
'
printf '[DISTRO-ALPINE] Target rootfs: %s
' "$TARGET_ROOTFS"
printf '[DISTRO-ALPINE] Profile: %s
' "$PROFILE"

mkdir -p "$TARGET_ROOTFS"

STAMP_FILE="${TARGET_ROOTFS}/.alpine_distro_built"
if [ -f "$STAMP_FILE" ]; then
  printf '[IDEMPOTENT] Alpine distribution already synthesized at: %s
' "$TARGET_ROOTFS"
  exit 0
fi

# Phase 1: Musl & BusyBox Bootstrap
printf '[DISTRO-ALPINE] Phase 1: Creating FHS directory layout and BusyBox links...
'
"${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/create_fhs_layout.sh" "$TARGET_ROOTFS"

# Phase 2: Apk-Tools Configuration
printf '[DISTRO-ALPINE] Phase 2: Initializing apk-tools directories and repositories...
'
mkdir -p "$TARGET_ROOTFS/etc/apk/keys" "$TARGET_ROOTFS/lib/apk/db" "$TARGET_ROOTFS/var/cache/apk"

cat <<EOF > "$TARGET_ROOTFS/etc/apk/repositories"
https://dl-cdn.alpinelinux.org/alpine/v3.20/main
https://dl-cdn.alpinelinux.org/alpine/v3.20/community
EOF

cat <<EOF > "$TARGET_ROOTFS/etc/apk/world"
alpine-base
busybox
openrc
EOF

# Phase 3 & 4: Package Synthesis & Repository Indexing
printf '[DISTRO-ALPINE] Phase 3 & 4: Generating base APK packages and APKINDEX...
'
PACKAGES_OUT="${LIBSCRIPT_ROOT_DIR}/build/packages/apk"
mkdir -p "$PACKAGES_OUT"

"${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/packagers/build_apk.sh" "alpine-base" "3.20.0" "$TARGET_ROOTFS" "$PACKAGES_OUT"
"${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/repogen/apk_index.sh" "$PACKAGES_OUT" "x86_64" "v3.20"

# Phase 5: Target Rootfs Installation via APK DB Registration
printf '[DISTRO-ALPINE] Phase 5: Registering installed packages in APK database...
'
cat <<EOF > "$TARGET_ROOTFS/lib/apk/db/installed"
C:Q1dummyhash
P:alpine-base
V:3.20.0
A:x86_64
S:4096
I:4096
T:Alpine Base Meta Package
U:https://alpinelinux.org
L:MIT
o:alpine-base
m:LibScript Maintainer <libscript@local>
t:1700000000
c:none
D:busybox openrc
p:alpine-base=3.20.0

EOF

cat <<EOF > "$TARGET_ROOTFS/etc/os-release"
NAME="LibScript Alpine Linux"
ID=alpine
ID_LIKE=libscript
VERSION_ID="3.20.0"
PRETTY_NAME="LibScript Alpine-style Linux v3.20"
HOME_URL="https://github.com/libscript/libscript"
EOF

touch "$STAMP_FILE"
printf '[OK] Alpine Linux-style distribution synthesis complete at: %s
' "$TARGET_ROOTFS"
exit 0
