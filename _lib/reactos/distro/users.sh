#!/bin/sh
# ## Overview
# Provisions local user accounts, Administrators group membership, and optional Winlogon
# automatic desktop login inside the ReactOS firstboot and registry delta configuration.
#
# ## Usage
# ./_lib/reactos/distro/users.sh [sysroot_path] [username] [password] [is_admin] [autologin_user]

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

SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/reactos-sysroot}}"
USER_NAME="${2:-admin}"
USER_PASS="${3:-vagrant}"
IS_ADMIN="${4:-true}"
AUTOLOGIN="${5:-}"

STAMP_DIR="${SYSROOT}/.libscript-stamps"
STAMP_FILE="${STAMP_DIR}/users.stamp"
LS_STAGE="${SYSROOT}/iso_root/libscript"

if [ -f "$STAMP_FILE" ]; then
  printf '[SKIP]     ReactOS user accounts already provisioned in %s\n' "$SYSROOT"
  exit 0
fi

mkdir -p "$STAMP_DIR" "$LS_STAGE"

if [ -n "$USER_NAME" ]; then
  printf 'net user "%s" "%s" /add >nul 2>&1\r\n' "$USER_NAME" "$USER_PASS" >> "${LS_STAGE}/firstboot.cmd"
  if [ "$IS_ADMIN" = 'true' ] || [ "$IS_ADMIN" = 'yes' ] || [ "$IS_ADMIN" = '1' ]; then
    printf 'net localgroup Administrators "%s" /add >nul 2>&1\r\n' "$USER_NAME" >> "${LS_STAGE}/firstboot.cmd"
  fi
fi

if [ -n "$AUTOLOGIN" ]; then
  cat <<ALOG_EOF >> "${LS_STAGE}/hivesft_delta.reg"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon]
"AutoAdminLogon"="1"
"DefaultUserName"="${AUTOLOGIN}"
"DefaultPassword"="${USER_PASS}"
ALOG_EOF
  awk '{ sub(/\r$/, ""); printf "%s\r\n", $0 }' "${LS_STAGE}/hivesft_delta.reg" > "${LS_STAGE}/hivesft_delta.reg.tmp"
  mv "${LS_STAGE}/hivesft_delta.reg.tmp" "${LS_STAGE}/hivesft_delta.reg"
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK]       ReactOS user provisioning configured (user=%s, autologin=%s).\n' "$USER_NAME" "${AUTOLOGIN:-none}"
