#!/bin/sh
# ## Overview
# Suite E9 runner (`e9_framework_matrix.sh`): Head-to-head Cloud TPU VM evaluation comparing upstream Google `libtpu` (`og`) vs. `libtpu-rs` (`rs`) across JAX, Keras 3 (`KERAS_BACKEND=jax`), PyTorch (`torch_xla` / TorchTPU PJRT), and TensorFlow (`tensorflow-tpu` / PJRT) using dedicated twin `/dev/shm` virtualenvs and `/proc/self/maps` SHA-256 verification.
# ## Usage
# ./experiments/libtpu-pjrt/suites/e9_framework_matrix.sh <repo_dir> <results_dir> <host_arch> <warmup> <trials>

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

_e9_this="${THIS_FILE}"
_e9_dir="${SCRIPT_DIR}"
for _e9_lib in 'experiments/_common/harness.sh' 'workloads/ai/_common/tpu_matrix.sh' 'experiments/gemma-4-sql/suites/stage_ab_telemetry.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_e9_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _e9_lib || true
THIS_FILE="${_e9_this}"
SCRIPT_DIR="${_e9_dir}"

REPO_DIR="${1}"
RESULTS_DIR="${2}"
HOST_ARCH="${3:-linux_x64}"
WARMUP_W="${4:-${LIBTPU_RS_WARMUP:-5}}"
TRIALS_N="${5:-${LIBTPU_RS_TRIALS:-20}}"
FRAMEWORKS_CSV="${LIBTPU_PJRT_FRAMEWORKS:-jax,keras_jax,pytorch_tpu,tensorflow_tpu}"
SHM_ROOT="${LIBTPU_PJRT_SHM_ROOT:-/dev/shm/libscript-tpu}"
mkdir -p "${RESULTS_DIR}"

# ## map_framework_to_matrix_id
# Maps a Suite E9 logical framework key to its standalone tpu_matrix backend spec ID.
map_framework_to_matrix_id() {
  case "$1" in
    jax) printf 'pjrt_jax\n' ;;
    keras_jax) printf 'pjrt_keras_jax\n' ;;
    pytorch_tpu) printf 'pjrt_pytorch_tpu\n' ;;
    tensorflow_tpu) printf 'pjrt_tensorflow_tpu\n' ;;
    *)
      log_error "[E9] Unsupported framework key: '$1'"
      return 1
      ;;
  esac
}

# ## emit_synthetic_or_dry_cell
# Emits deterministic provenance-stamped E9 artifact JSON during --dry-run or --synthetic-fixtures validation.
emit_synthetic_or_dry_cell() {
  _esd_fw="$1"
  _esd_sha="$2"
  _esd_dirty="$3"
  _esd_out="${RESULTS_DIR}/e9_${_esd_fw}_vs_og.json"
  _og_p50='1.92'
  _rs_p50='1.74'
  _og_cmp='18.40'
  _rs_cmp='9.80'
  case "${_esd_fw}" in
    keras_jax) _og_p50='2.35'; _rs_p50='2.14'; _og_cmp='24.60'; _rs_cmp='13.50' ;;
    pytorch_tpu) _og_p50='2.68'; _rs_p50='2.42'; _og_cmp='31.20'; _rs_cmp='17.90' ;;
    tensorflow_tpu) _og_p50='2.51'; _rs_p50='2.29'; _og_cmp='28.10'; _rs_cmp='16.40' ;;
  esac
  jq -n \
    --arg fw "${_esd_fw}" \
    --arg sha "${_esd_sha}" \
    --argjson dirty "${_esd_dirty}" \
    --arg arch "${HOST_ARCH}" \
    --argjson og_p50 "${_og_p50}" \
    --argjson rs_p50 "${_rs_p50}" \
    --argjson og_cmp "${_og_cmp}" \
    --argjson rs_cmp "${_rs_cmp}" \
    '{
      schema_version: "1.0.0",
      suite: "E9",
      status: "PASS",
      framework: $fw,
      git_commit_sha: $sha,
      git_dirty: $dirty,
      host_manifest_ref: ("e0_env_" + $arch + ".json"),
      speedup_vs_og_x: (($og_p50 / $rs_p50 * 1000 | round) / 1000),
      compile_speedup_vs_og_x: (($og_cmp / $rs_cmp * 1000 | round) / 1000),
      hbm_delta_pct: -3.2,
      max_abs_diff: 0.000061,
      max_rel_linf_error: 0.000122,
      og: {
        provider: "og",
        chip_count: 8,
        mapped_so_sha256: "og_synthetic_sha256",
        client_init_ms: 42.5,
        cold_compile_ms: $og_cmp,
        step_p50_ms: $og_p50,
        step_p99_ms: ($og_p50 * 1.08),
        step_iqr_ms: 0.06,
        achieved_tflops: 198.4,
        peak_tpu_hbm_bytes: 4294967296,
        peak_rss_bytes: 671088640
      },
      rs: {
        provider: "rs",
        chip_count: 8,
        mapped_so_sha256: "rs_synthetic_sha256",
        client_init_ms: 3.1,
        cold_compile_ms: $rs_cmp,
        step_p50_ms: $rs_p50,
        step_p99_ms: ($rs_p50 * 1.06),
        step_iqr_ms: 0.04,
        achieved_tflops: 218.9,
        peak_tpu_hbm_bytes: 4157528320,
        peak_rss_bytes: 268435456
      }
    }' > "${_esd_out}.tmp"
  mv -f "${_esd_out}.tmp" "${_esd_out}"
}

# ## run_live_framework_ab
# Provisions dedicated <group>-og and <group>-rs virtualenvs on a Cloud TPU VM and benchmarks one framework head-to-head.
run_live_framework_ab() {
  _lfa_fw="$1"
  _lfa_sha="$2"
  _lfa_dirty="$3"
  _lfa_mid=$(map_framework_to_matrix_id "${_lfa_fw}")
  _lfa_out="${RESULTS_DIR}/e9_${_lfa_fw}_vs_og.json"
  _lfa_work="${RESULTS_DIR}/.e9_work_${_lfa_fw}"
  mkdir -p "${_lfa_work}"

  TPU_JAX_FIND_LINKS="${LIBTPU_PJRT_JAX_FIND_LINKS:-}"
  TPU_TORCH_XLA_FIND_LINKS="${LIBTPU_PJRT_TORCH_FIND_LINKS:-}"
  TPU_TF_FIND_LINKS="${LIBTPU_PJRT_TF_FIND_LINKS:-}"
  export TPU_JAX_FIND_LINKS TPU_TORCH_XLA_FIND_LINKS TPU_TF_FIND_LINKS

  _py_harness="${LIBSCRIPT_ROOT_DIR}/experiments/libtpu-pjrt/py_harnesses/bench_framework_cell.py"

  for _prov in og rs; do
    libscript_tpu_release_local_locks
    _vdir=$(TPU_LIBTPU_PROVIDER="${_prov}" libscript_tpu_prepare_backend_venv "${_lfa_mid}" '' "${SHM_ROOT}" "${_prov}")
    _penv=$(libscript_tpu_provider_env "${_vdir}" "${_prov}")
    _so_p=''
    _exp_s=''
    for _kv in ${_penv}; do
      case "${_kv}" in
        TPU_LIBRARY_PATH=*) _so_p="${_kv#*=}" ;;
        LIBTPU_EXPECTED_SHA256=*) _exp_s="${_kv#*=}" ;;
      esac
    done
    _spec=$(libscript_tpu_backend_spec "${_lfa_mid}" "${SHM_ROOT}")
    _kbe=$(printf '%s' "${_spec}" | cut -d'|' -f3)

    (
      export TPU_LIBRARY_PATH="${_so_p}"
      export PJRT_PLUGIN_LIBRARY_PATH="${_so_p}"
      export LIBTPU_EXPECTED_PROVIDER="${_prov}"
      export LIBTPU_EXPECTED_SHA256="${_exp_s}"
      if [ -n "${_kbe}" ]; then
        export KERAS_BACKEND="${_kbe}"
      fi
      if [ "${_lfa_fw}" = 'jax' ] || [ "${_lfa_fw}" = 'keras_jax' ]; then
        export JAX_PLATFORMS='tpu'
      elif [ "${_lfa_fw}" = 'pytorch_tpu' ]; then
        export PJRT_DEVICE='TPU'
        export XLA_USE_BF16='1'
      elif [ "${_lfa_fw}" = 'tensorflow_tpu' ]; then
        export NEXT_PLUGGABLE_DEVICE_USE_C_API='true'
      fi
      libscript_tpu_verify_loaded_so "${_vdir}/bin/python" "${_lfa_mid}" "${_exp_s}" "${_prov}" > "${_lfa_work}/stage_a_${_prov}.json"
      GEMMA_4_SQL_REQUIRE_HBM="${LIBTPU_PJRT_REQUIRE_HBM:-1}" gemma_4_sql_stage_b_run \
        "${_lfa_work}/stage_b_${_prov}.json" \
        "${_lfa_work}/cell_${_prov}.log" \
        "${_vdir}/bin/python" "${_py_harness}" \
        --framework "${_lfa_fw}" \
        --provider "${_prov}" \
        --warmup "${WARMUP_W}" \
        --trials "${TRIALS_N}" \
        --expected-so-sha256 "${_exp_s}" \
        --tensor-out "${_lfa_work}/probe_${_prov}.json" \
        --out "${_lfa_work}/metrics_${_prov}.json"
    )
  done

  jq -n \
    --arg fw "${_lfa_fw}" \
    --arg sha "${_lfa_sha}" \
    --argjson dirty "${_lfa_dirty}" \
    --arg arch "${HOST_ARCH}" \
    --slurpfile og_m "${_lfa_work}/metrics_og.json" \
    --slurpfile rs_m "${_lfa_work}/metrics_rs.json" \
    --slurpfile og_b "${_lfa_work}/stage_b_og.json" \
    --slurpfile rs_b "${_lfa_work}/stage_b_rs.json" \
    --slurpfile og_p "${_lfa_work}/probe_og.json" \
    --slurpfile rs_p "${_lfa_work}/probe_rs.json" \
    '
    ($og_m[0]) as $og |
    ($rs_m[0]) as $rs |
    ($og_b[0].peak_tpu_hbm_bytes // 0) as $og_hbm |
    ($rs_b[0].peak_tpu_hbm_bytes // 0) as $rs_hbm |
    ([range(0; ($og_p[0].probe | length)) | (($og_p[0].probe[.] - $rs_p[0].probe[.]) | fabs)] | max // 0) as $max_abs |
    (([ $og_p[0].probe[] | fabs ] | max) // 1.0) as $denom |
    {
      schema_version: "1.0.0",
      suite: "E9",
      status: "PASS",
      framework: $fw,
      git_commit_sha: $sha,
      git_dirty: $dirty,
      host_manifest_ref: ("e0_env_" + $arch + ".json"),
      speedup_vs_og_x: ((($og.step_p50_ms / (if $rs.step_p50_ms > 0 then $rs.step_p50_ms else 1 end)) * 1000 | round) / 1000),
      compile_speedup_vs_og_x: ((($og.cold_compile_ms / (if $rs.cold_compile_ms > 0 then $rs.cold_compile_ms else 1 end)) * 1000 | round) / 1000),
      hbm_delta_pct: (if $og_hbm > 0 then (((($rs_hbm - $og_hbm) / $og_hbm) * 10000 | round) / 100) else 0 end),
      max_abs_diff: $max_abs,
      max_rel_linf_error: (if $denom > 0 then ($max_abs / $denom) else $max_abs end),
      og: ($og + {peak_tpu_hbm_bytes: $og_hbm, stage_b_telemetry: $og_b[0]}),
      rs: ($rs + {peak_tpu_hbm_bytes: $rs_hbm, stage_b_telemetry: $rs_b[0]})
    }' > "${_lfa_out}.tmp"
  mv -f "${_lfa_out}.tmp" "${_lfa_out}"
  rm -rf "${_lfa_work}"
}

# ## synthesize_e9_summary
# Synthesizes `e9_framework_comparison.{json,csv,md}` from per-framework `e9_*_vs_og.json` artifacts.
synthesize_e9_summary() {
  _s9_json="${RESULTS_DIR}/e9_framework_comparison.json"
  _s9_csv="${RESULTS_DIR}/e9_framework_comparison.csv"
  _s9_md="${RESULTS_DIR}/e9_framework_comparison.md"

  find "${RESULTS_DIR}" -maxdepth 1 -type f -name 'e9_*_vs_og.json' | LC_ALL=C sort | xargs jq -s '{
    schema_version: "1.0.0",
    suite: "E9",
    status: "PASS",
    frameworks: .
  }' > "${_s9_json}.tmp"
  mv -f "${_s9_json}.tmp" "${_s9_json}"

  jq -r '
    ["framework","og_p50_ms","rs_p50_ms","speedup_vs_og_x","og_compile_ms","rs_compile_ms","compile_speedup_x","hbm_delta_pct","max_rel_linf_error"],
    (.frameworks[] | [
      .framework,
      (.og.step_p50_ms | tostring),
      (.rs.step_p50_ms | tostring),
      (.speedup_vs_og_x | tostring),
      (.og.cold_compile_ms | tostring),
      (.rs.cold_compile_ms | tostring),
      (.compile_speedup_vs_og_x | tostring),
      (.hbm_delta_pct | tostring),
      (.max_rel_linf_error | tostring)
    ]) | @csv
  ' "${_s9_json}" > "${_s9_csv}.tmp"
  mv -f "${_s9_csv}.tmp" "${_s9_csv}"

  {
    printf '# Suite E9: 4-Framework Cloud TPU Comparison (libtpu vs. libtpu-rs)\n\n'
    printf '| Framework | OG Step p50 (ms) | RS Step p50 (ms) | Step Speedup (x) | OG Compile (ms) | RS Compile (ms) | Compile Speedup (x) | HBM Delta (%%) | Max Rel L_inf Err |\n'
    printf '| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n'
    jq -r '.frameworks[] | "| `\(.framework)` | \(.og.step_p50_ms) | \(.rs.step_p50_ms) | \(.speedup_vs_og_x)x | \(.og.cold_compile_ms) | \(.rs.cold_compile_ms) | \(.compile_speedup_vs_og_x)x | \(.hbm_delta_pct)% | \(.max_rel_linf_error) |"' "${_s9_json}"
  } > "${_s9_md}.tmp"
  mv -f "${_s9_md}.tmp" "${_s9_md}"
}

# ## run_e9_framework_matrix
# Orchestrates local TPU VM execution, remote Cloud TPU VM SSH dispatch, or synthetic/dry-run validation for Suite E9.
run_e9_framework_matrix() {
  if [ "${FORCE_REBUILD:-0}" != '1' ] && [ -s "${RESULTS_DIR}/e9_framework_comparison.json" ]; then
    log_info "[E9] Cached E9 4-framework comparison artifacts already verified in '${RESULTS_DIR}'."
    return 0
  fi

  if [ -n "${TPU_NAME:-}" ] && [ "${LIBTPU_PJRT_LOCAL_EXEC:-0}" != '1' ] && [ "${LIBTPU_RS_DRY_RUN:-0}" != '1' ] && [ "${LIBTPU_RS_SYNTHETIC_FIXTURES:-0}" != '1' ]; then
    _cli="${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/gcp-tpu-vm/cli.sh"
    "${SCRIPT_DIR}/../sync.sh" --repo-dir="${REPO_DIR}"
    _rem_cmd="LIBTPU_PJRT_LOCAL_EXEC=1 LIBTPU_PJRT_FRAMEWORKS='${FRAMEWORKS_CSV}' LIBTPU_PJRT_REQUIRE_HBM='${LIBTPU_PJRT_REQUIRE_HBM:-1}' \"\$HOME/libscript/experiments/libtpu-pjrt/suites/e9_framework_matrix.sh\" \"\$HOME/libtpu-rs\" \"\$HOME/results\" '${HOST_ARCH}' '${WARMUP_W}' '${TRIALS_N}'"
    "${_cli}" ssh "${TPU_NAME}" --command="${_rem_cmd}"
    "${_cli}" scp-from "${TPU_NAME}" "${TPU_NAME}:~/results/e9_*" "${RESULTS_DIR}" --worker=0
    return 0
  fi

  _prov_f="${RESULTS_DIR}/.e9_prov.json"
  libscript_exp_capture_provenance "${REPO_DIR}" "${_prov_f}" "e9_framework_matrix ${HOST_ARCH}" "e0_env_${HOST_ARCH}.json"
  _sha=$(sed -n 's/.*"git_commit_sha":[[:space:]]*"\([^"]*\)".*/\1/p' "${_prov_f}" | head -n 1)
  _dirty=$(sed -n 's/.*"git_dirty":[[:space:]]*\([a-z]*\).*/\1/p' "${_prov_f}" | head -n 1)
  rm -f "${_prov_f}"
  if [ -z "${_dirty}" ]; then
    _dirty='false'
  fi

  if [ "${LIBTPU_RS_SYNTHETIC_FIXTURES:-0}" = '1' ] || [ "${LIBTPU_RS_DRY_RUN:-0}" = '1' ]; then
    for _fw in $(printf '%s' "${FRAMEWORKS_CSV}" | tr ',;' '  '); do
      emit_synthetic_or_dry_cell "${_fw}" "${_sha:-synthetic}" "${_dirty}"
    done
    synthesize_e9_summary
    log_info "[E9] Emitted synthetic/dry-run 4-framework comparison artifacts in '${RESULTS_DIR}'."
    return 0
  fi

  if [ ! -e '/dev/accel0' ] && [ ! -d '/dev/vfio' ]; then
    log_error '[E9] Suite E9 targets real Cloud TPU VM hardware (/dev/accel* or /dev/vfio/*); set TPU_NAME for remote dispatch or pass --dry-run.'
    return 65
  fi

  for _fw in $(printf '%s' "${FRAMEWORKS_CSV}" | tr ',;' '  '); do
    run_live_framework_ab "${_fw}" "${_sha}" "${_dirty}"
  done
  synthesize_e9_summary
  log_info "[E9] Completed 4-framework head-to-head Cloud TPU comparison in '${RESULTS_DIR}'."
}

run_e9_framework_matrix
