#!/bin/sh
# ## Overview
# Unified CLI entrypoint to synthesize and package a ReactOS distribution profile
# into iso, qcow2, raw, vhd, vmdk, or Vagrant box formats.
#
# ## Usage
# synthesis/formats/reactos_distro.sh --format <iso|qcow2|box|raw|vhd|vmdk> --profile <profile_json> [--output <path>] [--size <gib>] [--from-source] [--bake-qemu]

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

while [ $# -gt 0 ]; do
  case "$1" in
    --format|-f) FORMAT="$2"; shift 2 ;;
    --format=*) FORMAT="${1#*=}"; shift ;;
    --profile|-p) PROFILE="$2"; shift 2 ;;
    --profile=*) PROFILE="${1#*=}"; shift ;;
    --output|-o) OUTPUT="$2"; shift 2 ;;
    --output=*) OUTPUT="${1#*=}"; shift ;;
    --size) SIZE_GIB="$2"; shift 2 ;;
    --size=*) SIZE_GIB="${1#*=}"; shift ;;
    --sysroot) SYSROOT="$2"; shift 2 ;;
    --sysroot=*) SYSROOT="${1#*=}"; shift ;;
    --from-source) export REACTOS_BUILD_FROM_SOURCE='1'; shift ;;
    --bake-qemu) export REACTOS_QEMU_BAKE='1'; shift ;;
    --strict) export LIBSCRIPT_STRICT_IMAGE_BUILD='1'; export LIBSCRIPT_ALLOW_STUB='0'; shift ;;
    --allow-stub) export LIBSCRIPT_ALLOW_STUB='1'; export LIBSCRIPT_STRICT_IMAGE_BUILD='0'; shift ;;
    --help|-h)
      printf 'Usage: %s --format <iso|qcow2|box|raw|vhd|vmdk> --profile <path> [--output <path>] [--size <gib>] [--from-source] [--bake-qemu]\n' "$THIS_FILE"
      exit 0
      ;;
    *)
      printf '[ERROR] Unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

PBASE="${PROFILE##*/}"
PNAME="${PBASE%.json}"
: "${SYSROOT:=${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/reactos-sysroot-${PNAME}}}"

printf '[DISTRO]   Synthesizing ReactOS sysroot (%s) from %s...\n' "$SYSROOT" "$PROFILE"
STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/reactos/assemble.sh" "$PROFILE" "$SYSROOT"

case "$FORMAT" in
  iso)
    : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/iso/reactos-${PNAME}.iso}"
    STACK='' "${SCRIPT_DIR}/reactos_iso.sh" "$SYSROOT" "$OUTPUT"
    ;;
  raw)
    : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/raw/reactos-${PNAME}.raw}"
    STACK='' "${SCRIPT_DIR}/reactos_raw.sh" "$SYSROOT" "$OUTPUT" "$SIZE_GIB"
    ;;
  qcow2)
    : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/qemu/reactos-${PNAME}.qcow2}"
    STACK='' "${SCRIPT_DIR}/reactos_qcow2.sh" "$SYSROOT" "$OUTPUT" "$SIZE_GIB"
    ;;
  vhd)
    : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/hyperv/reactos-${PNAME}.vhd}"
    STACK='' "${SCRIPT_DIR}/reactos_vhd.sh" "$SYSROOT" "$OUTPUT" "$SIZE_GIB"
    ;;
  vmdk)
    : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/vmware/reactos-${PNAME}.vmdk}"
    STACK='' "${SCRIPT_DIR}/reactos_vmdk.sh" "$SYSROOT" "$OUTPUT" "$SIZE_GIB"
    ;;
  box|vagrant-box)
    : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/vagrant/reactos-${PNAME}.box}"
    _qcow_tmp="${OUTPUT}.qcow2.tmp"
    STACK='' "${SCRIPT_DIR}/reactos_qcow2.sh" "$SYSROOT" "$_qcow_tmp" "$SIZE_GIB"
    STACK='' "${SCRIPT_DIR}/reactos_vagrant_box.sh" "$_qcow_tmp" "$OUTPUT" 'qemu'
    rm -f "$_qcow_tmp" "${_qcow_tmp}.stamp"
    ;;
  *)
    printf '[ERROR] Unsupported ReactOS packaging format: %s\n' "$FORMAT" >&2
    exit 1
    ;;
esac

printf '[OK]       ReactOS distribution packaged as %s: %s\n' "$FORMAT" "$OUTPUT"
