#!/bin/sh
# ## Overview
# Generic setup module for nuget.
# 
# ## Usage
# Execute this script to perform generic initialization steps for nuget.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
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
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf "%s\n" "$d")}"
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

NUGET_INSTALL_METHOD="$(libscript_resolve_install_method "NUGET")"
ACTION="${ACTION:-install}"
VERSION="${NUGET_VERSION:-latest}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote nuget 2>/dev/null | tail -n 1)
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
    if [ "$NUGET_INSTALL_METHOD" = "mise" ]; then
      mise ls nuget || true
    elif [ "$NUGET_INSTALL_METHOD" = "asdf" ]; then
      asdf list nuget || true
    elif [ "$NUGET_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$NUGET_INSTALL_METHOD" = "vfox" ]; then
      vfox ls nuget || true
    elif [ "$NUGET_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/nuget/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$NUGET_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote nuget || true
    elif [ "$NUGET_INSTALL_METHOD" = "asdf" ]; then
      asdf list all nuget || true
    elif [ "$NUGET_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$NUGET_INSTALL_METHOD" = "vfox" ]; then
      vfox ls all nuget || true
    else
      if [ -n "${NUGET_RELEASES_URL:-}" ]; then
        curl -sSL "${NUGET_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
      else
      git ls-remote --tags "https://github.com/libscript/nuget" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
    fi
    fi
    exit 0
    ;;
  use)
    if [ "$NUGET_INSTALL_METHOD" = "mise" ]; then
      mise use "nuget@${VERSION}"
    elif [ "$NUGET_INSTALL_METHOD" = "asdf" ]; then
      asdf global nuget "${VERSION}"
    elif [ "$NUGET_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "$NUGET_INSTALL_METHOD" = "vfox" ]; then
      vfox use "nuget@${VERSION}"
    elif [ "$NUGET_INSTALL_METHOD" = "vfox" ]; then
      vfox use "nuget@${VERSION}"
    elif [ "$NUGET_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "nuget" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "nuget" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/nuget/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "nuget ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "nuget" "default" "${EXACT_VERSION}"
      log_info "Set default nuget version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  . \"${DIR}/env.sh\" # or: . \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env nuget \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$NUGET_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading nuget ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/nuget..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/nuget"
      if [ -n "${NUGET_DOWNLOAD_URL:-}" ]; then
        libscript_download "${NUGET_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/nuget/nuget-${VERSION}.tar.gz"
      else
        log_warn "NUGET_DOWNLOAD_URL is not defined for nuget ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$NUGET_INSTALL_METHOD" = "system" ]; then
      libscript_depends "nuget"
    elif [ "$NUGET_INSTALL_METHOD" = "mise" ]; then
      mise install "nuget@${VERSION}"
    elif [ "$NUGET_INSTALL_METHOD" = "asdf" ]; then
      asdf install nuget "${VERSION}"
    elif [ "$NUGET_INSTALL_METHOD" = "pkgx" ]; then
      pkgx install "nuget@${VERSION}"
    elif [ "$NUGET_INSTALL_METHOD" = "vfox" ]; then
      vfox add nuget || true
      vfox install "nuget@${VERSION}"
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/nuget/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing nuget ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"

        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/nuget/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info "Extracting from cache..."
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/nuget/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/nuget" || true
              chmod +x "${TARGET_DIR}/bin/nuget" || true
            fi
          fi
        else
          if [ -n "${NUGET_DOWNLOAD_URL:-}" ]; then
            TEMP_FILE=$(mktemp)
            libscript_download "${NUGET_DOWNLOAD_URL:-}" "${TEMP_FILE}"
            if case "${NUGET_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "${NUGET_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
              unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
            else
              cp "${TEMP_FILE}" "${TARGET_DIR}/bin/nuget" || true
              chmod +x "${TARGET_DIR}/bin/nuget" || true
            fi
            rm -f "${TEMP_FILE}"
          else
            if [ "$UNAME_LOWER" = "linux" ] || [ "$UNAME_LOWER" = "freebsd" ] && [ -n "${PKG_MGR:-}" ]; then
              log_info "Falling back to system package manager for nuget (via mono/dotnet)..."
              if ! libscript_depends "nuget" 2>/dev/null; then
                if [ "$UNAME_LOWER" = "linux" ]; then
                  log_info "Installing mono runtime and downloading nuget.exe..."
                  libscript_depends "mono-complete" || libscript_depends "mono-devel" || true
                  if ! command -v mono >/dev/null 2>&1; then
                    if command -v dnf >/dev/null 2>&1; then
                      priv dnf install -y dotnet-sdk-8.0 || true
                    elif command -v apt-get >/dev/null 2>&1; then
                      priv apt-get install -y dotnet-sdk-8.0 2>/dev/null || true
                    fi
                  fi
                  NUGET_URL="https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
                  libscript_depends "curl"
                  if [ -f "${TARGET_DIR}/bin/nuget.exe" ] || curl -sSLf "$NUGET_URL" -o "${TARGET_DIR}/bin/nuget.exe"; then
                    cat <<'EOF' > "${TARGET_DIR}/bin/nuget"
#!/bin/sh
# ## Overview
# Executable wrapper for nuget.
#
# ## Usage
# nuget "$@"

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

BIN_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
NUGET_EXE="${BIN_DIR}/nuget.exe"
if command -v mono >/dev/null 2>&1 && [ -f "$NUGET_EXE" ]; then
  exec mono "$NUGET_EXE" "$@"
elif command -v dotnet >/dev/null 2>&1; then
  if [ "${1:-}" = "help" ]; then
    shift
    exec dotnet nuget --help "$@"
  else
    exec dotnet nuget "$@"
  fi
else
  exec "$NUGET_EXE" "$@"
fi
EOF
                    chmod +x "${TARGET_DIR}/bin/nuget" "${TARGET_DIR}/bin/nuget.exe"
                  fi
                fi
              fi
              if command -v nuget >/dev/null 2>&1 && [ ! -f "${TARGET_DIR}/bin/nuget" ]; then
                ln -sf "$(command -v nuget)" "${TARGET_DIR}/bin/nuget"
              elif command -v dotnet >/dev/null 2>&1 && [ ! -f "${TARGET_DIR}/bin/nuget" ]; then
                # dotnet provides nuget functionality usually, but as a test hack we'll create a wrapper
                cat <<'EOF' > "${TARGET_DIR}/bin/nuget"
#!/bin/sh
# ## Overview
# Executable wrapper for dotnet nuget.
#
# ## Usage
# nuget "$@"

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

exec dotnet nuget "$@"
EOF
                chmod +x "${TARGET_DIR}/bin/nuget"
              fi
            else
              if [ "$UNAME_LOWER" = "freebsd" ]; then
              log_info "No native binary for FreeBSD. Falling back to system package manager for nuget..."
              libscript_depends "nuget"
            else
              log_warn "No download URL provided for nuget ${VERSION}."
            fi
            fi
          fi
        fi
      else
        log_info "nuget ${VERSION} is already installed."
      fi
      libscript_symlink_alias "nuget" "latest" "${EXACT_VERSION}"
      libscript_symlink_alias "nuget" "default" "${EXACT_VERSION}"
      if [ "$VERSION" != "latest" ] && [ "$VERSION" != "default" ]; then
        libscript_symlink_alias "nuget" "$VERSION" "${EXACT_VERSION}"
      fi
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$NUGET_INSTALL_METHOD" = "libscript_native" ] || [ "$NUGET_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-nuget}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $NUGET_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$NUGET_INSTALL_METHOD" = "libscript_native" ] || [ "$NUGET_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-nuget}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $NUGET_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$NUGET_INSTALL_METHOD" = "libscript_native" ] || [ "$NUGET_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-nuget}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $NUGET_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$NUGET_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling nuget $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/nuget/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/nuget/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $NUGET_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
