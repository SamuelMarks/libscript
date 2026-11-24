#!/bin/sh
# ## Overview
# Master idempotent 7-backend TFRC TPU benchmark orchestrator (benchmark_experiments.sh) for `gemma-4-sql`, routing E0-E4 locally or across Cloud TPU VM --worker=all with per-cell result streaming and LaTeX synthesis.
#
# ## Usage
# ./experiments/gemma-4-sql/benchmark_experiments.sh [--tfrc-config=<path>] [--repo-dir=<dir>] [--results-dir=<dir>] [--backends=<csv|all>] [--subsuites=E0,E1,E2,E3,E4] [--render-latex]

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

_be_this="${THIS_FILE}"
_be_dir="${SCRIPT_DIR}"
for _lib in engine/common/log.sh engine/common/remote_sync.sh engine/common/tfrc_guard.sh workloads/ai/_common/tpu_matrix.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _lib || true
THIS_FILE="${_be_this}"
SCRIPT_DIR="${_be_dir}"

# ## show_help
# Prints CLI options for gemma-4-sql benchmark_experiments.sh.
show_help() {
  printf '%s\n' "Usage: ${THIS_FILE} [--tfrc-config=<path>] [--repo-dir=<dir>] [--results-dir=<dir>] [--paper-dir=<dir>] [--model=<id>] [--backends=<csv|all>] [--subsuites=E0,E1,E2,E3,E4] [--batch-sizes=1,8,32] [--warmup=<n>] [--trials=<n>] [--dataset=<id>] [--db-types=sqlite,duckdb] [--command-template=<tpl>] [--fresh-vm-per-backend] [--resume|--no-resume] [--local-exec] [--render-latex] [--build-pdf] [--dry-run]"
}

GEMMA_4_SQL_REPO_DIR="${GEMMA_4_SQL_REPO_DIR:-${REPO_DIR:-$(pwd)}}"
GEMMA_4_SQL_RESULTS_DIR="${GEMMA_4_SQL_RESULTS_DIR:-${RESULTS_DIR:-${OUT_DIR:-${LIBSCRIPT_ROOT_DIR}/build/experiment_results/gemma-4-sql}}}"
GEMMA_4_SQL_PAPER_DIR="${GEMMA_4_SQL_PAPER_DIR:-${PAPER_DIR:-}}"
GEMMA_4_SQL_MODEL="${GEMMA_4_SQL_MODEL:-${MODEL:-google/gemma-4-E4B}}"
GEMMA_4_SQL_BACKENDS="${GEMMA_4_SQL_BACKENDS:-${BACKENDS:-${TPU_ALL_BACKENDS}}}"
GEMMA_4_SQL_SUBSUITES="${GEMMA_4_SQL_SUBSUITES:-${SUBSUITES:-E0,E1,E2,E3,E4}}"
GEMMA_4_SQL_BATCH_SIZES="${GEMMA_4_SQL_BATCH_SIZES:-1,8,32}"
GEMMA_4_SQL_WARMUP="${GEMMA_4_SQL_WARMUP:-${WARMUP:-2}}"
GEMMA_4_SQL_TRIALS="${GEMMA_4_SQL_TRIALS:-${TRIALS:-5}}"
GEMMA_4_SQL_DATASET="${GEMMA_4_SQL_DATASET:-gemma-4-sql-bench}"
GEMMA_4_SQL_DB_TYPES="${GEMMA_4_SQL_DB_TYPES:-sqlite,duckdb}"
GEMMA_4_SQL_COMMAND_TEMPLATE="${GEMMA_4_SQL_COMMAND_TEMPLATE:-}"
GEMMA_4_SQL_REQUIRE_HBM="${GEMMA_4_SQL_REQUIRE_HBM:-1}"
GEMMA_4_SQL_RESUME="${GEMMA_4_SQL_RESUME:-1}"
GEMMA_4_SQL_LOCAL_EXEC="${GEMMA_4_SQL_LOCAL_EXEC:-0}"
GEMMA_4_SQL_SHM_ROOT="${GEMMA_4_SQL_SHM_ROOT:-/dev/shm/libscript-tpu}"
GEMMA_4_SQL_RENDER_LATEX="${GEMMA_4_SQL_RENDER_LATEX:-0}"
GEMMA_4_SQL_BUILD_PDF="${GEMMA_4_SQL_BUILD_PDF:-0}"
GEMMA_4_SQL_DRY_RUN="${GEMMA_4_SQL_DRY_RUN:-${DRY_RUN:-0}}"

case "${1:-}" in
  experiments|benchmark-matrix|tpu_matrix) shift ;;
esac

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) show_help; exit 0 ;;
    --tfrc-config=*) TFRC_CONFIG="${1#*=}"; TFRC_STRICT='1'; export TFRC_CONFIG TFRC_STRICT; shift ;;
    --tfrc-config) TFRC_CONFIG="$2"; TFRC_STRICT='1'; export TFRC_CONFIG TFRC_STRICT; shift 2 ;;
    --repo-dir=*|--repo=*) GEMMA_4_SQL_REPO_DIR="${1#*=}"; shift ;;
    --repo-dir|--repo) GEMMA_4_SQL_REPO_DIR="$2"; shift 2 ;;
    --results-dir=*|--out-dir=*) GEMMA_4_SQL_RESULTS_DIR="${1#*=}"; shift ;;
    --results-dir|--out-dir) GEMMA_4_SQL_RESULTS_DIR="$2"; shift 2 ;;
    --paper-dir=*) GEMMA_4_SQL_PAPER_DIR="${1#*=}"; shift ;;
    --paper-dir) GEMMA_4_SQL_PAPER_DIR="$2"; shift 2 ;;
    --model=*) GEMMA_4_SQL_MODEL="${1#*=}"; shift ;;
    --model) GEMMA_4_SQL_MODEL="$2"; shift 2 ;;
    --backends=*) GEMMA_4_SQL_BACKENDS="${1#*=}"; shift ;;
    --backends) GEMMA_4_SQL_BACKENDS="$2"; shift 2 ;;
    --subsuites=*) GEMMA_4_SQL_SUBSUITES="${1#*=}"; shift ;;
    --subsuites) GEMMA_4_SQL_SUBSUITES="$2"; shift 2 ;;
    --batch-sizes=*) GEMMA_4_SQL_BATCH_SIZES="${1#*=}"; shift ;;
    --batch-sizes) GEMMA_4_SQL_BATCH_SIZES="$2"; shift 2 ;;
    --warmup=*) GEMMA_4_SQL_WARMUP="${1#*=}"; shift ;;
    --warmup) GEMMA_4_SQL_WARMUP="$2"; shift 2 ;;
    --trials=*) GEMMA_4_SQL_TRIALS="${1#*=}"; shift ;;
    --trials) GEMMA_4_SQL_TRIALS="$2"; shift 2 ;;
    --dataset=*) GEMMA_4_SQL_DATASET="${1#*=}"; shift ;;
    --dataset) GEMMA_4_SQL_DATASET="$2"; shift 2 ;;
    --db-types=*) GEMMA_4_SQL_DB_TYPES="${1#*=}"; shift ;;
    --db-types) GEMMA_4_SQL_DB_TYPES="$2"; shift 2 ;;
    --command-template=*) GEMMA_4_SQL_COMMAND_TEMPLATE="${1#*=}"; shift ;;
    --command-template) GEMMA_4_SQL_COMMAND_TEMPLATE="$2"; shift 2 ;;
    --shm-root=*) GEMMA_4_SQL_SHM_ROOT="${1#*=}"; shift ;;
    --shm-root) GEMMA_4_SQL_SHM_ROOT="$2"; shift 2 ;;
    --fresh-vm-per-backend) TPU_FRESH_VM_PER_BACKEND='1'; export TPU_FRESH_VM_PER_BACKEND; shift ;;
    --resume) GEMMA_4_SQL_RESUME='1'; shift ;;
    --no-resume) GEMMA_4_SQL_RESUME='0'; shift ;;
    --require-tpu-hbm) GEMMA_4_SQL_REQUIRE_HBM='1'; shift ;;
    --no-require-tpu-hbm) GEMMA_4_SQL_REQUIRE_HBM='0'; shift ;;
    --local-exec) GEMMA_4_SQL_LOCAL_EXEC='1'; shift ;;
    --render-latex) GEMMA_4_SQL_RENDER_LATEX='1'; shift ;;
    --build-pdf) GEMMA_4_SQL_BUILD_PDF='1'; shift ;;
    --dry-run) GEMMA_4_SQL_DRY_RUN='1'; shift ;;
    *) shift ;;
  esac
done

if [ "${GEMMA_4_SQL_BACKENDS}" = 'all' ]; then
  GEMMA_4_SQL_BACKENDS="${TPU_ALL_BACKENDS}"
fi

if [ -d "${GEMMA_4_SQL_REPO_DIR}" ]; then
  GEMMA_4_SQL_REPO_DIR=$(cd -- "${GEMMA_4_SQL_REPO_DIR}" && pwd)
fi
mkdir -p "${GEMMA_4_SQL_RESULTS_DIR}/raw"
GEMMA_4_SQL_RESULTS_DIR=$(cd -- "${GEMMA_4_SQL_RESULTS_DIR}" && pwd)
TPU_SUITE_MANIFEST_PATH="${SCRIPT_DIR}/suite.json"

export GEMMA_4_SQL_REPO_DIR GEMMA_4_SQL_RESULTS_DIR GEMMA_4_SQL_PAPER_DIR GEMMA_4_SQL_MODEL GEMMA_4_SQL_BACKENDS GEMMA_4_SQL_SUBSUITES GEMMA_4_SQL_BATCH_SIZES GEMMA_4_SQL_WARMUP GEMMA_4_SQL_TRIALS GEMMA_4_SQL_DATASET GEMMA_4_SQL_DB_TYPES GEMMA_4_SQL_COMMAND_TEMPLATE GEMMA_4_SQL_REQUIRE_HBM GEMMA_4_SQL_RESUME GEMMA_4_SQL_LOCAL_EXEC GEMMA_4_SQL_SHM_ROOT GEMMA_4_SQL_RENDER_LATEX GEMMA_4_SQL_BUILD_PDF GEMMA_4_SQL_DRY_RUN TPU_SUITE_MANIFEST_PATH

# ## sync_paper_and_build_pdf
# Copies generated_metrics.tex into GEMMA_4_SQL_PAPER_DIR and optionally builds the LaTeX manuscript PDF.
sync_paper_and_build_pdf() {
  if [ -n "${GEMMA_4_SQL_PAPER_DIR}" ] && [ -f "${GEMMA_4_SQL_RESULTS_DIR}/generated_metrics.tex" ]; then
    mkdir -p "${GEMMA_4_SQL_PAPER_DIR}"
    cp -f "${GEMMA_4_SQL_RESULTS_DIR}/generated_metrics.tex" "${GEMMA_4_SQL_PAPER_DIR}/generated_metrics.tex.tmp"
    mv -f "${GEMMA_4_SQL_PAPER_DIR}/generated_metrics.tex.tmp" "${GEMMA_4_SQL_PAPER_DIR}/generated_metrics.tex"
    if [ "${GEMMA_4_SQL_BUILD_PDF}" = '1' ]; then
      if command -v latexmk >/dev/null 2>&1; then
        (cd -- "${GEMMA_4_SQL_PAPER_DIR}" && latexmk -pdf -interaction=nonstopmode main.tex)
      elif command -v pdflatex >/dev/null 2>&1; then
        (cd -- "${GEMMA_4_SQL_PAPER_DIR}" && pdflatex -interaction=nonstopmode main.tex)
      else
        log_error 'Neither latexmk nor pdflatex is installed for --build-pdf.'
        return 1
      fi
    fi
  fi
}

if [ "${GEMMA_4_SQL_DRY_RUN}" = '1' ] || [ "${GEMMA_4_SQL_DRY_RUN}" = 'true' ]; then
  if libscript_tfrc_is_enabled; then
    libscript_tfrc_require_config "${GEMMA_4_SQL_REPO_DIR}"
    libscript_tfrc_enforce_zero_cost_env
  fi
  log_info "[DRY-RUN] gemma-4-sql validated: backends=${GEMMA_4_SQL_BACKENDS} subsuites=${GEMMA_4_SQL_SUBSUITES} model=${GEMMA_4_SQL_MODEL} results=${GEMMA_4_SQL_RESULTS_DIR}"
  exit 0
fi

if [ "${GEMMA_4_SQL_RENDER_LATEX}" = '1' ]; then
  GEMMA_4_SQL_SKIP_CUSTOM_EXEC='1' GEMMA_4_SQL_LOCAL_EXEC='1' "${SCRIPT_DIR}/suites/e4_custom_matrix_and_synthesis.sh" "${GEMMA_4_SQL_REPO_DIR}" "${GEMMA_4_SQL_RESULTS_DIR}" "${GEMMA_4_SQL_BACKENDS}"
  sync_paper_and_build_pdf
  exit 0
fi

# ## subsuite_enabled
# Returns 0 if a sub-suite ID (E0..E4) is present in GEMMA_4_SQL_SUBSUITES.
subsuite_enabled() {
  case ",${GEMMA_4_SQL_SUBSUITES}," in
    *,"$1",*) return 0 ;;
    *) return 1 ;;
  esac
}

# ## pull_remote_artifact_atomic
# Streams a single completed JSON artifact from TPU worker 0 and validates JSON syntax before atomic mv -f.
pull_remote_artifact_atomic() {
  _pra_tpu="$1"
  _pra_rel="$2"
  _pra_local="${GEMMA_4_SQL_RESULTS_DIR}/${_pra_rel}"
  mkdir -p "$(dirname -- "${_pra_local}")"
  "${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/gcp-tpu-vm/cli.sh" scp-from "${_pra_tpu}" "${_pra_tpu}:~/results/${_pra_rel}" "${_pra_local}.tmp" --worker=0
  jq -e . "${_pra_local}.tmp" >/dev/null
  mv -f "${_pra_local}.tmp" "${_pra_local}"
}

# ## pull_remote_custom_artifacts
# Discovers and pulls all remote raw/e4_custom_*.json files from worker 0 prior to local E4 synthesis.
pull_remote_custom_artifacts() {
  _prc_tpu="$1"
  _prc_cli="${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/gcp-tpu-vm/cli.sh"
  _prc_list=$("${_prc_cli}" ssh "${_prc_tpu}" --worker=0 --command="ls -1 \$HOME/results/raw/e4_custom_*.json 2>/dev/null || true" 2>/dev/null || true)
  for _prc_f in ${_prc_list}; do
    _prc_base=$(basename -- "${_prc_f}")
    case "${_prc_base}" in
      e4_custom_*.json)
        pull_remote_artifact_atomic "${_prc_tpu}" "raw/${_prc_base}"
        ;;
    esac
  done
}

# ## run_suite_matrix
# Executes E0-E4 locally on worker/host or dispatches per-backend cells across a remote Cloud TPU VM slice.
run_suite_matrix() {
  if [ "${GEMMA_4_SQL_LOCAL_EXEC}" = '1' ] || [ -z "${TPU_NAME:-}" ]; then
    libscript_tpu_ensure_host_tools '0'
    if subsuite_enabled 'E0'; then
      "${SCRIPT_DIR}/suites/e0_tfrc_provenance.sh" "${GEMMA_4_SQL_REPO_DIR}" "${GEMMA_4_SQL_RESULTS_DIR}" "${GEMMA_4_SQL_BACKENDS}"
    fi
    _first_be=1
    _old_ifs="${IFS}"
    IFS=','
    for _bid in ${GEMMA_4_SQL_BACKENDS}; do
      IFS="${_old_ifs}"
      [ -n "${_bid}" ] || continue
      if [ "${_first_be}" -eq 0 ] && [ -n "${TPU_NAME:-}" ]; then
        libscript_tpu_cycle_vm_for_backend "${TPU_NAME}" "${_bid}" "${GEMMA_4_SQL_REPO_DIR}"
      fi
      _first_be=0
      if subsuite_enabled 'E1'; then
        "${SCRIPT_DIR}/suites/e1_inference_throughput.sh" "${GEMMA_4_SQL_REPO_DIR}" "${GEMMA_4_SQL_RESULTS_DIR}" "${_bid}"
      fi
      if subsuite_enabled 'E2'; then
        "${SCRIPT_DIR}/suites/e2_sql_evaluation.sh" "${GEMMA_4_SQL_REPO_DIR}" "${GEMMA_4_SQL_RESULTS_DIR}" "${_bid}"
      fi
      if subsuite_enabled 'E3'; then
        "${SCRIPT_DIR}/suites/e3_training_finetuning.sh" "${GEMMA_4_SQL_REPO_DIR}" "${GEMMA_4_SQL_RESULTS_DIR}" "${_bid}"
      fi
      IFS=','
    done
    IFS="${_old_ifs}"
    if subsuite_enabled 'E4'; then
      "${SCRIPT_DIR}/suites/e4_custom_matrix_and_synthesis.sh" "${GEMMA_4_SQL_REPO_DIR}" "${GEMMA_4_SQL_RESULTS_DIR}" "${GEMMA_4_SQL_BACKENDS}"
    fi
    sync_paper_and_build_pdf
    return 0
  fi

  libscript_tpu_ensure_host_tools '1'
  _rem_env="GEMMA_4_SQL_LOCAL_EXEC=1 GEMMA_4_SQL_MODEL='${GEMMA_4_SQL_MODEL}' GEMMA_4_SQL_BATCH_SIZES='${GEMMA_4_SQL_BATCH_SIZES}' GEMMA_4_SQL_WARMUP='${GEMMA_4_SQL_WARMUP}' GEMMA_4_SQL_TRIALS='${GEMMA_4_SQL_TRIALS}' GEMMA_4_SQL_DATASET='${GEMMA_4_SQL_DATASET}' GEMMA_4_SQL_DB_TYPES='${GEMMA_4_SQL_DB_TYPES}' GEMMA_4_SQL_REQUIRE_HBM='${GEMMA_4_SQL_REQUIRE_HBM}' GEMMA_4_SQL_RESUME='${GEMMA_4_SQL_RESUME}' GEMMA_4_SQL_SHM_ROOT='${GEMMA_4_SQL_SHM_ROOT}'"

  if subsuite_enabled 'E0'; then
    libscript_tpu_run_lockstep "${TPU_NAME}" 'jax_native' "${_rem_env} \"\$HOME/libscript/experiments/gemma-4-sql/suites/e0_tfrc_provenance.sh\" \"\$HOME/workspace\" \"\$HOME/results\" '${GEMMA_4_SQL_BACKENDS}'" "${GEMMA_4_SQL_RESULTS_DIR}/logs/e0"
    pull_remote_artifact_atomic "${TPU_NAME}" 'raw/e0_provenance.json'
  fi

  _first_be=1
  _old_ifs="${IFS}"
  IFS=','
  for _bid in ${GEMMA_4_SQL_BACKENDS}; do
    IFS="${_old_ifs}"
    [ -n "${_bid}" ] || continue
    if [ "${_first_be}" -eq 0 ]; then
      libscript_tpu_cycle_vm_for_backend "${TPU_NAME}" "${_bid}" "${GEMMA_4_SQL_REPO_DIR}"
    fi
    _first_be=0

    if subsuite_enabled 'E1'; then
      if ! libscript_tpu_run_lockstep "${TPU_NAME}" "${_bid}" "${_rem_env} \"\$HOME/libscript/experiments/gemma-4-sql/suites/e1_inference_throughput.sh\" \"\$HOME/workspace\" \"\$HOME/results\" '${_bid}'" "${GEMMA_4_SQL_RESULTS_DIR}/logs/e1_${_bid}"; then
        pull_remote_artifact_atomic "${TPU_NAME}" "raw/e1_inference_${_bid}.json" || true
        return 65
      fi
      pull_remote_artifact_atomic "${TPU_NAME}" "raw/e1_inference_${_bid}.json"
    fi
    if subsuite_enabled 'E2'; then
      if ! libscript_tpu_run_lockstep "${TPU_NAME}" "${_bid}" "${_rem_env} \"\$HOME/libscript/experiments/gemma-4-sql/suites/e2_sql_evaluation.sh\" \"\$HOME/workspace\" \"\$HOME/results\" '${_bid}'" "${GEMMA_4_SQL_RESULTS_DIR}/logs/e2_${_bid}"; then
        pull_remote_artifact_atomic "${TPU_NAME}" "raw/e2_sql_eval_${_bid}.json" || true
        return 65
      fi
      pull_remote_artifact_atomic "${TPU_NAME}" "raw/e2_sql_eval_${_bid}.json"
    fi
    if subsuite_enabled 'E3'; then
      if ! libscript_tpu_run_lockstep "${TPU_NAME}" "${_bid}" "${_rem_env} \"\$HOME/libscript/experiments/gemma-4-sql/suites/e3_training_finetuning.sh\" \"\$HOME/workspace\" \"\$HOME/results\" '${_bid}'" "${GEMMA_4_SQL_RESULTS_DIR}/logs/e3_${_bid}"; then
        pull_remote_artifact_atomic "${TPU_NAME}" "raw/e3_training_${_bid}.json" || true
        return 65
      fi
      pull_remote_artifact_atomic "${TPU_NAME}" "raw/e3_training_${_bid}.json"
    fi
    IFS=','
  done
  IFS="${_old_ifs}"

  if subsuite_enabled 'E4'; then
    _custom_esc=$(printf '%s' "${GEMMA_4_SQL_COMMAND_TEMPLATE}" | awk '{gsub(/\x27/, "\x27\\\x27\x27"); printf "%s", $0}')
    libscript_tpu_run_lockstep "${TPU_NAME}" 'jax_native' "${_rem_env} GEMMA_4_SQL_COMMAND_TEMPLATE='${_custom_esc}' \"\$HOME/libscript/experiments/gemma-4-sql/suites/e4_custom_matrix_and_synthesis.sh\" \"\$HOME/workspace\" \"\$HOME/results\" '${GEMMA_4_SQL_BACKENDS}'" "${GEMMA_4_SQL_RESULTS_DIR}/logs/e4"
    pull_remote_custom_artifacts "${TPU_NAME}"
    GEMMA_4_SQL_SKIP_CUSTOM_EXEC='1' GEMMA_4_SQL_LOCAL_EXEC='1' "${SCRIPT_DIR}/suites/e4_custom_matrix_and_synthesis.sh" "${GEMMA_4_SQL_REPO_DIR}" "${GEMMA_4_SQL_RESULTS_DIR}" "${GEMMA_4_SQL_BACKENDS}"
  fi
  sync_paper_and_build_pdf
}

run_suite_matrix
