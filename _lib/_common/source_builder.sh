#!/bin/sh
# ## Overview
# Generic source build engine for LibScript components. Supports Mode 2 (building
# from source with the platform default C toolchain) and Mode 3 (building from
# source with an explicit custom C toolchain such as gcc, clang, tcc, or custom-cc).
#
# ## Usage
# Source this library via SCRIPT_NAME from any component's setup_generic.sh:
#   SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/source_builder.sh"
#   export SCRIPT_NAME
#   . "${SCRIPT_NAME}"

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

_sb_saved_script_dir="${SCRIPT_DIR}"
for LIB in "_lib/_common/log.sh" "_lib/_common/pkg_mgr.sh" "_lib/_common/versioning.sh" "_lib/toolchains/triplets.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  LIBSCRIPT_TRIPLETS_QUIET=1 . "${SCRIPT_NAME}"
done
SCRIPT_DIR="${_sb_saved_script_dir}"

# ## libscript_now_ms
# Returns the current monotonic/epoch timestamp in milliseconds for build timing metrics.
libscript_now_ms() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import time; print(int(time.time() * 1000))' 2>/dev/null && return 0
  fi
  if command -v perl >/dev/null 2>&1; then
    perl -MTime::HiRes=time -e 'printf "%d
", int(time() * 1000)' 2>/dev/null && return 0
  fi
  printf '%s000
' "$(date +%s)"
}

# ## libscript_resolve_build_toolchain
# Resolves and activates the requested C build toolchain (Mode 2 'default' or Mode 3 custom compiler) and computes the target installation directory.
libscript_resolve_build_toolchain() {
  _sb_comp="${1:-${PACKAGE_NAME:-component}}"
  _sb_exact_ver="${2:-${EXACT_VERSION:-latest}}"
  _sb_comp_upper=$(printf '%s\n' "${_sb_comp##*/}" | tr '[:lower:]' '[:upper:]' | tr '-' '_')

  _tc_spec="$(printenv "${_sb_comp_upper}_BUILD_TOOLCHAIN" 2>/dev/null || true)"
  if [ -z "${_tc_spec}" ]; then
    _tc_spec="$(printenv "${_sb_comp_upper}_COMPILER" 2>/dev/null || true)"
  fi
  if [ -z "${_tc_spec}" ]; then
    _tc_spec="${LIBSCRIPT_BUILD_TOOLCHAIN:-${CC_BACKEND:-default}}"
  fi
  [ -z "${_tc_spec}" ] && _tc_spec="default"

  LIBSCRIPT_RESOLVED_CC_ID="default"
  LIBSCRIPT_RESOLVED_CC_BIN="${CC:-cc}"

  case "${_tc_spec}" in
    /*|./*|../*|*/*)
      export CUSTOM_CC_BIN="${_tc_spec}"
      export LIBSCRIPT_CUSTOM_CC_BIN="${_tc_spec}"
      _tc_spec="custom-cc"
      ;;
  esac

  if [ "${_tc_spec}" = "default" ] || [ "${_tc_spec}" = "system" ]; then
    if ! command -v cc >/dev/null 2>&1 && ! command -v gcc >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1; then
      if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/languages/c/setup.sh" ]; then
        unset SCRIPT_NAME || true
        "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install c latest || true
      fi
    fi
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/languages/c/env.sh" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/languages/c/env.sh"
      export SCRIPT_NAME
      # shellcheck disable=SC1090,SC1091
      . "${SCRIPT_NAME}"
    fi
    if command -v "${CC:-cc}" >/dev/null 2>&1; then
      LIBSCRIPT_RESOLVED_CC_BIN="$(command -v "${CC:-cc}")"
    elif command -v gcc >/dev/null 2>&1; then
      LIBSCRIPT_RESOLVED_CC_BIN="$(command -v gcc)"
    elif command -v clang >/dev/null 2>&1; then
      LIBSCRIPT_RESOLVED_CC_BIN="$(command -v clang)"
    else
      LIBSCRIPT_RESOLVED_CC_BIN="cc"
    fi
    LIBSCRIPT_RESOLVED_CC_ID="default"
    export CC="${LIBSCRIPT_RESOLVED_CC_BIN}"
    export HOSTCC="${HOSTCC:-${CC}}"
    resolve_compiler_flags "default"
    if [ "${LIBSCRIPT_NAMESPACE_DEFAULT_TOOLCHAIN:-0}" = "1" ]; then
      LIBSCRIPT_BUILD_TARGET_DIR="${PREFIX:-${LIBSCRIPT_HOME:-$HOME/.libscript}/${_sb_comp}/${_sb_exact_ver}-default}"
    else
      LIBSCRIPT_BUILD_TARGET_DIR="${PREFIX:-${LIBSCRIPT_HOME:-$HOME/.libscript}/${_sb_comp}/${_sb_exact_ver}}"
    fi
  else
    LIBSCRIPT_RESOLVED_CC_ID="${_tc_spec}"
    if [ -d "${LIBSCRIPT_ROOT_DIR}/_lib/languages/${_tc_spec}" ]; then
      _cc_recipe_dir="${LIBSCRIPT_ROOT_DIR}/_lib/languages/${_tc_spec}"
      _need_install=1
      if [ "${_tc_spec}" = "gcc" ] && command -v gcc >/dev/null 2>&1 && [ ! -x "${LIBSCRIPT_HOME:-$HOME/.libscript}/gcc/default/bin/gcc" ]; then
        _need_install=1
      fi
      if [ "${_need_install}" = "1" ]; then
        unset SCRIPT_NAME || true
        LIBSCRIPT_DEFAULT_INSTALL_METHOD="" LIBSCRIPT_BUILD_TOOLCHAIN="default" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install "${_tc_spec}" latest || true
      fi
      if [ -f "${_cc_recipe_dir}/env.sh" ]; then
        SCRIPT_NAME="${_cc_recipe_dir}/env.sh"
        export SCRIPT_NAME
        # shellcheck disable=SC1090,SC1091
        . "${SCRIPT_NAME}"
      fi
    fi

    case "${_tc_spec}" in
      gcc)
        if [ -x "${LIBSCRIPT_HOME:-$HOME/.libscript}/gcc/default/bin/gcc" ]; then
          LIBSCRIPT_RESOLVED_CC_BIN="${LIBSCRIPT_HOME:-$HOME/.libscript}/gcc/default/bin/gcc"
        elif command -v gcc >/dev/null 2>&1; then
          LIBSCRIPT_RESOLVED_CC_BIN="$(command -v gcc)"
        else
          LIBSCRIPT_RESOLVED_CC_BIN="${CC:-gcc}"
        fi
        ;;
      clang)
        if [ -x "${LIBSCRIPT_HOME:-$HOME/.libscript}/clang/default/bin/clang" ]; then
          LIBSCRIPT_RESOLVED_CC_BIN="${LIBSCRIPT_HOME:-$HOME/.libscript}/clang/default/bin/clang"
        elif command -v clang >/dev/null 2>&1; then
          LIBSCRIPT_RESOLVED_CC_BIN="$(command -v clang)"
        else
          LIBSCRIPT_RESOLVED_CC_BIN="${CC:-clang}"
        fi
        ;;
      tcc)
        if [ -x "${LIBSCRIPT_HOME:-$HOME/.libscript}/tcc/default/bin/tcc" ]; then
          LIBSCRIPT_RESOLVED_CC_BIN="${LIBSCRIPT_HOME:-$HOME/.libscript}/tcc/default/bin/tcc"
        elif command -v tcc >/dev/null 2>&1; then
          LIBSCRIPT_RESOLVED_CC_BIN="$(command -v tcc)"
        else
          LIBSCRIPT_RESOLVED_CC_BIN="${CC:-tcc}"
        fi
        ;;
      custom-cc)
        if [ -x "${LIBSCRIPT_HOME:-$HOME/.libscript}/custom-cc/default/bin/custom-cc" ]; then
          LIBSCRIPT_RESOLVED_CC_BIN="${LIBSCRIPT_HOME:-$HOME/.libscript}/custom-cc/default/bin/custom-cc"
        elif [ -n "${CUSTOM_CC_BIN:-}" ] && [ -x "${CUSTOM_CC_BIN}" ]; then
          LIBSCRIPT_RESOLVED_CC_BIN="${CUSTOM_CC_BIN}"
        elif [ -x "${LIBSCRIPT_ROOT_DIR}/_lib/languages/custom-cc/cc_wrapper.sh" ]; then
          LIBSCRIPT_RESOLVED_CC_BIN="${LIBSCRIPT_ROOT_DIR}/_lib/languages/custom-cc/cc_wrapper.sh"
        else
          LIBSCRIPT_RESOLVED_CC_BIN="${CC:-cc}"
        fi
        ;;
      *)
        if command -v "${_tc_spec}" >/dev/null 2>&1; then
          LIBSCRIPT_RESOLVED_CC_BIN="$(command -v "${_tc_spec}")"
        else
          LIBSCRIPT_RESOLVED_CC_BIN="${_tc_spec}"
        fi
        ;;
    esac

    export CC="${LIBSCRIPT_RESOLVED_CC_BIN}"
    export HOSTCC="${HOSTCC:-${CC}}"
    resolve_compiler_flags "${LIBSCRIPT_RESOLVED_CC_ID}"
    LIBSCRIPT_BUILD_TARGET_DIR="${PREFIX:-${LIBSCRIPT_HOME:-$HOME/.libscript}/${_sb_comp}/${_sb_exact_ver}-${LIBSCRIPT_RESOLVED_CC_ID}}"
  fi

  LIBSCRIPT_RESOLVED_CC_VERSION="$("${LIBSCRIPT_RESOLVED_CC_BIN}" --version 2>&1 | head -n 1 | tr -d '
' || printf '%s' "unknown")"
  export LIBSCRIPT_RESOLVED_CC_ID
  export LIBSCRIPT_RESOLVED_CC_BIN
  export LIBSCRIPT_RESOLVED_CC_VERSION
  export LIBSCRIPT_BUILD_TARGET_DIR
}

# ## libscript_check_source_build_idempotency
# Verifies whether a source build for the resolved component, version, and compiler already exists and is up to date.
libscript_check_source_build_idempotency() {
  _idemp_comp="${1}"
  _idemp_ver="${2}"
  _idemp_bin="${3}"
  _idemp_alias="${4:-default}"

  if [ "${FORCE_REBUILD:-0}" = "1" ]; then
    return 1
  fi

  if [ -x "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/${_idemp_bin}" ] && [ -f "${LIBSCRIPT_BUILD_TARGET_DIR}/build-metrics.json" ]; then
    if [ "${LIBSCRIPT_RESOLVED_CC_ID:-default}" = "default" ]; then
      libscript_symlink_alias "${_idemp_comp}" "${_idemp_alias}" "${_idemp_ver}"
    else
      libscript_symlink_alias "${_idemp_comp}" "${_idemp_alias}-${LIBSCRIPT_RESOLVED_CC_ID}" "${_idemp_ver}-${LIBSCRIPT_RESOLVED_CC_ID}"
      libscript_symlink_alias "${_idemp_comp}" "${_idemp_alias}" "${_idemp_ver}-${LIBSCRIPT_RESOLVED_CC_ID}"
    fi
    log_info "${_idemp_comp} ${_idemp_ver} (${LIBSCRIPT_RESOLVED_CC_ID}) already built from source at ${LIBSCRIPT_BUILD_TARGET_DIR}."
    return 0
  fi
  return 1
}

# ## libscript_fetch_and_extract_source
# Downloads a source archive or clones a git repository into a shared download cache and extracts it into an isolated build directory.
libscript_fetch_and_extract_source() {
  _src_comp="${1}"
  _src_url="${2}"
  _src_checksum="${3:-}"
  _src_cache_dir="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}/${_src_comp}}"
  mkdir -p "${_src_cache_dir}"

  LIBSCRIPT_SOURCE_WORKDIR="${TMPDIR:-/tmp}/libscript_srcbuild_${_src_comp}_${LIBSCRIPT_RESOLVED_CC_ID:-default}_$$"
  rm -rf "${LIBSCRIPT_SOURCE_WORKDIR}"
  mkdir -p "${LIBSCRIPT_SOURCE_WORKDIR}"

  case "${_src_url}" in
    *.git|git://*)
      if command -v git >/dev/null 2>&1; then
        git clone --depth 1 "${_src_url}" "${LIBSCRIPT_SOURCE_WORKDIR}/src"
        LIBSCRIPT_EXTRACTED_SRC_DIR="${LIBSCRIPT_SOURCE_WORKDIR}/src"
        export LIBSCRIPT_SOURCE_WORKDIR
        export LIBSCRIPT_EXTRACTED_SRC_DIR
        return 0
      fi
      ;;
  esac

  _archive_name="$(basename "${_src_url}")"
  _archive_file="${_src_cache_dir}/${_archive_name}"
  PACKAGE_NAME="${_src_comp}" libscript_download "${_src_url}" "${_archive_file}" "${_src_checksum}"

  case "${_archive_name}" in
    *.zip)
      if ! command -v unzip >/dev/null 2>&1; then
        pkg_mgr_install unzip >/dev/null 2>&1 || true
      fi
      if command -v unzip >/dev/null 2>&1; then
        unzip -q -o "${_archive_file}" -d "${LIBSCRIPT_SOURCE_WORKDIR}"
      elif command -v python3 >/dev/null 2>&1; then
        python3 -c 'import sys, zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])' "${_archive_file}" "${LIBSCRIPT_SOURCE_WORKDIR}"
      elif command -v bsdtar >/dev/null 2>&1; then
        bsdtar -xf "${_archive_file}" -C "${LIBSCRIPT_SOURCE_WORKDIR}"
      elif command -v tar >/dev/null 2>&1; then
        tar -xf "${_archive_file}" -C "${LIBSCRIPT_SOURCE_WORKDIR}"
      else
        log_error "Neither unzip nor bsdtar available to extract ${_archive_file}"
        return 1
      fi
      ;;
    *.tar.gz|*.tgz)
      tar -xzf "${_archive_file}" -C "${LIBSCRIPT_SOURCE_WORKDIR}"
      ;;
    *.tar.xz|*.txz)
      tar -xJf "${_archive_file}" -C "${LIBSCRIPT_SOURCE_WORKDIR}"
      ;;
    *.tar.bz2|*.tbz2)
      tar -xjf "${_archive_file}" -C "${LIBSCRIPT_SOURCE_WORKDIR}"
      ;;
    *)
      tar -xf "${_archive_file}" -C "${LIBSCRIPT_SOURCE_WORKDIR}"
      ;;
  esac

  LIBSCRIPT_EXTRACTED_SRC_DIR="$(find "${LIBSCRIPT_SOURCE_WORKDIR}" -mindepth 1 -maxdepth 1 -type d | head -n 1 || true)"
  if [ -z "${LIBSCRIPT_EXTRACTED_SRC_DIR}" ]; then
    LIBSCRIPT_EXTRACTED_SRC_DIR="${LIBSCRIPT_SOURCE_WORKDIR}"
  fi
  export LIBSCRIPT_SOURCE_WORKDIR
  export LIBSCRIPT_EXTRACTED_SRC_DIR
}

# ## libscript_execute_source_build
# Executes the requested source build driver (autotools, cmake, make, or custom callback) and records compilation duration.
libscript_execute_source_build() {
  _drv="${1}"
  _src_dir="${2:-${LIBSCRIPT_EXTRACTED_SRC_DIR:-.}}"
  shift 2 || true

  _t_start="$(libscript_now_ms)"
  mkdir -p "${LIBSCRIPT_BUILD_TARGET_DIR}/bin" "${LIBSCRIPT_BUILD_TARGET_DIR}/lib" "${LIBSCRIPT_BUILD_TARGET_DIR}/include"

  case "${_drv}" in
    autotools)
      (
        cd "${_src_dir}"
        CC="${LIBSCRIPT_RESOLVED_CC_BIN}" CFLAGS="${LIBSCRIPT_COMPILER_CFLAGS:-} ${LIBSCRIPT_BUILD_CFLAGS:-}" LDFLAGS="${LIBSCRIPT_COMPILER_LDFLAGS:-} ${LIBSCRIPT_BUILD_LDFLAGS:-}" ./configure --prefix="${LIBSCRIPT_BUILD_TARGET_DIR}" "$@"
        make CC="${LIBSCRIPT_RESOLVED_CC_BIN}"
        make install
      )
      ;;
    cmake)
      (
        cd "${_src_dir}"
        cmake -B build -DCMAKE_INSTALL_PREFIX="${LIBSCRIPT_BUILD_TARGET_DIR}" -DCMAKE_C_COMPILER="${LIBSCRIPT_RESOLVED_CC_BIN}" "$@"
        cmake --build build
        cmake --install build
      )
      ;;
    make)
      (
        cd "${_src_dir}"
        make CC="${LIBSCRIPT_RESOLVED_CC_BIN}" PREFIX="${LIBSCRIPT_BUILD_TARGET_DIR}" "$@"
      )
      ;;
    custom)
      _custom_fn="${1}"
      shift
      "${_custom_fn}" "${_src_dir}" "$@"
      ;;
    *)
      log_error "Unknown source build driver: ${_drv}"
      return 1
      ;;
  esac

  _t_end="$(libscript_now_ms)"
  LIBSCRIPT_LAST_COMPILE_TIME_MS=$((_t_end - _t_start))
  [ "${LIBSCRIPT_LAST_COMPILE_TIME_MS}" -lt 0 ] && LIBSCRIPT_LAST_COMPILE_TIME_MS=0
  export LIBSCRIPT_LAST_COMPILE_TIME_MS
}

# ## libscript_emit_build_metrics
# Inspects a compiled artifact and atomically writes structured compilation and binary section telemetry to build-metrics.json.
libscript_emit_build_metrics() {
  _bm_comp="${1}"
  _bm_ver="${2}"
  _bm_bin_path="${3}"
  _bm_cflags="${4:-}"
  _bm_ldflags="${5:-}"
  _bm_metrics_file="${LIBSCRIPT_BUILD_TARGET_DIR}/build-metrics.json"

  mkdir -p "${LIBSCRIPT_BUILD_TARGET_DIR}"

  _bin_bytes=0
  _text_bytes=0
  _data_bytes=0
  _bss_bytes=0
  _sha256="unknown"

  if [ -f "${_bm_bin_path}" ]; then
    _bin_bytes=$(wc -c < "${_bm_bin_path}" | tr -d '[:space:]' 2>/dev/null || printf '0')
    if command -v size >/dev/null 2>&1; then
      _size_line=$(size "${_bm_bin_path}" 2>/dev/null | tail -n 1 || true)
      if [ -n "${_size_line}" ]; then
        _t_val=$(printf '%s\n' "${_size_line}" | awk '{print $1}' 2>/dev/null || printf '0')
        _d_val=$(printf '%s\n' "${_size_line}" | awk '{print $2}' 2>/dev/null || printf '0')
        _b_val=$(printf '%s\n' "${_size_line}" | awk '{print $3}' 2>/dev/null || printf '0')
        case "${_t_val}" in ''|*[!0-9]*) _t_val=0 ;; esac
        case "${_d_val}" in ''|*[!0-9]*) _d_val=0 ;; esac
        case "${_b_val}" in ''|*[!0-9]*) _b_val=0 ;; esac
        _text_bytes="${_t_val}"
        _data_bytes="${_d_val}"
        _bss_bytes="${_b_val}"
      fi
    fi
    if command -v sha256sum >/dev/null 2>&1; then
      _sha256=$(sha256sum "${_bm_bin_path}" | awk '{print $1}')
    elif command -v shasum >/dev/null 2>&1; then
      _sha256=$(shasum -a 256 "${_bm_bin_path}" | awk '{print $1}')
    fi
  fi

  _safe_cc_ver=$(printf '%s' "${LIBSCRIPT_RESOLVED_CC_VERSION:-unknown}" | tr '"' "'" | tr -d '

')
  _safe_cflags=$(printf '%s' "${_bm_cflags}" | tr '"' "'" | tr -d '

')
  _safe_ldflags=$(printf '%s' "${_bm_ldflags}" | tr '"' "'" | tr -d '

')
  _ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || printf '2026-10-15T00:00:00Z')

  cat <<EOF > "${_bm_metrics_file}.tmp"
{
  "component": "${_bm_comp}",
  "version": "${_bm_ver}",
  "compiler_id": "${LIBSCRIPT_RESOLVED_CC_ID:-default}",
  "compiler_bin": "${LIBSCRIPT_RESOLVED_CC_BIN:-cc}",
  "compiler_version": "${_safe_cc_ver}",
  "cflags": "${_safe_cflags}",
  "ldflags": "${_safe_ldflags}",
  "compile_time_ms": ${LIBSCRIPT_LAST_COMPILE_TIME_MS:-0},
  "binary_path": "${_bm_bin_path}",
  "binary_size_bytes": ${_bin_bytes},
  "text_size_bytes": ${_text_bytes},
  "data_size_bytes": ${_data_bytes},
  "bss_size_bytes": ${_bss_bytes},
  "sha256": "${_sha256}",
  "timestamp": "${_ts}"
}
EOF
  mv -f "${_bm_metrics_file}.tmp" "${_bm_metrics_file}"
}
