#!/bin/sh
# ## Overview
# Suite E3 runner (e3_training_finetuning.sh): Benchmarks SFT, LoRA (PEFT), and DPO training throughput, step time, loss trajectory sanity, and peak TPU HBM across all 7 TPU backends.
#
# ## Usage
# ./experiments/gemma-4-sql/suites/e3_training_finetuning.sh <repo_dir> <results_dir> <backend_id>

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

_e3_this="${THIS_FILE}"
_e3_dir="${SCRIPT_DIR}"
for _lib in engine/common/log.sh engine/common/remote_sync.sh workloads/ai/_common/tpu_matrix.sh experiments/gemma-4-sql/suites/stage_ab_telemetry.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _lib || true
THIS_FILE="${_e3_this}"
SCRIPT_DIR="${_e3_dir}"

REPO_ARG="$1"
RESULTS_ARG="$2"
BACKEND_ID="$3"
MODEL_NAME="${GEMMA_4_SQL_MODEL:-google/gemma-4-E4B}"
DATASET_ID="${GEMMA_4_SQL_DATASET:-gemma-4-sql-bench}"
SHM_ROOT="${GEMMA_4_SQL_SHM_ROOT:-/dev/shm/libscript-tpu}"

# ## prepare_train_dataset_fixture
# Idempotently writes deterministic SFT/PEFT and DPO JSONL training fixtures under RESULTS_DIR/fixtures when default dataset ID is selected.
prepare_train_dataset_fixture() {
  _tf_dir="$1"
  mkdir -p "${_tf_dir}"
  if [ ! -f "${_tf_dir}/train_sft_seed42.jsonl" ]; then
    cat <<'SFT_EOF' > "${_tf_dir}/train_sft_seed42.jsonl"
{"prompt":"List department names with average salary above 100000","completion":"SELECT d.name FROM departments d JOIN employees e ON d.id = e.dept_id GROUP BY d.id, d.name HAVING AVG(e.salary) > 100000;"}
{"prompt":"Count total employees in Engineering","completion":"SELECT COUNT(*) FROM employees e JOIN departments d ON e.dept_id = d.id WHERE d.name = 'Engineering';"}
SFT_EOF
  fi
  if [ ! -f "${_tf_dir}/train_dpo_seed42.jsonl" ]; then
    cat <<'DPO_EOF' > "${_tf_dir}/train_dpo_seed42.jsonl"
{"prompt":"Count total employees in Engineering","chosen":"SELECT COUNT(*) FROM employees e JOIN departments d ON e.dept_id = d.id WHERE d.name = 'Engineering';","rejected":"SELECT * FROM employees;"}
DPO_EOF
  fi
}

# ## extract_train_metric
# Extracts a required numeric training metric via jq, failing immediately if absent or non-numeric.
extract_train_metric() {
  _etm_f="$1"
  _etm_q="$2"
  _etm_lbl="$3"
  [ -f "${_etm_f}" ] || { log_error "Missing training output file ${_etm_f} (${_etm_lbl})"; return 1; }
  _etm_v=$(jq -er "${_etm_q}" "${_etm_f}" 2>/dev/null || true)
  case "${_etm_v}" in
    ''|null|*[!0-9.-]*)
      log_error "Missing or invalid numeric metric '${_etm_lbl}' in ${_etm_f}: '${_etm_v}'"
      return 1
      ;;
  esac
  printf '%s\n' "${_etm_v}"
}

# ## run_e3_backend
# Executes SFT, LoRA (PEFT), and DPO training runs for BACKEND_ID with Stage B HBM verification and strict loss/throughput validation.
run_e3_backend() {
  REPO_DIR=$(cd -- "${REPO_ARG}" && pwd)
  mkdir -p "${RESULTS_ARG}/raw"
  RESULTS_DIR=$(cd -- "${RESULTS_ARG}" && pwd)
  OUT_FILE="${RESULTS_DIR}/raw/e3_training_${BACKEND_ID}.json"

  _tree_hash=$(libscript_compute_tree_hash "${REPO_DIR}")
  if [ "${GEMMA_4_SQL_RESUME:-1}" = '1' ] && [ -f "${OUT_FILE}" ]; then
    if jq -e --arg th "${_tree_hash}" '.status == "ok" and .tree_hash == $th' "${OUT_FILE}" >/dev/null 2>&1; then
      log_info "[RESUME] Skipping completed E3 cell for ${BACKEND_ID} (tree_hash=${_tree_hash})."
      return 0
    fi
  fi

  _vdir=$(libscript_tpu_prepare_backend_venv "${BACKEND_ID}" "${REPO_DIR}" "${SHM_ROOT}")
  _spec=$(libscript_tpu_backend_spec "${BACKEND_ID}" "${SHM_ROOT}")
  _cli_be=$(printf '%s' "${_spec}" | cut -d'|' -f2)
  _benv=$(printf '%s' "${_spec}" | cut -d'|' -f7)
  _fam=$(libscript_tpu_family_label "${BACKEND_ID}")

  _fix_dir="${RESULTS_DIR}/fixtures"
  prepare_train_dataset_fixture "${_fix_dir}"
  _sft_ds="${DATASET_ID}"
  _dpo_ds="${DATASET_ID}"
  if [ "${DATASET_ID}" = 'gemma-4-sql-bench' ]; then
    _sft_ds="${_fix_dir}/train_sft_seed42.jsonl"
    _dpo_ds="${_fix_dir}/train_dpo_seed42.jsonl"
  fi

  _strict_flag=''
  if [ "${GEMMA_4_SQL_REQUIRE_HBM:-1}" = '1' ]; then
    _strict_flag='--strict-hardware'
  fi

  _raw_sft="${RESULTS_DIR}/raw/.w_e3_sft_${BACKEND_ID}.json"
  _raw_peft="${RESULTS_DIR}/raw/.w_e3_peft_${BACKEND_ID}.json"
  _raw_dpo="${RESULTS_DIR}/raw/.w_e3_dpo_${BACKEND_ID}.json"
  rm -f "${_raw_sft}" "${_raw_peft}" "${_raw_dpo}"

  _wcmd="export ${_benv}; PATH='${_vdir}/bin':\"\$PATH\"; cd '${REPO_DIR}' && gemma-4-sql sft --model '${MODEL_NAME}' --dataset '${_sft_ds}' --hardware tpu ${_strict_flag} --dtype bfloat16 --backend '${_cli_be}' --output-json '${_raw_sft}' && gemma-4-sql peft --model '${MODEL_NAME}' --dataset '${_sft_ds}' --hardware tpu ${_strict_flag} --dtype bfloat16 --backend '${_cli_be}' --output-json '${_raw_peft}' && gemma-4-sql dpo --model '${MODEL_NAME}' --dataset '${_dpo_ds}' --hardware tpu ${_strict_flag} --dtype bfloat16 --backend '${_cli_be}' --output-json '${_raw_dpo}'"

  gemma_4_sql_exec_with_stage_b "${BACKEND_ID}" "${_wcmd}" "${OUT_FILE}" "${GEMMA_4_SQL_REQUIRE_HBM:-1}" "${_raw_peft}"

  _sft_tpsc=$(extract_train_metric "${_raw_sft}" '.tokens_per_sec_per_chip // .tokens_per_sec' 'sft.tokens_per_sec_per_chip')
  _peft_tpsc=$(extract_train_metric "${_raw_peft}" '.tokens_per_sec_per_chip // .tokens_per_sec' 'peft.tokens_per_sec_per_chip')
  _step_ms=$(extract_train_metric "${_raw_peft}" '.step_time_ms // .latency_ms' 'peft.step_time_ms')
  _loss_init=$(extract_train_metric "${_raw_peft}" '.initial_loss' 'peft.initial_loss')
  _loss_final=$(extract_train_metric "${_raw_peft}" '.final_loss' 'peft.final_loss')
  _dpo_tpsc=$(extract_train_metric "${_raw_dpo}" '.tokens_per_sec_per_chip // .tokens_per_sec' 'dpo.tokens_per_sec_per_chip')
  rm -f "${_raw_sft}" "${_raw_peft}" "${_raw_dpo}"

  jq -n \
    --arg b "${BACKEND_ID}" \
    --arg fam "${_fam}" \
    --arg m "${MODEL_NAME}" \
    --arg th "${_tree_hash}" \
    --argjson sft_tps "${_sft_tpsc}" \
    --argjson peft_tps "${_peft_tpsc}" \
    --argjson dpo_tps "${_dpo_tpsc}" \
    --argjson step_ms "${_step_ms}" \
    --argjson loss_init "${_loss_init}" \
    --argjson loss_fin "${_loss_final}" \
    --argjson fd "${STAGE_B_ACCEL_FD}" \
    --argjson hbm "${STAGE_B_PEAK_HBM}" \
    '{
      suite: "E3",
      experiment_id: "gemma-4-sql",
      backend_id: $b,
      comparison_family: $fam,
      model: $m,
      status: "ok",
      tree_hash: $th,
      sft_tokens_per_sec_per_chip: $sft_tps,
      peft_tokens_per_sec_per_chip: $peft_tps,
      dpo_tokens_per_sec_per_chip: $dpo_tps,
      step_time_ms: $step_ms,
      loss_trajectory: {
        initial_loss: $loss_init,
        final_loss: $loss_fin,
        loss_decreased: ($loss_fin < $loss_init)
      },
      telemetry: { accelerator_fd_opened: $fd, peak_tpu_hbm_bytes: $hbm }
    }' > "${OUT_FILE}.tmp"
  jq -e . "${OUT_FILE}.tmp" >/dev/null
  mv -f "${OUT_FILE}.tmp" "${OUT_FILE}"
  log_info "Emitted E3 training artifact -> ${OUT_FILE}"
}

run_e3_backend
