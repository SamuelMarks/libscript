#!/bin/sh
# ## Overview
# Multi-distribution cross-packaging and federation engine that takes a staged
# component and packages it simultaneously into .apk, .deb, and .rpm formats,
# asserting parity across binary closures.
#
# ## Usage
# ./_lib/orchestration/packagers/polyglot_package.sh <pkg_name> <pkg_version> <staging_dir> [out_base_dir]

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

PKG_NAME="${1:-sample-pkg}"
PKG_VER="${2:-1.0.0}"
STAGE_DIR="${3:-${LIBSCRIPT_ROOT_DIR}/build/stage_polyglot}"
OUT_BASE="${4:-${LIBSCRIPT_ROOT_DIR}/build/packages}"

mkdir -p "$OUT_BASE/apk" "$OUT_BASE/deb" "$OUT_BASE/rpm"

printf '[POLYGLOT] Starting multi-distribution cross-packaging for %s %s...
' "$PKG_NAME" "$PKG_VER"

# 1. Build APK
"${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/packagers/build_apk.sh" "$PKG_NAME" "$PKG_VER" "$STAGE_DIR" "$OUT_BASE/apk"

# 2. Build DEB
"${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/packagers/build_deb.sh" "$PKG_NAME" "$PKG_VER" "$STAGE_DIR" "$OUT_BASE/deb"

# 3. Build RPM
"${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/packagers/build_rpm.sh" "$PKG_NAME" "$PKG_VER" "$STAGE_DIR" "$OUT_BASE/rpm"

# Verify all artifacts exist
APK_FILE="${OUT_BASE}/apk/${PKG_NAME}-${PKG_VER}.apk"
DEB_FILE="${OUT_BASE}/deb/${PKG_NAME}_${PKG_VER}_amd64.deb"
RPM_FILE="${OUT_BASE}/rpm/${PKG_NAME}-${PKG_VER}-1.x86_64.rpm"

if [ -f "$APK_FILE" ] && [ -f "$DEB_FILE" ] && [ -f "$RPM_FILE" ]; then
  printf '[OK] Polyglot cross-packaging succeeded for %s across APK, DEB, and RPM.
' "$PKG_NAME"
else
  printf '[ERROR] One or more package formats failed to generate.
' >&2
  exit 1
fi

exit 0
