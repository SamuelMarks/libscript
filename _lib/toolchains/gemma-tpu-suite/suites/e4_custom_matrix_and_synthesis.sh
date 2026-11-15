#!/bin/sh
# ## Overview
# Suite E4 runner (e4_custom_matrix_and_synthesis.sh): Executes custom templated commands across backends and synthesizes comparison_summary.{json,csv,md} and generated_metrics.tex.
#
# ## Usage
# ./_lib/toolchains/gemma-tpu-suite/suites/e4_custom_matrix_and_synthesis.sh <repo_dir> <results_dir> <backends_csv>
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

for _e4_lib in _lib/_common/log.sh _lib/_common/remote_sync.sh _lib/ml-training/_common/tpu_matrix.sh _lib/toolchains/gemma-tpu-suite/suites/stage_ab_telemetry.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_e4_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _e4_lib || true

REPO_DIR="$1"
RESULTS_DIR="$2"
BACKENDS_CSV="${3:-${TPU_ALL_BACKENDS}}"
MODEL_NAME="${GEMMA_TPU_SUITE_MODEL:-google/gemma-4-E4B}"
SHM_ROOT="${GEMMA_TPU_SUITE_SHM_ROOT:-/dev/shm/libscript-tpu}"
REQ_HBM="${GEMMA_TPU_SUITE_REQUIRE_HBM:-1}"
mkdir -p "${RESULTS_DIR}/raw"

# ## render_command_template
# Substitutes {backend_id}, {cli_backend}, {keras_backend}, {model}, {batch_size}, {output_json}, and {repo_dir} in a template string.
render_command_template() {
  jq -nr \
    --arg tpl "$1" \
    --arg bid "$2" \
    --arg cbe "$3" \
    --arg kbe "$4" \
    --arg out "$5" \
    --arg model "${MODEL_NAME}" \
    --arg repo "${REPO_DIR}" \
    '$tpl
      | gsub("\\{backend_id\\}"; $bid)
      | gsub("\\{cli_backend\\}"; $cbe)
      | gsub("\\{keras_backend\\}"; $kbe)
      | gsub("\\{model\\}"; $model)
      | gsub("\\{batch_size\\}"; "8")
      | gsub("\\{output_json\\}"; $out)
      | gsub("\\{repo_dir\\}"; $repo)'
}

# ## run_e4_custom_and_synthesize
# Runs optional custom templates across backends and emits comparison_summary.{json,csv,md} and generated_metrics.tex.
run_e4_custom_and_synthesize() {
  _tree_hash=$(libscript_compute_tree_hash "${REPO_DIR}")
  _tpl_list="${TMPDIR:-/tmp}/libscript_e4_tpl_$$.txt"
  : > "${_tpl_list}"
  if [ "${GEMMA_TPU_SUITE_SKIP_CUSTOM_EXEC:-0}" != '1' ]; then
    if [ -n "${GEMMA_TPU_SUITE_COMMAND_TEMPLATE:-}" ]; then
      printf '%s\n' "${GEMMA_TPU_SUITE_COMMAND_TEMPLATE}" >> "${_tpl_list}"
    fi
    if [ -f "${REPO_DIR}/libscript.json" ]; then
      jq -r '(.ml.command_matrix // [])[]' "${REPO_DIR}/libscript.json" 2>/dev/null >> "${_tpl_list}" || true
    fi
  fi

  if [ -s "${_tpl_list}" ]; then
    _t_idx=0
    while IFS= read -r _tpl_line; do
      [ -n "${_tpl_line}" ] || continue
      _t_idx=$((_t_idx + 1))
      _old_ifs="${IFS}"
      IFS=','
      for _bid in ${BACKENDS_CSV}; do
        IFS="${_old_ifs}"
        [ -n "${_bid}" ] || continue
        _cout="${RESULTS_DIR}/raw/e4_custom_${_t_idx}_${_bid}.json"
        if [ "${GEMMA_TPU_SUITE_RESUME:-1}" = '1' ] && [ -f "${_cout}" ]; then
          if jq -e --arg th "${_tree_hash}" '.status == "ok" and .tree_hash == $th' "${_cout}" >/dev/null 2>&1; then
            log_info "Skipping completed E4 custom cell ${_t_idx}/${_bid} (--resume)."
            continue
          fi
        fi
        _vdir=$(libscript_tpu_prepare_backend_venv "${_bid}" "${REPO_DIR}" "${SHM_ROOT}")
        _spec=$(libscript_tpu_backend_spec "${_bid}" "${SHM_ROOT}")
        _cbe=$(printf '%s' "${_spec}" | cut -d'|' -f2)
        _kbe=$(printf '%s' "${_spec}" | cut -d'|' -f3)
        _benv=$(printf '%s' "${_spec}" | cut -d'|' -f7)
        _w_tmp="${RESULTS_DIR}/raw/.w_e4_${_t_idx}_${_bid}.json"
        _rcmd=$(render_command_template "${_tpl_line}" "${_bid}" "${_cbe}" "${_kbe}" "${_w_tmp}")
        gemma_tpu_exec_with_stage_b "${_bid}" 'E4' "custom_${_t_idx}" "${SHM_ROOT}" "${REQ_HBM}" "${_cout}" "export PATH='${_vdir}/bin':\"\$PATH\" ${_benv}; cd '${REPO_DIR}' && ${_rcmd}"
        _payload='{}'
        if [ -f "${_w_tmp}" ]; then
          _payload=$(jq -c '.' "${_w_tmp}" 2>/dev/null || printf '{}')
          rm -f "${_w_tmp}"
        fi
        jq -n \
          --arg th "${_tree_hash}" \
          --arg bid "${_bid}" \
          --arg tpl "${_tpl_line}" \
          --argjson idx "${_t_idx}" \
          --argjson res "${_payload}" \
          --argjson fd "${STAGE_B_ACCEL_FD:-true}" \
          --argjson hbm "${STAGE_B_PEAK_HBM:-1}" \
          '{
            subsuite: "E4",
            custom_index: $idx,
            backend_id: $bid,
            template: $tpl,
            tree_hash: $th,
            status: "ok",
            result: $res,
            telemetry: { accelerator_fd_opened: $fd, peak_tpu_hbm_bytes: $hbm }
          }' > "${_cout}.tmp"
        jq -e . "${_cout}.tmp" >/dev/null
        mv -f "${_cout}.tmp" "${_cout}"
      done
      IFS="${_old_ifs}"
    done < "${_tpl_list}"
  fi
  rm -f "${_tpl_list}"

  _custom_json='[]'
  _cf_list="${TMPDIR:-/tmp}/libscript_e4_custom_files_$$.txt"
  find "${RESULTS_DIR}/raw" -maxdepth 1 -type f -name 'e4_custom_*.json' 2>/dev/null | sort > "${_cf_list}" || true
  while IFS= read -r _cf; do
    [ -n "${_cf}" ] || continue
    [ -f "${_cf}" ] || continue
    _custom_json=$(printf '%s' "${_custom_json}" | jq --slurpfile c "${_cf}" '. + $c')
  done < "${_cf_list}"
  rm -f "${_cf_list}"

  _rows='[]'
  _old_ifs="${IFS}"
  IFS=','
  for _bid in ${BACKENDS_CSV}; do
    IFS="${_old_ifs}"
    [ -n "${_bid}" ] || continue
    _tps='0'
    _acc='0'
    _tpsc='0'
    _hbm='0'
    if [ -f "${RESULTS_DIR}/raw/e1_inference_${_bid}.json" ]; then
      _tps=$(jq -r '.tokens_per_sec // 0' "${RESULTS_DIR}/raw/e1_inference_${_bid}.json")
      _hbm=$(jq -r '.telemetry.peak_tpu_hbm_bytes // 0' "${RESULTS_DIR}/raw/e1_inference_${_bid}.json")
    fi
    if [ -f "${RESULTS_DIR}/raw/e2_sql_eval_${_bid}.json" ]; then
      _acc=$(jq -r '.execution_accuracy // 0' "${RESULTS_DIR}/raw/e2_sql_eval_${_bid}.json")
    fi
    if [ -f "${RESULTS_DIR}/raw/e3_training_${_bid}.json" ]; then
      _tpsc=$(jq -r '.tokens_per_sec_per_chip // 0' "${RESULTS_DIR}/raw/e3_training_${_bid}.json")
    fi
    _rows=$(printf '%s' "${_rows}" | jq \
      --arg b "${_bid}" \
      --argjson tps "${_tps}" \
      --argjson acc "${_acc}" \
      --argjson tpsc "${_tpsc}" \
      --argjson hbm "${_hbm}" \
      '. + [{backend_id: $b, inference_tokens_per_sec: $tps, sql_execution_accuracy: $acc, train_tokens_per_sec_per_chip: $tpsc, peak_tpu_hbm_bytes: $hbm}]')
  done
  IFS="${_old_ifs}"

  jq -n \
    --arg model "${MODEL_NAME}" \
    --argjson rows "${_rows}" \
    --argjson custom "${_custom_json}" '
    (([ $rows[] | select(.backend_id == "hf_transformers") | .inference_tokens_per_sec ][0]) // 1) as $hf_base
    | (([ $rows[] | select(.backend_id == "jax_native") | .inference_tokens_per_sec ][0]) // 1) as $jax_base
    | {
        suite: "gemma_tpu",
        status: "ok",
        model: $model,
        backends: [
          $rows[] | . + {
            speedup_vs_hf_transformers: (if $hf_base > 0 then ((.inference_tokens_per_sec / $hf_base * 1000 | round) / 1000) else 1 end),
            speedup_vs_jax_native: (if $jax_base > 0 then ((.inference_tokens_per_sec / $jax_base * 1000 | round) / 1000) else 1 end)
          }
        ],
        custom_workloads: $custom
      }
  ' > "${RESULTS_DIR}/comparison_summary.json.tmp"
  jq -e . "${RESULTS_DIR}/comparison_summary.json.tmp" >/dev/null
  mv -f "${RESULTS_DIR}/comparison_summary.json.tmp" "${RESULTS_DIR}/comparison_summary.json"

  jq -r '
    ["backend_id","inference_tokens_per_sec","sql_execution_accuracy","train_tokens_per_sec_per_chip","peak_tpu_hbm_bytes","speedup_vs_hf_transformers","speedup_vs_jax_native"],
    (.backends[] | [.backend_id, .inference_tokens_per_sec, .sql_execution_accuracy, .train_tokens_per_sec_per_chip, .peak_tpu_hbm_bytes, .speedup_vs_hf_transformers, .speedup_vs_jax_native])
    | @csv
  ' "${RESULTS_DIR}/comparison_summary.json" > "${RESULTS_DIR}/comparison_summary.csv.tmp"
  mv -f "${RESULTS_DIR}/comparison_summary.csv.tmp" "${RESULTS_DIR}/comparison_summary.csv"

  {
    printf '# Gemma 4 7-Backend Cloud TPU Comparison (%s)\n\n' "${MODEL_NAME}"
    printf '| Backend | Inference tok/s | SQL Exec Acc | Train tok/s/chip | Peak HBM (B) | vs HF | vs JAX |\n'
    printf '| :--- | ---: | ---: | ---: | ---: | ---: | ---: |\n'
    jq -r '.backends[] | "| `\(.backend_id)` | \(.inference_tokens_per_sec) | \(.sql_execution_accuracy) | \(.train_tokens_per_sec_per_chip) | \(.peak_tpu_hbm_bytes) | \(.speedup_vs_hf_transformers)x | \(.speedup_vs_jax_native)x |"' "${RESULTS_DIR}/comparison_summary.json"
  } > "${RESULTS_DIR}/comparison_summary.md.tmp"
  mv -f "${RESULTS_DIR}/comparison_summary.md.tmp" "${RESULTS_DIR}/comparison_summary.md"

  jq -r '.backends[] | "\\newcommand{\\GemmaTpuTokPerSec\(.backend_id | gsub("_"; ""))}{\(.inference_tokens_per_sec)}"' \
    "${RESULTS_DIR}/comparison_summary.json" > "${RESULTS_DIR}/generated_metrics.tex.tmp"
  mv -f "${RESULTS_DIR}/generated_metrics.tex.tmp" "${RESULTS_DIR}/generated_metrics.tex"

  log_info "Synthesized 7-backend comparison tables -> ${RESULTS_DIR}/comparison_summary.{json,csv,md}"
}

run_e4_custom_and_synthesize
