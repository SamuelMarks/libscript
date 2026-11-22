#!/bin/sh
# ## Overview
# Applies `engine/schemas/gcs-ml-storage.schema.json` across TPU slices and GKE XPK clusters: enforces
# TFRC same-region bucket checks, configures checkpoint lifecycle retention, exports worker env
# (`JAX_COMPILATION_CACHE_DIR`, `ORBAX_CHECKPOINT_URI`), and emits GKE GCS FUSE CSI annotations.
#
# ## Usage
# ./traits/storage/gcs_ml.sh <config.json> --out-dir=<dir> [--zone=<tpu_zone>] [--dry-run]

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

_gcs_this="${THIS_FILE}"; _gcs_dir="${SCRIPT_DIR}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/tfrc_guard.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true
THIS_FILE="${_gcs_this}"; SCRIPT_DIR="${_gcs_dir}"

CFG_FILE=''
OUT_DIR=''
ZONE_VAL="${TPU_ZONE:-}"
DRY_RUN="${LIBSCRIPT_DRY_RUN:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    --out-dir=*) OUT_DIR="${1#*=}"; shift ;;
    --zone=*) ZONE_VAL="${1#*=}"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    *) [ -z "$CFG_FILE" ] && CFG_FILE="$1"; shift ;;
  esac
done

[ -n "$CFG_FILE" ] && [ -f "$CFG_FILE" ] || { printf '[ERROR] Valid GCS ML config JSON required.\n' >&2; exit 1; }
[ -n "$OUT_DIR" ] || OUT_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript-state}/gcs-ml"
mkdir -p "$OUT_DIR"

DOC_EXPR='if has("ml") and (.ml | has("gcs_storage")) then .ml.gcs_storage else . end'
[ -n "$ZONE_VAL" ] || ZONE_VAL=$(jq -r "${DOC_EXPR} | .zone // \"us-central2-b\"" "$CFG_FILE")

# ## extract_bucket_uris
# Extracts all unique gs://<bucket> root URIs referenced across all 4 ML storage roles.
extract_bucket_uris() {
  jq -r "${DOC_EXPR} | [
    (.datasets[]?.uri // empty),
    (.checkpoints.uri // empty),
    (.xla_compilation_cache.uri // empty),
    (.fuse_mounts[]?.bucket // empty | if startswith(\"gs://\") then . else \"gs://\" + . end)
  ] | .[] | select(length > 0) | \"gs://\" + (sub(\"^gs://\"; \"\") | split(\"/\")[0])" "$CFG_FILE" | sort -u
}

# 1. Verify TFRC zero-egress same-region policy on every referenced GCS bucket
if libscript_tfrc_is_enabled; then
  libscript_tfrc_require_config "$(dirname -- "$CFG_FILE")"
  for _b_uri in $(extract_bucket_uris); do
    libscript_tfrc_verify_gcs_bucket "$_b_uri" "$ZONE_VAL"
  done
fi

# 2. Emit checkpoint retention lifecycle rule & ensure buckets when live
RET_DAYS=$(jq -r "${DOC_EXPR} | .checkpoints.retention_days // 30" "$CFG_FILE")
cat << EOF_LC > "${OUT_DIR}/checkpoint-lifecycle.json"
{
  "rule": [
    {
      "action": { "type": "Delete" },
      "condition": { "age": ${RET_DAYS} }
    }
  ]
}
EOF_LC

if [ "$DRY_RUN" != "1" ] && [ -n "${GCP_PROJECT_ID:-}" ] && command -v gcloud >/dev/null 2>&1; then
  _reg=$(printf '%s' "$ZONE_VAL" | sed 's/-[^-]*$//' | tr '[:lower:]' '[:upper:]')
  for _b_uri in $(extract_bucket_uris); do
    gcloud storage buckets describe "$_b_uri" --project="$GCP_PROJECT_ID" >/dev/null 2>&1 || \
      gcloud storage buckets create "$_b_uri" --project="$GCP_PROJECT_ID" --location="$_reg" --uniform-bucket-level-access
  done
  _checkpoint_bkt=$(jq -r "${DOC_EXPR} | .checkpoints.uri // empty | select(length>0) | \"gs://\" + (sub(\"^gs://\"; \"\") | split(\"/\")[0])" "$CFG_FILE")
  if [ -n "$_checkpoint_bkt" ]; then
    gcloud storage buckets update "$_checkpoint_bkt" --lifecycle-file="${OUT_DIR}/checkpoint-lifecycle.json" --project="$GCP_PROJECT_ID" >/dev/null 2>&1 || true
  fi
fi

# 3. Synthesize worker environment exports (Role 1: streaming datasets, Role 2: checkpoints, Role 3: XLA cache)
: > "${OUT_DIR}/tpu-gcs-env.sh.tmp"
jq -r "${DOC_EXPR} | .datasets[]? | \"export LIBSCRIPT_DATASET_\(.name | ascii_upcase | gsub(\"[^A-Z0-9]\"; \"_\"))_URI=\\\"\(.uri)\\\"\"" "$CFG_FILE" >> "${OUT_DIR}/tpu-gcs-env.sh.tmp"
_checkpoint_uri=$(jq -r "${DOC_EXPR} | .checkpoints.uri // empty" "$CFG_FILE")
if [ -n "$_checkpoint_uri" ]; then
  printf 'export ORBAX_CHECKPOINT_URI="%s"\nexport LIBSCRIPT_CHECKPOINT_URI="%s"\n' "$_checkpoint_uri" "$_checkpoint_uri" >> "${OUT_DIR}/tpu-gcs-env.sh.tmp"
fi
_xla_uri=$(jq -r "${DOC_EXPR} | .xla_compilation_cache.uri // empty" "$CFG_FILE")
if [ -n "$_xla_uri" ]; then
  printf 'export JAX_COMPILATION_CACHE_DIR="%s"\nexport JAX_PERSISTENT_CACHE_MIN_COMPILE_TIME_SECS="1"\n' "$_xla_uri" >> "${OUT_DIR}/tpu-gcs-env.sh.tmp"
fi
mv "${OUT_DIR}/tpu-gcs-env.sh.tmp" "${OUT_DIR}/tpu-gcs-env.sh"

# 4. Synthesize GKE GCS FUSE CSI pod patch + Workload Identity annotations (Role 4)
jq "${DOC_EXPR} | {
  podAnnotations: {
    \"gke-gcsfuse/volumes\": (if ((.fuse_mounts // []) | length) > 0 then \"true\" else \"false\" end)
  },
  serviceAccountName: ((.fuse_mounts[0].workload_identity_ksa) // \"default\"),
  csiVolumes: [
    (.fuse_mounts // [])[] | {
      name: (.bucket | gsub(\"^gs://\"; \"\") | gsub(\"[^a-z0-9-]\"; \"-\")),
      mountPath: .mount_path,
      csi: {
        driver: \"gcsfuse.csi.storage.gke.io\",
        volumeAttributes: {
          bucketName: (.bucket | sub(\"^gs://\"; \"\")),
          mountOptions: \"implicit-dirs,metadata-cache:stat-cache-max-size-mb:\(.stat_cache_mb // 256),metadata-cache:type-cache-max-size-mb:\(.type_cache_mb // 64)\"
        }
      }
    }
  ]
}" "$CFG_FILE" > "${OUT_DIR}/gke-gcsfuse-csi-patch.json.tmp"
mv "${OUT_DIR}/gke-gcsfuse-csi-patch.json.tmp" "${OUT_DIR}/gke-gcsfuse-csi-patch.json"

printf '[OK] Synthesized 4-role GCS ML storage coordination at %s\n' "$OUT_DIR"
