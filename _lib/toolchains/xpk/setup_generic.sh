#!/bin/sh
# ## Overview
# Generic setup script for the xpk component.
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
export DIR="${SCRIPT_DIR}"

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/env.sh'
  export SCRIPT_NAME
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  . "${SCRIPT_NAME}"
done

XPK_INSTALL_METHOD="${XPK_INSTALL_METHOD:-libscript_native}"
XPK_INSTALL_METHOD="$(LIBSCRIPT_DEFAULT_INSTALL_METHOD="$XPK_INSTALL_METHOD" libscript_resolve_install_method "XPK")"
XPK_VERSION="${XPK_VERSION:-latest}"
ACTION="${ACTION:-install}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${XPK_VERSION}" = "latest" ] || [ "${XPK_VERSION}" = "lts" ]; then
    EXACT_VERSION=$(libscript_fetch_stdout "https://api.github.com/repos/google/xpk/releases/latest" | grep '"tag_name":' | head -n 1 | cut -d '"' -f 4 | sed 's/^v//')
    if [ -z "$EXACT_VERSION" ]; then
      EXACT_VERSION='latest'
    fi
  else
    EXACT_VERSION="${XPK_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "${XPK_INSTALL_METHOD}" = "system" ]; then
      xpk --version || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/xpk/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "${XPK_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' 'System package manager does not support ls-remote directly here.'
    else
      printf '%s\n' 'Fetching remote versions not implemented generically for xpk'
    fi
    exit 0
    ;;
  use)
    if [ "${XPK_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "xpk" "${XPK_VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias "xpk" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/xpk/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "xpk ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "xpk" "default" "${EXACT_VERSION}"
      log_info "Set default xpk version to ${EXACT_VERSION}."
      log_info 'To apply to the current shell, run:'
      log_info "  . \"${DIR}/env.sh\" # or: . \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env xpk \"${XPK_VERSION}\")"
    fi
    exit 0
    ;;
  download)
    if [ "$XPK_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading xpk ${VERSION:-} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/xpk..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/xpk"
      if [ -n "${XPK_DOWNLOAD_URL:-}" ]; then
        libscript_download "${XPK_DOWNLOAD_URL}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/xpk/xpk-${VERSION:-}.tar.gz"
      else
        printf '%s\n' 'XPK_DOWNLOAD_URL is not defined. Skipping.'
      fi
    fi
    exit 0
    ;;
  install)

    if [ "${XPK_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'xpk'
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/xpk/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing xpk ${VERSION} natively to ${TARGET_DIR}..."
        libscript_depends 'python3' 'pip' 'python3-venv' || true
        if ! type libscript_python_venv >/dev/null 2>&1; then
          . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/python_env.sh"
        fi
        if ! (command -v python3 >/dev/null 2>&1 && python3 --version 2>&1 | awk '{split($2, v, "."); exit((v[1] > 3 || (v[1] == 3 && v[2] >= 10)) ? 0 : 1)}'); then
          libscript_depends 'python3.11' || true
        fi
        _py_ver=""
        if command -v python3.11 >/dev/null 2>&1; then
          _py_ver='3.11'
        elif command -v python3.12 >/dev/null 2>&1; then
          _py_ver='3.12'
        fi
        libscript_python_venv "${TARGET_DIR}" "${_py_ver}"
        if [ "${EXACT_VERSION}" = "latest" ]; then
          "${TARGET_DIR}/bin/pip" install -U "xpk"
        else
          "${TARGET_DIR}/bin/pip" install "xpk==${EXACT_VERSION}"
        fi
      else
        log_info "xpk ${VERSION} is already installed."
      fi
      libscript_symlink_alias "xpk" "latest" "${EXACT_VERSION}"
      libscript_symlink_alias "xpk" "default" "${EXACT_VERSION}"
      if [ -n "${VERSION:-}" ] && [ "${VERSION}" != "xpk" ]; then
        libscript_symlink_alias "xpk" "$VERSION" "${EXACT_VERSION}"
      fi
        fi

    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "xpk" "$ACTION" "$VERSION" "${XPK_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
