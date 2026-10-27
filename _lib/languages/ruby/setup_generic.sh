#!/bin/sh
# ## Overview
# Generic setup module for ruby.
# 
# ## Usage
# Execute this script to perform generic initialization steps for ruby.

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

RUBY_INSTALL_METHOD='system'
ACTION="${ACTION:-install}"
VERSION="${RUBY_VERSION:-latest}"

# Parse offline and ruby options
while [ $# -gt 0 ]; do
  case "$1" in
    --offline|-o) export LIBSCRIPT_OFFLINE=1; shift ;;
    --gem-local) export GEM_OFFLINE=1; shift ;;
    *) shift ;;
  esac
done

if [ "${LIBSCRIPT_OFFLINE:-0}" = "1" ]; then
  export GEM_OFFLINE=1
  export BUNDLE_LOCAL=true
fi

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote ruby 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "ruby" "$ACTION" "$VERSION" "${RUBY_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${RUBY_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${RUBY_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/wch/r-sourceuby" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    if [ "$RUBY_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' 'System packages do not support use here.'
    else
      resolve_exact_version
      libscript_symlink_alias "ruby" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "ruby" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/ruby/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "ruby ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "ruby" "default" "${EXACT_VERSION}"
      log_info "Set default ruby version to ${EXACT_VERSION}."
      log_info 'To apply to the current shell, run:'
      log_info "  . \"${DIR}/env.sh\" # or: . \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env ruby \"${VERSION}\")"
    fi
    exit 0
    ;;
  download)
    if [ "$RUBY_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading ruby ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/ruby..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/ruby"
      if [ -n "${RUBY_DOWNLOAD_URL:-}" ]; then
        libscript_download "${RUBY_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/ruby/ruby-${VERSION}.tar.gz"
      else
        log_warn "RUBY_DOWNLOAD_URL is not defined for ruby ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$RUBY_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'ruby'
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/ruby/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing ruby ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/ruby/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info 'Extracting from cache...'
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/ruby/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/ruby" || true
              chmod +x "${TARGET_DIR}/bin/ruby" || true
            fi
          fi
        else
          if [ -n "${RUBY_DOWNLOAD_URL:-}" ]; then
            TEMP_FILE=$(mktemp)
            libscript_download "${RUBY_DOWNLOAD_URL:-}" "${TEMP_FILE}"
            if case "${RUBY_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "${RUBY_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
              unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
            else
              cp "${TEMP_FILE}" "${TARGET_DIR}/bin/ruby" || true
              chmod +x "${TARGET_DIR}/bin/ruby" || true
            fi
            rm -f "${TEMP_FILE}"
          else
            log_error "No download URL provided for ruby ${VERSION}."
            exit 1
          fi
        fi
      else
        log_info "ruby ${VERSION} is already installed."
      fi
      libscript_symlink_alias "ruby" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "ruby" "$ACTION" "$VERSION" "${RUBY_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
