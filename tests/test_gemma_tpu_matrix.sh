#!/bin/sh
# ## Overview
# End-to-end hermetic test suite for the 7-backend Gemma 4 TPU matrix (workloads/ai/_common/tpu_matrix.sh, experiments/gemma-tpu/, experiment_cloud.sh, VM cycling, custom templates, CPU-fallback exit 65, and libscript.cmd %* parity).
#
# ## Usage
# ./tests/test_gemma_tpu_matrix.sh
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

WORK_DIR="${LIBSCRIPT_ROOT_DIR}/tests_tmp/gemma_matrix_$$"
mkdir -p "${WORK_DIR}/bin" "${WORK_DIR}/repo" "${WORK_DIR}/shm/cache/hf" "${WORK_DIR}/results"
trap 'rm -rf "${WORK_DIR}"' EXIT

UV_LOG="${WORK_DIR}/uv.log"
GCLOUD_LOG="${WORK_DIR}/gcloud.log"
WORKLOAD_LOG="${WORK_DIR}/workload.log"
: > "${UV_LOG}"
: > "${GCLOUD_LOG}"
: > "${WORKLOAD_LOG}"
export WORK_DIR UV_LOG GCLOUD_LOG WORKLOAD_LOG

printf '[project]\nname = "gemma-4-sql"\nversion = "0.1.0"\n' > "${WORK_DIR}/repo/pyproject.toml"
cat <<'JSON_EOF' > "${WORK_DIR}/repo/libscript.json"
{
  "ml": {
    "model": "google/gemma-4-E4B",
    "command_matrix": [
      "gemma-4-sql benchmark --model {model} --hardware tpu --dtype bfloat16 --mode custom --batch-size {batch_size} --backend {cli_backend} --output {output_json}"
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
printf 'backend=%s keras=%s pjrt=%s args=%s\n' "${ML_CLI_Check:-}" "${KERAS_BACKEND:-}" "${PJRT_DEVICE:-}" "$*" >> "${WORKLOAD_LOG}"
_out=''
while [ $# -gt 0 ]; do
  if [ "$1" = "--output" ]; then _out="$2"; shift 2; else shift; fi
done
if [ -n "${_out}" ]; then
  printf '{"tokens_per_sec":165.0,"cold_compile_ms":1200.0,"latency_ms":{"p25":17.8,"p50":18.5,"p75":19.2,"p99":21.0},"execution_accuracy":0.85,"mean_query_ms":40.0,"tokens_per_sec_per_chip":3400.0,"step_time_ms":98.0,"initial_loss":2.5,"final_loss":1.1}\n' > "${_out}"
fi
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
  *"list"*) printf '[]\n'; exit 0 ;;
esac
exit 0
MOCK_GC
chmod +x "${WORK_DIR}/bin/gcloud"

PATH="${WORK_DIR}/bin:${PATH}"
export PATH

# ## run_gemma_matrix_tests
# Executes 7-backend local/synthetic suite, venv reuse, shm eviction, VM cycling, Stage B CPU-fallback exit 65, trap teardown, and Batch %* audit.
run_gemma_matrix_tests() {
  export GEMMA_TPU_SUITE_SYNTHETIC_FIXTURES='1'
  export GEMMA_TPU_SUITE_SHM_ROOT="${WORK_DIR}/shm"
  export TFRC_MOCK_UTC_DATE='2026-11-14'
  export TPU_MOCK_SHM_FREE_KB='67108864'

  # 1. Full 7-backend E0-E4 execution including manifest .ml.command_matrix
  "${LIBSCRIPT_ROOT_DIR}/experiments/gemma-tpu/benchmark_experiments.sh" \
    --local-exec \
    --tfrc-config="${WORK_DIR}/repo/tfrc.policy.json" \
    --repo-dir="${WORK_DIR}/repo" \
    --results-dir="${WORK_DIR}/results" \
    --backends='hf_transformers,pytorch_native,keras_jax,keras_tensorflow,keras_pytorch,maxtext,jax_native' \
    --subsuites='E0,E1,E2,E3,E4'

  [ -s "${WORK_DIR}/results/raw/e0_provenance.json" ]
  [ -s "${WORK_DIR}/results/comparison_summary.json" ]
  [ -s "${WORK_DIR}/results/comparison_summary.csv" ]
  [ -s "${WORK_DIR}/results/comparison_summary.md" ]
  [ -s "${WORK_DIR}/results/generated_metrics.tex" ]
  [ "$(jq '.backends | length' "${WORK_DIR}/results/comparison_summary.json")" -eq 7 ]
  [ "$(jq '.custom_workloads | length' "${WORK_DIR}/results/comparison_summary.json")" -eq 7 ]
  [ "$(jq -r '.topology.ici_mesh' "${WORK_DIR}/results/raw/e0_provenance.json")" = '2x2x1' ]
  [ "$(jq -r '.stage_a_probes[0].wheel_versions.jax' "${WORK_DIR}/results/raw/e0_provenance.json")" = '0.5.0' ]
  jq -e '.prefill_tokens_per_sec > 0 and .decode_tokens_per_sec > 0 and .telemetry.peak_host_rss_bytes > 0' "${WORK_DIR}/results/raw/e1_inference_jax_native.json" >/dev/null
  jq -e '.execution_accuracy > 0 and .agent_execution_accuracy > 0 and .seed == 42' "${WORK_DIR}/results/raw/e2_sql_eval_jax_native.json" >/dev/null
  jq -e '.loss_trajectory_sanity.decreased == true and .modes.sft_tokens_per_sec_per_chip > 0' "${WORK_DIR}/results/raw/e3_training_jax_native.json" >/dev/null

  # Verify --no-deps -e editable install happened after wheel install, and pytorch-xla venv built only once for hf_transformers + pytorch_native
  grep -q -- '--no-deps -e' "${UV_LOG}"
  _pt_venv_builds=$(grep -c 'venvs/pytorch-xla' "${UV_LOG}")
  [ "${_pt_venv_builds}" -eq 3 ]

  # Verify KERAS_BACKEND isolation across keras_jax, keras_tensorflow, and keras_pytorch
  grep -q 'keras=jax' "${WORKLOAD_LOG}"
  grep -q 'keras=tensorflow' "${WORKLOAD_LOG}"
  grep -q 'keras=torch pjrt=TPU' "${WORKLOAD_LOG}"

  # 2. Spot preemption --resume 2x idempotency: second run executes zero new workloads and preserves summary byte-for-byte
  cp "${WORK_DIR}/results/comparison_summary.json" "${WORK_DIR}/summary_pass1.json"
  _wlines_before=$(wc -l < "${WORKLOAD_LOG}" | tr -d ' ')
  "${LIBSCRIPT_ROOT_DIR}/experiments/gemma-tpu/benchmark_experiments.sh" \
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

  # 3. /dev/shm watermark eviction preserves cache/hf/model.safetensors
  TPU_MOCK_SHM_FREE_KB='1024' sh -c "SCRIPT_NAME='${LIBSCRIPT_ROOT_DIR}/workloads/ai/_common/tpu_matrix.sh' . '${LIBSCRIPT_ROOT_DIR}/workloads/ai/_common/tpu_matrix.sh' && libscript_tpu_evict_shm_if_needed 'jax-native' '${WORK_DIR}/shm' '32'"
  [ -f "${WORK_DIR}/shm/cache/hf/model.safetensors" ]
  [ ! -d "${WORK_DIR}/shm/venvs/maxtext" ]
  [ -d "${WORK_DIR}/shm/venvs/jax-native" ]

  # 4. --fresh-vm-per-backend VM cycling tears down, audits postflight, and reprovisions cleanly
  : > "${GCLOUD_LOG}"
  touch "${WORK_DIR}/qr_live" "${WORK_DIR}/vm_live"
  TFRC_CONFIG="${WORK_DIR}/repo/tfrc.policy.json" GCP_PROJECT_ID='trc-gemma-proj' TPU_ZONE='us-central2-b' TPU_ACCELERATOR_TYPE='v4-8' TPU_SCHEDULING_TYPE='spot' TPU_WAIT_POLL_SEC='0' TPU_FRESH_VM_PER_BACKEND='1' \
    sh -c "SCRIPT_NAME='${LIBSCRIPT_ROOT_DIR}/workloads/ai/_common/tpu_matrix.sh' . '${LIBSCRIPT_ROOT_DIR}/workloads/ai/_common/tpu_matrix.sh' && libscript_tpu_cycle_vm_for_backend 'gemma-tfrc-node' 'keras_tensorflow' '${WORK_DIR}/repo'"
  grep -q 'queued-resources delete gemma-tfrc-node-qr' "${GCLOUD_LOG}"
  grep -q 'queued-resources create gemma-tfrc-node-qr' "${GCLOUD_LOG}"

  # 5. Stage B fail-fast CPU-fallback detection (peak_tpu_hbm_bytes == 0 -> status == failed_cpu_fallback, exit 65)
  _fb_rc=0
  TPU_MOCK_PEAK_HBM_BYTES='0' TPU_MOCK_ACCEL_FD_OPENED='false' \
    "${LIBSCRIPT_ROOT_DIR}/experiments/gemma-tpu/benchmark_experiments.sh" \
    --local-exec --no-resume \
    --tfrc-config="${WORK_DIR}/repo/tfrc.policy.json" \
    --repo-dir="${WORK_DIR}/repo" \
    --results-dir="${WORK_DIR}/results_fb" \
    --backends='jax_native' \
    --subsuites='E1' >/dev/null 2>&1 || _fb_rc=$?
  [ "${_fb_rc}" -eq 65 ]
  [ "$(jq -r '.status' "${WORK_DIR}/results_fb/raw/e1_inference_jax_native.json")" = 'failed_cpu_fallback' ]

  # 6. Campaign failure triggers EXIT trap teardown + postflight audit in experiment_cloud.sh
  : > "${GCLOUD_LOG}"
  touch "${WORK_DIR}/qr_live" "${WORK_DIR}/vm_live"
  _camp_rc=0
  TPU_MOCK_PEAK_HBM_BYTES='0' TPU_MOCK_ACCEL_FD_OPENED='false' GEMMA_TPU_SUITE_LOCAL_EXEC='1' \
    "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment tpu_matrix \
    --tfrc-config="${WORK_DIR}/repo/tfrc.policy.json" \
    --repo-dir="${WORK_DIR}/repo" \
    --output-dir="${WORK_DIR}/camp_out" \
    --state-file="${WORK_DIR}/camp_state.json" \
    --backends='jax_native' \
    --subsuites='E1' >/dev/null 2>&1 || _camp_rc=$?
  [ "${_camp_rc}" -ne 0 ]
  grep -q 'tpu-vm delete gemma-tfrc-node' "${GCLOUD_LOG}"

  # 7. Verify libscript.cmd forwards %* (no %2..%9 truncation) and experiment_cloud.cmd uses :parse_args shift loop
  grep -q 'experiment\.cmd" %\*' "${LIBSCRIPT_ROOT_DIR}/libscript.cmd"
  grep -q '^:parse_args' "${LIBSCRIPT_ROOT_DIR}/experiments/cli/experiment_cloud.cmd"

  printf '[PASS] All hermetic 7-backend Gemma 4 TPU matrix tests passed!\n'
}

run_gemma_matrix_tests
