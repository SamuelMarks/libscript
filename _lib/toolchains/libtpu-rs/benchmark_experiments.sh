#!/bin/sh
# ## Overview
# Master idempotent empirical evaluation orchestrator (`benchmark_experiments.sh`) for `libtpu-rs` / `libtpu_paper`, routing sub-suites `E0` through `E8` while enforcing SIGPLAN `RULE-1`–`RULE-7`.
# ## Usage
# ./_lib/toolchains/libtpu-rs/benchmark_experiments.sh [--subsuites=E0,E1,E2,E3,E4,E5,E6,E7,E8] [--warmup=10] [--trials=200] [--results-dir=...] [--repo-dir=...] [--paper-dir=...] [--build-pdf]
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
elif [ "${ARCH:-}" = "aarch64" ] || [ "${ARCH:-}" = "arm64" ]; then
  _def_arch='linux_arm64'
fi

LIBTPU_RS_SUBSUITES="${LIBTPU_RS_SUBSUITES:-${LIBSCRIPT_EXPERIMENT_SUBSUITES:-E0,E1,E2,E3,E4,E5,E6,E7,E8}}"
LIBTPU_RS_WARMUP="${LIBTPU_RS_WARMUP:-${LIBSCRIPT_EXPERIMENT_WARMUP:-10}}"
LIBTPU_RS_TRIALS="${LIBTPU_RS_TRIALS:-${LIBSCRIPT_EXPERIMENT_TRIALS:-200}}"
LIBTPU_RS_RESULTS_DIR="${LIBTPU_RS_RESULTS_DIR:-${LIBSCRIPT_EXPERIMENT_OUT_DIR:-${LIBSCRIPT_ROOT_DIR}/build/libtpu_results}}"
LIBTPU_RS_SYNTHETIC_FIXTURES="${LIBTPU_RS_SYNTHETIC_FIXTURES:-0}"
LIBTPU_RS_DRY_RUN="${LIBTPU_RS_DRY_RUN:-0}"
_EXPLICIT_REPO_DIR=0
if [ -n "${LIBTPU_RS_REPO_DIR:-}" ]; then
  _EXPLICIT_REPO_DIR=1
fi
_EXPLICIT_PAPER_DIR=0
if [ -n "${LIBTPU_RS_PAPER_DIR:-}" ]; then
  _EXPLICIT_PAPER_DIR=1
fi
LIBTPU_RS_REPO_DIR="${LIBTPU_RS_REPO_DIR:-${LIBSCRIPT_EXPERIMENT_REPO_DIR:-${LIBSCRIPT_ROOT_DIR}/../libtpu-rs}}"
LIBTPU_RS_PAPER_DIR="${LIBTPU_RS_PAPER_DIR:-${LIBSCRIPT_EXPERIMENT_PAPER_DIR:-${LIBSCRIPT_ROOT_DIR}/../new_research/libtpu_paper}}"
LIBTPU_RS_CARGO_PROFILE="${LIBTPU_RS_CARGO_PROFILE:-${LIBSCRIPT_BENCH_CARGO_PROFILE:-opt3-lto-thin-cgu1}}"
LIBTPU_RS_HOST_ARCH="${LIBTPU_RS_HOST_ARCH:-${_def_arch}}"
LIBTPU_RS_BUILD_PDF="${LIBTPU_RS_BUILD_PDF:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    --subsuites=*) LIBTPU_RS_SUBSUITES="${1#*=}"; shift ;;
    --subsuites) LIBTPU_RS_SUBSUITES="${2:-}"; shift 2 ;;
    --warmup=*) LIBTPU_RS_WARMUP="${1#*=}"; shift ;;
    --warmup) LIBTPU_RS_WARMUP="${2:-10}"; shift 2 ;;
    --trials=*) LIBTPU_RS_TRIALS="${1#*=}"; shift ;;
    --trials) LIBTPU_RS_TRIALS="${2:-200}"; shift 2 ;;
    --results-dir=*|--out-dir=*) LIBTPU_RS_RESULTS_DIR="${1#*=}"; shift ;;
    --results-dir|--out-dir) LIBTPU_RS_RESULTS_DIR="${2:-}"; shift 2 ;;
    --repo-dir=*) LIBTPU_RS_REPO_DIR="${1#*=}"; _EXPLICIT_REPO_DIR=1; shift ;;
    --repo-dir) LIBTPU_RS_REPO_DIR="${2:-}"; _EXPLICIT_REPO_DIR=1; shift 2 ;;
    --paper-dir=*) LIBTPU_RS_PAPER_DIR="${1#*=}"; _EXPLICIT_PAPER_DIR=1; shift ;;
    --paper-dir) LIBTPU_RS_PAPER_DIR="${2:-}"; _EXPLICIT_PAPER_DIR=1; shift 2 ;;
    --cargo-profile=*) LIBTPU_RS_CARGO_PROFILE="${1#*=}"; shift ;;
    --host-arch=*) LIBTPU_RS_HOST_ARCH="${1#*=}"; shift ;;
    --build-pdf) LIBTPU_RS_BUILD_PDF='1'; shift ;;
    --synthetic-fixtures) LIBTPU_RS_SYNTHETIC_FIXTURES='1'; shift ;;
    --allow-dirty) export LIBTPU_RS_ALLOW_DIRTY='1'; shift ;;
    --dry-run|-n) LIBTPU_RS_DRY_RUN='1'; shift ;;
    --force) export FORCE_REBUILD='1'; shift ;;
    --help|-h)
      printf '%s\n' 'Usage: benchmark_experiments.sh [--subsuites=E0..E8] [--warmup=10] [--trials=200] [--results-dir=...] [--repo-dir=...] [--paper-dir=...] [--build-pdf] [--force]'
      exit 0
      ;;
    *) shift ;;
  esac
done

export LIBTPU_RS_SYNTHETIC_FIXTURES LIBTPU_RS_DRY_RUN LIBTPU_RS_BUILD_PDF LIBTPU_RS_CARGO_PROFILE

# ## prepare_synthetic_fixture_repo
# Creates an isolated, clean git repository fixture with zero-unsafe safe-core Rust code when `LIBTPU_RS_SYNTHETIC_FIXTURES=1` and `LIBTPU_RS_REPO_DIR` does not exist.
prepare_synthetic_fixture_repo() {
  if [ "${LIBTPU_RS_SYNTHETIC_FIXTURES}" = "1" ]; then
    if [ "${_EXPLICIT_PAPER_DIR}" = "0" ]; then
      LIBTPU_RS_PAPER_DIR=''
    fi
    if [ "${_EXPLICIT_REPO_DIR}" = "0" ] || [ ! -d "${LIBTPU_RS_REPO_DIR}/.git" ]; then
      _fx_repo="${LIBTPU_RS_RESULTS_DIR}/.synthetic_repo"
      if [ ! -d "${_fx_repo}/.git" ]; then
        mkdir -p "${_fx_repo}/crates/libtpu-core/src/hal" "${_fx_repo}/crates/libtpu-core/src/compiler" "${_fx_repo}/scripts"
        printf 'pub fn safe_compile_pass(x: u32) -> u32 { x + 1 }\n' > "${_fx_repo}/crates/libtpu-core/src/lib.rs"
        printf '// ModuloPipelineScheduler RecMII ResMII\npub struct ModuloPipelineScheduler;\n' > "${_fx_repo}/crates/libtpu-core/src/compiler/vliw.rs"
        printf 'pub fn hlo_bridge_ok() -> usize { 1 }\n' > "${_fx_repo}/crates/libtpu-core/src/compiler/hlo_bridge.rs"
        printf 'pub unsafe fn raw_ioctl() {}\n' > "${_fx_repo}/crates/libtpu-core/src/hal/syscall.rs"
        printf '# PJRT_Compile differential oracle\n' > "${_fx_repo}/scripts/differential_oracle.py"
        (
          cd -- "${_fx_repo}"
          git init -q
          git config user.email 'ci@libscript.local'
          git config user.name 'LibScript CI'
          git add .
          git commit -q -m 'Initialize synthetic libtpu-rs fixture'
        )
      fi
      LIBTPU_RS_REPO_DIR="${_fx_repo}"
    fi
  fi
}

# ## run_selected_subsuites
# Dispatches each requested sub-suite (`E0`..`E8`) in topological order and emits a master campaign summary JSON.
run_selected_subsuites() {
  mkdir -p "${LIBTPU_RS_RESULTS_DIR}"
  prepare_synthetic_fixture_repo
  libscript_exp_pin_cargo_release "${LIBTPU_RS_CARGO_PROFILE}" "${LIBTPU_RS_RESULTS_DIR}/cargo_profile.json"

  _list=$(printf '%s' "${LIBTPU_RS_SUBSUITES}" | tr ',;' '  ')
  for _s in ${_list}; do
    case "${_s}" in
      E0|e0) "${SCRIPT_DIR}/suites/e0_provenance.sh" "${LIBTPU_RS_REPO_DIR}" "${LIBTPU_RS_RESULTS_DIR}" "${LIBTPU_RS_HOST_ARCH}" ;;
      E1|e1) "${SCRIPT_DIR}/suites/e1_forensics.sh" "${LIBTPU_RS_REPO_DIR}" "${LIBTPU_RS_RESULTS_DIR}" "${LIBTPU_RS_HOST_ARCH}" ;;
      E2|e2) "${SCRIPT_DIR}/suites/e2_footprint_startup.sh" "${LIBTPU_RS_REPO_DIR}" "${LIBTPU_RS_RESULTS_DIR}" "${LIBTPU_RS_HOST_ARCH}" "${LIBTPU_RS_WARMUP}" "${LIBTPU_RS_TRIALS}" ;;
      E3|e3) "${SCRIPT_DIR}/suites/e3_jax_e2e.sh" "${LIBTPU_RS_REPO_DIR}" "${LIBTPU_RS_RESULTS_DIR}" "${LIBTPU_RS_HOST_ARCH}" ;;
      E4|e4) "${SCRIPT_DIR}/suites/e4_compiler_aot.sh" "${LIBTPU_RS_REPO_DIR}" "${LIBTPU_RS_RESULTS_DIR}" "${LIBTPU_RS_HOST_ARCH}" "${LIBTPU_RS_TRIALS}" ;;
      E5|e5) "${SCRIPT_DIR}/suites/e5_memory_studies.sh" "${LIBTPU_RS_REPO_DIR}" "${LIBTPU_RS_RESULTS_DIR}" "${LIBTPU_RS_HOST_ARCH}" ;;
      E6|e6) "${SCRIPT_DIR}/suites/e6_vliw_ablations.sh" "${LIBTPU_RS_REPO_DIR}" "${LIBTPU_RS_RESULTS_DIR}" "${LIBTPU_RS_HOST_ARCH}" ;;
      E7|e7) "${SCRIPT_DIR}/suites/e7_numerics_sparsecore.sh" "${LIBTPU_RS_REPO_DIR}" "${LIBTPU_RS_RESULTS_DIR}" "${LIBTPU_RS_HOST_ARCH}" ;;
      E8|e8) "${SCRIPT_DIR}/suites/e8_latex.sh" "${LIBTPU_RS_RESULTS_DIR}" "${LIBTPU_RS_PAPER_DIR}" "${LIBTPU_RS_BUILD_PDF}" ;;
      *)
        log_error "Unknown libtpu empirical sub-suite: '${_s}' (expected E0..E8)"
        return 1
        ;;
    esac
  done

  cat <<EOF > "${LIBTPU_RS_RESULTS_DIR}/campaign_summary.json.tmp"
{
  "schema_version": "1.0.0",
  "suite": "libtpu",
  "subsuites": "${LIBTPU_RS_SUBSUITES}",
  "host_arch": "${LIBTPU_RS_HOST_ARCH}",
  "warmup": ${LIBTPU_RS_WARMUP},
  "trials": ${LIBTPU_RS_TRIALS},
  "cargo_profile": "${LIBTPU_RS_CARGO_PROFILE}",
  "status": "PASS"
}
EOF
  mv -f "${LIBTPU_RS_RESULTS_DIR}/campaign_summary.json.tmp" "${LIBTPU_RS_RESULTS_DIR}/campaign_summary.json"
  log_info "Completed libtpu empirical suites (${LIBTPU_RS_SUBSUITES}) -> ${LIBTPU_RS_RESULTS_DIR}/campaign_summary.json"
}

run_selected_subsuites
