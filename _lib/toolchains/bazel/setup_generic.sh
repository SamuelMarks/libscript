#!/bin/sh
# ## Overview
# Generic setup script for the bazel component.
#
# ## Usage
# This script is typically called internally by the component lifecycle.

set -feu
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
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  . "${SCRIPT_NAME}"
done

BAZEL_INSTALL_METHOD="$(libscript_resolve_install_method "BAZEL")"
BAZEL_VERSION="${BAZEL_VERSION:-latest}"
ACTION="${ACTION:-install}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${BAZEL_VERSION}" = "latest" ] || [ "${BAZEL_VERSION}" = "lts" ]; then
    EXACT_VERSION=$(curl -sL https://api.github.com/repos/bazelbuild/bazel/releases/latest | grep '"tag_name":' | head -n 1 | cut -d '"' -f 4 | sed 's/^v//')
    if [ -z "$EXACT_VERSION" ]; then
      EXACT_VERSION="latest"
    fi
  else
    EXACT_VERSION="${BAZEL_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "${BAZEL_INSTALL_METHOD}" = "mise" ]; then
      mise ls bazel
    elif [ "${BAZEL_INSTALL_METHOD}" = "asdf" ]; then
      asdf list bazel
    elif [ "${BAZEL_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "${BAZEL_INSTALL_METHOD}" = "vfox" ]; then
      vfox ls bazel
    elif [ "${BAZEL_INSTALL_METHOD}" = "system" ]; then
      bazel --version || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/bazel/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "${BAZEL_INSTALL_METHOD}" = "mise" ]; then
      mise ls-remote bazel
    elif [ "${BAZEL_INSTALL_METHOD}" = "asdf" ]; then
      asdf list all bazel
    elif [ "${BAZEL_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "${BAZEL_INSTALL_METHOD}" = "vfox" ]; then
      vfox ls all bazel
    elif [ "${BAZEL_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      printf '%s\n' "Fetching remote versions not implemented generically for bazel"
    fi
    exit 0
    ;;
  use)
    if [ "${BAZEL_INSTALL_METHOD}" = "mise" ]; then
      mise use "bazel@${BAZEL_VERSION}"
    elif [ "${BAZEL_INSTALL_METHOD}" = "asdf" ]; then
      asdf global bazel "${BAZEL_VERSION}"
    elif [ "${BAZEL_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "${BAZEL_INSTALL_METHOD}" = "vfox" ]; then
      vfox use "bazel@${BAZEL_VERSION}"
    elif [ "${BAZEL_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "bazel" "${BAZEL_VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias "bazel" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/bazel/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "bazel ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "bazel" "default" "${EXACT_VERSION}"
      log_info "Set default bazel version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env bazel \"${BAZEL_VERSION}\")"
    fi
    exit 0
    ;;
  download)
    if [ "$BAZEL_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading bazel ${VERSION:-} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/bazel..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/bazel"
      if [ -n "${BAZEL_DOWNLOAD_URL:-}" ]; then
        libscript_download "${BAZEL_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/bazel/bazel-${VERSION:-}.tar.gz"
      else
        log_warn "BAZEL_DOWNLOAD_URL is not defined for bazel ${VERSION:-}."
      fi
    fi
    exit 0
    ;;
  install)

    if [ "${BAZEL_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'bazel'
    elif [ "${BAZEL_INSTALL_METHOD}" = "mise" ]; then
      mise install "bazel@${BAZEL_VERSION}"
    elif [ "${BAZEL_INSTALL_METHOD}" = "asdf" ]; then
      asdf install bazel "${BAZEL_VERSION}"
    elif [ "${BAZEL_INSTALL_METHOD}" = "pkgx" ]; then
      pkgx install "bazel@${BAZEL_VERSION}"
    elif [ "${BAZEL_INSTALL_METHOD}" = "vfox" ]; then
      vfox add bazel || true
      vfox install "bazel@${BAZEL_VERSION}"
    else
        # libscript_native implementation
        if [ -f /etc/alpine-release ]; then
          log_info "bazel official binaries require glibc and cannot run on Alpine Linux. Skipping."
          exit 0
        fi

        resolve_exact_version
        if [ "${EXACT_VERSION}" = "latest" ]; then
           libscript_depends "curl"
           EXACT_VERSION=$(curl -sL https://api.github.com/repos/bazelbuild/bazelisk/releases/latest | grep -oE "\"tag_name\": *\"v[^\"]+\"" | sed -E "s/.*\"v([^\"]+)\".*/\1/" | head -n 1)
        fi
        TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/bazel/${EXACT_VERSION}"
        if [ ! -d "${TARGET_DIR}" ]; then
          log_info "Installing bazel ${VERSION} natively to ${TARGET_DIR}..."
          mkdir -p "${TARGET_DIR}/bin"
          ARCH=$(uname -m)
          OS=$(uname -s | tr "[:upper:]" "[:lower:]")
          if [ "$ARCH" = "x86_64" ]; then ARCH="x86_64"; elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then ARCH="arm64"; fi
          if [ "$UNAME_LOWER" = "freebsd" ]; then
            log_info "No native binary for FreeBSD. Falling back to system package manager for bazel..."
            libscript_depends "bazel"
            if command -v "bazel" >/dev/null 2>&1; then
              ln -s "$(command -v "bazel")" "${TARGET_DIR}/bin/bazel"
            fi
          else
            URL="https://github.com/bazelbuild/bazel/releases/download/${EXACT_VERSION}/bazel-${EXACT_VERSION}-${OS}-${ARCH}"
            TEMP_FILE=$(mktemp)
            libscript_depends "curl"
            if ! curl -sSLf "$URL" -o "$TEMP_FILE"; then
              log_error "Failed to download bazel from $URL"
              rm -f "$TEMP_FILE"
              exit 1
            fi
            cp "$TEMP_FILE" "${TARGET_DIR}/bin/bazel"
            chmod +x "${TARGET_DIR}/bin/bazel"
            rm -f "$TEMP_FILE"
          fi
        else
          log_info "bazel ${VERSION} is already installed."
        fi
        libscript_symlink_alias "bazel" "$VERSION" "${EXACT_VERSION}"
      fi

    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$BAZEL_INSTALL_METHOD" = "libscript_native" ] || [ "$BAZEL_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-bazel}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $BAZEL_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$BAZEL_INSTALL_METHOD" = "libscript_native" ] || [ "$BAZEL_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-bazel}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $BAZEL_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$BAZEL_INSTALL_METHOD" = "libscript_native" ] || [ "$BAZEL_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-bazel}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $BAZEL_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$BAZEL_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling bazel $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/bazel/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/bazel/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $BAZEL_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
