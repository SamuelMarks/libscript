#!/bin/sh
# ## Overview
# Hermetic unit and integration test suite for engine/common/tfrc_guard.sh covering missing config, project mismatch, UTC expiry, SKU/zone/tier bounds, GKE/Artifact Registry blocks, disk stripping, GCS region parity, pre/postflight audits, and 2x idempotency.
#
# ## Usage
# ./tests/test_tfrc_guard.sh
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

WORK_DIR="${LIBSCRIPT_ROOT_DIR}/tests_tmp/tfrc_guard_$$"
mkdir -p "${WORK_DIR}/bin" "${WORK_DIR}/empty_repo"
trap 'rm -rf "${WORK_DIR}"' EXIT

GCLOUD_LOG="${WORK_DIR}/gcloud_calls.log"
: > "${GCLOUD_LOG}"
export WORK_DIR GCLOUD_LOG

cat <<'MOCK_EOF' > "${WORK_DIR}/bin/gcloud"
#!/bin/sh
printf '%s\n' "$*" >> "${GCLOUD_LOG}"
case "$*" in
  *"config get-value project"*)
    printf '%s\n' "${MOCK_GCLOUD_PROJECT:-my-trc-research-project}"
    exit 0
    ;;
  *"storage buckets describe gs://valid-us-central2"*)
    printf '{"locationType":"region","location":"US-CENTRAL2"}\n'
    exit 0
    ;;
  *"storage buckets describe gs://multi-us-bucket"*)
    printf '{"locationType":"multi-region","location":"US"}\n'
    exit 0
    ;;
  *"storage buckets describe gs://wrong-region-east1"*)
    printf '{"locationType":"region","location":"US-EAST1"}\n'
    exit 0
    ;;
  *"tpu-vm list"*)
    if [ "${MOCK_LEAKED_TPU:-0}" = "1" ]; then
      printf '[{"name":"projects/my-trc-research-project/locations/us-central2-b/nodes/leaked-node","state":"READY"}]\n'
    else
      printf '[]\n'
    fi
    exit 0
    ;;
  *"list"*)
    printf '[]\n'
    exit 0
    ;;
esac
exit 0
MOCK_EOF
chmod +x "${WORK_DIR}/bin/gcloud"
PATH="${WORK_DIR}/bin:${PATH}"
export PATH

POLICY_FILE="${WORK_DIR}/tfrc.policy.json"
cat <<'JSON_EOF' > "${POLICY_FILE}"
{
  "$schema": "../engine/schemas/tfrc-policy.schema.json",
  "schema_version": "1.0",
  "gcp_project_id": "my-trc-research-project",
  "strict_zero_cost": true,
  "storage_mode": "ssh",
  "max_ttl_minutes": 180,
  "shm_min_free_gb": 32,
  "grants": [
    {
      "zone": "us-central2-b",
      "accelerator_types": ["v4-8", "v4-16", "v4-32"],
      "scheduling_tiers": ["on-demand", "spot", "preemptible"],
      "max_hosts": 4,
      "max_chips": 16,
      "max_concurrent_nodes": 1,
      "expires_on": "2026-12-14"
    },
    {
      "zone": "us-central1-a",
      "accelerator_types": ["v5litepod-8", "v5litepod-16", "v6e-8"],
      "scheduling_tiers": ["spot"],
      "max_hosts": 2,
      "max_chips": 16,
      "max_concurrent_nodes": 1,
      "expires_on": "2026-12-14"
    }
  ]
}
JSON_EOF

# ## assert_exit_78
# Verifies that executing a subshell command fails with sysexit 78 (EX_CONFIG).
assert_exit_78() {
  _ae_desc="$1"
  shift
  _ae_rc=0
  ( "$@" ) >/dev/null 2>&1 || _ae_rc=$?
  if [ "${_ae_rc}" -ne 78 ]; then
    printf '[FAIL] %s: expected exit 78, got %d\n' "${_ae_desc}" "${_ae_rc}" >&2
    exit 1
  fi
}

# ## run_tfrc_guard_tests
# Executes all hermetic TFRC zero-cost guardrail assertions.
run_tfrc_guard_tests() {
  # 1. Missing TFRC_CONFIG -> exits 78 before any gcloud invocation
  : > "${GCLOUD_LOG}"
  assert_exit_78 'missing TFRC_CONFIG' sh -c "cd '${WORK_DIR}/empty_repo' && unset TFRC_CONFIG LIBSCRIPT_TFRC_CONFIG && TFRC_STRICT=1 '${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/gcp-tpu-vm/cli.sh' create test-node"
  if [ -s "${GCLOUD_LOG}" ]; then
    printf '[FAIL] Missing TFRC_CONFIG invoked gcloud unexpectedly!\n' >&2
    exit 1
  fi

  # 2. Project mismatch (explicit env and active gcloud project) -> exits 78
  assert_exit_78 'project mismatch' env TFRC_CONFIG="${POLICY_FILE}" GCP_PROJECT_ID='wrong-billing-proj' TPU_ZONE='us-central2-b' TPU_ACCELERATOR_TYPE='v4-8' "${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/gcp-tpu-vm/cli.sh" create test-node
  assert_exit_78 'active gcloud project mismatch' env TFRC_CONFIG="${POLICY_FILE}" MOCK_GCLOUD_PROJECT='other-gcp-proj' GCP_PROJECT_ID='my-trc-research-project' TPU_ZONE='us-central2-b' TPU_ACCELERATOR_TYPE='v4-8' "${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/gcp-tpu-vm/cli.sh" create test-node

  # 3. Expired grant -> exits 78
  assert_exit_78 'expired grant' env TFRC_CONFIG="${POLICY_FILE}" TFRC_MOCK_UTC_DATE='2027-01-15' GCP_PROJECT_ID='my-trc-research-project' TPU_ZONE='us-central2-b' TPU_ACCELERATOR_TYPE='v4-8' "${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/gcp-tpu-vm/cli.sh" create test-node

  # 4. Disallowed zone, SKU, chip bound, and on-demand tier on Spot-only grant -> exits 78
  assert_exit_78 'disallowed zone' env TFRC_CONFIG="${POLICY_FILE}" TFRC_MOCK_UTC_DATE='2026-11-14' GCP_PROJECT_ID='my-trc-research-project' TPU_ZONE='europe-west4-a' TPU_ACCELERATOR_TYPE='v4-8' "${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/gcp-tpu-vm/cli.sh" create test-node
  assert_exit_78 'disallowed SKU' env TFRC_CONFIG="${POLICY_FILE}" TFRC_MOCK_UTC_DATE='2026-11-14' GCP_PROJECT_ID='my-trc-research-project' TPU_ZONE='us-central2-b' TPU_ACCELERATOR_TYPE='v5p-8' "${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/gcp-tpu-vm/cli.sh" create test-node
  assert_exit_78 'exceeded chip bound' env TFRC_CONFIG="${POLICY_FILE}" TFRC_MOCK_UTC_DATE='2026-11-14' GCP_PROJECT_ID='my-trc-research-project' TPU_ZONE='us-central2-b' TPU_ACCELERATOR_TYPE='v4-64' "${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/gcp-tpu-vm/cli.sh" create test-node
  assert_exit_78 'on-demand on spot-only grant' env TFRC_CONFIG="${POLICY_FILE}" TFRC_MOCK_UTC_DATE='2026-11-14' GCP_PROJECT_ID='my-trc-research-project' TPU_ZONE='us-central1-a' TPU_ACCELERATOR_TYPE='v6e-8' TPU_SCHEDULING_TYPE='on-demand' "${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/gcp-tpu-vm/cli.sh" create test-node

  # 5. gke-xpk and Artifact Registry targets blocked with 78
  assert_exit_78 'gke-tpu-cluster blocked' env TFRC_CONFIG="${POLICY_FILE}" "${LIBSCRIPT_ROOT_DIR}/infrastructure/clusters/gke-tpu-cluster/cli.sh" create test-cluster
  assert_exit_78 'gke-xpk-training setup blocked' env TFRC_CONFIG="${POLICY_FILE}" "${LIBSCRIPT_ROOT_DIR}/workloads/payloads/ai/gke-xpk-training/setup.sh"
  assert_exit_78 'gke-xpk-inference deploy blocked' env TFRC_CONFIG="${POLICY_FILE}" "${LIBSCRIPT_ROOT_DIR}/workloads/payloads/ai/gke-xpk-inference/deploy.sh"
  assert_exit_78 'ml actions gke-xpk blocked' env TFRC_CONFIG="${POLICY_FILE}" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" train --tfrc-only --target=gke-xpk --dry-run
  assert_exit_78 'artifact registry image blocked' sh -c "SCRIPT_NAME='${LIBSCRIPT_ROOT_DIR}/engine/common/tfrc_guard.sh' . '${LIBSCRIPT_ROOT_DIR}/engine/common/tfrc_guard.sh' && TFRC_CONFIG='${POLICY_FILE}' DOCKER_IMAGE='us-central1-docker.pkg.dev/my-proj/repo/img:latest' libscript_tfrc_require_config && libscript_tfrc_enforce_zero_cost_env"

  # 6. DISK_SIZE_GB=500 / TPU_DATA_DISK_SIZE=500 stripped and zero disks create calls
  : > "${GCLOUD_LOG}"
  TFRC_CONFIG="${POLICY_FILE}" TFRC_MOCK_UTC_DATE='2026-11-14' GCP_PROJECT_ID='my-trc-research-project' TPU_ZONE='us-central2-b' TPU_ACCELERATOR_TYPE='v4-8' TPU_SCHEDULING_TYPE='spot' DISK_SIZE_GB='500' TPU_DATA_DISK_SIZE='500' \
    "${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/gcp-tpu-vm/cli.sh" create tfrc-ok-node
  if grep -q 'disks create' "${GCLOUD_LOG}"; then
    printf '[FAIL] Persistent disk creation occurred under TFRC zero-cost mode!\n' >&2
    exit 1
  fi

  # 7. GCS bucket ignored under ssh mode; multi-region/wrong-region rejected; matching single-region accepted; 2x idempotent
  (
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/tfrc_guard.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090,SC1091
    . "${SCRIPT_NAME}"
    TFRC_CONFIG="${POLICY_FILE}"
    BUCKET_NAME='some-manifest-bucket'
    GCS_BUCKET='gs://some-manifest-bucket'
    DISK_SIZE_GB='500'
    export TFRC_CONFIG BUCKET_NAME GCS_BUCKET DISK_SIZE_GB
    libscript_tfrc_require_config
    libscript_tfrc_enforce_zero_cost_env
    libscript_tfrc_enforce_zero_cost_env
    [ -z "${BUCKET_NAME}" ] && [ -z "${GCS_BUCKET}" ] && [ -z "${DISK_SIZE_GB}" ]
    libscript_tfrc_verify_gcs_bucket 'gs://valid-us-central2' 'us-central2-b'
    libscript_tfrc_postflight_audit 'my-trc-research-project' 'us-central2-b' 'leaked-node'
  )
  assert_exit_78 'multi-region US GCS rejected' sh -c "SCRIPT_NAME='${LIBSCRIPT_ROOT_DIR}/engine/common/tfrc_guard.sh' . '${LIBSCRIPT_ROOT_DIR}/engine/common/tfrc_guard.sh' && TFRC_CONFIG='${POLICY_FILE}' GCP_PROJECT_ID='my-trc-research-project' libscript_tfrc_verify_gcs_bucket 'gs://multi-us-bucket' 'us-central2-b'"
  assert_exit_78 'wrong-region US-EAST1 GCS rejected' sh -c "SCRIPT_NAME='${LIBSCRIPT_ROOT_DIR}/engine/common/tfrc_guard.sh' . '${LIBSCRIPT_ROOT_DIR}/engine/common/tfrc_guard.sh' && TFRC_CONFIG='${POLICY_FILE}' GCP_PROJECT_ID='my-trc-research-project' libscript_tfrc_verify_gcs_bucket 'gs://wrong-region-east1' 'us-central2-b'"

  # 8. Postflight audit fails non-zero when a TPU node survives teardown
  _pf_rc=0
  MOCK_LEAKED_TPU='1' sh -c "SCRIPT_NAME='${LIBSCRIPT_ROOT_DIR}/engine/common/tfrc_guard.sh' . '${LIBSCRIPT_ROOT_DIR}/engine/common/tfrc_guard.sh' && TFRC_CONFIG='${POLICY_FILE}' libscript_tfrc_postflight_audit 'my-trc-research-project' 'us-central2-b' 'leaked-node'" >/dev/null 2>&1 || _pf_rc=$?
  [ "${_pf_rc}" -ne 0 ]

  printf '[PASS] All hermetic TFRC zero-cost guardrail tests passed!\n'
}

run_tfrc_guard_tests
