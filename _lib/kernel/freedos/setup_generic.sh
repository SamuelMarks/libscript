#!/bin/sh
# ## Overview
# Tier 2 setup and kernel synthesis router for FreeDOS (_lib/kernel/freedos/).
# Rejects `use` with exit code 2 per T2 Version Manager Contract.
#
# ## Usage
# ACTION=install FREEDOS_VERSION=1.4 ./_lib/kernel/freedos/setup.sh

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

for _flib in "engine/common/pkg_mgr.sh" "engine/common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_flib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME || true

ACTION="${ACTION:-install}"
VERSION="${FREEDOS_VERSION:-1.4}"

# ## resolve_exact_version
# Resolves latest/stable/lts aliases to concrete FreeDOS release versions.
resolve_exact_version() {
  case "${VERSION}" in
    latest|stable) EXACT_VERSION='1.4' ;;
    lts) EXACT_VERSION='1.3' ;;
    *) EXACT_VERSION="${VERSION#v}" ;;
  esac
}

# ## stage_freedos_sysroot
# Copies KERNEL.SYS, COMMAND.COM, SYS.COM, and VBRs into LIBSCRIPT_TARGET_SYSROOT.
stage_freedos_sysroot() {
  _sfs_dir="$1"
  if [ -z "${LIBSCRIPT_TARGET_SYSROOT:-}" ]; then
    return 0
  fi
  mkdir -p "${LIBSCRIPT_TARGET_SYSROOT}/DOS" "${LIBSCRIPT_TARGET_SYSROOT}/BOOT"
  cp -f "${_sfs_dir}/boot/KERNEL.SYS" "${LIBSCRIPT_TARGET_SYSROOT}/KERNEL.SYS"
  cp -f "${_sfs_dir}/boot/COMMAND.COM" "${LIBSCRIPT_TARGET_SYSROOT}/COMMAND.COM"
  cp -f "${_sfs_dir}/boot/COMMAND.COM" "${LIBSCRIPT_TARGET_SYSROOT}/DOS/COMMAND.COM"
  cp -f "${_sfs_dir}/boot/SYS.COM" "${LIBSCRIPT_TARGET_SYSROOT}/DOS/SYS.COM"
    for _vb in fat12.bin fat16.bin fat32lba.bin; do
    [ -f "${_sfs_dir}/boot/${_vb}" ] && cp -f "${_sfs_dir}/boot/${_vb}" "${LIBSCRIPT_TARGET_SYSROOT}/BOOT/${_vb}"
  done
}

case "${ACTION}" in
  use)
    printf '[ERROR] freedos is a Tier 2 kernel/sysroot package; use is unsupported.\n' >&2
    exit 2
    ;;
  ls)
    if [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/freedos" ]; then
      ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/freedos" || true
    fi
    ;;
  ls-remote)
    printf '1.4\n1.3\n2043\n'
    ;;
  download)
    resolve_exact_version
    printf '[INFO] FreeDOS %s kernel build inputs ready.\n' "${EXACT_VERSION}"
    ;;
  bootstrap|compile|install)
    resolve_exact_version
    TARGET_DIR=$(libscript_get_version_dir 'freedos' "${EXACT_VERSION}")
    if [ -f "${TARGET_DIR}/boot/KERNEL.SYS" ] && [ -f "${TARGET_DIR}/boot/COMMAND.COM" ] && [ "${FORCE_REINSTALL:-0}" != '1' ]; then
      stage_freedos_sysroot "${TARGET_DIR}"
      libscript_symlink_alias 'freedos' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'freedos' 'default' "${EXACT_VERSION}"
      log_info "freedos ${EXACT_VERSION} is already staged at ${TARGET_DIR}."
      exit 0
    fi
    mkdir -p "${TARGET_DIR}/boot"
    STACK='' "${SCRIPT_DIR}/build_kernel.sh" "${TARGET_DIR}/boot" "${EXACT_VERSION}"
    stage_freedos_sysroot "${TARGET_DIR}"
    libscript_symlink_alias 'freedos' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'freedos' 'default' "${EXACT_VERSION}"
    log_success "FreeDOS ${EXACT_VERSION} kernel staged at ${TARGET_DIR}/boot."
    ;;
  uninstall)
    resolve_exact_version
    rm -rf "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/freedos/${EXACT_VERSION}"
    ;;
  *)
    resolve_exact_version
    TARGET_DIR=$(libscript_get_version_dir 'freedos' "${EXACT_VERSION}")
    libscript_handle_generic_action 'freedos' "${ACTION}" "${EXACT_VERSION}" 'from-source' '' '' '' "${TARGET_DIR}/boot/KERNEL.SYS" "${TARGET_DIR}"
    ;;
esac
