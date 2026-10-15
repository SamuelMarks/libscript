#!/bin/sh
# ## Overview
# Generic setup and multi-mode build module for SQLite.
# Supports Mode 1 (installing via a specific package manager), Mode 2 (building
# the SQLite C amalgamation from source with the default host toolchain), and
# Mode 3 (building the SQLite C amalgamation from source with a custom compiler
# toolchain such as gcc, clang, tcc, or custom-cc).
#
# ## Usage
# Invoked via `./libscript.sh install sqlite [version] [options]`.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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
export LIBSCRIPT_ROOT_DIR
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

if [ -n "${SQLITE_PKG_MGR:-}" ]; then
  export LIBSCRIPT_PKG_MGR="${SQLITE_PKG_MGR}"
fi

SQLITE_INSTALL_METHOD="${SQLITE_INSTALL_METHOD:-$(libscript_resolve_install_method "SQLITE")}"
ACTION="${ACTION:-install}"
VERSION="${SQLITE_VERSION:-${VERSION:-latest}}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'stable') to a concrete SQLite version string.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ] || [ -z "${VERSION:-}" ]; then
    EXACT_VERSION="3.46.1"
  else
    EXACT_VERSION="${VERSION}"
  fi
}

# ## resolve_sqlite_amalgamation_url
# Computes the sqlite.org amalgamation zip URL and numeric version code for the target SQLite version.
resolve_sqlite_amalgamation_url() {
  resolve_exact_version
  if [ -n "${SQLITE_AMALGAMATION_URL:-}" ]; then
    printf '%s\n' "${SQLITE_AMALGAMATION_URL}"
    return 0
  fi
  _yr="${SQLITE_AMALGAMATION_YEAR:-2024}"
  case "${EXACT_VERSION}" in
    3.46.1) _num="3460100" ;;
    3.46.0) _num="3460000" ;;
    3.45.*) _num="3450300" ;;
    *)      _num="3460100" ;;
  esac
  printf 'https://www.sqlite.org/%s/sqlite-amalgamation-%s.zip
' "${_yr}" "${_num}"
}

# ## install_sqlite_via_pkg_mgr
# Installs SQLite using the explicitly selected or auto-detected system package manager (Mode 1) and stages a local shim.
install_sqlite_via_pkg_mgr() {
  resolve_exact_version
  if [ -n "${SQLITE_PKG_MGR:-}" ]; then
    export LIBSCRIPT_PKG_MGR="${SQLITE_PKG_MGR}"
  fi
  libscript_depends "sqlite"
  if [ "${LIBSCRIPT_DRY_RUN_PKG_MGR:-0}" = "1" ]; then
    return 0
  fi
  _target_dir="${LIBSCRIPT_HOME:-$HOME/.libscript}/sqlite/${EXACT_VERSION}"
  mkdir -p "${_target_dir}/bin"
  _sys_sqlite="$(command -v sqlite3 2>/dev/null || true)"
  if [ -n "${_sys_sqlite}" ] && [ "${_sys_sqlite}" != "${_target_dir}/bin/sqlite3" ] && [ "${_sys_sqlite}" != "${LIBSCRIPT_HOME:-$HOME/.libscript}/sqlite/default/bin/sqlite3" ]; then
    ln -sf "${_sys_sqlite}" "${_target_dir}/bin/sqlite3"
    ln -sf "${_sys_sqlite}" "${_target_dir}/bin/sqlite"
  fi
  libscript_symlink_alias "sqlite" "${VERSION}" "${EXACT_VERSION}"
  libscript_symlink_alias "sqlite" "default" "${EXACT_VERSION}"
}

# ## compile_sqlite_amalgamation_callback
# Compiles sqlite3.c and shell.c into the sqlite3 CLI, static library libsqlite3.a, and headers.
compile_sqlite_amalgamation_callback() {
  _amal_dir="${1}"
  _cflags="${SQLITE_CFLAGS:--O2 -DSQLITE_ENABLE_MATH_FUNCTIONS -DSQLITE_ENABLE_FTS5 -DSQLITE_ENABLE_RTREE}"
  _ldflags="${SQLITE_LDFLAGS:--lpthread -ldl -lm}"

  if [ "${SQLITE_SINGLE_THREADED:-false}" = "true" ] || [ "${SQLITE_SINGLE_THREADED:-0}" = "1" ] || [ "${LIBSCRIPT_RESOLVED_CC_ID:-default}" = "tcc" ]; then
    _cflags="-O2 -DSQLITE_THREADSAFE=0 -DSQLITE_OMIT_LOAD_EXTENSION=1 -DSQLITE_ENABLE_MATH_FUNCTIONS -DSQLITE_ENABLE_FTS5 -DSQLITE_ENABLE_RTREE"
    _ldflags="-lm"
  fi
  if [ -n "${LIBSCRIPT_BUILD_CFLAGS:-}" ]; then
    _cflags="${_cflags} ${LIBSCRIPT_BUILD_CFLAGS}"
  fi
  if [ -n "${LIBSCRIPT_BUILD_LDFLAGS:-}" ]; then
    _ldflags="${_ldflags} ${LIBSCRIPT_BUILD_LDFLAGS}"
  fi

  SQLITE_EFFECTIVE_CFLAGS="${_cflags}"
  SQLITE_EFFECTIVE_LDFLAGS="${_ldflags}"
  export SQLITE_EFFECTIVE_CFLAGS
  export SQLITE_EFFECTIVE_LDFLAGS

  log_info "Compiling SQLite ${EXACT_VERSION} amalgamation with ${LIBSCRIPT_RESOLVED_CC_ID} (${LIBSCRIPT_RESOLVED_CC_BIN})..."
  # shellcheck disable=SC2086
  "${LIBSCRIPT_RESOLVED_CC_BIN}" ${_cflags} -c "${_amal_dir}/sqlite3.c" -o "${_amal_dir}/sqlite3.o"
  if command -v ar >/dev/null 2>&1; then
    ar rcs "${LIBSCRIPT_BUILD_TARGET_DIR}/lib/libsqlite3.a" "${_amal_dir}/sqlite3.o" || true
  fi
  rm -f "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/sqlite3" "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/sqlite"
  # shellcheck disable=SC2086
  "${LIBSCRIPT_RESOLVED_CC_BIN}" ${_cflags} "${_amal_dir}/shell.c" "${_amal_dir}/sqlite3.o" -o "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/sqlite3" ${_ldflags}
  ln -sf "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/sqlite3" "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/sqlite"
  cp "${_amal_dir}/sqlite3.h" "${LIBSCRIPT_BUILD_TARGET_DIR}/include/sqlite3.h"
  if [ -f "${_amal_dir}/sqlite3ext.h" ]; then
    cp "${_amal_dir}/sqlite3ext.h" "${LIBSCRIPT_BUILD_TARGET_DIR}/include/sqlite3ext.h"
  fi
}

# ## build_sqlite_from_source
# Resolves the requested build toolchain (Mode 2 'default' or Mode 3 custom compiler), downloads the SQLite amalgamation once, compiles sqlite3, and emits build-metrics.json.
build_sqlite_from_source() {
  resolve_exact_version
  libscript_resolve_build_toolchain "sqlite" "${EXACT_VERSION}"
  if libscript_check_source_build_idempotency "sqlite" "${EXACT_VERSION}" "sqlite3" "${VERSION}"; then
    return 0
  fi

  _amal_url="$(resolve_sqlite_amalgamation_url)"
  libscript_fetch_and_extract_source "sqlite" "${_amal_url}"
  libscript_execute_source_build "custom" "${LIBSCRIPT_EXTRACTED_SRC_DIR}" compile_sqlite_amalgamation_callback
  libscript_emit_build_metrics "sqlite" "${EXACT_VERSION}" "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/sqlite3" "${SQLITE_EFFECTIVE_CFLAGS:-}" "${SQLITE_EFFECTIVE_LDFLAGS:-}"

  rm -rf "${LIBSCRIPT_SOURCE_WORKDIR:-}" 2>/dev/null || true

  _target_leaf="$(basename "${LIBSCRIPT_BUILD_TARGET_DIR}")"
  if [ "${LIBSCRIPT_RESOLVED_CC_ID:-default}" = "default" ]; then
    libscript_symlink_alias "sqlite" "${VERSION}" "${_target_leaf}"
    libscript_symlink_alias "sqlite" "default" "${_target_leaf}"
  else
    libscript_symlink_alias "sqlite" "${VERSION}-${LIBSCRIPT_RESOLVED_CC_ID}" "${_target_leaf}"
    libscript_symlink_alias "sqlite" "default-${LIBSCRIPT_RESOLVED_CC_ID}" "${_target_leaf}"
    libscript_symlink_alias "sqlite" "${VERSION}" "${_target_leaf}"
    libscript_symlink_alias "sqlite" "default" "${_target_leaf}"
  fi
}

case "$ACTION" in
  ls)
    if [ "$SQLITE_INSTALL_METHOD" = "mise" ]; then
      mise ls sqlite || true
    elif [ "$SQLITE_INSTALL_METHOD" = "asdf" ]; then
      asdf list sqlite || true
    elif [ "$SQLITE_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$SQLITE_INSTALL_METHOD" = "vfox" ]; then
      vfox ls sqlite || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/sqlite/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$SQLITE_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote sqlite || true
    elif [ "$SQLITE_INSTALL_METHOD" = "asdf" ]; then
      asdf list all sqlite || true
    else
      printf '3.45.3
3.46.0
3.46.1
'
    fi
    exit 0
    ;;
  use)
    resolve_exact_version
    _tc_id="${SQLITE_BUILD_TOOLCHAIN:-${SQLITE_COMPILER:-${LIBSCRIPT_BUILD_TOOLCHAIN:-default}}}"
    if [ "${_tc_id}" != "default" ] && [ -d "${LIBSCRIPT_HOME:-$HOME/.libscript}/sqlite/${EXACT_VERSION}-${_tc_id}" ]; then
      libscript_symlink_alias "sqlite" "${VERSION}" "${EXACT_VERSION}-${_tc_id}"
      libscript_symlink_alias "sqlite" "default" "${EXACT_VERSION}-${_tc_id}"
      log_info "Set default sqlite version to ${EXACT_VERSION}-${_tc_id}."
    else
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/sqlite/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "sqlite ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "${PACKAGE_NAME:-sqlite}" "" || exit 1
      fi
      libscript_symlink_alias "sqlite" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "sqlite" "default" "${EXACT_VERSION}"
      log_info "Set default sqlite version to ${EXACT_VERSION}."
    fi
    exit 0
    ;;
  download)
    _amal_url="$(resolve_sqlite_amalgamation_url)"
    _cache_dir="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}/sqlite}"
    mkdir -p "${_cache_dir}"
    PACKAGE_NAME="sqlite" libscript_download "${_amal_url}" "${_cache_dir}/$(basename "${_amal_url}")"
    exit 0
    ;;
  install)
    case "$SQLITE_INSTALL_METHOD" in
      from-source)
        build_sqlite_from_source
        ;;
      system|pkg_mgr:*|brew|winget|choco|scoop|nix|spack|vcpkg)
        install_sqlite_via_pkg_mgr
        ;;
      mise)
        mise install "sqlite@${VERSION}"
        ;;
      asdf)
        asdf install sqlite "${VERSION}"
        ;;
      pkgx)
        pkgx install "sqlite@${VERSION}"
        ;;
      vfox)
        vfox add sqlite || true
        vfox install "sqlite@${VERSION}"
        ;;
      *)
        resolve_exact_version
        TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/sqlite/${EXACT_VERSION}"
        if [ -x "${TARGET_DIR}/bin/sqlite3" ] && [ "${FORCE_REBUILD:-0}" != "1" ]; then
          log_info "sqlite ${EXACT_VERSION} is already installed at ${TARGET_DIR}."
          libscript_symlink_alias "sqlite" "$VERSION" "${EXACT_VERSION}"
          libscript_symlink_alias "sqlite" "default" "${EXACT_VERSION}"
          exit 0
        fi
        if [ -n "${SQLITE_DOWNLOAD_URL:-}" ]; then
          mkdir -p "${TARGET_DIR}/bin"
          TEMP_FILE=$(mktemp)
          PACKAGE_NAME="sqlite" libscript_download "${SQLITE_DOWNLOAD_URL}" "${TEMP_FILE}"
          case "${SQLITE_DOWNLOAD_URL}" in
            *.tar.gz|*.tgz) tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true ;;
            *.zip) unzip -q -o "${TEMP_FILE}" -d "${TARGET_DIR}" || true ;;
            *) cp "${TEMP_FILE}" "${TARGET_DIR}/bin/sqlite3" && chmod +x "${TARGET_DIR}/bin/sqlite3" ;;
          esac
          rm -f "${TEMP_FILE}"
          libscript_symlink_alias "sqlite" "$VERSION" "${EXACT_VERSION}"
          libscript_symlink_alias "sqlite" "default" "${EXACT_VERSION}"
        elif command -v sqlite3 >/dev/null 2>&1; then
          mkdir -p "${TARGET_DIR}/bin"
          ln -sf "$(command -v sqlite3)" "${TARGET_DIR}/bin/sqlite3"
          ln -sf "$(command -v sqlite3)" "${TARGET_DIR}/bin/sqlite"
          libscript_symlink_alias "sqlite" "$VERSION" "${EXACT_VERSION}"
          libscript_symlink_alias "sqlite" "default" "${EXACT_VERSION}"
        else
          build_sqlite_from_source
        fi
        ;;
    esac
    ;;
  start|stop|restart|status|health|logs|up|down)
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090,SC1091
    . "${SCRIPT_NAME}"
    service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-sqlite}}"
    libscript_service "$ACTION" "$service_name" "$@"
    exit 0
    ;;
  install-service)
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090,SC1091
    . "${SCRIPT_NAME}"
    service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-sqlite}}"
    libscript_install_service "$service_name" "$@"
    exit 0
    ;;
  uninstall-service)
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090,SC1091
    . "${SCRIPT_NAME}"
    service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-sqlite}}"
    libscript_uninstall_service "$service_name" "$@"
    exit 0
    ;;
  uninstall)
    resolve_exact_version
    log_info "Uninstalling sqlite ${VERSION}..."
    rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/sqlite/${EXACT_VERSION}"*
    rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/sqlite/${VERSION}"
    exit 0
    ;;
esac
