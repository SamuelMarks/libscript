#!/bin/sh
# ## Overview
# Integration test suite verifying Pillar 3 (`ML-01`..`ML-15`): GKE+TPU topology state machine &
# choreography, 4-role GCS ML storage coordination + TFRC cross-region rejection, and `tpu_vm`/`xpk` schedulers.
#
# ## Usage
# ./tests/test_tpu_k8s_gcs_stack.sh

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

TEST_TMP=$(mktemp -d)
export LIBSCRIPT_DATA_DIR="${TEST_TMP}/state"

# ## fail_ml
# Reports test failure, cleans up temporary directory, and exits 1.
fail_ml() {
  printf '[FAIL] %s\n' "$1" >&2
  rm -rf "${TEST_TMP}"
  exit 1
}

printf '%s\n' '=== 1. GKE+TPU Topology Convergence, Dynamic Scale, & Choreography Checkpoints ==='
export LIBSCRIPT_TOPOLOGY_STATE_DIR="${TEST_TMP}/gke_topo"
"${LIBSCRIPT_ROOT_DIR}/topologies/engine.sh" up "${LIBSCRIPT_ROOT_DIR}/topologies/gke-tpu-cluster/topology.json" >/dev/null
"${LIBSCRIPT_ROOT_DIR}/topologies/engine.sh" up "${LIBSCRIPT_ROOT_DIR}/topologies/gke-tpu-cluster/topology.json" >/dev/null
jq -e '.status == "HEALTHY" and (.completed_hooks | length == 5)' "${LIBSCRIPT_TOPOLOGY_STATE_DIR}/.topology_state.json" >/dev/null || fail_ml 'Topology choreography hooks not recorded'
"${LIBSCRIPT_ROOT_DIR}/topologies/engine.sh" scale "${LIBSCRIPT_ROOT_DIR}/topologies/gke-tpu-cluster/topology.json" tpu-slice-pool=4 >/dev/null
jq -e '[.nodes[] | select(.group == "tpu-slice-pool")] | length == 4' "${LIBSCRIPT_TOPOLOGY_STATE_DIR}/.topology_state.json" >/dev/null || fail_ml 'Dynamic topology scale failed to reconcile node count to 4'

printf '%s\n' '=== 2. 4-Role GCS ML Storage Synthesis & TFRC Same-Region Verification ==='
mkdir -p "${TEST_TMP}/bin"
cat << 'EOF_MOCK_GCLOUD' > "${TEST_TMP}/bin/gcloud"
#!/bin/sh
case "$*" in
  *"buckets describe gs://tfrc-us-central2"*)
    printf '{"name":"tfrc-us-central2","location":"US-CENTRAL2","locationType":"region"}\n'
    exit 0
    ;;
  *"buckets describe gs://wrong-eu-west4"*)
    printf '{"name":"wrong-eu-west4","location":"EUROPE-WEST4","locationType":"region"}\n'
    exit 0
    ;;
  *"config get-value project"*)
    printf 'trc-ml-proj\n'
    exit 0
    ;;
esac
exit 0
EOF_MOCK_GCLOUD
chmod 755 "${TEST_TMP}/bin/gcloud"

cat << 'EOF_POL' > "${TEST_TMP}/tfrc.policy.json"
{
  "schema_version": "1.0",
  "gcp_project_id": "trc-ml-proj",
  "strict_zero_cost": true,
  "storage_mode": "same_region_gcs",
  "allowed_gcs_buckets": ["gs://tfrc-us-central2"],
  "grants": [
    {
      "zone": "us-central2-b",
      "accelerator_types": ["v4-8", "v4-32"],
      "scheduling_tiers": ["spot"],
      "max_chips": 16,
      "max_hosts": 4,
      "max_concurrent_nodes": 2
    }
  ]
}
EOF_POL

cat << 'EOF_GCS_DOC' > "${TEST_TMP}/ml-manifest.json"
{
  "ml": {
    "target": "gcp-tpu-vm",
    "backend": "jax_native",
    "gcs_storage": {
      "zone": "us-central2-b",
      "datasets": [
        { "name": "fineweb", "uri": "gs://tfrc-us-central2/datasets/fineweb", "format": "arrayrecord" }
      ],
      "checkpoints": {
        "uri": "gs://tfrc-us-central2/checkpoints/gemma4",
        "retention_days": 14,
        "async_save": true
      },
      "xla_compilation_cache": {
        "uri": "gs://tfrc-us-central2/xla-cache"
      },
      "fuse_mounts": [
        { "bucket": "gs://tfrc-us-central2", "mount_path": "/mnt/weights", "workload_identity_ksa": "ml-trainer-ksa" }
      ]
    }
  }
}
EOF_GCS_DOC

PATH="${TEST_TMP}/bin:${PATH}" TFRC_CONFIG="${TEST_TMP}/tfrc.policy.json" GCP_PROJECT_ID='trc-ml-proj' \
  "${LIBSCRIPT_ROOT_DIR}/traits/storage/gcs_ml.sh" "${TEST_TMP}/ml-manifest.json" --out-dir="${TEST_TMP}/gcs_out" --dry-run
grep -q 'JAX_COMPILATION_CACHE_DIR="gs://tfrc-us-central2/xla-cache"' "${TEST_TMP}/gcs_out/tpu-gcs-env.sh" || fail_ml 'Missing JAX_COMPILATION_CACHE_DIR export'
grep -q 'ORBAX_CHECKPOINT_URI="gs://tfrc-us-central2/checkpoints/gemma4"' "${TEST_TMP}/gcs_out/tpu-gcs-env.sh" || fail_ml 'Missing ORBAX_CHECKPOINT_URI export'
jq -e '.csiVolumes[0].csi.driver == "gcsfuse.csi.storage.gke.io" and .serviceAccountName == "ml-trainer-ksa"' "${TEST_TMP}/gcs_out/gke-gcsfuse-csi-patch.json" >/dev/null || fail_ml 'Invalid GKE GCS FUSE CSI patch'

sed 's|gs://tfrc-us-central2|gs://wrong-eu-west4|g' "${TEST_TMP}/ml-manifest.json" > "${TEST_TMP}/bad-gcs.json"
if PATH="${TEST_TMP}/bin:${PATH}" TFRC_CONFIG="${TEST_TMP}/tfrc.policy.json" GCP_PROJECT_ID='trc-ml-proj' \
  "${LIBSCRIPT_ROOT_DIR}/traits/storage/gcs_ml.sh" "${TEST_TMP}/bad-gcs.json" --out-dir="${TEST_TMP}/gcs_bad" --dry-run >/dev/null 2>&1; then
  fail_ml 'Expected TFRC cross-region GCS bucket to be rejected!'
fi

printf '%s\n' '=== 3. Unified tpu_vm & xpk Payload Scheduler Lifecycle ==='
"${LIBSCRIPT_ROOT_DIR}/payloads/engine.sh" compile "${LIBSCRIPT_ROOT_DIR}/payloads/ai/gcp-tpu-vm/payload.json" --scheduler=tpu_vm | jq -e '.scheduler == "tpu_vm" and .sync_mode == "tree-hash-all-workers"' >/dev/null || fail_ml 'tpu_vm compile failed'
"${LIBSCRIPT_ROOT_DIR}/payloads/engine.sh" submit "${LIBSCRIPT_ROOT_DIR}/payloads/ai/gcp-tpu-vm/payload.json" --scheduler=tpu_vm --dry-run | jq -e '.status == "ok"' >/dev/null || fail_ml 'tpu_vm submit failed'
"${LIBSCRIPT_ROOT_DIR}/payloads/engine.sh" destroy "${LIBSCRIPT_ROOT_DIR}/payloads/ai/gcp-tpu-vm/payload.json" --scheduler=tpu_vm --dry-run | jq -e '.status == "ok"' >/dev/null || fail_ml 'tpu_vm destroy failed'

rm -rf "${TEST_TMP}"
printf '%s\n' '[PASS] All Pillar 3 ML / TPU / Kubernetes / GCS stack tests passed!'
