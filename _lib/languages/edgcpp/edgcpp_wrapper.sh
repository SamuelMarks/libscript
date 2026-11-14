#!/bin/sh
# ## Overview
# Hardened CC/CXX compiler driver wrapper and telemetry shim for the EDG C/C++ Compiler Frontend (edgcpp v7.0.1). Supports EDG-FE-ONLY, EDG-LLVM, EDG-GCC, EDG-C-LEGACY, and EDG-CPP-LEGACY without triggering the --gcc CLI trap.
# ## Usage
# ./_lib/languages/edgcpp/edgcpp_wrapper.sh [compiler_args...]
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
  *) ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

if [ -z "${UNAME:-}" ] || [ -z "${ARCH:-}" ] || [ -z "${UNAME_LOWER:-}" ] || [ -z "${UNAME_A:-}" ]; then
  _edgw_oi_this="${THIS_FILE}"
  _edgw_oi_dir="${SCRIPT_DIR}"
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/os_info.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}" 2>/dev/null
  unset SCRIPT_NAME || true
  THIS_FILE="${_edgw_oi_this}"
  SCRIPT_DIR="${_edgw_oi_dir}"
  unset _edgw_oi_this _edgw_oi_dir || true
fi

# ## now_ms
# Returns a monotonic or epoch timestamp in integer milliseconds.
now_ms() {
  if [ -x "${LIBSCRIPT_ROOT_DIR}/build/.bench_probe/libscript_bench_probe" ]; then
    _ns=$("${LIBSCRIPT_ROOT_DIR}/build/.bench_probe/libscript_bench_probe" --now-ns 2>/dev/null || printf '')
    if [ -n "${_ns}" ]; then
      awk -v n="${_ns}" 'BEGIN { printf "%.0f\n", (n + 0) / 1000000.0 }'
      return 0
    fi
  fi
  if [ -r /proc/uptime ]; then
    awk '{printf "%d\n", $1 * 1000}' /proc/uptime 2>/dev/null && return 0
  fi
  _s=$(date +%s 2>/dev/null || printf '0')
  printf '%s000\n' "${_s}"
}

# ## resolve_edgcpp_binaries
# Locates cpfe, cpfe-cp, libedg.a, active codegen backend mode, CLI dialect style, and matched host C/C++ compiler executables.
resolve_edgcpp_binaries() {
  _req_flavor="${EDGCPP_FLAVOR:-${EDGCPP_INSTALLED_FLAVOR:-}}"
  _inv_name="${0##*/}"
  case "${_inv_name}" in
    *fe-only*)
      EDGCPP_BACKEND_MODE="${EDGCPP_BACKEND_MODE:-fe_only}"
      ;;
    *cp-be*)
      EDGCPP_BACKEND_MODE="${EDGCPP_BACKEND_MODE:-cpp_backend}"
      ;;
    *gcc-be*|*edgcpp-gcc*)
      [ -z "${_req_flavor}" ] && _req_flavor="edgcpp+gcc"
      EDGCPP_BACKEND_MODE="${EDGCPP_BACKEND_MODE:-gcc_backend}"
      ;;
    *llvm-be*|*edgcpp-llvm*)
      [ -z "${_req_flavor}" ] && _req_flavor="edgcpp+llvm"
      EDGCPP_BACKEND_MODE="${EDGCPP_BACKEND_MODE:-llvm_backend}"
      ;;
    *edgcpp-c-be*|*edgcpp-legacy*)
      [ -z "${_req_flavor}" ] && _req_flavor="edgcpp+llvm+gcc"
      EDGCPP_BACKEND_MODE="${EDGCPP_BACKEND_MODE:-c_backend}"
      ;;
  esac
  EDGCPP_ACTIVE_FLAVOR="${_req_flavor:-edgcpp+llvm+gcc}"

  _edg_base="${LIBSCRIPT_HOME:-$HOME/.libscript}/edgcpp"
  if [ -n "${EDG_REPO:-}" ] && [ -x "${EDG_REPO}/build-rel/src/cpfe" ] && [ -z "${EDGCPP_HOME:-}" ] && [ -z "${CPFE_BIN:-}" ]; then
    _edg_home="${EDG_REPO}/build-rel"
  elif [ -n "${EDGCPP_SOURCE_DIR:-}" ] && [ -x "${EDGCPP_SOURCE_DIR}/build-rel/src/cpfe" ] && [ -z "${EDGCPP_HOME:-}" ] && [ -z "${CPFE_BIN:-}" ]; then
    _edg_home="${EDGCPP_SOURCE_DIR}/build-rel"
  elif [ -n "${EDGCPP_HOME:-}" ] && [ -d "${EDGCPP_HOME}" ]; then
    _edg_home="${EDGCPP_HOME}"
  elif [ -n "${_req_flavor}" ] && [ -d "${_edg_base}/${_req_flavor}" ]; then
    _edg_home="${_edg_base}/${_req_flavor}"
  elif [ -n "${_req_flavor}" ] && [ -d "${_edg_base}/7.0.1-${_req_flavor}" ]; then
    _edg_home="${_edg_base}/7.0.1-${_req_flavor}"
  elif [ -d "${_edg_base}/default" ]; then
    _edg_home="${_edg_base}/default"
  elif [ -d "${_edg_base}/7.0.1" ]; then
    _edg_home="${_edg_base}/7.0.1"
  else
    _edg_home="${_edg_base}/default"
  fi
  EDGCPP_RESOLVED_HOME="${_edg_home}"

  if [ -d "${_edg_home}/lib" ]; then
    export LD_LIBRARY_PATH="${_edg_home}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
    if [ -f "${_edg_home}/lib/libedg_el9_compat.so" ]; then
      export LD_PRELOAD="${_edg_home}/lib/libedg_el9_compat.so${LD_PRELOAD:+:${LD_PRELOAD}}"
    fi
  fi

  if [ -n "${CPFE_BIN:-}" ] && [ -x "${CPFE_BIN}" ]; then
    EDGCPP_RESOLVED_CPFE="${CPFE_BIN}"
  elif [ -x "${_edg_home}/src/cpfe" ]; then
    EDGCPP_RESOLVED_CPFE="${_edg_home}/src/cpfe"
  elif [ -x "${_edg_home}/bin/cpfe" ]; then
    EDGCPP_RESOLVED_CPFE="${_edg_home}/bin/cpfe"
  else
    EDGCPP_RESOLVED_CPFE="$(command -v cpfe 2>/dev/null || true)"
  fi

  if [ -n "${CPFE_CP_BIN:-}" ] && [ -x "${CPFE_CP_BIN}" ]; then
    EDGCPP_RESOLVED_CPFE_CP="${CPFE_CP_BIN}"
  elif [ -x "${_edg_home}/src/cmake/cpfe-cp/cpfe-cp" ]; then
    EDGCPP_RESOLVED_CPFE_CP="${_edg_home}/src/cmake/cpfe-cp/cpfe-cp"
  elif [ -x "${_edg_home}/bin/cpfe-cp" ]; then
    EDGCPP_RESOLVED_CPFE_CP="${_edg_home}/bin/cpfe-cp"
  else
    EDGCPP_RESOLVED_CPFE_CP="$(command -v cpfe-cp 2>/dev/null || true)"
  fi
  export EDGCPP_RESOLVED_CPFE_CP

  _rt_lib="${EDG_RT_LIB:-${EDGCPP_RT_LIB:-}}"
  if [ -z "${_rt_lib}" ]; then
    if [ -f "${_edg_home}/lib_src/libedg.a" ]; then
      _rt_lib="${_edg_home}/lib_src/libedg.a"
    elif [ -f "${_edg_home}/lib/libedg.a" ]; then
      _rt_lib="${_edg_home}/lib/libedg.a"
    fi
  fi
  RESOLVED_EDG_RT_LIB="${_rt_lib}"

  _raw_be_mode="${EDG_BACKEND:-${LLVM_BACKEND_OR_GCC_BACKEND:-${EDGCPP_BACKEND_MODE:-}}}"
  if [ -z "${_raw_be_mode}" ]; then
    case "${EDGCPP_ACTIVE_FLAVOR}" in
      *+gcc)
        case "${EDGCPP_ACTIVE_FLAVOR}" in
          *llvm*) _raw_be_mode="llvm_backend" ;;
          *) _raw_be_mode="gcc_backend" ;;
        esac
        ;;
      *)
        _raw_be_mode='llvm_backend'
        ;;
    esac
  fi
  case "${_raw_be_mode}" in
    fe-only|fe_only|EDG-FE-ONLY)
      EDGCPP_ACTIVE_CODEGEN_BACKEND='fe_only'
      SHORT_BACKEND_NAME='fe-only'
      ;;
    cpp|cpp-be|cp-be|cp_gen_be|cpp_backend|EDG-CPP-LEGACY)
      EDGCPP_ACTIVE_CODEGEN_BACKEND='cpp_backend'
      SHORT_BACKEND_NAME='cpp'
      ;;
    c|c-be|c_gen_be|c_backend|legacy|EDG-LEGACY|EDG-C-LEGACY)
      EDGCPP_ACTIVE_CODEGEN_BACKEND='c_backend'
      SHORT_BACKEND_NAME='c'
      ;;
    gcc|gcc-be|gcc_gen_be|gcc_backend|EDG-GCC)
      EDGCPP_ACTIVE_CODEGEN_BACKEND='gcc_backend'
      SHORT_BACKEND_NAME='gcc'
      ;;
    *)
      EDGCPP_ACTIVE_CODEGEN_BACKEND='llvm_backend'
      SHORT_BACKEND_NAME='llvm'
      ;;
  esac

  _drv_lang="${EDGCPP_DRIVER_LANG:-c}"
  case "${_inv_name}" in
    *++*|*cxx*) _drv_lang="c++" ;;
  esac
  EDGCPP_ACTIVE_LANG="${_drv_lang}"

  _host_cc_pref="${EDG_HOST_CC:-${CLANG_MATCHED:-${EDGCPP_BACKEND_CC:-}}}"
  _host_cxx_pref="${EDG_HOST_CXX:-${CLANGXX_MATCHED:-${EDGCPP_BACKEND_CXX:-}}}"
  if [ "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" = "gcc_backend" ]; then
    _host_cc_pref="${EDG_HOST_CC:-${GCC_MATCHED:-${_host_cc_pref}}}"
    _host_cxx_pref="${EDG_HOST_CXX:-${GXX_MATCHED:-${_host_cxx_pref}}}"
  fi

  if [ "${_drv_lang}" = "c++" ]; then
    if [ -n "${_host_cxx_pref}" ] && { [ -x "${_host_cxx_pref}" ] || command -v "${_host_cxx_pref}" >/dev/null 2>&1; }; then
      EDGCPP_RESOLVED_BACKEND="$(command -v "${_host_cxx_pref}" 2>/dev/null || printf '%s' "${_host_cxx_pref}")"
    elif command -v clang++ >/dev/null 2>&1; then
      EDGCPP_RESOLVED_BACKEND="$(command -v clang++)"
    elif command -v g++ >/dev/null 2>&1; then
      EDGCPP_RESOLVED_BACKEND="$(command -v g++)"
    else
      EDGCPP_RESOLVED_BACKEND="$(command -v c++ 2>/dev/null || printf '/usr/bin/c++')"
    fi
  else
    if [ -n "${_host_cc_pref}" ] && { [ -x "${_host_cc_pref}" ] || command -v "${_host_cc_pref}" >/dev/null 2>&1; }; then
      EDGCPP_RESOLVED_BACKEND="$(command -v "${_host_cc_pref}" 2>/dev/null || printf '%s' "${_host_cc_pref}")"
    elif command -v clang >/dev/null 2>&1; then
      EDGCPP_RESOLVED_BACKEND="$(command -v clang)"
    elif command -v gcc >/dev/null 2>&1; then
      EDGCPP_RESOLVED_BACKEND="$(command -v gcc)"
    else
      EDGCPP_RESOLVED_BACKEND="$(command -v cc 2>/dev/null || printf '/usr/bin/cc')"
    fi
  fi
  if [ "${UNAME:-}" = "Darwin" ] && command -v otool >/dev/null 2>&1 && command -v install_name_tool >/dev/null 2>&1 && [ -f '/opt/homebrew/opt/z3/lib/libz3.dylib' ]; then
    for _m_bin in "${EDGCPP_RESOLVED_CPFE:-}" "${EDGCPP_RESOLVED_CPFE_CP:-}"; do
      if [ -n "${_m_bin}" ] && [ -w "${_m_bin}" ]; then
        _bad_z3=$(otool -L "${_m_bin}" 2>/dev/null | awk '/libz3\.[0-9.]+\.dylib/ {print $1}' || true)
        for _zdep in ${_bad_z3}; do
          if [ ! -f "${_zdep}" ]; then
            install_name_tool -change "${_zdep}" '/opt/homebrew/opt/z3/lib/libz3.dylib' "${_m_bin}" 2>/dev/null || true
            if command -v codesign >/dev/null 2>&1; then
              codesign -f -s - "${_m_bin}" >/dev/null 2>&1 || true
            fi
          fi
        done
      fi
    done
  fi
}

# ## detect_cpfe_cli_style
# Determines once per cpfe binary whether unified v7.0.1 `--backend=llvm --emit-obj=` (`multibackend`) or release `--llvm-be --gen_obj_file_name=` (`release`) flags are supported.
detect_cpfe_cli_style() {
  if [ -n "${EDG_CPFE_CLI_STYLE:-}" ]; then
    CPFE_CLI_STYLE="${EDG_CPFE_CLI_STYLE}"
    return 0
  fi
  CPFE_CLI_STYLE='release'
  if [ -z "${EDGCPP_RESOLVED_CPFE:-}" ] || [ ! -x "${EDGCPP_RESOLVED_CPFE}" ]; then
    return 0
  fi
  _style_cache_dir="${LIBSCRIPT_CACHE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache}/edgcpp"
  mkdir -p "${_style_cache_dir}"
  _bin_key=$(printf '%s' "${EDGCPP_RESOLVED_CPFE}" | cksum | awk '{print $1 "_" $2}')
  _style_file="${_style_cache_dir}/cli_style_${_bin_key}.txt"
  if [ -f "${_style_file}" ] && [ ! "${EDGCPP_RESOLVED_CPFE}" -nt "${_style_file}" ]; then
    CPFE_CLI_STYLE=$(cat "${_style_file}" 2>/dev/null || printf 'release')
    return 0
  fi
  _help_out=$("${EDGCPP_RESOLVED_CPFE}" --help < /dev/null 2>&1 || true)
  if printf '%s\n' "${_help_out}" | grep -qE -- '--backend=|--emit-obj'; then
    CPFE_CLI_STYLE='multibackend'
  else
    CPFE_CLI_STYLE='release'
  fi
  printf '%s\n' "${CPFE_CLI_STYLE}" > "${_style_file}.tmp" 2>/dev/null && mv -f "${_style_file}.tmp" "${_style_file}" 2>/dev/null || true
}

# ## discover_system_includes
# Queries the matched host compiler once per `(compiler, lang, sdkroot, cli_style)` tuple for default `-isystem` search paths and caches `--sys_include` / `-I` flags idempotently.
discover_system_includes() {
  _dsi_lang="${1}"
  if [ "${IS_NOSTDINC}" = "1" ]; then
    DISCOVERED_SYS_INC_FLAGS=""
    return 0
  fi
  _dsi_cc="${EDGCPP_RESOLVED_BACKEND}"
  _dsi_sdk="${SDKROOT:-}"
  if [ -z "${_dsi_sdk}" ] && [ "${UNAME:-}" = "Darwin" ] && command -v xcrun >/dev/null 2>&1; then
    _dsi_sdk="$(xcrun --show-sdk-path 2>/dev/null || true)"
  fi
  _cache_dir="${LIBSCRIPT_CACHE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache}/edgcpp"
  mkdir -p "${_cache_dir}"
  _key=$(printf '%s|%s|%s|%s' "${_dsi_cc}" "${_dsi_lang}" "${_dsi_sdk}" "${CPFE_CLI_STYLE}" | cksum | awk '{print $1 "_" $2}')
  _cache_file="${_cache_dir}/sysinc_${_key}.flags"
  if [ -f "${_cache_file}" ]; then
    DISCOVERED_SYS_INC_FLAGS=$(cat "${_cache_file}" 2>/dev/null || printf '')
    return 0
  fi

  _probe_out=$("${_dsi_cc}" -E -x "${_dsi_lang}" - -v < /dev/null 2>&1 || true)
  _inc_list=$(printf '%s\n' "${_probe_out}" | awk '
    /#include <\.\.\.> search starts here:/ { in_blk = 1; next }
    /End of search list\./ { in_blk = 0 }
    in_blk {
      line = $0
      sub(/^[[:space:]]+/, "", line)
      sub(/[[:space:]]+$/, "", line)
      if (line != "" && line !~ /\(framework directory\)$/) {
        print line
      }
    }
  ')
  _built=""
  _old_ifs="${IFS}"
  IFS='
'
  for _d in ${_inc_list}; do
    if [ -d "${_d}" ]; then
      if [ "${CPFE_CLI_STYLE}" = "multibackend" ]; then
        _built="${_built} --sys_include ${_d}"
      else
        _built="${_built} -I${_d}"
      fi
    fi
  done
  IFS="${_old_ifs}"
  DISCOVERED_SYS_INC_FLAGS="${_built# }"
  printf '%s\n' "${DISCOVERED_SYS_INC_FLAGS}" > "${_cache_file}.tmp" 2>/dev/null && mv -f "${_cache_file}.tmp" "${_cache_file}" 2>/dev/null || true
}

# ## configure_gccjit_library_path
# Populates LIBRARY_PATH and EDG_LIBGCCJIT_PATH for libgccjit so internal crt/emutls objects resolve during --backend=gcc / --gcc-be compilation.
configure_gccjit_library_path() {
  _extra_lib_path=""
  if [ -d "/opt/homebrew/lib/gcc/current" ]; then
    _emutls_dir="$(find /opt/homebrew/lib/gcc/current -name 'libemutls_w.a' -exec dirname {} \; 2>/dev/null | head -n 1 || true)"
    if [ -n "${_emutls_dir}" ]; then
      _extra_lib_path="${_emutls_dir}:/opt/homebrew/lib/gcc/current"
    else
      _extra_lib_path='/opt/homebrew/lib/gcc/current'
    fi
    if [ -z "${EDG_LIBGCCJIT_PATH:-}" ] && [ -f '/opt/homebrew/lib/gcc/current/libgccjit.0.dylib' ]; then
      export EDG_LIBGCCJIT_PATH='/opt/homebrew/lib/gcc/current/libgccjit.0.dylib'
    fi
    _mac_sdk="$(xcrun --show-sdk-path 2>/dev/null || true)"
    if [ -n "${_mac_sdk}" ] && [ -d "${_mac_sdk}/usr/lib" ]; then
      _extra_lib_path="${_extra_lib_path}:${_mac_sdk}/usr/lib"
    fi
  elif [ -d "/usr/lib/gcc" ]; then
    _gcc_crt_dir="$(find /usr/lib/gcc -name 'crtbegin.o' -exec dirname {} \; 2>/dev/null | head -n 1 || true)"
    if [ -n "${_gcc_crt_dir}" ]; then
      _extra_lib_path="${_gcc_crt_dir}"
    fi
    if [ -z "${EDG_LIBGCCJIT_PATH:-}" ]; then
      for _cand_jit in /usr/lib/x86_64-linux-gnu/libgccjit.so.0 /usr/lib/aarch64-linux-gnu/libgccjit.so.0 /usr/lib64/libgccjit.so.0 /usr/lib/libgccjit.so.0; do
        if [ -f "${_cand_jit}" ]; then
          export EDG_LIBGCCJIT_PATH="${_cand_jit}"
          break
        fi
      done
    fi
  fi
  if [ -n "${_extra_lib_path}" ]; then
    export LIBRARY_PATH="${_extra_lib_path}${LIBRARY_PATH:+:${LIBRARY_PATH}}"
  fi
}

# ## emit_depfile_via_host_preprocessor
# Emits Makefile/Ninja `.d` dependency files via the matched host compiler when `-MD` or `-MMD` flags accompany `-c` (`EXPERIMENTS.md` §11).
emit_depfile_via_host_preprocessor() {
  if [ "${HAS_DEP_SIDE_EFFECT}" != "1" ]; then
    return 0
  fi
  _has_mf=0
  for _da in "$@"; do
    case "${_da}" in
      -MF|-MF*|-Wp,-MF*) _has_mf=1 ;;
    esac
  done
  _first_d=1
  _skip_d=0
  for _da in "$@"; do
    if [ "${_first_d}" = "1" ]; then
      set --
      _first_d=0
    fi
    if [ "${_skip_d}" = "1" ]; then
      _skip_d=0
      continue
    fi
    case "${_da}" in
      -c|--llvm|--llvm-be|--llvm_gen_be|--gcc|--gcc-be|--gcc_gen_be|--c-be|--c_gen_be|--legacy|--fno-tbaa)
        ;;
      -o)
        _skip_d=1
        ;;
      -o*)
        ;;
      -MD)
        set -- "$@" "-M"
        ;;
      -MMD)
        set -- "$@" "-MM"
        ;;
      -Wp,-MD,*)
        _dep_rest="${_da#-Wp,-MD,}"
        set -- "$@" "-M" "-MF" "${_dep_rest}"
        _has_mf=1
        ;;
      -Wp,-MMD,*)
        _dep_rest="${_da#-Wp,-MMD,}"
        set -- "$@" "-MM" "-MF" "${_dep_rest}"
        _has_mf=1
        ;;
      *)
        set -- "$@" "${_da}"
        ;;
    esac
  done
  if [ "${_has_mf}" = "0" ]; then
    _def_d=""
    if [ -n "${WRAPPER_OUTPUT_FILE}" ]; then
      _def_d="${WRAPPER_OUTPUT_FILE%.*}.d"
    elif [ -n "${WRAPPER_SOURCE_FILE}" ]; then
      _base_s="${WRAPPER_SOURCE_FILE##*/}"
      _def_d="${_base_s%.*}.d"
    fi
    if [ -n "${_def_d}" ]; then
      set -- "$@" "-MF" "${_def_d}"
    fi
  fi
  "${EDGCPP_RESOLVED_BACKEND}" "$@" >/dev/null 2>&1 || true
}

# ## record_edgcpp_event
# Appends atomic single-line JSONL compilation telemetry to `EDGCPP_LOG_FILE` and `EDG_DRIVER_LOG`.
record_edgcpp_event() {
  _ev_src="${1:-unknown}"
  _ev_cpfe_rc="${2:-0}"
  _ev_be_rc="${3:-0}"
  _ev_fb="${4:-false}"
  _ev_ms="${5:-1}"
  _ev_mode="${6:-c}"
  _ev_nb_rc="${7:-0}"
  _ev_rss_kb="${8:-0}"
  _ev_be_kind="${9:-${EDGCPP_ACTIVE_CODEGEN_BACKEND:-llvm_backend}}"
  _ev_dialect="${10:-${CPFE_STD_DIALECT:-c11}}"
  _ev_kmode="${11:-false}"
  _ev_fe_ms="${PHASE_FE_MS:-0}"
  _ev_il_ms="${PHASE_IL_MS:-0}"
  _ev_be_ms="${PHASE_BE_MS:-0}"
  _ev_cg_ms="${PHASE_CG_MS:-0}"
  _ev_flavor="${EDGCPP_ACTIVE_FLAVOR:-edgcpp+llvm+gcc}"
  _ev_diag="${LAST_FAILURE_LOG_PATH:-}"
  _ev_repro="${LAST_REPRODUCER_DIR:-}"
  _log_file="${EDGCPP_LOG_FILE:-${LIBSCRIPT_HOME:-$HOME/.libscript}/edgcpp/compile_events.jsonl}"
  mkdir -p "$(dirname -- "${_log_file}")"
  _safe_src=$(printf '%s' "${_ev_src}" | tr '"' "'" | tr -d '[:cntrl:]')
  _safe_diag=$(printf '%s' "${_ev_diag}" | tr '"' "'" | tr -d '[:cntrl:]')
  _safe_repro=$(printf '%s' "${_ev_repro}" | tr '"' "'" | tr -d '[:cntrl:]')
  printf '{"source":"%s","lang":"%s","std_dialect":"%s","opt":"%s","kernel_mode":%s,"edgcpp_flavor":"%s","llvm_backend_or_gcc_backend":"%s","cpfe_exit_code":%s,"native_backend_exit_code":%s,"exit_code":%s,"fallback":%s,"elapsed_ms":%s,"fe_ms":%s,"lower_il_ms":%s,"be_ms":%s,"codegen_ms":%s,"fe_cpu_s":%s,"be_cpu_s":%s,"peak_rss_kb":%s,"diagnostic_log":"%s","reproducer_dir":"%s"}\n' "${_safe_src}" "${_ev_mode}" "${_ev_dialect}" "${ACTIVE_OPT_FLAG}" "${_ev_kmode}" "${_ev_flavor}" "${_ev_be_kind}" "${_ev_cpfe_rc}" "${_ev_nb_rc}" "${_ev_be_rc}" "${_ev_fb}" "${_ev_ms}" "${_ev_fe_ms}" "${_ev_il_ms}" "${_ev_be_ms}" "${_ev_cg_ms}" "${PHASE_FE_CPU_S}" "${PHASE_BE_CPU_S}" "${_ev_rss_kb}" "${_safe_diag}" "${_safe_repro}" >> "${_log_file}" 2>/dev/null || true

  if [ -n "${EDG_DRIVER_LOG:-}" ]; then
    mkdir -p "$(dirname -- "${EDG_DRIVER_LOG}")"
    _wall_s=$(awk -v m="${_ev_ms}" 'BEGIN { printf "%.4f", (m + 0) / 1000.0 }')
    _rss_mb=$(awk -v k="${_ev_rss_kb}" 'BEGIN { printf "%.2f", (k + 0) / 1024.0 }')
    printf '{"backend":"%s","srcs":["%s"],"std":"%s","opt":"%s","exit_code":%s,"wall_s":%s,"fe_cpu_s":%s,"be_cpu_s":%s,"peak_rss_mb":%s}\n' "${SHORT_BACKEND_NAME}" "${_safe_src}" "${_ev_dialect}" "${ACTIVE_OPT_FLAG}" "${_ev_be_rc}" "${_wall_s}" "${PHASE_FE_CPU_S}" "${PHASE_BE_CPU_S}" "${_rss_mb}" >> "${EDG_DRIVER_LOG}" 2>/dev/null || true
  fi
}

resolve_edgcpp_binaries
detect_cpfe_cli_style

if [ "$#" -eq 1 ]; then
  case "${1}" in
    --version|-v|-V)
      if [ -n "${EDGCPP_RESOLVED_CPFE}" ] && [ -x "${EDGCPP_RESOLVED_CPFE}" ]; then
        _cpfe_ver="$("${EDGCPP_RESOLVED_CPFE}" --version < /dev/null 2>&1 | head -n 1 || true)"
        printf 'edgcpp 7.0.1 (%s; codegen=%s; cli=%s; host_backend=%s)\n' "${_cpfe_ver:-EDG C/C++ Front End v7.0.1}" "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" "${CPFE_CLI_STYLE}" "${EDGCPP_RESOLVED_BACKEND}"
      else
        printf 'edgcpp 7.0.1 (EDG C/C++ Front End wrapper; codegen=%s; host_backend=%s)\n' "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" "${EDGCPP_RESOLVED_BACKEND}"
      fi
      exit 0
      ;;
    -dumpversion)
      printf '%s\n' '7.0.1'
      exit 0
      ;;
    -dumpmachine)
      "${EDGCPP_RESOLVED_BACKEND}" -dumpmachine 2>/dev/null || printf '%s-%s\n' "${ARCH:-x86_64}" "${UNAME_LOWER:-linux}"
      exit 0
      ;;
  esac
fi

WRAPPER_SOURCE_FILE=""
WRAPPER_OUTPUT_FILE=""
CPFE_STD_FLAG='--c11'
CPFE_STD_DIALECT='c11'
GNU_VER_FLAG="--gnu_version=${EDGCPP_GNU_VERSION:-130200}"
ACTIVE_OPT_FLAG='-O0'
HAS_SOURCE_FILE=0
SOURCE_COUNT=0
IS_COMPILE_ONLY=0
IS_PREPROCESS_ONLY=0
IS_DEP_ONLY=0
HAS_DEP_SIDE_EFFECT=0
IS_NOSTDINC=0
IS_KERNEL_MODE=0
LAST_PEAK_RSS_KB=0
NATIVE_BACKEND_RC=0
NATIVE_OBJ_PRODUCED=0
PHASE_FE_MS=0
PHASE_IL_MS=0
PHASE_BE_MS=0
PHASE_CG_MS=0
PHASE_FE_CPU_S='0.0000'
PHASE_BE_CPU_S='0.0000'
DISCOVERED_SYS_INC_FLAGS=""
LAST_FAILURE_LOG_PATH=""
LAST_REPRODUCER_DIR=""
SAVED_DRIVER_ARGS="$*"

if [ "${EDGCPP_ACTIVE_LANG}" = "c++" ]; then
  CPFE_STD_FLAG='--c++17'
  CPFE_STD_DIALECT='c++17'
fi

# ## inspect_driver_args
# Inspects compiler driver flags to identify translation units, output path, language dialect, optimization level, dependency flags, and freestanding kernel mode.
inspect_driver_args() {
  _expect_next=""
  for _arg in "$@"; do
    if [ -n "${_expect_next}" ]; then
      if [ "${_expect_next}" = "-o" ]; then
        WRAPPER_OUTPUT_FILE="${_arg}"
      fi
      _expect_next=""
      continue
    fi
    case "${_arg}" in
      --fe-only)
        EDGCPP_ACTIVE_CODEGEN_BACKEND='fe_only'
        SHORT_BACKEND_NAME='fe-only'
        ;;
      --llvm|--llvm-be|--llvm_gen_be|--backend=llvm)
        EDGCPP_ACTIVE_CODEGEN_BACKEND='llvm_backend'
        SHORT_BACKEND_NAME='llvm'
        ;;
      --gcc|--gcc-be|--gcc_gen_be|--backend=gcc)
        EDGCPP_ACTIVE_CODEGEN_BACKEND='gcc_backend'
        SHORT_BACKEND_NAME='gcc'
        ;;
      --c-be|--c_gen_be|--legacy|--backend=c)
        EDGCPP_ACTIVE_CODEGEN_BACKEND='c_backend'
        SHORT_BACKEND_NAME='c'
        ;;
      --cp-be|--cpp-be|--cp_gen_be|--backend=cpp)
        EDGCPP_ACTIVE_CODEGEN_BACKEND='cpp_backend'
        SHORT_BACKEND_NAME='cpp'
        ;;
      -o) _expect_next="-o" ;;
      -MF|-MT|-MQ|-I|-D|-U|-isystem|-include|-imacros) _expect_next="${_arg}" ;;
      -o*) WRAPPER_OUTPUT_FILE="${_arg#-o}" ;;
      -c) IS_COMPILE_ONLY=1 ;;
      -E) IS_PREPROCESS_ONLY=1 ;;
      -M|-MM) IS_DEP_ONLY=1 ;;
      -MD|-MMD|-Wp,-MD*|-Wp,-MMD*) HAS_DEP_SIDE_EFFECT=1 ;;
      -O0|-O1|-O2|-O3|-Os|-Oz|-Ofast) ACTIVE_OPT_FLAG="${_arg}" ;;
      -nostdinc)
        IS_NOSTDINC=1
        IS_KERNEL_MODE=1
        ;;
      -ffreestanding|-D__KERNEL__|-D__KERNEL__=*)
        IS_KERNEL_MODE=1
        ;;
      -std=gnu89)
        CPFE_STD_FLAG='--c89'
        CPFE_STD_DIALECT='gnu89'
        ;;
      -std=c89|-std=c90|-ansi)
        CPFE_STD_FLAG='--c89'
        CPFE_STD_DIALECT='c89'
        ;;
      -std=gnu99)
        CPFE_STD_FLAG='--c99'
        CPFE_STD_DIALECT='gnu99'
        ;;
      -std=c99)
        CPFE_STD_FLAG='--c99'
        CPFE_STD_DIALECT='c99'
        ;;
      -std=gnu11|-std=gnu17|-std=gnu2x)
        CPFE_STD_FLAG='--c11'
        CPFE_STD_DIALECT='gnu11'
        ;;
      -std=c11|-std=c17|-std=c23|-std=c2x)
        CPFE_STD_FLAG='--c11'
        CPFE_STD_DIALECT='c11'
        ;;
      -std=c++11|-std=gnu++11)
        EDGCPP_ACTIVE_LANG='c++'
        CPFE_STD_FLAG='--c++11'
        CPFE_STD_DIALECT='c++11'
        ;;
      -std=c++14|-std=gnu++14)
        EDGCPP_ACTIVE_LANG='c++'
        CPFE_STD_FLAG='--c++14'
        CPFE_STD_DIALECT='c++14'
        ;;
      -std=c++17|-std=gnu++17)
        EDGCPP_ACTIVE_LANG='c++'
        CPFE_STD_FLAG='--c++17'
        CPFE_STD_DIALECT='c++17'
        ;;
      -std=c++20|-std=gnu++20|-std=c++2a|-std=gnu++2a)
        EDGCPP_ACTIVE_LANG='c++'
        CPFE_STD_FLAG='--c++20'
        CPFE_STD_DIALECT='c++20'
        ;;
      -std=c++23|-std=gnu++23|-std=c++2b|-std=gnu++2b)
        EDGCPP_ACTIVE_LANG='c++'
        CPFE_STD_FLAG='--c++20'
        CPFE_STD_DIALECT='c++23'
        ;;
      *.cc|*.cpp|*.cxx|*.C)
        WRAPPER_SOURCE_FILE="${_arg}"
        HAS_SOURCE_FILE=1
        SOURCE_COUNT=$((SOURCE_COUNT + 1))
        if [ "${EDGCPP_ACTIVE_LANG}" != "c++" ]; then
          EDGCPP_ACTIVE_LANG='c++'
          resolve_edgcpp_binaries
          EDGCPP_ACTIVE_LANG='c++'
        fi
        case "${CPFE_STD_FLAG}" in
          --c++*) ;;
          *)
            CPFE_STD_FLAG='--c++17'
            CPFE_STD_DIALECT='c++17'
            ;;
        esac
        ;;
      *.c)
        WRAPPER_SOURCE_FILE="${_arg}"
        HAS_SOURCE_FILE=1
        SOURCE_COUNT=$((SOURCE_COUNT + 1))
        ;;
    esac
  done
}

# ## run_with_rss_probe
# Executes a command, captures stdout/stderr to `$1`, and extracts peak RSS in KiB plus optional `cpfe --timing` phase CPU seconds.
run_with_rss_probe() {
  _capture_file="${1}"
  shift
  _cmd_rc=0
  : > "${_capture_file}"
  _probe_bin="${LIBSCRIPT_ROOT_DIR}/build/.bench_probe/libscript_bench_probe"
  if [ -x "${_probe_bin}" ]; then
    _prb_json="${TMPDIR:-/tmp}/edgcpp_prb_$$.json"
    "${_probe_bin}" --json-out "${_prb_json}" --stdout-file "${_capture_file}.out" --stderr-file "${_capture_file}" --exec "$@" || _cmd_rc=$?
    if [ -s "${_capture_file}.out" ]; then
      cat "${_capture_file}.out" >> "${_capture_file}"
    fi
    rm -f "${_capture_file}.out"
    if [ -f "${_prb_json}" ]; then
      _p_bytes=$(awk -F: '/"peak_rss_bytes"/ {gsub(/[^0-9]/, "", $2); print $2+0}' "${_prb_json}" 2>/dev/null || printf '0')
      if [ "${_p_bytes}" -gt 0 ] 2>/dev/null; then
        LAST_PEAK_RSS_KB=$((_p_bytes / 1024))
      fi
      rm -f "${_prb_json}"
    fi
  elif [ -x "/usr/bin/time" ]; then
    _rss_tmp="${TMPDIR:-/tmp}/edgcpp_rss_$$.log"
    case "${UNAME:-}" in
      Darwin*)
        /usr/bin/time -l "$@" >"${_capture_file}" 2>"${_rss_tmp}" || _cmd_rc=$?
        _bytes=$(awk '/maximum resident set size/ {print $1}' "${_rss_tmp}" 2>/dev/null | head -n 1 || printf '0')
        case "${_bytes}" in ''|*[!0-9]*) _bytes=0 ;; esac
        [ "${_bytes}" -gt 0 ] && LAST_PEAK_RSS_KB=$((_bytes / 1024))
        grep -vE '^[[:space:]]*[0-9]+(\.[0-9]+)?[[:space:]]+(real|user|sys|maximum|average|unshared|page|block|voluntary|involuntary|swaps|messages|signals|context|instructions|cycles|peak)' "${_rss_tmp}" >> "${_capture_file}" 2>/dev/null || true
        ;;
      *)
        /usr/bin/time -v "$@" >"${_capture_file}" 2>"${_rss_tmp}" || _cmd_rc=$?
        _kb=$(awk -F: '/Maximum resident set size/ {gsub(/[^0-9]/, "", $2); print $2}' "${_rss_tmp}" 2>/dev/null | head -n 1 || printf '0')
        case "${_kb}" in ''|*[!0-9]*) _kb=0 ;; esac
        [ "${_kb}" -gt 0 ] && LAST_PEAK_RSS_KB="${_kb}"
        grep -vE '^[[:space:]]*(Command being timed|User time|System time|Percent of CPU|Elapsed \(wall clock\)|Average shared|Average unshared|Average stack|Average total|Maximum resident|Average resident|Major \(requiring|Minor \(reclaiming|Voluntary context|Involuntary context|Swaps:|File system|Socket messages|Signals delivered|Page size|Exit status:)' "${_rss_tmp}" >> "${_capture_file}" 2>/dev/null || true
        ;;
    esac
    rm -f "${_rss_tmp}" 2>/dev/null || true
  else
    "$@" >"${_capture_file}" 2>&1 || _cmd_rc=$?
  fi

  if [ -s "${_capture_file}" ]; then
    _parsed_timing=$(awk '
      BEGIN { fe = 0.0; be = 0.0; found = 0 }
      {
        l = tolower($0)
        if (l ~ /(front[ -]?end|fe_cpu_s|fe time)/) {
          for (i = 1; i <= NF; i++) { t = $i; gsub(/[^0-9.]/, "", t); if (t ~ /^[0-9]+(\.[0-9]+)?$/) { fe = t + 0; found = 1 } }
        } else if (l ~ /(back[ -]?end|be_cpu_s|be time|llvm_gen_be|gcc_gen_be|codegen)/) {
          for (i = 1; i <= NF; i++) { t = $i; gsub(/[^0-9.]/, "", t); if (t ~ /^[0-9]+(\.[0-9]+)?$/) { be = t + 0; found = 1 } }
        }
      }
      END { if (found) printf "%.4f|%.4f|%.0f|%.0f\n", fe, be, fe * 1000.0, be * 1000.0 }
    ' "${_capture_file}" 2>/dev/null || true)
    if [ -n "${_parsed_timing}" ]; then
      PHASE_FE_CPU_S="${_parsed_timing%%|*}"
      _pt_r1="${_parsed_timing#*|}"
      PHASE_BE_CPU_S="${_pt_r1%%|*}"
      _pt_r2="${_pt_r1#*|}"
      PHASE_FE_MS="${_pt_r2%%|*}"
      PHASE_BE_MS="${_pt_r2#*|}"
    fi
  fi
  return "${_cmd_rc}"
}

# ## record_edgcpp_failure_forensics
# Captures detailed cpfe front-end/backend diagnostics and a self-contained preprocessed (.i) reproducer bundle on failure.
record_edgcpp_failure_forensics() {
  _ff_src="${1}"
  _ff_fe_rc="${2}"
  _ff_be_rc="${3}"
  _ff_fe_cmd="${4}"
  _ff_be_cmd="${5}"
  _ff_fe_log="${6}"
  _ff_be_log="${7}"
  shift 7

  _fail_log="${EDGCPP_FAILURE_LOG:-${LIBSCRIPT_ROOT_DIR}/build/kernel/logs/edgcpp-failures.log}"
  _repro_root="${EDGCPP_REPRO_DIR:-${LIBSCRIPT_ROOT_DIR}/build/kernel/logs/reproducers}"
  _tu_slug="$(basename "${_ff_src}" | tr './ ' '___')"
  _kver_slug="${LINUX_VERSION:-host}"
  _flavor_slug="$(printf '%s' "${EDGCPP_ACTIVE_FLAVOR}" | tr '+' '_')"
  _repro_dir="${_repro_root}/${_tu_slug}-${_flavor_slug}-${EDGCPP_ACTIVE_CODEGEN_BACKEND}-${_kver_slug}"

  mkdir -p "$(dirname -- "${_fail_log}")" "${_repro_dir}"
  LAST_FAILURE_LOG_PATH="${_fail_log}"
  LAST_REPRODUCER_DIR="${_repro_dir}"

  _preprocessed_file="${_repro_dir}/${_tu_slug}.i"
  if [ -n "${EDGCPP_RESOLVED_BACKEND:-}" ]; then
    "${EDGCPP_RESOLVED_BACKEND}" -E -dD "$@" > "${_preprocessed_file}" 2>/dev/null || cp "${_ff_src}" "${_preprocessed_file}" 2>/dev/null || true
  else
    cp "${_ff_src}" "${_preprocessed_file}" 2>/dev/null || true
  fi

  cat <<REPRO_SH > "${_repro_dir}/repro.sh"
#!/bin/sh
# ## Overview
# Standalone reproducer script for edgcpp failure on ${_ff_src}.
# ## Usage
# ./repro.sh
set -feu
export LD_LIBRARY_PATH="${EDGCPP_RESOLVED_HOME}/lib\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}"
export LIBRARY_PATH="${LIBRARY_PATH:-}"
${_ff_fe_cmd}
${_ff_be_cmd}
REPRO_SH
  chmod +x "${_repro_dir}/repro.sh" 2>/dev/null || true

  cat <<REPRO_CMD > "${_repro_dir}/repro.cmd"
@echo off
:: # repro.cmd
:: ## Overview
:: Standalone Windows reproducer script for edgcpp failure on ${_ff_src}.
:: ## Usage
:: repro.cmd
${_ff_fe_cmd}
${_ff_be_cmd}
REPRO_CMD

  _diag_block="${_repro_dir}/diagnostic.log"
  {
    printf '================================================================================\n'
    printf 'EDGCPP FAILURE FORENSIC REPORT (%s)\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || printf 'now')"
    printf 'Active Backend      : %s (cli=%s)\n' "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" "${CPFE_CLI_STYLE}"
    printf 'CPFE Binary         : %s\n' "${EDGCPP_RESOLVED_CPFE}"
    printf 'Dialect / Opt       : %s / %s (kernel_mode=%s)\n' "${CPFE_STD_DIALECT}" "${ACTIVE_OPT_FLAG}" "${IS_KERNEL_MODE}"
    printf 'Translation Unit    : %s\n' "${_ff_src}"
    printf 'Wrapper Invocation  : %s %s\n' "${0}" "${SAVED_DRIVER_ARGS}"
    printf 'Frontend Exit Code  : %s\n' "${_ff_fe_rc}"
    printf 'Backend Exit Code   : %s\n' "${_ff_be_rc}"
    printf '1. CPFE FRONTEND COMMAND:\n  %s\n' "${_ff_fe_cmd}"
    [ -s "${_ff_fe_log}" ] && cat "${_ff_fe_log}"
    printf '2. CPFE BACKEND COMMAND:\n  %s\n' "${_ff_be_cmd}"
    [ -s "${_ff_be_log}" ] && cat "${_ff_be_log}"
    printf '================================================================================\n\n'
  } > "${_diag_block}"

  cat "${_diag_block}" >> "${_fail_log}"
  if [ "${EDGCPP_STRICT_BACKEND:-0}" = "1" ] || [ -n "${EDG_BACKEND:-}" ] || [ "${EDGCPP_VERBOSE_DIAGNOSTICS:-0}" = "1" ]; then
    cat "${_diag_block}" >&2
  fi
}

# ## run_cpfe_frontend_and_codegen
# Runs `cpfe` / `cpfe-cp` for C and C++ translation units using `--gnu_version=130200` (never `--gcc` on LLVM!) and produces real object code when supported.
run_cpfe_frontend_and_codegen() {
  if [ "${HAS_SOURCE_FILE}" = "0" ] || [ -z "${WRAPPER_SOURCE_FILE}" ] || [ ! -f "${WRAPPER_SOURCE_FILE}" ]; then
    return 0
  fi
  if [ "${IS_PREPROCESS_ONLY}" = "1" ] || [ "${IS_DEP_ONLY}" = "1" ]; then
    return 0
  fi

  emit_depfile_via_host_preprocessor "$@"

  _src_abs="${WRAPPER_SOURCE_FILE}"
  case "${_src_abs}" in
    /*) ;;
    *) _src_abs="$(pwd)/${_src_abs}" ;;
  esac

  discover_system_includes "${EDGCPP_ACTIVE_LANG}"

  _cpfe_sys_args="${GNU_VER_FLAG}"
  if [ "${CPFE_CLI_STYLE}" = "release" ]; then
    case "${UNAME:-}" in
      Darwin*)
        _cpfe_sys_args='--clang --clang_version=170000 -D__GNUC__=4 -D__GNUC_MINOR__=2 -D_FORTIFY_SOURCE=0 -D__LP64__=1 -D__LITTLE_ENDIAN__=1 -D__BYTE_ORDER__=1234 -D__ORDER_LITTLE_ENDIAN__=1234 -D__ORDER_BIG_ENDIAN__=4321 -D__APPLE__=1 -D__MACH__=1 -U__BLOCKS__'
        case "${ARCH:-}" in
          arm64|aarch64) _cpfe_sys_args="${_cpfe_sys_args} -D__arm64__=1 -D__aarch64__=1" ;;
          *) _cpfe_sys_args="${_cpfe_sys_args} -D__x86_64__=1" ;;
        esac
        _sdk_dir="$(xcrun --show-sdk-path 2>/dev/null || true)"
        _clang_res="$(clang -print-resource-dir 2>/dev/null || true)"
        if [ -n "${_clang_res}" ] && [ -d "${_clang_res}/include" ]; then
          _cpfe_sys_args="${_cpfe_sys_args} -I${_clang_res}/include"
        fi
        if [ "${IS_NOSTDINC}" != "1" ] && [ -n "${_sdk_dir}" ] && [ -d "${_sdk_dir}/usr/include" ]; then
          _cpfe_sys_args="${_cpfe_sys_args} -I${_sdk_dir}/usr/include"
        fi
        ;;
      *)
        _cpfe_sys_args="${GNU_VER_FLAG} -D_FORTIFY_SOURCE=0"
        if [ -n "${DISCOVERED_SYS_INC_FLAGS}" ]; then
          _cpfe_sys_args="${_cpfe_sys_args} ${DISCOVERED_SYS_INC_FLAGS}"
        fi
        ;;
    esac
  elif [ -n "${DISCOVERED_SYS_INC_FLAGS}" ]; then
    _cpfe_sys_args="${_cpfe_sys_args} ${DISCOVERED_SYS_INC_FLAGS}"
  fi

  _cpfe_inc_args=""
  if [ "${CPFE_CLI_STYLE}" = "release" ]; then
    if [ -d "${EDGCPP_RESOLVED_HOME}/include_c99" ] && [ "${EDGCPP_ACTIVE_LANG}" = "c" ]; then
      _cpfe_inc_args="-I${EDGCPP_RESOLVED_HOME}/include_c99"
    elif [ -d "${EDGCPP_RESOLVED_HOME}/include_c++" ] && [ "${EDGCPP_ACTIVE_LANG}" = "c++" ]; then
      _cpfe_inc_args="-I${EDGCPP_RESOLVED_HOME}/include_c++"
    fi
  fi

  _cpfe_flags=""
  _be_pass_flags=""
  _expect_arg=""
  for _a in "$@"; do
    if [ -n "${_expect_arg}" ]; then
      _val="${_a}"
      case "${_expect_arg}" in
        -I)
          case "${_val}" in /*) ;; *) _val="$(pwd)/${_val}" ;; esac
          _cpfe_flags="${_cpfe_flags} -I${_val}"
          ;;
        -isystem)
          case "${_val}" in /*) ;; *) _val="$(pwd)/${_val}" ;; esac
          if [ "${CPFE_CLI_STYLE}" = "multibackend" ]; then
            _cpfe_flags="${_cpfe_flags} --sys_include ${_val}"
          else
            _cpfe_flags="${_cpfe_flags} -I${_val}"
          fi
          ;;
        -include|-imacros)
          case "${_val}" in /*) ;; *) [ -f "$(pwd)/${_val}" ] && _val="$(pwd)/${_val}" ;; esac
          if [ "${CPFE_CLI_STYLE}" = "multibackend" ]; then
            _cpfe_flags="${_cpfe_flags} --preinclude ${_val}"
          else
            _cpfe_flags="${_cpfe_flags} --preinclude=${_val}"
          fi
          ;;
        -D|-U)
          _cpfe_flags="${_cpfe_flags} ${_expect_arg}${_val}"
          ;;
      esac
      _expect_arg=""
      continue
    fi
    case "${_a}" in
      -I|-D|-U|-isystem|-include|-imacros|-o|-MF|-MT|-MQ)
        _expect_arg="${_a}"
        ;;
      -I*)
        _val="${_a#-I}"
        case "${_val}" in /*) ;; *) _val="$(pwd)/${_val}" ;; esac
        _cpfe_flags="${_cpfe_flags} -I${_val}"
        ;;
      -D*|-U*)
        _cpfe_flags="${_cpfe_flags} ${_a}"
        ;;
      -g|-gdwarf*)
        if [ "${CPFE_CLI_STYLE}" = "multibackend" ]; then
          _be_pass_flags="${_be_pass_flags} -g"
        fi
        ;;
      -fPIC|-fpic|-fPIE|-shared|-static|-fopenmp|--fno-tbaa|-flto=thin|-fprofile-generate=*|-fprofile-use=*|-fsanitize=*|--target=*)
        if [ "${CPFE_CLI_STYLE}" = "multibackend" ]; then
          _be_pass_flags="${_be_pass_flags} ${_a}"
        fi
        ;;
    esac
  done

  _fe_bin="${EDGCPP_RESOLVED_CPFE}"
  if [ -z "${_fe_bin}" ] || [ ! -x "${_fe_bin}" ]; then
    return 0
  fi

  _src_dir_inc="-I$(dirname -- "${_src_abs}")"
  _preinc_arg=""
  if [ "${CPFE_CLI_STYLE}" = "release" ] && [ -f "${EDGCPP_RESOLVED_HOME}/lib/predefined_macros.txt" ]; then
    _preinc_arg="--preinclude=${EDGCPP_RESOLVED_HOME}/lib/predefined_macros.txt"
  fi

  _tmp_nb_dir="${TMPDIR:-/tmp}/edgcpp_nb_$$"
  mkdir -p "${_tmp_nb_dir}"
  _fe_err_log="${_tmp_nb_dir}/cpfe_fe.log"
  _be_err_log="${_tmp_nb_dir}/cpfe_be.log"
  _tmp_nb_obj="${_tmp_nb_dir}/native_out.o"
  _tmp_nb_ll="${_tmp_nb_dir}/native_out.ll"
  _tmp_nb_c="${_tmp_nb_dir}/native_out.int.c"
  _tmp_nb_cpp="${_tmp_nb_dir}/native_out.int.cpp"

  _cpfe_rc=0
  NATIVE_BACKEND_RC=0

  if [ "${CPFE_CLI_STYLE}" = "multibackend" ]; then
    _timing_flag='--timing'
    if [ "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" = "fe_only" ]; then
      _fe_cmd_str="\"${_fe_bin}\" ${CPFE_STD_FLAG} ${_cpfe_sys_args} \"${_src_dir_inc}\" ${_cpfe_flags} ${_timing_flag} --no_code_gen \"${_src_abs}\""
      _be_cmd_str="(fe_only mode)"
      _t_fe0="$(now_ms)"
      # shellcheck disable=SC2086
      run_with_rss_probe "${_fe_err_log}" "${_fe_bin}" ${CPFE_STD_FLAG} ${_cpfe_sys_args} "${_src_dir_inc}" ${_cpfe_flags} ${_timing_flag} --no_code_gen "${_src_abs}" || _cpfe_rc=$?
      _t_fe1="$(now_ms)"
      [ "${PHASE_FE_MS}" -eq 0 ] && PHASE_FE_MS=$((_t_fe1 - _t_fe0))
      NATIVE_OBJ_PRODUCED=1
    elif [ "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" = "llvm_backend" ]; then
      _fe_cmd_str="(unified --backend=llvm)"
      _be_cmd_str="\"${_fe_bin}\" ${CPFE_STD_FLAG} ${_cpfe_sys_args} \"${_src_dir_inc}\" ${_cpfe_flags} --backend=llvm ${ACTIVE_OPT_FLAG} ${_be_pass_flags} ${_timing_flag} --emit-obj=\"${_tmp_nb_obj}\" \"${_src_abs}\""
      _t_be0="$(now_ms)"
      # shellcheck disable=SC2086
      run_with_rss_probe "${_be_err_log}" "${_fe_bin}" ${CPFE_STD_FLAG} ${_cpfe_sys_args} "${_src_dir_inc}" ${_cpfe_flags} --backend=llvm ${ACTIVE_OPT_FLAG} ${_be_pass_flags} ${_timing_flag} --emit-obj="${_tmp_nb_obj}" "${_src_abs}" || NATIVE_BACKEND_RC=$?
      _t_be1="$(now_ms)"
      _cpfe_rc="${NATIVE_BACKEND_RC}"
      [ "${PHASE_BE_MS}" -eq 0 ] && PHASE_BE_MS=$((_t_be1 - _t_be0))
    elif [ "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" = "gcc_backend" ]; then
      configure_gccjit_library_path
      _fe_cmd_str="(unified --backend=gcc)"
      _be_cmd_str="\"${_fe_bin}\" ${CPFE_STD_FLAG} ${_cpfe_sys_args} \"${_src_dir_inc}\" ${_cpfe_flags} --backend=gcc ${ACTIVE_OPT_FLAG} ${_be_pass_flags} ${_timing_flag} -c -o \"${_tmp_nb_obj}\" \"${_src_abs}\""
      _t_be0="$(now_ms)"
      # shellcheck disable=SC2086
      run_with_rss_probe "${_be_err_log}" "${_fe_bin}" ${CPFE_STD_FLAG} ${_cpfe_sys_args} "${_src_dir_inc}" ${_cpfe_flags} --backend=gcc ${ACTIVE_OPT_FLAG} ${_be_pass_flags} ${_timing_flag} -c -o "${_tmp_nb_obj}" "${_src_abs}" || NATIVE_BACKEND_RC=$?
      _t_be1="$(now_ms)"
      _cpfe_rc="${NATIVE_BACKEND_RC}"
      [ "${PHASE_BE_MS}" -eq 0 ] && PHASE_BE_MS=$((_t_be1 - _t_be0))
    elif [ "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" = "c_backend" ]; then
      _fe_cmd_str="\"${_fe_bin}\" ${CPFE_STD_FLAG} ${_cpfe_sys_args} \"${_src_dir_inc}\" ${_cpfe_flags} --c-be ${_timing_flag} --gen_c_file_name=\"${_tmp_nb_c}\" \"${_src_abs}\""
      # shellcheck disable=SC2086
      run_with_rss_probe "${_fe_err_log}" "${_fe_bin}" ${CPFE_STD_FLAG} ${_cpfe_sys_args} "${_src_dir_inc}" ${_cpfe_flags} --c-be ${_timing_flag} --gen_c_file_name="${_tmp_nb_c}" "${_src_abs}" || _cpfe_rc=$?
      _s1_rss="${LAST_PEAK_RSS_KB}"
      _be_cmd_str="\"${EDGCPP_RESOLVED_BACKEND}\" -x c ${ACTIVE_OPT_FLAG} -w -c \"${_tmp_nb_c}\" -o \"${_tmp_nb_obj}\""
      if [ "${_cpfe_rc}" -eq 0 ] && [ -s "${_tmp_nb_c}" ]; then
        run_with_rss_probe "${_be_err_log}" "${EDGCPP_RESOLVED_BACKEND}" -x c "${ACTIVE_OPT_FLAG}" -w -c "${_tmp_nb_c}" -o "${_tmp_nb_obj}" || NATIVE_BACKEND_RC=$?
      else
        NATIVE_BACKEND_RC="${_cpfe_rc}"
      fi
      [ "${LAST_PEAK_RSS_KB}" -lt "${_s1_rss}" ] && LAST_PEAK_RSS_KB="${_s1_rss}"
    elif [ "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" = "cpp_backend" ]; then
      _cp_bin="${EDGCPP_RESOLVED_CPFE_CP:-${_fe_bin}}"
      _fe_cmd_str="\"${_cp_bin}\" ${CPFE_STD_FLAG} ${_cpfe_sys_args} \"${_src_dir_inc}\" ${_cpfe_flags} ${_timing_flag} --gen_c_file_name=\"${_tmp_nb_cpp}\" \"${_src_abs}\""
      # shellcheck disable=SC2086
      run_with_rss_probe "${_fe_err_log}" "${_cp_bin}" ${CPFE_STD_FLAG} ${_cpfe_sys_args} "${_src_dir_inc}" ${_cpfe_flags} ${_timing_flag} --gen_c_file_name="${_tmp_nb_cpp}" "${_src_abs}" || _cpfe_rc=$?
      _s1_rss="${LAST_PEAK_RSS_KB}"
      _cxx_std_host="-std=c++17"
      case "${CPFE_STD_FLAG}" in
        --c++20) _cxx_std_host="-std=c++20" ;;
        --c++14) _cxx_std_host="-std=c++14" ;;
      esac
      _be_cmd_str="\"${EDGCPP_RESOLVED_BACKEND}\" ${_cxx_std_host} ${ACTIVE_OPT_FLAG} -w -c \"${_tmp_nb_cpp}\" -o \"${_tmp_nb_obj}\""
      if [ "${_cpfe_rc}" -eq 0 ] && [ -s "${_tmp_nb_cpp}" ]; then
        run_with_rss_probe "${_be_err_log}" "${EDGCPP_RESOLVED_BACKEND}" "${_cxx_std_host}" "${ACTIVE_OPT_FLAG}" -w -c "${_tmp_nb_cpp}" -o "${_tmp_nb_obj}" || NATIVE_BACKEND_RC=$?
      else
        NATIVE_BACKEND_RC="${_cpfe_rc}"
      fi
      [ "${LAST_PEAK_RSS_KB}" -lt "${_s1_rss}" ] && LAST_PEAK_RSS_KB="${_s1_rss}"
    fi
  else
    _cxx_rel_flags=""
    if [ "${EDGCPP_ACTIVE_LANG}" = "c++" ] && [ -d "${EDGCPP_RESOLVED_HOME}/include_c++" ]; then
      _cxx_rel_flags='--no_auto_instantiation'
    fi
    _fe_cmd_str="\"${_fe_bin}\" ${CPFE_STD_FLAG} ${_cxx_rel_flags} ${_preinc_arg} ${_cpfe_inc_args} \"${_src_dir_inc}\" ${_cpfe_sys_args} ${_cpfe_flags} --no_code_gen \"${_src_abs}\""
    _fe_t0="$(now_ms)"
    # shellcheck disable=SC2086
    run_with_rss_probe "${_fe_err_log}" "${_fe_bin}" ${CPFE_STD_FLAG} --no_warnings ${_cxx_rel_flags} ${_preinc_arg} ${_cpfe_inc_args} "${_src_dir_inc}" ${_cpfe_sys_args} ${_cpfe_flags} --no_code_gen "${_src_abs}" || _cpfe_rc=$?
    _fe_t1="$(now_ms)"
    PHASE_FE_MS=$((_fe_t1 - _fe_t0))
    _fe_rss="${LAST_PEAK_RSS_KB}"

    if [ "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" = "fe_only" ]; then
      _be_cmd_str="(fe_only mode)"
      NATIVE_OBJ_PRODUCED=1
    elif [ "${EDGCPP_ACTIVE_LANG}" = "c" ]; then
      _be_t0="$(now_ms)"
      if [ "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" = "c_backend" ]; then
        _c_be_bin="${EDGCPP_RESOLVED_CPFE_CP:-${_fe_bin}}"
        _be_cmd_str="\"${_c_be_bin}\" ${CPFE_STD_FLAG} ${_preinc_arg} ${_cpfe_inc_args} \"${_src_dir_inc}\" ${_cpfe_sys_args} ${_cpfe_flags} --c_gen_be --gen_c_file_name=\"${_tmp_nb_c}\" \"${_src_abs}\""
        # shellcheck disable=SC2086
        run_with_rss_probe "${_be_err_log}" "${_c_be_bin}" ${CPFE_STD_FLAG} --no_warnings ${_preinc_arg} ${_cpfe_inc_args} "${_src_dir_inc}" ${_cpfe_sys_args} ${_cpfe_flags} --c_gen_be --gen_c_file_name="${_tmp_nb_c}" "${_src_abs}" || NATIVE_BACKEND_RC=$?
        if [ "${NATIVE_BACKEND_RC}" -eq 0 ] && [ -s "${_tmp_nb_c}" ]; then
          "${EDGCPP_RESOLVED_BACKEND}" -c "${ACTIVE_OPT_FLAG}" -w "${_tmp_nb_c}" -o "${_tmp_nb_obj}" 2>/dev/null || NATIVE_BACKEND_RC=0
        else
          NATIVE_BACKEND_RC=0
        fi
      elif [ "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" = "gcc_backend" ]; then
        configure_gccjit_library_path
        _be_cmd_str="\"${_fe_bin}\" ${CPFE_STD_FLAG} ${_preinc_arg} ${_cpfe_inc_args} \"${_src_dir_inc}\" ${_cpfe_sys_args} ${_cpfe_flags} --gcc-be --compile_only -o \"${_tmp_nb_obj}\" \"${_src_abs}\""
        # shellcheck disable=SC2086
        run_with_rss_probe "${_be_err_log}" "${_fe_bin}" ${CPFE_STD_FLAG} --no_warnings ${_preinc_arg} ${_cpfe_inc_args} "${_src_dir_inc}" ${_cpfe_sys_args} ${_cpfe_flags} --gcc-be --compile_only -o "${_tmp_nb_obj}" "${_src_abs}" || NATIVE_BACKEND_RC=$?
      else
        _be_cmd_str="\"${_fe_bin}\" ${CPFE_STD_FLAG} ${_preinc_arg} ${_cpfe_inc_args} \"${_src_dir_inc}\" ${_cpfe_sys_args} ${_cpfe_flags} --llvm-be --gen_llvm_file_name=\"${_tmp_nb_ll}\" --gen_obj_file_name=\"${_tmp_nb_obj}\" \"${_src_abs}\""
        # shellcheck disable=SC2086
        run_with_rss_probe "${_be_err_log}" "${_fe_bin}" ${CPFE_STD_FLAG} --no_warnings ${_preinc_arg} ${_cpfe_inc_args} "${_src_dir_inc}" ${_cpfe_sys_args} ${_cpfe_flags} --llvm-be --gen_llvm_file_name="${_tmp_nb_ll}" --gen_obj_file_name="${_tmp_nb_obj}" "${_src_abs}" || NATIVE_BACKEND_RC=$?
      fi
      _be_t1="$(now_ms)"
      PHASE_BE_MS=$((_be_t1 - _be_t0))
    else
      _be_cmd_str="(release archive C++ mode)"
    fi
    [ "${LAST_PEAK_RSS_KB}" -lt "${_fe_rss}" ] && LAST_PEAK_RSS_KB="${_fe_rss}"
  fi

  if [ "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" != "fe_only" ] && [ "${NATIVE_BACKEND_RC}" -eq 0 ] && [ -s "${_tmp_nb_obj}" ]; then
    _can_use_native_obj=1
    if [ "${EDGCPP_FORCE_LINUX_LLVM_OBJ:-1}" = "0" ] && [ "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" = "llvm_backend" ] && [ "${UNAME:-}" = "Linux" ]; then
      _can_use_native_obj=0
    fi
    if [ "${_can_use_native_obj}" = "1" ] && [ "${EDGCPP_USE_NATIVE_CODEGEN:-1}" = "1" ]; then
      if [ "${IS_COMPILE_ONLY}" = "1" ]; then
        _dest_obj="${WRAPPER_OUTPUT_FILE}"
        if [ -z "${_dest_obj}" ]; then
          _src_base="${WRAPPER_SOURCE_FILE##*/}"
          _dest_obj="${_src_base%.*}.o"
        fi
        mkdir -p "$(dirname -- "${_dest_obj}")"
        cp "${_tmp_nb_obj}" "${_dest_obj}"
        NATIVE_OBJ_PRODUCED=1
      elif [ "${CPFE_CLI_STYLE}" = "multibackend" ] && [ "${SOURCE_COUNT}" -eq 1 ]; then
        _dest_bin="${WRAPPER_OUTPUT_FILE:-a.out}"
        mkdir -p "$(dirname -- "${_dest_bin}")"
        _lnk_extra=""
        if [ "${EDGCPP_ACTIVE_LANG}" = "c++" ] && [ -n "${RESOLVED_EDG_RT_LIB}" ] && [ -f "${RESOLVED_EDG_RT_LIB}" ]; then
          case "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" in
            gcc_backend|c_backend) _lnk_extra="${RESOLVED_EDG_RT_LIB}" ;;
          esac
        fi
        # Collect linker flags from "$@" (excluding source and -c/-o)
        _lnk_flags=""
        _sk=0
        for _la in "$@"; do
          if [ "${_sk}" = "1" ]; then _sk=0; continue; fi
          case "${_la}" in
            -o|-I|-D|-U|-isystem|-include|-imacros|-MF|-MT|-MQ) _sk=1 ;;
            -o*|-I*|-D*|-U*|-std=*|-c|-MD|-MMD|-MP|-Wp,-MD*|-Wp,-MMD*|--llvm*|--gcc*|--c-be|--c_gen_be|--cp-be|--cpp-be|--fe-only|--backend=*|--fno-tbaa|*.c|*.cc|*.cpp|*.cxx|*.C) ;;
            *) _lnk_flags="${_lnk_flags} ${_la}" ;;
          esac
        done
        # shellcheck disable=SC2086
        "${EDGCPP_RESOLVED_BACKEND}" "${_tmp_nb_obj}" ${_lnk_flags} ${_lnk_extra:+"${_lnk_extra}"} -o "${_dest_bin}" 2>>"${_be_err_log}" || NATIVE_BACKEND_RC=$?
        [ "${NATIVE_BACKEND_RC}" -eq 0 ] && NATIVE_OBJ_PRODUCED=1
      fi
    fi
  elif [ "${CPFE_CLI_STYLE}" = "multibackend" ] && [ "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" != "fe_only" ]; then
    [ "${NATIVE_BACKEND_RC}" -eq 0 ] && NATIVE_BACKEND_RC=1
  fi

  if [ "${_cpfe_rc}" -ne 0 ] || [ "${NATIVE_BACKEND_RC}" -ne 0 ]; then
    record_edgcpp_failure_forensics "${_src_abs}" "${_cpfe_rc}" "${NATIVE_BACKEND_RC}" "${_fe_cmd_str}" "${_be_cmd_str}" "${_fe_err_log}" "${_be_err_log}" "$@"
  fi

  rm -rf "${_tmp_nb_dir}" 2>/dev/null || true
  return "${_cpfe_rc}"
}

inspect_driver_args "$@"

if [ "${IS_PREPROCESS_ONLY}" = "1" ] || [ "${IS_DEP_ONLY}" = "1" ]; then
  exec "${EDGCPP_RESOLVED_BACKEND}" "$@"
fi

# Pure link-only invocation (no C/C++ source files): forward to host linker and auto-append libedg.a when linking C++ under gcc/c backend.
if [ "${HAS_SOURCE_FILE}" = "0" ]; then
  if [ "${EDGCPP_ACTIVE_LANG}" = "c++" ] && [ -n "${RESOLVED_EDG_RT_LIB}" ] && [ -f "${RESOLVED_EDG_RT_LIB}" ]; then
    case "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" in
      gcc_backend|c_backend)
        exec "${EDGCPP_RESOLVED_BACKEND}" "$@" "${RESOLVED_EDG_RT_LIB}"
        ;;
    esac
  fi
  exec "${EDGCPP_RESOLVED_BACKEND}" "$@"
fi

_strict_be="${EDGCPP_STRICT_BACKEND:-0}"
if [ "${CPFE_CLI_STYLE}" = "multibackend" ] && [ -n "${EDG_BACKEND:-}" ] && [ -z "${EDGCPP_STRICT_BACKEND:-}" ]; then
  _strict_be='1'
fi

_t0=$(now_ms)
_cpfe_status=0
run_cpfe_frontend_and_codegen "$@" || _cpfe_status=$?

# ## run_filtered_host_backend
# Invokes `EDGCPP_RESOLVED_BACKEND` after stripping EDG-specific backend selector flags.
run_filtered_host_backend() {
  _first_keep=1
  for _arg_item in "$@"; do
    if [ "${_first_keep}" = "1" ]; then
      set --
      _first_keep=0
    fi
    case "${_arg_item}" in
      --llvm|--llvm-be|--llvm_gen_be|--gcc|--gcc-be|--gcc_gen_be|--c-be|--c_gen_be|--cp-be|--cpp-be|--fe-only|--legacy|--backend=*|--fno-tbaa)
        ;;
      *)
        set -- "$@" "${_arg_item}"
        ;;
    esac
  done
  if [ "${IS_COMPILE_ONLY}" = "0" ] && [ "${EDGCPP_ACTIVE_LANG}" = "c++" ] && [ -n "${RESOLVED_EDG_RT_LIB}" ] && [ -f "${RESOLVED_EDG_RT_LIB}" ]; then
    case "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" in
      gcc_backend|c_backend)
        set -- "$@" "${RESOLVED_EDG_RT_LIB}"
        ;;
    esac
  fi
  "${EDGCPP_RESOLVED_BACKEND}" "$@"
}

_be_status=0
if [ "${NATIVE_OBJ_PRODUCED}" = "1" ]; then
  _be_status="${_cpfe_status}"
  [ "${_be_status}" -eq 0 ] && _be_status="${NATIVE_BACKEND_RC}"
elif [ "${_strict_be}" = "1" ] && { [ "${NATIVE_BACKEND_RC}" -ne 0 ] || [ "${_cpfe_status}" -ne 0 ]; }; then
  if [ "${_cpfe_status}" -ne 0 ]; then
    _be_status="${_cpfe_status}"
  else
    _be_status="${NATIVE_BACKEND_RC}"
  fi
else
  if [ -n "${EDGCPP_EXTRA_CFLAGS:-}" ] && [ "${EDGCPP_ACTIVE_LANG}" = "c" ]; then
    # shellcheck disable=SC2086
    run_filtered_host_backend "$@" ${EDGCPP_EXTRA_CFLAGS} || _be_status=$?
  elif [ -n "${EDGCPP_EXTRA_CXXFLAGS:-}" ] && [ "${EDGCPP_ACTIVE_LANG}" = "c++" ]; then
    # shellcheck disable=SC2086
    run_filtered_host_backend "$@" ${EDGCPP_EXTRA_CXXFLAGS} || _be_status=$?
  else
    run_filtered_host_backend "$@" 2>/dev/null || {
      if [ "${IS_COMPILE_ONLY}" = "0" ] && [ "${UNAME:-}" = "Linux" ]; then
        run_filtered_host_backend -no-pie "$@" || _be_status=$?
      else
        run_filtered_host_backend "$@" || _be_status=$?
      fi
    }
  fi
fi

_t1=$(now_ms)
_elapsed_ms=$((_t1 - _t0))
[ "${_elapsed_ms}" -le 0 ] && _elapsed_ms=1

if [ -n "${WRAPPER_SOURCE_FILE}" ]; then
  _fb_str='false'
  if [ "${NATIVE_OBJ_PRODUCED}" != "1" ] && { [ "${NATIVE_BACKEND_RC}" -ne 0 ] || [ "${_cpfe_status}" -ne 0 ]; }; then
    _fb_str='true'
  fi
  _kmode_str='false'
  [ "${IS_KERNEL_MODE}" = "1" ] && _kmode_str='true'
  record_edgcpp_event "${WRAPPER_SOURCE_FILE}" "${_cpfe_status}" "${_be_status}" "${_fb_str}" "${_elapsed_ms}" "${EDGCPP_ACTIVE_LANG}" "${NATIVE_BACKEND_RC}" "${LAST_PEAK_RSS_KB}" "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" "${CPFE_STD_DIALECT}" "${_kmode_str}"
fi

exit "${_be_status}"
