#!/bin/sh
# ## Overview
# Suite E4 runner (e4_custom_matrix_and_synthesis.sh): Executes custom templated commands across backends and synthesizes 5-family + 7-backend comparison_summary.{json,csv,md} and \gemmaFourSql* generated_metrics.tex.
#
# ## Usage
# ./experiments/gemma-4-sql/suites/e4_custom_matrix_and_synthesis.sh <repo_dir> <results_dir> [backends_csv]

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

_e4_this="${THIS_FILE}"
_e4_dir="${SCRIPT_DIR}"
for _lib in engine/common/log.sh engine/common/remote_sync.sh workloads/ai/_common/tpu_matrix.sh experiments/gemma-4-sql/suites/stage_ab_telemetry.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _lib || true
THIS_FILE="${_e4_this}"
SCRIPT_DIR="${_e4_dir}"

REPO_ARG="${1:-$(pwd)}"
RESULTS_ARG="${2:-${LIBSCRIPT_ROOT_DIR}/build/experiment_results/gemma-4-sql}"
BACKENDS_CSV="${3:-${GEMMA_4_SQL_BACKENDS:-${TPU_ALL_BACKENDS}}}"
MODEL_NAME="${GEMMA_4_SQL_MODEL:-google/gemma-4-E4B}"
SHM_ROOT="${GEMMA_4_SQL_SHM_ROOT:-/dev/shm/libscript-tpu}"

# ## expand_workload_template
# Expands {backend}, {cli_backend}, {keras_backend}, {model}, {batch_size}, {output_json}, {repo_dir}, and {results_dir} tokens safely via jq.
expand_workload_template() {
  jq -rn \
    --arg tpl "$1" \
    --arg bid "$2" \
    --arg cbe "$3" \
    --arg kbe "$4" \
    --arg out "$5" \
    --arg model "${MODEL_NAME}" \
    --arg repo "${REPO_DIR}" \
    --arg res "${RESULTS_DIR}" \
    '$tpl
     | gsub("\\{backend\\}"; $bid)
     | gsub("\\{cli_backend\\}"; $cbe)
     | gsub("\\{keras_backend\\}"; $kbe)
     | gsub("\\{model\\}"; $model)
     | gsub("\\{batch_size\\}"; "8")
     | gsub("\\{output_json\\}"; $out)
     | gsub("\\{repo_dir\\}"; $repo)
     | gsub("\\{results_dir\\}"; $res)'
}

# ## backend_tex_slug
# Maps backend_id to a CamelCase suffix for \gemmaFourSql* LaTeX macro generation.
backend_tex_slug() {
  case "$1" in
    hf_transformers) printf 'HfTransformers' ;;
    pytorch_native) printf 'PytorchNative' ;;
    keras_jax) printf 'KerasJax' ;;
    keras_tensorflow) printf 'KerasTensorflow' ;;
    keras_pytorch) printf 'KerasPytorch' ;;
    maxtext) printf 'Maxtext' ;;
    jax_native) printf 'JaxNative' ;;
    *) printf 'Custom' ;;
  esac
}

# ## run_e4_custom_and_synthesize
# Runs any custom command templates across backends and emits 5-family + 7-backend comparison_summary.{json,csv,md} and generated_metrics.tex.
run_e4_custom_and_synthesize() {
  REPO_DIR=$(cd -- "${REPO_ARG}" && pwd)
  mkdir -p "${RESULTS_ARG}/raw"
  RESULTS_DIR=$(cd -- "${RESULTS_ARG}" && pwd)

  _tree_hash=$(libscript_compute_tree_hash "${REPO_DIR}")
  _templates_json='[]'
  if [ "${GEMMA_4_SQL_SKIP_CUSTOM_EXEC:-0}" != '1' ]; then
    if [ -n "${GEMMA_4_SQL_COMMAND_TEMPLATE:-}" ]; then
      _templates_json=$(printf '%s' "${_templates_json}" | jq --arg t "${GEMMA_4_SQL_COMMAND_TEMPLATE}" '. + [$t]')
    fi
    if [ -f "${REPO_DIR}/libscript.json" ]; then
      _m_list=$(jq -c 'if (.ml.command_matrix | type) == "array" then .ml.command_matrix elif (.ml.command_matrix | type) == "string" then [.ml.command_matrix] else [] end' "${REPO_DIR}/libscript.json" 2>/dev/null || printf '[]')
      _templates_json=$(jq -nc --argjson a "${_templates_json}" --argjson b "${_m_list}" '$a + $b')
    fi
  fi

  _tpl_count=$(printf '%s' "${_templates_json}" | jq 'length')
  if [ "${_tpl_count}" -gt 0 ]; then
    _t_idx=0
    while [ "${_t_idx}" -lt "${_tpl_count}" ]; do
      _tpl=$(printf '%s' "${_templates_json}" | jq -r ".[${_t_idx}]")
      _old_ifs="${IFS}"
      IFS=','
      for _bid in ${BACKENDS_CSV}; do
        IFS="${_old_ifs}"
        [ -n "${_bid}" ] || continue
        _cout="${RESULTS_DIR}/raw/e4_custom_${_t_idx}_${_bid}.json"
        if [ "${GEMMA_4_SQL_RESUME:-1}" = '1' ] && [ -f "${_cout}" ] && jq -e --arg th "${_tree_hash}" '.status == "ok" and .tree_hash == $th' "${_cout}" >/dev/null 2>&1; then
          IFS=','
          continue
        fi
        _vdir=$(libscript_tpu_prepare_backend_venv "${_bid}" "${REPO_DIR}" "${SHM_ROOT}" "${GEMMA_4_SQL_LIBTPU_PROVIDER:-og}")
        _penv=$(libscript_tpu_provider_env "${_vdir}" "${GEMMA_4_SQL_LIBTPU_PROVIDER:-og}")
        _spec=$(libscript_tpu_backend_spec "${_bid}" "${SHM_ROOT}")
        _cbe=$(printf '%s' "${_spec}" | cut -d'|' -f2)
        _kbe=$(printf '%s' "${_spec}" | cut -d'|' -f3)
        _benv=$(printf '%s' "${_spec}" | cut -d'|' -f7)
        _raw_w="${RESULTS_DIR}/raw/.w_e4_${_t_idx}_${_bid}.json"
        rm -f "${_raw_w}"
        _exp_cmd=$(expand_workload_template "${_tpl}" "${_bid}" "${_cbe}" "${_kbe}" "${_raw_w}")
        _full_cmd="export ${_benv} ${_penv}; PATH='${_vdir}/bin':\"\$PATH\"; cd '${REPO_DIR}' && ${_exp_cmd}"
        gemma_4_sql_exec_with_stage_b "${_bid}" "${_full_cmd}" "${_cout}" "${GEMMA_4_SQL_REQUIRE_HBM:-1}" "${_raw_w}"
        _payload='{}'
        if [ -f "${_raw_w}" ]; then
          _payload=$(cat "${_raw_w}" 2>/dev/null || printf '{}')
          rm -f "${_raw_w}"
        fi
        jq -n \
          --arg b "${_bid}" \
          --arg th "${_tree_hash}" \
          --arg cmd "${_exp_cmd}" \
          --argjson idx "${_t_idx}" \
          --argjson p "${_payload}" \
          --argjson hbm "${STAGE_B_PEAK_HBM}" \
          '{suite:"E4", experiment_id:"gemma-4-sql", backend_id:$b, template_index:$idx, status:"ok", tree_hash:$th, command:$cmd, workload_output:$p, peak_tpu_hbm_bytes:$hbm}' > "${_cout}.tmp"
        mv -f "${_cout}.tmp" "${_cout}"
        IFS=','
      done
      IFS="${_old_ifs}"
      _t_idx=$(( _t_idx + 1 ))
    done
  fi

  _rows='[]'
  _old_ifs="${IFS}"
  IFS=','
  for _bid in ${BACKENDS_CSV}; do
    IFS="${_old_ifs}"
    [ -n "${_bid}" ] || continue
    _fam=$(libscript_tpu_family_label "${_bid}")
    _e1_f="${RESULTS_DIR}/raw/e1_inference_${_bid}.json"
    _e2_f="${RESULTS_DIR}/raw/e2_sql_eval_${_bid}.json"
    _e3_f="${RESULTS_DIR}/raw/e3_training_${_bid}.json"
    _pre=$( [ -f "${_e1_f}" ] && jq -r '.prefill_tokens_per_sec // 0' "${_e1_f}" || printf '0' )
    _tps=$( [ -f "${_e1_f}" ] && jq -r '.decode_tokens_per_sec // 0' "${_e1_f}" || printf '0' )
    _cms=$( [ -f "${_e1_f}" ] && jq -r '.cold_compile_ms // 0' "${_e1_f}" || printf '0' )
    _p50=$( [ -f "${_e1_f}" ] && jq -r '.latency_ms.p50 // 0' "${_e1_f}" || printf '0' )
    _p99=$( [ -f "${_e1_f}" ] && jq -r '.latency_ms.p99 // 0' "${_e1_f}" || printf '0' )
    _sqa=$( [ -f "${_e2_f}" ] && jq -r '.sqlite_execution_accuracy // 0' "${_e2_f}" || printf '0' )
    _dka=$( [ -f "${_e2_f}" ] && jq -r '.duckdb_execution_accuracy // 0' "${_e2_f}" || printf '0' )
    _acc=$( [ -f "${_e2_f}" ] && jq -r '.sql_execution_accuracy // 0' "${_e2_f}" || printf '0' )
    _tpsc=$( [ -f "${_e3_f}" ] && jq -r '.peft_tokens_per_sec_per_chip // 0' "${_e3_f}" || printf '0' )
    _hbm=$( [ -f "${_e1_f}" ] && jq -r '.telemetry.peak_tpu_hbm_bytes // 0' "${_e1_f}" || printf '0' )
    if [ "${_hbm}" = '0' ] && [ -f "${_e3_f}" ]; then
      _hbm=$(jq -r '.telemetry.peak_tpu_hbm_bytes // 0' "${_e3_f}" || printf '0')
    fi
    _rows=$(printf '%s' "${_rows}" | jq \
      --arg b "${_bid}" \
      --arg fam "${_fam}" \
      --arg slug "$(backend_tex_slug "${_bid}")" \
      --argjson pre "${_pre}" \
      --argjson tps "${_tps}" \
      --argjson cms "${_cms}" \
      --argjson p50 "${_p50}" \
      --argjson p99 "${_p99}" \
      --argjson sqa "${_sqa}" \
      --argjson dka "${_dka}" \
      --argjson acc "${_acc}" \
      --argjson tpsc "${_tpsc}" \
      --argjson hbm "${_hbm}" \
      '. + [{backend_id: $b, comparison_family: $fam, tex_slug: $slug, prefill_tokens_per_sec: $pre, inference_tokens_per_sec: $tps, cold_compile_ms: $cms, latency_p50_ms: $p50, latency_p99_ms: $p99, sqlite_execution_accuracy: $sqa, duckdb_execution_accuracy: $dka, sql_execution_accuracy: $acc, train_tokens_per_sec_per_chip: $tpsc, peak_tpu_hbm_bytes: $hbm}]')
    IFS=','
  done
  IFS="${_old_ifs}"

  _custom_arr='[]'
  for _cf_name in $(ls -1 "${RESULTS_DIR}/raw" 2>/dev/null || true); do
    case "${_cf_name}" in
      e4_custom_*.json)
        _cf="${RESULTS_DIR}/raw/${_cf_name}"
        [ -f "${_cf}" ] || continue
        _custom_arr=$(printf '%s' "${_custom_arr}" | jq --slurpfile c "${_cf}" '. + $c')
        ;;
    esac
  done

  jq -n \
    --arg m "${MODEL_NAME}" \
    --argjson rows "${_rows}" \
    --argjson custom "${_custom_arr}" \
    '
    (($rows | map(select(.backend_id == "hf_transformers") | .inference_tokens_per_sec)[0]) // ($rows[0].inference_tokens_per_sec // 1)) as $base_tps |
    (if $base_tps <= 0 then 1 else $base_tps end) as $safe_base |
    (($rows | map(select(.backend_id == "hf_transformers") | .train_tokens_per_sec_per_chip)[0]) // ($rows[0].train_tokens_per_sec_per_chip // 1)) as $base_trn |
    (if $base_trn <= 0 then 1 else $base_trn end) as $safe_trn |
    ($rows | map(. + {
      relative_inference_speedup: (((.inference_tokens_per_sec / $safe_base) * 1000 | round) / 1000),
      relative_training_speedup: (((.train_tokens_per_sec_per_chip / $safe_trn) * 1000 | round) / 1000)
    })) as $enriched |
    ([
      "Hugging Face Transformers [which wraps PyTorch]",
      "PyTorch [native]",
      "Keras [and its JAX, TensorFlow, and PyTorch backends]",
      "MaxText [which wraps JAX]",
      "JAX [native]"
    ] | map(. as $f | ($enriched | map(select(.comparison_family == $f))) as $grp | select(($grp | length) > 0) | {
      comparison_family: $f,
      backend_cells: ($grp | map(.backend_id)),
      peak_inference_tokens_per_sec: ($grp | map(.inference_tokens_per_sec) | max),
      mean_sql_execution_accuracy: ((($grp | map(.sql_execution_accuracy) | add) / ($grp | length)) * 10000 | round / 10000),
      peak_train_tokens_per_sec_per_chip: ($grp | map(.train_tokens_per_sec_per_chip) | max)
    })) as $families |
    {
      suite: "gemma-4-sql",
      title: "gemma-4-sql: TPU performance comparisons betwixt JAX, Keras, and PyTorch on Google'\''s Gemma 4",
      model: $m,
      baseline_backend: "hf_transformers",
      comparison_families: $families,
      backends: $enriched,
      custom_workloads: $custom
    }' > "${RESULTS_DIR}/comparison_summary.json.tmp"
  jq -e . "${RESULTS_DIR}/comparison_summary.json.tmp" >/dev/null
  mv -f "${RESULTS_DIR}/comparison_summary.json.tmp" "${RESULTS_DIR}/comparison_summary.json"

  jq -r '
    ["backend_id","comparison_family","prefill_tokens_per_sec","inference_tokens_per_sec","cold_compile_ms","sqlite_execution_accuracy","duckdb_execution_accuracy","sql_execution_accuracy","train_tokens_per_sec_per_chip","peak_tpu_hbm_bytes","relative_inference_speedup","relative_training_speedup"],
    (.backends[] | [.backend_id, .comparison_family, .prefill_tokens_per_sec, .inference_tokens_per_sec, .cold_compile_ms, .sqlite_execution_accuracy, .duckdb_execution_accuracy, .sql_execution_accuracy, .train_tokens_per_sec_per_chip, .peak_tpu_hbm_bytes, .relative_inference_speedup, .relative_training_speedup])
    | @csv
  ' "${RESULTS_DIR}/comparison_summary.json" > "${RESULTS_DIR}/comparison_summary.csv.tmp"
  mv -f "${RESULTS_DIR}/comparison_summary.csv.tmp" "${RESULTS_DIR}/comparison_summary.csv"

  {
    printf '# gemma-4-sql: TPU performance comparisons betwixt JAX, Keras, and PyTorch on Google'\''s Gemma 4\n\n'
    printf "## 5-Family Architectural Comparison (\`%s\`)\n\n" "${MODEL_NAME}"
    printf '| Comparison Family | Backend Cells | Peak Decode tok/s | Mean SQL Acc | Peak Train tok/s/chip |\n'
    printf '| :--- | :--- | ---: | ---: | ---: |\n'
    jq -r '.comparison_families[] | "| `\(.comparison_family)` | `\(.backend_cells | join(", "))` | \(.peak_inference_tokens_per_sec) | \(.mean_sql_execution_accuracy) | \(.peak_train_tokens_per_sec_per_chip) |"' "${RESULTS_DIR}/comparison_summary.json"
    printf "\n## 7-Backend Runtime Matrix (\`%s\`)\n\n" "${MODEL_NAME}"
    printf '| Backend | Family | Prefill tok/s | Decode tok/s | SQLite Acc | DuckDB Acc | Train tok/s/chip | Peak TPU HBM (B) | Speedup |\n'
    printf '| :--- | :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n'
    jq -r '.backends[] | "| `\(.backend_id)` | \(.comparison_family) | \(.prefill_tokens_per_sec) | \(.inference_tokens_per_sec) | \(.sqlite_execution_accuracy) | \(.duckdb_execution_accuracy) | \(.train_tokens_per_sec_per_chip) | \(.peak_tpu_hbm_bytes) | \(.relative_inference_speedup)x |"' "${RESULTS_DIR}/comparison_summary.json"
  } > "${RESULTS_DIR}/comparison_summary.md.tmp"
  mv -f "${RESULTS_DIR}/comparison_summary.md.tmp" "${RESULTS_DIR}/comparison_summary.md"

  {
    printf '%% Auto-generated by experiments/gemma-4-sql/suites/e4_custom_matrix_and_synthesis.sh\n'
    printf '\\providecommand{\\gemmaFourSqlStudyTitle}{gemma-4-sql: TPU performance comparisons betwixt JAX, Keras, and PyTorch on Google'\''s Gemma 4}\n'
    jq -r '.backends[] |
      "\\providecommand{\\gemmaFourSql\(.tex_slug)PrefillTps}{\(.prefill_tokens_per_sec)}\n" +
      "\\providecommand{\\gemmaFourSql\(.tex_slug)DecodeTps}{\(.inference_tokens_per_sec)}\n" +
      "\\providecommand{\\gemmaFourSql\(.tex_slug)CompileMs}{\(.cold_compile_ms)}\n" +
      "\\providecommand{\\gemmaFourSql\(.tex_slug)SqlAcc}{\(.sql_execution_accuracy)}\n" +
      "\\providecommand{\\gemmaFourSql\(.tex_slug)DuckdbAcc}{\(.duckdb_execution_accuracy)}\n" +
      "\\providecommand{\\gemmaFourSql\(.tex_slug)TrainTpsChip}{\(.train_tokens_per_sec_per_chip)}\n" +
      "\\providecommand{\\gemmaFourSql\(.tex_slug)PeakHbmGiB}{\(((.peak_tpu_hbm_bytes / 1073741824) * 100 | round) / 100)}"
    ' "${RESULTS_DIR}/comparison_summary.json"
  } > "${RESULTS_DIR}/generated_metrics.tex.tmp"
  mv -f "${RESULTS_DIR}/generated_metrics.tex.tmp" "${RESULTS_DIR}/generated_metrics.tex"

  log_info "Synthesized 5-family / 7-backend comparison tables -> ${RESULTS_DIR}/comparison_summary.{json,csv,md}"
}

run_e4_custom_and_synthesize
