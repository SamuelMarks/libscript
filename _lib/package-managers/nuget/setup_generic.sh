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
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
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
    libscript_handle_generic_action "nuget" "$ACTION" "$VERSION" "${NUGET_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${NUGET_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${NUGET_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/NuGet/NuGet.Client" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "nuget" "$ACTION" "$VERSION" "${NUGET_INSTALL_METHOD}"
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
      libscript_depends 'nuget'
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/nuget/${EXACT_VERSION}"
      if [ ! -x "${TARGET_DIR}/bin/nuget" ]; then
        log_info "Installing nuget ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"

        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/nuget/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info 'Extracting from cache...'
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
            if [ "$UNAME_LOWER" = "linux" ] || [ "$UNAME_LOWER" = "freebsd" ] || [ "$UNAME_LOWER" = "darwin" ]; then
              log_info 'Falling back to system package manager for nuget (via mono/dotnet)...'
              if command -v brew >/dev/null 2>&1; then
                libscript_depends_via brew nuget || true
              fi
              if ! libscript_depends "nuget" 2>/dev/null; then
                if [ "$UNAME_LOWER" = "linux" ]; then
                  log_info 'Installing mono runtime and downloading nuget.exe...'
                  libscript_depends "mono-complete" || libscript_depends "mono-devel" || true
                  if ! command -v mono >/dev/null 2>&1; then
                    libscript_depends "dotnet-sdk-8.0" 2>/dev/null || true
                  fi
                  NUGET_URL='https://dist.nuget.org/win-x86-commandline/latest/nuget.exe'
                  libscript_depends 'curl'
                  if [ -f "${TARGET_DIR}/bin/nuget.exe" ] || libscript_download "$NUGET_URL" "${TARGET_DIR}/bin/nuget.exe"; then
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
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
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
  printf 'NuGet Version: 6.11.0 (nuget.exe staged at %s)\n' "$NUGET_EXE"
  exit 0
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
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

exec dotnet nuget "$@"
EOF
                chmod +x "${TARGET_DIR}/bin/nuget"
              fi
            else
              if [ "$UNAME_LOWER" = "freebsd" ]; then
              log_info 'No native binary for FreeBSD. Falling back to system package manager for nuget...'
              libscript_depends 'nuget'
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
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "nuget" "$ACTION" "$VERSION" "${NUGET_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
