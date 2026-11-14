#!/bin/sh
# ## Overview
# Unified kernel-abstracted installer and base-image synthesizer for {component0, component1, ...}
# across Linux, FreeBSD, illumos, and Unikernels (Unikraft, Nanos/Ops, OSv, Rumprun, MirageOS).
# ## Usage
# ./libscript.sh build-image --kernel=<kernel> --format=<format> --components=<c0,c1,...> [--out=<path>] [--dry-run]

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

KERNEL='linux-glibc'
OS_FLAVOR=''
TARGET_ARCH='x86_64'
FORMAT='qcow2'
COMPONENTS_CSV=''
PROFILE_JSON=''
OUT_PATH=''
DRY_RUN="${LIBSCRIPT_DRY_RUN:-0}"
STRICT_BUILD="${LIBSCRIPT_STRICT_IMAGE_BUILD:-0}"
ALLOW_STUB="${LIBSCRIPT_ALLOW_STUB:-0}"
OFFLINE_MODE="${LIBSCRIPT_OFFLINE:-0}"

# ## show_help
# Displays usage instructions for the unified kernel-abstracted image and installer builder.
show_help() {
  printf 'Usage: libscript build-image | build-installer [OPTIONS]\n\n'
  printf 'Options:\n'
  printf '  --kernel=<kernel>        Target kernel: linux, linux-glibc, linux-musl, freebsd, illumos,\n'
  printf '                           unikraft, nanos, osv, rumprun, mirageos, firecracker\n'
  printf '  --os-flavor=<flavor>     Optional flavor: debian, alpine, rocky, lfs, omnios, openindiana, tribblix, smartos\n'
  printf '  --arch=<arch>            Target ISA: x86_64, aarch64, amd64, arm64 (default: x86_64)\n'
  printf '  --format=<format>        Output format: live-iso, live-usb, raw, qcow2, vmdk, vhd, vhdx,\n'
  printf '                           vagrant-box, zfs-stream, rootfs-tar, oci-image, direct-kernel, unikernel\n'
  printf '  --components=<c0,c1,...> Comma-separated Tier 1 components (e.g. redis,postgres,openedx)\n'
  printf '  --profile=<file.json>    Optional base OS profile JSON to merge\n'
  printf '  --out=<path>             Output artifact file or directory path\n'
  printf '  --offline                Build strictly using local cache without network access\n'
  printf '  --dry-run                Resolve execution plan and validate compatibility without mutating disk images\n'
  printf '  --strict                 Fail if native hypervisor/filesystem tools are missing\n'
  printf '  --allow-stub             Permit structural stub outputs in unit test environments\n'
}

while [ $# -gt 0 ]; do
  case "$1" in
    build-image|build-installer) shift ;;
    --help|-h|/\?|-\?) show_help; exit 0 ;;
    --kernel=*) KERNEL="${1#*=}"; shift ;;
    --kernel) KERNEL="$2"; shift 2 ;;
    --os-flavor=*) OS_FLAVOR="${1#*=}"; shift ;;
    --os-flavor) OS_FLAVOR="$2"; shift 2 ;;
    --arch=*) TARGET_ARCH="$2_unused"; TARGET_ARCH="${1#*=}"; shift ;;
    --arch) TARGET_ARCH="$2"; shift 2 ;;
    --format=*) FORMAT="${1#*=}"; shift ;;
    --format) FORMAT="$2"; shift 2 ;;
    --components=*)
      if [ -n "$COMPONENTS_CSV" ]; then
        COMPONENTS_CSV="${COMPONENTS_CSV},${1#*=}"
      else
        COMPONENTS_CSV="${1#*=}"
      fi
      shift
      ;;
    --components)
      if [ -n "$COMPONENTS_CSV" ]; then
        COMPONENTS_CSV="${COMPONENTS_CSV},$2"
      else
        COMPONENTS_CSV="$2"
      fi
      shift 2
      ;;
    --profile=*) PROFILE_JSON="${1#*=}"; shift ;;
    --profile) PROFILE_JSON="$2"; shift 2 ;;
    --out=*) OUT_PATH="${1#*=}"; shift ;;
    --out) OUT_PATH="$2"; shift 2 ;;
    --offline) OFFLINE_MODE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --strict) STRICT_BUILD=1; shift ;;
    --allow-stub) ALLOW_STUB=1; shift ;;
    *)
      printf '[ERROR] Unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

case "$KERNEL" in
  linux|linux-glibc)
    OS_FAMILY='linux-glibc'
    LIBC='glibc'
    KPROVIDER='linux-lts'
    INIT_PROV='systemd'
    BOOTLOADER='grub2-efi'
    RESOLVE_OS='linux'
    ;;
  linux-musl|alpine)
    OS_FAMILY='linux-musl'
    LIBC='musl'
    KPROVIDER='linux-lts'
    INIT_PROV='openrc'
    BOOTLOADER='grub2-efi'
    RESOLVE_OS='linux'
    ;;
  freebsd)
    OS_FAMILY='freebsd'
    LIBC='bsd-libc'
    KPROVIDER='freebsd-kernel'
    INIT_PROV='bsd-rc'
    BOOTLOADER='freebsd-loader'
    RESOLVE_OS='freebsd'
    ;;
  illumos|sunos)
    OS_FAMILY='illumos'
    LIBC='illumos-libc'
    KPROVIDER='illumos-gate'
    INIT_PROV='smf'
    BOOTLOADER='illumos-loader'
    RESOLVE_OS='sunos'
    ;;
  unikraft|unikernel-unikraft)
    OS_FAMILY='unikernel-unikraft'
    LIBC='musl'
    KPROVIDER='unikraft-core'
    INIT_PROV='unikernel-entrypoint'
    BOOTLOADER='unikernel-direct'
    RESOLVE_OS='unikraft'
    ;;
  nanos|ops|unikernel-nanos)
    OS_FAMILY='unikernel-nanos'
    LIBC='glibc'
    KPROVIDER='nanos-kernel'
    INIT_PROV='unikernel-entrypoint'
    BOOTLOADER='unikernel-direct'
    RESOLVE_OS='nanos'
    ;;
  osv|unikernel-osv)
    OS_FAMILY='unikernel-osv'
    LIBC='glibc'
    KPROVIDER='osv-kernel'
    INIT_PROV='unikernel-entrypoint'
    BOOTLOADER='unikernel-direct'
    RESOLVE_OS='osv'
    ;;
  rumprun|unikernel-rumprun)
    OS_FAMILY='unikernel-rumprun'
    LIBC='rump-libc'
    KPROVIDER='rumprun-hw'
    INIT_PROV='unikernel-entrypoint'
    BOOTLOADER='unikernel-direct'
    RESOLVE_OS='rumprun'
    ;;
  mirage|mirageos|unikernel-mirageos)
    OS_FAMILY='unikernel-mirageos'
    LIBC='mirage-ocaml'
    KPROVIDER='mirage-solo5-hvt'
    INIT_PROV='unikernel-entrypoint'
    BOOTLOADER='unikernel-direct'
    RESOLVE_OS='mirageos'
    ;;
  firecracker|microvm-firecracker)
    OS_FAMILY='microvm-firecracker'
    LIBC='musl'
    KPROVIDER='linux-stable'
    INIT_PROV='openrc'
    BOOTLOADER='none'
    RESOLVE_OS='linux'
    ;;
  *)
    printf '[ERROR] Unsupported --kernel value: %s\n' "$KERNEL" >&2
    exit 1
    ;;
esac

if [ -z "$OUT_PATH" ]; then
  case "$FORMAT" in
    live-iso|iso) OUT_PATH="${LIBSCRIPT_ROOT_DIR}/build/synthesis/${OS_FAMILY}.iso" ;;
    live-usb|raw|raw-img) OUT_PATH="${LIBSCRIPT_ROOT_DIR}/build/synthesis/${OS_FAMILY}.raw" ;;
    qcow2) OUT_PATH="${LIBSCRIPT_ROOT_DIR}/build/synthesis/${OS_FAMILY}.qcow2" ;;
    vmdk) OUT_PATH="${LIBSCRIPT_ROOT_DIR}/build/synthesis/${OS_FAMILY}.vmdk" ;;
    vhd|vhdx) OUT_PATH="${LIBSCRIPT_ROOT_DIR}/build/synthesis/${OS_FAMILY}.vhd" ;;
    vagrant-box) OUT_PATH="${LIBSCRIPT_ROOT_DIR}/build/synthesis/${OS_FAMILY}.box" ;;
    zfs-stream) OUT_PATH="${LIBSCRIPT_ROOT_DIR}/build/synthesis/${OS_FAMILY}.zfs.zst" ;;
    rootfs-tar|oci-image) OUT_PATH="${LIBSCRIPT_ROOT_DIR}/build/synthesis/${OS_FAMILY}.rootfs.tar.gz" ;;
    direct-kernel) OUT_PATH="${LIBSCRIPT_ROOT_DIR}/build/synthesis/${OS_FAMILY}-direct" ;;
    unikernel) OUT_PATH="${LIBSCRIPT_ROOT_DIR}/build/synthesis/${OS_FAMILY}.unikernel.elf" ;;
    *)
      printf '[ERROR] Unsupported --format value: %s\n' "$FORMAT" >&2
      exit 1
      ;;
  esac
fi

WORK_BASE="${LIBSCRIPT_BUILD_DIR:-${LIBSCRIPT_ROOT_DIR}/build/synthesis}/.work-${OS_FAMILY}-${TARGET_ARCH}"
SYSROOT_DIR="${LIBSCRIPT_TARGET_SYSROOT:-${WORK_BASE}/sysroot}"
mkdir -p "$WORK_BASE" "$SYSROOT_DIR" "$(dirname "$OUT_PATH")"

GEN_OS_CONFIG="${WORK_BASE}/os-config.generated.json"
GEN_PLAN="${WORK_BASE}/execution-plan.generated.json"

# Ensure jq is bootstrapped via resolve_stack.sh helper or PATH
if ! command -v jq >/dev/null 2>&1; then
  STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install jq latest >/dev/null 2>&1 || true
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1091
    . "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" >/dev/null 2>&1 || true
    unset SCRIPT_NAME || true
  fi
fi

COMP_JSON='[]'
if [ -n "$COMPONENTS_CSV" ]; then
  COMP_JSON=$(printf '%s' "$COMPONENTS_CSV" | jq -Rc 'split(",") | map(gsub("^[[:space:]]+|[[:space:]]+$"; "")) | map(select(length > 0))')
fi

NORM_FMT="$FORMAT"
case "$FORMAT" in
  iso) NORM_FMT='live-iso' ;;
  raw-img) NORM_FMT='raw' ;;
  unikernel) NORM_FMT='direct-kernel' ;;
esac

if [ -n "$PROFILE_JSON" ] && [ -f "$PROFILE_JSON" ]; then
  jq --arg os_fam "$OS_FAMILY" \
     --arg arch "$TARGET_ARCH" \
     --arg libc "$LIBC" \
     --arg flavor "$OS_FLAVOR" \
     --arg kprov "$KPROVIDER" \
     --arg iprov "$INIT_PROV" \
     --arg bl "$BOOTLOADER" \
     --arg fmt "$NORM_FMT" \
     --argjson comps "$COMP_JSON" '
    .target.os_family = $os_fam
    | .target.arch = $arch
    | .target.libc = (.target.libc // $libc)
    | (if $flavor != "" then .target.flavor = $flavor else . end)
    | .kernel = ((.kernel // {"config_method": "defconfig"}) | .provider = (.provider // $kprov))
    | .init_system = ((.init_system // {}) | .provider = (.provider // $iprov))
    | .storage = ((.storage // {"disk_size_gib": 16, "partition_table": "gpt", "boot_mode": "uefi"}) | .bootloader = (.bootloader // $bl))
    | .output_formats = [$fmt]
    | .components = (((.components // []) + $comps) | unique)
  ' "$PROFILE_JSON" > "$GEN_OS_CONFIG"
else
  jq -n --arg os_fam "$OS_FAMILY" \
        --arg arch "$TARGET_ARCH" \
        --arg libc "$LIBC" \
        --arg flavor "$OS_FLAVOR" \
        --arg kprov "$KPROVIDER" \
        --arg iprov "$INIT_PROV" \
        --arg bl "$BOOTLOADER" \
        --arg fmt "$NORM_FMT" \
        --arg offline "$OFFLINE_MODE" \
        --argjson comps "$COMP_JSON" '
    {
      schema_version: "1.0.0",
      profile_name: ("synthesized-" + $os_fam),
      description: ("Synthesized " + $os_fam + " image with selected components"),
      target: (
        { arch: $arch, os_family: $os_fam, libc: $libc }
        + (if $flavor != "" then { flavor: $flavor } else {} end)
      ),
      kernel: { provider: $kprov, config_method: "defconfig" },
      init_system: { provider: $iprov },
      storage: {
        disk_size_gib: 16,
        partition_table: "gpt",
        boot_mode: (if $bl == "unikernel-direct" then "direct-kernel" else "uefi" end),
        bootloader: $bl
      },
      offline: { enabled: ($offline == "1") },
      output_formats: [$fmt],
      components: $comps
    }
  ' > "$GEN_OS_CONFIG"
fi

LIBSCRIPT_TARGET_OS="$RESOLVE_OS" \
  STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/resolve_stack.sh" "$GEN_OS_CONFIG" "$GEN_PLAN"

if [ "$DRY_RUN" = "1" ]; then
  LIBSCRIPT_TARGET_SYSROOT="$SYSROOT_DIR" \
    STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/execute_plan.sh" "$GEN_PLAN" --dry-run
  printf '[DRYRUN] Synthesized plan verified for kernel=%s format=%s out=%s\n' "$OS_FAMILY" "$FORMAT" "$OUT_PATH"
  exit 0
fi

LIBSCRIPT_TARGET_SYSROOT="$SYSROOT_DIR" \
  LIBSCRIPT_TARGET_OS="$RESOLVE_OS" \
  LIBSCRIPT_IMAGE_BUILD='1' \
  LIBSCRIPT_OFFLINE="$OFFLINE_MODE" \
  LIBSCRIPT_STRICT_IMAGE_BUILD="$STRICT_BUILD" \
  LIBSCRIPT_ALLOW_STUB="$ALLOW_STUB" \
  STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/execute_plan.sh" "$GEN_PLAN"

export LIBSCRIPT_TARGET_SYSROOT="$SYSROOT_DIR"
export LIBSCRIPT_TARGET_OS="$RESOLVE_OS"
export LIBSCRIPT_UNIKERNEL_FRAMEWORK="$RESOLVE_OS"
export LIBSCRIPT_STRICT_IMAGE_BUILD="$STRICT_BUILD"
export LIBSCRIPT_ALLOW_STUB="$ALLOW_STUB"

case "$FORMAT" in
  live-iso|iso)
    if [ "$RESOLVE_OS" = "freebsd" ]; then
      STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/freebsd_iso.sh" "$SYSROOT_DIR" "$OUT_PATH"
    elif [ "$RESOLVE_OS" = "sunos" ]; then
      STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/illumos_iso.sh" "$SYSROOT_DIR" "$OUT_PATH"
    else
      STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/iso.sh" "$SYSROOT_DIR" "$OUT_PATH"
    fi
    ;;
  live-usb|raw|raw-img)
    if [ "$RESOLVE_OS" = "freebsd" ]; then
      STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/freebsd_raw.sh" "$SYSROOT_DIR" "$OUT_PATH" 16
    elif [ "$RESOLVE_OS" = "sunos" ]; then
      STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/illumos_raw.sh" "$SYSROOT_DIR" "$OUT_PATH" 16
    else
      STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/raw_img.sh" "$SYSROOT_DIR" "$OUT_PATH" 16
    fi
    ;;
  qcow2)
    if [ "$RESOLVE_OS" = "freebsd" ]; then
      STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/freebsd_qcow2.sh" "$SYSROOT_DIR" "$OUT_PATH" 16
    elif [ "$RESOLVE_OS" = "sunos" ]; then
      STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/illumos_qcow2.sh" "$SYSROOT_DIR" "$OUT_PATH" 16
    else
      STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/qcow2.sh" "$SYSROOT_DIR" "$OUT_PATH" qcow2 16
    fi
    ;;
  vmdk)
    STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/qcow2.sh" "$SYSROOT_DIR" "$OUT_PATH" vmdk 16
    ;;
  vhd|vhdx)
    STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/hyperv_img.sh" "$SYSROOT_DIR" "$OUT_PATH"
    ;;
  vagrant-box)
    STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/vagrant_box.sh" "$SYSROOT_DIR" "$OUT_PATH"
    ;;
  zfs-stream)
    STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/zfs_stream.sh" "$SYSROOT_DIR" "$OUT_PATH"
    ;;
  rootfs-tar|oci-image)
    STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/rootfs_tar.sh" "$SYSROOT_DIR" "$OUT_PATH"
    ;;
  direct-kernel)
    STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/direct_kernel.sh" --kernel="$RESOLVE_OS" "$SYSROOT_DIR" "$OUT_PATH"
    ;;
  unikernel)
    STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/unikernel.sh" "$SYSROOT_DIR" "$OUT_PATH"
    ;;
esac

printf '[OK] Synthesized %s (%s) -> %s\n' "$OS_FAMILY" "$FORMAT" "$OUT_PATH"
exit 0
