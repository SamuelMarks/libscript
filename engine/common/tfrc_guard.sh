#!/bin/sh
# ## Overview
# Enforces TPU Research Cloud (TFRC) USD 0.00 zero-cost policy guardrails, SKU/zone/TTL allowlists, same-region GCS checks, and pre/post-flight orphan resource audits.
#
# ## Usage
# SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/tfrc_guard.sh"; export SCRIPT_NAME; . "${SCRIPT_NAME}"
set -feu
_tg_caller_this="${THIS_FILE:-}"; _tg_caller_dir="${SCRIPT_DIR:-}"
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
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2; fi
    if [ -n "${_tg_caller_dir}" ]; then SCRIPT_DIR="${_tg_caller_dir}"; fi; if [ -n "${_tg_caller_this}" ]; then THIS_FILE="${_tg_caller_this}"; fi; unset _tg_caller_this _tg_caller_dir || true
    if (return 0 2>/dev/null); then return 0; else exit 0; fi ;;
  *) if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/log.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

TFRC_EX_CONFIG=78
export TFRC_EX_CONFIG

# ## libscript_tfrc_is_enabled
# Returns 0 if TFRC zero-cost enforcement is active in the current environment, 1 otherwise.
libscript_tfrc_is_enabled() {
  if [ "${TFRC_STRICT:-${LIBSCRIPT_TFRC_STRICT:-0}}" = '1' ] || [ "${TFRC_STRICT:-}" = 'true' ]; then
    return 0
  fi
  if [ -n "${TFRC_CONFIG:-${LIBSCRIPT_TFRC_CONFIG:-}}" ]; then
    return 0
  fi
  return 1
}

# ## libscript_tfrc_abort
# Logs a TFRC policy violation and exits with sysexit 78 (EX_CONFIG).
libscript_tfrc_abort() {
  _tg_msg="$1"
  printf '[TFRC-GUARD] [VIOLATION] %s\n' "${_tg_msg}" >&2
  exit "${TFRC_EX_CONFIG}"
}

# ## libscript_tfrc_derive_topology
# Derives 'hosts chips' from a TPU accelerator SKU (e.g. v4-8 -> '1 4', v4-32 -> '4 16', v5litepod-16 -> '2 16', v6e-8 -> '1 8') and slice count.
libscript_tfrc_derive_topology() {
  _tg_sku="$1"
  _tg_slices="${2:-1}"
  case "${_tg_slices}" in
    ''|*[!0-9]*) _tg_slices=1 ;;
  esac
  if [ "${_tg_slices}" -lt 1 ]; then
    _tg_slices=1
  fi

  _tg_num="${_tg_sku##*-}"
  case "${_tg_num}" in
    ''|*[!0-9]*) _tg_num=8 ;;
  esac

  case "${_tg_sku}" in
    v2-*|v3-*|v4-*|v5p-*)
      _tg_chips=$(( _tg_num / 2 ))
      if [ "${_tg_chips}" -lt 1 ]; then _tg_chips=1; fi
      _tg_hosts=$(( (_tg_chips + 3) / 4 ))
      ;;
    v5litepod-*|v5e-*|v6e-*)
      _tg_chips="${_tg_num}"
      if [ "${_tg_chips}" -lt 1 ]; then _tg_chips=1; fi
      _tg_hosts=$(( (_tg_chips + 7) / 8 ))
      ;;
    *)
      _tg_chips="${_tg_num}"
      if [ "${_tg_chips}" -lt 1 ]; then _tg_chips=1; fi
      _tg_hosts=$(( (_tg_chips + 3) / 4 ))
      ;;
  esac

  _tg_total_hosts=$(( _tg_hosts * _tg_slices ))
  _tg_total_chips=$(( _tg_chips * _tg_slices ))
  printf '%d %d\n' "${_tg_total_hosts}" "${_tg_total_chips}"
}

# ## libscript_tfrc_require_config
# Resolves TFRC_CONFIG explicitly without implicit zone/SKU defaults and validates schema invariants via jq.
libscript_tfrc_require_config() {
  _tg_repo_hint="${1:-${REPO_DIR:-${APP_DIR:-}}}"
  _tg_cfg="${TFRC_CONFIG:-${LIBSCRIPT_TFRC_CONFIG:-}}"
  if [ -z "${_tg_cfg}" ] && [ -n "${_tg_repo_hint}" ] && [ -f "${_tg_repo_hint}/tfrc.policy.json" ]; then
    _tg_cfg="${_tg_repo_hint}/tfrc.policy.json"
  fi
  if [ -z "${_tg_cfg}" ] && [ -f './tfrc.policy.json' ]; then
    _tg_cfg='./tfrc.policy.json'
  fi
  if [ -z "${_tg_cfg}" ]; then
    libscript_tfrc_abort 'Missing explicit TFRC policy file. Supply --tfrc-config=<path> or TFRC_CONFIG pointing to a valid tfrc.policy.json.'
  fi
  if [ ! -f "${_tg_cfg}" ]; then
    libscript_tfrc_abort "TFRC policy file not found at '${_tg_cfg}'."
  fi
  if ! command -v jq >/dev/null 2>&1; then
    libscript_tfrc_abort 'jq is required to validate TFRC zero-cost policy files.'
  fi

  _tg_schema_check=$(jq -r '
    if (.schema_version // "") != "1.0" then "schema_version must equal \"1.0\""
    elif ((.gcp_project_id // "") | length) == 0 then "gcp_project_id must be a non-empty string"
    elif (.strict_zero_cost | type) != "boolean" or (.strict_zero_cost != true) then "strict_zero_cost must be true"
    elif (.grants | type) != "array" or ((.grants | length) == 0) then "grants must be a non-empty array"
    elif ([.grants[] | select(((.zone // "") | length) == 0 or ((.accelerator_types // []) | length) == 0 or ((.scheduling_tiers // []) | length) == 0 or ((.max_chips // 0) < 1) or ((.max_concurrent_nodes // 0) < 1))] | length) > 0 then "every grant requires zone, accelerator_types, scheduling_tiers, max_chips >= 1, and max_concurrent_nodes >= 1"
    else "OK"
    end
  ' "${_tg_cfg}" 2>/dev/null || printf 'invalid JSON syntax')

  if [ "${_tg_schema_check}" != 'OK' ]; then
    libscript_tfrc_abort "Invalid TFRC policy '${_tg_cfg}': ${_tg_schema_check}"
  fi

  TFRC_CONFIG=$(cd -- "$(dirname -- "${_tg_cfg}")" && pwd)/"$(basename -- "${_tg_cfg}")"
  LIBSCRIPT_TFRC_CONFIG="${TFRC_CONFIG}"
  TFRC_STRICT='1'
  LIBSCRIPT_TFRC_STRICT='1'

  _tg_ttl=$(jq -r '.max_ttl_minutes // 180' "${TFRC_CONFIG}")
  _tg_shm=$(jq -r '.shm_min_free_gb // 32' "${TFRC_CONFIG}")
  _tg_smode=$(jq -r '.storage_mode // "ssh"' "${TFRC_CONFIG}")
  : "${TFRC_MAX_TTL_MINUTES:=${LIBSCRIPT_TFRC_MAX_TTL_MINUTES:-${_tg_ttl}}}"
  : "${TFRC_SHM_MIN_FREE_GB:=${LIBSCRIPT_TFRC_SHM_MIN_FREE_GB:-${_tg_shm}}}"
  : "${TFRC_STORAGE_MODE:=${LIBSCRIPT_TFRC_STORAGE_MODE:-${_tg_smode}}}"
  LIBSCRIPT_TFRC_MAX_TTL_MINUTES="${TFRC_MAX_TTL_MINUTES}"
  LIBSCRIPT_TFRC_SHM_MIN_FREE_GB="${TFRC_SHM_MIN_FREE_GB}"
  LIBSCRIPT_TFRC_STORAGE_MODE="${TFRC_STORAGE_MODE}"
  export TFRC_CONFIG LIBSCRIPT_TFRC_CONFIG TFRC_STRICT LIBSCRIPT_TFRC_STRICT
  export TFRC_MAX_TTL_MINUTES LIBSCRIPT_TFRC_MAX_TTL_MINUTES TFRC_SHM_MIN_FREE_GB LIBSCRIPT_TFRC_SHM_MIN_FREE_GB
  export TFRC_STORAGE_MODE LIBSCRIPT_TFRC_STORAGE_MODE
}

# ## libscript_tfrc_enforce_zero_cost_env
# Idempotently strips billable disk/bucket settings and rejects GKE/GPU/Filestore targets under TFRC mode.
libscript_tfrc_enforce_zero_cost_env() {
  TFRC_STRICT='1'
  LIBSCRIPT_TFRC_STRICT='1'
  export TFRC_STRICT LIBSCRIPT_TFRC_STRICT

  if [ "${TPU_NO_QUEUED_RESOURCE:-0}" != '1' ] && [ "${TPU_USE_QUEUED_RESOURCE:-}" != 'false' ]; then
    TPU_USE_QUEUED_RESOURCE='true'
    export TPU_USE_QUEUED_RESOURCE
  fi

  if [ -n "${TPU_DATA_DISK_SIZE:-}" ] || [ -n "${DISK_SIZE_GB:-}" ]; then
    printf '[TFRC-GUARD] Stripping persistent disk configuration (TPU_DATA_DISK_SIZE="%s", DISK_SIZE_GB="%s") to enforce USD 0.00 TFRC compliance.\n' "${TPU_DATA_DISK_SIZE:-}" "${DISK_SIZE_GB:-}" >&2
  fi
  TPU_DATA_DISK_SIZE=''
  DISK_SIZE_GB=''
  DISK_NAME=''
  export TPU_DATA_DISK_SIZE DISK_SIZE_GB DISK_NAME

  if [ "${TFRC_STORAGE_MODE:-${LIBSCRIPT_TFRC_STORAGE_MODE:-ssh}}" != 'same_region_gcs' ] && [ "${TFRC_EXPLICIT_GCS_BUCKET:-0}" != '1' ]; then
    if [ -n "${BUCKET_NAME:-}" ] || [ -n "${GCS_BUCKET:-}" ]; then
      printf '[TFRC-GUARD] Ignoring manifest GCS bucket (BUCKET_NAME="%s", GCS_BUCKET="%s") under default ssh storage_mode.\n' "${BUCKET_NAME:-}" "${GCS_BUCKET:-}" >&2
    fi
    BUCKET_NAME=''
    GCS_BUCKET=''
    export BUCKET_NAME GCS_BUCKET
  fi

  case "${ML_TARGET:-}" in
    gke-xpk|xpk|gcp-gke-tpu-cluster|gcp-gpu-vm|gcp-filestore)
      libscript_tfrc_abort "Target '${ML_TARGET}' incurs non-TFRC GCP billing (GKE/GPU/Filestore) and is strictly forbidden in TFRC zero-cost mode."
      ;;
  esac

  case "${DOCKER_IMAGE:-}" in
    *.pkg.dev/*|*gcr.io/*)
      _tg_forbid_ar='true'
      if [ -n "${TFRC_CONFIG:-}" ] && [ -f "${TFRC_CONFIG}" ]; then
        _tg_forbid_ar=$(jq -r 'if .forbid_artifact_registry == false then "false" else "true" end' "${TFRC_CONFIG}" 2>/dev/null || printf 'true')
      fi
      if [ "${_tg_forbid_ar}" = 'true' ]; then
        libscript_tfrc_abort "Artifact Registry / GCR image '${DOCKER_IMAGE}' incurs storage/egress billing and is forbidden when forbid_artifact_registry=true."
      fi
      ;;
  esac
}

# ## libscript_tfrc_validate_request
# Validates (project, zone, accel_type, scheduling_type, slice_count) against grants[] and UTC expiration date.
libscript_tfrc_validate_request() {
  _tg_req_proj="${1:-${GCP_PROJECT_ID:-}}"
  _tg_req_zone="${2:-${TPU_ZONE:-}}"
  _tg_req_sku="${3:-${TPU_ACCELERATOR_TYPE:-}}"
  _tg_req_tier="${4:-${TPU_SCHEDULING_TYPE:-spot}}"
  _tg_req_cnt="${5:-1}"

  libscript_tfrc_require_config
  libscript_tfrc_enforce_zero_cost_env

  _tg_pol_proj=$(jq -r '.gcp_project_id' "${TFRC_CONFIG}")
  if [ -z "${_tg_req_proj}" ]; then
    _tg_req_proj="${_tg_pol_proj}"
    GCP_PROJECT_ID="${_tg_pol_proj}"
    export GCP_PROJECT_ID
  fi
  if [ "${_tg_req_proj}" != "${_tg_pol_proj}" ]; then
    libscript_tfrc_abort "Requested GCP_PROJECT_ID '${_tg_req_proj}' does not match TFRC policy gcp_project_id '${_tg_pol_proj}'."
  fi

  if [ "${DRY_RUN:-false}" != 'true' ] && [ "${DRY_RUN:-0}" != '1' ] && [ "${LIBSCRIPT_DRY_RUN:-0}" != '1' ]; then
    if command -v gcloud >/dev/null 2>&1; then
      _tg_active_proj=$(gcloud config get-value project 2>/dev/null | tr -d '\r\n' || true)
      if [ -n "${_tg_active_proj}" ] && [ "${_tg_active_proj}" != '(unset)' ] && [ "${_tg_active_proj}" != "${_tg_pol_proj}" ]; then
        libscript_tfrc_abort "Active gcloud project '${_tg_active_proj}' does not match TFRC policy gcp_project_id '${_tg_pol_proj}'."
      fi
    fi
  fi

  if [ -z "${_tg_req_zone}" ] || [ -z "${_tg_req_sku}" ]; then
    libscript_tfrc_abort 'Both TPU_ZONE and TPU_ACCELERATOR_TYPE must be explicitly specified and covered by TFRC grants[].'
  fi

  _tg_today="${TFRC_MOCK_UTC_DATE:-$(date -u +%Y-%m-%d)}"
  _tg_topo=$(libscript_tfrc_derive_topology "${_tg_req_sku}" "${_tg_req_cnt}")
  _tg_hosts="${_tg_topo%% *}"
  _tg_chips="${_tg_topo##* }"

  _tg_verdict=$(jq -r \
    --arg zone "${_tg_req_zone}" \
    --arg sku "${_tg_req_sku}" \
    --arg tier "${_tg_req_tier}" \
    --arg today "${_tg_today}" \
    --argjson hosts "${_tg_hosts}" \
    --argjson chips "${_tg_chips}" \
    --argjson cnt "${_tg_req_cnt}" '
    [ .grants[] | select(.zone == $zone) ] as $zgrants
    | if ($zgrants | length) == 0 then
        "Zone \"\($zone)\" is not allowlisted in TFRC grants[]"
      else
        [ $zgrants[] | select((.accelerator_types | index($sku)) != null) ] as $sgrants
        | if ($sgrants | length) == 0 then
            "Accelerator \"\($sku)\" is not allowlisted in zone \"\($zone)\""
          else
            [ $sgrants[] | select((.scheduling_tiers | index($tier)) != null) ] as $tgrants
            | if ($tgrants | length) == 0 then
                "Scheduling tier \"\($tier)\" is not allowlisted for \($sku) in \($zone)"
              else
                [ $tgrants[] | select(((.expires_on // "") == "") or (.expires_on >= $today)) ] as $egrants
                | if ($egrants | length) == 0 then
                    "TFRC grant for \($sku) in \($zone) expired prior to UTC \($today)"
                  else
                    [ $egrants[] | select(($chips <= .max_chips) and ($hosts <= (.max_hosts // 1)) and ($cnt <= (.max_concurrent_nodes // 1))) ] as $cgrants
                    | if ($cgrants | length) == 0 then
                        "Requested slice (\($hosts) host(s), \($chips) chip(s), \($cnt) node(s)) exceeds TFRC grant limits in \($zone)"
                      else
                        "OK"
                      end
                  end
              end
          end
      end
  ' "${TFRC_CONFIG}")

  if [ "${_tg_verdict}" != 'OK' ]; then
    libscript_tfrc_abort "${_tg_verdict}"
  fi
  printf '[TFRC-GUARD] Verified grant: project=%s zone=%s sku=%s tier=%s hosts=%s chips=%s\n' \
    "${_tg_pol_proj}" "${_tg_req_zone}" "${_tg_req_sku}" "${_tg_req_tier}" "${_tg_hosts}" "${_tg_chips}" >&2
}

# ## libscript_tfrc_verify_gcs_bucket
# Verifies an optional gs:// bucket is allowlisted (if configured), single-region, and matches TPU_ZONE's region.
libscript_tfrc_verify_gcs_bucket() {
  _tg_uri="$1"
  _tg_zone="$2"
  [ -n "${_tg_uri}" ] || return 0

  libscript_tfrc_require_config
  _tg_clean="${_tg_uri#gs://}"
  _tg_clean="${_tg_clean%%/*}"
  _tg_full_uri="gs://${_tg_clean}"

  _tg_allow_check=$(jq -r --arg u "${_tg_full_uri}" '
    if ((.allowed_gcs_buckets // []) | length) > 0 and ((.allowed_gcs_buckets | index($u)) == null) then
      "GCS bucket \"\($u)\" is not in tfrc.policy.json allowed_gcs_buckets[]"
    else
      "OK"
    end
  ' "${TFRC_CONFIG}")
  if [ "${_tg_allow_check}" != 'OK' ]; then
    libscript_tfrc_abort "${_tg_allow_check}"
  fi

  _tg_expected_reg=$(printf '%s' "${_tg_zone%-*}" | tr '[:lower:]' '[:upper:]')
  _tg_proj="${GCP_PROJECT_ID:-$(jq -r '.gcp_project_id' "${TFRC_CONFIG}")}"

  _tg_bjson=$(gcloud storage buckets describe "${_tg_full_uri}" --project="${_tg_proj}" --format=json 2>/dev/null || true)
  if [ -z "${_tg_bjson}" ]; then
    libscript_tfrc_abort "Unable to inspect GCS bucket '${_tg_full_uri}' in project '${_tg_proj}'."
  fi

  _tg_loc_type=$(printf '%s' "${_tg_bjson}" | jq -r '.locationType // .location_type // ""' | tr '[:upper:]' '[:lower:]')
  _tg_loc=$(printf '%s' "${_tg_bjson}" | jq -r '.location // ""' | tr '[:lower:]' '[:upper:]')

  if [ "${_tg_loc_type}" != 'region' ]; then
    libscript_tfrc_abort "GCS bucket '${_tg_full_uri}' has locationType='${_tg_loc_type}' (must be single 'region' to prevent cross-region egress charges)."
  fi
  if [ "${_tg_loc}" != "${_tg_expected_reg}" ]; then
    libscript_tfrc_abort "GCS bucket '${_tg_full_uri}' is in region '${_tg_loc}', which does not match TPU zone '${_tg_zone}' (${_tg_expected_reg})."
  fi

  TFRC_STORAGE_MODE='same_region_gcs'
  LIBSCRIPT_TFRC_STORAGE_MODE='same_region_gcs'
  TFRC_EXPLICIT_GCS_BUCKET='1'
  export TFRC_STORAGE_MODE LIBSCRIPT_TFRC_STORAGE_MODE TFRC_EXPLICIT_GCS_BUCKET
  printf '[TFRC-GUARD] Verified same-region GCS bucket %s (%s)\n' "${_tg_full_uri}" "${_tg_loc}" >&2
}

# ## libscript_tfrc_preflight_audit
# Audits existing TPU VMs, Queued Resources, disks, static IPs, and GKE clusters before provisioning.
libscript_tfrc_preflight_audit() {
  _tg_proj="${1:-${GCP_PROJECT_ID:-}}"
  _tg_zone="${2:-${TPU_ZONE:-}}"
  _tg_target_name="${3:-${TPU_NAME:-}}"

  libscript_tfrc_require_config
  if [ -z "${_tg_proj}" ]; then
    _tg_proj=$(jq -r '.gcp_project_id' "${TFRC_CONFIG}")
  fi
  if [ "${DRY_RUN:-false}" = 'true' ] || [ "${DRY_RUN:-0}" = '1' ] || [ "${LIBSCRIPT_DRY_RUN:-0}" = '1' ]; then
    TFRC_REUSE_ACTIVE_NODE='0'
    export TFRC_REUSE_ACTIVE_NODE
    return 0
  fi
  command -v gcloud >/dev/null 2>&1 || return 0

  _tg_max_nodes=$(jq -r --arg z "${_tg_zone}" '[.grants[] | select(.zone == $z) | .max_concurrent_nodes // 1] | max // 1' "${TFRC_CONFIG}")
  _tg_tpus=$(gcloud compute tpus tpu-vm list --zone="${_tg_zone}" --project="${_tg_proj}" --format=json 2>/dev/null || printf '[]')
  _tg_qrs=$(gcloud compute tpus queued-resources list --zone="${_tg_zone}" --project="${_tg_proj}" --format=json 2>/dev/null || gcloud alpha compute tpus queued-resources list --zone="${_tg_zone}" --project="${_tg_proj}" --format=json 2>/dev/null || printf '[]')
  _tg_disks=$(gcloud compute disks list --filter="zone:(${_tg_zone})" --project="${_tg_proj}" --format=json 2>/dev/null || printf '[]')
  _tg_addrs=$(gcloud compute addresses list --project="${_tg_proj}" --format=json 2>/dev/null || printf '[]')
  _tg_clusters=$(gcloud container clusters list --project="${_tg_proj}" --format=json 2>/dev/null || printf '[]')

  _tg_gke_cnt=$(printf '%s' "${_tg_clusters}" | jq 'length' 2>/dev/null || printf '0')
  if [ "${_tg_gke_cnt}" -gt 0 ]; then
    libscript_tfrc_abort "Detected ${_tg_gke_cnt} active GKE cluster(s) in project '${_tg_proj}'. Resolve billable clusters before running TFRC workloads."
  fi

  _tg_addr_cnt=$(printf '%s' "${_tg_addrs}" | jq '[.[] | select((.status // "") == "RESERVED")] | length' 2>/dev/null || printf '0')
  if [ "${_tg_addr_cnt}" -gt 0 ]; then
    libscript_tfrc_abort "Detected ${_tg_addr_cnt} reserved static IP address(es) in project '${_tg_proj}'."
  fi

  _tg_orphan_disks=$(printf '%s' "${_tg_disks}" | jq '[.[] | select(((.users // []) | length) == 0 and ((.name // "") | test("libscript|tpu|ml-eval")))] | length' 2>/dev/null || printf '0')
  if [ "${_tg_orphan_disks}" -gt 0 ]; then
    libscript_tfrc_abort "Detected ${_tg_orphan_disks} unattached persistent disk(s) in '${_tg_zone}'. Delete orphaned disks to preserve USD 0.00 TFRC spend."
  fi

  TFRC_REUSE_ACTIVE_NODE='0'
  if [ -n "${_tg_target_name}" ]; then
    _tg_match=$(printf '%s' "${_tg_tpus}" | jq -r --arg n "${_tg_target_name}" '[.[] | select((.name | split("/") | last) == $n and (.state == "READY" or .state == "ACTIVE"))] | length' 2>/dev/null || printf '0')
    if [ "${_tg_match}" -gt 0 ]; then
      TFRC_REUSE_ACTIVE_NODE='1'
      export TFRC_REUSE_ACTIVE_NODE
      printf '[TFRC-GUARD] Existing active TPU node "%s" found in %s; marking reusable for idempotent re-entry.\n' "${_tg_target_name}" "${_tg_zone}" >&2
      return 0
    fi
  fi
  export TFRC_REUSE_ACTIVE_NODE

  _tg_active_cnt=$(printf '%s' "${_tg_tpus}" | jq 'length' 2>/dev/null || printf '0')
  _tg_qr_extra=$(printf '%s' "${_tg_qrs}" | jq --arg n "${_tg_target_name}-qr" '[.[] | select((.name | split("/") | last) != $n)] | length' 2>/dev/null || printf '0')
  if [ "${_tg_qr_extra}" -gt "${_tg_active_cnt}" ]; then
    _tg_active_cnt="${_tg_qr_extra}"
  fi
  if [ $(( _tg_active_cnt + 1 )) -gt "${_tg_max_nodes}" ]; then
    libscript_tfrc_abort "Zone '${_tg_zone}' already has ${_tg_active_cnt} TPU node(s)/Queued Resource(s), which would exceed max_concurrent_nodes=${_tg_max_nodes}."
  fi
}

# ## libscript_tfrc_postflight_audit
# Verifies zero session TPU VMs, Queued Resources, or persistent disks remain after teardown.
libscript_tfrc_postflight_audit() {
  _tg_proj="${1:-${GCP_PROJECT_ID:-}}"
  _tg_zone="${2:-${TPU_ZONE:-}}"
  _tg_target_name="${3:-${TPU_NAME:-}}"

  if [ -z "${_tg_proj}" ] && [ -n "${TFRC_CONFIG:-}" ] && [ -f "${TFRC_CONFIG}" ]; then
    _tg_proj=$(jq -r '.gcp_project_id' "${TFRC_CONFIG}")
  fi
  if [ "${DRY_RUN:-false}" = 'true' ] || [ "${DRY_RUN:-0}" = '1' ] || [ "${LIBSCRIPT_DRY_RUN:-0}" = '1' ]; then
    return 0
  fi
  command -v gcloud >/dev/null 2>&1 || return 0

  _tg_tpus=$(gcloud compute tpus tpu-vm list --zone="${_tg_zone}" --project="${_tg_proj}" --format=json 2>/dev/null || printf '[]')
  _tg_qrs=$(gcloud compute tpus queued-resources list --zone="${_tg_zone}" --project="${_tg_proj}" --format=json 2>/dev/null || gcloud alpha compute tpus queued-resources list --zone="${_tg_zone}" --project="${_tg_proj}" --format=json 2>/dev/null || printf '[]')
  _tg_disks=$(gcloud compute disks list --filter="zone:(${_tg_zone})" --project="${_tg_proj}" --format=json 2>/dev/null || printf '[]')

  _tg_rem_tpu=0
  _tg_rem_qr=0
  _tg_rem_disk=0
  if [ -n "${_tg_target_name}" ]; then
    _tg_rem_tpu=$(printf '%s' "${_tg_tpus}" | jq --arg n "${_tg_target_name}" '[.[] | select((.name | split("/") | last) == $n)] | length' 2>/dev/null || printf '0')
    _tg_rem_qr=$(printf '%s' "${_tg_qrs}" | jq --arg n "${_tg_target_name}-qr" '[.[] | select((.name | split("/") | last) == $n)] | length' 2>/dev/null || printf '0')
    _tg_rem_disk=$(printf '%s' "${_tg_disks}" | jq --arg n "${_tg_target_name}" '[.[] | select((.name // "") | contains($n))] | length' 2>/dev/null || printf '0')
  else
    _tg_rem_tpu=$(printf '%s' "${_tg_tpus}" | jq 'length' 2>/dev/null || printf '0')
    _tg_rem_qr=$(printf '%s' "${_tg_qrs}" | jq 'length' 2>/dev/null || printf '0')
  fi

  if [ "${_tg_rem_tpu}" -gt 0 ] || [ "${_tg_rem_qr}" -gt 0 ] || [ "${_tg_rem_disk}" -gt 0 ]; then
    printf '[TFRC-GUARD] [POSTFLIGHT-FAIL] Surviving resources detected in %s (tpu_vm=%s, queued_resources=%s, disks=%s)!\n' \
      "${_tg_zone}" "${_tg_rem_tpu}" "${_tg_rem_qr}" "${_tg_rem_disk}" >&2
    if [ -n "${_tg_target_name}" ]; then
      printf '[TFRC-GUARD] Emergency cleanup: gcloud compute tpus queued-resources delete "%s-qr" --zone="%s" --project="%s" --force --quiet && gcloud compute tpus tpu-vm delete "%s" --zone="%s" --project="%s" --quiet\n' \
        "${_tg_target_name}" "${_tg_zone}" "${_tg_proj}" "${_tg_target_name}" "${_tg_zone}" "${_tg_proj}" >&2
    fi
    return 1
  fi
  printf '[TFRC-GUARD] Post-flight audit passed: zero surviving TPU VMs, Queued Resources, or disks in %s.\n' "${_tg_zone}" >&2
  return 0
}

STACK="${STACK%"${THIS_FILE}":}"
export STACK
if [ -n "${_tg_caller_dir}" ]; then SCRIPT_DIR="${_tg_caller_dir}"; fi
if [ -n "${_tg_caller_this}" ]; then THIS_FILE="${_tg_caller_this}"; fi
unset _tg_caller_this _tg_caller_dir || true
