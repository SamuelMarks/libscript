#!/bin/sh
# ## Overview
# Generic setup module for duckdb.
# 
# ## Usage
# Execute this script to perform generic initialization steps for duckdb with reuse-else-create semantics.

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

DUCKDB_INSTALL_METHOD="$(libscript_resolve_install_method "DUCKDB")"
ACTION="${ACTION:-install}"
VERSION="${DUCKDB_VERSION:-latest}"

# ## find_existing_duckdb
# Searches LIBSCRIPT_HOME and system PATH for an existing duckdb CLI binary.
find_existing_duckdb() {
  _fed_home="${LIBSCRIPT_HOME:-$HOME/.libscript}"
  for _fed_cand in \
    "${_fed_home}/duckdb/${VERSION}/bin/duckdb" \
    "${_fed_home}/duckdb/default/bin/duckdb" \
    "${REMOTE_HOME:-$HOME}/.local/bin/duckdb" \
    "${HOME}/.local/bin/duckdb" \
    "/usr/local/bin/duckdb" \
    "$(command -v duckdb 2>/dev/null || true)"; do
    if [ -n "$_fed_cand" ] && [ -x "$_fed_cand" ] && "$_fed_cand" --version >/dev/null 2>&1; then
      printf '%s\n' "$_fed_cand"
      return 0
    fi
  done
  return 1
}

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${FORCE_REINSTALL:-0}" != "1" ] && _existing_dk=$(find_existing_duckdb 2>/dev/null); then
    EXACT_VERSION="${VERSION:-latest}"
    return 0
  fi
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ] || [ -z "${VERSION:-}" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote duckdb 2>/dev/null | tail -n 1 || true)
    if [ -n "$_latest" ] && [ "$_latest" != "No versions found" ] && [ "$_latest" != "ls-remote not fully implemented natively yet." ] && printf '%s\n' "$_latest" | grep -qE '^v?[0-9]+\.[0-9]+\.[0-9]+'; then
      EXACT_VERSION="${_latest#v}"
    else
      EXACT_VERSION='1.2.1'
    fi
  else
    EXACT_VERSION="${VERSION#v}"
  fi
}

# ## resolve_duckdb_release_url
# Computes the platform-specific GitHub release download URL for the given version tag.
resolve_duckdb_release_url() {
  _rdru_ver="${1:-${EXACT_VERSION:-1.2.1}}"
  if [ "$_rdru_ver" = "latest" ] || [ -z "$_rdru_ver" ]; then
    _rdru_ver='1.2.1'
  fi
  case "$_rdru_ver" in
    v*) ;;
    *) _rdru_ver="v${_rdru_ver}" ;;
  esac
  _rdru_arch="${ARCH:-x86_64}"
  _rdru_musl=""
  if [ -f "/etc/alpine-release" ] && [ "$_rdru_arch" = "x86_64" ]; then
    _rdru_musl='-musl'
  fi
  if [ "${UNAME_LOWER:-linux}" = "darwin" ]; then
    printf 'https://github.com/duckdb/duckdb/releases/download/%s/duckdb_cli-osx-universal.zip\n' "$_rdru_ver"
  elif [ "$_rdru_arch" = "aarch64" ] || [ "$_rdru_arch" = "arm64" ]; then
    printf 'https://github.com/duckdb/duckdb/releases/download/%s/duckdb_cli-linux-arm64.zip\n' "$_rdru_ver"
  else
    printf 'https://github.com/duckdb/duckdb/releases/download/%s/duckdb_cli-linux-amd64%s.zip\n' "$_rdru_ver" "$_rdru_musl"
  fi
}

# ## purge_stale_duckdb_cache
# Removes any corrupt or zero-byte cached archive matching the given URL or filename.
purge_stale_duckdb_cache() {
  _psdc_fname="$(basename "${1:-duckdb_cli.zip}")"
  _psdc_cache_dir="${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}"
  for _psdc_f in \
    "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/$_psdc_fname" \
    "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/duckdb/$_psdc_fname" \
    "$_psdc_cache_dir/$_psdc_fname" \
    "$_psdc_cache_dir/duckdb/$_psdc_fname" \
    "$_psdc_cache_dir/unknown/$_psdc_fname" \
    "$_psdc_cache_dir/databases/$_psdc_fname" \
    "${LIBSCRIPT_ROOT_DIR}/cache/$_psdc_fname" \
    "${LIBSCRIPT_ROOT_DIR}/cache/downloads/$_psdc_fname"; do
    if [ -f "$_psdc_f" ]; then
      rm -f "$_psdc_f" 2>/dev/null || true
    fi
  done
}

# ## extract_duckdb_archive
# Extracts a downloaded DuckDB archive (.zip, .tar.gz, .gz, or raw binary) into TARGET_DIR/bin/duckdb.
extract_duckdb_archive() {
  _eda_src="${1:-}"
  _eda_target="${2:-}"
  _eda_hint="${3:-$_eda_src}"
  if [ -z "$_eda_src" ] || [ ! -s "$_eda_src" ]; then
    log_error "DuckDB archive '${_eda_src}' is missing or empty."
    return 1
  fi
  mkdir -p "${_eda_target}/bin"
  case "$_eda_hint" in
    *.tar.gz|*.tgz)
      tar -xzf "$_eda_src" -C "${_eda_target}" --strip-components=1 2>/dev/null || tar -xzf "$_eda_src" -C "${_eda_target}/bin" || return 1
      ;;
    *.zip)
      unzip -qo "$_eda_src" -d "${_eda_target}/bin" || return 1
      ;;
    *.gz)
      gzip -dc "$_eda_src" > "${_eda_target}/bin/duckdb" || return 1
      ;;
    *)
      if head -c 2 "$_eda_src" 2>/dev/null | grep -q "PK"; then
        unzip -qo "$_eda_src" -d "${_eda_target}/bin" || return 1
      else
        cp "$_eda_src" "${_eda_target}/bin/duckdb" || return 1
      fi
      ;;
  esac
  if [ -f "${_eda_target}/duckdb" ] && [ ! -f "${_eda_target}/bin/duckdb" ]; then
    mv "${_eda_target}/duckdb" "${_eda_target}/bin/duckdb"
  fi
  chmod +x "${_eda_target}/bin/duckdb" 2>/dev/null || true
  [ -x "${_eda_target}/bin/duckdb" ]
}

case "$ACTION" in
  ls)
    libscript_handle_generic_action "duckdb" "$ACTION" "$VERSION" "${DUCKDB_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${DUCKDB_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${DUCKDB_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
      git ls-remote --tags "https://github.com/duckdb/duckdb" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "duckdb" "$ACTION" "$VERSION" "${DUCKDB_INSTALL_METHOD}"
    ;;
  download)
    if [ "$DUCKDB_INSTALL_METHOD" = "libscript_native" ]; then
      if [ "${FORCE_REINSTALL:-0}" != "1" ] && find_existing_duckdb >/dev/null 2>&1; then
        log_info '[REUSE] duckdb is already installed; skipping download.'
        exit 0
      fi
      resolve_exact_version
      log_info "Downloading duckdb ${VERSION} (${EXACT_VERSION}) to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/duckdb..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/duckdb"
      if [ -n "${DUCKDB_DOWNLOAD_URL:-}" ]; then
        _dl_ext='zip'
        case "${DUCKDB_DOWNLOAD_URL}" in
          *.tar.gz|*.tgz) _dl_ext='tar.gz' ;;
          *.gz) _dl_ext='gz' ;;
        esac
        rm -f "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/duckdb/duckdb-${VERSION}.${_dl_ext}"
        libscript_download "${DUCKDB_DOWNLOAD_URL}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/duckdb/duckdb-${VERSION}.${_dl_ext}"
      else
        _dl_url=$(resolve_duckdb_release_url "${EXACT_VERSION}")
        _dl_dest="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/duckdb/duckdb-${VERSION}.zip"
        rm -f "$_dl_dest"
        if ! libscript_download "$_dl_url" "$_dl_dest"; then
          _fallback_url=$(resolve_duckdb_release_url "1.1.3")
          rm -f "$_dl_dest"
          libscript_download "$_fallback_url" "$_dl_dest"
        fi
      fi
    fi
    exit 0
    ;;
  install)
    if [ "${FORCE_REINSTALL:-0}" != "1" ] && _existing_dk=$(find_existing_duckdb 2>/dev/null); then
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/duckdb/${EXACT_VERSION}"
      mkdir -p "${TARGET_DIR}/bin"
      if [ "$_existing_dk" != "${TARGET_DIR}/bin/duckdb" ]; then
        ln -sf "$_existing_dk" "${TARGET_DIR}/bin/duckdb" 2>/dev/null || true
      fi
      libscript_symlink_alias "duckdb" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "duckdb" "default" "${EXACT_VERSION}"
      log_info "[REUSE] duckdb (${VERSION}) already installed at ${_existing_dk}."
      exit 0
    fi
    if [ "$DUCKDB_INSTALL_METHOD" = "from-source" ]; then
      EXACT_VERSION="${VERSION:-1.1.3}"
      [ "${EXACT_VERSION}" = "latest" ] && EXACT_VERSION='1.1.3'
      libscript_build_component_from_source "duckdb" "${EXACT_VERSION}" "duckdb" "c++" "cmake" "${DUCKDB_DOWNLOAD_URL:-}"
      exit 0
    fi
    if [ "$DUCKDB_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'duckdb'
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/duckdb/${EXACT_VERSION}"
      if [ ! -x "${TARGET_DIR}/bin/duckdb" ]; then
        log_info "Installing duckdb ${VERSION} (${EXACT_VERSION}) natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        cache_file=""
        if [ -d "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/duckdb" ]; then
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/duckdb/" -maxdepth 1 -type f \( -name "*${VERSION}*" -o -name "*${EXACT_VERSION}*" \) 2>/dev/null | head -n 1 || true)
        fi
        _extracted_ok=0
        if [ -n "$cache_file" ] && [ -s "$cache_file" ]; then
          log_info "Extracting from cache (${cache_file})..."
          libscript_depends 'unzip'
          if extract_duckdb_archive "$cache_file" "${TARGET_DIR}" "$cache_file"; then
            _extracted_ok=1
          else
            log_warn "Cached DuckDB archive '${cache_file}' is corrupt; removing and re-downloading..."
            rm -f "$cache_file"
          fi
        fi
        if [ "$_extracted_ok" -eq 0 ]; then
          if [ -n "${DUCKDB_DOWNLOAD_URL:-}" ]; then
            TEMP_DIR=$(mktemp -d)
            TEMP_FILE="${TEMP_DIR}/duckdb_archive"
            if ! libscript_download "${DUCKDB_DOWNLOAD_URL}" "${TEMP_FILE}" || [ ! -s "${TEMP_FILE}" ]; then
              purge_stale_duckdb_cache "${DUCKDB_DOWNLOAD_URL}"
              rm -f "${TEMP_FILE}"
              if ! libscript_download "${DUCKDB_DOWNLOAD_URL}" "${TEMP_FILE}" || [ ! -s "${TEMP_FILE}" ]; then
                rm -rf "${TEMP_DIR}"
                log_error "Failed to download duckdb from ${DUCKDB_DOWNLOAD_URL}"
                exit 1
              fi
            fi
            extract_duckdb_archive "${TEMP_FILE}" "${TARGET_DIR}" "${DUCKDB_DOWNLOAD_URL}"
            rm -rf "${TEMP_DIR}"
          else
            if [ "$UNAME_LOWER" = "freebsd" ]; then
              log_info "No native binary for FreeBSD. Falling back to system package manager for $PACKAGE_NAME..."
              libscript_depends "$PACKAGE_NAME"
              if command -v "$PACKAGE_NAME" >/dev/null 2>&1; then
                ln -sf "$(command -v "$PACKAGE_NAME")" "${TARGET_DIR}/bin/$PACKAGE_NAME"
              fi
            else
              log_info "No download URL provided for duckdb ${VERSION}. Attempting fallback to Github..."
              libscript_depends 'curl' 'unzip'
              TEMP_DIR=$(mktemp -d)
              TEMP_FILE="${TEMP_DIR}/duckdb_cli.zip"
              OS_ARCH="${ARCH:-x86_64}"
              _arch_slug='amd64'
              if [ "$OS_ARCH" = "aarch64" ] || [ "$OS_ARCH" = "arm64" ]; then
                _arch_slug='arm64'
              fi
              _actual_version="${EXACT_VERSION}"
              if [ "${_actual_version}" = "latest" ] || [ -z "${_actual_version}" ]; then
                _actual_version=$(libscript_fetch_stdout "https://api.github.com/repos/duckdb/duckdb/releases/latest" | grep -oE '"tag_name":[[:space:]]*"v[^"]+"' | sed -E 's/.*"v([^"]+)".*/v\1/' | head -n 1 || true)
                [ -z "$_actual_version" ] && _actual_version='v1.1.3'
              else
                case "${_actual_version}" in
                  v*) ;;
                  *) _actual_version="v${_actual_version}" ;;
                esac
              fi
              _musl_suffix=""
              if [ -f "/etc/alpine-release" ] && [ "$OS_ARCH" = "x86_64" ]; then _musl_suffix='-musl'; fi
              if [ "$UNAME_LOWER" = "darwin" ]; then
                DL_URL="https://github.com/duckdb/duckdb/releases/download/${_actual_version}/duckdb_cli-osx-universal.zip"
              elif [ "$_arch_slug" = "arm64" ]; then
                if [ -f "/etc/alpine-release" ]; then
                  libscript_depends 'gcompat' 'libstdc++' || true
                fi
                DL_URL="https://github.com/duckdb/duckdb/releases/download/${_actual_version}/duckdb_cli-linux-arm64.zip"
              else
                DL_URL="https://github.com/duckdb/duckdb/releases/download/${_actual_version}/duckdb_cli-linux-amd64${_musl_suffix}.zip"
              fi
              _dl_ok=0
              rm -f "${TEMP_FILE}"
              if libscript_download "$DL_URL" "${TEMP_FILE}" && [ -s "${TEMP_FILE}" ] && extract_duckdb_archive "${TEMP_FILE}" "${TARGET_DIR}" "$DL_URL"; then
                _dl_ok=1
              else
                purge_stale_duckdb_cache "$DL_URL"
                rm -f "${TEMP_FILE}"
                if libscript_download "$DL_URL" "${TEMP_FILE}" && [ -s "${TEMP_FILE}" ] && extract_duckdb_archive "${TEMP_FILE}" "${TARGET_DIR}" "$DL_URL"; then
                  _dl_ok=1
                fi
              fi
              if [ "$_dl_ok" -eq 0 ] && [ -n "$_musl_suffix" ]; then
                libscript_depends 'gcompat' 'libstdc++' || true
                DL_URL="https://github.com/duckdb/duckdb/releases/download/${_actual_version}/duckdb_cli-linux-amd64.zip"
                rm -f "${TEMP_FILE}"
                if libscript_download "$DL_URL" "${TEMP_FILE}" && [ -s "${TEMP_FILE}" ] && extract_duckdb_archive "${TEMP_FILE}" "${TARGET_DIR}" "$DL_URL"; then
                  _dl_ok=1
                else
                  purge_stale_duckdb_cache "$DL_URL"
                  rm -f "${TEMP_FILE}"
                  if libscript_download "$DL_URL" "${TEMP_FILE}" && [ -s "${TEMP_FILE}" ] && extract_duckdb_archive "${TEMP_FILE}" "${TARGET_DIR}" "$DL_URL"; then
                    _dl_ok=1
                  fi
                fi
              fi
              if [ "$_dl_ok" -eq 0 ]; then
                if [ "$UNAME_LOWER" = "darwin" ]; then
                  DL_URL='https://github.com/duckdb/duckdb/releases/download/v1.1.3/duckdb_cli-osx-universal.zip'
                else
                  DL_URL="https://github.com/duckdb/duckdb/releases/download/v1.1.3/duckdb_cli-linux-${_arch_slug}.zip"
                fi
                log_warn "Primary DuckDB download failed; falling back to ${DL_URL}..."
                purge_stale_duckdb_cache "$DL_URL"
                rm -f "${TEMP_FILE}"
                if libscript_download "$DL_URL" "${TEMP_FILE}" && [ -s "${TEMP_FILE}" ] && extract_duckdb_archive "${TEMP_FILE}" "${TARGET_DIR}" "$DL_URL"; then
                  _dl_ok=1
                fi
              fi
              if [ "$_dl_ok" -eq 0 ]; then
                rm -rf "${TEMP_DIR}"
                log_error 'Failed to download DuckDB CLI binary from GitHub releases.'
                exit 1
              fi
              rm -rf "${TEMP_DIR}"
              if [ -f "/etc/alpine-release" ] && [ -x "${TARGET_DIR}/bin/duckdb" ] && ! "${TARGET_DIR}/bin/duckdb" --version >/dev/null 2>&1; then
                libscript_depends 'gcompat' 'gcc' 'musl-dev' 'libstdc++' >/dev/null 2>&1 || true
                mkdir -p /usr/local/lib
                if [ ! -f "/usr/local/lib/libglibc_shim.so" ]; then
                  printf 'int __res_init(void){return 0;}\nint res_init(void){return 0;}\nint __register_atfork(void (*p)(void), void (*pa)(void), void (*c)(void), void *d){return 0;}\nconst char *gnu_get_libc_version(void){return "2.38";}\n' | gcc -shared -fPIC -x c - -o /usr/local/lib/libglibc_shim.so 2>/dev/null || true
                fi
                if [ -f "/usr/local/lib/libglibc_shim.so" ]; then
                  mv "${TARGET_DIR}/bin/duckdb" "${TARGET_DIR}/bin/duckdb.bin"
                  cat << 'SHIM' > "${TARGET_DIR}/bin/duckdb"
#!/bin/sh
export LD_PRELOAD="/usr/local/lib/libglibc_shim.so:/lib/libgcompat.so.0:${LD_PRELOAD:-}"
exec "$(dirname "$0")/duckdb.bin" "$@"
SHIM
                  chmod +x "${TARGET_DIR}/bin/duckdb"
                fi
              fi
            fi
          fi
        fi
        if [ ! -x "${TARGET_DIR}/bin/duckdb" ] || ! "${TARGET_DIR}/bin/duckdb" --version >/dev/null 2>&1; then
          log_error "DuckDB binary verification failed at ${TARGET_DIR}/bin/duckdb."
          exit 1
        fi
      else
        log_info "duckdb ${VERSION} is already installed."
      fi
      libscript_symlink_alias "duckdb" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "duckdb" "default" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "duckdb" "$ACTION" "$VERSION" "${DUCKDB_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
