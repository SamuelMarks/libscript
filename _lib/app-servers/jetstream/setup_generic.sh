#!/bin/sh
# ## Overview
# Generic setup module for Jetstream.
#
# ## Usage
# Handles libscript_native installation (using python's venv) as well as delegation.

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
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

JETSTREAM_INSTALL_METHOD="$(libscript_resolve_install_method "JETSTREAM")"
ACTION="${ACTION:-install}"
VERSION="${JETSTREAM_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote jetstream 2>/dev/null | tail -n 1)
    if [ -n "$_latest" ] && [ "$_latest" != "No versions found" ] && [ "$_latest" != "ls-remote not fully implemented natively yet." ]; then
      EXACT_VERSION="$_latest"
    else
      EXACT_VERSION="${VERSION:-latest}"
    fi
  else
    EXACT_VERSION="${VERSION:-latest}"
  fi
}

case "$ACTION" in
  ls)
    libscript_handle_generic_action "jetstream" "$ACTION" "$VERSION" "${JETSTREAM_INSTALL_METHOD}"
    ;;
  ls-remote)
    printf '%s\n' 'Use pip index versions jetstream-pytorch'
    exit 0
    ;;
  use)
    libscript_handle_generic_action "jetstream" "$ACTION" "$VERSION" "${JETSTREAM_INSTALL_METHOD}"
    ;;
  download)
    if [ "$JETSTREAM_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading jetstream ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/jetstream..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/jetstream"
      if [ -n "${JETSTREAM_DOWNLOAD_URL:-}" ]; then
        libscript_download "${JETSTREAM_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/jetstream/jetstream-${VERSION}.tar.gz"
      else
        log_warn "JETSTREAM_DOWNLOAD_URL is not defined for jetstream ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$JETSTREAM_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' 'system install not implemented for jetstream'
    else
      # libscript_native implementation
      resolve_exact_version
      
      if [ -f "/etc/alpine-release" ]; then
        log_info 'Skipping Jetstream installation on Alpine. Missing jaxlib wheels for musl.'
        exit 0
      fi

      libscript_depends 'python' 'git'
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/jetstream/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing Jetstream ${EXACT_VERSION} to ${TARGET_DIR}..."
        if ! type libscript_python_venv >/dev/null 2>&1; then
          . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/python_env.sh"
        fi
        _py_ver=""
        if command -v python3 >/dev/null 2>&1 && python3 --version 2>&1 | awk '{split($2, v, "."); exit((v[1] > 3 || (v[1] == 3 && v[2] >= 10)) ? 0 : 1)}'; then
          _py_ver=""
        elif command -v python3.11 >/dev/null 2>&1; then
          _py_ver='3.11'
        elif command -v python3.12 >/dev/null 2>&1; then
          _py_ver='3.12'
        elif command -v python3.10 >/dev/null 2>&1; then
          _py_ver='3.10'
        else
          if [ "${PKG_MGR:-}" = "dnf" ] || [ "${PKG_MGR:-}" = "yum" ]; then
            pkg_mgr_install python3.11 python3.11-pip python3.11-devel || true
            if command -v python3.11 >/dev/null 2>&1; then
              _py_ver='3.11'
            fi
          fi
        fi
        libscript_python_venv "${TARGET_DIR}" "${_py_ver}"
        
        JETSTREAM_SRC_DIR="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/jetstream-src"
        if [ ! -d "${JETSTREAM_SRC_DIR}/.git" ]; then
            git clone https://github.com/google/JetStream.git "${JETSTREAM_SRC_DIR}"
        else
            log_info 'Jetstream source already present, pulling latest...'
            (cd "${JETSTREAM_SRC_DIR}" && git fetch --all && git reset --hard '@{upstream}')
        fi
        
        if [ "$EXACT_VERSION" != "latest" ]; then
            (cd "${JETSTREAM_SRC_DIR}" && git checkout "v${EXACT_VERSION}" 2>/dev/null || git checkout "${EXACT_VERSION}" 2>/dev/null || true)
        fi

        "${TARGET_DIR}/bin/pip" install --upgrade pip
        "${TARGET_DIR}/bin/pip" install -e "${JETSTREAM_SRC_DIR}" || "${TARGET_DIR}/bin/pip" install -e "${JETSTREAM_SRC_DIR}" --no-deps || PIP_FAILED=1
        
        if [ "${PIP_FAILED:-0}" = "1" ]; then
          log_error 'Failed to install Jetstream via pip.'
          exit 1
        fi
        
        # Link main entry points
        cat << 'EOF' > "${TARGET_DIR}/bin/jetstream"
#!/bin/sh
# ## Overview
# Executable wrapper for jetstream.
#
# ## Usage
# jetstream "$@"

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

SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
exec "${SCRIPT_DIR}/python" -m jetstream "$@"
EOF
        chmod +x "${TARGET_DIR}/bin/jetstream"
      else
        log_info "Jetstream ${EXACT_VERSION} is already installed."
      fi
      
      libscript_symlink_alias "jetstream" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "jetstream" "$ACTION" "$VERSION" "${JETSTREAM_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
