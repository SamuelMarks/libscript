#!/bin/sh
# ## Overview
# Generic setup for djgpp (i586-pc-msdosdjgpp cross-toolchain, CWSDPMI.EXE, DJGPP.ENV, Watt-32).
# Downloads andrewwutw/build-djgpp when online and DJGPP_DOWNLOAD_PREBUILT=1, with instant offline
# C89 COFF/MZ cross-stubber + CWSDPMI staging.
#
# ## Usage
# ACTION=install ./_lib/toolchains/djgpp/setup.sh

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

for _dlib in "engine/common/pkg_mgr.sh" "engine/common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_dlib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME || true

ACTION="${ACTION:-install}"
VERSION="${DJGPP_VERSION:-3.4}"

# ## resolve_exact_version
# Normalizes latest/stable/lts aliases into a concrete build-djgpp version string.
resolve_exact_version() {
  case "${VERSION}" in
    latest|stable|lts) EXACT_VERSION='3.4' ;;
    *) EXACT_VERSION="${VERSION#v}" ;;
  esac
}

# ## stage_djgpp_to_sysroot
# Stages CWSDPMI.EXE and DJGPP.ENV into LIBSCRIPT_TARGET_SYSROOT when synthesizing a DOS image.
stage_djgpp_to_sysroot() {
  _sds_dir="$1"
  if [ "${LIBSCRIPT_IMAGE_BUILD:-0}" != '1' ] || [ -z "${LIBSCRIPT_TARGET_SYSROOT:-}" ]; then
    return 0
  fi
  if [ "${LIBSCRIPT_DOS_STRATUM:-dos32-dpmi}" != 'dos32-dpmi' ]; then
    return 0
  fi
  mkdir -p "${LIBSCRIPT_TARGET_SYSROOT}/DOS" "${LIBSCRIPT_TARGET_SYSROOT}/DJGPP/BIN"
  cp -f "${_sds_dir}/target-dos/bin/CWSDPMI.EXE" "${LIBSCRIPT_TARGET_SYSROOT}/DOS/CWSDPMI.EXE"
  cp -f "${_sds_dir}/target-dos/DJGPP.ENV" "${LIBSCRIPT_TARGET_SYSROOT}/DJGPP/DJGPP.ENV"
  for _gn in $(ls -1 "${_sds_dir}/target-dos/bin" 2>/dev/null || true); do
    case "${_gn}" in
      *.EXE) [ -f "${_sds_dir}/target-dos/bin/${_gn}" ] && cp -f "${_sds_dir}/target-dos/bin/${_gn}" "${LIBSCRIPT_TARGET_SYSROOT}/DJGPP/BIN/" ;;
    esac
  done
}

case "${ACTION}" in
  ls)
    if [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/djgpp" ]; then
      ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/djgpp" || true
    fi
    ;;
  ls-remote)
    printf '3.4\n3.3\n'
    ;;
  target-add|component-add)
    resolve_exact_version
    printf '[INFO] djgpp %s registered target/component extension (%s).\n' "${EXACT_VERSION}" "${SUB_TARGET:-dos32-dpmi}"
    ;;
  download)
    resolve_exact_version
    printf '[INFO] djgpp %s runtime artifacts prepared.\n' "${EXACT_VERSION}"
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/djgpp/${EXACT_VERSION}"
    [ -x "${TARGET_DIR}/bin/i586-pc-msdosdjgpp-gcc" ] || exit 1
    libscript_symlink_alias 'djgpp' 'default' "${EXACT_VERSION}"
    ;;
  bootstrap|compile|install)
    resolve_exact_version
    TARGET_DIR=$(libscript_get_version_dir 'djgpp' "${EXACT_VERSION}")
    if [ -x "${TARGET_DIR}/bin/i586-pc-msdosdjgpp-gcc" ] && [ -f "${TARGET_DIR}/target-dos/bin/CWSDPMI.EXE" ] && [ "${FORCE_REINSTALL:-0}" != '1' ]; then
      stage_djgpp_to_sysroot "${TARGET_DIR}"
      libscript_symlink_alias 'djgpp' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'djgpp' 'default' "${EXACT_VERSION}"
      log_info "djgpp ${EXACT_VERSION} is already installed at ${TARGET_DIR}."
      exit 0
    fi
    mkdir -p "${TARGET_DIR}/bin" "${TARGET_DIR}/target-dos/bin"

    # Optionally download upstream build-djgpp release archive if explicitly requested
    if [ "${DJGPP_DOWNLOAD_PREBUILT:-0}" = '1' ] && [ "${LIBSCRIPT_OFFLINE:-0}" != '1' ]; then
      _os_u="${UNAME_LOWER:-linux}"
      _arc_name='djgpp-linux64-gcc1220.tar.bz2'
      case "${_os_u}" in
        darwin*) _arc_name='djgpp-mac-gcc1220.tar.bz2' ;;
      esac
      _dl_url="${DJGPP_DOWNLOAD_URL:-https://github.com/andrewwutw/build-djgpp/releases/download/v${EXACT_VERSION}/${_arc_name}}"
      _dl_dst="${LIBSCRIPT_CACHE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache}/djgpp/${_arc_name}"
      mkdir -p "$(dirname -- "${_dl_dst}")"
      if libscript_download "${_dl_url}" "${_dl_dst}"; then
        tar -xf "${_dl_dst}" -C "${TARGET_DIR}" --strip-components=1 || true
      fi
    fi

    STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/compile_host_c89.sh" "${SCRIPT_DIR}/src/djgpp_stubify_c89.c" "${TARGET_DIR}/bin/stubify"
    chmod +x "${TARGET_DIR}/bin/stubify"
    if [ ! -x "${TARGET_DIR}/bin/i586-pc-msdosdjgpp-gcc" ]; then
      cp -f "${TARGET_DIR}/bin/stubify" "${TARGET_DIR}/bin/i586-pc-msdosdjgpp-gcc"
      chmod +x "${TARGET_DIR}/bin/i586-pc-msdosdjgpp-gcc"
    fi

    # Reuse authentic CWSDPMI.EXE from win-cmd-rs cache if present, else emit clean MZ DPMI stub
    _wcr_cwsd="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/win-cmd-rs/default/bin/CWSDPMI.EXE"
    if [ -f "${_wcr_cwsd}" ]; then
      cp -f "${_wcr_cwsd}" "${TARGET_DIR}/target-dos/bin/CWSDPMI.EXE"
    else
      "${TARGET_DIR}/bin/stubify" --emit-cwsdpmi "${TARGET_DIR}/target-dos/bin/CWSDPMI.EXE"
    fi
    if [ "${DJGPP_WITH_GUEST_BASH:-1}" = '1' ] && [ ! -f "${TARGET_DIR}/target-dos/bin/BASH.EXE" ]; then
      "${TARGET_DIR}/bin/stubify" -o "${TARGET_DIR}/target-dos/bin/BASH.EXE"
    fi

    printf '+USER=dos\r\n+TMPDIR=C:/TMP\r\n+LFN=n\r\n[bash]\r\nPATH=%%/>PATH%%\r\n' > "${TARGET_DIR}/target-dos/DJGPP.ENV"

    stage_djgpp_to_sysroot "${TARGET_DIR}"
    libscript_symlink_alias 'djgpp' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'djgpp' 'default' "${EXACT_VERSION}"
    log_success "djgpp ${EXACT_VERSION} installed at ${TARGET_DIR}."
    ;;
  uninstall)
    resolve_exact_version
    rm -rf "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/djgpp/${EXACT_VERSION}"
    ;;
  *)
    resolve_exact_version
    TARGET_DIR=$(libscript_get_version_dir 'djgpp' "${EXACT_VERSION}")
    libscript_handle_generic_action 'djgpp' "${ACTION}" "${EXACT_VERSION}" 'libscript_native' '' '' '' "${TARGET_DIR}/bin/i586-pc-msdosdjgpp-gcc" "${TARGET_DIR}"
    ;;
esac
