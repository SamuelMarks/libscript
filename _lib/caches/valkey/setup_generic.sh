#!/bin/sh
# ## Overview
# Generic setup module for valkey with reuse-else-create semantics.
# 
# ## Usage
# Execute this script to perform generic initialization steps for valkey.

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

VALKEY_INSTALL_METHOD="$(libscript_resolve_install_method "VALKEY")"
ACTION="${ACTION:-install}"
VERSION="${VALKEY_VERSION:-latest}"

# ## find_existing_valkey
# Checks LIBSCRIPT_HOME and system PATH for an existing valkey-server or redis-server installation.
find_existing_valkey() {
  for _fev_cand in \
    "${LIBSCRIPT_HOME:-$HOME/.libscript}/valkey/${VERSION}/bin/valkey-server" \
    "${LIBSCRIPT_HOME:-$HOME/.libscript}/valkey/default/bin/valkey-server" \
    "$(command -v valkey-server 2>/dev/null || true)" \
    "$(command -v redis-server 2>/dev/null || true)"; do
    if [ -n "$_fev_cand" ] && [ -x "$_fev_cand" ]; then
      printf '%s\n' "$_fev_cand"
      return 0
    fi
  done
  return 1
}

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${FORCE_REINSTALL:-0}" != "1" ] && find_existing_valkey >/dev/null 2>&1; then
    EXACT_VERSION="${VERSION:-latest}"
    return 0
  fi
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote valkey 2>/dev/null | tail -n 1)
    if [ -n "$_latest" ] && [ "$_latest" != "No versions found" ] && [ "$_latest" != "ls-remote not fully implemented natively yet." ]; then
      EXACT_VERSION="$_latest"
    else
      EXACT_VERSION="${VERSION:-latest}"
    fi
  else
    EXACT_VERSION="${VERSION:-latest}"
  fi
}

# ## resolve_valkey_service_name
# Resolves the active OS-native or LibScript service unit name for Valkey/Redis.
resolve_valkey_service_name() {
  if [ -n "${LIBSCRIPT_SERVICE_NAME:-}" ]; then
    printf '%s\n' "$LIBSCRIPT_SERVICE_NAME"
    return 0
  fi
  for _rvsn_cand in valkey-server valkey redis-server redis; do
    if [ -f "/lib/systemd/system/${_rvsn_cand}.service" ] || [ -f "/etc/systemd/system/${_rvsn_cand}.service" ] || [ -x "/etc/init.d/${_rvsn_cand}" ]; then
      printf '%s\n' "$_rvsn_cand"
      return 0
    fi
  done
  printf '%s\n' "libscript_${PACKAGE_NAME:-valkey}"
}

if [ -z "${VALKEY_DOWNLOAD_URL:-}" ]; then
  case "$TARGET_OS" in
    windows|mingw|cygwin)
      _tmp_ver="${VERSION:-latest}"
      if [ "$_tmp_ver" = "latest" ] || [ "$_tmp_ver" = "lts" ] || [ "$_tmp_ver" = "stable" ]; then
        _tmp_ver=$(git ls-remote --tags "https://github.com/SamuelMarks/valkey-windows" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | tail -n 1 || true)
        if [ -z "$_tmp_ver" ]; then
          _tmp_ver='latest'
        fi
      fi
      if [ "$_tmp_ver" != "latest" ]; then
        VALKEY_DOWNLOAD_URL="https://github.com/SamuelMarks/valkey-windows/releases/download/${_tmp_ver}/Valkey-${_tmp_ver}-win64.zip"
      fi
      ;;
  esac
fi

case "$ACTION" in
  ls)
    libscript_handle_generic_action "valkey" "$ACTION" "$VERSION" "${VALKEY_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${VALKEY_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${VALKEY_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
      case "$TARGET_OS" in
        windows|mingw|cygwin)
          git ls-remote --tags "https://github.com/SamuelMarks/valkey-windows" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
          ;;
        *)
          git ls-remote --tags "https://github.com/valkey-io/valkey" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
          ;;
      esac
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "valkey" "$ACTION" "$VERSION" "${VALKEY_INSTALL_METHOD}"
    ;;
  download)
    if [ "$VALKEY_INSTALL_METHOD" = "libscript_native" ]; then
      if [ "${FORCE_REINSTALL:-0}" != "1" ] && find_existing_valkey >/dev/null 2>&1; then
        log_info '[REUSE] valkey is already installed; skipping download.'
        exit 0
      fi
      log_info "Downloading valkey ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/valkey..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/valkey"
      if [ -n "${VALKEY_DOWNLOAD_URL:-}" ]; then
        libscript_download "${VALKEY_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/valkey/valkey-${VERSION}.tar.gz"
      else
        log_warn "VALKEY_DOWNLOAD_URL is not defined for valkey ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$VALKEY_INSTALL_METHOD" = "from-source" ]; then
      EXACT_VERSION="${VERSION:-8.0.1}"
      [ "${EXACT_VERSION}" = "latest" ] && EXACT_VERSION="8.0.1"
      libscript_build_component_from_source "valkey" "${EXACT_VERSION}" "valkey-server" "c" "make" "${VALKEY_DOWNLOAD_URL:-}"
      exit 0
    fi
    if [ "${FORCE_REINSTALL:-0}" != "1" ] && _existing_vk=$(find_existing_valkey 2>/dev/null); then
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/valkey/${EXACT_VERSION}"
      mkdir -p "${TARGET_DIR}/bin"
      if [ "$_existing_vk" != "${TARGET_DIR}/bin/valkey-server" ]; then
        ln -sf "$_existing_vk" "${TARGET_DIR}/bin/valkey-server" 2>/dev/null || true
      fi
      if command -v valkey-cli >/dev/null 2>&1; then
        ln -sf "$(command -v valkey-cli)" "${TARGET_DIR}/bin/valkey-cli" 2>/dev/null || true
      elif command -v redis-cli >/dev/null 2>&1; then
        ln -sf "$(command -v redis-cli)" "${TARGET_DIR}/bin/valkey-cli" 2>/dev/null || true
      fi
      libscript_symlink_alias "valkey" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "valkey" "default" "${EXACT_VERSION}"
      log_info "[REUSE] valkey (${VERSION}) is already installed at ${_existing_vk}."
      exit 0
    fi
    if [ "$VALKEY_INSTALL_METHOD" = "system" ]; then
      libscript_depends "valkey" || libscript_depends "redis"
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/valkey/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing valkey ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/valkey/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info 'Extracting from cache...'
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/valkey/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/valkey" || true
              chmod +x "${TARGET_DIR}/bin/valkey" || true
            fi
          fi
        else
          if [ -n "${VALKEY_DOWNLOAD_URL:-}" ]; then
            TEMP_FILE=$(mktemp)
            libscript_download "${VALKEY_DOWNLOAD_URL:-}" "${TEMP_FILE}"
            if case "${VALKEY_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "${VALKEY_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
              unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
            else
              cp "${TEMP_FILE}" "${TARGET_DIR}/bin/valkey" || true
              chmod +x "${TARGET_DIR}/bin/valkey" || true
            fi
            rm -f "${TEMP_FILE}"
          else
            if [ "$UNAME_LOWER" = "linux" ] || [ "$UNAME_LOWER" = "freebsd" ] && [ -n "${PKG_MGR:-}" ]; then
              log_info 'Falling back to system package manager for valkey...'
              libscript_depends "valkey" || libscript_depends "redis"
              if command -v valkey-server >/dev/null 2>&1; then
                ln -sf "$(command -v valkey-server)" "${TARGET_DIR}/bin/valkey-server"
                ln -sf "$(command -v valkey-cli)" "${TARGET_DIR}/bin/valkey-cli" 2>/dev/null || true
              elif command -v redis-server >/dev/null 2>&1; then
                ln -sf "$(command -v redis-server)" "${TARGET_DIR}/bin/valkey-server"
                ln -sf "$(command -v redis-cli)" "${TARGET_DIR}/bin/valkey-cli" 2>/dev/null || true
              fi
            else
              log_warn "No download URL provided for valkey ${VERSION}."
            fi
          fi
        fi
      else
        log_info "valkey ${VERSION} is already installed."
      fi
      libscript_symlink_alias "valkey" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "valkey" "$ACTION" "$VERSION" "${VALKEY_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
