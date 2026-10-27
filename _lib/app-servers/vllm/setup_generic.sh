#!/bin/sh
# ## Overview
# Generic setup module for vllm.
# 
# ## Usage
# Execute this script to perform generic initialization steps for vllm.

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

VLLM_INSTALL_METHOD="$(libscript_resolve_install_method "VLLM")"
ACTION="${ACTION:-install}"
VERSION="${VLLM_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote vllm 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "vllm" "$ACTION" "$VERSION" "${VLLM_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${VLLM_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${VLLM_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/vllm-project/vllm" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "vllm" "$ACTION" "$VERSION" "${VLLM_INSTALL_METHOD}"
    ;;
  download)
    if [ "$VLLM_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading vllm ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/vllm..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/vllm"
      if [ -n "${VLLM_DOWNLOAD_URL:-}" ]; then
        libscript_download "${VLLM_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/vllm/vllm-${VERSION}.tar.gz"
      else
        log_warn "VLLM_DOWNLOAD_URL is not defined for vllm ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$VLLM_INSTALL_METHOD" = "system" ]; then
      if ! libscript_depends "vllm" 2>/dev/null; then
        log_warn 'System package for vllm failed. Falling back to native venv python3 installation.'
        VLLM_INSTALL_METHOD='libscript_native'
      fi
    fi

    # libscript_native implementation
    resolve_exact_version
    libscript_depends 'python'
    
    TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/vllm/${EXACT_VERSION}"
    if [ ! -d "${TARGET_DIR}" ]; then
      log_info "Installing vllm ${VERSION} to ${TARGET_DIR}..."
      if ! type libscript_python_venv >/dev/null 2>&1; then
        _ls_src_this="${THIS_FILE:-}"; _ls_src_dir="${SCRIPT_DIR:-}"
        SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/python_env.sh"
        export SCRIPT_NAME
        # shellcheck disable=SC1090,SC1091
        . "${SCRIPT_NAME}"
        unset SCRIPT_NAME || true
        [ -n "${_ls_src_this:-}" ] && THIS_FILE="$_ls_src_this"
        [ -n "${_ls_src_dir:-}" ] && SCRIPT_DIR="$_ls_src_dir"
      fi
      libscript_python_venv "${TARGET_DIR}"

      PIP_EXTRA_ARGS=""
      if [ "$UNAME_LOWER" = "linux" ]; then
        PIP_EXTRA_ARGS="--extra-index-url https://download.pytorch.org/whl/cpu"
      fi

      if [ "$EXACT_VERSION" = "latest" ]; then
        # shellcheck disable=SC2086
        TMPDIR=/var/tmp "${TARGET_DIR}/bin/pip" install $PIP_EXTRA_ARGS --no-cache-dir --upgrade vllm || PIP_FAILED=1
      else
        # shellcheck disable=SC2086
        TMPDIR=/var/tmp "${TARGET_DIR}/bin/pip" install $PIP_EXTRA_ARGS --no-cache-dir "vllm==${EXACT_VERSION}" || PIP_FAILED=1
      fi

      # Ensure vllm executable wrapper exists if pip failed to generate console script
      if [ ! -s "${TARGET_DIR}/bin/vllm" ]; then
        cat <<'EOF' > "${TARGET_DIR}/bin/vllm"
#!/bin/sh
# ## Overview
# Executable wrapper for vllm.
#
# ## Usage
# vllm "$@"

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

VENV_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")/.." && pwd)
export VLLM_TARGET_DEVICE="${VLLM_TARGET_DEVICE:-cpu}"
exec "${VENV_DIR}/bin/python3" -m vllm.entrypoints.cli.main "$@"
EOF
        chmod +x "${TARGET_DIR}/bin/vllm"
      fi
      
      if [ "${PIP_FAILED:-0}" = "1" ]; then
        log_error 'Failed to install vllm via pip.'
        if [ "${TARGET_OS:-}" = "alpine" ]; then
          log_warn 'vllm is known to fail on Alpine due to lack of PyTorch musl wheels. Falling back to build from source.'
          
          # Install build dependencies
          libscript_depends 'git' 'c' 'cmake' 'ninja' 'python' || true
          
          # Create a temporary directory for the source
          VLLM_SRC_DIR="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/vllm-src"
          if [ ! -d "${VLLM_SRC_DIR}/.git" ]; then
              git clone "https://github.com/vllm-project/vllm.git" "${VLLM_SRC_DIR}"
          else
              log_info 'vLLM source already present, pulling latest...'
              (cd "${VLLM_SRC_DIR}" && git fetch --all && git reset --hard '@{upstream}')
          fi
          
          # Build and install
          (
            cd "${VLLM_SRC_DIR}"
            if [ "$EXACT_VERSION" != "latest" ]; then
              git checkout "v${EXACT_VERSION}" || git checkout "${EXACT_VERSION}"
            fi
            "${TARGET_DIR}/bin/pip" install -e .
          ) || {
            log_error 'Failed to build vllm from source.'
            exit 1
          }
        else
          exit 1
        fi
      fi
    else
      log_info "vllm ${VERSION} is already installed."
    fi
    libscript_symlink_alias "vllm" "$VERSION" "${EXACT_VERSION}"
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "vllm" "$ACTION" "$VERSION" "${VLLM_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
