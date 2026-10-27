#!/bin/sh
# ## Overview
# Generic setup module for redis with reuse-else-create semantics.
# 
# ## Usage
# Execute this script to perform generic initialization steps for redis.

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

REDIS_INSTALL_METHOD="$(libscript_resolve_install_method "REDIS")"
ACTION="${ACTION:-install}"
VERSION="${REDIS_VERSION:-latest}"

# ## find_existing_redis
# Checks LIBSCRIPT_HOME and system PATH for an existing redis-server or valkey-server installation.
find_existing_redis() {
  for _fer_cand in \
    "${LIBSCRIPT_HOME:-$HOME/.libscript}/redis/${VERSION}/bin/redis-server" \
    "${LIBSCRIPT_HOME:-$HOME/.libscript}/redis/default/bin/redis-server" \
    "$(command -v redis-server 2>/dev/null || true)" \
    "$(command -v valkey-server 2>/dev/null || true)"; do
    if [ -n "$_fer_cand" ] && [ -x "$_fer_cand" ]; then
      printf '%s\n' "$_fer_cand"
      return 0
    fi
  done
  return 1
}

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${FORCE_REINSTALL:-0}" != "1" ] && find_existing_redis >/dev/null 2>&1; then
    EXACT_VERSION="${VERSION:-latest}"
    return 0
  fi
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote redis 2>/dev/null | tail -n 1)
    if [ -n "$_latest" ] && [ "$_latest" != "No versions found" ] && [ "$_latest" != "ls-remote not fully implemented natively yet." ]; then
      EXACT_VERSION="$_latest"
    else
      EXACT_VERSION="${VERSION:-latest}"
    fi
  else
    EXACT_VERSION="${VERSION:-latest}"
  fi
}

# ## resolve_redis_service_name
# Resolves the active OS-native or LibScript service unit name for Redis/Valkey.
resolve_redis_service_name() {
  if [ -n "${LIBSCRIPT_SERVICE_NAME:-}" ]; then
    printf '%s\n' "$LIBSCRIPT_SERVICE_NAME"
    return 0
  fi
  for _rrsn_cand in redis-server redis valkey-server valkey; do
    if [ -f "/lib/systemd/system/${_rrsn_cand}.service" ] || [ -f "/etc/systemd/system/${_rrsn_cand}.service" ] || [ -x "/etc/init.d/${_rrsn_cand}" ]; then
      printf '%s\n' "$_rrsn_cand"
      return 0
    fi
  done
  printf '%s\n' "libscript_${PACKAGE_NAME:-redis}"
}

if [ -z "${REDIS_DOWNLOAD_URL:-}" ]; then
  case "$TARGET_OS" in
    windows|mingw|cygwin)
      _tmp_ver="${VERSION:-latest}"
      if [ "$_tmp_ver" = "latest" ] || [ "$_tmp_ver" = "lts" ] || [ "$_tmp_ver" = "stable" ]; then
        _tmp_ver=$(git ls-remote --tags "https://github.com/SamuelMarks/redis-windows" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | tail -n 1 || true)
        if [ -z "$_tmp_ver" ]; then
          _tmp_ver='latest'
        fi
      fi
      if [ "$_tmp_ver" != "latest" ]; then
        REDIS_DOWNLOAD_URL="https://github.com/SamuelMarks/redis-windows/releases/download/${_tmp_ver}/redis-${_tmp_ver}-win64.zip"
      fi
      ;;
  esac
fi

case "$ACTION" in
  ls)
    libscript_handle_generic_action "redis" "$ACTION" "$VERSION" "${REDIS_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${REDIS_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${REDIS_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
      case "$TARGET_OS" in
        windows|mingw|cygwin)
          git ls-remote --tags "https://github.com/SamuelMarks/redis-windows" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
          ;;
        *)
          git ls-remote --tags "https://github.com/redis/redis" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
          ;;
      esac
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "redis" "$ACTION" "$VERSION" "${REDIS_INSTALL_METHOD}"
    ;;
  download)
    if [ "$REDIS_INSTALL_METHOD" = "libscript_native" ]; then
      if [ "${FORCE_REINSTALL:-0}" != "1" ] && find_existing_redis >/dev/null 2>&1; then
        log_info '[REUSE] redis is already installed; skipping download.'
        exit 0
      fi
      log_info "Downloading redis ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/redis..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/redis"
      if [ -n "${REDIS_DOWNLOAD_URL:-}" ]; then
        libscript_download "${REDIS_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/redis/redis-${VERSION}.tar.gz"
      else
        log_warn "REDIS_DOWNLOAD_URL is not defined for redis ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$REDIS_INSTALL_METHOD" = "from-source" ]; then
      EXACT_VERSION="${VERSION:-7.4.1}"
      [ "${EXACT_VERSION}" = "latest" ] && EXACT_VERSION="7.4.1"
      libscript_build_component_from_source "redis" "${EXACT_VERSION}" "redis-server" "c" "make" "${REDIS_DOWNLOAD_URL:-}"
      exit 0
    fi
    if [ "${FORCE_REINSTALL:-0}" != "1" ] && _existing_rd=$(find_existing_redis 2>/dev/null); then
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/redis/${EXACT_VERSION}"
      mkdir -p "${TARGET_DIR}/bin"
      if [ "$_existing_rd" != "${TARGET_DIR}/bin/redis-server" ]; then
        ln -sf "$_existing_rd" "${TARGET_DIR}/bin/redis-server" 2>/dev/null || true
      fi
      if command -v redis-cli >/dev/null 2>&1; then
        ln -sf "$(command -v redis-cli)" "${TARGET_DIR}/bin/redis-cli" 2>/dev/null || true
      elif command -v valkey-cli >/dev/null 2>&1; then
        ln -sf "$(command -v valkey-cli)" "${TARGET_DIR}/bin/redis-cli" 2>/dev/null || true
      fi
      libscript_symlink_alias "redis" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "redis" "default" "${EXACT_VERSION}"
      log_info "[REUSE] redis (${VERSION}) is already installed at ${_existing_rd}."
      exit 0
    fi
    if [ "$REDIS_INSTALL_METHOD" = "system" ]; then
      libscript_depends "redis" || libscript_depends "valkey"
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/redis/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing redis ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/redis/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info 'Extracting from cache...'
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/redis/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/redis" || true
              chmod +x "${TARGET_DIR}/bin/redis" || true
            fi
          fi
        else
          if [ -n "${REDIS_DOWNLOAD_URL:-}" ]; then
            TEMP_FILE=$(mktemp)
            libscript_download "${REDIS_DOWNLOAD_URL:-}" "${TEMP_FILE}"
            if case "${REDIS_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "${REDIS_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
              unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
            else
              cp "${TEMP_FILE}" "${TARGET_DIR}/bin/redis" || true
              chmod +x "${TARGET_DIR}/bin/redis" || true
            fi
            rm -f "${TEMP_FILE}"
          else
            if [ "$UNAME_LOWER" = "linux" ] || [ "$UNAME_LOWER" = "freebsd" ] && [ -n "${PKG_MGR:-}" ]; then
              log_info 'Falling back to system package manager for redis...'
              libscript_depends "redis" || libscript_depends "valkey"
              if command -v redis-server >/dev/null 2>&1; then
                ln -sf "$(command -v redis-server)" "${TARGET_DIR}/bin/redis-server"
                ln -sf "$(command -v redis-cli)" "${TARGET_DIR}/bin/redis-cli" 2>/dev/null || true
              elif command -v valkey-server >/dev/null 2>&1; then
                ln -sf "$(command -v valkey-server)" "${TARGET_DIR}/bin/redis-server"
                ln -sf "$(command -v valkey-cli)" "${TARGET_DIR}/bin/redis-cli" 2>/dev/null || true
              fi
            else
              log_warn "No download URL provided for redis ${VERSION}."
            fi
          fi
        fi
      else
        log_info "redis ${VERSION} is already installed."
      fi
      libscript_symlink_alias "redis" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "redis" "$ACTION" "$VERSION" "${REDIS_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
