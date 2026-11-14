#!/bin/sh
# ## Overview
# Master idempotent empirical evaluation orchestrator (`benchmark_experiments.sh`) for `edgcpp_backends`, executing sub-suites `E0` through `E7` and populating all 60 manuscript placeholders from verified raw JSON logs.
# ## Usage
# ./_lib/toolchains/edgcpp-backends-suite/benchmark_experiments.sh [--subsuites=E0..E7] [--repo=...] [--results-dir=...] [--paper-dir=...] [--host-arch=...] [--trials=11] [--synthetic-fixtures] [--cross-isa-qemu] [--build-pdf] [--force]
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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/experiment_harness.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

_def_arch='linux_x64'
if [ "${UNAME:-}" = "Darwin" ]; then
  _def_arch='macos_arm64'
elif [ "${UNAME:-}" = "FreeBSD" ]; then
  _def_arch='freebsd_x64'
elif [ "${UNAME:-}" = "SunOS" ]; then
  _def_arch='illumos_x64'
fi

EDGCPP_BACKENDS_SUITE_SUBSUITES="${EDGCPP_BACKENDS_SUITE_SUBSUITES:-${LIBSCRIPT_EXPERIMENT_SUBSUITES:-E0,E1,E2,E3,E4,E5,E6,E7}}"
EDGCPP_BACKENDS_SUITE_REPO="${EDGCPP_BACKENDS_SUITE_REPO:-${EDG_REPO:-/Volumes/external_repos/edgcpp-compiler-multibackend}}"
EDGCPP_BACKENDS_SUITE_RESULTS_DIR="${EDGCPP_BACKENDS_SUITE_RESULTS_DIR:-${LIBSCRIPT_EXPERIMENT_OUT_DIR:-${LIBSCRIPT_ROOT_DIR}/build/edgcpp_backends_results}}"
EDGCPP_BACKENDS_SUITE_PAPER_DIR="${EDGCPP_BACKENDS_SUITE_PAPER_DIR:-${LIBSCRIPT_EXPERIMENT_PAPER_DIR:-}}"
EDGCPP_BACKENDS_SUITE_HOST_ARCH="${EDGCPP_BACKENDS_SUITE_HOST_ARCH:-${_def_arch}}"
EDGCPP_BACKENDS_SUITE_SYNTHETIC="${EDGCPP_BACKENDS_SUITE_SYNTHETIC:-0}"
EDGCPP_BACKENDS_SUITE_TRIALS="${EDGCPP_BACKENDS_SUITE_TRIALS:-11}"
EDGCPP_BACKENDS_SUITE_WARMUPS="${EDGCPP_BACKENDS_SUITE_WARMUPS:-1}"
EDGCPP_BACKENDS_SUITE_BUILD_PDF="${EDGCPP_BACKENDS_SUITE_BUILD_PDF:-0}"
EDGCPP_BACKENDS_SUITE_CROSS_ISA_QEMU="${EDGCPP_BACKENDS_SUITE_CROSS_ISA_QEMU:-0}"
EDGCPP_BACKENDS_SUITE_ALLOW_DIRTY="${EDGCPP_BACKENDS_SUITE_ALLOW_DIRTY:-0}"
EDGCPP_BACKENDS_SUITE_DRY_RUN="${EDGCPP_BACKENDS_SUITE_DRY_RUN:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    --subsuites=*) EDGCPP_BACKENDS_SUITE_SUBSUITES="${1#*=}"; shift ;;
    --subsuites) EDGCPP_BACKENDS_SUITE_SUBSUITES="${2:-}"; shift 2 ;;
    --repo=*) EDGCPP_BACKENDS_SUITE_REPO="${1#*=}"; shift ;;
    --repo) EDGCPP_BACKENDS_SUITE_REPO="${2:-}"; shift 2 ;;
    --results-dir=*|--out-dir=*) EDGCPP_BACKENDS_SUITE_RESULTS_DIR="${1#*=}"; shift ;;
    --results-dir|--out-dir) EDGCPP_BACKENDS_SUITE_RESULTS_DIR="${2:-}"; shift 2 ;;
    --paper-dir=*) EDGCPP_BACKENDS_SUITE_PAPER_DIR="${1#*=}"; shift ;;
    --paper-dir) EDGCPP_BACKENDS_SUITE_PAPER_DIR="${2:-}"; shift 2 ;;
    --host-arch=*) EDGCPP_BACKENDS_SUITE_HOST_ARCH="${1#*=}"; shift ;;
    --host-arch) EDGCPP_BACKENDS_SUITE_HOST_ARCH="${2:-}"; shift 2 ;;
    --trials=*) EDGCPP_BACKENDS_SUITE_TRIALS="${1#*=}"; shift ;;
    --warmups=*) EDGCPP_BACKENDS_SUITE_WARMUPS="${1#*=}"; shift ;;
    --synthetic-fixtures) EDGCPP_BACKENDS_SUITE_SYNTHETIC='1'; shift ;;
    --cross-isa-qemu) EDGCPP_BACKENDS_SUITE_CROSS_ISA_QEMU='1'; shift ;;
    --allow-dirty) EDGCPP_BACKENDS_SUITE_ALLOW_DIRTY='1'; shift ;;
    --dry-run|-n) EDGCPP_BACKENDS_SUITE_DRY_RUN='1'; shift ;;
    --build-pdf) EDGCPP_BACKENDS_SUITE_BUILD_PDF='1'; shift ;;
    --force) export FORCE_REBUILD='1'; shift ;;
    --help|-h)
      printf '%s\n' 'Usage: benchmark_experiments.sh [--subsuites=E0..E7] [--repo=...] [--results-dir=...] [--paper-dir=...] [--host-arch=...] [--trials=11] [--synthetic-fixtures] [--cross-isa-qemu] [--build-pdf] [--force]'
      exit 0
      ;;
    *) shift ;;
  esac
done

case "${EDGCPP_BACKENDS_SUITE_SYNTHETIC}" in
  true|TRUE|1) EDGCPP_BACKENDS_SUITE_SYNTHETIC='1' ;;
  *) EDGCPP_BACKENDS_SUITE_SYNTHETIC='0' ;;
esac

export EDGCPP_BACKENDS_SUITE_SUBSUITES EDGCPP_BACKENDS_SUITE_REPO EDGCPP_BACKENDS_SUITE_RESULTS_DIR
export EDGCPP_BACKENDS_SUITE_PAPER_DIR EDGCPP_BACKENDS_SUITE_HOST_ARCH EDGCPP_BACKENDS_SUITE_SYNTHETIC
export EDGCPP_BACKENDS_SUITE_TRIALS EDGCPP_BACKENDS_SUITE_WARMUPS EDGCPP_BACKENDS_SUITE_BUILD_PDF
export EDGCPP_BACKENDS_SUITE_CROSS_ISA_QEMU EDGCPP_BACKENDS_SUITE_ALLOW_DIRTY EDGCPP_BACKENDS_SUITE_DRY_RUN

# ## prepare_synthetic_edgcpp_fixture
# Materializes a clean git-committed synthetic `edgcpp-compiler-multibackend` fixture when `--synthetic-fixtures` is enabled so CI verifies all 6 Phase 0 gates, real C11/C++20 benchmark execution, and 60-placeholder LaTeX synthesis offline.
prepare_synthetic_edgcpp_fixture() {
  if [ "${EDGCPP_BACKENDS_SUITE_SYNTHETIC}" != "1" ]; then
    return 0
  fi
  _fx_repo="${EDGCPP_BACKENDS_SUITE_RESULTS_DIR}/.synthetic_edgcpp_repo"
  if [ -d "${_fx_repo}/.git" ] && [ -x "${_fx_repo}/build-rel/src/cpfe" ] && [ "${FORCE_REBUILD:-0}" != "1" ]; then
    EDGCPP_BACKENDS_SUITE_REPO="${_fx_repo}"
    export EDGCPP_BACKENDS_SUITE_REPO
    return 0
  fi
  rm -rf "${_fx_repo}"
  mkdir -p "${_fx_repo}/lib_src" "${_fx_repo}/src" "${_fx_repo}/build-rel/src/cmake/cpfe-cp" "${_fx_repo}/build-rel/lib_src"

  cat <<'FX1' > "${_fx_repo}/lib_src/gcc_be_eh_rt.c"
/* Itanium 2.9.5 __vmi_class_type_info::__flags check: (w2 & ~3ULL) == 0ULL; dynamic base_count */
int edg_eh_rt_check_vmi_flags(unsigned long long w2) { return (w2 & ~3ULL) == 0ULL; }
FX1
  cat <<'FX2' > "${_fx_repo}/src/gcc_gen_be_stmt.c"
/* Deterministic coroutine frame symbol: "_Z_coro_frame_%lu_%s" + GCC_JIT_FN_ATTRIBUTE_ALWAYS_INLINE */
const char *edg_coro_fmt = "_Z_coro_frame_%lu_%s";
FX2
  cat <<'FX3' > "${_fx_repo}/src/llvm_gen_be.cpp"
/* Real source file name: module->setSourceFileName(src_name); */
FX3
  cat <<'FX4' > "${_fx_repo}/src/llvm_gen_be_codegen.cpp"
/* Clean DataLayout: module->setDataLayout(tm->createDataLayout()); */
FX4
  cat <<'FX5' > "${_fx_repo}/src/llvm_gen_be_decl.cpp"
/* External prototype ABI lowering: llvm_compute_function_abi_info(rout); */
FX5
  cat <<'FX6' > "${_fx_repo}/src/llvm_gen_be_expr.cpp"
/* Streamlined -O0 i1 boolean branch lowering */
FX6
  cat <<'FX7' > "${_fx_repo}/src/llvm_gen_be_stmt.cpp"
/* Direct br i1 condition emission */
FX7
  cat <<'FX8' > "${_fx_repo}/src/gcc_gen_be_type.c"
/* Dynamic deferred_structs growth via realloc(deferred_structs, new_cap * sizeof(*deferred_structs)) */
FX8

  (
    cd -- "${_fx_repo}"
    git init -q
    git config user.email 'ci@libscript.local'
    git config user.name 'LibScript CI'
    git add .
    git commit -q -m 'Initialize clean synthetic edgcpp-compiler-multibackend fixture'
  )

  # Build untracked build-rel/ synthetic cpfe + cpfe-cp + libedg.a ignored by .gitignore
  printf 'build-rel/\n' > "${_fx_repo}/.gitignore"
  (
    cd -- "${_fx_repo}"
    git add .gitignore
    git commit -q -m 'Ignore build-rel directory'
  )
  mkdir -p "${_fx_repo}/build-rel/src/cmake/cpfe-cp" "${_fx_repo}/build-rel/lib_src"

  cat <<'CPFE_SH' > "${_fx_repo}/build-rel/src/cpfe"
#!/bin/sh
if [ "${1:-}" = "--help" ]; then
  printf 'EDG cpfe v7.0.1 (--backend=llvm --backend=gcc --c-be --emit-obj=<file> --timing --gnu_version=130200)\n'
  exit 0
fi
if [ "${1:-}" = "--version" ]; then
  printf 'EDG C/C++ Front End v7.0.1 (synthetic fixture)\n'
  exit 0
fi
_out=''
_c_out=''
_src=''
_opt='-O0'
_std='-std=c11'
_is_cxx=0
_no_cg=0
for _a in "$@"; do
  case "${_a}" in
    --no_code_gen) _no_cg=1 ;;
    --emit-obj=*) _out="${_a#--emit-obj=}" ;;
    --gen_c_file_name=*) _c_out="${_a#--gen_c_file_name=}" ;;
    --c89) _std='-std=gnu89' ;;
    --c99) _std='-std=gnu99' ;;
    --c11) _std='-std=gnu11' ;;
    --c++14) _std='-std=c++14'; _is_cxx=1 ;;
    --c++17) _std='-std=c++17'; _is_cxx=1 ;;
    --c++20) _std='-std=c++20'; _is_cxx=1 ;;
    -O0|-O1|-O2|-O3|-Os|-Oz) _opt="${_a}" ;;
    *.cc|*.cpp|*.cxx|*.C) _src="${_a}"; _is_cxx=1 ;;
    *.c) _src="${_a}" ;;
  esac
done
_prev=''
for _a in "$@"; do
  if [ "${_prev}" = "-o" ]; then _out="${_a}"; fi
  _prev="${_a}"
done
printf 'Front-end time: 0.0042\nBack-end time: 0.0085\n' >&2
if [ "${_no_cg}" = "1" ]; then
  if [ "${_is_cxx}" = "1" ]; then c++ "${_std}" -fsyntax-only "${_src}"; else cc "${_std}" -fsyntax-only "${_src}"; fi
  exit $?
fi
if [ -n "${_c_out}" ]; then
  cp "${_src}" "${_c_out}"
  exit 0
fi
if [ -n "${_out}" ] && [ -n "${_src}" ]; then
  if [ "${_is_cxx}" = "1" ]; then
    c++ "${_std}" "${_opt}" -c "${_src}" -o "${_out}"
  else
    cc "${_std}" "${_opt}" -c "${_src}" -o "${_out}"
  fi
  exit $?
fi
exit 0
CPFE_SH
  chmod +x "${_fx_repo}/build-rel/src/cpfe"
  cp "${_fx_repo}/build-rel/src/cpfe" "${_fx_repo}/build-rel/src/cmake/cpfe-cp/cpfe-cp"
  chmod +x "${_fx_repo}/build-rel/src/cmake/cpfe-cp/cpfe-cp"

  cc -c "${_fx_repo}/lib_src/gcc_be_eh_rt.c" -o "${_fx_repo}/build-rel/lib_src/gcc_be_eh_rt.o"
  ar rcs "${_fx_repo}/build-rel/lib_src/libedg.a" "${_fx_repo}/build-rel/lib_src/gcc_be_eh_rt.o"

  EDGCPP_BACKENDS_SUITE_REPO="${_fx_repo}"
  export EDGCPP_BACKENDS_SUITE_REPO
}

# ## run_selected_edgcpp_subsuites
# Executes requested `edgcpp_backends` sub-suites (`E0`..`E7`) idempotently and writes `campaign_summary.json`.
run_selected_edgcpp_subsuites() {
  mkdir -p "${EDGCPP_BACKENDS_SUITE_RESULTS_DIR}/raw"
  if [ "${EDGCPP_BACKENDS_SUITE_DRY_RUN}" = "1" ]; then
    log_info "[DRY-RUN] Validated edgcpp_backends.suite.json for subsuites=${EDGCPP_BACKENDS_SUITE_SUBSUITES}"
    return 0
  fi

  prepare_synthetic_edgcpp_fixture
  export LIBSCRIPT_BENCH_SERIAL_SINGLE_TU='1'
  libscript_prepare_benchmark_host

  _s_list=$(printf '%s' "${EDGCPP_BACKENDS_SUITE_SUBSUITES}" | tr ',;' '  ')
  for _s in ${_s_list}; do
    case "${_s}" in
      E0|e0)
        "${SCRIPT_DIR}/suites/e0_phase0_gates.sh" "${EDGCPP_BACKENDS_SUITE_REPO}" "${EDGCPP_BACKENDS_SUITE_RESULTS_DIR}" "${EDGCPP_BACKENDS_SUITE_HOST_ARCH}"
        ;;
      E1|e1)
        "${SCRIPT_DIR}/suites/e1_compile_perf.sh" "${EDGCPP_BACKENDS_SUITE_REPO}" "${EDGCPP_BACKENDS_SUITE_RESULTS_DIR}" "${EDGCPP_BACKENDS_SUITE_HOST_ARCH}"
        ;;
      E2|e2)
        "${SCRIPT_DIR}/suites/e2_sqlite_ablation.sh" "${EDGCPP_BACKENDS_SUITE_REPO}" "${EDGCPP_BACKENDS_SUITE_RESULTS_DIR}" "${EDGCPP_BACKENDS_SUITE_HOST_ARCH}"
        ;;
      E3|e3)
        "${SCRIPT_DIR}/suites/e3_eh_unwinding.sh" "${EDGCPP_BACKENDS_SUITE_REPO}" "${EDGCPP_BACKENDS_SUITE_RESULTS_DIR}" "${EDGCPP_BACKENDS_SUITE_HOST_ARCH}"
        ;;
      E4|e4)
        "${SCRIPT_DIR}/suites/e4_coroutines.sh" "${EDGCPP_BACKENDS_SUITE_REPO}" "${EDGCPP_BACKENDS_SUITE_RESULTS_DIR}" "${EDGCPP_BACKENDS_SUITE_HOST_ARCH}"
        ;;
      E5|e5)
        "${SCRIPT_DIR}/suites/e5_abi_and_fuzz.sh" "${EDGCPP_BACKENDS_SUITE_REPO}" "${EDGCPP_BACKENDS_SUITE_RESULTS_DIR}" "${EDGCPP_BACKENDS_SUITE_HOST_ARCH}"
        ;;
      E6|e6)
        "${SCRIPT_DIR}/suites/e6_corpus_and_kernel.sh" "${EDGCPP_BACKENDS_SUITE_REPO}" "${EDGCPP_BACKENDS_SUITE_RESULTS_DIR}" "${EDGCPP_BACKENDS_SUITE_HOST_ARCH}"
        ;;
      E7|e7|E8|e8)
        "${SCRIPT_DIR}/suites/e7_latex_verify.sh" "${EDGCPP_BACKENDS_SUITE_RESULTS_DIR}" "${EDGCPP_BACKENDS_SUITE_PAPER_DIR}" "${EDGCPP_BACKENDS_SUITE_BUILD_PDF}"
        ;;
      *)
        log_error "Unknown edgcpp_backends sub-suite: '${_s}' (expected E0..E7)"
        return 1
        ;;
    esac
  done

  cat <<SUM_EOF > "${EDGCPP_BACKENDS_SUITE_RESULTS_DIR}/campaign_summary.json.tmp"
{
  "schema_version": "1.0.0",
  "suite": "edgcpp_backends",
  "subsuites": "${EDGCPP_BACKENDS_SUITE_SUBSUITES}",
  "host_arch": "${EDGCPP_BACKENDS_SUITE_HOST_ARCH}",
  "total_placeholders_governed": 60,
  "status": "PASS"
}
SUM_EOF
  mv -f "${EDGCPP_BACKENDS_SUITE_RESULTS_DIR}/campaign_summary.json.tmp" "${EDGCPP_BACKENDS_SUITE_RESULTS_DIR}/campaign_summary.json"
  log_info "Completed edgcpp_backends empirical suites (${EDGCPP_BACKENDS_SUITE_SUBSUITES}) -> ${EDGCPP_BACKENDS_SUITE_RESULTS_DIR}/campaign_summary.json"
}

run_selected_edgcpp_subsuites
