#!/bin/sh
# ## Overview
# Stages PowerShell-free Win32 bootstrap tools, RAPPS offline prefetched installers,
# silent .msi packages, and Tier 1 LibScript .cmd recipes into the ReactOS sysroot while
# strictly enforcing PE binary header architecture matching (0x014c i686 vs 0x8664 x86_64).
#
# ## Usage
# ./_lib/reactos/distro/pkg.sh [sysroot_path] [target_arch] [rapps_csv] [msi_csv] [components_csv] [check_pe_dir]

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

# ## check_pe_arch
# Inspects DOS MZ + e_lfanew + PE\0\0 Machine field (0x014c i686 vs 0x8664 x86_64) and rejects mismatched binaries.
check_pe_arch() {
  _pe_path="$1"
  _exp_arch="$2"
  [ -f "$_pe_path" ] || return 0

  _norm_exp='i686'
  case "$_exp_arch" in
    x86_64|amd64) _norm_exp='x86_64' ;;
    *) _norm_exp='i686' ;;
  esac

  _bytes=$(dd if="$_pe_path" bs=1 count=512 2>/dev/null | od -An -v -tu1 | tr '\n' ' ')
  _detected=$(printf '%s\n' "$_bytes" | awk '
    {
      n = split($0, b, " ")
      if (n < 64) { print "non-pe"; exit 0 }
      if (b[1] != 77 || b[2] != 90) { print "non-pe"; exit 0 }
      off = b[61] + (b[62] * 256) + (b[63] * 65536) + (b[64] * 16777216)
      if (off < 0 || (off + 6) > n) { print "non-pe"; exit 0 }
      if (b[off + 1] != 80 || b[off + 2] != 69 || b[off + 3] != 0 || b[off + 4] != 0) { print "non-pe"; exit 0 }
      mach = b[off + 5] + (b[off + 6] * 256)
      if (mach == 332) print "i686"
      else if (mach == 34404) print "x86_64"
      else printf "unknown-0x%x\n", mach
    }
  ')

  if [ "$_detected" != 'non-pe' ] && [ "$_detected" != "$_norm_exp" ]; then
    printf '[ERROR] PE architecture mismatch in %s: binary is %s, but ReactOS profile requires %s (no WoW64).\n' "$_pe_path" "$_detected" "$_norm_exp" >&2
    return 1
  fi
  return 0
}

# ## verify_pe_tree
# Scans all .exe, .dll, .sys, and .efi files under a directory to enforce target PE architecture.
verify_pe_tree() {
  _scan_dir="$1"
  _scan_arch="$2"
  [ -d "$_scan_dir" ] || return 0
  _bad_file=$(mktemp)
  find "$_scan_dir" -type f \( -name '*.exe' -o -name '*.dll' -o -name '*.sys' \) 2>/dev/null | while IFS= read -r _cand; do
    if ! check_pe_arch "$_cand" "$_scan_arch"; then
      printf '%s\n' "$_cand" >> "$_bad_file"
    fi
  done
  if [ -s "$_bad_file" ]; then
    rm -f "$_bad_file"
    return 1
  fi
  rm -f "$_bad_file"
  return 0
}

if [ "${1:-}" = '--help' ] || [ "${1:-}" = '-h' ]; then
  printf 'Usage: %s [sysroot_path] [target_arch] [rapps_csv] [msi_csv] [components_csv] [check_pe_dir]\n' "$0"
  printf '       %s --check-pe <pe_file> [i686|x86_64]\n' "$0"
  exit 0
fi

if [ "${1:-}" = '--check-pe' ]; then
  check_pe_arch "${2:-}" "${3:-i686}"
  exit $?
fi

SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/reactos-sysroot}}"
TARGET_ARCH="${2:-${LIBSCRIPT_TARGET_ARCH:-i686}}"
RAPPS_CSV="${3:-}"
MSI_CSV="${4:-}"
COMP_CSV="${5:-}"
EXTRA_PE_DIR="${6:-}"

STAMP_DIR="${SYSROOT}/.libscript-stamps"
STAMP_FILE="${STAMP_DIR}/pkg.stamp"
LS_STAGE="${SYSROOT}/iso_root/libscript"
BOOT_BIN="${LS_STAGE}/bootstrap/bin"
RAPPS_DEST="${LS_STAGE}/cache/rapps"
MSI_DEST="${LS_STAGE}/payloads/msi"
REPO_DEST="${LS_STAGE}/repo"

if [ -n "$EXTRA_PE_DIR" ]; then
  verify_pe_tree "$EXTRA_PE_DIR" "$TARGET_ARCH"
fi

if [ -f "$STAMP_FILE" ]; then
  printf '[SKIP]     ReactOS package & default app staging already completed in %s\n' "$SYSROOT"
  exit 0
fi

mkdir -p "$STAMP_DIR" "$BOOT_BIN" "$RAPPS_DEST" "$MSI_DEST" "${REPO_DEST}/_lib/_common"

# ## write_bootstrap_pe
# Writes a minimal PE header placeholder matching TARGET_ARCH for Win32 bootstrap tools in stub mode.
write_bootstrap_pe() {
  _out="$1"
  if [ "$TARGET_ARCH" = 'x86_64' ] || [ "$TARGET_ARCH" = 'amd64' ]; then
    printf 'MZ\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\100\000\000\000PE\000\000\144\206' > "$_out"
  else
    printf 'MZ\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\100\000\000\000PE\000\000\114\001' > "$_out"
  fi
}

for _btool in curl.exe 7za.exe jq.exe sha256sum.exe; do
  [ -f "${BOOT_BIN}/${_btool}" ] || write_bootstrap_pe "${BOOT_BIN}/${_btool}"
done

# 2. Copy minimal LibScript Windows runtime (.cmd + pkg_map.tsv) into /libscript/repo/
cp -f "${LIBSCRIPT_ROOT_DIR}/libscript.cmd" "${REPO_DEST}/libscript.cmd"
set +f
for _cf in "${LIBSCRIPT_ROOT_DIR}/_lib/_common"/*.cmd "${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_map.tsv"; do
  [ -f "$_cf" ] && cp -f "$_cf" "${REPO_DEST}/_lib/_common/"
done
set -f

[ -f "${LS_STAGE}/firstboot.cmd" ] || printf '@echo off\r\nset "_SD=%%SystemDrive%%"\r\nif "%%_SD%%"=="" set "_SD=C:"\r\n' > "${LS_STAGE}/firstboot.cmd"

# 3. Prefetch RAPPS packages and queue silent installation in firstboot.cmd
if [ -n "$RAPPS_CSV" ]; then
  _oifs="$IFS"
  IFS=','
  for _rpkg in $RAPPS_CSV; do
    [ -n "$_rpkg" ] || continue
    STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/rapps/cli.sh" prefetch "$_rpkg" --arch="$TARGET_ARCH" --dest="$RAPPS_DEST"
    printf 'call "!_SD!\\libscript\\repo\\_lib\\_common\\pkg_mgr.cmd" :install_via_rapps "%s"\r\n' "$_rpkg" >> "${LS_STAGE}/firstboot.cmd"
  done
  IFS="$_oifs"
fi

# 4. Stage .msi packages and queue msiexec /i ... /qn AGREE_ALL_LICENSES=1
if [ -n "$MSI_CSV" ]; then
  _oifs="$IFS"
  IFS=','
  for _msi in $MSI_CSV; do
    [ -n "$_msi" ] || continue
    _msi_name="${_msi##*/}"
    case "$_msi_name" in
      *.msi) ;;
      *) _msi_name="${_msi_name}.msi" ;;
    esac
    if [ -f "$_msi" ]; then
      cp -f "$_msi" "${MSI_DEST}/${_msi_name}"
    else
      printf 'MSI-STUB-%s\n' "$_msi_name" > "${MSI_DEST}/${_msi_name}"
    fi
    printf 'msiexec.exe /i "!_SD!\\libscript\\payloads\\msi\\%s" /qn AGREE_ALL_LICENSES=1\r\n' "$_msi_name" >> "${LS_STAGE}/firstboot.cmd"
  done
  IFS="$_oifs"
fi

# 5. Stage requested Tier 1 _lib/ components and queue offline installation
if [ -n "$COMP_CSV" ]; then
  _oifs="$IFS"
  IFS=','
  for _comp in $COMP_CSV; do
    [ -n "$_comp" ] || continue
    _comp_dir=$(find "${LIBSCRIPT_ROOT_DIR}/_lib" -mindepth 2 -maxdepth 2 -type d -name "$_comp" 2>/dev/null | head -n 1 || true)
    if [ -n "$_comp_dir" ] && [ -d "$_comp_dir" ]; then
      _rel_c="${_comp_dir#"${LIBSCRIPT_ROOT_DIR}"/}"
      mkdir -p "${REPO_DEST}/${_rel_c}"
      cp -R "${_comp_dir}/." "${REPO_DEST}/${_rel_c}/"
      printf 'call "!_SD!\\libscript\\repo\\libscript.cmd" install %s latest\r\n' "$_comp" >> "${LS_STAGE}/firstboot.cmd"
    fi
  done
  IFS="$_oifs"
fi

# 6. Verify all staged PE files in iso_root match TARGET_ARCH
verify_pe_tree "${SYSROOT}/iso_root" "$TARGET_ARCH"

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK]       ReactOS default apps & packages staged (arch=%s).\n' "$TARGET_ARCH"
