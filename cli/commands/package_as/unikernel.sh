#!/bin/sh
# ## Overview
# Kernel-dispatching unikernel packager supporting Unikraft, Nanos/Ops, OSv, Rumprun,
# and MirageOS across QEMU, Firecracker, Cloud-Hypervisor, bhyve, Xen, and Solo5.
# ## Usage
# ./cli/commands/package_as/unikernel.sh [--framework=<fw>] [--vmm=<vmm>] [--strict | --allow-stub] [app_dir] [output_image]

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

FRAMEWORK="${LIBSCRIPT_UNIKERNEL_FRAMEWORK:-unikraft}"
VMM='qemu'
STRICT_BUILD="${LIBSCRIPT_STRICT_IMAGE_BUILD:-0}"
ALLOW_STUB="${LIBSCRIPT_ALLOW_STUB:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)
      printf 'Usage: %s [--framework=unikraft|nanos|osv|rumprun|mirageos] [--vmm=qemu|firecracker|cloud-hypervisor|bhyve|xen|solo5-hvt|solo5-spt] [--strict | --allow-stub] [app_dir] [output_image]\n' "$(basename "$THIS_FILE")"
      exit 0
      ;;
    --framework=*) FRAMEWORK="${1#*=}"; shift ;;
    --vmm=*) VMM="${1#*=}"; shift ;;
    --strict) STRICT_BUILD=1; shift ;;
    --allow-stub) ALLOW_STUB=1; shift ;;
    *) break ;;
  esac
done

case "$FRAMEWORK" in
  unikernel-*) FRAMEWORK="${FRAMEWORK#unikernel-}" ;;
  linux|freebsd|sunos) FRAMEWORK='unikraft' ;;
esac

APP_DIR="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}}"
OUT_ELF="${2:-${LIBSCRIPT_ROOT_DIR}/build/images/unikernel/app.unikernel.elf}"
STAMP_FILE="${OUT_ELF}.stamp"

# ## has_unikernel_sdk
# Checks whether the requested unikernel framework SDK binary is installed on the host.
has_unikernel_sdk() {
  case "$FRAMEWORK" in
    unikraft) command -v kraft >/dev/null 2>&1 ;;
    nanos|ops) command -v ops >/dev/null 2>&1 ;;
    osv) command -v capstan >/dev/null 2>&1 ;;
    rumprun) command -v rumpbake >/dev/null 2>&1 ;;
    mirage|mirageos) command -v mirage >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

if [ -f "$STAMP_FILE" ] && [ -s "$OUT_ELF" ]; then
  if grep -q '^mode=stub$' "$STAMP_FILE" 2>/dev/null; then
    if [ "$STRICT_BUILD" = "1" ] || has_unikernel_sdk; then
      rm -f "$STAMP_FILE"
    else
      printf '[SKIP] Unikernel image already synthesized (stub): %s\n' "$OUT_ELF"
      exit 0
    fi
  else
    printf '[SKIP] Unikernel image already synthesized: %s\n' "$OUT_ELF"
    exit 0
  fi
fi

mkdir -p "$(dirname "$OUT_ELF")" "$APP_DIR"
WORK_UK="${LIBSCRIPT_ROOT_DIR}/build/unikernel_stage_$$"
mkdir -p "$WORK_UK"
trap 'rm -rf "$WORK_UK"' EXIT INT TERM HUP

printf '[PACKAGE] Synthesizing %s unikernel image (vmm=%s) -> %s...\n' "$FRAMEWORK" "$VMM" "$OUT_ELF"
BUILT_NATIVE=0

case "$FRAMEWORK" in
  unikraft)
    _uk_plat='qemu'
    case "$VMM" in
      firecracker|fc) _uk_plat='fc' ;;
      xen) _uk_plat='xen' ;;
    esac
    cat << KRAFT_EOF > "${WORK_UK}/Kraftfile"
spec: v0.6
name: libscript-app
unikraft:
  version: stable
targets:
  - architecture: x86_64
    platform: ${_uk_plat}
rootfs: ${APP_DIR}
KRAFT_EOF
    if command -v cpio >/dev/null 2>&1; then
      (cd "$APP_DIR" && find . | cpio -H newc -o 2>/dev/null > "${OUT_ELF}.initrd.cpio") || true
    fi
    if command -v kraft >/dev/null 2>&1; then
      (cd "$WORK_UK" && kraft build --plat "$_uk_plat" --arch x86_64) >/dev/null 2>&1 || true
      _kbin=$(find "$WORK_UK" -name "*_${_uk_plat}-x86_64" -type f | head -n 1 || true)
      if [ -n "$_kbin" ] && [ -s "$_kbin" ]; then
        cp -f "$_kbin" "$OUT_ELF"
        BUILT_NATIVE=1
      fi
    fi
    ;;

  nanos|ops)
    _elf_target=''
    for _cand in "${APP_DIR}"/opt/libscript/*/*/bin/* "${APP_DIR}"/usr/local/bin/* "${APP_DIR}"/usr/bin/*; do
      if [ -f "$_cand" ] && [ -x "$_cand" ]; then
        _elf_target="$_cand"
        break
      fi
    done
    cat << OPS_EOF > "${WORK_UK}/ops.config.json"
{
  "Dirs": ["${APP_DIR}"],
  "MapDirs": {"${APP_DIR}/*": "/*"},
  "RunConfig": {
    "Memory": "512M"
  }
}
OPS_EOF
    if command -v ops >/dev/null 2>&1 && [ -n "$_elf_target" ]; then
      OPS_DIR="${LIBSCRIPT_HOME:-${HOME:-/tmp}/.libscript}/nanos/ops_home" \
        ops build "$_elf_target" -c "${WORK_UK}/ops.config.json" -i libscript-nanos-app >/dev/null 2>&1 || true
      _ops_img=$(find "${LIBSCRIPT_HOME:-${HOME:-/tmp}/.libscript}/nanos" -name "libscript-nanos-app*" -type f 2>/dev/null | head -n 1 || true)
      if [ -n "$_ops_img" ] && [ -s "$_ops_img" ]; then
        cp -f "$_ops_img" "$OUT_ELF"
        BUILT_NATIVE=1
      fi
    fi
    ;;

  osv)
    cat << OSV_EOF > "${WORK_UK}/Capstanfile"
base: cloudius/osv-base
cmdline: /libscript-entrypoint.so
files:
  /etc/hosts: ${WORK_UK}/hosts
OSV_EOF
    printf '127.0.0.1 localhost osv-app\n' > "${WORK_UK}/hosts"
    if command -v capstan >/dev/null 2>&1; then
      (cd "$WORK_UK" && capstan build libscript-osv-app) >/dev/null 2>&1 || true
      _osv_img="${HOME:-/tmp}/.capstan/repository/libscript-osv-app/libscript-osv-app.qemu"
      if [ -s "$_osv_img" ]; then
        cp -f "$_osv_img" "$OUT_ELF"
        BUILT_NATIVE=1
      fi
    fi
    ;;

  rumprun)
    _rump_target='hw_virtio'
    if [ "$VMM" = "xen" ]; then
      _rump_target='xen_pv'
    fi
    if command -v rumpbake >/dev/null 2>&1; then
      _rbin=$(find "$APP_DIR" -type f -perm -111 2>/dev/null | head -n 1 || true)
      if [ -n "$_rbin" ]; then
        rumpbake "$_rump_target" "$OUT_ELF" "$_rbin" >/dev/null 2>&1 || true
        if [ -s "$OUT_ELF" ]; then
          BUILT_NATIVE=1
        fi
      fi
    fi
    ;;

  mirage|mirageos)
    _mir_target='hvt'
    if [ "$VMM" = "solo5-spt" ]; then
      _mir_target='spt'
    elif [ "$VMM" = "xen" ]; then
      _mir_target='xen'
    fi
    if command -v mirage >/dev/null 2>&1 && [ -f "${APP_DIR}/config.ml" ]; then
      (cd "$APP_DIR" && mirage configure -t "$_mir_target" && make depend && mirage build) >/dev/null 2>&1 || true
      _mbin=$(find "${APP_DIR}/dist" -name "*.${_mir_target}" -type f 2>/dev/null | head -n 1 || true)
      if [ -n "$_mbin" ] && [ -s "$_mbin" ]; then
        cp -f "$_mbin" "$OUT_ELF"
        BUILT_NATIVE=1
      fi
    fi
    ;;
esac

cp -f "${WORK_UK}"/* "$(dirname "$OUT_ELF")/" 2>/dev/null || true

if [ "$BUILT_NATIVE" -eq 1 ]; then
  chmod +x "$OUT_ELF" 2>/dev/null || true
  printf 'mode=native\nframework=%s\nvmm=%s\ntimestamp=%s\n' "$FRAMEWORK" "$VMM" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
  mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
  printf '[OK] Synthesized %s unikernel image (%s): %s\n' "$FRAMEWORK" "$VMM" "$OUT_ELF"
  exit 0
fi

if [ "$STRICT_BUILD" = "1" ] && [ "$ALLOW_STUB" != "1" ]; then
  printf '[ERROR] Strict %s unikernel build failed: install SDK via ./libscript.sh install %s.\n' "$FRAMEWORK" "$FRAMEWORK" >&2
  rm -f "$OUT_ELF" "$STAMP_FILE"
  exit 1
fi

printf 'LibScript Unikernel (%s/%s) Stub\n' "$FRAMEWORK" "$VMM" > "$OUT_ELF"
chmod +x "$OUT_ELF" 2>/dev/null || true
printf 'mode=stub\nframework=%s\nvmm=%s\ntimestamp=%s\n' "$FRAMEWORK" "$VMM" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[WARN] %s SDK not on host; emitted unikernel descriptor and stub: %s\n' "$FRAMEWORK" "$OUT_ELF"
exit 0
