#!/bin/sh
# ## Overview
# Master idempotent A/B orchestrator (`benchmark_experiments.sh`) for `gemma-4-sql-libtpu`, running all 7 `SamuelMarks/gemma-4-sql` TPU backends first under upstream Google `libtpu` (`og`) and then under `libtpu-rs` (`rs`) in dedicated twin `/dev/shm` virtualenvs before synthesizing differential tables and LaTeX macros.
# ## Usage
# ./experiments/gemma-4-sql-libtpu/benchmark_experiments.sh [--tfrc-config=<path>] [--repo-dir=<dir>] [--results-dir=<dir>] [--providers=og,rs] [--fresh-vm-per-provider] [--render-latex] [--dry-run]

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

_ab_this="${THIS_FILE}"; _ab_dir="${SCRIPT_DIR}"
for _lib in engine/common/log.sh engine/common/tfrc_guard.sh workloads/ai/_common/tpu_matrix.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_lib}"; export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _lib || true
THIS_FILE="${_ab_this}"; SCRIPT_DIR="${_ab_dir}"

GEMMA_4_SQL_REPO_DIR="${GEMMA_4_SQL_REPO_DIR:-$(pwd)}"
GEMMA_4_SQL_AB_RESULTS_DIR="${GEMMA_4_SQL_AB_RESULTS_DIR:-${RESULTS_DIR:-${LIBSCRIPT_ROOT_DIR}/build/experiment_results/gemma-4-sql-libtpu}}"
GEMMA_4_SQL_AB_PROVIDERS="${GEMMA_4_SQL_AB_PROVIDERS:-og,rs}"
GEMMA_4_SQL_AB_FRESH_VM_PER_PROVIDER="${GEMMA_4_SQL_AB_FRESH_VM_PER_PROVIDER:-0}"
GEMMA_4_SQL_BACKENDS="${GEMMA_4_SQL_BACKENDS:-${TPU_ALL_BACKENDS}}"
GEMMA_4_SQL_SUBSUITES="${GEMMA_4_SQL_SUBSUITES:-E0,E1,E2,E3,E4}"
GEMMA_4_SQL_RENDER_LATEX="${GEMMA_4_SQL_RENDER_LATEX:-0}"
GEMMA_4_SQL_DRY_RUN="${GEMMA_4_SQL_DRY_RUN:-0}"
_PASS_ARGS=''

while [ $# -gt 0 ]; do
  case "$1" in
    --tfrc-config=*) TFRC_CONFIG="${1#*=}"; TFRC_STRICT='1'; export TFRC_CONFIG TFRC_STRICT; shift ;;
    --tfrc-config) TFRC_CONFIG="$2"; TFRC_STRICT='1'; export TFRC_CONFIG TFRC_STRICT; shift 2 ;;
    --repo-dir=*) GEMMA_4_SQL_REPO_DIR="${1#*=}"; shift ;;
    --repo-dir) GEMMA_4_SQL_REPO_DIR="$2"; shift 2 ;;
    --results-dir=*|--out-dir=*) GEMMA_4_SQL_AB_RESULTS_DIR="${1#*=}"; shift ;;
    --results-dir|--out-dir) GEMMA_4_SQL_AB_RESULTS_DIR="$2"; shift 2 ;;
    --providers=*) GEMMA_4_SQL_AB_PROVIDERS="${1#*=}"; shift ;;
    --providers) GEMMA_4_SQL_AB_PROVIDERS="$2"; shift 2 ;;
    --backends=*) GEMMA_4_SQL_BACKENDS="${1#*=}"; shift ;;
    --backends) GEMMA_4_SQL_BACKENDS="$2"; shift 2 ;;
    --subsuites=*) GEMMA_4_SQL_SUBSUITES="${1#*=}"; shift ;;
    --subsuites) GEMMA_4_SQL_SUBSUITES="$2"; shift 2 ;;
    --fresh-vm-per-provider) GEMMA_4_SQL_AB_FRESH_VM_PER_PROVIDER='1'; shift ;;
    --render-latex) GEMMA_4_SQL_RENDER_LATEX='1'; shift ;;
    --dry-run|-n) GEMMA_4_SQL_DRY_RUN='1'; shift ;;
    --local-exec) export GEMMA_4_SQL_LOCAL_EXEC='1'; shift ;;
    *) shift ;;
  esac
done

if [ "${GEMMA_4_SQL_BACKENDS}" = 'all' ]; then
  GEMMA_4_SQL_BACKENDS="${TPU_ALL_BACKENDS}"
fi

# ## release_or_cycle_between_providers
# Releases /dev/accel* locks across workers or reprovisions a fresh TPU VM slice between 'og' and 'rs' provider passes.
release_or_cycle_between_providers() {
  if [ -z "${TPU_NAME:-}" ]; then
    if [ "${GEMMA_4_SQL_LOCAL_EXEC:-0}" = '1' ]; then
      libscript_tpu_release_local_locks
    fi
    return 0
  fi
  _cli="${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/gcp-tpu-vm/cli.sh"
  if [ "${GEMMA_4_SQL_AB_FRESH_VM_PER_PROVIDER}" = '1' ]; then
    TPU_FRESH_VM_PER_BACKEND='1' TPU_BOOTSTRAP_LIBTPU_RS='1' \
      libscript_tpu_cycle_vm_for_backend "${TPU_NAME}" 'jax_native' "${GEMMA_4_SQL_REPO_DIR}" ''
  else
    "${_cli}" release-locks "${TPU_NAME}"
  fi
}

# ## run_gemma4_libtpu_ab_campaign
# Executes gemma-4-sql across GEMMA_4_SQL_AB_PROVIDERS and invokes differential synthesis.
run_gemma4_libtpu_ab_campaign() {
  GEMMA_4_SQL_REPO_DIR=$(cd -- "${GEMMA_4_SQL_REPO_DIR}" && pwd)
  mkdir -p "${GEMMA_4_SQL_AB_RESULTS_DIR}/og/raw" "${GEMMA_4_SQL_AB_RESULTS_DIR}/rs/raw"
  GEMMA_4_SQL_AB_RESULTS_DIR=$(cd -- "${GEMMA_4_SQL_AB_RESULTS_DIR}" && pwd)

  if [ "${GEMMA_4_SQL_DRY_RUN}" = '1' ]; then
    if libscript_tfrc_is_enabled; then
      libscript_tfrc_require_config "${GEMMA_4_SQL_REPO_DIR}"
      libscript_tfrc_enforce_zero_cost_env
    fi
    log_info "[DRY-RUN] gemma-4-sql-libtpu validated: providers=${GEMMA_4_SQL_AB_PROVIDERS} backends=${GEMMA_4_SQL_BACKENDS} subsuites=${GEMMA_4_SQL_SUBSUITES} results=${GEMMA_4_SQL_AB_RESULTS_DIR}"
    return 0
  fi

  if [ "${GEMMA_4_SQL_RENDER_LATEX}" = '1' ]; then
    "${SCRIPT_DIR}/suites/synthesize_ab.sh" "${GEMMA_4_SQL_REPO_DIR}" "${GEMMA_4_SQL_AB_RESULTS_DIR}" "${GEMMA_4_SQL_BACKENDS}"
    return 0
  fi

  _first=1
  for _prov in $(printf '%s' "${GEMMA_4_SQL_AB_PROVIDERS}" | tr ',;' '  '); do
    if [ "${_first}" -eq 0 ]; then
      release_or_cycle_between_providers
    fi
    _first=0
    STACK='' GEMMA_4_SQL_LIBTPU_PROVIDER="${_prov}" TPU_LIBTPU_PROVIDER="${_prov}" \
      "${LIBSCRIPT_ROOT_DIR}/experiments/gemma-4-sql/benchmark_experiments.sh" \
      --repo-dir="${GEMMA_4_SQL_REPO_DIR}" \
      --results-dir="${GEMMA_4_SQL_AB_RESULTS_DIR}/${_prov}" \
      --backends="${GEMMA_4_SQL_BACKENDS}" \
      --subsuites="${GEMMA_4_SQL_SUBSUITES}" \
      --libtpu-provider="${_prov}"
  done

  "${SCRIPT_DIR}/suites/synthesize_ab.sh" "${GEMMA_4_SQL_REPO_DIR}" "${GEMMA_4_SQL_AB_RESULTS_DIR}" "${GEMMA_4_SQL_BACKENDS}"
}

run_gemma4_libtpu_ab_campaign
