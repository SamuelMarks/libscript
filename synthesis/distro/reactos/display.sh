#!/bin/sh
# ## Overview
# Configures the ReactOS Win32k GDI display subsystem, video miniport driver (vbemp, vga, bochs),
# and default framebuffer resolution (WIDTHxHEIGHTxBPP) in the offline registry delta.
#
# ## Usage
# ./synthesis/distro/reactos/display.sh [sysroot_path] [protocol] [graphics_driver] [resolution]

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
PROTO="${2:-win32-gdi}"
DRIVER="${3:-vbemp}"
RES="${4:-1024x768x32}"

STAMP_DIR="${SYSROOT}/.libscript-stamps"
STAMP_FILE="${STAMP_DIR}/display.stamp"
LS_STAGE="${SYSROOT}/iso_root/libscript"

if [ -f "$STAMP_FILE" ]; then
  printf '[SKIP]     ReactOS display subsystem already configured in %s\n' "$SYSROOT"
  exit 0
fi

mkdir -p "$STAMP_DIR" "$LS_STAGE"
_xres=$(printf '%s' "$RES" | cut -d'x' -f1)
_yres=$(printf '%s' "$RES" | cut -d'x' -f2)
_bpp=$(printf '%s' "$RES" | cut -d'x' -f3)
[ -z "$_xres" ] && _xres='1024'
[ -z "$_yres" ] && _yres='768'
[ -z "$_bpp" ] && _bpp='32'

printf 'protocol=%s\ndriver=%s\nresolution=%sx%sx%s\n' "$PROTO" "$DRIVER" "$_xres" "$_yres" "$_bpp" > "${LS_STAGE}/display.conf"

cat <<DISP_EOF >> "${LS_STAGE}/hivesft_delta.reg"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Hardware Profiles\Current\System\CurrentControlSet\Services\VBE\Device0]
"DefaultSettings.XResolution"=dword:${_xres}
"DefaultSettings.YResolution"=dword:${_yres}
"DefaultSettings.BitsPerPel"=dword:${_bpp}
DISP_EOF

awk '{ sub(/\r$/, ""); printf "%s\r\n", $0 }' "${LS_STAGE}/hivesft_delta.reg" > "${LS_STAGE}/hivesft_delta.reg.tmp"
mv "${LS_STAGE}/hivesft_delta.reg.tmp" "${LS_STAGE}/hivesft_delta.reg"

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK]       ReactOS display (%s, %s, %s) configured.\n' "$PROTO" "$DRIVER" "$RES"
