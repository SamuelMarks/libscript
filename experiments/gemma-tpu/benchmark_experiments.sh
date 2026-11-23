#!/bin/sh
# ## Overview
# Master idempotent 7-backend TFRC TPU benchmark orchestrator (benchmark_experiments.sh) routing E0–E4 locally on TPU workers or remotely across --worker=all with per-cell result streaming.
#
# ## Usage
# ./experiments/gemma-tpu/benchmark_experiments.sh [--tfrc-config=<path>] [--repo-dir=<dir>] [--results-dir=<dir>] [--backends=<csv|all>] [--subsuites=E0,E1,E2,E3,E4]
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

for _be_lib in engine/common/log.sh engine/common/remote_sync.sh engine/common/tfrc_guard.sh workloads/ai/_common/tpu_matrix.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_be_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _be_lib || true

# ## show_suite_help
# Prints CLI options for gemma-tpu-suite benchmark_experiments.sh.
show_suite_help() {
  printf '%s\n' "Usage: ${THIS_FILE} [--tfrc-config=<path>] [--repo-dir=<dir>] [--results-dir=<dir>] [--model=<id>] [--backends=<csv|all>] [--subsuites=E0,E1,E2,E3,E4] [--command-template=<tpl>] [--fresh-vm-per-backend] [--resume] [--local-exec]"
}

GEMMA_TPU_SUITE_REPO_DIR="${GEMMA_TPU_SUITE_REPO_DIR:-$(pwd)}"
GEMMA_TPU_SUITE_RESULTS_DIR="${GEMMA_TPU_SUITE_RESULTS_DIR:-${LIBSCRIPT_ROOT_DIR}/build/experiment_results/gemma_tpu}"
GEMMA_TPU_SUITE_MODEL="${GEMMA_TPU_SUITE_MODEL:-google/gemma-4-E4B}"
GEMMA_TPU_SUITE_BACKENDS="${GEMMA_TPU_SUITE_BACKENDS:-${TPU_ALL_BACKENDS}}"
GEMMA_TPU_SUITE_SUBSUITES="${GEMMA_TPU_SUITE_SUBSUITES:-E0,E1,E2,E3,E4}"
GEMMA_TPU_SUITE_WARMUP="${GEMMA_TPU_SUITE_WARMUP:-2}"
GEMMA_TPU_SUITE_TRIALS="${GEMMA_TPU_SUITE_TRIALS:-5}"
GEMMA_TPU_SUITE_REQUIRE_HBM="${GEMMA_TPU_SUITE_REQUIRE_HBM:-1}"
GEMMA_TPU_SUITE_RESUME="${GEMMA_TPU_SUITE_RESUME:-1}"
GEMMA_TPU_SUITE_LOCAL_EXEC="${GEMMA_TPU_SUITE_LOCAL_EXEC:-0}"
GEMMA_TPU_SUITE_DRY_RUN="${GEMMA_TPU_SUITE_DRY_RUN:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) show_suite_help; exit 0 ;;
    experiments|benchmark-matrix) shift ;;
    --repo-dir=*) GEMMA_TPU_SUITE_REPO_DIR="${1#*=}"; shift ;;
    --repo-dir) GEMMA_TPU_SUITE_REPO_DIR="$2"; shift 2 ;;
    --results-dir=*|--output-dir=*) GEMMA_TPU_SUITE_RESULTS_DIR="${1#*=}"; shift ;;
    --results-dir|--output-dir) GEMMA_TPU_SUITE_RESULTS_DIR="$2"; shift 2 ;;
    --tfrc-config=*) TFRC_CONFIG="${1#*=}"; export TFRC_CONFIG; shift ;;
    --tfrc-config) TFRC_CONFIG="$2"; export TFRC_CONFIG; shift 2 ;;
    --model=*) GEMMA_TPU_SUITE_MODEL="${1#*=}"; shift ;;
    --model) GEMMA_TPU_SUITE_MODEL="$2"; shift 2 ;;
    --backends=*) GEMMA_TPU_SUITE_BACKENDS="${1#*=}"; shift ;;
    --backends) GEMMA_TPU_SUITE_BACKENDS="$2"; shift 2 ;;
    --subsuites=*) GEMMA_TPU_SUITE_SUBSUITES="${1#*=}"; shift ;;
    --subsuites) GEMMA_TPU_SUITE_SUBSUITES="$2"; shift 2 ;;
    --command-template=*) GEMMA_TPU_SUITE_COMMAND_TEMPLATE="${1#*=}"; shift ;;
    --command-template) GEMMA_TPU_SUITE_COMMAND_TEMPLATE="$2"; shift 2 ;;
    --warmup=*) GEMMA_TPU_SUITE_WARMUP="${1#*=}"; shift ;;
    --warmup) GEMMA_TPU_SUITE_WARMUP="$2"; shift 2 ;;
    --trials=*) GEMMA_TPU_SUITE_TRIALS="${1#*=}"; shift ;;
    --trials) GEMMA_TPU_SUITE_TRIALS="$2"; shift 2 ;;
    --fresh-vm-per-backend) TPU_FRESH_VM_PER_BACKEND='1'; export TPU_FRESH_VM_PER_BACKEND; shift ;;
    --resume) GEMMA_TPU_SUITE_RESUME='1'; shift ;;
    --no-resume) GEMMA_TPU_SUITE_RESUME='0'; shift ;;
    --require-tpu-hbm) GEMMA_TPU_SUITE_REQUIRE_HBM='1'; shift ;;
    --no-require-tpu-hbm) GEMMA_TPU_SUITE_REQUIRE_HBM='0'; shift ;;
    --local-exec) GEMMA_TPU_SUITE_LOCAL_EXEC='1'; shift ;;
    --dry-run) GEMMA_TPU_SUITE_DRY_RUN='1'; shift ;;
    *) shift ;;
  esac
done

if [ "${GEMMA_TPU_SUITE_BACKENDS}" = 'all' ]; then
  GEMMA_TPU_SUITE_BACKENDS="${TPU_ALL_BACKENDS}"
fi
export GEMMA_TPU_SUITE_REPO_DIR GEMMA_TPU_SUITE_RESULTS_DIR GEMMA_TPU_SUITE_MODEL
export GEMMA_TPU_SUITE_BACKENDS GEMMA_TPU_SUITE_SUBSUITES GEMMA_TPU_SUITE_WARMUP GEMMA_TPU_SUITE_TRIALS
export GEMMA_TPU_SUITE_REQUIRE_HBM GEMMA_TPU_SUITE_RESUME GEMMA_TPU_SUITE_LOCAL_EXEC
export GEMMA_TPU_SUITE_COMMAND_TEMPLATE="${GEMMA_TPU_SUITE_COMMAND_TEMPLATE:-}"

mkdir -p "${GEMMA_TPU_SUITE_RESULTS_DIR}/raw"

if [ "${GEMMA_TPU_SUITE_DRY_RUN}" = '1' ]; then
  if libscript_tfrc_is_enabled; then
    libscript_tfrc_require_config "${GEMMA_TPU_SUITE_REPO_DIR}"
    libscript_tfrc_enforce_zero_cost_env
  fi
  printf '[DRY-RUN] gemma-tpu-suite repo=%s results=%s model=%s backends=%s subsuites=%s\n' \
    "${GEMMA_TPU_SUITE_REPO_DIR}" "${GEMMA_TPU_SUITE_RESULTS_DIR}" "${GEMMA_TPU_SUITE_MODEL}" \
    "${GEMMA_TPU_SUITE_BACKENDS}" "${GEMMA_TPU_SUITE_SUBSUITES}"
  exit 0
fi

# ## subsuite_enabled
# Returns 0 if a sub-suite ID (E0..E4) is present in GEMMA_TPU_SUITE_SUBSUITES.
subsuite_enabled() {
  case ",${GEMMA_TPU_SUITE_SUBSUITES}," in
    *,"$1",*) return 0 ;;
    *) return 1 ;;
  esac
}

# ## pull_remote_artifact_atomic
# Streams a single completed JSON artifact from TPU worker 0 and validates JSON syntax before atomic mv -f.
pull_remote_artifact_atomic() {
  _pra_tpu="$1"
  _pra_rel="$2"
  _pra_local="${GEMMA_TPU_SUITE_RESULTS_DIR}/${_pra_rel}"
  mkdir -p "$(dirname -- "${_pra_local}")"
  "${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/gcp-tpu-vm/cli.sh" scp "${_pra_tpu}" "${_pra_tpu}:~/results/${_pra_rel}" "${_pra_local}.tmp" --worker=0
  jq -e . "${_pra_local}.tmp" >/dev/null
  mv -f "${_pra_local}.tmp" "${_pra_local}"
}

# ## run_suite_matrix
# Executes E0–E4 locally on worker/stub or dispatches per-backend cells across a remote Cloud TPU VM slice.
run_suite_matrix() {
  if [ "${GEMMA_TPU_SUITE_LOCAL_EXEC}" = '1' ] || [ -z "${TPU_NAME:-}" ]; then
    if subsuite_enabled 'E0'; then
      "${SCRIPT_DIR}/suites/e0_tfrc_provenance.sh" "${GEMMA_TPU_SUITE_REPO_DIR}" "${GEMMA_TPU_SUITE_RESULTS_DIR}" "${GEMMA_TPU_SUITE_BACKENDS}"
    fi
    _first_be=1
    _old_ifs="${IFS}"
    IFS=','
    for _bid in ${GEMMA_TPU_SUITE_BACKENDS}; do
      IFS="${_old_ifs}"
      [ -n "${_bid}" ] || continue
      if [ "${_first_be}" -eq 0 ] && [ -n "${TPU_NAME:-}" ]; then
        libscript_tpu_cycle_vm_for_backend "${TPU_NAME}" "${_bid}" "${GEMMA_TPU_SUITE_REPO_DIR}"
      fi
      _first_be=0
      if subsuite_enabled 'E1'; then
        "${SCRIPT_DIR}/suites/e1_inference_throughput.sh" "${GEMMA_TPU_SUITE_REPO_DIR}" "${GEMMA_TPU_SUITE_RESULTS_DIR}" "${_bid}"
      fi
      if subsuite_enabled 'E2'; then
        "${SCRIPT_DIR}/suites/e2_sql_evaluation.sh" "${GEMMA_TPU_SUITE_REPO_DIR}" "${GEMMA_TPU_SUITE_RESULTS_DIR}" "${_bid}"
      fi
      if subsuite_enabled 'E3'; then
        "${SCRIPT_DIR}/suites/e3_training_finetuning.sh" "${GEMMA_TPU_SUITE_REPO_DIR}" "${GEMMA_TPU_SUITE_RESULTS_DIR}" "${_bid}"
      fi
    done
    IFS="${_old_ifs}"
    if subsuite_enabled 'E4'; then
      "${SCRIPT_DIR}/suites/e4_custom_matrix_and_synthesis.sh" "${GEMMA_TPU_SUITE_REPO_DIR}" "${GEMMA_TPU_SUITE_RESULTS_DIR}" "${GEMMA_TPU_SUITE_BACKENDS}"
    fi
    return 0
  fi

  _tree_hash=$(libscript_compute_tree_hash "${GEMMA_TPU_SUITE_REPO_DIR}")
  if subsuite_enabled 'E0'; then
    libscript_tpu_run_lockstep "${TPU_NAME}" 'jax_native' "./libscript/experiments/gemma-tpu/suites/e0_tfrc_provenance.sh ./workspace ./results '${GEMMA_TPU_SUITE_BACKENDS}'" "${GEMMA_TPU_SUITE_RESULTS_DIR}/logs/E0"
    pull_remote_artifact_atomic "${TPU_NAME}" 'raw/e0_provenance.json'
  fi

  _first_be=1
  _old_ifs="${IFS}"
  IFS=','
  for _bid in ${GEMMA_TPU_SUITE_BACKENDS}; do
    IFS="${_old_ifs}"
    [ -n "${_bid}" ] || continue
    if [ "${_first_be}" -eq 0 ]; then
      libscript_tpu_cycle_vm_for_backend "${TPU_NAME}" "${_bid}" "${GEMMA_TPU_SUITE_REPO_DIR}"
    fi
    _first_be=0

    if subsuite_enabled 'E1'; then
      _e1_f="${GEMMA_TPU_SUITE_RESULTS_DIR}/raw/e1_inference_${_bid}.json"
      if [ "${GEMMA_TPU_SUITE_RESUME}" = '1' ] && [ -f "${_e1_f}" ] && jq -e --arg th "${_tree_hash}" '.status == "ok" and .tree_hash == $th' "${_e1_f}" >/dev/null 2>&1; then
        log_info "Skipping completed remote cell E1/${_bid} (--resume)."
      else
        libscript_tpu_run_lockstep "${TPU_NAME}" "${_bid}" "GEMMA_TPU_SUITE_MODEL='${GEMMA_TPU_SUITE_MODEL}' GEMMA_TPU_SUITE_WARMUP='${GEMMA_TPU_SUITE_WARMUP}' ./libscript/experiments/gemma-tpu/suites/e1_inference_throughput.sh ./workspace ./results '${_bid}'" "${GEMMA_TPU_SUITE_RESULTS_DIR}/logs/E1_${_bid}"
        pull_remote_artifact_atomic "${TPU_NAME}" "raw/e1_inference_${_bid}.json"
      fi
    fi

    if subsuite_enabled 'E2'; then
      _e2_f="${GEMMA_TPU_SUITE_RESULTS_DIR}/raw/e2_sql_eval_${_bid}.json"
      if [ "${GEMMA_TPU_SUITE_RESUME}" = '1' ] && [ -f "${_e2_f}" ] && jq -e --arg th "${_tree_hash}" '.status == "ok" and .tree_hash == $th' "${_e2_f}" >/dev/null 2>&1; then
        log_info "Skipping completed remote cell E2/${_bid} (--resume)."
      else
        libscript_tpu_run_lockstep "${TPU_NAME}" "${_bid}" "GEMMA_TPU_SUITE_MODEL='${GEMMA_TPU_SUITE_MODEL}' ./libscript/experiments/gemma-tpu/suites/e2_sql_evaluation.sh ./workspace ./results '${_bid}'" "${GEMMA_TPU_SUITE_RESULTS_DIR}/logs/E2_${_bid}"
        pull_remote_artifact_atomic "${TPU_NAME}" "raw/e2_sql_eval_${_bid}.json"
      fi
    fi

    if subsuite_enabled 'E3'; then
      _e3_f="${GEMMA_TPU_SUITE_RESULTS_DIR}/raw/e3_training_${_bid}.json"
      if [ "${GEMMA_TPU_SUITE_RESUME}" = '1' ] && [ -f "${_e3_f}" ] && jq -e --arg th "${_tree_hash}" '.status == "ok" and .tree_hash == $th' "${_e3_f}" >/dev/null 2>&1; then
        log_info "Skipping completed remote cell E3/${_bid} (--resume)."
      else
        libscript_tpu_run_lockstep "${TPU_NAME}" "${_bid}" "GEMMA_TPU_SUITE_MODEL='${GEMMA_TPU_SUITE_MODEL}' ./libscript/experiments/gemma-tpu/suites/e3_training_finetuning.sh ./workspace ./results '${_bid}'" "${GEMMA_TPU_SUITE_RESULTS_DIR}/logs/E3_${_bid}"
        pull_remote_artifact_atomic "${TPU_NAME}" "raw/e3_training_${_bid}.json"
      fi
    fi
  done
  IFS="${_old_ifs}"

  if subsuite_enabled 'E4'; then
    if [ -n "${GEMMA_TPU_SUITE_COMMAND_TEMPLATE}" ] || { [ -f "${GEMMA_TPU_SUITE_REPO_DIR}/libscript.json" ] && jq -e '((.ml.command_matrix // []) | length) > 0' "${GEMMA_TPU_SUITE_REPO_DIR}/libscript.json" >/dev/null 2>&1; }; then
      libscript_tpu_run_lockstep "${TPU_NAME}" 'jax_native' "GEMMA_TPU_SUITE_MODEL='${GEMMA_TPU_SUITE_MODEL}' GEMMA_TPU_SUITE_COMMAND_TEMPLATE='${GEMMA_TPU_SUITE_COMMAND_TEMPLATE}' ./libscript/experiments/gemma-tpu/suites/e4_custom_matrix_and_synthesis.sh ./workspace ./results '${GEMMA_TPU_SUITE_BACKENDS}'" "${GEMMA_TPU_SUITE_RESULTS_DIR}/logs/E4"
      pull_remote_artifact_atomic "${TPU_NAME}" 'comparison_summary.json'
    fi
    GEMMA_TPU_SUITE_SKIP_CUSTOM_EXEC='1' GEMMA_TPU_SUITE_LOCAL_EXEC='1' "${SCRIPT_DIR}/suites/e4_custom_matrix_and_synthesis.sh" "${GEMMA_TPU_SUITE_REPO_DIR}" "${GEMMA_TPU_SUITE_RESULTS_DIR}" "${GEMMA_TPU_SUITE_BACKENDS}"
  fi
}

run_suite_matrix
