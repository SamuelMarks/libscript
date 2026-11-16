#!/bin/sh
# ## Overview
# Initializes the ReactOS firstboot.cmd runner, offline registry delta file (hivesft_delta.reg),
# network hostname/DNS configuration, and serial milestone reporting in the target sysroot.
#
# ## Usage
# ./_lib/reactos/distro/config.sh [sysroot_path] [hostname] [dhcp] [dns_csv]

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
HOSTNAME_VAL="${2:-REACTOS-NODE}"
USE_DHCP="${3:-true}"
DNS_CSV="${4:-1.1.1.1,8.8.8.8}"

STAMP_DIR="${SYSROOT}/.libscript-stamps"
STAMP_FILE="${STAMP_DIR}/config.stamp"
LS_STAGE="${SYSROOT}/iso_root/libscript"

mkdir -p "$STAMP_DIR" "$LS_STAGE" "${SYSROOT}/iso_root/ReactOS/System32/drivers/etc"

if [ -f "$STAMP_FILE" ]; then
  printf '[SKIP]     ReactOS core config already staged in %s\n' "$SYSROOT"
  exit 0
fi

cat <<HOSTS_EOF > "${SYSROOT}/iso_root/ReactOS/System32/drivers/etc/hosts"
127.0.0.1       localhost
127.0.0.1       ${HOSTNAME_VAL}
HOSTS_EOF

cat <<REG_EOF > "${LS_STAGE}/hivesft_delta.reg"
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName]
"ComputerName"="${HOSTNAME_VAL}"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters]
"Hostname"="${HOSTNAME_VAL}"
"NameServer"="${DNS_CSV}"
REG_EOF

cat <<'FB_EOF' > "${LS_STAGE}/firstboot.cmd"
@echo off
:: # firstboot.cmd
:: ## Overview
:: Idempotent GuiRunOnce provisioning runner executed inside ReactOS on first boot.
:: ## Usage
:: %SystemDrive%\libscript\firstboot.cmd
setlocal EnableDelayedExpansion
set "_SD=%SystemDrive%"
if "!_SD!"=="" set "_SD=C:"
if exist "!_SD!\libscript\.firstboot.done" exit /b 0
set "PATH=!_SD!\libscript\bootstrap\bin;!PATH!"
set "IS_REACTOS=1"
set "LIBSCRIPT_OFFLINE=1"
echo [LIBSCRIPT-FIRSTBOOT] Applying registry and network configuration...
if exist "!_SD!\libscript\hivesft_delta.reg" reg.exe import "!_SD!\libscript\hivesft_delta.reg" >nul 2>&1
FB_EOF

if [ "$USE_DHCP" = 'true' ] || [ "$USE_DHCP" = '1' ]; then
  printf 'echo [LIBSCRIPT-FIRSTBOOT] DHCP client enabled (dns=%s).\n' "$DNS_CSV" >> "${LS_STAGE}/firstboot.cmd"
fi

awk '{ sub(/\r$/, ""); printf "%s\r\n", $0 }' "${LS_STAGE}/hivesft_delta.reg" > "${LS_STAGE}/hivesft_delta.reg.tmp"
mv "${LS_STAGE}/hivesft_delta.reg.tmp" "${LS_STAGE}/hivesft_delta.reg"
awk '{ sub(/\r$/, ""); printf "%s\r\n", $0 }' "${LS_STAGE}/firstboot.cmd" > "${LS_STAGE}/firstboot.cmd.tmp"
mv "${LS_STAGE}/firstboot.cmd.tmp" "${LS_STAGE}/firstboot.cmd"

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK]       ReactOS core config & firstboot.cmd initialized (hostname=%s).\n' "$HOSTNAME_VAL"
