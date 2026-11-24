#!/bin/sh
# ## Overview
# Unified CLI entrypoint to synthesize and package a ReactOS distribution profile
# into iso, qcow2, raw, vhd, vmdk, or Vagrant box formats.
#
# ## Usage
# synthesis/formats/reactos_distro.sh [--format <iso|qcow2|box|raw|vhd|vmdk>] [--profile <profile_json>] [--output <path>] [--size <gib>] [--from-source] [--bake-qemu] [--dry-run] [--allow-stub] [--strict]

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

FORMAT='iso'
PROFILE="${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/reactos/desktop-classic-i686.json"
OUTPUT=''
SIZE_GIB='8'
SYSROOT=''
DRY_RUN="${LIBSCRIPT_DRY_RUN:-0}"
STRICT_BUILD="${LIBSCRIPT_STRICT_IMAGE_BUILD:-0}"
ALLOW_STUB="${LIBSCRIPT_ALLOW_STUB:-0}"

# ## resolve_reactos_profile
# Resolves a ReactOS profile path or preset name under synthesis/profiles/.
resolve_reactos_profile() {
  _rrp="$1"
  if [ -f "$_rrp" ]; then
    printf '%s\n' "$_rrp"
    return 0
  fi
  for _sub in '' 'reactos/'; do
    if [ -f "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/${_sub}${_rrp}.json" ]; then
      printf '%s\n' "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/${_sub}${_rrp}.json"
      return 0
    fi
  done
  printf '%s\n' "$_rrp"
  return 0
}

# ## compute_profile_hash
# Computes a deterministic SHA-256 or byte-length fingerprint for a profile file.
compute_profile_hash() {
  _cph="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$_cph" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$_cph" | awk '{print $1}'
  else
    wc -c < "$_cph" | tr -d ' '
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --format|-f) FORMAT="$2"; shift 2 ;;
    --format=*) FORMAT="${1#*=}"; shift ;;
    --profile|-p) PROFILE="$2"; shift 2 ;;
    --profile=*) PROFILE="${1#*=}"; shift ;;
    --output|-o|--out) OUTPUT="$2"; shift 2 ;;
    --output=*|--out=*) OUTPUT="${1#*=}"; shift ;;
    --size) SIZE_GIB="$2"; shift 2 ;;
    --size=*) SIZE_GIB="${1#*=}"; shift ;;
    --sysroot) SYSROOT="$2"; shift 2 ;;
    --sysroot=*) SYSROOT="${1#*=}"; shift ;;
    --from-source) export REACTOS_BUILD_FROM_SOURCE='1'; shift ;;
    --bake-qemu) export REACTOS_QEMU_BAKE='1'; shift ;;
    --dry-run) DRY_RUN='1'; shift ;;
    --offline) export LIBSCRIPT_OFFLINE='1'; shift ;;
    --strict) STRICT_BUILD='1'; ALLOW_STUB='0'; export LIBSCRIPT_STRICT_IMAGE_BUILD='1'; export LIBSCRIPT_ALLOW_STUB='0'; shift ;;
    --allow-stub) ALLOW_STUB='1'; STRICT_BUILD='0'; export LIBSCRIPT_ALLOW_STUB='1'; export LIBSCRIPT_STRICT_IMAGE_BUILD='0'; shift ;;
    --help|-h)
      printf 'Usage: %s [--format <iso|qcow2|box|raw|vhd|vmdk>] [--profile <path|preset>] [--output <path>] [--size <gib>] [--from-source] [--bake-qemu] [--dry-run] [--allow-stub] [--strict]\n' "$THIS_FILE"
      exit 0
      ;;
    *)
      printf '[ERROR] Unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

PROFILE=$(resolve_reactos_profile "$PROFILE")
if [ ! -f "$PROFILE" ]; then
  printf '[ERROR] ReactOS profile not found: %s\n' "$PROFILE" >&2
  exit 1
fi

PBASE="${PROFILE##*/}"
PNAME="${PBASE%.json}"
: "${SYSROOT:=${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/reactos-sysroot-${PNAME}}}"

case "$FORMAT" in
  iso|live-iso) : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/iso/reactos-${PNAME}.iso}" ;;
  raw|raw-img) : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/raw/reactos-${PNAME}.raw}" ;;
  qcow2) : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/qemu/reactos-${PNAME}.qcow2}" ;;
  vhd|vhdx) : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/hyperv/reactos-${PNAME}.vhd}" ;;
  vmdk) : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/vmware/reactos-${PNAME}.vmdk}" ;;
  box|vagrant-box) : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/vagrant/reactos-${PNAME}.box}" ;;
  *)
    printf '[ERROR] Unsupported ReactOS packaging format: %s\n' "$FORMAT" >&2
    exit 1
    ;;
esac

if [ "$DRY_RUN" = '1' ]; then
  STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/config/config.sh" os --validate="$PROFILE"
  printf '[DRYRUN]   ReactOS distribution plan verified (format=%s) -> %s\n' "$FORMAT" "$OUTPUT"
  exit 0
fi

STAMP_FILE="${OUTPUT}.distro.stamp"
PROF_HASH=$(compute_profile_hash "$PROFILE")
if [ -f "$STAMP_FILE" ] && [ -f "$OUTPUT" ]; then
  if grep -q "^profile_hash=${PROF_HASH}$" "$STAMP_FILE" 2>/dev/null && grep -q "^format=${FORMAT}$" "$STAMP_FILE" 2>/dev/null; then
    if [ "$STRICT_BUILD" != '1' ] || ! grep -q '^mode=stub$' "$STAMP_FILE" 2>/dev/null; then
      printf '[SKIP]     ReactOS distribution artifact already synthesized: %s\n' "$OUTPUT"
      exit 0
    fi
  fi
fi

printf '[DISTRO]   Synthesizing ReactOS sysroot (%s) from %s...\n' "$SYSROOT" "$PROFILE"
STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/reactos/assemble.sh" "$PROFILE" "$SYSROOT"

case "$FORMAT" in
  iso|live-iso)
    STACK='' "${SCRIPT_DIR}/reactos_iso.sh" "$SYSROOT" "$OUTPUT"
    ;;
  raw|raw-img)
    STACK='' "${SCRIPT_DIR}/reactos_raw.sh" "$SYSROOT" "$OUTPUT" "$SIZE_GIB"
    ;;
  qcow2)
    STACK='' "${SCRIPT_DIR}/reactos_qcow2.sh" "$SYSROOT" "$OUTPUT" "$SIZE_GIB"
    ;;
  vhd|vhdx)
    STACK='' "${SCRIPT_DIR}/reactos_vhd.sh" "$SYSROOT" "$OUTPUT" "$SIZE_GIB"
    ;;
  vmdk)
    STACK='' "${SCRIPT_DIR}/reactos_vmdk.sh" "$SYSROOT" "$OUTPUT" "$SIZE_GIB"
    ;;
  box|vagrant-box)
    _qcow_tmp="${OUTPUT}.qcow2.tmp"
    STACK='' "${SCRIPT_DIR}/reactos_qcow2.sh" "$SYSROOT" "$_qcow_tmp" "$SIZE_GIB"
    STACK='' "${SCRIPT_DIR}/reactos_vagrant_box.sh" "$_qcow_tmp" "$OUTPUT" 'qemu'
    rm -f "$_qcow_tmp" "${_qcow_tmp}.stamp"
    ;;
esac

STAMP_MODE='native'
[ "$ALLOW_STUB" = '1' ] && STAMP_MODE='stub'
printf 'format=%s\nprofile=%s\nprofile_hash=%s\nmode=%s\ntimestamp=%s\n' \
  "$FORMAT" "$PROFILE" "$PROF_HASH" "$STAMP_MODE" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"

printf '[OK]       ReactOS distribution packaged as %s: %s\n' "$FORMAT" "$OUTPUT"
