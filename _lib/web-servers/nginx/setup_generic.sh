#!/bin/sh
# ## Overview
# Generic setup script for the nginx component with reuse-else-create semantics.
#
# ## Usage
# This script is typically called internally by the component lifecycle.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/versioning.sh" "_lib/_common/source_builder.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  . "${SCRIPT_NAME}"
done

NGINX_INSTALL_METHOD="${NGINX_INSTALL_METHOD:-system}"
NGINX_INSTALL_METHOD="$(LIBSCRIPT_DEFAULT_INSTALL_METHOD="$NGINX_INSTALL_METHOD" libscript_resolve_install_method "NGINX")"
NGINX_VERSION="${NGINX_VERSION:-latest}"
ACTION="${ACTION:-install}"

# ## find_existing_nginx
# Checks LIBSCRIPT_HOME, /usr/sbin/nginx, and system PATH for an existing nginx binary.
find_existing_nginx() {
  for _fen_cand in \
    "${LIBSCRIPT_HOME:-$HOME/.libscript}/nginx/${NGINX_VERSION}/bin/nginx" \
    "/usr/sbin/nginx" \
    "/usr/local/bin/nginx" \
    "$(command -v nginx 2>/dev/null || true)"; do
    if [ -n "$_fen_cand" ] && [ -x "$_fen_cand" ]; then
      printf '%s\n' "$_fen_cand"
      return 0
    fi
  done
  return 1
}

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${NGINX_VERSION}" = "latest" ] || [ "${NGINX_VERSION}" = "lts" ]; then
    EXACT_VERSION="1.25.4"
    if [ -z "$EXACT_VERSION" ]; then
      EXACT_VERSION="latest"
    fi
  else
    EXACT_VERSION="${NGINX_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "${NGINX_INSTALL_METHOD}" = "mise" ]; then
      mise ls nginx
    elif [ "${NGINX_INSTALL_METHOD}" = "asdf" ]; then
      asdf list nginx
    elif [ "${NGINX_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "${NGINX_INSTALL_METHOD}" = "vfox" ]; then
      vfox ls nginx
    elif [ "${NGINX_INSTALL_METHOD}" = "system" ]; then
      nginx --version || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/nginx/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "${NGINX_INSTALL_METHOD}" = "mise" ]; then
      mise ls-remote nginx
    elif [ "${NGINX_INSTALL_METHOD}" = "asdf" ]; then
      asdf list all nginx
    elif [ "${NGINX_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "${NGINX_INSTALL_METHOD}" = "vfox" ]; then
      vfox ls all nginx
    elif [ "${NGINX_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      printf '%s\n' "Fetching remote versions not implemented generically for nginx"
    fi
    exit 0
    ;;
  use)
    if [ "${NGINX_INSTALL_METHOD}" = "mise" ]; then
      mise use "nginx@${NGINX_VERSION}"
    elif [ "${NGINX_INSTALL_METHOD}" = "asdf" ]; then
      asdf global nginx "${NGINX_VERSION}"
    elif [ "${NGINX_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "${NGINX_INSTALL_METHOD}" = "vfox" ]; then
      vfox use "nginx@${NGINX_VERSION}"
    elif [ "${NGINX_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "nginx" "${NGINX_VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias "nginx" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/nginx/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "nginx ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "nginx" "default" "${EXACT_VERSION}"
      log_info "Set default nginx version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  . \"${DIR}/env.sh\" # or: . \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env nginx \"${NGINX_VERSION}\")"
    fi
    exit 0
    ;;
  download)
    if [ "$NGINX_INSTALL_METHOD" = "libscript_native" ]; then
      if [ "${FORCE_REINSTALL:-0}" != "1" ] && find_existing_nginx >/dev/null 2>&1; then
        log_info "[REUSE] nginx is already installed; skipping download."
        exit 0
      fi
      log_info "Downloading nginx ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/nginx..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/nginx"
      if [ -n "${NGINX_DOWNLOAD_URL:-}" ]; then
        libscript_download "${NGINX_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/nginx/nginx-${VERSION}.tar.gz"
      else
        log_warn "NGINX_DOWNLOAD_URL is not defined for nginx ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "${NGINX_INSTALL_METHOD}" = "from-source" ]; then
      resolve_exact_version
      libscript_build_component_from_source "nginx" "${EXACT_VERSION}" "nginx" "c" "autotools" "${NGINX_DOWNLOAD_URL:-}"
      exit 0
    fi
    if [ "${FORCE_REINSTALL:-0}" != "1" ] && _existing_nx=$(find_existing_nginx 2>/dev/null); then
      log_info "[REUSE] nginx is already installed at ${_existing_nx}."
      exit 0
    fi

    if [ "${NGINX_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'nginx'
    elif [ "${NGINX_INSTALL_METHOD}" = "mise" ]; then
      mise install "nginx@${NGINX_VERSION}"
    elif [ "${NGINX_INSTALL_METHOD}" = "asdf" ]; then
      asdf install nginx "${NGINX_VERSION}"
    elif [ "${NGINX_INSTALL_METHOD}" = "pkgx" ]; then
      pkgx install "nginx@${NGINX_VERSION}"
    elif [ "${NGINX_INSTALL_METHOD}" = "vfox" ]; then
      vfox add nginx || true
      vfox install "nginx@${NGINX_VERSION}"
    else
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/nginx/${EXACT_VERSION}"
      
      if [ -x "${TARGET_DIR}/bin/nginx" ]; then
        libscript_symlink_alias "nginx" "${NGINX_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      if [ "$UNAME_LOWER" = "linux" ] || [ "$UNAME_LOWER" = "freebsd" ] && [ -n "${PKG_MGR:-}" ]; then
        log_info "Falling back to system package manager for nginx..."
        libscript_depends "nginx"
      else
        log_error "Native installation for nginx from source is not supported yet."
        exit 1
      fi
      
      libscript_symlink_alias "nginx" "${NGINX_VERSION}" "${EXACT_VERSION}"

    fi
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/hw_tune.sh" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/hw_tune.sh"
      # shellcheck disable=SC1090,SC1091
      . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/hw_tune.sh"
      unset SCRIPT_NAME || true
      libscript_apply_hardware_tuning "nginx" || true
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$NGINX_INSTALL_METHOD" = "libscript_native" ] || [ "$NGINX_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-}"
      if [ -z "$service_name" ]; then
        if [ "$NGINX_INSTALL_METHOD" = "system" ] || [ -f "/lib/systemd/system/nginx.service" ] || [ -f "/etc/init.d/nginx" ]; then
          service_name="nginx"
        else
          service_name="libscript_${PACKAGE_NAME:-nginx}"
        fi
      fi
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $NGINX_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$NGINX_INSTALL_METHOD" = "libscript_native" ] || [ "$NGINX_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-nginx}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $NGINX_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$NGINX_INSTALL_METHOD" = "libscript_native" ] || [ "$NGINX_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-nginx}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $NGINX_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$NGINX_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling nginx $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/nginx/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/nginx/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $NGINX_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
