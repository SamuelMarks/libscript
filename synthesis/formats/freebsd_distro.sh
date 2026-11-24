#!/bin/sh
# ## Overview
# Unified CLI entrypoint to package a FreeBSD distribution profile into
# raw, qcow2, vagrant box, vhd, vmdk, iso, or direct-kernel target formats.
# ## Usage
# Package FreeBSD distribution:
#   synthesis/formats/freebsd_distro.sh [--format <qcow2|box|raw|vhd|vmdk|iso|direct-kernel>] [--profile <profile_json>] [--output <path>] [--dry-run] [--allow-stub] [--strict]

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
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2; fi
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

FORMAT='qcow2'
PROFILE="${REPO_ROOT}/synthesis/profiles/freebsd/minimal-server.json"
OUTPUT=''
SYSROOT=''
DRY_RUN="${LIBSCRIPT_DRY_RUN:-0}"
STRICT_BUILD="${LIBSCRIPT_STRICT_IMAGE_BUILD:-0}"
ALLOW_STUB="${LIBSCRIPT_ALLOW_STUB:-0}"

# ## resolve_freebsd_profile
# Resolves a FreeBSD profile path or preset name under synthesis/profiles/.
resolve_freebsd_profile() {
  _rfp="$1"
  if [ -f "$_rfp" ]; then
    printf '%s\n' "$_rfp"
    return 0
  fi
  for _sub in '' 'freebsd/'; do
    if [ -f "${REPO_ROOT}/synthesis/profiles/${_sub}${_rfp}.json" ]; then
      printf '%s\n' "${REPO_ROOT}/synthesis/profiles/${_sub}${_rfp}.json"
      return 0
    fi
  done
  printf '%s\n' "$_rfp"
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
    --sysroot) SYSROOT="$2"; shift 2 ;;
    --sysroot=*) SYSROOT="${1#*=}"; shift ;;
    --dry-run) DRY_RUN='1'; shift ;;
    --strict) STRICT_BUILD='1'; ALLOW_STUB='0'; export LIBSCRIPT_STRICT_IMAGE_BUILD='1'; export LIBSCRIPT_ALLOW_STUB='0'; shift ;;
    --allow-stub) ALLOW_STUB='1'; STRICT_BUILD='0'; export LIBSCRIPT_ALLOW_STUB='1'; export LIBSCRIPT_STRICT_IMAGE_BUILD='0'; shift ;;
    --offline) export LIBSCRIPT_OFFLINE='1'; shift ;;
    --help|-h)
      printf 'Usage: %s [--format <qcow2|box|raw|vhd|vmdk|iso|direct-kernel>] [--profile <path|preset>] [--output <path>] [--dry-run] [--allow-stub] [--strict]\n' "${THIS_FILE}"
      exit 0
      ;;
    *)
      printf '[ERROR] Unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

PROFILE=$(resolve_freebsd_profile "$PROFILE")
if [ ! -f "$PROFILE" ]; then
  printf '[ERROR] FreeBSD profile not found: %s\n' "$PROFILE" >&2
  exit 1
fi

case "${FORMAT}" in
  raw|raw-img) : "${OUTPUT:=${REPO_ROOT}/build/images/raw/freebsd.raw}" ;;
  qcow2) : "${OUTPUT:=${REPO_ROOT}/build/images/qemu/freebsd.qcow2}" ;;
  box|vagrant-box) : "${OUTPUT:=${REPO_ROOT}/build/images/vagrant/freebsd.box}" ;;
  vhd|vhdx) : "${OUTPUT:=${REPO_ROOT}/build/images/hyperv/freebsd.vhd}" ;;
  vmdk) : "${OUTPUT:=${REPO_ROOT}/build/images/vmware/freebsd.vmdk}" ;;
  iso|live-iso) : "${OUTPUT:=${REPO_ROOT}/build/images/iso/freebsd.iso}" ;;
  direct-kernel) : "${OUTPUT:=${REPO_ROOT}/build/images/direct-kernel/freebsd}" ;;
  *)
    printf '[ERROR] Unsupported packaging format: %s\n' "${FORMAT}" >&2
    printf 'Supported formats: qcow2, box, raw, vhd, vmdk, iso, direct-kernel\n' >&2
    exit 1
    ;;
esac

if [ "$DRY_RUN" = '1' ]; then
  STACK='' "${REPO_ROOT}/cli/commands/config/config.sh" os --validate="$PROFILE"
  printf '[DRYRUN]   FreeBSD distribution plan verified (format=%s) -> %s\n' "$FORMAT" "$OUTPUT"
  exit 0
fi

STAMP_FILE="${OUTPUT}.distro.stamp"
PROF_HASH=$(compute_profile_hash "$PROFILE")
if [ -f "$STAMP_FILE" ] && { [ -f "$OUTPUT" ] || [ -d "$OUTPUT" ]; }; then
  if grep -q "^profile_hash=${PROF_HASH}$" "$STAMP_FILE" 2>/dev/null && grep -q "^format=${FORMAT}$" "$STAMP_FILE" 2>/dev/null; then
    if [ "$STRICT_BUILD" != '1' ] || ! grep -q '^mode=stub$' "$STAMP_FILE" 2>/dev/null; then
      printf '[SKIP]     FreeBSD distribution artifact already synthesized: %s\n' "$OUTPUT"
      exit 0
    fi
  fi
fi

PBASE="${PROFILE##*/}"
PNAME="${PBASE%.json}"
: "${SYSROOT:=${LIBSCRIPT_TARGET_SYSROOT:-${REPO_ROOT}/build/freebsd-sysroot-${PNAME}}}"

# Step 1: Assemble sysroot from profile
printf '[DISTRO]   Synthesizing FreeBSD sysroot from %s...\n' "${PROFILE}"
STACK='' "${REPO_ROOT}/synthesis/distro/freebsd/assemble.sh" "${PROFILE}" "${SYSROOT}"

# Step 2: Dispatch to requested format exporter
case "${FORMAT}" in
  raw|raw-img)
    STACK='' "${SCRIPT_DIR}/freebsd_raw.sh" "${SYSROOT}" "${OUTPUT}" 20
    ;;
  qcow2)
    STACK='' "${SCRIPT_DIR}/freebsd_qcow2.sh" "${SYSROOT}" "${OUTPUT}" 20
    ;;
  box|vagrant-box)
    QCOW_TMP="${REPO_ROOT}/build/images/qemu/freebsd.qcow2"
    STACK='' "${SCRIPT_DIR}/freebsd_qcow2.sh" "${SYSROOT}" "${QCOW_TMP}" 20
    STACK='' "${SCRIPT_DIR}/freebsd_vagrant_box.sh" "${QCOW_TMP}" "${OUTPUT}" "qemu"
    ;;
  vhd|vhdx)
    STACK='' "${SCRIPT_DIR}/freebsd_vhd.sh" "${SYSROOT}" "${OUTPUT}" 20
    ;;
  vmdk)
    STACK='' "${SCRIPT_DIR}/freebsd_vmdk.sh" "${SYSROOT}" "${OUTPUT}" 20
    ;;
  iso|live-iso)
    STACK='' "${SCRIPT_DIR}/freebsd_iso.sh" "${SYSROOT}" "${OUTPUT}"
    ;;
  direct-kernel)
    _dk_flags=''
    [ "$ALLOW_STUB" = '1' ] && _dk_flags='--allow-stub'
    [ "$STRICT_BUILD" = '1' ] && _dk_flags='--strict'
    if [ -n "$_dk_flags" ]; then
      STACK='' "${SCRIPT_DIR}/direct_kernel.sh" --kernel=freebsd "$_dk_flags" "${SYSROOT}" "${OUTPUT}"
    else
      STACK='' "${SCRIPT_DIR}/direct_kernel.sh" --kernel=freebsd "${SYSROOT}" "${OUTPUT}"
    fi
    ;;
esac

STAMP_MODE='native'
[ "$ALLOW_STUB" = '1' ] && STAMP_MODE='stub'
printf 'format=%s\nprofile=%s\nprofile_hash=%s\nmode=%s\ntimestamp=%s\n' \
  "$FORMAT" "$PROFILE" "$PROF_HASH" "$STAMP_MODE" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"

printf '[OK]       Packaging complete: %s\n' "${OUTPUT}"
