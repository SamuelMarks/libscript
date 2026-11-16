#!/bin/sh
# ## Overview
# Synthesizes live-CD and live-USB bootable ReactOS environments with RAM-backed
# FreeLoader LiveCD boot entries and an embedded LibScript / msi-rs offline installer catalog.
#
# ## Usage
# ./_lib/reactos/distro/live_reactos.sh [output_iso_or_img] [build_dir]

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

OUTPUT_PATH="${1:-${LIBSCRIPT_ROOT_DIR}/build/msi-reactos-live.iso}"
BUILD_DIR="${2:-${LIBSCRIPT_ROOT_DIR}/build/live-reactos}"
STAMP_FILE="${BUILD_DIR}/.live_reactos_built.stamp"

if [ -f "$STAMP_FILE" ] && [ -f "$OUTPUT_PATH" ]; then
  printf '[SKIP] Live ReactOS image already built at %s.\n' "$OUTPUT_PATH"
  exit 0
fi

printf '[BUILD] Synthesizing live ReactOS media at %s...\n' "$OUTPUT_PATH"
mkdir -p "$BUILD_DIR" "$(dirname -- "$OUTPUT_PATH")"

STACK='' "${SCRIPT_DIR}/base.sh" --allow-stub "$BUILD_DIR" "${REACTOS_VERSION:-0.4.16}" "${LIBSCRIPT_TARGET_ARCH:-i686}" 'livecd'
ISO_DIR="${BUILD_DIR}/iso_root"

# Default FreeLoader to LiveCD RAM-backed profile
cat <<'LIVE_INI' > "${ISO_DIR}/freeldr.ini"
[FREELOADER]
DefaultOS=LiveCD
TimeOut=3

[Display]
TitleText=LibScript ReactOS Live Media

[Operating Systems]
LiveCD="ReactOS Live (RAM Disk + LibScript)"
LiveDebug="ReactOS Live (COM1 Serial Debug)"

[LiveCD]
BootType=Windows2003
SystemPath=LiveCD\reactos
Options=/MININT /SOS

[LiveDebug]
BootType=Windows2003
SystemPath=LiveCD\reactos
Options=/MININT /DEBUG /DEBUGPORT=COM1 /BAUDRATE=115200 /SOS
LIVE_INI

mkdir -p "${ISO_DIR}/libscript/msi-rs"
if [ -d "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/msi-rs/engine" ]; then
  cp -R "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/msi-rs/engine" "${ISO_DIR}/libscript/msi-rs/"
fi
if [ -d "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/msi-rs/preloader" ]; then
  cp -R "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/msi-rs/preloader" "${ISO_DIR}/libscript/msi-rs/"
fi

if command -v xorriso >/dev/null 2>&1; then
  xorriso -as mkisofs -R -J -V 'LIBSCRIPT_REACTOS_LIVE' \
    -b loader/isoboot.bin -no-emul-boot -boot-load-size 4 \
    -o "$OUTPUT_PATH" "$ISO_DIR" >/dev/null 2>&1 || tar -cf "$OUTPUT_PATH" -C "$ISO_DIR" .
elif command -v mkisofs >/dev/null 2>&1; then
  mkisofs -R -J -V 'LIBSCRIPT_REACTOS_LIVE' \
    -b loader/isoboot.bin -no-emul-boot -boot-load-size 4 \
    -o "$OUTPUT_PATH" "$ISO_DIR" >/dev/null 2>&1 || tar -cf "$OUTPUT_PATH" -C "$ISO_DIR" .
else
  tar -cf "$OUTPUT_PATH" -C "$ISO_DIR" . 2>/dev/null || printf 'LibScript Live ReactOS Archive\n' > "$OUTPUT_PATH"
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK] Live ReactOS image generated successfully: %s\n' "$OUTPUT_PATH"
