#!/bin/sh
# ## Overview
# Generic setup module for postgres.
# 
# ## Usage
# Execute this script to perform generic initialization steps for postgres.

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

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh" "_lib/_common/versioning.sh" "_lib/_common/source_builder.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

POSTGRES_INSTALL_METHOD="$(libscript_resolve_install_method "POSTGRES")"
ACTION="${ACTION:-install}"
VERSION="${POSTGRES_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote postgres 2>/dev/null | tail -n 1)
    if [ -n "$_latest" ] && [ "$_latest" != "No versions found" ] && [ "$_latest" != "ls-remote not fully implemented natively yet." ]; then
      EXACT_VERSION="$_latest"
    else
      EXACT_VERSION="${VERSION:-latest}"
    fi
  else
    EXACT_VERSION="${VERSION:-latest}"
  fi
}

# ## libscript_postgres_is_ready
# Checks whether a PostgreSQL client/server installation or active cluster is already present on the host.
libscript_postgres_is_ready() {
  _pg_port="${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-5432}}"
  if command -v pg_isready >/dev/null 2>&1 && pg_isready -h 127.0.0.1 -p "${_pg_port}" -q 2>/dev/null; then
    return 0
  fi
  if command -v pg_isready >/dev/null 2>&1 && pg_isready -q 2>/dev/null; then
    return 0
  fi
  if command -v psql >/dev/null 2>&1 && { command -v postgres >/dev/null 2>&1 || [ -d "/etc/postgresql" ] || [ -d "/var/lib/postgresql" ]; }; then
    return 0
  fi
  return 1
}

case "$ACTION" in
  ls)
    libscript_handle_generic_action "postgres" "$ACTION" "$VERSION" "${POSTGRES_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${POSTGRES_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${POSTGRES_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/postgres/postgres" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "postgres" "$ACTION" "$VERSION" "${POSTGRES_INSTALL_METHOD}"
    ;;
  download)
    if [ "$POSTGRES_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading postgres ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/postgres..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/postgres"
      if [ -n "${POSTGRES_DOWNLOAD_URL:-}" ]; then
        libscript_download "${POSTGRES_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/postgres/postgres-${VERSION}.tar.gz"
      else
        log_warn "POSTGRES_DOWNLOAD_URL is not defined for postgres ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$POSTGRES_INSTALL_METHOD" = "from-source" ]; then
      EXACT_VERSION="${VERSION:-17.0}"
      [ "${EXACT_VERSION}" = "latest" ] && EXACT_VERSION="17.0"
      libscript_build_component_from_source "postgres" "${EXACT_VERSION}" "postgres" "c" "autotools" "${POSTGRES_DOWNLOAD_URL:-}"
      exit 0
    fi
    if [ "${FORCE_REINSTALL:-0}" != "1" ] && { [ "$POSTGRES_INSTALL_METHOD" = "libscript_native" ] || [ "$POSTGRES_INSTALL_METHOD" = "system" ]; } && libscript_postgres_is_ready; then
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/postgres/${EXACT_VERSION}"
      mkdir -p "${TARGET_DIR}/bin"
      if command -v psql >/dev/null 2>&1; then
        ln -sf "$(command -v psql)" "${TARGET_DIR}/bin/psql" 2>/dev/null || true
      fi
      if command -v postgres >/dev/null 2>&1; then
        ln -sf "$(command -v postgres)" "${TARGET_DIR}/bin/postgres" 2>/dev/null || true
      fi
      libscript_symlink_alias "postgres" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "postgres" "default" "${EXACT_VERSION}"
      log_info "[REUSE] PostgreSQL (${VERSION}) is already installed and ready."
      exit 0
    fi
    if [ "$POSTGRES_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'postgres'
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/postgres/${EXACT_VERSION}"
      if [ ! -x "${TARGET_DIR}/bin/psql" ]; then
        log_info "Installing postgres ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/postgres/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info 'Extracting from cache...'
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/postgres/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/postgres" || true
              chmod +x "${TARGET_DIR}/bin/postgres" || true
            fi
          fi
        else
          if [ -n "${POSTGRES_DOWNLOAD_URL:-}" ]; then
            TEMP_FILE=$(mktemp)
            libscript_download "${POSTGRES_DOWNLOAD_URL:-}" "${TEMP_FILE}"
            if case "${POSTGRES_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "${POSTGRES_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
              unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
            else
              cp "${TEMP_FILE}" "${TARGET_DIR}/bin/postgres" || true
              chmod +x "${TARGET_DIR}/bin/postgres" || true
            fi
            rm -f "${TEMP_FILE}"
          else
            if { [ "$UNAME_LOWER" = "linux" ] || [ "$UNAME_LOWER" = "freebsd" ] || [ "$UNAME_LOWER" = "sunos" ]; } && [ -n "${PKG_MGR:-}" ]; then
              log_info 'Falling back to system package manager for postgres...'
              libscript_depends 'postgres'
              export PATH="/opt/ooce/bin:/opt/ooce/pgsql-17/bin:/opt/ooce/pgsql-18/bin:/usr/local/bin:${PATH}"
              if command -v psql >/dev/null 2>&1; then
                ln -sf "$(command -v psql)" "${TARGET_DIR}/bin/psql" 2>/dev/null || true
                ln -sf "$(command -v postgres)" "${TARGET_DIR}/bin/postgres" 2>/dev/null || true
              fi
            else
              log_warn "No download URL provided for postgres ${VERSION}."
            fi
          fi
        fi
      else
        log_info "postgres ${VERSION} is already installed."
      fi
      libscript_symlink_alias "postgres" "$VERSION" "${EXACT_VERSION}"
    fi
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/hw_tune.sh" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/hw_tune.sh"
      # shellcheck disable=SC1090,SC1091
      . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/hw_tune.sh"
      unset SCRIPT_NAME || true
      libscript_apply_hardware_tuning "postgres" || true
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "postgres" "$ACTION" "$VERSION" "${POSTGRES_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
