#!/bin/sh
# ## Overview
# Configures audio subsystem (Solaris Boomer kernel audio, OSS, or PulseAudio)
# and audio device configuration inside the illumos target sysroot.
#
# ## Usage
# Configure audio subsystem:
#   _lib/illumos/distro/audio.sh [sysroot_path] [subsystem]

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

SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${REPO_ROOT}/build/illumos-sysroot}}"
SUBSYSTEM="${2:-none}"

STAMP_DIR="${SYSROOT}/.libscript_stamps"
STAMP_FILE="${STAMP_DIR}/audio.stamp"

mkdir -p "${STAMP_DIR}"
mkdir -p "${SYSROOT}/etc"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     illumos audio subsystem %s already configured in %s
' "${SUBSYSTEM}" "${SYSROOT}"
  exit 0
fi

printf '[AUDIO]    Configuring illumos audio subsystem %s...
' "${SUBSYSTEM}"

case "${SUBSYSTEM}" in
  none)
    printf 'AUDIO_SUBSYSTEM="none"
' > "${SYSROOT}/etc/audio.conf"
    ;;

  boomer)
    # Native Solaris Boomer in-kernel audio framework
    mkdir -p "${SYSROOT}/dev/sound"
    cat << 'EOF' > "${SYSROOT}/etc/audio.conf"
# Solaris Boomer Audio Configuration (managed by LibScript)
AUDIO_SUBSYSTEM="boomer"
AUDIO_DEV="/dev/audio"
AUDIOCTL_DEV="/dev/audioctl"
DEFAULT_VOLUME="75"
EOF
    ;;

  oss)
    # Open Sound System
    mkdir -p "${SYSROOT}/etc/oss"
    cat << 'EOF' > "${SYSROOT}/etc/audio.conf"
AUDIO_SUBSYSTEM="oss"
OSS_DEV="/dev/dsp"
EOF
    ;;

  pulseaudio)
    # PulseAudio daemon
    mkdir -p "${SYSROOT}/etc/pulse"
    cat << 'EOF' > "${SYSROOT}/etc/audio.conf"
AUDIO_SUBSYSTEM="pulseaudio"
EOF
    ;;

  *)
    printf '[WARN]     Unknown audio subsystem: %s, defaulting to none
' "${SUBSYSTEM}" >&2
    printf 'AUDIO_SUBSYSTEM="none"
' > "${SYSROOT}/etc/audio.conf"
    ;;
esac

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"

printf '[OK]       illumos audio configuration complete: %s
' "${SYSROOT}"
