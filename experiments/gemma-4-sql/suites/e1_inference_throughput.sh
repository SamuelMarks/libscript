#!/bin/sh
# ## Overview
# Suite E1 runner (e1_inference_throughput.sh): Evaluates Gemma 4 prefill and decode throughput & latency quantiles across integer batch sizes for all 7 TPU backends, separating cold XLA compile from warm steady-state runs.
#
# ## Usage
# ./experiments/gemma-4-sql/suites/e1_inference_throughput.sh <repo_dir> <results_dir> <backend_id>

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

_e1_this="${THIS_FILE}"
_e1_dir="${SCRIPT_DIR}"
for _lib in engine/common/log.sh engine/common/remote_sync.sh workloads/ai/_common/tpu_matrix.sh experiments/gemma-4-sql/suites/stage_ab_telemetry.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _lib || true
THIS_FILE="${_e1_this}"
SCRIPT_DIR="${_e1_dir}"

REPO_ARG="$1"
RESULTS_ARG="$2"
BACKEND_ID="$3"
MODEL_NAME="${GEMMA_4_SQL_MODEL:-google/gemma-4-E4B}"
BATCH_SIZES="${GEMMA_4_SQL_BATCH_SIZES:-1,8,32}"
WARMUP_STEPS="${GEMMA_4_SQL_WARMUP:-2}"
TRIAL_RUNS="${GEMMA_4_SQL_TRIALS:-5}"
SHM_ROOT="${GEMMA_4_SQL_SHM_ROOT:-/dev/shm/libscript-tpu}"
LIBTPU_PROVIDER="${GEMMA_4_SQL_LIBTPU_PROVIDER:-og}"

# ## extract_required_number
# Extracts a mandatory numeric JSON field via jq, failing immediately if null or non-numeric.
extract_required_number() {
  _ern_file="$1"
  _ern_expr="$2"
  _ern_label="$3"
  if [ ! -f "${_ern_file}" ]; then
    log_error "Missing expected gemma-4-sql JSON output file: ${_ern_file} (${_ern_label})"
    return 1
  fi
  _ern_val=$(jq -er "${_ern_expr}" "${_ern_file}" 2>/dev/null || true)
  case "${_ern_val}" in
    ''|null|*[!0-9.-]*)
      log_error "Invalid or missing numeric metric '${_ern_label}' in ${_ern_file}: '${_ern_val}'"
      return 1
      ;;
  esac
  printf '%s\n' "${_ern_val}"
}

# ## run_e1_backend
# Executes E1 prefill and decode sweeps across integer batch sizes for BACKEND_ID with Stage B TPU HBM and descendant RSS capture.
run_e1_backend() {
  REPO_DIR=$(cd -- "${REPO_ARG}" && pwd)
  mkdir -p "${RESULTS_ARG}/raw"
  RESULTS_DIR=$(cd -- "${RESULTS_ARG}" && pwd)
  OUT_FILE="${RESULTS_DIR}/raw/e1_inference_${BACKEND_ID}.json"

  _tree_hash=$(libscript_compute_tree_hash "${REPO_DIR}")
  if [ "${GEMMA_4_SQL_RESUME:-1}" = '1' ] && [ -f "${OUT_FILE}" ]; then
    if jq -e --arg th "${_tree_hash}" --arg prov "${LIBTPU_PROVIDER}" '.status == "ok" and .tree_hash == $th and (.libtpu_provider // "og") == $prov' "${OUT_FILE}" >/dev/null 2>&1; then
      log_info "[RESUME] Skipping completed E1 cell for ${BACKEND_ID} (tree_hash=${_tree_hash})."
      return 0
    fi
  fi

  _vdir=$(libscript_tpu_prepare_backend_venv "${BACKEND_ID}" "${REPO_DIR}" "${SHM_ROOT}" "${LIBTPU_PROVIDER}")
  _penv=$(libscript_tpu_provider_env "${_vdir}" "${LIBTPU_PROVIDER}")
  _spec=$(libscript_tpu_backend_spec "${BACKEND_ID}" "${SHM_ROOT}")
  _cli_be=$(printf '%s' "${_spec}" | cut -d'|' -f2)
  _benv=$(printf '%s' "${_spec}" | cut -d'|' -f7)
  _fam=$(libscript_tpu_family_label "${BACKEND_ID}")

  _strict_flag=''
  if [ "${GEMMA_4_SQL_REQUIRE_HBM:-1}" = '1' ]; then
    _strict_flag='--strict-hardware'
  fi

  _profiles_json='[]'
  _best_pre_tps='0'
  _best_dec_tps='0'
  _cold_ms='0'
  _p25_ms='0'
  _p50_ms='0'
  _p75_ms='0'
  _p90_ms='0'
  _p99_ms='0'
  _max_hbm=0
  _max_rss=0
  _max_duty='0.0'
  _any_fd='false'

  _old_ifs="${IFS}"
  IFS=','
  for _bs in ${BATCH_SIZES}; do
    IFS="${_old_ifs}"
    [ -n "${_bs}" ] || continue
    case "${_bs}" in *[!0-9]*) log_error "Batch size must be an integer, got '${_bs}'"; return 1 ;; esac

    _raw_pre="${RESULTS_DIR}/raw/.w_e1_pre_bs${_bs}_${BACKEND_ID}.json"
    _raw_dec="${RESULTS_DIR}/raw/.w_e1_dec_bs${_bs}_${BACKEND_ID}.json"
    rm -f "${_raw_pre}" "${_raw_dec}"

    _wcmd="export ${_benv} ${_penv}; PATH='${_vdir}/bin':\"\$PATH\"; cd '${REPO_DIR}' && gemma-4-sql benchmark --model '${MODEL_NAME}' --hardware tpu ${_strict_flag} --dtype bfloat16 --mode prefill --batch-size ${_bs} --warmup-steps '${WARMUP_STEPS}' --num-runs '${TRIAL_RUNS}' --backend '${_cli_be}' --output-json '${_raw_pre}' && gemma-4-sql benchmark --model '${MODEL_NAME}' --hardware tpu ${_strict_flag} --dtype bfloat16 --mode decode --batch-size ${_bs} --warmup-steps '${WARMUP_STEPS}' --num-runs '${TRIAL_RUNS}' --backend '${_cli_be}' --output-json '${_raw_dec}'"

    gemma_4_sql_exec_with_stage_b "${BACKEND_ID}" "${_wcmd}" "${OUT_FILE}" "${GEMMA_4_SQL_REQUIRE_HBM:-1}" "${_raw_dec}"

    _bs_pre=$(extract_required_number "${_raw_pre}" '.tokens_per_sec' "prefill.tokens_per_sec(bs=${_bs})")
    _bs_dec=$(extract_required_number "${_raw_dec}" '.tokens_per_sec' "decode.tokens_per_sec(bs=${_bs})")
    _bs_cold=$(extract_required_number "${_raw_pre}" '.compile_latency_ms' "prefill.compile_latency_ms(bs=${_bs})")
    _bs_p50=$(extract_required_number "${_raw_dec}" '.latency_stats.p50_ms' "decode.latency_stats.p50_ms(bs=${_bs})")
    _bs_p90=$(extract_required_number "${_raw_dec}" '.latency_stats.p90_ms' "decode.latency_stats.p90_ms(bs=${_bs})")
    _bs_p99=$(extract_required_number "${_raw_dec}" '.latency_stats.p99_ms' "decode.latency_stats.p99_ms(bs=${_bs})")
    _bs_p25=$(extract_required_number "${_raw_dec}" '.latency_stats.p25_ms // .latency_stats.min_ms' "decode.latency_stats.p25_ms(bs=${_bs})")
    _bs_p75=$(extract_required_number "${_raw_dec}" '.latency_stats.p75_ms // .latency_stats.p90_ms' "decode.latency_stats.p75_ms(bs=${_bs})")
    rm -f "${_raw_pre}" "${_raw_dec}"

    if [ "${STAGE_B_ACCEL_FD}" = 'true' ]; then _any_fd='true'; fi
    if [ "${STAGE_B_PEAK_HBM}" -gt "${_max_hbm}" ]; then _max_hbm="${STAGE_B_PEAK_HBM}"; fi
    if [ "${STAGE_B_PEAK_HOST_RSS_BYTES}" -gt "${_max_rss}" ]; then _max_rss="${STAGE_B_PEAK_HOST_RSS_BYTES}"; fi
    _max_duty=$(awk -v a="${_max_duty}" -v b="${STAGE_B_DUTY_PCT}" 'BEGIN { if (b+0 > a+0) printf "%.2f", b+0; else printf "%.2f", a+0 }')

    if [ "${_cold_ms}" = '0' ]; then _cold_ms="${_bs_cold}"; fi
    if [ "${_bs}" = '1' ] || [ "${_p50_ms}" = '0' ]; then
      _p25_ms="${_bs_p25}"; _p50_ms="${_bs_p50}"; _p75_ms="${_bs_p75}"; _p90_ms="${_bs_p90}"; _p99_ms="${_bs_p99}"
    fi
    _best_pre_tps=$(awk -v a="${_best_pre_tps}" -v b="${_bs_pre}" 'BEGIN { if (b+0 > a+0) printf "%.4f", b+0; else printf "%.4f", a+0 }')
    _best_dec_tps=$(awk -v a="${_best_dec_tps}" -v b="${_bs_dec}" 'BEGIN { if (b+0 > a+0) printf "%.4f", b+0; else printf "%.4f", a+0 }')

    _profiles_json=$(printf '%s' "${_profiles_json}" | jq \
      --argjson bs "${_bs}" \
      --argjson pre "${_bs_pre}" \
      --argjson dec "${_bs_dec}" \
      --argjson cold "${_bs_cold}" \
      --argjson p50 "${_bs_p50}" \
      --argjson p99 "${_bs_p99}" \
      '. + [{batch_size: $bs, prefill_tokens_per_sec: $pre, decode_tokens_per_sec: $dec, compile_latency_ms: $cold, latency_p50_ms: $p50, latency_p99_ms: $p99}]')
    IFS=','
  done
  IFS="${_old_ifs}"

  jq -n \
    --arg b "${BACKEND_ID}" \
    --arg fam "${_fam}" \
    --arg m "${MODEL_NAME}" \
    --arg th "${_tree_hash}" \
    --arg prov "${LIBTPU_PROVIDER}" \
    --argjson pre "${_best_pre_tps}" \
    --argjson dec "${_best_dec_tps}" \
    --argjson cold "${_cold_ms}" \
    --argjson p25 "${_p25_ms}" \
    --argjson p50 "${_p50_ms}" \
    --argjson p75 "${_p75_ms}" \
    --argjson p90 "${_p90_ms}" \
    --argjson p99 "${_p99_ms}" \
    --argjson profiles "${_profiles_json}" \
    --argjson fd "${_any_fd}" \
    --argjson hbm "${_max_hbm}" \
    --argjson duty "${_max_duty}" \
    --argjson rss "${_max_rss}" \
    '{
      suite: "E1",
      experiment_id: "gemma-4-sql",
      backend_id: $b,
      libtpu_provider: $prov,
      comparison_family: $fam,
      model: $m,
      status: "ok",
      tree_hash: $th,
      prefill_tokens_per_sec: $pre,
      decode_tokens_per_sec: $dec,
      cold_compile_ms: $cold,
      latency_ms: {
        p25: $p25,
        p50: $p50,
        p75: $p75,
        p90: $p90,
        p99: $p99,
        iqr: (($p75 - $p25) * 1000 | round / 1000)
      },
      batch_profiles: $profiles,
      telemetry: {
        accelerator_fd_opened: $fd,
        peak_tpu_hbm_bytes: $hbm,
        tpu_duty_cycle_pct: $duty,
        peak_host_rss_bytes: $rss
      }
    }' > "${OUT_FILE}.tmp"
  jq -e . "${OUT_FILE}.tmp" >/dev/null
  mv -f "${OUT_FILE}.tmp" "${OUT_FILE}"
  log_info "Emitted E1 inference artifact -> ${OUT_FILE}"
}

run_e1_backend
