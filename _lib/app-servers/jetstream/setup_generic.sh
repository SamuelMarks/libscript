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
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
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
DIR="${SCRIPT_DIR}"

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
  install|*)
    if [ "$JETSTREAM_INSTALL_METHOD" = "system" ]; then
      libscript_depends "pipx"
      pipx install "jetstream-pytorch==${VERSION}"
    elif [ "$JETSTREAM_INSTALL_METHOD" = "mise" ]; then
      mise install "jetstream-pytorch@${VERSION}"
    elif [ "$JETSTREAM_INSTALL_METHOD" = "asdf" ]; then
      asdf install jetstream-pytorch "${VERSION}"
    elif [ "$JETSTREAM_INSTALL_METHOD" = "pkgx" ]; then
      pkgx install "jetstream-pytorch@${VERSION}"
    elif [ "$JETSTREAM_INSTALL_METHOD" = "vfox" ]; then
      vfox add jetstream-pytorch || true
      vfox install "jetstream-pytorch@${VERSION}"
    else
      # libscript_native implementation
      resolve_exact_version
      libscript_depends 'python'
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/jetstream/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing Jetstream ${VERSION} to ${TARGET_DIR}..."
        python -m venv "${TARGET_DIR}"
        if [ "$VERSION" = "latest" ]; then
          if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/jetstream/"*"${VERSION}"* >/dev/null 2>&1; then
          "${TARGET_DIR}/bin/pip" install --upgrade jetstream-pytorch --no-index --find-links="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/jetstream/"
        else
          "${TARGET_DIR}/bin/pip" install --upgrade jetstream-pytorch
        fi
        else
          if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/jetstream/"*"${VERSION}"* >/dev/null 2>&1; then
          "${TARGET_DIR}/bin/pip" install "jetstream-pytorch==${VERSION}" --no-index --find-links="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/jetstream/"
        else
          "${TARGET_DIR}/bin/pip" install "jetstream-pytorch==${VERSION}"
        fi
        fi
      else
        log_info "Jetstream ${VERSION} is already installed."
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
