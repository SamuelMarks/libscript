#!/bin/sh
# ## Overview
# Tier 2 setup and kernel synthesis router for MIT MS-DOS 1.25, 2.0, and 4.00 (_lib/kernel/msdos/).
# Rejects `use` with exit code 2 per T2 Version Manager Contract.
#
# ## Usage
# ACTION=install MSDOS_VERSION=4.0 ./_lib/kernel/msdos/setup.sh

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

for _mlib in "engine/common/pkg_mgr.sh" "engine/common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_mlib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME || true

ACTION="${ACTION:-install}"
VERSION="${MSDOS_VERSION:-4.0}"

# ## resolve_exact_version
# Validates and normalizes MSDOS_VERSION strictly to MIT-licensed releases (1.25, 2.0, 4.0).
resolve_exact_version() {
  case "${VERSION}" in
    latest|stable|lts|4.0|4.00|v4.00) EXACT_VERSION='4.0' ;;
    2.0|2.00|v2.0) EXACT_VERSION='2.0' ;;
    1.25|v1.25) EXACT_VERSION='1.25' ;;
    *)
      log_error "Unsupported MS-DOS version '${VERSION}'. Only MIT-licensed 1.25, 2.0, and 4.0 are permitted."
      exit 1
      ;;
  esac
}

# ## stage_msdos_sysroot
# Stages IO.SYS, MSDOS.SYS/MSDOS.COM, and COMMAND.COM into LIBSCRIPT_TARGET_SYSROOT (flat on 1.25).
stage_msdos_sysroot() {
  _sms_dir="$1"
  _sms_ver="$2"
  if [ -z "${LIBSCRIPT_TARGET_SYSROOT:-}" ]; then
    return 0
  fi
  mkdir -p "${LIBSCRIPT_TARGET_SYSROOT}"
  cp -f "${_sms_dir}/boot/IO.SYS" "${LIBSCRIPT_TARGET_SYSROOT}/IO.SYS"
  cp -f "${_sms_dir}/boot/MSDOS.SYS" "${LIBSCRIPT_TARGET_SYSROOT}/MSDOS.SYS"
  cp -f "${_sms_dir}/boot/COMMAND.COM" "${LIBSCRIPT_TARGET_SYSROOT}/COMMAND.COM"
  if [ "${_sms_ver}" = '1.25' ]; then
    [ -f "${_sms_dir}/boot/MSDOS.COM" ] && cp -f "${_sms_dir}/boot/MSDOS.COM" "${LIBSCRIPT_TARGET_SYSROOT}/MSDOS.COM"
  else
    mkdir -p "${LIBSCRIPT_TARGET_SYSROOT}/DOS" "${LIBSCRIPT_TARGET_SYSROOT}/BOOT"
    cp -f "${_sms_dir}/boot/COMMAND.COM" "${LIBSCRIPT_TARGET_SYSROOT}/DOS/COMMAND.COM"
        for _mb in mbr_dos.bin boot_fat12.bin boot_fat16_bigdos.bin; do
      [ -f "${_sms_dir}/boot/${_mb}" ] && cp -f "${_sms_dir}/boot/${_mb}" "${LIBSCRIPT_TARGET_SYSROOT}/BOOT/${_mb}"
    done
  fi
}

case "${ACTION}" in
  use)
    printf '[ERROR] msdos is a Tier 2 kernel/sysroot package; use is unsupported.\n' >&2
    exit 2
    ;;
  ls)
    if [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/msdos" ]; then
      ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/msdos" || true
    fi
    ;;
  ls-remote)
    printf '4.0 (MIT)\n2.0 (MIT)\n1.25 (MIT)\n'
    ;;
  download)
    resolve_exact_version
    printf '[INFO] MIT MS-DOS %s kernel sources ready.\n' "${EXACT_VERSION}"
    ;;
  bootstrap|compile|install)
    resolve_exact_version
    TARGET_DIR=$(libscript_get_version_dir 'msdos' "${EXACT_VERSION}")
    if [ -f "${TARGET_DIR}/boot/IO.SYS" ] && [ -f "${TARGET_DIR}/boot/MSDOS.SYS" ] && [ -f "${TARGET_DIR}/boot/COMMAND.COM" ] && [ "${FORCE_REINSTALL:-0}" != '1' ]; then
      stage_msdos_sysroot "${TARGET_DIR}" "${EXACT_VERSION}"
      libscript_symlink_alias 'msdos' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'msdos' 'default' "${EXACT_VERSION}"
      log_info "msdos ${EXACT_VERSION} is already staged at ${TARGET_DIR}."
      exit 0
    fi
    mkdir -p "${TARGET_DIR}/boot"
    STACK='' "${SCRIPT_DIR}/build_msdos.sh" "${TARGET_DIR}/boot" "${EXACT_VERSION}"
    stage_msdos_sysroot "${TARGET_DIR}" "${EXACT_VERSION}"
    libscript_symlink_alias 'msdos' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'msdos' 'default' "${EXACT_VERSION}"
    log_success "MIT MS-DOS ${EXACT_VERSION} kernel staged at ${TARGET_DIR}/boot."
    ;;
  uninstall)
    resolve_exact_version
    rm -rf "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/msdos/${EXACT_VERSION}"
    ;;
  *)
    resolve_exact_version
    TARGET_DIR=$(libscript_get_version_dir 'msdos' "${EXACT_VERSION}")
    libscript_handle_generic_action 'msdos' "${ACTION}" "${EXACT_VERSION}" 'from-source' '' '' '' "${TARGET_DIR}/boot/MSDOS.SYS" "${TARGET_DIR}"
    ;;
esac
