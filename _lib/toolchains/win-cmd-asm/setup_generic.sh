#!/bin/sh
# ## Overview
# Generic setup for win-cmd-asm (multi-ISA assembly shell, 17 DOS utilities, vm8086, asm-conv).
# Supports local sibling ../win-cmd-asm builds, GitHub releases, and C89 clean-room 8086 emission.
#
# ## Usage
# ACTION=install ./_lib/toolchains/win-cmd-asm/setup.sh

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

for _wlib in "engine/common/pkg_mgr.sh" "engine/common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_wlib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME || true

ACTION="${ACTION:-install}"
VERSION="${WIN_CMD_ASM_VERSION:-0.1.0}"

# ## resolve_exact_version
# Normalizes latest/stable/lts aliases into a concrete win-cmd-asm version string.
resolve_exact_version() {
  case "${VERSION}" in
    latest|stable|lts) EXACT_VERSION='0.1.0' ;;
    *) EXACT_VERSION="${VERSION#v}" ;;
  esac
}

# ## stage_to_dos_sysroot
# Copies WINCMD1.COM or WINCMD.COM + 17 DOS utilities into LIBSCRIPT_TARGET_SYSROOT during OS image synthesis.
stage_to_dos_sysroot() {
  _stds_src="$1"
  if [ "${LIBSCRIPT_IMAGE_BUILD:-0}" != '1' ] || [ -z "${LIBSCRIPT_TARGET_SYSROOT:-}" ]; then
    return 0
  fi
  if [ "${LIBSCRIPT_DOS_STRATUM:-}" = 'dos16-fcb' ]; then
    mkdir -p "${LIBSCRIPT_TARGET_SYSROOT}"
    cp -f "${_stds_src}/target-dos/dos125/WINCMD1.COM" "${LIBSCRIPT_TARGET_SYSROOT}/WINCMD1.COM"
  else
    mkdir -p "${LIBSCRIPT_TARGET_SYSROOT}/DOS" "${LIBSCRIPT_TARGET_SYSROOT}/LIBSCRIP/BIN"
    for _fn in $(ls -1 "${_stds_src}/target-dos/dos16" 2>/dev/null || true); do
      case "${_fn}" in
        *.COM) [ -f "${_stds_src}/target-dos/dos16/${_fn}" ] && cp -f "${_stds_src}/target-dos/dos16/${_fn}" "${LIBSCRIPT_TARGET_SYSROOT}/DOS/" ;;
      esac
    done
    cp -f "${_stds_src}/target-dos/dos125/WINCMD1.COM" "${LIBSCRIPT_TARGET_SYSROOT}/DOS/WINCMD1.COM"
  fi
}

case "${ACTION}" in
  ls)
    if [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/win-cmd-asm" ]; then
      ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/win-cmd-asm" || true
    fi
    ;;
  ls-remote)
    printf '0.1.0\n'
    ;;
  download)
    resolve_exact_version
    printf '[INFO] win-cmd-asm %s sources ready.\n' "${EXACT_VERSION}"
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/win-cmd-asm/${EXACT_VERSION}"
    [ -x "${TARGET_DIR}/bin/asm-conv" ] || exit 1
    libscript_symlink_alias 'win-cmd-asm' 'default' "${EXACT_VERSION}"
    ;;
  bootstrap|compile|install)
    resolve_exact_version
    TARGET_DIR=$(libscript_get_version_dir 'win-cmd-asm' "${EXACT_VERSION}")
    if [ -x "${TARGET_DIR}/bin/asm-conv" ] && [ -f "${TARGET_DIR}/target-dos/dos125/WINCMD1.COM" ] && [ -f "${TARGET_DIR}/target-dos/dos16/WINCMD.COM" ] && [ "${FORCE_REINSTALL:-0}" != '1' ]; then
      stage_to_dos_sysroot "${TARGET_DIR}"
      libscript_symlink_alias 'win-cmd-asm' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'win-cmd-asm' 'default' "${EXACT_VERSION}"
      log_info "win-cmd-asm ${EXACT_VERSION} is already installed at ${TARGET_DIR}."
      exit 0
    fi
    mkdir -p "${TARGET_DIR}/bin" "${TARGET_DIR}/target-dos/dos125" "${TARGET_DIR}/target-dos/dos16"
    STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/compile_host_c89.sh" "${SCRIPT_DIR}/src/asm_conv_c89.c" "${TARGET_DIR}/bin/asm-conv"
    chmod +x "${TARGET_DIR}/bin/asm-conv"

    _emit_bin="${TMPDIR:-/tmp}/wca_emit_$$"
    STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/compile_host_c89.sh" "${SCRIPT_DIR}/src/emit_dos_suite_c89.c" "${_emit_bin}"
    "${_emit_bin}" "${TARGET_DIR}/target-dos"
    rm -f "${_emit_bin}"

    # Overlay prebuilt binaries from sibling ../win-cmd-asm checkout if present
    _repo_dir="${WIN_CMD_ASM_REPO_DIR:-${LIBSCRIPT_ROOT_DIR}/../win-cmd-asm}"
    if [ -d "${_repo_dir}" ]; then
      for _cand in "${_repo_dir}/build/dos/WINCMD1.COM" "${_repo_dir}/dist/WINCMD1.COM"; do
        [ -f "${_cand}" ] && cp -f "${_cand}" "${TARGET_DIR}/target-dos/dos125/WINCMD1.COM"
      done
      for _cand in "${_repo_dir}/build/dos/WINCMD.COM" "${_repo_dir}/dist/WINCMD.COM"; do
        [ -f "${_cand}" ] && cp -f "${_cand}" "${TARGET_DIR}/target-dos/dos16/WINCMD.COM"
      done
    fi

    stage_to_dos_sysroot "${TARGET_DIR}"
    libscript_symlink_alias 'win-cmd-asm' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'win-cmd-asm' 'default' "${EXACT_VERSION}"
    log_success "win-cmd-asm ${EXACT_VERSION} installed at ${TARGET_DIR}."
    ;;
  uninstall)
    resolve_exact_version
    rm -rf "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/win-cmd-asm/${EXACT_VERSION}"
    ;;
  *)
    resolve_exact_version
    TARGET_DIR=$(libscript_get_version_dir 'win-cmd-asm' "${EXACT_VERSION}")
    libscript_handle_generic_action 'win-cmd-asm' "${ACTION}" "${EXACT_VERSION}" 'from-source' '' '' '' "${TARGET_DIR}/bin/asm-conv" "${TARGET_DIR}"
    ;;
esac
