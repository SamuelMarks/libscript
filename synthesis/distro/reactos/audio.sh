#!/bin/sh
# ## Overview
# Configures the ReactOS WDM audio subsystem (wdmaud, ac97, hdaudio, sb16, or none)
# inside the target sysroot and firstboot service configuration.
#
# ## Usage
# ./synthesis/distro/reactos/audio.sh [sysroot_path] [subsystem]

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
AUDIO_SUB="${2:-none}"

STAMP_DIR="${SYSROOT}/.libscript-stamps"
STAMP_FILE="${STAMP_DIR}/audio.stamp"
LS_STAGE="${SYSROOT}/iso_root/libscript"

if [ -f "$STAMP_FILE" ]; then
  printf '[SKIP]     ReactOS audio subsystem (%s) already configured in %s\n' "$AUDIO_SUB" "$SYSROOT"
  exit 0
fi

mkdir -p "$STAMP_DIR" "$LS_STAGE"
printf 'audio=%s\n' "$AUDIO_SUB" > "${LS_STAGE}/audio.conf"

if [ "$AUDIO_SUB" != 'none' ]; then
  _sc_cmd='sc.exe'
  printf '%s config audiosrv start= auto >nul 2>&1\r\n' "$_sc_cmd" >> "${LS_STAGE}/firstboot.cmd"
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK]       ReactOS audio subsystem (%s) configured.\n' "$AUDIO_SUB"
