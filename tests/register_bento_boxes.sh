#!/bin/sh
# ## Overview
# Discovers built `../bento` `.box` images, validates non-DOS/DOS Packer templates & builders, and registers boxes idempotently.
# ## Usage
# ./tests/register_bento_boxes.sh [--bento-dir <path>] [--bento-prefix <prefix>] [--arch <aarch64|x86_64>] [--force] [--validate-only]

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
export LIBSCRIPT_ROOT_DIR

BENTO_DIR="${BENTO_DIR:-${LIBSCRIPT_ROOT_DIR}/../bento}"
BENTO_PREFIX="${BENTO_PREFIX:-bento}"
BENTO_HOST_ARCH="${BENTO_HOST_ARCH:-}"
FORCE_FLAG=""
VALIDATE_ONLY=0

# ## show_usage
# Prints command-line usage instructions for register_bento_boxes.sh.
show_usage() {
  printf 'Usage: %s [--bento-dir <path>] [--bento-prefix <prefix>] [--arch <aarch64|x86_64>] [--force] [--validate-only]\n' "${THIS_FILE}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --bento-dir)
      BENTO_DIR="$2"
      shift 2
      ;;
    --bento-dir=*)
      BENTO_DIR="${1#*=}"
      shift
      ;;
    --bento-prefix)
      BENTO_PREFIX="$2"
      shift 2
      ;;
    --bento-prefix=*)
      BENTO_PREFIX="${1#*=}"
      shift
      ;;
    --arch)
      BENTO_HOST_ARCH="$2"
      shift 2
      ;;
    --arch=*)
      BENTO_HOST_ARCH="${1#*=}"
      shift
      ;;
    --force)
      FORCE_FLAG='--force'
      shift
      ;;
    --validate-only)
      VALIDATE_ONLY=1
      shift
      ;;
    --help|-h|/\?|-\?)
      show_usage
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

# ## detect_bento_host_arch
# Resolves the canonical Bento host architecture string (`aarch64` or `x86_64`).
detect_bento_host_arch() {
  if [ -n "$BENTO_HOST_ARCH" ]; then
    case "$BENTO_HOST_ARCH" in
      arm64|aarch64) printf '%s\n' 'aarch64' ;;
      amd64|x86_64) printf '%s\n' 'x86_64' ;;
      *) printf '%s\n' "$BENTO_HOST_ARCH" ;;
    esac
    return 0
  fi
  _raw_arch=$(uname -m 2>/dev/null || printf '%s' 'x86_64')
  case "$_raw_arch" in
    arm64|aarch64) printf '%s\n' 'aarch64' ;;
    *) printf '%s\n' 'x86_64' ;;
  esac
}

BENTO_HOST_ARCH=$(detect_bento_host_arch)

# ## resolve_box_artifact
# Resolves a built Vagrant `.box` file in `builds/build_complete/` preferring the host architecture with cross-arch fallback.
resolve_box_artifact() {
  _stem="$1"
  _ext="${2:-qemu.box}"
  _bc_dir="${BENTO_DIR}/builds/build_complete"
  for _cand_arch in "$BENTO_HOST_ARCH" "aarch64" "x86_64" "i386"; do
    if [ -f "${_bc_dir}/${_stem}-${_cand_arch}.${_ext}" ]; then
      printf '%s\n' "${_bc_dir}/${_stem}-${_cand_arch}.${_ext}"
      return 0
    fi
  done
  printf '%s\n' "${_bc_dir}/${_stem}-${BENTO_HOST_ARCH}.${_ext}"
}

# ## validate_bento_pkrvars
# Validates that all non-DOS and DOS target OS Packer variable templates and standalone DOS builders exist in `../bento/`.
validate_bento_pkrvars() {
  if [ ! -d "$BENTO_DIR" ]; then
    printf '[WARN] Bento directory not found at %s; skipping pkrvars check.\n' "$BENTO_DIR" >&2
    return 0
  fi
  printf '==> Validating Bento Packer templates & DOS builders in %s (host arch: %s)...\n' "$BENTO_DIR" "$BENTO_HOST_ARCH"
  for _pkr in \
    "os_pkrvars/omnios/omnios-braich-aarch64.pkrvars.hcl" \
    "os_pkrvars/alpine/alpine-3.24-${BENTO_HOST_ARCH}.pkrvars.hcl" \
    "os_pkrvars/debian/debian-13-${BENTO_HOST_ARCH}.pkrvars.hcl" \
    "os_pkrvars/rockylinux/rockylinux-10-${BENTO_HOST_ARCH}.pkrvars.hcl" \
    "os_pkrvars/freebsd/freebsd-15-${BENTO_HOST_ARCH}.pkrvars.hcl" \
    "os_pkrvars/macos/macos-27-aarch64.pkrvars.hcl" \
    "os_pkrvars/macos/macos-14-aarch64.pkrvars.hcl" \
    "os_pkrvars/windows/windows-11-${BENTO_HOST_ARCH}.pkrvars.hcl" \
    "os_pkrvars/freedos/freedos-1.3-${BENTO_HOST_ARCH}.pkrvars.hcl" \
    "os_pkrvars/freedos/freedos-1.4-${BENTO_HOST_ARCH}.pkrvars.hcl" \
    "os_pkrvars/msdos/msdos-1.25-${BENTO_HOST_ARCH}.pkrvars.hcl" \
    "os_pkrvars/msdos/msdos-2.0-${BENTO_HOST_ARCH}.pkrvars.hcl" \
    "os_pkrvars/msdos/msdos-4.0-${BENTO_HOST_ARCH}.pkrvars.hcl" \
    "freedos-builder.sh" \
    "freedos-builder.cmd" \
    "msdos-builder.sh" \
    "msdos-builder.cmd"; do
    if [ -f "${BENTO_DIR}/${_pkr}" ]; then
      printf '[PASS] Found %s\n' "$_pkr"
    else
      printf '[WARN] Missing %s in %s\n' "$_pkr" "$BENTO_DIR" >&2
    fi
  done
}

# ## ensure_libvirt_qemu_links
# Idempotently links `libvirt` provider directories to `qemu` inside `~/.vagrant.d/boxes` for `arm64` and `amd64`.
ensure_libvirt_qemu_links() {
  _box_name="$1"
  _vag_home="${VAGRANT_HOME:-${HOME:-/root}/.vagrant.d}"
  _vslash_name=$(printf '%s' "$_box_name" | sed 's|/|-VAGRANTSLASH-|g')
  for _vag_arch in arm64 amd64; do
    if [ -d "${_vag_home}/boxes/${_vslash_name}/0/${_vag_arch}/qemu" ] && [ ! -d "${_vag_home}/boxes/${_vslash_name}/0/${_vag_arch}/libvirt" ]; then
      rm -f "${_vag_home}/boxes/${_vslash_name}/0/${_vag_arch}/libvirt" 2>/dev/null || true
      ln -sf "${_vag_home}/boxes/${_vslash_name}/0/${_vag_arch}/qemu" "${_vag_home}/boxes/${_vslash_name}/0/${_vag_arch}/libvirt"
    fi
  done
  if [ -d "${_vag_home}/boxes/${_vslash_name}/0/qemu" ] && [ ! -d "${_vag_home}/boxes/${_vslash_name}/0/libvirt" ]; then
    rm -f "${_vag_home}/boxes/${_vslash_name}/0/libvirt" 2>/dev/null || true
    ln -sf "${_vag_home}/boxes/${_vslash_name}/0/qemu" "${_vag_home}/boxes/${_vslash_name}/0/libvirt"
  fi
}

# ## register_box_if_needed
# Registers a `.qemu.box`, `.libvirt.box`, or `.utm.box` artifact into host Vagrant if not already present (or if `--force` is passed).
register_box_if_needed() {
  _box_name="$1"
  _box_file="$2"
  _existing_boxes="$3"
  _provider="${4:-qemu}"

  if [ -z "$FORCE_FLAG" ] && printf '%s\n' "$_existing_boxes" | grep -q "^${_box_name} .*${_provider}"; then
    printf '[OK]   Box %s (%s) is already registered in host Vagrant.\n' "$_box_name" "$_provider"
  elif [ -f "$_box_file" ]; then
    printf '==> Registering %s (%s) from %s...\n' "$_box_name" "$_provider" "$_box_file"
    # shellcheck disable=SC2086
    vagrant box add --name "$_box_name" --provider "$_provider" $FORCE_FLAG "$_box_file"
    printf '[PASS] Registered %s (%s).\n' "$_box_name" "$_provider"
  else
    printf '[WARN] Box file %s not found; cannot register %s.\n' "$_box_file" "$_box_name" >&2
    return 0
  fi

  ensure_libvirt_qemu_links "$_box_name"
}

validate_bento_pkrvars

if [ "$VALIDATE_ONLY" -eq 1 ]; then
  exit 0
fi

if ! command -v vagrant >/dev/null 2>&1; then
  printf '[WARN] vagrant CLI not found on host; skipping box registration.\n' >&2
  exit 0
fi

EXISTING_BOXES=$(vagrant box list 2>/dev/null || true)
BUILD_COMPLETE="${BENTO_DIR}/builds/build_complete"

register_box_if_needed "${BENTO_PREFIX}/omnios" "$(resolve_box_artifact 'omnios-braich' 'qemu.box')" "$EXISTING_BOXES" "qemu"
register_box_if_needed "${BENTO_PREFIX}/alpine-3.24" "$(resolve_box_artifact 'alpine-3.24' 'qemu.box')" "$EXISTING_BOXES" "qemu"
register_box_if_needed "${BENTO_PREFIX}/debian-13" "$(resolve_box_artifact 'debian-13.6' 'qemu.box')" "$EXISTING_BOXES" "qemu"

ROCKY_BOX=$(resolve_box_artifact 'rockylinux-10.2' 'qemu.box')
ALMA_BOX=$(resolve_box_artifact 'almalinux-9.8' 'qemu.box')
if [ -f "$ROCKY_BOX" ]; then
  register_box_if_needed "${BENTO_PREFIX}/rockylinux-10.2" "$ROCKY_BOX" "$EXISTING_BOXES" "qemu"
elif [ -f "$ALMA_BOX" ]; then
  register_box_if_needed "${BENTO_PREFIX}/rockylinux-10.2" "$ALMA_BOX" "$EXISTING_BOXES" "qemu"
else
  register_box_if_needed "${BENTO_PREFIX}/rockylinux-10.2" "$ROCKY_BOX" "$EXISTING_BOXES" "qemu"
fi

register_box_if_needed "${BENTO_PREFIX}/freebsd-15.1" "$(resolve_box_artifact 'freebsd-15.1' 'qemu.box')" "$EXISTING_BOXES" "qemu"
if [ -f "${BUILD_COMPLETE}/macos-27.2-aarch64.utm.box" ]; then
  register_box_if_needed "${BENTO_PREFIX}/macos-27.2-arm64" "${BUILD_COMPLETE}/macos-27.2-aarch64.utm.box" "$EXISTING_BOXES" "utm"
  register_box_if_needed "${BENTO_PREFIX}/macos-14-arm64" "${BUILD_COMPLETE}/macos-27.2-aarch64.utm.box" "$EXISTING_BOXES" "utm"
else
  register_box_if_needed "${BENTO_PREFIX}/macos-14-arm64" "${BUILD_COMPLETE}/macos-14-aarch64.utm.box" "$EXISTING_BOXES" "utm"
fi
register_box_if_needed "${BENTO_PREFIX}/windows-11" "$(resolve_box_artifact 'windows-11' 'qemu.box')" "$EXISTING_BOXES" "qemu"

MSDOS_125_BOX=$(resolve_box_artifact 'msdos-1.25' 'qemu.box')
MSDOS_20_BOX=$(resolve_box_artifact 'msdos-2.0' 'qemu.box')
MSDOS_40_BOX=$(resolve_box_artifact 'msdos-4.0' 'qemu.box')
FREEDOS_13_BOX=$(resolve_box_artifact 'freedos-1.3' 'qemu.box')
FREEDOS_14_BOX=$(resolve_box_artifact 'freedos-1.4' 'qemu.box')

register_box_if_needed "${BENTO_PREFIX}/msdos-1.25" "$MSDOS_125_BOX" "$EXISTING_BOXES" "qemu"
register_box_if_needed "${BENTO_PREFIX}/msdos-2.0" "$MSDOS_20_BOX" "$EXISTING_BOXES" "qemu"
register_box_if_needed "${BENTO_PREFIX}/msdos-4.0" "$MSDOS_40_BOX" "$EXISTING_BOXES" "qemu"
register_box_if_needed "${BENTO_PREFIX}/freedos-1.3" "$FREEDOS_13_BOX" "$EXISTING_BOXES" "qemu"
register_box_if_needed "${BENTO_PREFIX}/freedos-1.4" "$FREEDOS_14_BOX" "$EXISTING_BOXES" "qemu"

if [ -f "$FREEDOS_14_BOX" ]; then
  register_box_if_needed "${BENTO_PREFIX}/freedos" "$FREEDOS_14_BOX" "$EXISTING_BOXES" "qemu"
elif [ -f "$FREEDOS_13_BOX" ]; then
  register_box_if_needed "${BENTO_PREFIX}/freedos" "$FREEDOS_13_BOX" "$EXISTING_BOXES" "qemu"
fi

if [ "$BENTO_PREFIX" != "anondos" ]; then
  register_box_if_needed "anondos/msdos-1.25" "$MSDOS_125_BOX" "$EXISTING_BOXES" "qemu"
  register_box_if_needed "anondos/msdos-2.0" "$MSDOS_20_BOX" "$EXISTING_BOXES" "qemu"
  register_box_if_needed "anondos/msdos-4.0" "$MSDOS_40_BOX" "$EXISTING_BOXES" "qemu"
  register_box_if_needed "anondos/freedos-1.3" "$FREEDOS_13_BOX" "$EXISTING_BOXES" "qemu"
  if [ -f "$FREEDOS_14_BOX" ]; then
    register_box_if_needed "anondos/freedos-1.4" "$FREEDOS_14_BOX" "$EXISTING_BOXES" "qemu"
  elif [ -f "$FREEDOS_13_BOX" ]; then
    register_box_if_needed "anondos/freedos-1.4" "$FREEDOS_13_BOX" "$EXISTING_BOXES" "qemu"
  else
    register_box_if_needed "anondos/freedos-1.4" "$FREEDOS_14_BOX" "$EXISTING_BOXES" "qemu"
  fi
fi

printf '=== Host Vagrant Box Inventory ===\n'
vagrant box list
exit 0
