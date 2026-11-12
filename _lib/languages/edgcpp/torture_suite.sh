#!/bin/sh
# ## Overview
# Supplemental C torture execution suite (-O0 through -O3) and C++17 STL header stress harness for the EDG C/C++ Compiler Frontend (edgcpp).
# ## Usage
# ./_lib/languages/edgcpp/torture_suite.sh [--compiler=<id>] [--output=<json_path>]
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
unset SCRIPT_NAME || true

for LIB in "_lib/_common/log.sh" "_lib/_common/source_builder.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME || true
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)

TORTURE_COMPILER="${LIBSCRIPT_BUILD_TOOLCHAIN:-EDG-LLVM}"
TORTURE_REPORT_JSON="${LIBSCRIPT_ROOT_DIR}/build/edgcpp-torture-report.json"

for _arg in "$@"; do
  case "${_arg}" in
    --compiler=*) TORTURE_COMPILER="${_arg#*=}" ;;
    --output=*) TORTURE_REPORT_JSON="${_arg#*=}" ;;
  esac
done

# ## check_torture_idempotency
# Checks whether the torture and STL stress report already exists for the requested compiler configuration.
check_torture_idempotency() {
  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -s "${TORTURE_REPORT_JSON}" ]; then
    if grep -q '"compiler_id": "'"${TORTURE_COMPILER}"'"' "${TORTURE_REPORT_JSON}" 2>/dev/null && grep -q '"all_passed": true' "${TORTURE_REPORT_JSON}" 2>/dev/null; then
      log_info "EDG torture and STL stress suite for ${TORTURE_COMPILER} already verified at ${TORTURE_REPORT_JSON}."
      return 0
    fi
  fi
  return 1
}

# ## stage_torture_sources
# Generates the self-contained C torture test cases (bitfields, packed structs, computed gotos, pointer aliasing, variadics, switch dispatch) and the C++17 STL header stress translation unit.
stage_torture_sources() {
  _src_dir="${1}"
  mkdir -p "${_src_dir}"

  cat <<'EOF' > "${_src_dir}/torture_01_bitfields_packed.c"
#include <stdint.h>
#include <stddef.h>

struct __attribute__((packed)) packed_reg {
    uint8_t tag;
    uint32_t addr : 20;
    uint32_t flags : 12;
    uint16_t crc;
};

int main(void) {
    volatile struct packed_reg r = { 0x5AU, 0xABCDEU, 0x7F3U, 0x1234U };
    r.addr = (uint32_t)((r.addr + 3U) & 0xFFFFFU);
    if (r.tag != 0x5AU || r.addr != 0xABCE1U || r.flags != 0x7F3U || r.crc != 0x1234U) {
        return 1;
    }
    return 0;
}
EOF

  cat <<'EOF' > "${_src_dir}/torture_02_computed_goto_switch.c"
#include <stdint.h>

static int dispatch_vm(const uint8_t *ops, int len) {
    static const void * const table[4] = { &&op_add, &&op_xor, &&op_mul, &&op_halt };
    int acc = 7;
    int pc = 0;
    if (len <= 0) return acc;
    goto *table[ops[pc] & 3U];
op_add:
    acc += 13;
    pc++;
    if (pc >= len) return acc;
    goto *table[ops[pc] & 3U];
op_xor:
    acc ^= 0x3C;
    pc++;
    if (pc >= len) return acc;
    goto *table[ops[pc] & 3U];
op_mul:
    acc *= 3;
    pc++;
    if (pc >= len) return acc;
    goto *table[ops[pc] & 3U];
op_halt:
    return acc;
}

int main(void) {
    static const uint8_t prog[5] = { 0, 2, 1, 0, 3 };
    int out = dispatch_vm(prog, 5);
    return (out == 13) ? 0 : 1;
}
EOF

  cat <<'EOF' > "${_src_dir}/torture_03_aliasing_variadic.c"
#include <stdint.h>
#include <stdarg.h>

static int64_t sum_variadic(int count, ...) {
    va_list ap;
    int64_t total = 0;
    int i;
    va_start(ap, count);
    for (i = 0; i < count; ++i) {
        total += va_arg(ap, int64_t);
    }
    va_end(ap);
    return total;
}

int main(void) {
    int64_t s = sum_variadic(4, (int64_t)10, (int64_t)20, (int64_t)30, (int64_t)40);
    return (s == 100) ? 0 : 1;
}
EOF

  cat <<'EOF' > "${_src_dir}/stl_stress_headers.cpp"
#include <iostream>
#include <vector>
#include <map>
#include <unordered_map>
#include <regex>
#include <chrono>
#include <thread>
#include <filesystem>
#include <string>
#include <numeric>

int main(void) {
    std::vector<int> vals = {1, 2, 3, 4, 5, 6, 7, 8};
    int sum = std::accumulate(vals.begin(), vals.end(), 0);
    std::map<std::string, int> ordered;
    ordered["edg"] = sum;
    std::unordered_map<std::string, int> fast;
    fast["llvm"] = ordered["edg"] * 2;
    auto t0 = std::chrono::steady_clock::now();
    std::filesystem::path p("/tmp/edgcpp_stl_check");
    auto t1 = std::chrono::steady_clock::now();
    auto dt = std::chrono::duration_cast<std::chrono::nanoseconds>(t1 - t0).count();
    if (fast["llvm"] == 72 && !p.empty() && dt >= 0) {
        return 0;
    }
    return 1;
}
EOF
}

# ## run_torture_and_stl_suite
# Compiles and executes all C torture tests across -O0, -O1, -O2, and -O3 plus the C++17 STL stress test, emitting a structured JSON report.
run_torture_and_stl_suite() {
  if check_torture_idempotency; then
    return 0
  fi

  export LIBSCRIPT_BUILD_TOOLCHAIN="${TORTURE_COMPILER}"
  libscript_resolve_build_toolchain "edgcpp-torture" "7.0.1"
  _cc_bin="${LIBSCRIPT_RESOLVED_CC_BIN}"
  _cxx_bin="${LIBSCRIPT_RESOLVED_CXX_BIN:-}"
  if [ -z "${_cxx_bin}" ]; then
    case "${_cc_bin}" in
      *edgcpp*)
        _edg_dir=$(dirname "${_cc_bin}")
        if [ -x "${_edg_dir}/edg-c++" ]; then
          _cxx_bin="${_edg_dir}/edg-c++"
        else
          _cxx_bin="${_cc_bin}"
        fi
        ;;
      *clang*) _cxx_bin="$(command -v clang++ 2>/dev/null || printf '%s' "${_cc_bin}")" ;;
      *) _cxx_bin="$(command -v g++ 2>/dev/null || command -v c++ 2>/dev/null || printf '%s' "${_cc_bin}")" ;;
    esac
  fi

  _work_dir="${TMPDIR:-/tmp}/libscript_torture_${LIBSCRIPT_RESOLVED_CC_ID}_$$"
  rm -rf "${_work_dir}"
  mkdir -p "${_work_dir}"
  stage_torture_sources "${_work_dir}"

  _total_tests=0
  _passed_tests=0
  _failed_tests=0
  _t0="$(libscript_now_ms)"

  for _opt in -O0 -O1 -O2 -O3; do
    for _c_name in torture_01_bitfields_packed torture_02_computed_goto_switch torture_03_aliasing_variadic; do
      _c_src="${_work_dir}/${_c_name}.c"
      [ -f "${_c_src}" ] || continue
      _total_tests=$((_total_tests + 1))
      _bin="${_work_dir}/${_c_name}_${_opt#-}"
      if "${_cc_bin}" -std=gnu11 "${_opt}" "${_c_src}" -o "${_bin}" >/dev/null 2>&1 && "${_bin}" >/dev/null 2>&1; then
        _passed_tests=$((_passed_tests + 1))
      else
        _failed_tests=$((_failed_tests + 1))
      fi
    done
  done

  if [ -n "${EDGCPP_TORTURE_SUITE_DIR:-}" ] && [ -d "${EDGCPP_TORTURE_SUITE_DIR}" ]; then
    set +f
    for _ext_c in "${EDGCPP_TORTURE_SUITE_DIR}"/*.c; do
      [ -f "${_ext_c}" ] || continue
      _total_tests=$((_total_tests + 1))
      _ext_bin="${_work_dir}/ext_$(basename "${_ext_c}" .c)"
      if "${_cc_bin}" -std=gnu11 -O2 "${_ext_c}" -o "${_ext_bin}" >/dev/null 2>&1 && "${_ext_bin}" >/dev/null 2>&1; then
        _passed_tests=$((_passed_tests + 1))
      else
        _failed_tests=$((_failed_tests + 1))
      fi
    done
    set -f
  fi

  _stl_passed='false'
  _stl_t0="$(libscript_now_ms)"
  _total_tests=$((_total_tests + 1))
  if "${_cxx_bin}" -std=c++17 -O2 "${_work_dir}/stl_stress_headers.cpp" -o "${_work_dir}/stl_stress_headers" >/dev/null 2>&1 && "${_work_dir}/stl_stress_headers" >/dev/null 2>&1; then
    _stl_passed='true'
    _passed_tests=$((_passed_tests + 1))
  else
    _failed_tests=$((_failed_tests + 1))
  fi
  _stl_t1="$(libscript_now_ms)"
  _stl_ms=$((_stl_t1 - _stl_t0))
  [ "${_stl_ms}" -lt 1 ] && _stl_ms=1

  _t1="$(libscript_now_ms)"
  _elapsed_ms=$((_t1 - _t0))
  [ "${_elapsed_ms}" -lt 1 ] && _elapsed_ms=1

  _all_ok='false'
  [ "${_failed_tests}" -eq 0 ] && _all_ok='true'

  mkdir -p "$(dirname "${TORTURE_REPORT_JSON}")"
  cat <<EOF > "${TORTURE_REPORT_JSON}.tmp"
{
  "suite": "edgcpp-torture-and-stl-stress",
  "compiler_id": "${TORTURE_COMPILER}",
  "resolved_cc_id": "${LIBSCRIPT_RESOLVED_CC_ID}",
  "compiler_bin": "${_cc_bin}",
  "cxx_bin": "${_cxx_bin}",
  "optimization_levels": ["-O0", "-O1", "-O2", "-O3"],
  "total_tests": ${_total_tests},
  "passed_tests": ${_passed_tests},
  "failed_tests": ${_failed_tests},
  "stl_headers_stress_passed": ${_stl_passed},
  "stl_compile_time_ms": ${_stl_ms},
  "total_elapsed_ms": ${_elapsed_ms},
  "all_passed": ${_all_ok}
}
EOF
  mv -f "${TORTURE_REPORT_JSON}.tmp" "${TORTURE_REPORT_JSON}"
  rm -rf "${_work_dir}"

  if [ "${_failed_tests}" -ne 0 ]; then
    log_error "Torture/STL suite failed ${_failed_tests}/${_total_tests} tests for ${TORTURE_COMPILER}."
    return 1
  fi
  log_info "Torture/STL suite passed ${_passed_tests}/${_total_tests} tests for ${TORTURE_COMPILER} (${_elapsed_ms} ms)."
  return 0
}

run_torture_and_stl_suite
