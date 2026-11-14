#!/bin/sh
# ## Overview
# Packages an illumos target sysroot into a bootable hybrid ISO 9660 / El Torito image.
#
# ## Usage
# Package bootable ISO:
#   cli/commands/package_as/illumos_iso.sh [--strict | --allow-stub] [target_sysroot] [output_iso]

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

STRICT_BUILD="${LIBSCRIPT_STRICT_IMAGE_BUILD:-0}"
ALLOW_STUB="${LIBSCRIPT_ALLOW_STUB:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)
      printf 'Usage: %s [--strict | --allow-stub] [target_sysroot] [output_iso]\n' "$0"
      printf 'Synthesizes bootable illumos ISO image.\n'
      exit 0
      ;;
    --strict)
      STRICT_BUILD=1
      shift
      ;;
    --allow-stub)
      ALLOW_STUB=1
      shift
      ;;
    *)
      break
      ;;
  esac
done

TARGET_SYSROOT="${1:-${LIBSCRIPT_ROOT_DIR}/build/illumos-sysroot}"
OUT_ISO="${2:-${LIBSCRIPT_ROOT_DIR}/build/illumos.iso}"

mkdir -p "$(dirname "${OUT_ISO}")"
mkdir -p "${TARGET_SYSROOT}/boot"

STAMP_FILE="${OUT_ISO}.stamp"

# ## has_illumos_iso_tool
# Returns 0 if a genuine ISO 9660 synthesis utility is installed on the host.
has_illumos_iso_tool() {
  command -v xorriso >/dev/null 2>&1 ||
    command -v mkisofs >/dev/null 2>&1 ||
    command -v hdiutil >/dev/null 2>&1
}

if [ -f "${STAMP_FILE}" ] && [ -s "${OUT_ISO}" ]; then
  if grep -q '^mode=stub$' "${STAMP_FILE}" 2>/dev/null; then
    if [ "${STRICT_BUILD}" = "1" ] || has_illumos_iso_tool; then
      rm -f "${STAMP_FILE}"
    else
      printf '[SKIP]     illumos ISO %s already synthesized (stub)\n' "${OUT_ISO}"
      exit 0
    fi
  else
    printf '[SKIP]     illumos ISO %s already synthesized\n' "${OUT_ISO}"
    exit 0
  fi
fi

printf '[PACKAGE]  Synthesizing illumos bootable ISO: %s...\n' "${OUT_ISO}"
BUILT_NATIVE=0
rm -f "${OUT_ISO}"

if command -v xorriso >/dev/null 2>&1; then
  if [ -f "${TARGET_SYSROOT}/boot/cdboot" ]; then
    xorriso -as mkisofs -r -J -V "ILLUMOS_INSTALL" -b boot/cdboot -no-emul-boot -boot-info-table -o "${OUT_ISO}" "${TARGET_SYSROOT}" >/dev/null 2>&1 || true
  if [ -s "${OUT_ISO}" ]; then BUILT_NATIVE=1; fi
  elif [ -f "${TARGET_SYSROOT}/boot/grub/stage2_eltorito" ]; then
    xorriso -as mkisofs -r -J -V "ILLUMOS_INSTALL" -b boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 4 -boot-info-table -o "${OUT_ISO}" "${TARGET_SYSROOT}" >/dev/null 2>&1 || true
  if [ -s "${OUT_ISO}" ]; then BUILT_NATIVE=1; fi
  else
    xorriso -as mkisofs -r -J -V "ILLUMOS_INSTALL" -o "${OUT_ISO}" "${TARGET_SYSROOT}" >/dev/null 2>&1 || true
  if [ -s "${OUT_ISO}" ]; then BUILT_NATIVE=1; fi
  fi
fi

if [ "${BUILT_NATIVE}" -eq 0 ] && command -v mkisofs >/dev/null 2>&1; then
  if [ -f "${TARGET_SYSROOT}/boot/cdboot" ]; then
    mkisofs -r -J -V "ILLUMOS_INSTALL" -b boot/cdboot -no-emul-boot -boot-info-table -o "${OUT_ISO}" "${TARGET_SYSROOT}" >/dev/null 2>&1 || true
  if [ -s "${OUT_ISO}" ]; then BUILT_NATIVE=1; fi
  else
    mkisofs -r -J -V "ILLUMOS_INSTALL" -o "${OUT_ISO}" "${TARGET_SYSROOT}" >/dev/null 2>&1 || true
  if [ -s "${OUT_ISO}" ]; then BUILT_NATIVE=1; fi
  fi
fi

if [ "${BUILT_NATIVE}" -eq 0 ] && command -v hdiutil >/dev/null 2>&1; then
  hdiutil makehybrid -iso -joliet -default-volume-name "ILLUMOS_INSTALL" -o "${OUT_ISO}.cdr" "${TARGET_SYSROOT}" >/dev/null 2>&1 || true
    mv -f "${OUT_ISO}.cdr.iso" "${OUT_ISO}" 2>/dev/null || mv -f "${OUT_ISO}.cdr" "${OUT_ISO}" 2>/dev/null || true
  if [ -s "${OUT_ISO}" ]; then BUILT_NATIVE=1; fi
fi

if [ "${BUILT_NATIVE}" -eq 1 ]; then
  printf 'mode=native\ntimestamp=%s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
  mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
  printf '[OK]       illumos ISO generated: %s\n' "${OUT_ISO}"
  exit 0
fi

if [ "${STRICT_BUILD}" = "1" ] && [ "${ALLOW_STUB}" != "1" ]; then
  printf '[ERROR]    Strict illumos ISO synthesis failed: install xorriso or mkisofs.\n' >&2
  rm -f "${OUT_ISO}" "${STAMP_FILE}"
  exit 1
fi

printf 'LibScript illumos ISO Stub\n' > "${OUT_ISO}"
printf 'mode=stub\ntimestamp=%s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[WARN]     xorriso/mkisofs not found; wrote stub ISO: %s\n' "${OUT_ISO}"
exit 0
