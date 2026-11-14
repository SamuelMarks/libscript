#!/bin/sh
# ## Overview
# Generic setup and multi-mode build module for SQLite.
# Supports Mode 1 (installing via a specific package manager), Mode 2 (building
# the SQLite C amalgamation from source with the default host toolchain), and
# Mode 3 (building the SQLite C amalgamation from source with a custom compiler
# toolchain such as gcc, clang, tcc, or custom-cc).
# ## Usage
# Invoked via `./libscript.sh install sqlite [version] [options]`.
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
    EXACT_VERSION='3.46.1'
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
  libscript_depends 'sqlite'
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
    _ldflags='-lm'
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
  _cache_zip="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}/sqlite}/$(basename "${_amal_url}")"
  if [ "${LIBSCRIPT_OFFLINE:-0}" = "1" ] && [ ! -f "${_cache_zip}" ]; then
    libscript_build_component_from_source "sqlite" "${EXACT_VERSION}" "sqlite3" "c" "make" ""
    return 0
  fi
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

# ## run_sqlite_relational_regression
# Executes the Experiment 2 relational SQL integrity script (`CREATE TABLE`, `INDEX`, `TRIGGER`, `VIEW`, `ROLLBACK`, window functions, JSON functions) against `$1`.
run_sqlite_relational_regression() {
  _sq_bin="${1:-sqlite3}"
  "${_sq_bin}" ':memory:' <<'SQL_EOF'
PRAGMA foreign_keys = ON;
CREATE TABLE dept (id INTEGER PRIMARY KEY, name TEXT NOT NULL);
CREATE TABLE emp (id INTEGER PRIMARY KEY, dept_id INTEGER REFERENCES dept(id), salary INT, meta TEXT);
CREATE TABLE audit_log (evt TEXT);
CREATE INDEX idx_emp_dept ON emp(dept_id, salary);
CREATE TRIGGER trg_emp_ins AFTER INSERT ON emp BEGIN
  INSERT INTO audit_log(evt) VALUES ('ins:' || NEW.id || ':' || NEW.salary);
END;
INSERT INTO dept VALUES (1, 'compiler'), (2, 'runtime');
INSERT INTO emp VALUES (10, 1, 120, '{"tier":1}'), (11, 1, 150, '{"tier":2}'), (12, 2, 130, '{"tier":1}');
SAVEPOINT sp1;
INSERT INTO emp VALUES (99, 2, 999, '{"tier":9}');
ROLLBACK TO sp1;
RELEASE sp1;
CREATE VIEW v_dept_rank AS
  SELECT d.name AS dname, e.id AS eid, e.salary AS sal,
         RANK() OVER (PARTITION BY e.dept_id ORDER BY e.salary DESC) AS rnk,
         json_extract(e.meta, '$.tier') AS tier
  FROM emp e JOIN dept d ON d.id = e.dept_id;
SELECT dname || '|' || eid || '|' || sal || '|' || rnk || '|' || tier FROM v_dept_rank ORDER BY eid;
SELECT COUNT(*) || '|' || GROUP_CONCAT(evt, ',') FROM audit_log;
SQL_EOF
}

case "$ACTION" in
  stage-benchmark-inputs)
    resolve_exact_version
    _st_dir="${SQLITE_STAGE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache/benchmarks/sqlite-${EXACT_VERSION}}"
    mkdir -p "${_st_dir}"
    if [ ! -f "${_st_dir}/sqlite3.c" ] || [ ! -f "${_st_dir}/shell.c" ]; then
      _amal_url="$(resolve_sqlite_amalgamation_url)"
      libscript_fetch_and_extract_source "sqlite" "${_amal_url}"
      for _f in sqlite3.c shell.c sqlite3.h sqlite3ext.h; do
        [ -f "${LIBSCRIPT_EXTRACTED_SRC_DIR}/${_f}" ] && cp "${LIBSCRIPT_EXTRACTED_SRC_DIR}/${_f}" "${_st_dir}/${_f}"
      done
      rm -rf "${LIBSCRIPT_SOURCE_WORKDIR:-}" 2>/dev/null || true
    fi
    if [ ! -f "${_st_dir}/speedtest1.c" ] && [ -n "${SQLITE_SRC_URL:-}" ]; then
      libscript_fetch_and_extract_source "sqlite-src" "${SQLITE_SRC_URL}"
      [ -f "${LIBSCRIPT_EXTRACTED_SRC_DIR}/test/speedtest1.c" ] && cp "${LIBSCRIPT_EXTRACTED_SRC_DIR}/test/speedtest1.c" "${_st_dir}/speedtest1.c"
      rm -rf "${LIBSCRIPT_SOURCE_WORKDIR:-}" 2>/dev/null || true
    fi
    _loc_sq=0
    _loc_sh=0
    [ -f "${_st_dir}/sqlite3.c" ] && _loc_sq=$(wc -l < "${_st_dir}/sqlite3.c" | awk '{print $1+0}')
    [ -f "${_st_dir}/shell.c" ] && _loc_sh=$(wc -l < "${_st_dir}/shell.c" | awk '{print $1+0}')
    printf '{"version":"%s","stage_dir":"%s","sqlite3_loc":%s,"shell_loc":%s}\n' "${EXACT_VERSION}" "${_st_dir}" "${_loc_sq}" "${_loc_sh}"
    exit 0
    ;;
  run-sql-regression)
    run_sqlite_relational_regression "${SQLITE_BIN:-sqlite3}"
    exit 0
    ;;
  ls)
    ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/sqlite/" 2>/dev/null || true
    exit 0
    ;;
  ls-remote)
    printf '3.45.3
3.46.0
3.46.1
'
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
    _cache_dir="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}/sqlite}"
    mkdir -p "${_cache_dir}"
    if [ "$SQLITE_INSTALL_METHOD" = "from-source" ] || [ -n "${SQLITE_BUILD_TOOLCHAIN:-${SQLITE_COMPILER:-${LIBSCRIPT_BUILD_TOOLCHAIN:-}}}" ]; then
      _amal_url="$(resolve_sqlite_amalgamation_url)"
      PACKAGE_NAME="sqlite" libscript_download "${_amal_url}" "${_cache_dir}/$(basename "${_amal_url}")"
    elif [ -n "${SQLITE_DOWNLOAD_URL:-}" ]; then
      PACKAGE_NAME="sqlite" libscript_download "${SQLITE_DOWNLOAD_URL}" "${_cache_dir}/$(basename "${SQLITE_DOWNLOAD_URL}")"
    else
      log_info 'No SQLITE_DOWNLOAD_URL set for prebuilt SQLite; download skipped (from-source not requested).'
    fi
    exit 0
    ;;
  install)
    if [ -n "${SQLITE_BUILD_TOOLCHAIN:-${SQLITE_COMPILER:-${LIBSCRIPT_BUILD_TOOLCHAIN:-}}}" ] && [ "${SQLITE_BUILD_TOOLCHAIN:-${SQLITE_COMPILER:-${LIBSCRIPT_BUILD_TOOLCHAIN:-default}}}" != "default" ]; then
      build_sqlite_from_source
      exit 0
    fi
    case "$SQLITE_INSTALL_METHOD" in
      from-source)
        build_sqlite_from_source
        ;;
      system|pkg_mgr:*|brew|winget|choco|scoop|nix|spack|vcpkg)
        install_sqlite_via_pkg_mgr
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
          install_sqlite_via_pkg_mgr
        fi
        ;;
    esac
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "sqlite" "$ACTION" "$VERSION" "${SQLITE_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
