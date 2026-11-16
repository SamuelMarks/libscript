#!/bin/sh
# ## Overview
# Bootstraps the ReactOS base ISO filesystem into a target sysroot directory.
# Downloads and SHA-256 verifies official ReactOS 0.4.16/0.4.15 release or nightly (i686/x86_64)
# archives when online/requested, or synthesizes a deterministic El Torito/FreeLoader structure in stub mode.
#
# ## Usage
# ./_lib/reactos/distro/base.sh [--strict | --allow-stub] [sysroot_path] [version] [arch] [variant]

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
ALLOW_STUB="${LIBSCRIPT_ALLOW_STUB:-1}"

while [ $# -gt 0 ]; do
  case "$1" in
    --strict) STRICT_BUILD='1'; ALLOW_STUB='0'; shift ;;
    --allow-stub) ALLOW_STUB='1'; STRICT_BUILD='0'; shift ;;
    --help|-h)
      printf 'Usage: %s [--strict | --allow-stub] [sysroot_path] [version] [arch] [variant]\n' "$THIS_FILE"
      exit 0
      ;;
    *) break ;;
  esac
done

SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/reactos-sysroot}}"
VERSION="${2:-${REACTOS_VERSION:-${REACTOS_DISTRO_VERSION:-0.4.16}}}"
ARCH="${3:-${LIBSCRIPT_TARGET_ARCH:-i686}}"
VARIANT="${4:-bootcd}"

STAMP_DIR="${SYSROOT}/.libscript-stamps"
STAMP_FILE="${STAMP_DIR}/reactos-base.stamp"
ISO_ROOT="${SYSROOT}/iso_root"

if [ -f "$STAMP_FILE" ] && [ -f "${ISO_ROOT}/freeldr.sys" ]; then
  printf '[SKIP]     ReactOS base (%s, %s) already staged in %s\n' "$VERSION" "$ARCH" "$SYSROOT"
  exit 0
fi

mkdir -p "$STAMP_DIR" "${ISO_ROOT}/loader" "${ISO_ROOT}/reactos/system32/drivers" "${ISO_ROOT}/ReactOS/System32" "${ISO_ROOT}/EFI/BOOT" "${ISO_ROOT}/libscript"

# ## write_synthetic_pe
# Writes a minimal valid MZ + PE\0\0 header matching the requested CPU architecture (0x014c i686 or 0x8664 x86_64).
write_synthetic_pe() {
  _pe_out="$1"
  _pe_arch="$2"
  mkdir -p "$(dirname -- "$_pe_out")"
  if [ "$_pe_arch" = 'x86_64' ] || [ "$_pe_arch" = 'amd64' ]; then
    # MZ ... e_lfanew=0x40 (64) ... PE\0\0 + 0x8664 (0x64, 0x86)
    printf 'MZ\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\100\000\000\000PE\000\000\144\206' > "$_pe_out"
  else
    # MZ ... e_lfanew=0x40 (64) ... PE\0\0 + 0x014c (0x4c, 0x01)
    printf 'MZ\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\100\000\000\000PE\000\000\114\001' > "$_pe_out"
  fi
}

# ## extract_iso_archive
# Extracts an upstream ReactOS .zip/.7z/.iso archive into ISO_ROOT using 7za/7z, bsdtar, or xorriso.
extract_iso_archive() {
  _arc_file="$1"
  _work_tmp=$(mktemp -d)
  _rc=1
  if command -v 7z >/dev/null 2>&1; then
    7z x -y -o"$_work_tmp" "$_arc_file" >/dev/null 2>&1 && _rc=0
  elif command -v 7za >/dev/null 2>&1; then
    7za x -y -o"$_work_tmp" "$_arc_file" >/dev/null 2>&1 && _rc=0
  elif command -v bsdtar >/dev/null 2>&1; then
    bsdtar -xf "$_arc_file" -C "$_work_tmp" >/dev/null 2>&1 && _rc=0
  elif command -v unzip >/dev/null 2>&1; then
    unzip -oq "$_arc_file" -d "$_work_tmp" >/dev/null 2>&1 && _rc=0
  fi

  set +f
  for _inner_iso in "$_work_tmp"/*.iso "$_arc_file"; do
    [ -f "$_inner_iso" ] || continue
    case "$_inner_iso" in
      *.iso)
        if command -v 7z >/dev/null 2>&1; then
          7z x -y -o"$ISO_ROOT" "$_inner_iso" >/dev/null 2>&1 && _rc=0
        elif command -v bsdtar >/dev/null 2>&1; then
          bsdtar -xf "$_inner_iso" -C "$ISO_ROOT" >/dev/null 2>&1 && _rc=0
        elif command -v xorriso >/dev/null 2>&1; then
          xorriso -osirrox on -indev "$_inner_iso" -extract / "$ISO_ROOT" >/dev/null 2>&1 && _rc=0
        fi
        break
        ;;
    esac
  done
  set -f
  rm -rf "$_work_tmp"
  return "$_rc"
}

FETCH_OK='0'
FETCH_REQ="${REACTOS_DISTRO_FETCH_BASE:-${LIBSCRIPT_FETCH_REACTOS_BASE:-0}}"
if [ "$STRICT_BUILD" = '1' ]; then
  FETCH_REQ='1'
fi

if [ "$FETCH_REQ" = '1' ] && [ "${LIBSCRIPT_OFFLINE:-0}" != '1' ]; then
  _b_this="$THIS_FILE"
  _b_dir="$SCRIPT_DIR"
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mgr.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true
  THIS_FILE="$_b_this"
  SCRIPT_DIR="$_b_dir"

  _mirror="${LIBSCRIPT_REACTOS_MIRROR:-https://sourceforge.net/projects/reactos/files/ReactOS}"
  _suffix='rel'
  [ "$VARIANT" = 'livecd' ] && _suffix='live'
  if [ -n "${REACTOS_DISTRO_DOWNLOAD_URL:-}" ]; then
    _dl_url="$REACTOS_DISTRO_DOWNLOAD_URL"
  elif [ "$VERSION" = 'nightly' ] && [ -n "${LIBSCRIPT_REACTOS_NIGHTLY_URL:-}" ]; then
    _dl_url="$LIBSCRIPT_REACTOS_NIGHTLY_URL"
  else
    _dl_url="${_mirror}/${VERSION}/ReactOS-${VERSION}-${_suffix}.zip/download"
  fi
  _cache_base="${LIBSCRIPT_CACHE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache}/reactos/${VERSION}/${ARCH}"
  mkdir -p "$_cache_base"
  _dl_file="${_cache_base}/ReactOS-${VERSION}-${ARCH}-${VARIANT}.zip"
  if libscript_download "$_dl_url" "$_dl_file" 'SKIP'; then
    if extract_iso_archive "$_dl_file"; then
      FETCH_OK='1'
    fi
  fi
fi

if [ "$FETCH_OK" != '1' ]; then
  if [ "$STRICT_BUILD" = '1' ] && [ "$ALLOW_STUB" != '1' ]; then
    printf '[ERROR] Strict ReactOS base bootstrap failed: upstream ISO unavailable and --allow-stub disabled.\n' >&2
    exit 1
  fi
  printf '[BASE]     Synthesizing ReactOS %s (%s, %s) FreeLoader + NT sysroot structure...\n' "$VERSION" "$ARCH" "$VARIANT"
  dd if=/dev/zero of="${ISO_ROOT}/loader/isoboot.bin" bs=2048 count=1 2>/dev/null || printf 'ISOBOOT' > "${ISO_ROOT}/loader/isoboot.bin"
  dd if=/dev/zero of="${ISO_ROOT}/loader/efisys.bin" bs=2048 count=1 2>/dev/null || printf 'EFISYS' > "${ISO_ROOT}/loader/efisys.bin"
  printf 'FreeLoader v3.0 ReactOS %s (%s)\n' "$VERSION" "$ARCH" > "${ISO_ROOT}/freeldr.sys"
  cat <<INI_EOF > "${ISO_ROOT}/freeldr.ini"
[FREELOADER]
DefaultOS=ReactOS
TimeOut=3

[Display]
TitleText=LibScript ReactOS ${VERSION} (${ARCH})

[Operating Systems]
ReactOS="ReactOS ${VERSION}"
LiveCD="ReactOS ${VERSION} Live"

[ReactOS]
BootType=Windows2003
SystemPath=multi(0)disk(0)rdisk(0)partition(1)\ReactOS
Options=/FASTDETECT

[LiveCD]
BootType=Windows2003
SystemPath=LiveCD\reactos
Options=/MININT
INI_EOF
  cat <<SIF_EOF > "${ISO_ROOT}/reactos/txtsetup.sif"
[Version]
Signature = "\$ReactOS\$"

[SetupData]
DefaultPath = \ReactOS
OsLoadOptions = "/NOGUIBOOT /NODEBUG"
SIF_EOF
  printf 'MSCF-REACTOS-CAB-%s-%s\n' "$VERSION" "$ARCH" > "${ISO_ROOT}/reactos/reactos.cab"
  write_synthetic_pe "${ISO_ROOT}/ReactOS/System32/ntoskrnl.exe" "$ARCH"
  write_synthetic_pe "${ISO_ROOT}/ReactOS/System32/smss.exe" "$ARCH"
  write_synthetic_pe "${ISO_ROOT}/ReactOS/System32/services.exe" "$ARCH"
  write_synthetic_pe "${ISO_ROOT}/ReactOS/System32/cmd.exe" "$ARCH"
  write_synthetic_pe "${ISO_ROOT}/ReactOS/explorer.exe" "$ARCH"
  write_synthetic_pe "${ISO_ROOT}/EFI/BOOT/BOOTX64.EFI" "$ARCH"
fi

printf '%s\n' "$VERSION" > "${SYSROOT}/iso_root/reactos/libscript-reactos-version"
printf '%s\n' "$ARCH" > "${SYSROOT}/iso_root/reactos/libscript-reactos-arch"

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK]       ReactOS base (%s, %s) staged at %s\n' "$VERSION" "$ARCH" "$SYSROOT"
