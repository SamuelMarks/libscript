#!/bin/sh
# ## Overview
# Configures audio subsystems (native FreeBSD OSS, PipeWire/WirePlumber, or none)
# inside FreeBSD target sysroot.
#
# ## Usage
# Configure audio subsystem:
#   _lib/freebsd/distro/audio.sh [sysroot_path] [subsystem]

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
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${REPO_ROOT}/build/freebsd-sysroot}}"
SUBSYSTEM="${2:-oss}"

STAMP_DIR="${SYSROOT}/.libscript_stamps"
STAMP_FILE="${STAMP_DIR}/audio_${SUBSYSTEM}.stamp"

mkdir -p "${STAMP_DIR}"
mkdir -p "${SYSROOT}/etc"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     FreeBSD audio subsystem %s already configured in %s
' "${SUBSYSTEM}" "${SYSROOT}"
  exit 0
fi

printf '[AUDIO]    Configuring audio subsystem: %s...
' "${SUBSYSTEM}"

case "${SUBSYSTEM}" in
  none)
    printf '[AUDIO]    Audio disabled.
'
    ;;

  oss)
    # Native FreeBSD Open Sound System
    printf 'snd_driver_load="YES"
' >> "${SYSROOT}/boot/loader.conf"
    # Ensure syscons / devfs permissions for /dev/dsp*
    cat << 'EOF' >> "${SYSROOT}/etc/devfs.rules"
add path 'dsp*' mode 0666 group audio
add path 'audio*' mode 0666 group audio
EOF
    ;;

  pipewire)
    # PipeWire + WirePlumber daemon integration
    printf 'snd_driver_load="YES"
' >> "${SYSROOT}/boot/loader.conf"
    mkdir -p "${SYSROOT}/usr/local/etc/pipewire"
    ;;

  *)
    printf '[WARN]     Unknown audio subsystem "%s", skipping.
' "${SUBSYSTEM}" >&2
    ;;
esac

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       Audio subsystem %s configured.
' "${SUBSYSTEM}"
