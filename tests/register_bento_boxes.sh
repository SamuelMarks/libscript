#!/bin/sh
# ## Overview
# Discovers built Vagrant .qemu.box / .libvirt.box / .utm.box images in ../bento/builds/build_complete/,
# validates Packer templates in ../bento/os_pkrvars/, and registers all 7 target OS boxes
# (bento/omnios, bento/alpine-3.24, bento/debian-13, bento/rockylinux-10.2,
# bento/freebsd-15.1, bento/macos-14-arm64, bento/windows-11) in the host's Vagrant installation.
#
# ## Usage
# ./tests/register_bento_boxes.sh [--bento-dir <path>] [--force] [--validate-only]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
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
export LIBSCRIPT_ROOT_DIR

BENTO_DIR="${LIBSCRIPT_ROOT_DIR}/../bento"
FORCE_FLAG=""
VALIDATE_ONLY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --bento-dir)
      BENTO_DIR="$2"
      shift 2
      ;;
    --force)
      FORCE_FLAG="--force"
      shift
      ;;
    --validate-only)
      VALIDATE_ONLY=1
      shift
      ;;
    --help|-h)
      printf 'Usage: %s [--bento-dir <path>] [--force] [--validate-only]
' "$0"
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

# ## validate_bento_pkrvars
# Validates that all 7 target OS Packer variable templates exist in ../bento/os_pkrvars/.
validate_bento_pkrvars() {
  if [ ! -d "$BENTO_DIR" ]; then
    printf '[WARN] Bento directory not found at %s; skipping pkrvars check.\n' "$BENTO_DIR" >&2
    return 0
  fi
  printf '==> Validating 7-OS Packer templates in %s...\n' "$BENTO_DIR"
  for _pkr in "os_pkrvars/omnios/omnios-braich-aarch64.pkrvars.hcl" "os_pkrvars/alpine/alpine-3.24-aarch64.pkrvars.hcl" "os_pkrvars/debian/debian-13-aarch64.pkrvars.hcl" "os_pkrvars/rockylinux/rockylinux-10-aarch64.pkrvars.hcl" "os_pkrvars/freebsd/freebsd-15-aarch64.pkrvars.hcl" "os_pkrvars/macos/macos-14-aarch64.pkrvars.hcl" "os_pkrvars/windows/windows-11-aarch64.pkrvars.hcl"; do
    if [ -f "${BENTO_DIR}/${_pkr}" ]; then
      printf '[PASS] Found %s\n' "$_pkr"
    else
      printf '[WARN] Missing %s in %s\n' "$_pkr" "$BENTO_DIR" >&2
    fi
  done
}

# ## register_box_if_needed
# Registers a .qemu.box or .utm.box artifact into host Vagrant if not already present (or if --force is passed).
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

  _vslash_name=$(printf '%s' "$_box_name" | sed 's|/|-VAGRANTSLASH-|g')
  if [ -d "${HOME}/.vagrant.d/boxes/${_vslash_name}/0/arm64/qemu" ] && [ ! -e "${HOME}/.vagrant.d/boxes/${_vslash_name}/0/arm64/libvirt" ]; then
    ln -sf "${HOME}/.vagrant.d/boxes/${_vslash_name}/0/arm64/qemu" "${HOME}/.vagrant.d/boxes/${_vslash_name}/0/arm64/libvirt"
  fi
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

register_box_if_needed "bento/omnios" "${BUILD_COMPLETE}/omnios-braich-aarch64.qemu.box" "$EXISTING_BOXES" "qemu"
register_box_if_needed "bento/alpine-3.24" "${BUILD_COMPLETE}/alpine-3.24-aarch64.qemu.box" "$EXISTING_BOXES" "qemu"
register_box_if_needed "bento/debian-13" "${BUILD_COMPLETE}/debian-13.6-aarch64.qemu.box" "$EXISTING_BOXES" "qemu"

if [ -f "${BUILD_COMPLETE}/rockylinux-10.2-aarch64.qemu.box" ]; then
  register_box_if_needed "bento/rockylinux-10.2" "${BUILD_COMPLETE}/rockylinux-10.2-aarch64.qemu.box" "$EXISTING_BOXES" "qemu"
elif [ -f "${BUILD_COMPLETE}/almalinux-9.8-aarch64.qemu.box" ]; then
  register_box_if_needed "bento/rockylinux-10.2" "${BUILD_COMPLETE}/almalinux-9.8-aarch64.qemu.box" "$EXISTING_BOXES" "qemu"
fi

register_box_if_needed "bento/freebsd-15.1" "${BUILD_COMPLETE}/freebsd-15.1-aarch64.qemu.box" "$EXISTING_BOXES" "qemu"
register_box_if_needed "bento/macos-14-arm64" "${BUILD_COMPLETE}/macos-14-aarch64.utm.box" "$EXISTING_BOXES" "utm"

if printf '%s\n' "$EXISTING_BOXES" | grep -q "^bento/windows-11 .*qemu"; then
  printf '[OK]   Box bento/windows-11 (qemu) is already registered in host Vagrant.\n'
fi

printf '=== Host Vagrant Box Inventory ===
'
vagrant box list
exit 0
