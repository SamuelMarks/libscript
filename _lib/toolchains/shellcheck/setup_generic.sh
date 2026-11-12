#!/bin/sh
# ## Overview
# Generic setup script for the shellcheck component implementing the Version Manager Contract.
#
# ## Usage
# This script is typically called internally by the component lifecycle.

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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mgr.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/versioning.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/source_builder.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SHELLCHECK_INSTALL_METHOD="${SHELLCHECK_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}"
ACTION="${ACTION:-install}"
VERSION="${SHELLCHECK_VERSION:-latest}"

# ## resolve_exact_version
# Resolves dynamic version aliases (latest, stable, lts) into an exact normalized upstream version string.
resolve_exact_version() {
  if [ "${VERSION}" = "latest" ] || [ "${VERSION}" = "stable" ] || [ "${VERSION}" = "lts" ]; then
    EXACT_VERSION=""
    if [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ] && [ "${LIBSCRIPT_FORCE_OFFLINE:-0}" != "1" ]; then
      EXACT_VERSION=$(libscript_fetch_stdout 'https://api.github.com/repos/koalaman/shellcheck/releases/latest' | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's/^v//' || true)
    fi
    if [ -z "${EXACT_VERSION}" ]; then
      _sc_home="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/shellcheck"
      if [ -d "${_sc_home}" ]; then
        for _cand in $(find "${_sc_home}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null || true); do
          [ -d "${_cand}" ] || continue
          _bname=$(basename "${_cand}")
          case "${_bname}" in
            default|latest|stable|lts) continue ;;
            *)
              if [ -x "${_cand}/bin/shellcheck" ]; then
                EXACT_VERSION="${_bname#v}"
              fi
              ;;
          esac
        done
      fi
    fi
    if [ -z "${EXACT_VERSION}" ]; then
      EXACT_VERSION='0.11.0'
    fi
  else
    EXACT_VERSION="${VERSION#v}"
  fi
  return 0
}

# ## resolve_platform_artifact
# Maps the current POSIX OS and CPU architecture to the upstream koalaman/shellcheck release URL.
resolve_platform_artifact() {
  _u_os="${UNAME_LOWER:-linux}"
  _u_arch="${ARCH:-x86_64}"
  SC_OS=""
  SC_ARCH=""

  case "${_u_os}" in
    linux*) SC_OS='linux' ;;
    darwin*) SC_OS='darwin' ;;
    msys*|mingw*|cygwin*) SC_OS='windows' ;;
    *) SC_OS='unsupported' ;;
  esac

  case "${_u_arch}" in
    x86_64|amd64) SC_ARCH='x86_64' ;;
    aarch64|arm64) SC_ARCH='aarch64' ;;
    armv6*|armv7*|armhf)
      if [ "${SC_OS}" = "linux" ]; then
        SC_ARCH='armv6hf'
      else
        SC_ARCH='unsupported'
      fi
      ;;
    riscv64)
      if [ "${SC_OS}" = "linux" ]; then
        SC_ARCH='riscv64'
      else
        SC_ARCH='unsupported'
      fi
      ;;
    *) SC_ARCH='unsupported' ;;
  esac

  if [ -n "${SHELLCHECK_DOWNLOAD_URL:-}" ]; then
    RESOLVED_URL=$(printf '%s\n' "${SHELLCHECK_DOWNLOAD_URL}" | sed "s/{VERSION}/${EXACT_VERSION}/g")
    return 0
  fi

  if [ "${SC_OS}" = "windows" ]; then
    RESOLVED_URL="https://github.com/koalaman/shellcheck/releases/download/v${EXACT_VERSION}/shellcheck-v${EXACT_VERSION}.zip"
    return 0
  fi

  if [ "${SC_OS}" = "unsupported" ] || [ "${SC_ARCH}" = "unsupported" ]; then
    RESOLVED_URL=""
    return 1
  fi

  RESOLVED_URL="https://github.com/koalaman/shellcheck/releases/download/v${EXACT_VERSION}/shellcheck-v${EXACT_VERSION}.${SC_OS}.${SC_ARCH}.tar.gz"
  return 0
}

# ## install_binary_from_stage
# Locates the extracted shellcheck executable inside a temporary staging directory and installs it idempotently.
install_binary_from_stage() {
  _stage_dir="$1"
  _target_dir="$2"
  mkdir -p "${_target_dir}/bin"

  _found_bin=""
  for _cand_bin in \
    "${_stage_dir}/shellcheck-v${EXACT_VERSION}/shellcheck" \
    "${_stage_dir}/shellcheck-${EXACT_VERSION}/shellcheck" \
    "${_stage_dir}/bin/shellcheck" \
    "${_stage_dir}/shellcheck" \
    "${_stage_dir}/shellcheck.exe"; do
    if [ -f "${_cand_bin}" ]; then
      _found_bin="${_cand_bin}"
      break
    fi
  done

  if [ -z "${_found_bin}" ]; then
    _found_bin=$(find "${_stage_dir}" -type f \( -name 'shellcheck' -o -name 'shellcheck.exe' \) | head -n 1 || true)
  fi

  if [ -z "${_found_bin}" ] || [ ! -f "${_found_bin}" ]; then
    log_error "Failed to locate shellcheck binary inside extracted archive (${_stage_dir})"
    return 1
  fi

  cp -f "${_found_bin}" "${_target_dir}/bin/shellcheck"
  chmod +x "${_target_dir}/bin/shellcheck"

  _found_parent=$(dirname "${_found_bin}")
  for _doc in LICENSE.txt README.txt LICENSE README.md; do
    if [ -f "${_found_parent}/${_doc}" ]; then
      cp -f "${_found_parent}/${_doc}" "${_target_dir}/${_doc}"
    elif [ -f "${_stage_dir}/${_doc}" ]; then
      cp -f "${_stage_dir}/${_doc}" "${_target_dir}/${_doc}"
    fi
  done
}

case "$ACTION" in
  ls)
    if [ "${SHELLCHECK_INSTALL_METHOD}" = "libscript_native" ]; then
      [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/shellcheck" ] && ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/shellcheck"
    else
      if command -v shellcheck >/dev/null 2>&1; then
        shellcheck --version || true
      fi
    fi
    ;;
  ls-remote)
    RELEASES_URL="${SHELLCHECK_RELEASES_URL:-https://api.github.com/repos/koalaman/shellcheck/releases}"
    printf '[ls-remote] Fetching available shellcheck versions from %s...\n' "${RELEASES_URL}"
    if [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ] && [ "${LIBSCRIPT_FORCE_OFFLINE:-0}" != "1" ]; then
      libscript_fetch_stdout "${RELEASES_URL}" | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | sed 's/^v//' | head -n 30 || true
    fi
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/shellcheck/${EXACT_VERSION}"
    if [ ! -d "$TARGET_DIR" ]; then
      printf 'Version %s not installed. Installing...\n' "$EXACT_VERSION"
      ACTION='install' "$0"
    fi
    libscript_symlink_alias 'shellcheck' "${VERSION#v}" "${EXACT_VERSION}"
    libscript_symlink_alias 'shellcheck' 'default' "${EXACT_VERSION}"
    ;;
  download)
    resolve_exact_version
    if ! resolve_platform_artifact; then
      RESOLVED_URL="https://github.com/koalaman/shellcheck/archive/refs/tags/v${EXACT_VERSION}.tar.gz"
    fi
    DL_DIR="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/shellcheck"
    mkdir -p "$DL_DIR"
    ARCHIVE_NAME=$(basename "$RESOLVED_URL")
    printf '[download] Pre-downloading shellcheck %s from %s to %s...\n' "$EXACT_VERSION" "$RESOLVED_URL" "$DL_DIR/$ARCHIVE_NAME"
    PACKAGE_NAME='shellcheck' libscript_download "$RESOLVED_URL" "$DL_DIR/$ARCHIVE_NAME"
    ;;
  install)
    case "${SHELLCHECK_INSTALL_METHOD}" in
      from-source|source)
        resolve_exact_version
        TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/shellcheck/${EXACT_VERSION}"
        if [ -x "${TARGET_DIR}/bin/shellcheck" ] && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
          log_info "shellcheck ${EXACT_VERSION} is already installed at ${TARGET_DIR}."
          libscript_symlink_alias 'shellcheck' "${VERSION#v}" "${EXACT_VERSION}"
          libscript_symlink_alias 'shellcheck' 'default' "${EXACT_VERSION}"
          exit 0
        fi
        _ls_def_url="https://github.com/koalaman/shellcheck/archive/refs/tags/v{VERSION}.tar.gz"
        SRC_URL="${SHELLCHECK_DOWNLOAD_URL:-${_ls_def_url}}"
        SRC_URL=$(printf '%s\n' "$SRC_URL" | sed "s/{VERSION}/${EXACT_VERSION}/g")
        if command -v cabal >/dev/null 2>&1 && [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ]; then
          mkdir -p "${TARGET_DIR}/bin"
          if cabal update && cabal install "ShellCheck-${EXACT_VERSION}" --installdir="${TARGET_DIR}/bin" --install-method=copy --overwrite-policy=always; then
            libscript_symlink_alias 'shellcheck' "${VERSION#v}" "${EXACT_VERSION}"
            libscript_symlink_alias 'shellcheck' 'default' "${EXACT_VERSION}"
            exit 0
          fi
        fi
        libscript_build_component_from_source 'shellcheck' "$EXACT_VERSION" 'shellcheck' 'c' 'make' "$SRC_URL"
        libscript_symlink_alias 'shellcheck' "${VERSION#v}" "${EXACT_VERSION}"
        libscript_symlink_alias 'shellcheck' 'default' "${EXACT_VERSION}"
        exit 0
        ;;
      system)
        libscript_depends 'shellcheck'
        ;;
      nix|guix|spack|brew|winget|choco|scoop)
        libscript_depends_via "${SHELLCHECK_INSTALL_METHOD}" 'shellcheck'
        ;;
      *)
        resolve_exact_version
        TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/shellcheck/${EXACT_VERSION}"
        if [ -x "${TARGET_DIR}/bin/shellcheck" ] && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
          printf '[INFO] shellcheck %s is already installed at %s.\n' "${EXACT_VERSION}" "${TARGET_DIR}"
          libscript_symlink_alias 'shellcheck' "${VERSION#v}" "${EXACT_VERSION}"
          libscript_symlink_alias 'shellcheck' 'default' "${EXACT_VERSION}"
          exit 0
        fi

        if ! resolve_platform_artifact; then
          log_info "No prebuilt static shellcheck tarball for ${UNAME:-unknown}/${ARCH:-unknown}; delegating to system package manager..."
          libscript_depends 'shellcheck'
          exit 0
        fi

        mkdir -p "${TARGET_DIR}/bin"
        ARCHIVE_NAME=$(basename "${RESOLVED_URL}")
        CACHED_DL="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/shellcheck/${ARCHIVE_NAME}"
        if [ -s "${CACHED_DL}" ]; then
          TMP_FILE="${CACHED_DL}"
        else
          TMP_FILE="${TMPDIR:-/tmp}/shellcheck-$$-${ARCHIVE_NAME}"
          PACKAGE_NAME='shellcheck' libscript_download "${RESOLVED_URL}" "${TMP_FILE}"
        fi

        STAGE_DIR="${TMPDIR:-/tmp}/shellcheck-stage-$$"
        rm -rf "${STAGE_DIR}"
        mkdir -p "${STAGE_DIR}"

        case "${RESOLVED_URL}" in
          *.tar.gz|*.tgz)
            tar -xzf "${TMP_FILE}" -C "${STAGE_DIR}"
            install_binary_from_stage "${STAGE_DIR}" "${TARGET_DIR}"
            ;;
          *.tar.xz|*.txz)
            tar -xJf "${TMP_FILE}" -C "${STAGE_DIR}"
            install_binary_from_stage "${STAGE_DIR}" "${TARGET_DIR}"
            ;;
          *.zip)
            unzip -q -o "${TMP_FILE}" -d "${STAGE_DIR}"
            install_binary_from_stage "${STAGE_DIR}" "${TARGET_DIR}"
            ;;
          *)
            cp -f "${TMP_FILE}" "${TARGET_DIR}/bin/shellcheck"
            chmod +x "${TARGET_DIR}/bin/shellcheck"
            ;;
        esac

        rm -rf "${STAGE_DIR}"
        if [ "${TMP_FILE}" != "${CACHED_DL}" ]; then
          rm -f "${TMP_FILE}"
        fi
        libscript_symlink_alias 'shellcheck' "${VERSION#v}" "${EXACT_VERSION}"
        libscript_symlink_alias 'shellcheck' 'default' "${EXACT_VERSION}"
        ;;
    esac
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'shellcheck' "$ACTION" "$VERSION" "${SHELLCHECK_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
