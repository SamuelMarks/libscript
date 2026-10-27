#!/bin/sh
# ## Overview
# Generic setup module for opam.
# 
# ## Usage
# Execute this script to perform generic initialization steps for opam.

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

OPAM_INSTALL_METHOD="${OPAM_INSTALL_METHOD:-system}"
OPAM_INSTALL_METHOD="$(LIBSCRIPT_DEFAULT_INSTALL_METHOD="$OPAM_INSTALL_METHOD" libscript_resolve_install_method "OPAM")"
ACTION="${ACTION:-install}"
VERSION="${OPAM_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote opam 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "opam" "$ACTION" "$VERSION" "${OPAM_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${OPAM_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${OPAM_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/ocaml/opam" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "opam" "$ACTION" "$VERSION" "${OPAM_INSTALL_METHOD}"
    ;;
  download)
    if [ "$OPAM_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading opam ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/opam..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/opam"
      if [ -n "${OPAM_DOWNLOAD_URL:-}" ]; then
        libscript_download "${OPAM_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/opam/opam-${VERSION}.tar.gz"
      else
        log_warn "OPAM_DOWNLOAD_URL is not defined for opam ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$OPAM_INSTALL_METHOD" = "system" ] && command -v dnf >/dev/null 2>&1; then
      OPAM_INSTALL_METHOD='libscript_native'
    fi
    if [ "$OPAM_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'opam'
    else
      # libscript_native implementation
      if [ -z "${OPAM_DOWNLOAD_URL:-}" ]; then
        _opam_ver='2.2.1'
        _arch="${ARCH:-$(uname -m)}"
        case "$_arch" in
          aarch64|arm64) _opam_arch="arm64" ;;
          x86_64|amd64) _opam_arch="x86_64" ;;
          *) _opam_arch="$_arch" ;;
        esac
        OPAM_DOWNLOAD_URL="https://github.com/ocaml/opam/releases/download/${_opam_ver}/opam-${_opam_ver}-${_opam_arch}-linux"
      fi
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/opam/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing opam ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/opam/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info 'Extracting from cache...'
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/opam/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/opam" || true
              chmod +x "${TARGET_DIR}/bin/opam" || true
            fi
          fi
        else
          if [ -n "${OPAM_DOWNLOAD_URL:-}" ]; then
            TEMP_FILE=$(mktemp)
            libscript_download "${OPAM_DOWNLOAD_URL:-}" "${TEMP_FILE}"
            if case "${OPAM_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "${OPAM_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
              unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
            else
              cp "${TEMP_FILE}" "${TARGET_DIR}/bin/opam" || true
              chmod +x "${TARGET_DIR}/bin/opam" || true
            fi
            rm -f "${TEMP_FILE}"
          else
            if [ "$UNAME_LOWER" = "freebsd" ] || [ "${TARGET_OS:-}" = "alpine" ] || [ -z "${OPAM_DOWNLOAD_URL:-}" ]; then
              log_info "No native binary for ${TARGET_OS:-$UNAME_LOWER}. Falling back to system package manager for opam..."
              libscript_depends 'opam'
              mkdir -p "${TARGET_DIR}/bin"
              if command -v opam >/dev/null 2>&1; then
                ln -sf "$(command -v opam)" "${TARGET_DIR}/bin/opam"
              fi
            else
              log_warn "No download URL provided for opam ${VERSION}."
            fi
          fi
        fi
      else
        log_info "opam ${VERSION} is already installed."
      fi
      libscript_symlink_alias "opam" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "opam" "$ACTION" "$VERSION" "${OPAM_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
