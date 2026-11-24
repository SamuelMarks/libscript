#!/bin/sh
# ## Overview
# Unified CLI entrypoint to synthesize and package a Linux kernel or distribution profile
# into qcow2, raw, iso, vmdk, vdi, vhd, vagrant box, rootfs-tar, or direct-kernel formats.
#
# ## Usage
# synthesis/formats/linux_distro.sh --format <qcow2|raw|iso|vmdk|vdi|vhd|box|rootfs-tar|direct-kernel> --profile <profile_json> [--output <path>] [--dry-run] [--allow-stub] [--strict] [--offline]

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

FORMAT="${LIBSCRIPT_LINUX_DEFAULT_FORMAT:-qcow2}"
PROFILE="${LIBSCRIPT_LINUX_DEFAULT_PROFILE:-${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/linux/linux-minimal-headless-musl.json}"
OUTPUT=''
CLI_ARCH=''
INITRAMFS_COMPRESS="${LIBSCRIPT_INITRAMFS_COMPRESS:-}"
UKI_KEY="${LIBSCRIPT_UKI_KEY:-}"
UKI_CERT="${LIBSCRIPT_UKI_CERT:-}"
UKI_CMDLINE="${LIBSCRIPT_UKI_CMDLINE:-}"
DRY_RUN="${LIBSCRIPT_DRY_RUN:-0}"
STRICT_BUILD="${LIBSCRIPT_STRICT_IMAGE_BUILD:-0}"
ALLOW_STUB="${LIBSCRIPT_ALLOW_STUB:-0}"
OFFLINE_MODE="${LIBSCRIPT_OFFLINE:-0}"

# ## show_help
# Displays usage instructions for linux_distro.sh.
show_help() {
  printf 'Usage: %s [--format <qcow2|raw|iso|vmdk|vdi|vhd|box|rootfs-tar|direct-kernel|uki>] [--profile <path|preset>] [--arch <arch>] [--initramfs-compress <zstd|lz4|gzip>] [--output <path>] [--dry-run] [--allow-stub] [--strict] [--offline]\n' "$THIS_FILE"
}

# ## resolve_profile_path
# Resolves a file path or shorthand preset name under synthesis/profiles/ to an existing JSON file.
resolve_profile_path() {
  _rp_in="$1"
  if [ -f "$_rp_in" ]; then
    printf '%s\n' "$_rp_in"
    return 0
  fi
  if [ -f "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/${_rp_in}.json" ]; then
    printf '%s\n' "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/${_rp_in}.json"
    return 0
  fi
  if [ -f "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/linux/${_rp_in}.json" ]; then
    printf '%s\n' "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/linux/${_rp_in}.json"
    return 0
  fi
  if [ -f "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/lfs/${_rp_in}.json" ]; then
    printf '%s\n' "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/lfs/${_rp_in}.json"
    return 0
  fi
  printf '%s\n' "$_rp_in"
  return 0
}

# ## ensure_jq_ready
# Ensures jq is available on PATH or bootstrapped from _lib/utilities/jq.
ensure_jq_ready() {
  if command -v jq >/dev/null 2>&1; then
    return 0
  fi
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" ]; then
    _ej_this="${THIS_FILE}"
    _ej_dir="${SCRIPT_DIR}"
    _ej_stack="${STACK}"
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090,SC1091
    . "${SCRIPT_NAME}" >/dev/null 2>&1 || true
    unset SCRIPT_NAME || true
    THIS_FILE="${_ej_this}"
    SCRIPT_DIR="${_ej_dir}"
    STACK="${_ej_stack}"
    export STACK
  fi
  command -v jq >/dev/null 2>&1
}

# ## compute_profile_hash
# Computes a deterministic SHA-256 or byte-length fingerprint for a profile file.
compute_profile_hash() {
  _cph_file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$_cph_file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$_cph_file" | awk '{print $1}'
  else
    wc -c < "$_cph_file" | tr -d ' '
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --format|-f) FORMAT="$2"; shift 2 ;;
    --format=*) FORMAT="${1#*=}"; shift ;;
    --profile|-p) PROFILE="$2"; shift 2 ;;
    --profile=*) PROFILE="${1#*=}"; shift ;;
    --arch) CLI_ARCH="$2"; shift 2 ;;
    --arch=*) CLI_ARCH="${1#*=}"; shift ;;
    --initramfs-compress) INITRAMFS_COMPRESS="$2"; shift 2 ;;
    --initramfs-compress=*) INITRAMFS_COMPRESS="${1#*=}"; shift ;;
    --key) UKI_KEY="$2"; shift 2 ;;
    --key=*) UKI_KEY="${1#*=}"; shift ;;
    --cert) UKI_CERT="$2"; shift 2 ;;
    --cert=*) UKI_CERT="${1#*=}"; shift ;;
    --cmdline) UKI_CMDLINE="$2"; shift 2 ;;
    --cmdline=*) UKI_CMDLINE="${1#*=}"; shift ;;
    --output|-o|--out) OUTPUT="$2"; shift 2 ;;
    --output=*|--out=*) OUTPUT="${1#*=}"; shift ;;
    --dry-run) DRY_RUN='1'; shift ;;
    --strict) STRICT_BUILD='1'; ALLOW_STUB='0'; shift ;;
    --allow-stub) ALLOW_STUB='1'; STRICT_BUILD='0'; shift ;;
    --offline) OFFLINE_MODE='1'; shift ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      printf '[ERROR] Unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

PROFILE=$(resolve_profile_path "$PROFILE")
if [ ! -f "$PROFILE" ]; then
  printf '[ERROR] Linux profile not found: %s\n' "$PROFILE" >&2
  exit 1
fi

PBASE="${PROFILE##*/}"
PNAME="${PBASE%.json}"

KERNEL_ARG='linux-glibc'
EFF_ARCH="${CLI_ARCH:-}"
if ensure_jq_ready; then
  _os_fam=$(jq -r '.target.os_family // ""' "$PROFILE" 2>/dev/null || true)
  _libc=$(jq -r '.target.libc // ""' "$PROFILE" 2>/dev/null || true)
  if [ "$_os_fam" = 'linux-musl' ] || [ "$_libc" = 'musl' ]; then
    KERNEL_ARG='linux-musl'
  fi
  if [ -z "$EFF_ARCH" ]; then
    EFF_ARCH=$(jq -r '.target.arch // "x86_64"' "$PROFILE" 2>/dev/null || printf 'x86_64')
  fi
fi
[ -n "$EFF_ARCH" ] || EFF_ARCH='x86_64'

ARCH_SFX=''
if [ -n "$CLI_ARCH" ]; then
  ARCH_SFX="-${CLI_ARCH}"
fi

if [ -n "$INITRAMFS_COMPRESS" ]; then
  export LIBSCRIPT_INITRAMFS_COMPRESS="$INITRAMFS_COMPRESS"
fi
if [ -n "$UKI_KEY" ]; then
  export LIBSCRIPT_UKI_KEY="$UKI_KEY"
fi
if [ -n "$UKI_CERT" ]; then
  export LIBSCRIPT_UKI_CERT="$UKI_CERT"
fi
if [ -n "$UKI_CMDLINE" ]; then
  export LIBSCRIPT_UKI_CMDLINE="$UKI_CMDLINE"
fi

SYNTH_FMT="$FORMAT"
case "$FORMAT" in
  qcow2)
    : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/qemu/linux-${PNAME}${ARCH_SFX}.qcow2}"
    SYNTH_FMT='qcow2'
    ;;
  raw|raw-img)
    : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/raw/linux-${PNAME}${ARCH_SFX}.raw}"
    SYNTH_FMT='raw'
    ;;
  iso|live-iso)
    : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/iso/linux-${PNAME}${ARCH_SFX}.iso}"
    SYNTH_FMT='iso'
    ;;
  vmdk)
    : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/vmware/linux-${PNAME}${ARCH_SFX}.vmdk}"
    SYNTH_FMT='vmdk'
    ;;
  vdi)
    : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/virtualbox/linux-${PNAME}${ARCH_SFX}.vdi}"
    SYNTH_FMT='qcow2'
    ;;
  vhd|vhdx)
    : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/hyperv/linux-${PNAME}${ARCH_SFX}.vhd}"
    SYNTH_FMT='vhd'
    ;;
  box|vagrant-box)
    : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/vagrant/linux-${PNAME}${ARCH_SFX}.box}"
    SYNTH_FMT='vagrant-box'
    ;;
  rootfs-tar|oci-image)
    : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/rootfs/linux-${PNAME}${ARCH_SFX}.rootfs.tar.gz}"
    SYNTH_FMT='rootfs-tar'
    ;;
  uki)
    : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/uki/linux-${PNAME}-${EFF_ARCH}.efi}"
    SYNTH_FMT='uki'
    ;;
  direct-kernel|kernel)
    : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/direct-kernel/linux-${PNAME}${ARCH_SFX}}"
    SYNTH_FMT='direct-kernel'
    ;;
  *)
    printf '[ERROR] Unsupported Linux packaging format: %s\n' "$FORMAT" >&2
    printf 'Supported formats: qcow2, raw, iso, vmdk, vdi, vhd, box, rootfs-tar, direct-kernel, uki\n' >&2
    exit 1
    ;;
esac

ARCH_SYNTH_ARG=''
if [ -n "$CLI_ARCH" ]; then
  ARCH_SYNTH_ARG="--arch=${CLI_ARCH}"
fi

if [ "$DRY_RUN" = '1' ]; then
  printf '[DISTRO]   Validating Linux (%s, arch=%s) synthesis plan from %s (format=%s)...\n' "$KERNEL_ARG" "$EFF_ARCH" "$PROFILE" "$FORMAT"
  # shellcheck disable=SC2086
  STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/synthesize-image.sh" \
    --kernel="$KERNEL_ARG" \
    --profile="$PROFILE" \
    --format="$SYNTH_FMT" \
    --out="$OUTPUT" \
    $ARCH_SYNTH_ARG \
    --dry-run
  printf '[OK]       Linux dry-run plan verified (%s): %s\n' "$FORMAT" "$OUTPUT"
  exit 0
fi

STAMP_FILE="${OUTPUT}.stamp"
PROF_HASH=$(compute_profile_hash "$PROFILE")

if [ -f "$STAMP_FILE" ] && { [ -f "$OUTPUT" ] || [ -d "$OUTPUT" ]; }; then
  if grep -q "^profile_hash=${PROF_HASH}$" "$STAMP_FILE" 2>/dev/null && \
     grep -q "^format=${FORMAT}$" "$STAMP_FILE" 2>/dev/null && \
     grep -q "^arch=${EFF_ARCH}$" "$STAMP_FILE" 2>/dev/null; then
    if grep -q '^mode=stub$' "$STAMP_FILE" 2>/dev/null && [ "$STRICT_BUILD" = '1' ]; then
      rm -f "$STAMP_FILE"
    else
      printf '[SKIP]     Linux distribution artifact already synthesized: %s\n' "$OUTPUT"
      exit 0
    fi
  fi
fi

mkdir -p "$(dirname "$OUTPUT")"

if [ "$ALLOW_STUB" = '1' ] && [ ! -d '/proc/sys/kernel' ]; then
  # shellcheck disable=SC2086
  STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/synthesize-image.sh" \
    --kernel="$KERNEL_ARG" \
    --profile="$PROFILE" \
    --format="$SYNTH_FMT" \
    --out="$OUTPUT" \
    $ARCH_SYNTH_ARG \
    --dry-run
  _stub_sysroot="${LIBSCRIPT_BUILD_DIR:-${LIBSCRIPT_ROOT_DIR}/build}/linux-stub-sysroot-${PNAME}-${EFF_ARCH}"
  mkdir -p "${_stub_sysroot}/boot" "${_stub_sysroot}/etc"
  printf '%s\n' "$PNAME" > "${_stub_sysroot}/etc/hostname"
  export LIBSCRIPT_ALLOW_STUB='1'
  export LIBSCRIPT_STRICT_IMAGE_BUILD='0'
  export LIBSCRIPT_TARGET_ARCH="$EFF_ARCH"
  case "$SYNTH_FMT" in
    uki) STACK='' "${SCRIPT_DIR}/uki.sh" --arch="$EFF_ARCH" --allow-stub "$_stub_sysroot" "$OUTPUT" ;;
    direct-kernel) STACK='' "${SCRIPT_DIR}/direct_kernel.sh" --kernel=linux --arch="$EFF_ARCH" --allow-stub "$_stub_sysroot" "$OUTPUT" ;;
    raw) STACK='' "${SCRIPT_DIR}/raw_img.sh" --allow-stub "$_stub_sysroot" "$OUTPUT" 4 uefi ;;
    iso) STACK='' "${SCRIPT_DIR}/iso.sh" --allow-stub "$_stub_sysroot" "$OUTPUT" ;;
    rootfs-tar) STACK='' "${SCRIPT_DIR}/rootfs_tar.sh" "$_stub_sysroot" "$OUTPUT" ;;
    qcow2|vmdk)
      _raw_tmp="${OUTPUT}.raw.tmp"
      STACK='' "${SCRIPT_DIR}/raw_img.sh" --allow-stub "$_stub_sysroot" "$_raw_tmp" 4 uefi
      STACK='' "${SCRIPT_DIR}/qcow2.sh" "$_raw_tmp" "$OUTPUT" "$FORMAT"
      rm -f "$_raw_tmp" "${_raw_tmp}.stamp"
      ;;
    *) printf 'LibScript Linux Cross-Host Stub (%s)\n' "$FORMAT" > "$OUTPUT" ;;
  esac
else
  EXTRA_SYNTH_ARGS="$ARCH_SYNTH_ARG"
  [ "$STRICT_BUILD" = '1' ] && EXTRA_SYNTH_ARGS="${EXTRA_SYNTH_ARGS} --strict"
  [ "$ALLOW_STUB" = '1' ] && EXTRA_SYNTH_ARGS="${EXTRA_SYNTH_ARGS} --allow-stub"
  [ "$OFFLINE_MODE" = '1' ] && EXTRA_SYNTH_ARGS="${EXTRA_SYNTH_ARGS} --offline"

  printf '[DISTRO]   Synthesizing Linux (%s, arch=%s) artifact from %s...\n' "$KERNEL_ARG" "$EFF_ARCH" "$PROFILE"

  if [ "$FORMAT" = 'vdi' ]; then
    _tmp_qcow="${OUTPUT}.qcow2.tmp"
    # shellcheck disable=SC2086
    STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/synthesize-image.sh" \
      --kernel="$KERNEL_ARG" \
      --profile="$PROFILE" \
      --format='qcow2' \
      --out="$_tmp_qcow" \
      $EXTRA_SYNTH_ARGS
    STACK='' "${SCRIPT_DIR}/qcow2.sh" "$_tmp_qcow" "$OUTPUT" 'vdi'
    rm -f "$_tmp_qcow" "${_tmp_qcow}.stamp"
  else
    # shellcheck disable=SC2086
    STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/synthesize-image.sh" \
      --kernel="$KERNEL_ARG" \
      --profile="$PROFILE" \
      --format="$SYNTH_FMT" \
      --out="$OUTPUT" \
      $EXTRA_SYNTH_ARGS
  fi
fi

STAMP_MODE='native'
[ "$ALLOW_STUB" = '1' ] && STAMP_MODE='stub'
printf 'format=%s\nkernel=%s\narch=%s\nprofile=%s\nprofile_hash=%s\nmode=%s\ntimestamp=%s\n' \
  "$FORMAT" "$KERNEL_ARG" "$EFF_ARCH" "$PROFILE" "$PROF_HASH" "$STAMP_MODE" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"

printf '[OK]       Linux distribution packaged as %s: %s\n' "$FORMAT" "$OUTPUT"
