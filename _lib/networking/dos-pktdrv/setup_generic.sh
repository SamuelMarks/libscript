#!/bin/sh
# ## Overview
# Tier 2 sysroot setup for dos-pktdrv (PCNTPKT.COM, NE2000.COM, SHSUCDX.COM, FDAPM.COM, HIMEMX.EXE, DOSLFN.COM).
# Rejects `use` with exit code 2 per the T2 Version Manager Contract.
#
# ## Usage
# ACTION=install ./_lib/networking/dos-pktdrv/setup.sh

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

for _plib in "engine/common/pkg_mgr.sh" "engine/common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_plib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME || true

ACTION="${ACTION:-install}"
VERSION="${DOS_PKTDRV_VERSION:-1.4}"

# ## resolve_exact_version
# Normalizes latest/stable/lts aliases into concrete dos-pktdrv version.
resolve_exact_version() {
  case "${VERSION}" in
    latest|stable|lts) EXACT_VERSION='1.4' ;;
    *) EXACT_VERSION="${VERSION#v}" ;;
  esac
}

# ## stage_pktdrv_sysroot
# Copies staged DOS drivers into LIBSCRIPT_TARGET_SYSROOT/DOS during image synthesis.
stage_pktdrv_sysroot() {
  _sps_dir="$1"
  if [ "${LIBSCRIPT_IMAGE_BUILD:-0}" != '1' ] || [ -z "${LIBSCRIPT_TARGET_SYSROOT:-}" ]; then
    return 0
  fi
  if [ "${LIBSCRIPT_DOS_STRATUM:-}" = 'dos16-fcb' ]; then
    return 0
  fi
  mkdir -p "${LIBSCRIPT_TARGET_SYSROOT}/DOS"
  for _dn in $(ls -1 "${_sps_dir}/dos" 2>/dev/null || true); do
    [ -f "${_sps_dir}/dos/${_dn}" ] || continue
    cp -f "${_sps_dir}/dos/${_dn}" "${LIBSCRIPT_TARGET_SYSROOT}/DOS/"
  done
}

case "${ACTION}" in
  use)
    printf '[ERROR] dos-pktdrv is a Tier 2 sysroot-only package; use is unsupported.\n' >&2
    exit 2
    ;;
  ls)
    if [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/dos-pktdrv" ]; then
      ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/dos-pktdrv" || true
    fi
    ;;
  ls-remote)
    printf '1.4\n'
    ;;
  download)
    resolve_exact_version
    printf '[INFO] dos-pktdrv %s driver sources ready.\n' "${EXACT_VERSION}"
    ;;
  bootstrap|compile|install)
    resolve_exact_version
    TARGET_DIR=$(libscript_get_version_dir 'dos-pktdrv' "${EXACT_VERSION}")
    if [ -f "${TARGET_DIR}/dos/PCNTPKT.COM" ] && [ -f "${TARGET_DIR}/dos/FDAPM.COM" ] && [ "${FORCE_REINSTALL:-0}" != '1' ]; then
      stage_pktdrv_sysroot "${TARGET_DIR}"
      libscript_symlink_alias 'dos-pktdrv' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'dos-pktdrv' 'default' "${EXACT_VERSION}"
      log_info "dos-pktdrv ${EXACT_VERSION} is already staged at ${TARGET_DIR}."
      exit 0
    fi
    mkdir -p "${TARGET_DIR}/dos"
    _emit="${TMPDIR:-/tmp}/pktdrv_emit_$$"
    STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/compile_host_c89.sh" "${SCRIPT_DIR}/src/emit_dos_drivers_c89.c" "${_emit}"
    "${_emit}" "${TARGET_DIR}/dos"
    rm -f "${_emit}"
    stage_pktdrv_sysroot "${TARGET_DIR}"
    libscript_symlink_alias 'dos-pktdrv' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'dos-pktdrv' 'default' "${EXACT_VERSION}"
    log_success "dos-pktdrv ${EXACT_VERSION} staged at ${TARGET_DIR}/dos."
    ;;
  uninstall)
    resolve_exact_version
    rm -rf "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/dos-pktdrv/${EXACT_VERSION}"
    ;;
  *)
    resolve_exact_version
    TARGET_DIR=$(libscript_get_version_dir 'dos-pktdrv' "${EXACT_VERSION}")
    libscript_handle_generic_action 'dos-pktdrv' "${ACTION}" "${EXACT_VERSION}" 'from-source' '' '' '' "${TARGET_DIR}/dos/PCNTPKT.COM" "${TARGET_DIR}"
    ;;
esac
