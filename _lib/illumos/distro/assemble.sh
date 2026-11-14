#!/bin/sh
# ## Overview
# Orchestrates illumos modular distribution synthesis from a JSON profile specification using jq,
# invoking base, zfs, config, pkg, users, init, display, desktop, dm, audio, and Tier 1 components.
# ## Usage
# ./_lib/illumos/distro/assemble.sh [profile_json] [target_sysroot]

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
  printf 'Usage: %s [profile_json] [target_sysroot]\n' "$0"
  exit 0
fi

PROFILE="${1:-${LIBSCRIPT_ROOT_DIR}/profiles/illumos/minimal-server.json}"
SYSROOT="${2:-${LIBSCRIPT_ROOT_DIR}/build/illumos-sysroot}"

if [ ! -f "${PROFILE}" ]; then
  printf '[ERROR] Profile JSON not found: %s\n' "${PROFILE}" >&2
  exit 1
fi

PROFILE_BASE=$(basename "${PROFILE}" .json)
STAMP_DIR="${SYSROOT}/.libscript-stamps"
STAMP_FILE="${STAMP_DIR}/illumos-assemble-${PROFILE_BASE}.stamp"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     illumos profile (%s) already assembled at %s\n' "${PROFILE_BASE}" "${SYSROOT}"
  exit 0
fi

mkdir -p "${STAMP_DIR}"

if command -v jq >/dev/null 2>&1; then
  ILLUMOS_VER=$(jq -r '.illumos_version // "r151048"' "${PROFILE}")
  ARCH=$(jq -r '.target.arch // "amd64"' "${PROFILE}")
  FLAVOR=$(jq -r '.target.flavor // "omnios"' "${PROFILE}")
  POOL_NAME=$(jq -r '.storage.pool_name // "rpool"' "${PROFILE}")
  COMPRESSION=$(jq -r '.storage.compression // "lz4"' "${PROFILE}")
  HOSTNAME=$(jq -r '.network.hostname // "illumos-node"' "${PROFILE}")
  INIT_PROV=$(jq -r '.init_system.provider // "smf"' "${PROFILE}")
  PKG_PROV=$(jq -r '.package_manager.provider // "ips"' "${PROFILE}")
  DISP_SRV=$(jq -r '.display.server // "none"' "${PROFILE}")
  DISP_COMP=$(jq -r '.display.compositor // "none"' "${PROFILE}")
  DESK_ENV=$(jq -r '.desktop.environment // "none"' "${PROFILE}")
  DM_GREETER=$(jq -r '.desktop.display_manager // "none"' "${PROFILE}")
  AUTOLOGIN=$(jq -r '.desktop.autologin_user // ""' "${PROFILE}")
  AUDIO_SUB=$(jq -r '.audio.subsystem // "none"' "${PROFILE}")
else
  ILLUMOS_VER='r151048'; ARCH='amd64'; FLAVOR='omnios'; POOL_NAME='rpool'; COMPRESSION='lz4'
  HOSTNAME='illumos-node'; INIT_PROV='smf'; PKG_PROV='ips'; DISP_SRV='none'; DISP_COMP='none'
  DESK_ENV='none'; DM_GREETER='none'; AUTOLOGIN=''; AUDIO_SUB='none'
fi

printf '[ASSEMBLE] Building illumos (%s, flavor=%s) from profile: %s...\n' "${ILLUMOS_VER}" "${FLAVOR}" "${PROFILE_BASE}"

"${SCRIPT_DIR}/base.sh" "${SYSROOT}" "${ILLUMOS_VER}" "${ARCH}" "${FLAVOR}"
"${SCRIPT_DIR}/zfs.sh" "${SYSROOT}" "${POOL_NAME}" "${COMPRESSION}"
"${SCRIPT_DIR}/config.sh" "${SYSROOT}" "${HOSTNAME}" "UTC"
"${SCRIPT_DIR}/pkg.sh" "${SYSROOT}" "${PKG_PROV}"
"${SCRIPT_DIR}/users.sh" "${SYSROOT}" "vagrant" "vagrant" "1000" "yes"
"${SCRIPT_DIR}/init.sh" "${SYSROOT}" "${INIT_PROV}"
"${SCRIPT_DIR}/display.sh" "${SYSROOT}" "${DISP_SRV}" "${DISP_COMP}"
"${SCRIPT_DIR}/desktop.sh" "${SYSROOT}" "${DESK_ENV}" "vagrant"
"${SCRIPT_DIR}/dm.sh" "${SYSROOT}" "${DM_GREETER}" "${AUTOLOGIN}"
"${SCRIPT_DIR}/audio.sh" "${SYSROOT}" "${AUDIO_SUB}"

if command -v jq >/dev/null 2>&1; then
  _comps=$(jq -r '((.components // []) + (.packages // []))[]?' "${PROFILE}" 2>/dev/null || true)
  for _c in $_comps; do
    [ -n "$_c" ] || continue
    case "$_c" in
      pkg:/*) continue ;;
    esac
    if find "${LIBSCRIPT_ROOT_DIR}/_lib" -mindepth 2 -maxdepth 2 -type d -name "$_c" | grep -q .; then
      LIBSCRIPT_TARGET_SYSROOT="${SYSROOT}" LIBSCRIPT_TARGET_OS='sunos' LIBSCRIPT_IMAGE_BUILD='1' STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install "$_c" latest || true
    fi
  done
fi

cat <<PROF_EOF > "${SYSROOT}/etc/libscript-profile.conf"
profile=${PROFILE_BASE}
version=${ILLUMOS_VER}
flavor=${FLAVOR}
arch=${ARCH}
init_system=${INIT_PROV}
package_manager=${PKG_PROV}
display=${DISP_SRV}
desktop=${DESK_ENV}
dm=${DM_GREETER}
audio=${AUDIO_SUB}
assembled_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
PROF_EOF

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       illumos distribution synthesized successfully: %s\n' "${SYSROOT}"
