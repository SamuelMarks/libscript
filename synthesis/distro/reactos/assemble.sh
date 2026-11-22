#!/bin/sh
# ## Overview
# Master ReactOS modular distribution synthesizer.
# Validates a JSON profile against synthesis/schemas/execution-plan.reactos.schema.json and orchestrates
# base/from-source, filesystem, unattend, config, pkg, users, init, display, desktop, and audio stages.
#
# ## Usage
# ./synthesis/distro/reactos/assemble.sh [profile_json_path] [target_sysroot]

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

if [ "${1:-}" = '--help' ] || [ "${1:-}" = '-h' ]; then
  printf 'Usage: %s [profile_json_path] [target_sysroot]\n' "$THIS_FILE"
  exit 0
fi

PROFILE="${1:-${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/reactos/minimal-headless-i686.json}"
SYSROOT="${2:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/reactos-sysroot}}"

if [ ! -f "$PROFILE" ]; then
  printf '[ERROR] ReactOS profile not found: %s\n' "$PROFILE" >&2
  exit 1
fi

PROFILE_BASE="${PROFILE##*/}"
PROFILE_NAME="${PROFILE_BASE%.json}"
if command -v jq >/dev/null 2>&1; then
  _jq_pname=$(jq -r '.profile_name // empty' "$PROFILE" 2>/dev/null || true)
  [ -n "$_jq_pname" ] && PROFILE_NAME="$_jq_pname"
fi

STAMP_DIR="${SYSROOT}/.libscript-stamps"
STAMP_FILE="${STAMP_DIR}/reactos-assemble-${PROFILE_NAME}.stamp"

if [ -f "$STAMP_FILE" ]; then
  printf '[SKIP]     ReactOS profile (%s) already assembled at %s\n' "$PROFILE_NAME" "$SYSROOT"
  exit 0
fi

mkdir -p "$STAMP_DIR"

# Validate required fields against synthesis/schemas/execution-plan.reactos.schema.json
REACTOS_SCHEMA="${LIBSCRIPT_ROOT_DIR}/synthesis/schemas/execution-plan.reactos.schema.json"
if command -v jq >/dev/null 2>&1 && [ -f "$REACTOS_SCHEMA" ]; then
  _missing=$(jq -r --slurpfile s "$REACTOS_SCHEMA" '($s[0].required // []) - keys | .[]' "$PROFILE" 2>/dev/null || true)
  if [ -n "$_missing" ]; then
    printf '[ERROR] Profile %s missing required ReactOS schema fields: %s\n' "$PROFILE" "$_missing" >&2
    exit 1
  fi
fi

REACTOS_VER='0.4.16'
BUILD_MODE="${REACTOS_BUILD_FROM_SOURCE:-repack}"
[ "$BUILD_MODE" = '1' ] && BUILD_MODE='from-source'
[ "$BUILD_MODE" = '0' ] && BUILD_MODE='repack'
ARCH='i686'
VARIANT='bootcd'
FS_TYPE='fat32'
SERIAL_DBG='true'
COMP_NAME='REACTOS-NODE'
ADMIN_PASS=''
LOCALE_ID='00000409'
TZ_INDEX='85'
GUI_ONCE=''
HOSTNAME_VAL='REACTOS-NODE'
USE_DHCP='true'
DNS_CSV='1.1.1.1,8.8.8.8'
RAPPS_CSV=''
MSI_CSV=''
COMP_CSV=''
USER_NAME='admin'
USER_PASS='vagrant'
USER_ADMIN='true'
AUTOLOGIN=''
INIT_PROV='nt-scm'
SVC_EN='dhcp,eventlog,rpcss,umpnpmgr'
SVC_DIS=''
DISP_PROTO='win32-gdi'
DISP_DRV='vbemp'
DISP_RES='1024x768x32'
DESK_SHELL='explorer-classic'
DESK_THEME='classic'
DESK_CUSTOM=''
AUDIO_SUB='none'

if command -v jq >/dev/null 2>&1; then
  REACTOS_VER=$(jq -r '.reactos_version // "0.4.16"' "$PROFILE")
  if [ "${REACTOS_BUILD_FROM_SOURCE:-0}" != '1' ]; then
    BUILD_MODE=$(jq -r '.build_mode // "repack"' "$PROFILE")
  fi
  ARCH=$(jq -r '.target.arch // "i686"' "$PROFILE")
  VARIANT=$(jq -r '.target.image_variant // "bootcd"' "$PROFILE")
  FS_TYPE=$(jq -r '.storage.filesystem // "fat32"' "$PROFILE")
  SERIAL_DBG=$(jq -r 'if .storage.serial_debug == false then "false" else "true" end' "$PROFILE")
  COMP_NAME=$(jq -r '.unattend.computer_name // .network.hostname // "REACTOS-NODE"' "$PROFILE")
  ADMIN_PASS=$(jq -r '.unattend.admin_password // ""' "$PROFILE")
  LOCALE_ID=$(jq -r '.unattend.locale_id // "00000409"' "$PROFILE")
  TZ_INDEX=$(jq -r '.unattend.time_zone_index // 85' "$PROFILE")
  GUI_ONCE=$(jq -r '(.unattend.gui_run_once // []) | join(";")' "$PROFILE")
  HOSTNAME_VAL=$(jq -r '.network.hostname // .unattend.computer_name // "REACTOS-NODE"' "$PROFILE")
  USE_DHCP=$(jq -r 'if .network.dhcp == false then "false" else "true" end' "$PROFILE")
  DNS_CSV=$(jq -r 'if (.network.dns_servers // [] | length) > 0 then (.network.dns_servers | join(",")) else "1.1.1.1,8.8.8.8" end' "$PROFILE")
  RAPPS_CSV=$(jq -r '(.rapps_packages // []) | join(",")' "$PROFILE")
  MSI_CSV=$(jq -r '(.msi_packages // []) | join(",")' "$PROFILE")
  COMP_CSV=$(jq -r '((.components // []) + (.packages // [])) | unique | join(",")' "$PROFILE")
  USER_NAME=$(jq -r '(.users[0].username // "admin")' "$PROFILE")
  USER_PASS=$(jq -r '(.users[0].password // "vagrant")' "$PROFILE")
  USER_ADMIN=$(jq -r 'if .users[0].admin == false then "false" else "true" end' "$PROFILE")
  AUTOLOGIN=$(jq -r '.desktop.autologin_user // ""' "$PROFILE")
  INIT_PROV=$(jq -r '.init_system.provider // "nt-scm"' "$PROFILE")
  SVC_EN=$(jq -r 'if (.init_system.services_enabled // [] | length) > 0 then (.init_system.services_enabled | join(",")) else "dhcp,eventlog,rpcss,umpnpmgr" end' "$PROFILE")
  SVC_DIS=$(jq -r '(.init_system.services_disabled // []) | join(",")' "$PROFILE")
  DISP_PROTO=$(jq -r '.display.protocol // "win32-gdi"' "$PROFILE")
  DISP_DRV=$(jq -r '.display.graphics_driver // "vbemp"' "$PROFILE")
  DISP_RES=$(jq -r '.display.resolution // "1024x768x32"' "$PROFILE")
  DESK_SHELL=$(jq -r '.desktop.shell // "explorer-classic"' "$PROFILE")
  DESK_THEME=$(jq -r '.desktop.theme // "classic"' "$PROFILE")
  DESK_CUSTOM=$(jq -r '.desktop.custom_shell_path // ""' "$PROFILE")
  AUDIO_SUB=$(jq -r '.audio.subsystem // "none"' "$PROFILE")
fi

printf '[ASSEMBLE] Synthesizing ReactOS %s (%s, mode=%s) for profile %s...\n' "$REACTOS_VER" "$ARCH" "$BUILD_MODE" "$PROFILE_NAME"

if [ "$BUILD_MODE" = 'from-source' ]; then
  LIBSCRIPT_TARGET_SYSROOT="$SYSROOT" LIBSCRIPT_TARGET_ARCH="$ARCH" REACTOS_VERSION="$REACTOS_VER" \
    STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/reactos-base/setup.sh" --allow-stub --from-source install
else
  STACK='' "${SCRIPT_DIR}/base.sh" --allow-stub "$SYSROOT" "$REACTOS_VER" "$ARCH" "$VARIANT"
fi

STACK='' "${SCRIPT_DIR}/filesystem.sh" "$SYSROOT" "$FS_TYPE" "$SERIAL_DBG"
STACK='' "${SCRIPT_DIR}/unattend.sh" "$SYSROOT" "$COMP_NAME" "$ADMIN_PASS" "$LOCALE_ID" "$TZ_INDEX" "$FS_TYPE" "$GUI_ONCE"
STACK='' "${SCRIPT_DIR}/config.sh" "$SYSROOT" "$HOSTNAME_VAL" "$USE_DHCP" "$DNS_CSV"
STACK='' "${SCRIPT_DIR}/pkg.sh" "$SYSROOT" "$ARCH" "$RAPPS_CSV" "$MSI_CSV" "$COMP_CSV"
STACK='' "${SCRIPT_DIR}/users.sh" "$SYSROOT" "$USER_NAME" "$USER_PASS" "$USER_ADMIN" "$AUTOLOGIN"
STACK='' "${SCRIPT_DIR}/init.sh" "$SYSROOT" "$INIT_PROV" "$SVC_EN" "$SVC_DIS"
STACK='' "${SCRIPT_DIR}/display.sh" "$SYSROOT" "$DISP_PROTO" "$DISP_DRV" "$DISP_RES"
STACK='' "${SCRIPT_DIR}/desktop.sh" "$SYSROOT" "$DESK_SHELL" "$DESK_THEME" "$DESK_CUSTOM"
STACK='' "${SCRIPT_DIR}/audio.sh" "$SYSROOT" "$AUDIO_SUB"

# Finalize firstboot.cmd idempotent completion marker
if ! grep -q 'LIBSCRIPT-FIRSTBOOT-READY' "${SYSROOT}/iso_root/libscript/firstboot.cmd" 2>/dev/null; then
  {
    printf 'echo done> "!_SD!\\libscript\\.firstboot.done"\r\n'
    printf 'echo [LIBSCRIPT-FIRSTBOOT-READY] ReactOS provisioning complete.\r\n'
    printf 'exit /b 0\r\n'
  } >> "${SYSROOT}/iso_root/libscript/firstboot.cmd"
fi

cat <<META_EOF > "${SYSROOT}/iso_root/libscript/profile.meta"
profile_name=${PROFILE_NAME}
reactos_version=${REACTOS_VER}
arch=${ARCH}
filesystem=${FS_TYPE}
shell=${DESK_SHELL}
assembled_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
META_EOF

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK]       ReactOS distribution assembly complete for %s: %s\n' "$PROFILE_NAME" "$SYSROOT"
