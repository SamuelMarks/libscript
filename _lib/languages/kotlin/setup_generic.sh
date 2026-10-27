#!/bin/sh
# ## Overview
# Generic setup module for kotlin.
# 
# ## Usage
# Execute this script to perform generic initialization steps for kotlin.

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

KOTLIN_INSTALL_METHOD="$(libscript_resolve_install_method "KOTLIN")"
ACTION="${ACTION:-install}"
VERSION="${KOTLIN_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote kotlin 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "kotlin" "$ACTION" "$VERSION" "${KOTLIN_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${KOTLIN_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${KOTLIN_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/JetBrains/kotlin" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "kotlin" "$ACTION" "$VERSION" "${KOTLIN_INSTALL_METHOD}"
    ;;
  download)
    if [ "$KOTLIN_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading kotlin ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/kotlin..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/kotlin"
      if [ -n "${KOTLIN_DOWNLOAD_URL:-}" ]; then
        libscript_download "${KOTLIN_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/kotlin/kotlin-${VERSION}.tar.gz"
      else
        log_warn "KOTLIN_DOWNLOAD_URL is not defined for kotlin ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$KOTLIN_INSTALL_METHOD" = "system" ]; then
      if ! libscript_depends "kotlin"; then
        log_info 'System package manager does not have kotlin. Falling back to native...'
        KOTLIN_INSTALL_METHOD='libscript_native'
      fi
    fi
    # libscript_native implementation
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/kotlin/${EXACT_VERSION}"
    if [ ! -d "${TARGET_DIR}" ]; then
      log_info "Installing kotlin ${VERSION} natively to ${TARGET_DIR}..."
      mkdir -p "${TARGET_DIR}/bin"
      if [ "$(uname -s)" = "FreeBSD" ]; then
        libscript_depends 'kotlin'
        if command -v kotlinc >/dev/null 2>&1; then
          ln -sf "$(command -v kotlinc)" "${TARGET_DIR}/bin/kotlinc"
          ln -sf "$(command -v kotlin)" "${TARGET_DIR}/bin/kotlin"
        fi
      elif ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/kotlin/"*"${VERSION}"* >/dev/null 2>&1; then
        log_info 'Extracting from cache...'
        cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/kotlin/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
        if [ -n "$cache_file" ]; then
          if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
            tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
          elif case "$cache_file" in *.zip) true;; *) false;; esac; then
            unzip -q "$cache_file" -d "${TARGET_DIR}" || true
          else
            cp "$cache_file" "${TARGET_DIR}/bin/kotlin" || true
            chmod +x "${TARGET_DIR}/bin/kotlin" || true
          fi
        fi
      else
        libscript_depends 'java' 'unzip' || true
        if [ -z "${KOTLIN_DOWNLOAD_URL:-}" ]; then
          _kver='2.1.0'
          [ "${EXACT_VERSION:-}" != "latest" ] && [ "${EXACT_VERSION:-}" != "lts" ] && [ -n "${EXACT_VERSION:-}" ] && _kver="${EXACT_VERSION}"
          KOTLIN_DOWNLOAD_URL="https://github.com/JetBrains/kotlin/releases/download/v${_kver}/kotlin-compiler-${_kver}.zip"
        fi
        if [ -n "${KOTLIN_DOWNLOAD_URL:-}" ]; then
          TEMP_FILE=$(mktemp)
          libscript_download "${KOTLIN_DOWNLOAD_URL:-}" "${TEMP_FILE}"
          if case "${KOTLIN_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
            tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
          elif case "${KOTLIN_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
            EXTRACT_DIR=$(mktemp -d)
            unzip -q "${TEMP_FILE}" -d "${EXTRACT_DIR}" || true
            top_dir=$(find "${EXTRACT_DIR}" -mindepth 1 -maxdepth 1 -type d | head -n 1)
            if [ -n "$top_dir" ]; then
              cp -R "${top_dir}/." "${TARGET_DIR}/"
            fi
            rm -rf "${EXTRACT_DIR}"
          else
            cp "${TEMP_FILE}" "${TARGET_DIR}/bin/kotlin" || true
            chmod +x "${TARGET_DIR}/bin/kotlin" || true
          fi
          rm -f "${TEMP_FILE}"
        else
          log_warn "No download URL provided for kotlin ${VERSION}."
        fi
      fi
    else
      log_info "kotlin ${VERSION} is already installed."
    fi
    libscript_symlink_alias "kotlin" "$VERSION" "${EXACT_VERSION}"
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "kotlin" "$ACTION" "$VERSION" "${KOTLIN_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
