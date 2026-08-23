#!/bin/sh
# ## Overview
# Generic setup module for Jetstream.
#
# ## Usage
# Handles libscript_native installation (using python's venv) as well as delegation.

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
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
# Executes resolve_exact_version functionality.
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
    if [ "$JETSTREAM_INSTALL_METHOD" = "mise" ]; then
      mise ls jetstream-pytorch
    elif [ "$JETSTREAM_INSTALL_METHOD" = "asdf" ]; then
      asdf list jetstream-pytorch
    elif [ "$JETSTREAM_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$JETSTREAM_INSTALL_METHOD" = "vfox" ]; then
      vfox ls jetstream || true
    elif [ "$JETSTREAM_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/jetstream/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    printf '%s\n' "Use pip index versions jetstream-pytorch"
    exit 0
    ;;
  use)
    if [ "$JETSTREAM_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "jetstream" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "jetstream" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/jetstream/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "jetstream ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "jetstream" "default" "${EXACT_VERSION}"
      log_info "Set default jetstream version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env jetstream \"$VERSION\")"
    fi
    exit 0
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
      printf '%s\n' "system install not implemented for jetstream"
    elif [ "$JETSTREAM_INSTALL_METHOD" = "mise" ]; then
      printf '%s\n' "mise install not implemented for jetstream"
    elif [ "$JETSTREAM_INSTALL_METHOD" = "asdf" ]; then
      printf '%s\n' "asdf install not implemented for jetstream"
    elif [ "$JETSTREAM_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx install not implemented for jetstream"
    elif [ "$JETSTREAM_INSTALL_METHOD" = "vfox" ]; then
      printf '%s\n' "vfox install not implemented for jetstream"
    else
      # libscript_native implementation
      resolve_exact_version
      
      if [ -f "/etc/alpine-release" ]; then
        log_info "Skipping Jetstream installation on Alpine. Missing jaxlib wheels for musl."
        exit 0
      fi

      libscript_depends 'python' 'git'
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/jetstream/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing Jetstream ${EXACT_VERSION} to ${TARGET_DIR}..."
        if ! type libscript_python_venv >/dev/null 2>&1; then
          . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/python_env.sh"
        fi
        libscript_python_venv "${TARGET_DIR}"
        
        TEMP_DIR=$(mktemp -d)
        git clone https://github.com/google/JetStream.git "${TEMP_DIR}"
        
        if [ "$EXACT_VERSION" != "latest" ]; then
            (cd "${TEMP_DIR}" && git checkout "v${EXACT_VERSION}" 2>/dev/null || git checkout "${EXACT_VERSION}" 2>/dev/null || true)
        fi

        "${TARGET_DIR}/bin/pip" install --upgrade pip
        "${TARGET_DIR}/bin/pip" install -e "${TEMP_DIR}" || PIP_FAILED=1
        
        if [ "${PIP_FAILED:-0}" = "1" ]; then
          log_error "Failed to install Jetstream via pip."
          exit 1
        fi
        
        # Link main entry points
        cat << 'EOF' > "${TARGET_DIR}/bin/jetstream"
#!/bin/sh
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
exec "$SCRIPT_DIR/python" -m jetstream "$@"
EOF
        chmod +x "${TARGET_DIR}/bin/jetstream"
      else
        log_info "Jetstream ${EXACT_VERSION} is already installed."
      fi
      
      libscript_symlink_alias "jetstream" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$JETSTREAM_INSTALL_METHOD" = "libscript_native" ] || [ "$JETSTREAM_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-jetstream}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $JETSTREAM_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$JETSTREAM_INSTALL_METHOD" = "libscript_native" ] || [ "$JETSTREAM_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-jetstream}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $JETSTREAM_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$JETSTREAM_INSTALL_METHOD" = "libscript_native" ] || [ "$JETSTREAM_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-jetstream}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $JETSTREAM_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$JETSTREAM_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling jetstream $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/jetstream/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/jetstream/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $JETSTREAM_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
