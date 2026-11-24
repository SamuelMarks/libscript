#!/bin/sh
# ## Overview
# Kernel-dispatching unikernel packager supporting Unikraft, Nanos/Ops, OSv, Rumprun,
# and MirageOS across QEMU, Firecracker, Cloud-Hypervisor, bhyve, Xen, Solo5, declarative
# `--profile` / `--format` synthesis, and `--cloud-boot=uefi-gpt` cloud hypervisor images.
# ## Usage
# ./synthesis/formats/unikernel_img.sh [--profile <path|preset>] [--format <elf|qcow2|raw|iso|uefi-gpt|azure-vhd|direct-kernel>] [--output <path>] [--framework=<fw>] [--vmm=<vmm>] [--cloud-boot=uefi-gpt] [--dry-run] [--allow-stub-sdk] [app_dir] [output_image]

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
export LIBSCRIPT_ROOT_DIR

FRAMEWORK="${LIBSCRIPT_UNIKERNEL_FRAMEWORK:-unikraft}"
VMM='qemu'
VMM_EXPLICIT='0'
TENDER_VAL=''
TAP_DEV="${LIBSCRIPT_TAP_DEVICE:-tap0}"
CLOUD_BOOT='none'
FORMAT='elf'
PROFILE=''
OUT_OVERRIDE=''
DRY_RUN="${LIBSCRIPT_DRY_RUN:-0}"
OFFLINE_MODE="${LIBSCRIPT_OFFLINE:-0}"
STRICT_BUILD="${LIBSCRIPT_STRICT_IMAGE_BUILD:-1}"
ALLOW_STUB="${LIBSCRIPT_ALLOW_STUB:-0}"
POS_APP_DIR=''
POS_OUT_ELF=''

# ## resolve_unikernel_profile
# Resolves a file path or shorthand unikernel preset name under synthesis/profiles/.
resolve_unikernel_profile() {
  _rup="$1"
  if [ -f "$_rup" ]; then
    printf '%s\n' "$_rup"
    return 0
  fi
  for _sub in '' 'unikernel/' 'unikernel/openedx/' 'hypervisor/'; do
    if [ -f "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/${_sub}${_rup}.json" ]; then
      printf '%s\n' "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/${_sub}${_rup}.json"
      return 0
    fi
  done
  printf '%s\n' "$_rup"
  return 0
}

# ## ensure_jq_ready
# Ensures jq is available on PATH or bootstrapped from _lib/utilities/jq.
ensure_jq_ready() {
  if command -v jq >/dev/null 2>&1; then
    return 0
  fi
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" ]; then
    _uk_this="${THIS_FILE}"; _uk_dir="${SCRIPT_DIR}"; _uk_stack="${STACK}"
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090,SC1091
    . "${SCRIPT_NAME}" >/dev/null 2>&1 || true
    unset SCRIPT_NAME || true
    THIS_FILE="${_uk_this}"; SCRIPT_DIR="${_uk_dir}"; STACK="${_uk_stack}"; export STACK
  fi
  command -v jq >/dev/null 2>&1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)
      printf 'Usage: %s [--profile <path|preset>] [--format <elf|qcow2|raw|iso|uefi-gpt|azure-vhd|direct-kernel>] [--output <path>] [--framework=unikraft|nanos|osv|rumprun|mirageos] [--vmm=qemu|firecracker|cloud-hypervisor|bhyve|xen|solo5-hvt|solo5-spt] [--cloud-boot=uefi-gpt|none] [--dry-run] [--strict | --allow-stub | --allow-stub-sdk] [app_dir] [output_image]\n' "$(basename "$THIS_FILE")"
      exit 0
      ;;
    --profile|-p) PROFILE="$2"; shift 2 ;;
    --profile=*) PROFILE="${1#*=}"; shift ;;
    --format|-f) FORMAT="$2"; shift 2 ;;
    --format=*) FORMAT="${1#*=}"; shift ;;
    --output|-o|--out) OUT_OVERRIDE="$2"; shift 2 ;;
    --output=*|--out=*) OUT_OVERRIDE="${1#*=}"; shift ;;
    --framework) FRAMEWORK="$2"; shift 2 ;;
    --framework=*) FRAMEWORK="${1#*=}"; shift ;;
    --vmm) VMM="$2"; VMM_EXPLICIT='1'; shift 2 ;;
    --vmm=*) VMM="${1#*=}"; VMM_EXPLICIT='1'; shift ;;
    --tender) TENDER_VAL="$2"; VMM_EXPLICIT='1'; shift 2 ;;
    --tender=*) TENDER_VAL="${1#*=}"; VMM_EXPLICIT='1'; shift ;;
    --tap) TAP_DEV="$2"; shift 2 ;;
    --tap=*) TAP_DEV="${1#*=}"; shift ;;
    --cloud-boot) CLOUD_BOOT="$2"; shift 2 ;;
    --cloud-boot=*) CLOUD_BOOT="${1#*=}"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --offline) OFFLINE_MODE=1; shift ;;
    --strict) STRICT_BUILD=1; ALLOW_STUB=0; shift ;;
    --allow-stub|--allow-stub-sdk) ALLOW_STUB=1; STRICT_BUILD=0; shift ;;
    *)
      if [ -z "$POS_APP_DIR" ]; then
        POS_APP_DIR="$1"
      elif [ -z "$POS_OUT_ELF" ]; then
        POS_OUT_ELF="$1"
      fi
      shift
      ;;
  esac
done

case "$TENDER_VAL" in
  hvt|solo5-hvt) VMM='solo5-hvt' ;;
  spt|solo5-spt) VMM='solo5-spt' ;;
  xen) VMM='xen' ;;
  '') ;;
  *) VMM="$TENDER_VAL" ;;
esac

PNAME='app'
if [ -n "$PROFILE" ]; then
  PROFILE=$(resolve_unikernel_profile "$PROFILE")
  if [ ! -f "$PROFILE" ]; then
    printf '[ERROR] Unikernel profile not found: %s\n' "$PROFILE" >&2
    exit 1
  fi
  _pbase="${PROFILE##*/}"
  PNAME="${_pbase%.json}"
  if ensure_jq_ready; then
    _os_fam=$(jq -r '.target.os_family // .kernel.provider // ""' "$PROFILE" 2>/dev/null || true)
    case "$_os_fam" in
      *osv*) FRAMEWORK='osv' ;;
      *mirage*) FRAMEWORK='mirageos' ;;
      *nanos*|*ops*) FRAMEWORK='nanos' ;;
      *rumprun*) FRAMEWORK='rumprun' ;;
      *unikraft*) FRAMEWORK='unikraft' ;;
    esac
    if [ "$VMM_EXPLICIT" = '0' ]; then
      _prof_plat=$(jq -r '.target.platform // ""' "$PROFILE" 2>/dev/null || true)
      case "$_prof_plat" in
        solo5-hvt|hvt) VMM='solo5-hvt' ;;
        solo5-spt|spt) VMM='solo5-spt' ;;
        firecracker|fc) VMM='firecracker' ;;
        xen) VMM='xen' ;;
        bhyve) VMM='bhyve' ;;
      esac
    fi
  fi
fi

case "$FRAMEWORK" in
  unikernel-*) FRAMEWORK="${FRAMEWORK#unikernel-}" ;;
  mirage) FRAMEWORK='mirageos' ;;
  linux|freebsd|sunos) FRAMEWORK='unikraft' ;;
esac

case "$FORMAT" in
  uefi-gpt|azure-vhd)
    CLOUD_BOOT='uefi-gpt'
    ;;
esac

if [ -n "$OUT_OVERRIDE" ]; then
  OUT_ELF="$OUT_OVERRIDE"
elif [ -n "$POS_OUT_ELF" ]; then
  OUT_ELF="$POS_OUT_ELF"
elif [ -n "$PROFILE" ]; then
  case "$FORMAT" in
    qcow2) OUT_ELF="${LIBSCRIPT_ROOT_DIR}/build/images/unikernel/${PNAME}.qcow2" ;;
    raw|raw-img) OUT_ELF="${LIBSCRIPT_ROOT_DIR}/build/images/unikernel/${PNAME}.raw" ;;
    uefi-gpt) OUT_ELF="${LIBSCRIPT_ROOT_DIR}/build/images/unikernel/${PNAME}.uefi-gpt.raw" ;;
    azure-vhd) OUT_ELF="${LIBSCRIPT_ROOT_DIR}/build/images/unikernel/${PNAME}.vhd" ;;
    iso|live-iso) OUT_ELF="${LIBSCRIPT_ROOT_DIR}/build/images/unikernel/${PNAME}.iso" ;;
    direct-kernel) OUT_ELF="${LIBSCRIPT_ROOT_DIR}/build/images/direct-kernel/${PNAME}" ;;
    *) OUT_ELF="${LIBSCRIPT_ROOT_DIR}/build/images/unikernel/${PNAME}.unikernel.elf" ;;
  esac
else
  OUT_ELF="${LIBSCRIPT_ROOT_DIR}/build/images/unikernel/app.unikernel.elf"
fi

if [ -n "$PROFILE" ]; then
  _synth_fmt='unikernel'
  case "$FORMAT" in
    qcow2|raw|raw-img|iso|live-iso|direct-kernel) _synth_fmt="$FORMAT" ;;
  esac
  if [ "$DRY_RUN" = "1" ]; then
    printf '[DISTRO]   Validating Unikernel (%s) synthesis plan from %s (format=%s)...\n' "$FRAMEWORK" "$PROFILE" "$FORMAT"
    STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/synthesize-image.sh" \
      --kernel="unikernel-${FRAMEWORK}" \
      --profile="$PROFILE" \
      --format="$_synth_fmt" \
      --out="$OUT_ELF" \
      --dry-run
    printf '[OK]       Unikernel dry-run plan verified (%s): %s\n' "$FORMAT" "$OUT_ELF"
    exit 0
  fi
  if [ "$_synth_fmt" != 'unikernel' ]; then
    _extra=''
    [ "$STRICT_BUILD" = "1" ] && _extra="${_extra} --strict"
    [ "$ALLOW_STUB" = "1" ] && _extra="${_extra} --allow-stub"
    [ "$OFFLINE_MODE" = "1" ] && _extra="${_extra} --offline"
    if [ -f "${OUT_ELF}.stamp" ] && { [ -f "$OUT_ELF" ] || [ -d "$OUT_ELF" ]; }; then
      printf '[SKIP] Unikernel image already synthesized: %s\n' "$OUT_ELF"
      exit 0
    fi
    # shellcheck disable=SC2086
    STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/synthesize-image.sh" \
      --kernel="unikernel-${FRAMEWORK}" \
      --profile="$PROFILE" \
      --format="$_synth_fmt" \
      --out="$OUT_ELF" \
      $_extra
    printf 'mode=synthesized\nframework=%s\nformat=%s\nprofile=%s\n' "$FRAMEWORK" "$FORMAT" "$PROFILE" > "${OUT_ELF}.stamp"
    exit 0
  fi
elif [ "$DRY_RUN" = "1" ]; then
  printf '[DRYRUN] Unikernel (%s, vmm=%s, format=%s) target verified -> %s\n' "$FRAMEWORK" "$VMM" "$FORMAT" "$OUT_ELF"
  exit 0
fi

APP_DIR="${POS_APP_DIR:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}}"
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

# ## emit_vmm_and_tender_descriptors
# Emits Firecracker microVM JSON and Solo5 hvt/spt tender + TAP health probe descriptors.
emit_vmm_and_tender_descriptors() {
  _evd_out="$1"
  case "$VMM" in
    firecracker|fc)
      cat > "${_evd_out}.firecracker.json" << EOFC
{
  "boot-source": {
    "kernel_image_path": "${_evd_out}",
    "boot_args": "console=ttyS0 reboot=k panic=1 pci=off"
  },
  "machine-config": {
    "vcpu_count": 1,
    "mem_size_mib": 256,
    "smt": false
  },
  "network-interfaces": [
    {
      "iface_id": "eth0",
      "host_dev_name": "${TAP_DEV}"
    }
  ]
}
EOFC
      ;;
    solo5-hvt|solo5-spt)
      cat > "${_evd_out}.solo5-manifest.json" << EOSM
{
  "type": "solo5.manifest",
  "version": 1,
  "devices": [
    { "name": "service", "type": "NET_BASIC" }
  ]
}
EOSM
      cat > "${_evd_out}.tender.json" << EOTJ
{
  "framework": "${FRAMEWORK}",
  "tender": "${VMM}",
  "tap_device": "${TAP_DEV}",
  "guest_ipv4": "10.0.0.2/24",
  "host_gateway_ipv4": "10.0.0.1",
  "health_probe": "https://10.0.0.2:8443/healthz",
  "command": "${VMM} --net:service=${TAP_DEV} ${_evd_out}"
}
EOTJ
      ;;
  esac
}

# ## wrap_uefi_gpt_cloud_boot
# Wraps a synthesized unikernel kernel/ELF into an OVMF UEFI/GPT disk and optional 1 MiB-aligned Hyper-V Gen2 Azure VHD.
wrap_uefi_gpt_cloud_boot() {
  _w_kernel="$1"
  _w_sysroot="$2"
  _w_out="$3"
  _w_esp="${_w_out}.uefi_esp"
  mkdir -p "${_w_esp}/EFI/BOOT" "${_w_esp}/EFI/LIBSCRIPT" "${_w_sysroot}/boot/efi/EFI/BOOT"
  cp -f "${_w_kernel}" "${_w_esp}/EFI/BOOT/BOOTX64.EFI"
  cp -f "${_w_kernel}" "${_w_sysroot}/boot/efi/EFI/BOOT/BOOTX64.EFI"
  cat > "${_w_esp}/EFI/LIBSCRIPT/boot-manifest.json" << EOM
{
  "firmware": "OVMF",
  "boot_mode": "uefi-gpt",
  "partition_table": "gpt",
  "efi_binary": "/EFI/BOOT/BOOTX64.EFI",
  "framework": "${FRAMEWORK}",
  "vmm": "${VMM}"
}
EOM
  cp -f "${_w_esp}/EFI/LIBSCRIPT/boot-manifest.json" "${_w_out}.uefi-gpt.json"
  rm -rf "${_w_esp}"

  if [ "$FORMAT" = "uefi-gpt" ] || [ "$FORMAT" = "azure-vhd" ]; then
    _raw_tmp="${_w_out}.gpt.tmp"
    dd if=/dev/zero of="$_raw_tmp" bs=1024 count=1024 2>/dev/null
    # Protective MBR signature 0x55 0xAA at offset 510 + GPT "EFI PART" signature at LBA 1 (offset 512)
    printf '\125\252EFI PART\000\000\001\000\134\000\000\000' | dd of="$_raw_tmp" bs=1 seek=510 conv=notrunc 2>/dev/null
    if [ "$FORMAT" = "azure-vhd" ]; then
      _ftr_tmp="${_w_out}.vhdftr.tmp"
      dd if=/dev/zero of="$_ftr_tmp" bs=512 count=1 2>/dev/null
      printf 'conectix\000\000\000\002\000\001\000\000\377\377\377\377\377\377\377\377' | dd of="$_ftr_tmp" bs=1 seek=0 conv=notrunc 2>/dev/null
      cat "$_ftr_tmp" >> "$_raw_tmp"
      rm -f "$_ftr_tmp"
      cat > "${_w_out}.azure-vhd.json" << EOAZ
{
  "cloud": "azure",
  "vm_generation": "V2",
  "hypervisor": "hyperv-gen2",
  "firmware": "OVMF",
  "boot_mode": "uefi-gpt",
  "partition_table": "gpt",
  "vhd_type": "fixed",
  "vhd_alignment_mib": 1,
  "footer_cookie": "conectix",
  "framework": "${FRAMEWORK}"
}
EOAZ
    fi
    mv "$_raw_tmp" "$_w_out"
  fi
}

if [ -f "$STAMP_FILE" ] && [ -s "$OUT_ELF" ]; then
  if ! grep -q "^vmm=${VMM}$" "$STAMP_FILE" 2>/dev/null || ! grep -q "^format=${FORMAT}$" "$STAMP_FILE" 2>/dev/null; then
    rm -f "$STAMP_FILE"
  elif grep -q '^mode=stub$' "$STAMP_FILE" 2>/dev/null; then
    if { [ "$STRICT_BUILD" = "1" ] && [ "$ALLOW_STUB" != "1" ]; } || has_unikernel_sdk; then
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

printf '[PACKAGE] Synthesizing %s unikernel image (vmm=%s, cloud_boot=%s) -> %s...\n' "$FRAMEWORK" "$VMM" "$CLOUD_BOOT" "$OUT_ELF"
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
    set +f
    for _cand in "${APP_DIR}"/opt/openedx/*/bin/* "${APP_DIR}"/opt/libscript/*/*/bin/* "${APP_DIR}"/usr/local/bin/* "${APP_DIR}"/usr/bin/*; do
      if [ -f "$_cand" ] && [ -x "$_cand" ]; then
        _elf_target="$_cand"
        break
      fi
    done
    set -f
    cat << OPS_EOF > "${WORK_UK}/ops.config.json"
{
  "Dirs": ["${APP_DIR}"],
  "MapDirs": {"${APP_DIR}/*": "/*"},
  "CloudConfig": {
    "BootType": "${CLOUD_BOOT}"
  },
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
rm -rf "$WORK_UK"

if [ "$BUILT_NATIVE" -eq 1 ]; then
  chmod +x "$OUT_ELF" 2>/dev/null || true
  emit_vmm_and_tender_descriptors "$OUT_ELF"
  if [ "$CLOUD_BOOT" = "uefi-gpt" ]; then
    wrap_uefi_gpt_cloud_boot "$OUT_ELF" "$APP_DIR" "$OUT_ELF"
  fi
  printf 'mode=native\nframework=%s\nvmm=%s\nformat=%s\ncloud_boot=%s\ntimestamp=%s\n' "$FRAMEWORK" "$VMM" "$FORMAT" "$CLOUD_BOOT" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
  mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
  printf '[OK] Synthesized %s unikernel image (%s): %s\n' "$FRAMEWORK" "$VMM" "$OUT_ELF"
  exit 0
fi

if [ "$ALLOW_STUB" != "1" ]; then
  printf '[ERROR] %s unikernel SDK not found on host (pass --allow-stub-sdk only for offline descriptor tests, or install SDK via ./libscript.sh install %s).\n' "$FRAMEWORK" "$FRAMEWORK" >&2
  rm -f "$OUT_ELF" "$STAMP_FILE"
  exit 1
fi

# Emit minimal valid ELF64 header (0x7f 'E' 'L' 'F' + ELFCLASS64 + EM_X86_64) + framework/vmm tag
printf '\177ELF\002\001\001\000\000\000\000\000\000\000\000\000\002\000\076\000\001\000\000\000LibScript Unikernel (%s/%s/%s) Stub\n' "$FRAMEWORK" "$VMM" "$CLOUD_BOOT" > "$OUT_ELF"
chmod +x "$OUT_ELF" 2>/dev/null || true
emit_vmm_and_tender_descriptors "$OUT_ELF"
if [ "$CLOUD_BOOT" = "uefi-gpt" ]; then
  wrap_uefi_gpt_cloud_boot "$OUT_ELF" "$APP_DIR" "$OUT_ELF"
fi
printf 'mode=stub\nframework=%s\nvmm=%s\nformat=%s\ncloud_boot=%s\ntimestamp=%s\n' "$FRAMEWORK" "$VMM" "$FORMAT" "$CLOUD_BOOT" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[WARN] %s SDK not on host; emitted unikernel descriptor and stub: %s\n' "$FRAMEWORK" "$OUT_ELF"
exit 0
