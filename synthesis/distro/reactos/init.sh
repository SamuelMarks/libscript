#!/bin/sh
# ## Overview
# Configures NT Service Control Manager (nt-scm / services.exe) daemon startup states
# in the ReactOS firstboot runner and service manifest.
#
# ## Usage
# ./synthesis/distro/reactos/init.sh [sysroot_path] [provider] [services_enabled_csv] [services_disabled_csv]

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
PROVIDER="${2:-nt-scm}"
ENABLED_CSV="${3:-dhcp,eventlog,rpcss,umpnpmgr}"
DISABLED_CSV="${4:-}"

STAMP_DIR="${SYSROOT}/.libscript-stamps"
STAMP_FILE="${STAMP_DIR}/init_${PROVIDER}.stamp"
LS_STAGE="${SYSROOT}/iso_root/libscript"

if [ -f "$STAMP_FILE" ]; then
  printf '[SKIP]     ReactOS init system (%s) already configured in %s\n' "$PROVIDER" "$SYSROOT"
  exit 0
fi

mkdir -p "$STAMP_DIR" "$LS_STAGE"
printf 'provider=%s\nenabled=%s\ndisabled=%s\n' "$PROVIDER" "$ENABLED_CSV" "$DISABLED_CSV" > "${LS_STAGE}/nt_scm_services.conf"

_sc_cmd='sc.exe'
_oifs="$IFS"
IFS=','
for _svc in $ENABLED_CSV; do
  [ -n "$_svc" ] || continue
  printf '%s config "%s" start= auto >nul 2>&1\r\n' "$_sc_cmd" "$_svc" >> "${LS_STAGE}/firstboot.cmd"
  printf '%s start "%s" >nul 2>&1\r\n' "$_sc_cmd" "$_svc" >> "${LS_STAGE}/firstboot.cmd"
done
for _dsvc in $DISABLED_CSV; do
  [ -n "$_dsvc" ] || continue
  printf '%s config "%s" start= disabled >nul 2>&1\r\n' "$_sc_cmd" "$_dsvc" >> "${LS_STAGE}/firstboot.cmd"
done
IFS="$_oifs"

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK]       ReactOS init provider (%s) configured (enabled=%s).\n' "$PROVIDER" "$ENABLED_CSV"
