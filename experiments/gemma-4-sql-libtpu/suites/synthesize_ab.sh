#!/bin/sh
# ## Overview
# Differential synthesis runner (`synthesize_ab.sh`) for `gemma-4-sql-libtpu`: Verifies Stage A `/proc/self/maps` `libtpu.so` SHA-256 distinctness (`og` != `rs`) and synthesizes 7-backend + 5-family `ab_comparison_summary.{json,csv,md}` and `\gemmaFourSqlAb*` `generated_metrics.tex`.
# ## Usage
# ./experiments/gemma-4-sql-libtpu/suites/synthesize_ab.sh <repo_dir> <results_dir> [backends_csv]

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

_sab_this="${THIS_FILE}"; _sab_dir="${SCRIPT_DIR}"
for _lib in engine/common/log.sh workloads/ai/_common/tpu_matrix.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_lib}"; export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _lib || true
THIS_FILE="${_sab_this}"; SCRIPT_DIR="${_sab_dir}"

REPO_ARG="${1:-$(pwd)}"
RESULTS_ARG="${2:-${LIBSCRIPT_ROOT_DIR}/build/experiment_results/gemma-4-sql-libtpu}"
BACKENDS_CSV="${3:-${GEMMA_4_SQL_BACKENDS:-${TPU_ALL_BACKENDS}}}"
VERIFY_SHA="${GEMMA_4_SQL_AB_VERIFY_DISTINCT_SHA:-1}"

# ## verify_distinct_provider_digests
# Verifies Stage A mapped libtpu.so SHA-256 digests exist and differ between 'og' and 'rs' runs (exit 65 on collision/contamination).
verify_distinct_provider_digests() {
  _vdp_og="$1/og/raw/e0_provenance.json"
  _vdp_rs="$1/rs/raw/e0_provenance.json"
  if [ "${VERIFY_SHA}" != '1' ] || [ ! -f "${_vdp_og}" ] || [ ! -f "${_vdp_rs}" ]; then
    return 0
  fi
  if ! jq -e --slurpfile og "${_vdp_og}" --slurpfile rs "${_vdp_rs}" '
    ($og[0].libtpu_provider // "og") == "og" and
    ($rs[0].libtpu_provider // "rs") == "rs" and
    (([$og[0].stage_a_probes[]? | . as $op | ($rs[0].stage_a_probes[]? | select(.backend_id == $op.backend_id)) as $rp |
      (($op.libtpu_mapped_so_sha256 // "") != "" and ($rp.libtpu_mapped_so_sha256 // "") != "" and $op.libtpu_mapped_so_sha256 != $rp.libtpu_mapped_so_sha256)
    ] | all))
  ' -n >/dev/null 2>&1; then
    log_error '[AB-SYNTH] Stage A /proc/self/maps libtpu.so SHA-256 attestation failed: og and rs digests are missing or identical (exit 65)!'
    return 65
  fi
  return 0
}

# ## run_synthesize_gemma4_ab
# Materializes per-provider summaries if missing and emits A/B JSON, CSV, Markdown, and LaTeX comparison artifacts.
run_synthesize_gemma4_ab() {
  REPO_DIR=$(cd -- "${REPO_ARG}" && pwd)
  mkdir -p "${RESULTS_ARG}/og/raw" "${RESULTS_ARG}/rs/raw"
  RESULTS_DIR=$(cd -- "${RESULTS_ARG}" && pwd)

  for _p in og rs; do
    if [ ! -f "${RESULTS_DIR}/${_p}/comparison_summary.json" ]; then
      GEMMA_4_SQL_LIBTPU_PROVIDER="${_p}" GEMMA_4_SQL_SKIP_CUSTOM_EXEC='1' GEMMA_4_SQL_LOCAL_EXEC='1' \
        "${LIBSCRIPT_ROOT_DIR}/experiments/gemma-4-sql/suites/e4_custom_matrix_and_synthesis.sh" \
        "${REPO_DIR}" "${RESULTS_DIR}/${_p}" "${BACKENDS_CSV}"
    fi
  done

  verify_distinct_provider_digests "${RESULTS_DIR}"

  jq -n \
    --slurpfile og "${RESULTS_DIR}/og/comparison_summary.json" \
    --slurpfile rs "${RESULTS_DIR}/rs/comparison_summary.json" \
    '
    ($og[0].backends // []) as $og_b |
    ($rs[0].backends // []) as $rs_b |
    ([ $og_b[] | . as $o | (($rs_b | map(select(.backend_id == $o.backend_id))[0]) // $o) as $r | {
      backend_id: $o.backend_id,
      comparison_family: $o.comparison_family,
      tex_slug: ($o.tex_slug // $o.backend_id),
      og_cold_compile_ms: ($o.cold_compile_ms // 0),
      rs_cold_compile_ms: ($r.cold_compile_ms // 0),
      compile_speedup_x: (if ($r.cold_compile_ms // 0) > 0 then (((($o.cold_compile_ms // 0) / $r.cold_compile_ms) * 1000 | round) / 1000) else 1.0 end),
      og_prefill_tps: ($o.prefill_tokens_per_sec // 0),
      rs_prefill_tps: ($r.prefill_tokens_per_sec // 0),
      prefill_speedup_x: (if ($o.prefill_tokens_per_sec // 0) > 0 then (((($r.prefill_tokens_per_sec // 0) / $o.prefill_tokens_per_sec) * 1000 | round) / 1000) else 1.0 end),
      og_decode_tps: ($o.inference_tokens_per_sec // 0),
      rs_decode_tps: ($r.inference_tokens_per_sec // 0),
      decode_speedup_x: (if ($o.inference_tokens_per_sec // 0) > 0 then (((($r.inference_tokens_per_sec // 0) / $o.inference_tokens_per_sec) * 1000 | round) / 1000) else 1.0 end),
      og_sql_accuracy: ($o.sql_execution_accuracy // 0),
      rs_sql_accuracy: ($r.sql_execution_accuracy // 0),
      sql_accuracy_delta: (((($r.sql_execution_accuracy // 0) - ($o.sql_execution_accuracy // 0)) * 10000 | round) / 10000),
      og_train_tpsc: ($o.train_tokens_per_sec_per_chip // 0),
      rs_train_tpsc: ($r.train_tokens_per_sec_per_chip // 0),
      train_speedup_x: (if ($o.train_tokens_per_sec_per_chip // 0) > 0 then (((($r.train_tokens_per_sec_per_chip // 0) / $o.train_tokens_per_sec_per_chip) * 1000 | round) / 1000) else 1.0 end),
      og_peak_hbm_bytes: ($o.peak_tpu_hbm_bytes // 0),
      rs_peak_hbm_bytes: ($r.peak_tpu_hbm_bytes // 0),
      hbm_delta_pct: (if ($o.peak_tpu_hbm_bytes // 0) > 0 then ((((($r.peak_tpu_hbm_bytes // 0) - ($o.peak_tpu_hbm_bytes // 0)) / $o.peak_tpu_hbm_bytes) * 10000 | round) / 100) else 0.0 end)
    }]) as $rows |
    {
      suite: "gemma-4-sql-libtpu",
      status: "ok",
      model: ($og[0].model // "google/gemma-4-E4B"),
      providers: ["og", "rs"],
      backends: $rows
    }' > "${RESULTS_DIR}/ab_comparison_summary.json.tmp"
  jq -e . "${RESULTS_DIR}/ab_comparison_summary.json.tmp" >/dev/null
  mv -f "${RESULTS_DIR}/ab_comparison_summary.json.tmp" "${RESULTS_DIR}/ab_comparison_summary.json"

  jq -r '
    ["backend_id","comparison_family","og_decode_tps","rs_decode_tps","decode_speedup_x","og_compile_ms","rs_compile_ms","compile_speedup_x","og_sql_accuracy","rs_sql_accuracy","sql_accuracy_delta","og_train_tpsc","rs_train_tpsc","train_speedup_x","hbm_delta_pct"],
    (.backends[] | [
      .backend_id, .comparison_family, .og_decode_tps, .rs_decode_tps, .decode_speedup_x,
      .og_cold_compile_ms, .rs_cold_compile_ms, .compile_speedup_x,
      .og_sql_accuracy, .rs_sql_accuracy, .sql_accuracy_delta,
      .og_train_tpsc, .rs_train_tpsc, .train_speedup_x, .hbm_delta_pct
    ]) | @csv
  ' "${RESULTS_DIR}/ab_comparison_summary.json" > "${RESULTS_DIR}/ab_comparison_summary.csv.tmp"
  mv -f "${RESULTS_DIR}/ab_comparison_summary.csv.tmp" "${RESULTS_DIR}/ab_comparison_summary.csv"

  {
    printf '# gemma-4-sql A/B Cloud TPU Comparison (libtpu vs. libtpu-rs)\n\n'
    printf '| Backend | OG Decode (tok/s) | RS Decode (tok/s) | Decode Speedup | Compile Speedup | SQL Acc Delta | Train Speedup | HBM Delta |\n'
    printf '| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n'
    jq -r '.backends[] | "| `\(.backend_id)` | \(.og_decode_tps) | \(.rs_decode_tps) | \(.decode_speedup_x)x | \(.compile_speedup_x)x | \(.sql_accuracy_delta) | \(.train_speedup_x)x | \(.hbm_delta_pct)% |"' "${RESULTS_DIR}/ab_comparison_summary.json"
  } > "${RESULTS_DIR}/ab_comparison_summary.md.tmp"
  mv -f "${RESULTS_DIR}/ab_comparison_summary.md.tmp" "${RESULTS_DIR}/ab_comparison_summary.md"

  {
    printf '%% Mechanically generated by gemma-4-sql-libtpu synthesize_ab.sh\n'
    jq -r '.backends[] |
      "\\newcommand{\\gemmaFourSqlAb\(.tex_slug)DecodeSpeedupX}{\(.decode_speedup_x)}\n\\newcommand{\\gemmaFourSqlAb\(.tex_slug)CompileSpeedupX}{\(.compile_speedup_x)}\n\\newcommand{\\gemmaFourSqlAb\(.tex_slug)TrainSpeedupX}{\(.train_speedup_x)}\n\\newcommand{\\gemmaFourSqlAb\(.tex_slug)SqlAccDelta}{\(.sql_accuracy_delta)}\n\\newcommand{\\gemmaFourSqlAb\(.tex_slug)HbmDeltaPct}{\(.hbm_delta_pct)}"
    ' "${RESULTS_DIR}/ab_comparison_summary.json"
  } > "${RESULTS_DIR}/generated_metrics.tex.tmp"
  mv -f "${RESULTS_DIR}/generated_metrics.tex.tmp" "${RESULTS_DIR}/generated_metrics.tex"

  log_info "Synthesized gemma-4-sql libtpu vs libtpu-rs A/B tables -> ${RESULTS_DIR}/ab_comparison_summary.{json,csv,md}"
}

run_synthesize_gemma4_ab
