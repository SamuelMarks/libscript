#!/bin/sh
# ## Overview
# Tier 3 (T3) unified synthesis CLI router dispatching OS image assembly, native installer packaging,
# offline cache hydration, Linux/BSD/illumos/ReactOS/unikernel/RTOS distro synthesis, and repo generation.
#
# ## Usage
# ./synthesis/cli.sh <synthesize|build-image|build-installer|hydrate-cache|distro|repogen|package-as> [args...]

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
unset SCRIPT_NAME || true

# ## source_format_driver
# Sources a T3 format driver script while preserving caller THIS_FILE and SCRIPT_DIR variables.
source_format_driver() {
  _sfd_this="${THIS_FILE:-}"
  _sfd_dir="${SCRIPT_DIR:-}"
  SCRIPT_NAME="$1"
  export SCRIPT_NAME
  shift
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true
  [ -n "${_sfd_this:-}" ] && THIS_FILE="$_sfd_this"
  [ -n "${_sfd_dir:-}" ] && SCRIPT_DIR="$_sfd_dir"
}

# ## show_synthesis_help
# Prints usage instructions for the T3 synthesis CLI router.
show_synthesis_help() {
  printf '%s\n' 'Usage: ./synthesis/cli.sh <subcommand> [args...]'
  printf '%s\n' 'Subcommands: synthesize, build-image, build-installer, hydrate-cache, distro, repogen, package-as <format>'
}

SUBCMD="${CMD:-${1:-}}"
if [ "${1:-}" = "$SUBCMD" ]; then
  shift || true
fi

case "$SUBCMD" in
  --help|-h|'')
    show_synthesis_help
    exit 0
    ;;
  synthesize|synthesize-image|build-image)
    exec "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/synthesize-image.sh" "$@"
    ;;
  build-installer)
    exec "${LIBSCRIPT_ROOT_DIR}/synthesis/msi/build_msi.sh" "$@"
    ;;
  hydrate-cache)
    exec "${LIBSCRIPT_ROOT_DIR}/synthesis/msi/hydrate_offline_cache.sh" "$@"
    ;;
  distro)
    exec "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/linux/cli.sh" "$@"
    ;;
  repogen)
    exec "${LIBSCRIPT_ROOT_DIR}/synthesis/repogen/cli.sh" "$@"
    ;;
  package-as)
    export pkg_type="${1:-}"
    shift || true
    ;;
  *)
    export pkg_type="$SUBCMD"
    ;;
esac

case "${pkg_type:-}" in
  docker|dockerfile) source_format_driver "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/docker.sh" "$@" ;;
  docker_compose|docker-compose) source_format_driver "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/docker_compose.sh" "$@" ;;
  msi)
    case "${1:-}" in
      workloads/apps/openedx*|openedx) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/msi/build_msi.sh" "$@" ;;
      *) source_format_driver "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/msi.sh" "$@" ;;
    esac
    ;;
  innosetup|inno) source_format_driver "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/inno.sh" "$@" ;;
  nsis) source_format_driver "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/nsis.sh" "$@" ;;
  pkg) source_format_driver "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/pkg.sh" "$@" ;;
  dmg) source_format_driver "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/dmg.sh" "$@" ;;
  deb) source_format_driver "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/deb.sh" "$@" ;;
  rpm) source_format_driver "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/rpm.sh" "$@" ;;
  apk) source_format_driver "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/apk.sh" "$@" ;;
  txz) source_format_driver "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/txz.sh" "$@" ;;
  tui) source_format_driver "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/tui.sh" "$@" ;;
  illumos-distro|illumos_distro) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/illumos_distro.sh" "$@" ;;
  freebsd-distro|freebsd_distro) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/freebsd_distro.sh" "$@" ;;
  reactos-distro|reactos_distro) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/reactos_distro.sh" "$@" ;;
  raw-img|raw_img|img) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/raw_img.sh" "$@" ;;
  qcow2|vmdk|vdi) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/qcow2.sh" "$@" "$pkg_type" ;;
  iso) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/iso.sh" "$@" ;;
  rootfs-tar|rootfs_tar) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/rootfs_tar.sh" "$@" ;;
  bsd-img|bsd_img) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/bsd_img.sh" "$@" ;;
  unikernel|unikernel-img|unikernel_img) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/unikernel_img.sh" "$@" ;;
  docker-image|oci-image|docker_image) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/container_base.sh" "$@" ;;
  qemu-qcow2) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/qemu_img.sh" "$@" ;;
  vmware-vmdk) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/vmware_img.sh" "$@" ;;
  hyperv-vhd|hyperv-vhdx) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/hyperv_img.sh" "$@" ;;
  proxmox-template) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/proxmox_img.sh" "$@" ;;
  virtualbox-vdi|virtualbox-ova|ova) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/virtualbox_img.sh" "$@" ;;
  xen-img) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/xen_img.sh" "$@" ;;
  microvm-disk) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/microvm_img.sh" "$@" ;;
  aws-ami) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/aws_ami.sh" "$@" ;;
  azure-vhd) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/azure_vhd.sh" "$@" ;;
  gcp-image) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/gcp_image.sh" "$@" ;;
  vagrant-box|vagrant_box|vagrant|vagrantfile) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/vagrantfile.sh" "$@" ;;
  disk-builder|disk_builder) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/disk_builder.sh" "$@" ;;
  zfs-stream|zfs_stream) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/zfs_stream.sh" "$@" ;;
  direct-kernel|direct_kernel) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/direct_kernel.sh" "$@" ;;
  firmware-elf|firmware-bin|firmware_bin|firmware-hex|firmware-uf2|mcuboot-signed|renode-resc)
    exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/firmware_bin.sh" --format="$pkg_type" "$@"
    ;;
  cloud-img) exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/cloud_img.sh" "$@" ;;
  *)
    printf "Error: Unsupported synthesis package format '%s'.\n" "${pkg_type:-}" >&2
    exit 1
    ;;
esac
