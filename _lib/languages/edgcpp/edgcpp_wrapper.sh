#!/bin/sh
# ## Overview
# Compiler driver wrapper and telemetry shim for the EDG C/C++ Compiler Frontend (edgcpp).
# Translates standard cc/c++ flags (-c, -S, -E, -o, -I, -D, -U, -std=*, -O*, -g, -M*)
# to invoke the EDG front end (cpfe / cpfe-cp) and its native codegen backends
# (llvm_backend via --llvm-be or gcc_backend via --gcc-be / libgccjit), lowering or
# linking via the configured host backend toolchain when required while recording
# per-translation-unit JSONL compilation, memory (RSS), and backend telemetry.
#
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

# ## now_ms
# Returns the current wall-clock timestamp in milliseconds.
now_ms() {
  if [ -r /proc/uptime ]; then
    awk '{printf "%d\n", $1 * 1000}' /proc/uptime 2>/dev/null && return 0
  fi
  _s=$(date +%s 2>/dev/null || printf '0')
  printf '%s000\n' "${_s}"
}

# ## resolve_edgcpp_binaries
# Locates the installed cpfe, cpfe-cp, active codegen backend mode (llvm_backend or gcc_backend), and underlying host C/C++ compiler executables.
resolve_edgcpp_binaries() {
  _req_flavor="${EDGCPP_FLAVOR:-${EDGCPP_INSTALLED_FLAVOR:-}}"
  case "${0##*/}" in
    *gcc-be*|*edgcpp-gcc*)
      [ -z "${_req_flavor}" ] && _req_flavor="edgcpp+gcc"
      EDGCPP_BACKEND_MODE="${EDGCPP_BACKEND_MODE:-gcc_backend}"
      ;;
    *llvm-be*|*edgcpp-llvm*)
      [ -z "${_req_flavor}" ] && _req_flavor="edgcpp+llvm"
      EDGCPP_BACKEND_MODE="${EDGCPP_BACKEND_MODE:-llvm_backend}"
      ;;
  esac
  EDGCPP_ACTIVE_FLAVOR="${_req_flavor:-edgcpp+llvm+gcc}"

  _edg_base="${LIBSCRIPT_HOME:-$HOME/.libscript}/edgcpp"
  if [ -n "${EDGCPP_HOME:-}" ] && [ -d "${EDGCPP_HOME}" ]; then
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
  fi

  if [ -n "${CPFE_BIN:-}" ] && [ -x "${CPFE_BIN}" ]; then
    EDGCPP_RESOLVED_CPFE="${CPFE_BIN}"
  elif [ -x "${_edg_home}/bin/cpfe" ]; then
    EDGCPP_RESOLVED_CPFE="${_edg_home}/bin/cpfe"
  else
    EDGCPP_RESOLVED_CPFE="$(command -v cpfe 2>/dev/null || true)"
  fi

  if [ -n "${CPFE_CP_BIN:-}" ] && [ -x "${CPFE_CP_BIN}" ]; then
    EDGCPP_RESOLVED_CPFE_CP="${CPFE_CP_BIN}"
  elif [ -x "${_edg_home}/bin/cpfe-cp" ]; then
    EDGCPP_RESOLVED_CPFE_CP="${_edg_home}/bin/cpfe-cp"
  else
    EDGCPP_RESOLVED_CPFE_CP="$(command -v cpfe-cp 2>/dev/null || true)"
  fi
  export EDGCPP_RESOLVED_CPFE_CP

  _raw_be_mode="${LLVM_BACKEND_OR_GCC_BACKEND:-${EDGCPP_BACKEND_MODE:-}}"
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
    gcc|gcc-be|gcc_gen_be|gcc_backend)
      EDGCPP_ACTIVE_CODEGEN_BACKEND='gcc_backend'
      ;;
    *)
      EDGCPP_ACTIVE_CODEGEN_BACKEND='llvm_backend'
      ;;
  esac

  _drv_lang="${EDGCPP_DRIVER_LANG:-c}"
  case "${0##*/}" in
    *++*|*cxx*) _drv_lang="c++" ;;
  esac
  EDGCPP_ACTIVE_LANG="${_drv_lang}"

  if [ "${_drv_lang}" = "c++" ]; then
    if [ -n "${EDGCPP_BACKEND_CXX:-}" ] && command -v "${EDGCPP_BACKEND_CXX}" >/dev/null 2>&1; then
      EDGCPP_RESOLVED_BACKEND="$(command -v "${EDGCPP_BACKEND_CXX}")"
    elif [ -x "/usr/bin/clang++" ]; then
      EDGCPP_RESOLVED_BACKEND='/usr/bin/clang++'
    elif [ -x "/usr/bin/g++" ]; then
      EDGCPP_RESOLVED_BACKEND='/usr/bin/g++'
    elif [ -x "/usr/bin/c++" ]; then
      EDGCPP_RESOLVED_BACKEND='/usr/bin/c++'
    else
      EDGCPP_RESOLVED_BACKEND="$(command -v clang++ 2>/dev/null || command -v g++ 2>/dev/null || command -v c++ 2>/dev/null || printf '/usr/bin/c++')"
    fi
  else
    if [ -n "${EDGCPP_BACKEND_CC:-}" ] && command -v "${EDGCPP_BACKEND_CC}" >/dev/null 2>&1; then
      EDGCPP_RESOLVED_BACKEND="$(command -v "${EDGCPP_BACKEND_CC}")"
    elif [ -x "/usr/bin/clang" ]; then
      EDGCPP_RESOLVED_BACKEND='/usr/bin/clang'
    elif [ -x "/usr/bin/gcc" ]; then
      EDGCPP_RESOLVED_BACKEND='/usr/bin/gcc'
    elif [ -x "/usr/bin/cc" ]; then
      EDGCPP_RESOLVED_BACKEND='/usr/bin/cc'
    else
      EDGCPP_RESOLVED_BACKEND="$(command -v clang 2>/dev/null || command -v gcc 2>/dev/null || command -v cc 2>/dev/null || printf '/usr/bin/cc')"
    fi
  fi
}

# ## configure_gccjit_library_path
# Populates LIBRARY_PATH for libgccjit so that internal crt/emutls objects resolve during --gcc-be compilation.
configure_gccjit_library_path() {
  _extra_lib_path=""
  if [ -d "/opt/homebrew/lib/gcc/current" ]; then
    _emutls_dir="$(find /opt/homebrew/lib/gcc/current -name 'libemutls_w.a' -exec dirname {} \; 2>/dev/null | head -n 1 || true)"
    if [ -n "${_emutls_dir}" ]; then
      _extra_lib_path="${_emutls_dir}:/opt/homebrew/lib/gcc/current"
    else
      _extra_lib_path='/opt/homebrew/lib/gcc/current'
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
  fi
  if [ -n "${_extra_lib_path}" ]; then
    export LIBRARY_PATH="${_extra_lib_path}${LIBRARY_PATH:+:${LIBRARY_PATH}}"
  fi
}

# ## record_edgcpp_event
# Appends a structured JSONL compilation event to EDGCPP_LOG_FILE including flavor, backend mode, std_dialect, kernel_mode, exit codes, elapsed_ms, peak_rss_kb, and failure log paths.
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
  _ev_flavor="${EDGCPP_ACTIVE_FLAVOR:-edgcpp+llvm+gcc}"
  _ev_diag="${LAST_FAILURE_LOG_PATH:-}"
  _ev_repro="${LAST_REPRODUCER_DIR:-}"
  _log_file="${EDGCPP_LOG_FILE:-${LIBSCRIPT_HOME:-$HOME/.libscript}/edgcpp/compile_events.jsonl}"
  mkdir -p "$(dirname "${_log_file}")"
  _safe_src=$(printf '%s' "${_ev_src}" | tr '"' "'" | tr -d '[:cntrl:]')
  _safe_diag=$(printf '%s' "${_ev_diag}" | tr '"' "'" | tr -d '[:cntrl:]')
  _safe_repro=$(printf '%s' "${_ev_repro}" | tr '"' "'" | tr -d '[:cntrl:]')
  printf '{"source":"%s","lang":"%s","std_dialect":"%s","kernel_mode":%s,"edgcpp_flavor":"%s","llvm_backend_or_gcc_backend":"%s","cpfe_exit_code":%s,"native_backend_exit_code":%s,"exit_code":%s,"fallback":%s,"elapsed_ms":%s,"peak_rss_kb":%s,"diagnostic_log":"%s","reproducer_dir":"%s"}\n' "${_safe_src}" "${_ev_mode}" "${_ev_dialect}" "${_ev_kmode}" "${_ev_flavor}" "${_ev_be_kind}" "${_ev_cpfe_rc}" "${_ev_nb_rc}" "${_ev_be_rc}" "${_ev_fb}" "${_ev_ms}" "${_ev_rss_kb}" "${_safe_diag}" "${_safe_repro}" >> "${_log_file}" 2>/dev/null || true
}

resolve_edgcpp_binaries

if [ "$#" -eq 1 ]; then
  case "${1}" in
    --version|-v|-V)
      if [ -n "${EDGCPP_RESOLVED_CPFE}" ] && [ -x "${EDGCPP_RESOLVED_CPFE}" ]; then
        _cpfe_ver="$("${EDGCPP_RESOLVED_CPFE}" --version < /dev/null 2>&1 | head -n 1 || true)"
        printf 'edgcpp 7.0.1 (%s; codegen=%s; host_backend=%s)
' "${_cpfe_ver:-EDG C/C++ Front End v7.0.1}" "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" "${EDGCPP_RESOLVED_BACKEND}"
      else
        printf 'edgcpp 7.0.1 (EDG C/C++ Front End wrapper; codegen=%s; host_backend=%s)
' "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" "${EDGCPP_RESOLVED_BACKEND}"
      fi
      exit 0
      ;;
    -dumpversion)
      printf '%s
' "7.0.1"
      exit 0
      ;;
    -dumpmachine)
      "${EDGCPP_RESOLVED_BACKEND}" -dumpmachine 2>/dev/null || printf '%s-%s
' "$(uname -m)" "$(uname -s | tr '[:upper:]' '[:lower:]')"
      exit 0
      ;;
  esac
fi

WRAPPER_SOURCE_FILE=""
WRAPPER_OUTPUT_FILE=""
CPFE_STD_FLAG='--c11'
CPFE_STD_DIALECT='c11'
CPFE_COMPAT_FLAG='--gcc'
HAS_SOURCE_FILE=0
IS_COMPILE_ONLY=0
IS_PREPROCESS_ONLY=0
IS_DEP_ONLY=0
IS_NOSTDINC=0
IS_KERNEL_MODE=0
LAST_PEAK_RSS_KB=0
NATIVE_BACKEND_RC=0
NATIVE_OBJ_PRODUCED=0
LAST_FAILURE_LOG_PATH=""
LAST_REPRODUCER_DIR=""
SAVED_DRIVER_ARGS="$*"

case "$(uname -s 2>/dev/null || true)" in
  Darwin*) CPFE_COMPAT_FLAG="--clang --clang_version=170000" ;;
esac

if [ "${EDGCPP_ACTIVE_LANG}" = "c++" ]; then
  CPFE_STD_FLAG='--c++17'
  CPFE_STD_DIALECT='c++17'
fi

# ## inspect_driver_args
# Inspects compiler driver flags to identify translation units, output path, language dialect, kernel freestanding mode, and preprocess/dependency modes.
inspect_driver_args() {
  _expect_out=0
  for _arg in "$@"; do
    if [ "${_expect_out}" = "1" ]; then
      WRAPPER_OUTPUT_FILE="${_arg}"
      _expect_out=0
      continue
    fi
    case "${_arg}" in
      -o) _expect_out=1 ;;
      -o*) WRAPPER_OUTPUT_FILE="${_arg#-o}" ;;
      -c) IS_COMPILE_ONLY=1 ;;
      -E) IS_PREPROCESS_ONLY=1 ;;
      -M|-MM) IS_DEP_ONLY=1 ;;
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
      -std=c89|-ansi)
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
      -std=c11|-std=c17|-std=c2x)
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
      -std=c++20|-std=gnu++20|-std=c++2a)
        EDGCPP_ACTIVE_LANG='c++'
        CPFE_STD_FLAG='--c++20'
        CPFE_STD_DIALECT='c++20'
        ;;
      -std=c++23|-std=gnu++23|-std=c++2b)
        EDGCPP_ACTIVE_LANG='c++'
        CPFE_STD_FLAG='--c++23'
        CPFE_STD_DIALECT='c++23'
        ;;
      *.cc|*.cpp|*.cxx|*.C)
        WRAPPER_SOURCE_FILE="${_arg}"
        HAS_SOURCE_FILE=1
        EDGCPP_ACTIVE_LANG='c++'
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
        ;;
    esac
  done
}

# ## run_with_rss_probe
# Executes a command, captures its stdout/stderr to the file path in $1, and records peak resident set size in KB into LAST_PEAK_RSS_KB.
run_with_rss_probe() {
  _capture_file="${1}"
  shift
  _rss_tmp="${TMPDIR:-/tmp}/edgcpp_rss_$$.log"
  _cmd_rc=0
  : > "${_capture_file}"
  if [ -x "/usr/bin/time" ]; then
    case "$(uname -s 2>/dev/null || true)" in
      Darwin*)
        /usr/bin/time -l "$@" >"${_capture_file}" 2>"${_rss_tmp}" || _cmd_rc=$?
        _bytes=$(awk '/maximum resident set size/ {print $1}' "${_rss_tmp}" 2>/dev/null | head -n 1 || printf '0')
        case "${_bytes}" in ''|*[!0-9]*) _bytes=0 ;; esac
        if [ "${_bytes}" -gt 0 ]; then
          LAST_PEAK_RSS_KB=$((_bytes / 1024))
        fi
        grep -vE '^[[:space:]]*[0-9]+(\.[0-9]+)?[[:space:]]+(real|user|sys|maximum|average|unshared|page|block|voluntary|involuntary|swaps|messages|signals|context|instructions|cycles|peak)' "${_rss_tmp}" >> "${_capture_file}" 2>/dev/null || true
        ;;
      *)
        /usr/bin/time -v "$@" >"${_capture_file}" 2>"${_rss_tmp}" || _cmd_rc=$?
        _kb=$(awk -F: '/Maximum resident set size/ {gsub(/[^0-9]/, "", $2); print $2}' "${_rss_tmp}" 2>/dev/null | head -n 1 || printf '0')
        case "${_kb}" in ''|*[!0-9]*) _kb=0 ;; esac
        if [ "${_kb}" -gt 0 ]; then
          LAST_PEAK_RSS_KB="${_kb}"
        fi
        grep -vE '^[[:space:]]*(Command being timed|User time|System time|Percent of CPU|Elapsed \(wall clock\)|Average shared|Average unshared|Average stack|Average total|Maximum resident|Average resident|Major \(requiring|Minor \(reclaiming|Voluntary context|Involuntary context|Swaps:|File system|Socket messages|Signals delivered|Page size|Exit status:)' "${_rss_tmp}" >> "${_capture_file}" 2>/dev/null || true
        ;;
    esac
  else
    "$@" >"${_capture_file}" 2>&1 || _cmd_rc=$?
  fi
  rm -f "${_rss_tmp}" 2>/dev/null || true
  return "${_cmd_rc}"
}

# ## record_edgcpp_failure_forensics
# Captures detailed cpfe front-end/backend diagnostics, dynamic linker state, and a self-contained preprocessed (.i) reproducer bundle whenever cpfe fails.
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

  mkdir -p "$(dirname "${_fail_log}")" "${_repro_dir}"
  LAST_FAILURE_LOG_PATH="${_fail_log}"
  LAST_REPRODUCER_DIR="${_repro_dir}"

  _preprocessed_file="${_repro_dir}/${_tu_slug}.i"
  if [ -n "${EDGCPP_RESOLVED_BACKEND:-}" ]; then
    "${EDGCPP_RESOLVED_BACKEND}" -E -dD "$@" > "${_preprocessed_file}" 2>/dev/null || cp "${_ff_src}" "${_preprocessed_file}" 2>/dev/null || true
  else
    cp "${_ff_src}" "${_preprocessed_file}" 2>/dev/null || true
  fi

  cat <<EOF > "${_repro_dir}/repro.sh"
#!/bin/sh
# ## Overview
# Standalone reproducer script for edgcpp failure on ${_ff_src}.
#
# ## Usage
# ./repro.sh
set -feu
export LD_LIBRARY_PATH="${EDGCPP_RESOLVED_HOME}/lib\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}"
export LIBRARY_PATH="${LIBRARY_PATH:-}"
printf '==> Re-running cpfe front-end on %s...\n' "${_ff_src}"
${_ff_fe_cmd}
printf '==> Re-running cpfe native backend (%s) on %s...\n' "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" "${_ff_src}"
${_ff_be_cmd}
EOF
  chmod +x "${_repro_dir}/repro.sh" 2>/dev/null || true

  cat <<EOF > "${_repro_dir}/repro.cmd"
@echo off
:: # repro.cmd
:: ## Overview
:: Standalone Windows reproducer script for edgcpp failure on ${_ff_src}.
:: ## Usage
:: repro.cmd
${_ff_fe_cmd}
${_ff_be_cmd}
EOF

  _os_desc="$(uname -a 2>/dev/null || printf 'unknown')"
  if [ -f "/etc/os-release" ]; then
    _distro_name="$(grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | head -n 1 | cut -d= -f2- | tr -d '"' || true)"
    [ -n "${_distro_name}" ] && _os_desc="${_distro_name} (${_os_desc})"
  fi

  _diag_block="${_repro_dir}/diagnostic.log"
  {
    printf '================================================================================\n'
    printf 'EDGCPP FAILURE FORENSIC REPORT (%s)\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || printf 'now')"
    printf '================================================================================\n'
    printf 'Host / Guest OS     : %s\n' "${_os_desc}"
    printf 'EDGCPP Flavor       : %s\n' "${EDGCPP_ACTIVE_FLAVOR}"
    printf 'Active Backend      : %s\n' "${EDGCPP_ACTIVE_CODEGEN_BACKEND}"
    printf 'CPFE Binary         : %s\n' "${EDGCPP_RESOLVED_CPFE}"
    printf 'Kernel Version      : %s\n' "${LINUX_VERSION:-N/A}"
    printf 'C/C++ Dialect       : %s (kernel_mode=%s)\n' "${CPFE_STD_DIALECT}" "${IS_KERNEL_MODE}"
    printf 'Translation Unit    : %s\n' "${_ff_src}"
    printf 'Working Directory   : %s\n' "$(pwd)"
    printf 'Wrapper Invocation  : %s %s\n' "${0}" "${SAVED_DRIVER_ARGS}"
    printf 'Frontend Exit Code  : %s\n' "${_ff_fe_rc}"
    printf 'Backend Exit Code   : %s\n' "${_ff_be_rc}"
    printf 'Preprocessed (.i)   : %s\n' "${_preprocessed_file}"
    printf 'Reproducer Script   : %s/repro.sh\n' "${_repro_dir}"
    printf -- '--------------------------------------------------------------------------------\n'
    printf '1. CPFE FRONTEND COMMAND:\n  %s\n' "${_ff_fe_cmd}"
    printf 'CPFE FRONTEND OUTPUT (stdout/stderr):\n'
    if [ -s "${_ff_fe_log}" ]; then
      cat "${_ff_fe_log}"
    else
      printf '  (no output)\n'
    fi
    printf -- '--------------------------------------------------------------------------------\n'
    printf '2. CPFE NATIVE BACKEND (%s) COMMAND:\n  %s\n' "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" "${_ff_be_cmd}"
    printf 'CPFE NATIVE BACKEND OUTPUT (stdout/stderr):\n'
    if [ -s "${_ff_be_log}" ]; then
      cat "${_ff_be_log}"
    else
      printf '  (no output)\n'
    fi
    if [ "${_ff_fe_rc}" -ge 126 ] || [ "${_ff_be_rc}" -ge 126 ] || grep -qiE 'shared libraries|libgccjit|not found|symbol' "${_ff_fe_log}" "${_ff_be_log}" 2>/dev/null; then
      printf -- '--------------------------------------------------------------------------------\n'
      printf '3. DYNAMIC LINKER / SHARED LIBRARY DIAGNOSTICS (ldd %s):\n' "${EDGCPP_RESOLVED_CPFE}"
      if command -v ldd >/dev/null 2>&1; then
        ldd "${EDGCPP_RESOLVED_CPFE}" 2>&1 || true
      fi
    fi
    printf '================================================================================\n\n'
  } > "${_diag_block}"

  cat "${_diag_block}" >> "${_fail_log}"
  if [ "${EDGCPP_STRICT_BACKEND:-0}" = "1" ] || [ "${EDGCPP_VERBOSE_DIAGNOSTICS:-0}" = "1" ]; then
    cat "${_diag_block}" >&2
  fi
}

# ## run_cpfe_frontend_and_codegen
# Runs the EDG cpfe front-end validator and attempts native code generation via --llvm-be (llvm_backend) or --gcc-be (gcc_backend).
run_cpfe_frontend_and_codegen() {
  if [ "${HAS_SOURCE_FILE}" = "0" ] || [ -z "${WRAPPER_SOURCE_FILE}" ] || [ ! -f "${WRAPPER_SOURCE_FILE}" ]; then
    return 0
  fi
  if [ "${IS_PREPROCESS_ONLY}" = "1" ] || [ "${IS_DEP_ONLY}" = "1" ]; then
    return 0
  fi

  if [ "${EDGCPP_ACTIVE_LANG}" = "c++" ] && [ "${CPFE_COMPAT_FLAG}" = "--gcc" ]; then
    CPFE_COMPAT_FLAG='--g++'
  fi

  _src_abs="${WRAPPER_SOURCE_FILE}"
  case "${_src_abs}" in
    /*) ;;
    *) _src_abs="$(pwd)/${_src_abs}" ;;
  esac

  case "$(uname -s 2>/dev/null || true)" in
    Darwin*)
      _cpfe_sys_args="-D__GNUC__=4 -D__GNUC_MINOR__=2 -D_FORTIFY_SOURCE=0 -D__LP64__=1 -D__LITTLE_ENDIAN__=1 -D__BYTE_ORDER__=1234 -D__ORDER_LITTLE_ENDIAN__=1234 -D__ORDER_BIG_ENDIAN__=4321 -D__APPLE__=1 -D__MACH__=1 -U__BLOCKS__"
      case "$(uname -m 2>/dev/null || true)" in
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
      _cpfe_sys_args="--gnu_version=130000 -D_FORTIFY_SOURCE=0"
      _gcc_inc="$(gcc -print-file-name=include 2>/dev/null || true)"
      if [ -n "${_gcc_inc}" ] && [ -d "${_gcc_inc}" ]; then
        _cpfe_sys_args="${_cpfe_sys_args} -I${_gcc_inc}"
      fi
      if [ "${IS_NOSTDINC}" != "1" ]; then
        _multiarch_inc="/usr/include/$(uname -m 2>/dev/null || printf 'aarch64')-linux-gnu"
        if [ -d "${_multiarch_inc}" ]; then
          _cpfe_sys_args="${_cpfe_sys_args} -I${_multiarch_inc}"
        fi
        if [ -d "/usr/include" ]; then
          _cpfe_sys_args="${_cpfe_sys_args} -I/usr/include"
        fi
      fi
      ;;
  esac

  _cpfe_inc_args=""
  _cxx_extra_flags=""
  if [ -d "${EDGCPP_RESOLVED_HOME}/include_c99" ] && [ "${EDGCPP_ACTIVE_LANG}" = "c" ]; then
    _cpfe_inc_args="-I${EDGCPP_RESOLVED_HOME}/include_c99"
  elif [ -d "${EDGCPP_RESOLVED_HOME}/include_c++" ] && [ "${EDGCPP_ACTIVE_LANG}" = "c++" ]; then
    _cpfe_inc_args="-I${EDGCPP_RESOLVED_HOME}/include_c++"
    _cxx_extra_flags='--no_auto_instantiation'
  fi

  set -- "$@"
  _cpfe_flags=""
  _expect_arg=""
  for _a in "$@"; do
    if [ -n "${_expect_arg}" ]; then
      _inc_val="${_a}"
      case "${_expect_arg}" in
        -I|-isystem)
          case "${_inc_val}" in
            /*) ;;
            *) _inc_val="$(pwd)/${_inc_val}" ;;
          esac
          _cpfe_flags="${_cpfe_flags} -I${_inc_val}"
          ;;
        -include|-imacros)
          case "${_inc_val}" in
            /*) ;;
            *) [ -f "$(pwd)/${_inc_val}" ] && _inc_val="$(pwd)/${_inc_val}" ;;
          esac
          _cpfe_flags="${_cpfe_flags} --preinclude=${_inc_val}"
          ;;
        *)
          _cpfe_flags="${_cpfe_flags} ${_expect_arg}${_inc_val}"
          ;;
      esac
      _expect_arg=""
      continue
    fi
    case "${_a}" in
      -I|-D|-U|-isystem|-include|-imacros)
        _expect_arg="${_a}"
        ;;
      -I*)
        _inc_val="${_a#-I}"
        case "${_inc_val}" in
          /*) ;;
          *) _inc_val="$(pwd)/${_inc_val}" ;;
        esac
        _cpfe_flags="${_cpfe_flags} -I${_inc_val}"
        ;;
      -D*|-U*)
        _cpfe_flags="${_cpfe_flags} ${_a}"
        ;;
    esac
  done

  _cpfe_rc=0
  _fe_bin="${EDGCPP_RESOLVED_CPFE}"
  if [ -z "${_fe_bin}" ] || [ ! -x "${_fe_bin}" ]; then
    return 0
  fi

  _src_dir_inc="-I$(dirname "${_src_abs}")"
  _preinc_arg=""
  if [ -f "${EDGCPP_RESOLVED_HOME}/lib/predefined_macros.txt" ]; then
    _preinc_arg="--preinclude=${EDGCPP_RESOLVED_HOME}/lib/predefined_macros.txt"
  fi

  _tmp_nb_dir="${TMPDIR:-/tmp}/edgcpp_nb_$$"
  mkdir -p "${_tmp_nb_dir}"
  _fe_err_log="${_tmp_nb_dir}/cpfe_fe.log"
  _be_err_log="${_tmp_nb_dir}/cpfe_be.log"
  _tmp_nb_obj="${_tmp_nb_dir}/native_out.o"
  _tmp_nb_ll="${_tmp_nb_dir}/native_out.ll"

  _fe_cmd_str="\"${_fe_bin}\" ${CPFE_STD_FLAG} ${CPFE_COMPAT_FLAG} ${_cxx_extra_flags} ${_preinc_arg} ${_cpfe_inc_args} \"${_src_dir_inc}\" ${_cpfe_sys_args} ${_cpfe_flags} --no_code_gen \"${_src_abs}\""

  # 1. Front-end validation (--no_code_gen)
  # shellcheck disable=SC2086
  run_with_rss_probe "${_fe_err_log}" "${_fe_bin}" ${CPFE_STD_FLAG} ${CPFE_COMPAT_FLAG} --no_warnings ${_cxx_extra_flags} ${_preinc_arg} ${_cpfe_inc_args} "${_src_dir_inc}" ${_cpfe_sys_args} ${_cpfe_flags} --no_code_gen "${_src_abs}" || _cpfe_rc=$?
  _fe_rss="${LAST_PEAK_RSS_KB}"

  # 2. Native backend execution (llvm_backend via --llvm-be or gcc_backend via --gcc-be for C TUs)
  NATIVE_BACKEND_RC=0
  if [ "${EDGCPP_ACTIVE_LANG}" = "c" ]; then
    if [ "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" = "gcc_backend" ]; then
      configure_gccjit_library_path
      _be_cmd_str="\"${_fe_bin}\" ${CPFE_STD_FLAG} ${CPFE_COMPAT_FLAG} ${_cxx_extra_flags} ${_preinc_arg} ${_cpfe_inc_args} \"${_src_dir_inc}\" ${_cpfe_sys_args} ${_cpfe_flags} --gcc-be --compile_only -o \"${_tmp_nb_obj}\" \"${_src_abs}\""
      # shellcheck disable=SC2086
      run_with_rss_probe "${_be_err_log}" "${_fe_bin}" ${CPFE_STD_FLAG} ${CPFE_COMPAT_FLAG} --no_warnings ${_cxx_extra_flags} ${_preinc_arg} ${_cpfe_inc_args} "${_src_dir_inc}" ${_cpfe_sys_args} ${_cpfe_flags} --gcc-be --compile_only -o "${_tmp_nb_obj}" "${_src_abs}" || NATIVE_BACKEND_RC=$?
    else
      _be_cmd_str="\"${_fe_bin}\" ${CPFE_STD_FLAG} ${CPFE_COMPAT_FLAG} ${_cxx_extra_flags} ${_preinc_arg} ${_cpfe_inc_args} \"${_src_dir_inc}\" ${_cpfe_sys_args} ${_cpfe_flags} --llvm-be --gen_llvm_file_name=\"${_tmp_nb_ll}\" --gen_obj_file_name=\"${_tmp_nb_obj}\" \"${_src_abs}\""
      # shellcheck disable=SC2086
      run_with_rss_probe "${_be_err_log}" "${_fe_bin}" ${CPFE_STD_FLAG} ${CPFE_COMPAT_FLAG} --no_warnings ${_cxx_extra_flags} ${_preinc_arg} ${_cpfe_inc_args} "${_src_dir_inc}" ${_cpfe_sys_args} ${_cpfe_flags} --llvm-be --gen_llvm_file_name="${_tmp_nb_ll}" --gen_obj_file_name="${_tmp_nb_obj}" "${_src_abs}" || NATIVE_BACKEND_RC=$?
    fi
  else
    _be_cmd_str="(c++ mode: front-end validated via cpfe)"
  fi

  if [ "${LAST_PEAK_RSS_KB}" -lt "${_fe_rss}" ]; then
    LAST_PEAK_RSS_KB="${_fe_rss}"
  fi

  if [ "${EDGCPP_ACTIVE_LANG}" = "c" ]; then
    if [ "${NATIVE_BACKEND_RC}" -eq 0 ] && [ -s "${_tmp_nb_obj}" ]; then
      _can_use_native_obj=1
      if [ "${EDGCPP_FORCE_LINUX_LLVM_OBJ:-1}" = "0" ] && [ "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" = "llvm_backend" ] && [ "$(uname -s 2>/dev/null || true)" = "Linux" ]; then
        _can_use_native_obj=0
      fi
      if [ "${_can_use_native_obj}" = "1" ] && [ "${IS_COMPILE_ONLY}" = "1" ] && [ -n "${WRAPPER_OUTPUT_FILE}" ] && [ "${EDGCPP_USE_NATIVE_CODEGEN:-1}" = "1" ]; then
        mkdir -p "$(dirname "${WRAPPER_OUTPUT_FILE}")"
        cp "${_tmp_nb_obj}" "${WRAPPER_OUTPUT_FILE}"
        NATIVE_OBJ_PRODUCED=1
      fi
    else
      [ "${NATIVE_BACKEND_RC}" -eq 0 ] && NATIVE_BACKEND_RC=1
    fi
  fi

  if [ "${_cpfe_rc}" -ne 0 ] || [ "${NATIVE_BACKEND_RC}" -ne 0 ]; then
    # Re-run front-end without --no_warnings if _fe_err_log was empty on failure
    if [ "${_cpfe_rc}" -ne 0 ] && [ ! -s "${_fe_err_log}" ]; then
      # shellcheck disable=SC2086
      "${_fe_bin}" ${CPFE_STD_FLAG} ${CPFE_COMPAT_FLAG} ${_cxx_extra_flags} ${_preinc_arg} ${_cpfe_inc_args} "${_src_dir_inc}" ${_cpfe_sys_args} ${_cpfe_flags} --no_code_gen "${_src_abs}" >"${_fe_err_log}" 2>&1 || true
    fi
    record_edgcpp_failure_forensics "${_src_abs}" "${_cpfe_rc}" "${NATIVE_BACKEND_RC}" "${_fe_cmd_str}" "${_be_cmd_str}" "${_fe_err_log}" "${_be_err_log}" "$@"
  fi

  rm -rf "${_tmp_nb_dir}" 2>/dev/null || true
  return "${_cpfe_rc}"
}

inspect_driver_args "$@"

_t0=$(now_ms)
_cpfe_status=0
run_cpfe_frontend_and_codegen "$@" || _cpfe_status=$?

_be_status=0
if [ "${NATIVE_OBJ_PRODUCED}" = "1" ]; then
  _be_status=0
elif [ "${EDGCPP_STRICT_BACKEND:-0}" = "1" ] && [ "${HAS_SOURCE_FILE}" = "1" ] && { [ "${NATIVE_BACKEND_RC}" -ne 0 ] || [ "${_cpfe_status}" -ne 0 ]; }; then
  if [ "${_cpfe_status}" -ne 0 ]; then
    _be_status="${_cpfe_status}"
  else
    _be_status="${NATIVE_BACKEND_RC}"
  fi
else
  if [ -n "${EDGCPP_EXTRA_CFLAGS:-}" ] && [ "${EDGCPP_ACTIVE_LANG}" = "c" ]; then
    # shellcheck disable=SC2086
    "${EDGCPP_RESOLVED_BACKEND}" "$@" ${EDGCPP_EXTRA_CFLAGS} || _be_status=$?
  elif [ -n "${EDGCPP_EXTRA_CXXFLAGS:-}" ] && [ "${EDGCPP_ACTIVE_LANG}" = "c++" ]; then
    # shellcheck disable=SC2086
    "${EDGCPP_RESOLVED_BACKEND}" "$@" ${EDGCPP_EXTRA_CXXFLAGS} || _be_status=$?
  else
    "${EDGCPP_RESOLVED_BACKEND}" "$@" 2>/dev/null || {
      if [ "${IS_COMPILE_ONLY}" = "0" ] && [ "$(uname -s 2>/dev/null || true)" = "Linux" ]; then
        "${EDGCPP_RESOLVED_BACKEND}" -no-pie "$@" || _be_status=$?
      else
        "${EDGCPP_RESOLVED_BACKEND}" "$@" || _be_status=$?
      fi
    }
  fi
fi

_t1=$(now_ms)
_elapsed_ms=$((_t1 - _t0))
[ "${_elapsed_ms}" -le 0 ] && _elapsed_ms=1

if [ -n "${WRAPPER_SOURCE_FILE}" ]; then
  _fb_str='false'
  if [ "${NATIVE_BACKEND_RC}" -ne 0 ] || [ "${_cpfe_status}" -ne 0 ]; then
    _fb_str='true'
  fi
  _kmode_str='false'
  if [ "${IS_KERNEL_MODE}" = "1" ]; then
    _kmode_str='true'
  fi
  record_edgcpp_event "${WRAPPER_SOURCE_FILE}" "${_cpfe_status}" "${_be_status}" "${_fb_str}" "${_elapsed_ms}" "${EDGCPP_ACTIVE_LANG}" "${NATIVE_BACKEND_RC}" "${LAST_PEAK_RSS_KB}" "${EDGCPP_ACTIVE_CODEGEN_BACKEND}" "${CPFE_STD_DIALECT}" "${_kmode_str}"
fi

exit "${_be_status}"
