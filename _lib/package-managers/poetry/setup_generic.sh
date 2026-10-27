#!/bin/sh
# ## Overview
# Generic setup module for poetry.
# 
# ## Usage
# Execute this script to perform generic initialization steps for poetry.

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

POETRY_INSTALL_METHOD="${POETRY_INSTALL_METHOD:-system}"
POETRY_INSTALL_METHOD="$(LIBSCRIPT_DEFAULT_INSTALL_METHOD="$POETRY_INSTALL_METHOD" libscript_resolve_install_method "POETRY")"
ACTION="${ACTION:-install}"
VERSION="${POETRY_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote poetry 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "poetry" "$ACTION" "$VERSION" "${POETRY_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${POETRY_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${POETRY_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/python-poetry/poetry" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "poetry" "$ACTION" "$VERSION" "${POETRY_INSTALL_METHOD}"
    ;;
  download)
    if [ "$POETRY_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading poetry ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/poetry..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/poetry"
      if [ -n "${POETRY_DOWNLOAD_URL:-}" ]; then
        libscript_download "${POETRY_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/poetry/poetry-${VERSION}.tar.gz"
      else
        log_warn "POETRY_DOWNLOAD_URL is not defined for poetry ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$POETRY_INSTALL_METHOD" = "system" ]; then
      if ! libscript_depends "poetry" 2>/dev/null; then
        log_info 'System package manager does not have poetry, falling back to standalone install...'
        POETRY_INSTALL_METHOD='libscript_native'
      fi
    fi

    if [ "$POETRY_INSTALL_METHOD" = "libscript_native" ]; then
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/poetry/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing poetry ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/poetry/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info 'Extracting from cache...'
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/poetry/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/poetry" || true
              chmod +x "${TARGET_DIR}/bin/poetry" || true
            fi
          fi
        else
          if [ "$UNAME_LOWER" = "freebsd" ]; then
            log_info 'No native binary for FreeBSD. Falling back to system package manager for poetry...'
            libscript_depends 'poetry'
          else
            libscript_depends 'python' || true
            libscript_depends 'curl' || true
            PY_BIN='python3'
            if command -v python3.12 >/dev/null 2>&1; then
              PY_BIN='python3.12'
            elif command -v python3.11 >/dev/null 2>&1; then
              PY_BIN='python3.11'
            elif ! (command -v python3 >/dev/null 2>&1 && python3 --version 2>&1 | awk '{split($2, v, "."); exit((v[1] > 3 || (v[1] == 3 && v[2] >= 10)) ? 0 : 1)}'); then
              libscript_depends 'python3.11' || true
              if command -v python3.11 >/dev/null 2>&1; then
                PY_BIN='python3.11'
              fi
            fi
          _poetry_inst=$(mktemp)
          libscript_download "https://install.python-poetry.org" "${_poetry_inst}"
          if [ "${EXACT_VERSION}" = "latest" ]; then
             if ! POETRY_HOME="${TARGET_DIR}" "$PY_BIN" "${_poetry_inst}"; then
                rm -f "${_poetry_inst}"
                log_error 'Failed to install poetry.'
                exit 1
             fi
          else
             if ! POETRY_HOME="${TARGET_DIR}" "$PY_BIN" "${_poetry_inst}" --version "$EXACT_VERSION"; then
                rm -f "${_poetry_inst}"
                log_error "Failed to install poetry version $EXACT_VERSION."
                exit 1
             fi
          fi
          rm -f "${_poetry_inst}"
        fi
        if [ -x "${TARGET_DIR}/venv/bin/poetry" ] && [ ! -x "${TARGET_DIR}/bin/poetry" ]; then
          mkdir -p "${TARGET_DIR}/bin"
          ln -sf "${TARGET_DIR}/venv/bin/poetry" "${TARGET_DIR}/bin/poetry"
        fi
        fi
      else
        log_info "poetry ${VERSION} is already installed."
        if [ -x "${TARGET_DIR}/venv/bin/poetry" ] && [ ! -x "${TARGET_DIR}/bin/poetry" ]; then
          mkdir -p "${TARGET_DIR}/bin"
          ln -sf "${TARGET_DIR}/venv/bin/poetry" "${TARGET_DIR}/bin/poetry"
        fi
      fi
      libscript_symlink_alias "poetry" "latest" "${EXACT_VERSION}"
      libscript_symlink_alias "poetry" "default" "${EXACT_VERSION}"
      if [ -n "${VERSION:-}" ] && [ "${VERSION}" != "poetry" ]; then
        libscript_symlink_alias "poetry" "$VERSION" "${EXACT_VERSION}"
      fi
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "poetry" "$ACTION" "$VERSION" "${POETRY_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
