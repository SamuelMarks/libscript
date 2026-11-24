#!/bin/sh
# ## Overview
# End-to-end hermetic test suite for `experiments/gemma-4-sql/` (5-family / 7-backend TPU matrix, strict gemma-4-sql CLI/JSON contracts, relative-path tree-hash safety, 2x --resume idempotency, --render-latex idempotency, zero fake fallbacks, exit 65 CPU-fallback guard, remote E4 custom matrix pull, and zero legacy gemma-tpu references).
#
# ## Usage
# ./tests/test_gemma_4_sql_matrix.sh
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

WORK_DIR="${LIBSCRIPT_ROOT_DIR}/tests_tmp/gemma_4_sql_matrix_$$"
mkdir -p "${WORK_DIR}/bin" "${WORK_DIR}/repo" "${WORK_DIR}/shm/cache/hf" "${WORK_DIR}/results" "${WORK_DIR}/remote_results/raw"
trap 'rm -rf "${WORK_DIR}"' EXIT

UV_LOG="${WORK_DIR}/uv.log"
GCLOUD_LOG="${WORK_DIR}/gcloud.log"
WORKLOAD_LOG="${WORK_DIR}/workload.log"
: > "${UV_LOG}"
: > "${GCLOUD_LOG}"
: > "${WORKLOAD_LOG}"
export WORK_DIR UV_LOG GCLOUD_LOG WORKLOAD_LOG

printf '[project]\nname = "gemma-4-sql"\nversion = "0.1.0"\n' > "${WORK_DIR}/repo/pyproject.toml"
printf '%s\n' 'fastapi' 'sqlglot' > "${WORK_DIR}/repo/requirements.txt"
printf 'duckdb\n' > "${WORK_DIR}/repo/requirements-duckdb.txt"

cat <<'JSON_EOF' > "${WORK_DIR}/repo/libscript.json"
{
  "ml": {
    "model": "google/gemma-4-E4B",
    "command_matrix": [
      "gemma-4-sql benchmark --model {model} --hardware tpu --dtype bfloat16 --mode decode --batch-size {batch_size} --warmup-steps 1 --num-runs 2 --backend {cli_backend} --output-json {output_json}"
    ]
  }
}
JSON_EOF
printf 'keep-weights\n' > "${WORK_DIR}/shm/cache/hf/model.safetensors"

cat <<'JSON_EOF' > "${WORK_DIR}/repo/tfrc.policy.json"
{
  "schema_version": "1.0",
  "gcp_project_id": "trc-gemma-proj",
  "strict_zero_cost": true,
  "grants": [
    {
      "zone": "us-central2-b",
      "accelerator_types": ["v4-8", "v4-32"],
      "scheduling_tiers": ["spot", "on-demand"],
      "max_hosts": 4,
      "max_chips": 16,
      "max_concurrent_nodes": 1,
      "expires_on": "2026-12-31"
    }
  ]
}
JSON_EOF

cat <<'MOCK_UV' > "${WORK_DIR}/bin/uv"
#!/bin/sh
printf '%s\n' "$*" >> "${UV_LOG}"
if [ "${1:-}" = "venv" ]; then
  _vpath=''
  for _arg in "$@"; do
    _vpath="${_arg}"
  done
  mkdir -p "${_vpath}/bin"
  cat <<'PYSHIM' > "${_vpath}/bin/python"
#!/bin/sh
exit 0
PYSHIM
  chmod +x "${_vpath}/bin/python"
  cat <<'GMOCK' > "${_vpath}/bin/gemma-4-sql"
#!/bin/sh
_sub="${1:-}"
shift || true
printf 'sub=%s keras=%s pjrt=%s args=%s\n' "${_sub}" "${KERAS_BACKEND:-}" "${PJRT_DEVICE:-}" "$*" >> "${WORKLOAD_LOG}"

_out=''
_bs=''
_ds=''
_prompt=''
_dbt=''
_has_runs=0
while [ $# -gt 0 ]; do
  case "$1" in
    --output)
      printf '[MOCK-ERROR] Deprecated --output flag rejected; use --output-json\n' >&2
      exit 2
      ;;
    --output-json) _out="$2"; shift 2 ;;
    --output-json=*) _out="${1#*=}"; shift ;;
    --batch-size) _bs="$2"; shift 2 ;;
    --batch-size=*) _bs="${1#*=}"; shift ;;
    --dataset) _ds="$2"; shift 2 ;;
    --dataset=*) _ds="${1#*=}"; shift ;;
    --prompt) _prompt="$2"; shift 2 ;;
    --prompt=*) _prompt="${1#*=}"; shift ;;
    --db-type) _dbt="$2"; shift 2 ;;
    --num-runs) _has_runs=1; shift 2 ;;
    *) shift ;;
  esac
done

[ -n "${_out}" ] || { printf '[MOCK-ERROR] Missing --output-json for %s\n' "${_sub}" >&2; exit 2; }

if [ "${MOCK_OMIT_METRICS:-0}" = '1' ]; then
  printf '{"status":"completed"}\n' > "${_out}"
  exit 0
fi

case "${_sub}" in
  benchmark)
    case "${_bs}" in ''|*[!0-9]*) printf '[MOCK-ERROR] Non-integer --batch-size: %s\n' "${_bs}" >&2; exit 2 ;; esac
    [ "${_has_runs}" -eq 1 ] || { printf '[MOCK-ERROR] Missing --num-runs on benchmark\n' >&2; exit 2; }
    printf '{"tokens_per_sec":165.0,"compile_latency_ms":1200.0,"latency_ms":18.5,"peak_memory_mb":8192.0,"latency_stats":{"mean_ms":18.6,"p25_ms":17.8,"p50_ms":18.5,"p75_ms":19.2,"p90_ms":20.1,"p99_ms":21.0,"min_ms":17.0,"max_ms":21.5},"status":"completed"}\n' > "${_out}"
    ;;
  evaluate)
    [ -n "${_dbt}" ] || { printf '[MOCK-ERROR] Missing --db-type on evaluate\n' >&2; exit 2; }
    printf '{"status":"completed","mean_query_ms":38.4,"peak_memory_mb":4096.0,"metrics":{"execution_accuracy":0.875,"exact_match":0.75,"valid_sql":1.0}}\n' > "${_out}"
    ;;
  agent)
    [ -n "${_prompt}" ] || { printf '[MOCK-ERROR] Missing --prompt on agent\n' >&2; exit 2; }
    printf '{"status":"completed","success":true,"attempts":1,"peak_memory_mb":4096.0}\n' > "${_out}"
    ;;
  sft|peft|dpo)
    [ -n "${_ds}" ] || { printf '[MOCK-ERROR] Missing --dataset on %s\n' "${_sub}" >&2; exit 2; }
    printf '{"status":"completed","tokens_per_sec_per_chip":3400.0,"step_time_ms":98.0,"initial_loss":2.5,"final_loss":1.1,"peak_memory_mb":8192.0}\n' > "${_out}"
    ;;
  *)
    printf '[MOCK-ERROR] Unsupported subcommand: %s\n' "${_sub}" >&2
    exit 2
    ;;
esac
exit 0
GMOCK
  chmod +x "${_vpath}/bin/gemma-4-sql"
fi
exit 0
MOCK_UV
chmod +x "${WORK_DIR}/bin/uv"

cat <<'MOCK_GC' > "${WORK_DIR}/bin/gcloud"
#!/bin/sh
printf '%s\n' "$*" >> "${GCLOUD_LOG}"
case "$*" in
  *"value(labels.libscript)"*) printf 'managed\n'; exit 0 ;;
  *"disks describe"*) exit 1 ;;
  *"config get-value project"*) printf 'trc-gemma-proj\n'; exit 0 ;;
  *"tpu-vm describe"*)
    if [ -f "${WORK_DIR}/vm_live" ]; then
      printf '{"name":"gemma-tfrc-node","state":"READY","acceleratorType":"v4-8","runtimeVersion":"tpu-ubuntu2204-base","schedulingConfig":{"spot":true},"networkEndpoints":[{"ipAddress":"10.0.0.2"}]}\n'
      exit 0
    fi
    exit 1
    ;;
  *"tpu-vm create"*) touch "${WORK_DIR}/vm_live"; exit 0 ;;
  *"tpu-vm delete"*) rm -f "${WORK_DIR}/vm_live"; exit 0 ;;
  *"queued-resources describe"*)
    if [ -f "${WORK_DIR}/qr_live" ]; then printf '{"state":{"state":"ACTIVE"}}\n'; exit 0; fi
    exit 1
    ;;
  *"queued-resources create"*) touch "${WORK_DIR}/qr_live" "${WORK_DIR}/vm_live"; exit 0 ;;
  *"queued-resources delete"*) rm -f "${WORK_DIR}/qr_live" "${WORK_DIR}/vm_live"; exit 0 ;;
  *"tpu-vm ssh"*e4_custom_*)
    printf '%s\n' "${WORK_DIR}/remote_results/raw/e4_custom_0_jax_native.json"
    exit 0
    ;;
  *"tpu-vm ssh"*)
    exit 0
    ;;
  *"tpu-vm scp"*)
    _dest=''
    for _a in "$@"; do
      case "${_a}" in --*) ;; *) _dest="${_a}" ;; esac
    done
    case "${_dest}" in
      *:*) exit 0 ;;
      *e4_custom_0_jax_native.json*)
        cp "${WORK_DIR}/remote_results/raw/e4_custom_0_jax_native.json" "${_dest}"
        ;;
      *)
        printf '{"status":"ok"}\n' > "${_dest}"
        ;;
    esac
    exit 0
    ;;
  *"list"*) printf '[]\n'; exit 0 ;;
esac
exit 0
MOCK_GC
chmod +x "${WORK_DIR}/bin/gcloud"

PATH="${WORK_DIR}/bin:${PATH}"
export PATH

# ## run_gemma_4_sql_matrix_tests
# Executes 7-backend/5-family suite, strict flag/JSON checks, relative-path tree-hash safety, 2x --resume, --render-latex, fail-fast on missing metrics, exit 65 CPU-fallback, remote E4 pull, and zero legacy grep.
run_gemma_4_sql_matrix_tests() {
  # 0. Plugin discovery, validation, smoke test, and zero legacy gemma-tpu references
  _list_out=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment list)
  printf '%s\n' "${_list_out}" | grep -q '^gemma-4-sql	tpu-slice	gemma-4-sql: TPU performance comparisons betwixt JAX, Keras, and PyTorch on Google'\''s Gemma 4$'
  if printf '%s\n' "${_list_out}" | grep -Eq 'gemma-tpu|gemma_tpu'; then
    printf '[FAIL] Legacy gemma-tpu suite discovered!\n' >&2
    return 1
  fi
  [ ! -d "${LIBSCRIPT_ROOT_DIR}/experiments/gemma-tpu" ]
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment validate gemma-4-sql --batch-sizes=1,8,32 --dataset=gemma-4-sql-bench >/dev/null
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment test gemma-4-sql >/dev/null

  # SKU runtime resolution checks (v4, v5e, v6e)
  _rt_v4=$(TPU_ACCELERATOR_TYPE='v4-8' sh -c "SCRIPT_NAME='${LIBSCRIPT_ROOT_DIR}/workloads/ai/_common/tpu_matrix.sh' . '${LIBSCRIPT_ROOT_DIR}/workloads/ai/_common/tpu_matrix.sh' && libscript_tpu_backend_spec 'jax_native' | cut -d'|' -f4")
  _rt_v5e=$(TPU_ACCELERATOR_TYPE='v5e-8' sh -c "SCRIPT_NAME='${LIBSCRIPT_ROOT_DIR}/workloads/ai/_common/tpu_matrix.sh' . '${LIBSCRIPT_ROOT_DIR}/workloads/ai/_common/tpu_matrix.sh' && libscript_tpu_backend_spec 'jax_native' | cut -d'|' -f4")
  _rt_v6e=$(TPU_ACCELERATOR_TYPE='v6e-8' sh -c "SCRIPT_NAME='${LIBSCRIPT_ROOT_DIR}/workloads/ai/_common/tpu_matrix.sh' . '${LIBSCRIPT_ROOT_DIR}/workloads/ai/_common/tpu_matrix.sh' && libscript_tpu_backend_spec 'jax_native' | cut -d'|' -f4")
  [ "${_rt_v4}" = 'tpu-ubuntu2204-base' ]
  [ "${_rt_v5e}" = 'v2-alpha-tpuv5-lite' ]
  [ "${_rt_v6e}" = 'v2-alpha-tpuv6e' ]

  export GEMMA_4_SQL_SYNTHETIC_FIXTURES='1'
  export GEMMA_4_SQL_SHM_ROOT="${WORK_DIR}/shm"
  export TFRC_MOCK_UTC_DATE='2026-11-14'
  export TPU_MOCK_SHM_FREE_KB='67108864'

  # 1. Run E0-E4 using RELATIVE ./repo and ./results paths and verify tree_hash is 100% untouched
  _hash_before=$(sh -c "SCRIPT_NAME='${LIBSCRIPT_ROOT_DIR}/engine/common/remote_sync.sh' . '${LIBSCRIPT_ROOT_DIR}/engine/common/remote_sync.sh' && libscript_compute_tree_hash '${WORK_DIR}/repo'")
  (
    cd -- "${WORK_DIR}"
    "${LIBSCRIPT_ROOT_DIR}/experiments/gemma-4-sql/benchmark_experiments.sh" \
      --local-exec \
      --tfrc-config='./repo/tfrc.policy.json' \
      --repo-dir='./repo' \
      --results-dir='./results' \
      --backends='hf_transformers,pytorch_native,keras_jax,keras_tensorflow,keras_pytorch,maxtext,jax_native' \
      --subsuites='E0,E1,E2,E3,E4'
  )
  _hash_after=$(sh -c "SCRIPT_NAME='${LIBSCRIPT_ROOT_DIR}/engine/common/remote_sync.sh' . '${LIBSCRIPT_ROOT_DIR}/engine/common/remote_sync.sh' && libscript_compute_tree_hash '${WORK_DIR}/repo'")
  [ "${_hash_before}" = "${_hash_after}" ]
  [ ! -d "${WORK_DIR}/repo/results" ]

  [ -s "${WORK_DIR}/results/raw/e0_provenance.json" ]
  [ -s "${WORK_DIR}/results/comparison_summary.json" ]
  [ -s "${WORK_DIR}/results/comparison_summary.csv" ]
  [ -s "${WORK_DIR}/results/comparison_summary.md" ]
  [ -s "${WORK_DIR}/results/generated_metrics.tex" ]
  [ "$(jq '.comparison_families | length' "${WORK_DIR}/results/comparison_summary.json")" -eq 5 ]
  [ "$(jq '.backends | length' "${WORK_DIR}/results/comparison_summary.json")" -eq 7 ]
  [ "$(jq '.custom_workloads | length' "${WORK_DIR}/results/comparison_summary.json")" -eq 7 ]
  [ "$(jq -r '.topology.ici_mesh' "${WORK_DIR}/results/raw/e0_provenance.json")" = '2x2x1' ]
  grep -q 'gemmaFourSqlJaxNativeDecodeTps' "${WORK_DIR}/results/generated_metrics.tex"
  jq -e '.prefill_tokens_per_sec > 0 and .decode_tokens_per_sec > 0 and (.batch_profiles | length) == 3 and .telemetry.peak_host_rss_bytes > 0' "${WORK_DIR}/results/raw/e1_inference_jax_native.json" >/dev/null
  jq -e '.sqlite_execution_accuracy == 0.875 and .duckdb_execution_accuracy == 0.875 and .agent_execution_accuracy == 1.0 and .seed == 42' "${WORK_DIR}/results/raw/e2_sql_eval_jax_native.json" >/dev/null
  jq -e '.loss_trajectory.loss_decreased == true and .sft_tokens_per_sec_per_chip > 0 and .peft_tokens_per_sec_per_chip > 0 and .dpo_tokens_per_sec_per_chip > 0' "${WORK_DIR}/results/raw/e3_training_jax_native.json" >/dev/null

  # Verify requirements.txt + requirements-duckdb.txt installed before --no-deps -e, and explicit cli_backend IDs passed
  grep -q 'requirements.txt' "${UV_LOG}"
  grep -q 'requirements-duckdb.txt' "${UV_LOG}"
  grep -q -- '--no-deps -e' "${UV_LOG}"
  grep -q -- '--backend hf_transformers' "${WORKLOAD_LOG}"
  grep -q -- '--backend keras_jax' "${WORKLOAD_LOG}"
  grep -q -- '--backend keras_tensorflow' "${WORKLOAD_LOG}"
  grep -q -- '--backend keras_pytorch' "${WORKLOAD_LOG}"
  grep -q -- '--backend jax_native' "${WORKLOAD_LOG}"

  # 2. 2x --resume idempotency: second run executes zero new workloads
  cp "${WORK_DIR}/results/comparison_summary.json" "${WORK_DIR}/summary_pass1.json"
  _wlines_before=$(wc -l < "${WORKLOAD_LOG}" | tr -d ' ')
  "${LIBSCRIPT_ROOT_DIR}/experiments/gemma-4-sql/benchmark_experiments.sh" \
    --local-exec \
    --resume \
    --tfrc-config="${WORK_DIR}/repo/tfrc.policy.json" \
    --repo-dir="${WORK_DIR}/repo" \
    --results-dir="${WORK_DIR}/results" \
    --backends='all' \
    --subsuites='E0,E1,E2,E3,E4'
  _wlines_after=$(wc -l < "${WORKLOAD_LOG}" | tr -d ' ')
  [ "${_wlines_before}" -eq "${_wlines_after}" ]
  cmp -s "${WORK_DIR}/summary_pass1.json" "${WORK_DIR}/results/comparison_summary.json"

  # 3. --render-latex idempotency + --paper-dir copy without invoking E0-E3 workloads
  mkdir -p "${WORK_DIR}/paper"
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment render-latex gemma-4-sql \
    --repo-dir="${WORK_DIR}/repo" \
    --results-dir="${WORK_DIR}/results" \
    --paper-dir="${WORK_DIR}/paper"
  _wlines_latex=$(wc -l < "${WORKLOAD_LOG}" | tr -d ' ')
  [ "${_wlines_before}" -eq "${_wlines_latex}" ]
  [ -s "${WORK_DIR}/paper/generated_metrics.tex" ]

  # 4. Fail-fast when workload omits required JSON metrics (zero hardcoded fallback constants)
  _omit_rc=0
  MOCK_OMIT_METRICS='1' "${LIBSCRIPT_ROOT_DIR}/experiments/gemma-4-sql/benchmark_experiments.sh" \
    --local-exec --no-resume \
    --tfrc-config="${WORK_DIR}/repo/tfrc.policy.json" \
    --repo-dir="${WORK_DIR}/repo" \
    --results-dir="${WORK_DIR}/results_omit" \
    --backends='jax_native' \
    --subsuites='E1' >/dev/null 2>&1 || _omit_rc=$?
  [ "${_omit_rc}" -ne 0 ]

  # 5. /dev/shm watermark eviction preserves cache/hf/model.safetensors
  TPU_MOCK_SHM_FREE_KB='1024' sh -c "SCRIPT_NAME='${LIBSCRIPT_ROOT_DIR}/workloads/ai/_common/tpu_matrix.sh' . '${LIBSCRIPT_ROOT_DIR}/workloads/ai/_common/tpu_matrix.sh' && libscript_tpu_evict_shm_if_needed 'jax-native' '${WORK_DIR}/shm' '32'"
  [ -f "${WORK_DIR}/shm/cache/hf/model.safetensors" ]
  [ ! -d "${WORK_DIR}/shm/venvs/maxtext" ]
  [ -d "${WORK_DIR}/shm/venvs/jax-native" ]

  # 6. --fresh-vm-per-backend VM cycling + HF_TOKEN forwarding without leaking secret into logs
  : > "${GCLOUD_LOG}"
  touch "${WORK_DIR}/qr_live" "${WORK_DIR}/vm_live"
  TFRC_CONFIG="${WORK_DIR}/repo/tfrc.policy.json" GCP_PROJECT_ID='trc-gemma-proj' TPU_ZONE='us-central2-b' TPU_ACCELERATOR_TYPE='v4-8' TPU_SCHEDULING_TYPE='spot' TPU_WAIT_POLL_SEC='0' TPU_FRESH_VM_PER_BACKEND='1' \
    sh -c "SCRIPT_NAME='${LIBSCRIPT_ROOT_DIR}/workloads/ai/_common/tpu_matrix.sh' . '${LIBSCRIPT_ROOT_DIR}/workloads/ai/_common/tpu_matrix.sh' && libscript_tpu_cycle_vm_for_backend 'gemma-tfrc-node' 'keras_tensorflow' '${WORK_DIR}/repo'"
  grep -q 'queued-resources delete gemma-tfrc-node-qr' "${GCLOUD_LOG}"
  grep -q 'queued-resources create gemma-tfrc-node-qr' "${GCLOUD_LOG}"

  # 7. Remote E4 custom artifact pull preserves custom_workloads before local synthesis
  printf '{"suite":"E4","experiment_id":"gemma-4-sql","backend_id":"jax_native","template_index":0,"status":"ok","tree_hash":"h1","command":"gemma-4-sql benchmark","workload_output":{"tokens_per_sec":210.0},"peak_tpu_hbm_bytes":8589934592}\n' > "${WORK_DIR}/remote_results/raw/e4_custom_0_jax_native.json"
  touch "${WORK_DIR}/vm_live"
  TPU_NAME='gemma-tfrc-node' TPU_ZONE='us-central2-b' GCP_PROJECT_ID='trc-gemma-proj' GEMMA_4_SQL_LOCAL_EXEC='0' \
    "${LIBSCRIPT_ROOT_DIR}/experiments/gemma-4-sql/benchmark_experiments.sh" \
    --tfrc-config="${WORK_DIR}/repo/tfrc.policy.json" \
    --repo-dir="${WORK_DIR}/repo" \
    --results-dir="${WORK_DIR}/results_rem_e4" \
    --backends='jax_native' \
    --subsuites='E4'
  [ "$(jq '.custom_workloads | length' "${WORK_DIR}/results_rem_e4/comparison_summary.json")" -eq 1 ]

  # 8. Stage B fail-fast CPU-fallback detection (peak_tpu_hbm_bytes == 0 -> status == failed_cpu_fallback, exit 65)
  _fb_rc=0
  TPU_MOCK_PEAK_HBM_BYTES='0' TPU_MOCK_ACCEL_FD_OPENED='false' \
    "${LIBSCRIPT_ROOT_DIR}/experiments/gemma-4-sql/benchmark_experiments.sh" \
    --local-exec --no-resume \
    --tfrc-config="${WORK_DIR}/repo/tfrc.policy.json" \
    --repo-dir="${WORK_DIR}/repo" \
    --results-dir="${WORK_DIR}/results_fb" \
    --backends='jax_native' \
    --subsuites='E1' >/dev/null 2>&1 || _fb_rc=$?
  [ "${_fb_rc}" -eq 65 ]
  [ "$(jq -r '.status' "${WORK_DIR}/results_fb/raw/e1_inference_jax_native.json")" = 'failed_cpu_fallback' ]

  # 9. Campaign failure triggers EXIT trap teardown + postflight audit in experiment_cloud.sh
  : > "${GCLOUD_LOG}"
  touch "${WORK_DIR}/qr_live" "${WORK_DIR}/vm_live"
  _camp_rc=0
  TPU_MOCK_PEAK_HBM_BYTES='0' TPU_MOCK_ACCEL_FD_OPENED='false' GEMMA_4_SQL_LOCAL_EXEC='1' \
    "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment tpu_matrix \
    "${WORK_DIR}/repo/libscript.json" \
    --tfrc-config="${WORK_DIR}/repo/tfrc.policy.json" \
    --output-dir="${WORK_DIR}/camp_out" \
    --state-file="${WORK_DIR}/camp_state.json" \
    --backends='jax_native' \
    --subsuites='E1' >/dev/null 2>&1 || _camp_rc=$?
  [ "${_camp_rc}" -ne 0 ]
  grep -q 'tpu-vm delete gemma-tfrc-node' "${GCLOUD_LOG}"

  printf '[PASS] All hermetic gemma-4-sql 5-family / 7-backend TPU matrix tests passed!\n'
}

run_gemma_4_sql_matrix_tests
