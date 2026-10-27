#!/bin/sh
# ## Overview
# Generic setup module for conda.
# 
# ## Usage
# Execute this script to perform generic initialization steps for conda.

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

CONDA_INSTALL_METHOD="$(libscript_resolve_install_method "CONDA")"
ACTION="${ACTION:-install}"
VERSION="${CONDA_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote conda 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "conda" "$ACTION" "$VERSION" "${CONDA_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${CONDA_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${CONDA_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/conda/conda" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "conda" "$ACTION" "$VERSION" "${CONDA_INSTALL_METHOD}"
    ;;
  download)
    if [ "$CONDA_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading conda ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/conda..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/conda"
      if [ -n "${CONDA_DOWNLOAD_URL:-}" ]; then
        libscript_download "${CONDA_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/conda/conda-${VERSION}.tar.gz"
      else
        log_warn "CONDA_DOWNLOAD_URL is not defined for conda ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$CONDA_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'conda'
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/conda/${EXACT_VERSION}"
      if [ ! -x "${TARGET_DIR}/bin/conda" ]; then
        log_info "Installing conda ${VERSION} natively to ${TARGET_DIR}..."
        if [ -f /etc/alpine-release ]; then
          log_info 'Package is not supported on Alpine Linux (musl).'
          mkdir -p "${TARGET_DIR}/bin"
          echo '#!/bin/sh' > "${TARGET_DIR}/bin/conda"
          echo 'echo "Conda is not supported on Alpine Linux (musl)."' >> "${TARGET_DIR}/bin/conda"
          chmod +x "${TARGET_DIR}/bin/conda"
        else
          ARCH=$(uname -m)
          if [ "$ARCH" = "x86_64" ]; then MINICONDA_ARCH="x86_64"; elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then MINICONDA_ARCH="aarch64"; else MINICONDA_ARCH="x86_64"; fi
          if [ "$UNAME_LOWER" = "darwin" ]; then
            if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then MINICONDA_ARCH="arm64"; else MINICONDA_ARCH="x86_64"; fi
            URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-${MINICONDA_ARCH}.sh"
          else
            URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-${MINICONDA_ARCH}.sh"
          fi
          TEMP_FILE=$(mktemp --suffix=.sh 2>/dev/null || mktemp /tmp/miniconda_XXXXXX.sh)
          libscript_depends 'curl'
          if ! libscript_download "$URL" "$TEMP_FILE"; then
            log_error "Failed to download conda from $URL"
            rm -f "$TEMP_FILE"
            exit 1
          fi
          sh "$TEMP_FILE" -b -u -p "${TARGET_DIR}" 2>/dev/null || (chmod +x "$TEMP_FILE" && "$TEMP_FILE" -b -u -p "${TARGET_DIR}") || true
          rm -f "$TEMP_FILE"
        fi
      else
        log_info "conda ${VERSION} is already installed."
      fi
      libscript_symlink_alias "conda" "latest" "${EXACT_VERSION}"
      libscript_symlink_alias "conda" "default" "${EXACT_VERSION}"
      if [ "$VERSION" != "latest" ] && [ "$VERSION" != "default" ]; then
        libscript_symlink_alias "conda" "$VERSION" "${EXACT_VERSION}"
      fi
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "conda" "$ACTION" "$VERSION" "${CONDA_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
