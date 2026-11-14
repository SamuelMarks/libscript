#!/bin/sh
# ## Overview
# Orchestrates FreeBSD distribution synthesis from a JSON profile specification using jq,
# invoking base, config, pkg, users, init, display, desktop, audio, and Tier 1 components.
# ## Usage
# ./_lib/freebsd/distro/assemble.sh [profile_json_path] [target_sysroot]

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
  printf 'Usage: %s [profile_json_path] [target_sysroot]\n' "$0"
  exit 0
fi

PROFILE="${1:-${LIBSCRIPT_ROOT_DIR}/profiles/freebsd/minimal-server.json}"
SYSROOT="${2:-${LIBSCRIPT_ROOT_DIR}/build/freebsd-sysroot}"

if [ ! -f "${PROFILE}" ]; then
  printf '[ERROR] Profile not found: %s\n' "${PROFILE}" >&2
  exit 1
fi

PROFILE_NAME=$(basename "${PROFILE}" .json)
STAMP_DIR="${SYSROOT}/.libscript-stamps"
STAMP_FILE="${STAMP_DIR}/freebsd-assemble-${PROFILE_NAME}.stamp"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     FreeBSD distribution (%s) already assembled at %s\n' "${PROFILE_NAME}" "${SYSROOT}"
  exit 0
fi

mkdir -p "${STAMP_DIR}"

if command -v jq >/dev/null 2>&1; then
  FB_VER=$(jq -r '.freebsd_version // "14.1-RELEASE"' "${PROFILE}")
  ARCH=$(jq -r '.target.arch // "amd64"' "${PROFILE}")
  FS=$(jq -r '.storage.filesystem // (.storage.partitions[0].filesystem // "ufs2")' "${PROFILE}")
  HOSTNAME=$(jq -r '.network.hostname // "freebsd-node"' "${PROFILE}")
  INIT_PROV=$(jq -r '.init_system.provider // "bsd-rc"' "${PROFILE}")
  DISP_SRV=$(jq -r '.display.server // "none"' "${PROFILE}")
  COMP=$(jq -r '.display.compositor // "none"' "${PROFILE}")
  DESK=$(jq -r '.desktop.environment // (.desktop.desktop_suite // "none")' "${PROFILE}")
  DM=$(jq -r '.desktop.display_manager // (.desktop.greeter // "none")' "${PROFILE}")
  AUTOLOGIN=$(jq -r '.desktop.autologin_user // ""' "${PROFILE}")
  AUDIO_SUB=$(jq -r '.audio.subsystem // "oss"' "${PROFILE}")
  PKG_BRANCH=$(jq -r '.package_manager.branch // "quarterly"' "${PROFILE}")
else
  FB_VER='14.1-RELEASE'; ARCH='amd64'; FS='ufs2'; HOSTNAME='freebsd-node'; INIT_PROV='bsd-rc'
  DISP_SRV='none'; COMP='none'; DESK='none'; DM='none'; AUTOLOGIN=''; AUDIO_SUB='oss'; PKG_BRANCH='quarterly'
fi

printf '[ASSEMBLE] Synthesizing FreeBSD (%s) from profile %s...\n' "${FB_VER}" "${PROFILE_NAME}"
"${SCRIPT_DIR}/base.sh" "${SYSROOT}" "${FB_VER}" "${ARCH}"
"${SCRIPT_DIR}/config.sh" "${SYSROOT}" "${HOSTNAME}" "${FS}"
"${SCRIPT_DIR}/pkg.sh" "${SYSROOT}" "${PKG_BRANCH}"
"${SCRIPT_DIR}/users.sh" "${SYSROOT}" "vagrant" "vagrant" "1001" "wheel,video,operator" "yes"
"${SCRIPT_DIR}/init.sh" "${SYSROOT}" "${INIT_PROV}"
"${SCRIPT_DIR}/display.sh" "${SYSROOT}" "${DISP_SRV}" "${COMP}"
"${SCRIPT_DIR}/desktop.sh" "${SYSROOT}" "${DESK}" "vagrant"
"${SCRIPT_DIR}/dm.sh" "${SYSROOT}" "${DM}" "${AUTOLOGIN}"
"${SCRIPT_DIR}/audio.sh" "${SYSROOT}" "${AUDIO_SUB}"

# Stage requested LibScript Tier 1 components into FreeBSD sysroot
if command -v jq >/dev/null 2>&1; then
  _comps=$(jq -r '((.components // []) + (.packages // []))[]?' "${PROFILE}" 2>/dev/null || true)
  for _c in $_comps; do
    [ -n "$_c" ] || continue
    if [ -d "${LIBSCRIPT_ROOT_DIR}/_lib" ] && find "${LIBSCRIPT_ROOT_DIR}/_lib" -mindepth 2 -maxdepth 2 -type d -name "$_c" | grep -q .; then
      LIBSCRIPT_TARGET_SYSROOT="${SYSROOT}" LIBSCRIPT_TARGET_OS='freebsd' LIBSCRIPT_IMAGE_BUILD='1' STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install "$_c" latest || true
    fi
  done
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       FreeBSD distribution assembly complete for %s.\n' "${PROFILE_NAME}"
