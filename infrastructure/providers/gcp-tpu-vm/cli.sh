#!/bin/sh
# ## Overview
# Command-line interface for managing single-host and multi-host GCP Cloud TPU VMs and Queued Resources with TFRC zero-cost guardrails.
#
# ## Usage
# ./libscript.sh gcp-tpu-vm <create|delete|start|stop|status|ssh|scp|profile|wait-ready|topology-info|sync-repo|arm-ttl|release-locks|tfrc-audit> [args...]

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

COMP_DIR="${SCRIPT_DIR}"
for LIB in engine/common/pkg_mgr.sh engine/common/log.sh engine/common/remote_sync.sh engine/common/tfrc_guard.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME || true
SCRIPT_DIR="${COMP_DIR}"

# ## resolve_tpu_runtime_version
# Resolves the Cloud TPU VM runtime image automatically from accelerator SKU when TPU_VERSION is empty or 'auto'.
resolve_tpu_runtime_version() {
  _rt_sku="${1:-v4-8}"
  _rt_ver="${2:-auto}"
  if [ -n "${_rt_ver}" ] && [ "${_rt_ver}" != 'auto' ]; then
    printf '%s\n' "${_rt_ver}"
    return 0
  fi
  case "${_rt_sku}" in
    v2-*|v3-*|v4-*) printf '%s\n' 'tpu-ubuntu2204-base' ;;
    v5litepod-*|v5e-*) printf '%s\n' 'v2-alpha-tpuv5-lite' ;;
    v5p-*) printf '%s\n' 'v2-alpha-tpuv5' ;;
    v6e-*) printf '%s\n' 'v2-alpha-tpuv6e' ;;
    *) printf '%s\n' 'tpu-ubuntu2204-base' ;;
  esac
}

# ## run_queued_resources_gcloud
# Invokes GA 'gcloud compute tpus queued-resources' with automatic fallback to 'gcloud alpha compute tpus queued-resources'.
run_queued_resources_gcloud() {
  if [ "${TPU_QR_FORCE_ALPHA:-0}" = '1' ]; then
    gcloud alpha compute tpus queued-resources "$@"
    return $?
  fi
  if gcloud compute tpus queued-resources "$@" 2>/dev/null; then
    return 0
  fi
  gcloud alpha compute tpus queued-resources "$@"
}

# ## load_cloud_tags_arg
# Loads optional GCP resource label flags from infrastructure/resources/core/tags.sh while preserving THIS_FILE and SCRIPT_DIR.
load_cloud_tags_arg() {
  if [ -f "${LIBSCRIPT_ROOT_DIR}/infrastructure/resources/core/tags.sh" ]; then
    _ls_src_this="${THIS_FILE:-}"
    _ls_src_dir="${SCRIPT_DIR:-}"
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/infrastructure/resources/core/tags.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090,SC1091
    . "${SCRIPT_NAME}"
    unset SCRIPT_NAME || true
    if [ -n "${_ls_src_this}" ]; then THIS_FILE="${_ls_src_this}"; fi
    if [ -n "${_ls_src_dir}" ]; then SCRIPT_DIR="${_ls_src_dir}"; fi
    libscript_format_tags gcp
    return 0
  fi
  printf '%s' ''
}

# ## check_cloud_managed
# Verifies whether a GCP resource is managed by LibScript before mutating or deleting it.
check_cloud_managed() {
  if libscript_tfrc_is_enabled; then return 0; fi
  _cm_type="$1"
  _cm_name="$2"
  _cm_zone="$3"
  if [ -f "${LIBSCRIPT_ROOT_DIR}/infrastructure/resources/core/tags.sh" ]; then
    _ls_src_this="${THIS_FILE:-}"
    _ls_src_dir="${SCRIPT_DIR:-}"
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/infrastructure/resources/core/tags.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090,SC1091
    . "${SCRIPT_NAME}"
    unset SCRIPT_NAME || true
    if [ -n "${_ls_src_this}" ]; then THIS_FILE="${_ls_src_this}"; fi
    if [ -n "${_ls_src_dir}" ]; then SCRIPT_DIR="${_ls_src_dir}"; fi
    libscript_verify_managed gcp "${_cm_type}" "${_cm_name}" "${_cm_zone}"
    return $?
  fi
  return 0
}

case "${1:-}" in
  --help|-h|/\?|-\?)
    printf '%s\n' "Usage: ${THIS_FILE} <create|delete|start|stop|status|ssh|scp|profile|wait-ready|topology-info|sync-repo|arm-ttl|release-locks|tfrc-audit> [args...]"
    printf '%s\n' 'See README.md for details.'
    exit 0
    ;;
  install)
    SCRIPT_NAME="${SCRIPT_DIR}/setup.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
    exit 0
    ;;
  test)
    SCRIPT_NAME="${SCRIPT_DIR}/test.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
    exit 0
    ;;
  logs|use|env|ls|ls-remote|download|uninstall|install-service|uninstall-service|which|exec|run)
    printf '[ERROR] Action '\''%s'\'' requires capability '\''versioned-artifact'\'' or '\''service-daemon'\'' (gcp-tpu-vm capabilities: ["cloud-operator"]).\n' "${1}" >&2
    exit 1
    ;;
esac

ACTION="${1:-}"
while [ $# -gt 0 ]; do
  case "$1" in
    --tfrc-config=*)
      TFRC_CONFIG="${1#*=}"
      export TFRC_CONFIG
      break
      ;;
    *) break ;;
  esac
done

if [ "${ACTION}" = 'tfrc-audit' ]; then
  shift
  _audit_mode='preflight'
  _audit_name="${TPU_NAME:-}"
  while [ $# -gt 0 ]; do
    case "$1" in
      --postflight) _audit_mode='postflight'; shift ;;
      --tfrc-config=*) TFRC_CONFIG="${1#*=}"; export TFRC_CONFIG; shift ;;
      --tfrc-config) TFRC_CONFIG="${2:-}"; export TFRC_CONFIG; shift 2 ;;
      *) _audit_name="$1"; shift ;;
    esac
  done
  libscript_tfrc_require_config
  _pol_proj=$(jq -r '.gcp_project_id' "${TFRC_CONFIG}")
  GCP_PROJECT_ID="${GCP_PROJECT_ID:-${_pol_proj}}"
  export GCP_PROJECT_ID
  if [ -n "${TPU_ZONE:-}" ]; then
    _zones="${TPU_ZONE}"
  else
    _zones=$(jq -r '.grants[].zone' "${TFRC_CONFIG}" | sort -u | tr '\n' ' ')
  fi
  for _z in ${_zones}; do
    if [ "${_audit_mode}" = 'postflight' ]; then
      libscript_tfrc_postflight_audit "${GCP_PROJECT_ID}" "${_z}" "${_audit_name}"
    else
      libscript_tfrc_preflight_audit "${GCP_PROJECT_ID}" "${_z}" "${_audit_name}"
    fi
  done
  printf '{"status":"ok","mode":"%s","project":"%s"}\n' "${_audit_mode}" "${GCP_PROJECT_ID}"
  exit 0
fi

if ! command -v gcloud >/dev/null 2>&1; then
  log_error 'gcloud not found in PATH. Please install the gcp-cli component first.'
  exit 1
fi

TPU_NAME="${2:-${TPU_NAME:-}}"
TPU_COUNT="${TPU_COUNT:-1}"
TPU_ACCELERATOR_TYPE="${TPU_ACCELERATOR_TYPE:-v4-8}"
TPU_SCHEDULING_TYPE="${TPU_SCHEDULING_TYPE:-on-demand}"

if libscript_tfrc_is_enabled; then
  libscript_tfrc_require_config
  if [ -z "${GCP_PROJECT_ID:-}" ]; then
    GCP_PROJECT_ID=$(jq -r '.gcp_project_id' "${TFRC_CONFIG}")
    export GCP_PROJECT_ID
  fi
  libscript_tfrc_enforce_zero_cost_env
fi

TPU_ZONE="${TPU_ZONE:-}"
if [ -z "${TPU_ZONE}" ]; then
  log_error 'TPU_ZONE must be explicitly specified (e.g., us-central2-b).'
  exit 1
fi

GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
if [ -z "${GCP_PROJECT_ID}" ]; then
  log_error 'GCP_PROJECT_ID must be explicitly specified to prevent accidental provisioning.'
  exit 1
fi

TPU_VERSION=$(resolve_tpu_runtime_version "${TPU_ACCELERATOR_TYPE}" "${TPU_VERSION:-auto}")
SCHEDULING_FLAG=''
if [ "${TPU_SCHEDULING_TYPE}" = 'spot' ]; then
  SCHEDULING_FLAG='--spot'
elif [ "${TPU_SCHEDULING_TYPE}" = 'preemptible' ]; then
  SCHEDULING_FLAG='--preemptible'
fi

TPU_DATA_DISK_SIZE="${TPU_DATA_DISK_SIZE:-}"
TPU_DATA_DISK_TYPE="${TPU_DATA_DISK_TYPE:-pd-balanced}"
PROJECT_FLAG="--project=${GCP_PROJECT_ID}"

case "${ACTION}" in
  create)
    if [ -z "${TPU_NAME}" ]; then log_error 'Usage: tpu-vm create <name>'; exit 1; fi
    if libscript_tfrc_is_enabled; then
      libscript_tfrc_validate_request "${GCP_PROJECT_ID}" "${TPU_ZONE}" "${TPU_ACCELERATOR_TYPE}" "${TPU_SCHEDULING_TYPE}" "${TPU_COUNT}"
      libscript_tfrc_preflight_audit "${GCP_PROJECT_ID}" "${TPU_ZONE}" "${TPU_NAME}"
    fi
    i=1
    while [ "${i}" -le "${TPU_COUNT}" ]; do
      INSTANCE_NAME="${TPU_NAME}"
      if [ "${TPU_COUNT}" -gt 1 ]; then
        INSTANCE_NAME="${TPU_NAME}-${i}"
      fi

      DISK_FLAG=''
      if [ -n "${TPU_DATA_DISK_SIZE}" ]; then
        if libscript_tfrc_is_enabled; then
          libscript_tfrc_abort 'Persistent disks are strictly forbidden in TFRC zero-cost mode.'
        fi
        DISK_FLAG="--data-disk=source=projects/${GCP_PROJECT_ID}/zones/${TPU_ZONE}/disks/${INSTANCE_NAME}-data,mode=read-write"
        if ! gcloud compute disks describe "${INSTANCE_NAME}-data" --zone="${TPU_ZONE}" "${PROJECT_FLAG}" >/dev/null 2>&1; then
          log_info "Creating persistent data disk ${INSTANCE_NAME}-data (${TPU_DATA_DISK_SIZE}GB, ${TPU_DATA_DISK_TYPE})..."
          TAGS_ARG=$(load_cloud_tags_arg)
          # shellcheck disable=SC2086
          gcloud compute disks create "${INSTANCE_NAME}-data" \
            --size="${TPU_DATA_DISK_SIZE}GB" \
            --type="${TPU_DATA_DISK_TYPE}" \
            --zone="${TPU_ZONE}" \
            "${PROJECT_FLAG}" ${TAGS_ARG}
        else
          log_info "Data disk ${INSTANCE_NAME}-data already exists."
        fi
      fi

      if [ "${TPU_USE_QUEUED_RESOURCE:-false}" = 'true' ]; then
        log_info "Checking if TPU Queued Resource ${INSTANCE_NAME}-qr exists in zone ${TPU_ZONE}..."
        QR_JSON=$(run_queued_resources_gcloud describe "${INSTANCE_NAME}-qr" --zone="${TPU_ZONE}" "${PROJECT_FLAG}" --format=json 2>/dev/null || true)
        QR_STATE=''
        if [ -n "${QR_JSON}" ] && command -v jq >/dev/null 2>&1; then
          QR_STATE=$(printf '%s' "${QR_JSON}" | jq -r '.state.state // .state // ""' 2>/dev/null || true)
        elif [ -n "${QR_JSON}" ]; then
          QR_STATE='ACTIVE'
        fi
        case "${QR_STATE}" in
          ACTIVE|READY|WAITING_FOR_RESOURCES|PROVISIONING|CREATING)
            log_info "TPU Queued Resource ${INSTANCE_NAME}-qr already exists (state: ${QR_STATE}); reusing idempotently."
            ;;
          FAILED|SUSPENDED)
            log_warn "TPU Queued Resource ${INSTANCE_NAME}-qr in terminal state ${QR_STATE}; deleting before recreate..."
            run_queued_resources_gcloud delete "${INSTANCE_NAME}-qr" --zone="${TPU_ZONE}" "${PROJECT_FLAG}" --quiet --force >/dev/null 2>&1 || true
            QR_STATE=''
            ;;
        esac
        if [ -z "${QR_STATE}" ]; then
          log_info "Creating TPU Queued Resource ${INSTANCE_NAME}-qr (${TPU_ACCELERATOR_TYPE}, runtime=${TPU_VERSION}) in ${TPU_ZONE}..."
          TAGS_ARG=$(load_cloud_tags_arg)
          set -- create "${INSTANCE_NAME}-qr" \
            "--node-id=${INSTANCE_NAME}" \
            "--zone=${TPU_ZONE}" \
            "--accelerator-type=${TPU_ACCELERATOR_TYPE}" \
            "--runtime-version=${TPU_VERSION}" \
            "${PROJECT_FLAG}"
          if [ -n "${SCHEDULING_FLAG}" ]; then set -- "$@" "${SCHEDULING_FLAG}"; fi
          if [ -n "${DISK_FLAG}" ]; then set -- "$@" "${DISK_FLAG}"; fi
          if [ -n "${TPU_NETWORK:-}" ]; then set -- "$@" "--network=${TPU_NETWORK}"; fi
          if [ -n "${TPU_SUBNETWORK:-}" ]; then set -- "$@" "--subnetwork=${TPU_SUBNETWORK}"; fi
          # shellcheck disable=SC2086
          if ! run_queued_resources_gcloud "$@" ${TAGS_ARG}; then
            log_error 'Queued Resource provisioning failed. Check TFRC quota availability.'
            exit 1
          fi
          log_info "TPU Queued Resource ${INSTANCE_NAME}-qr submitted successfully."
        fi
      else
        log_info "Checking if TPU VM ${INSTANCE_NAME} exists in zone ${TPU_ZONE}..."
        TPU_JSON=$(gcloud compute tpus tpu-vm describe "${INSTANCE_NAME}" --zone="${TPU_ZONE}" "${PROJECT_FLAG}" --format=json 2>/dev/null || true)
        TPU_STATE=''
        if [ -n "${TPU_JSON}" ] && command -v jq >/dev/null 2>&1; then
          TPU_STATE=$(printf '%s' "${TPU_JSON}" | jq -r '.state // ""' 2>/dev/null || true)
        elif [ -n "${TPU_JSON}" ]; then
          TPU_STATE='READY'
        fi
        case "${TPU_STATE}" in
          READY|ACTIVE|CREATING)
            log_info "TPU VM ${INSTANCE_NAME} already exists (state: ${TPU_STATE}); reusing idempotently."
            ;;
          TERMINATED|STOPPED|PREEMPTED)
            log_warn "TPU VM ${INSTANCE_NAME} in state ${TPU_STATE}; deleting before recreate..."
            gcloud compute tpus tpu-vm delete "${INSTANCE_NAME}" --zone="${TPU_ZONE}" "${PROJECT_FLAG}" --quiet >/dev/null 2>&1 || true
            TPU_STATE=''
            ;;
        esac
        if [ -z "${TPU_STATE}" ]; then
          log_info "Creating TPU VM ${INSTANCE_NAME} (${TPU_ACCELERATOR_TYPE}, version=${TPU_VERSION}) in ${TPU_ZONE}..."
          TAGS_ARG=$(load_cloud_tags_arg)
          set -- compute tpus tpu-vm create "${INSTANCE_NAME}" \
            "--zone=${TPU_ZONE}" \
            "--accelerator-type=${TPU_ACCELERATOR_TYPE}" \
            "--version=${TPU_VERSION}" \
            "${PROJECT_FLAG}"
          if [ -n "${SCHEDULING_FLAG}" ]; then set -- "$@" "${SCHEDULING_FLAG}"; fi
          if [ -n "${DISK_FLAG}" ]; then set -- "$@" "${DISK_FLAG}"; fi
          if [ -n "${TPU_NETWORK:-}" ]; then set -- "$@" "--network=${TPU_NETWORK}"; fi
          if [ -n "${TPU_SUBNETWORK:-}" ]; then set -- "$@" "--subnetwork=${TPU_SUBNETWORK}"; fi
          # shellcheck disable=SC2086
          if ! gcloud "$@" ${TAGS_ARG}; then
            log_error 'Provisioning failed. Check TFRC quota availability.'
            exit 1
          fi
          log_info "TPU VM ${INSTANCE_NAME} created successfully."
        fi
      fi
      i=$((i + 1))
    done
    ;;

  delete)
    if [ -z "${TPU_NAME}" ]; then log_error 'Usage: tpu-vm delete <name> [--all]'; exit 1; fi
    shift 2
    ALL_FLAG=''
    while [ $# -gt 0 ]; do
      case "$1" in
        --all) ALL_FLAG='true'; shift ;;
        *) shift ;;
      esac
    done
    i=1
    LIMIT="${TPU_COUNT}"
    if [ "${ALL_FLAG}" != 'true' ]; then LIMIT=1; fi
    while [ "${i}" -le "${LIMIT}" ]; do
      INSTANCE_NAME="${TPU_NAME}"
      if [ "${LIMIT}" -gt 1 ] && [ "${TPU_COUNT}" -gt 1 ]; then
        INSTANCE_NAME="${TPU_NAME}-${i}"
      fi

      if run_queued_resources_gcloud describe "${INSTANCE_NAME}-qr" --zone="${TPU_ZONE}" "${PROJECT_FLAG}" >/dev/null 2>&1; then
        log_info "Deleting TPU Queued Resource ${INSTANCE_NAME}-qr in zone ${TPU_ZONE}..."
        if check_cloud_managed qr "${INSTANCE_NAME}-qr" "${TPU_ZONE}"; then
          run_queued_resources_gcloud delete "${INSTANCE_NAME}-qr" --zone="${TPU_ZONE}" "${PROJECT_FLAG}" --quiet --force >/dev/null 2>&1 || true
        fi
      fi

      if gcloud compute tpus tpu-vm describe "${INSTANCE_NAME}" --zone="${TPU_ZONE}" "${PROJECT_FLAG}" >/dev/null 2>&1; then
        log_info "Deleting TPU VM ${INSTANCE_NAME} in zone ${TPU_ZONE}..."
        if check_cloud_managed tpu-vm "${INSTANCE_NAME}" "${TPU_ZONE}"; then
          gcloud compute tpus tpu-vm delete "${INSTANCE_NAME}" --zone="${TPU_ZONE}" "${PROJECT_FLAG}" --quiet >/dev/null 2>&1 || true
        fi
      else
        log_info "TPU VM ${INSTANCE_NAME} already absent in ${TPU_ZONE} (idempotent no-op)."
      fi

      if gcloud compute disks describe "${INSTANCE_NAME}-data" --zone="${TPU_ZONE}" "${PROJECT_FLAG}" >/dev/null 2>&1; then
        log_info "Deleting attached data disk ${INSTANCE_NAME}-data..."
        if check_cloud_managed volume "${INSTANCE_NAME}-data" "${TPU_ZONE}"; then
          gcloud compute disks delete "${INSTANCE_NAME}-data" --zone="${TPU_ZONE}" "${PROJECT_FLAG}" --quiet >/dev/null 2>&1 || true
        fi
      fi
      i=$((i + 1))
    done
    ;;

  start)
    if [ -z "${TPU_NAME}" ]; then log_error 'Usage: tpu-vm start <name> [--all]'; exit 1; fi
    shift 2
    ALL_FLAG=''
    while [ $# -gt 0 ]; do
      case "$1" in
        --all) ALL_FLAG='true'; shift ;;
        *) shift ;;
      esac
    done
    i=1
    LIMIT="${TPU_COUNT}"
    if [ "${ALL_FLAG}" != 'true' ]; then LIMIT=1; fi
    while [ "${i}" -le "${LIMIT}" ]; do
      INSTANCE_NAME="${TPU_NAME}"
      if [ "${LIMIT}" -gt 1 ] && [ "${TPU_COUNT}" -gt 1 ]; then
        INSTANCE_NAME="${TPU_NAME}-${i}"
      fi
      log_info "Starting TPU VM ${INSTANCE_NAME} in zone ${TPU_ZONE}..."
      gcloud compute tpus tpu-vm start "${INSTANCE_NAME}" --zone="${TPU_ZONE}" "${PROJECT_FLAG}" || true
      i=$((i + 1))
    done
    ;;

  stop)
    if [ -z "${TPU_NAME}" ]; then log_error 'Usage: tpu-vm stop <name> [--all]'; exit 1; fi
    shift 2
    ALL_FLAG=''
    while [ $# -gt 0 ]; do
      case "$1" in
        --all) ALL_FLAG='true'; shift ;;
        *) shift ;;
      esac
    done
    i=1
    LIMIT="${TPU_COUNT}"
    if [ "${ALL_FLAG}" != 'true' ]; then LIMIT=1; fi
    while [ "${i}" -le "${LIMIT}" ]; do
      INSTANCE_NAME="${TPU_NAME}"
      if [ "${LIMIT}" -gt 1 ] && [ "${TPU_COUNT}" -gt 1 ]; then
        INSTANCE_NAME="${TPU_NAME}-${i}"
      fi
      log_info "Stopping TPU VM ${INSTANCE_NAME} in zone ${TPU_ZONE}..."
      gcloud compute tpus tpu-vm stop "${INSTANCE_NAME}" --zone="${TPU_ZONE}" "${PROJECT_FLAG}" || true
      i=$((i + 1))
    done
    ;;

  status)
    if [ -z "${TPU_NAME}" ]; then log_error 'Usage: tpu-vm status <name> [--all]'; exit 1; fi
    shift 2
    ALL_FLAG=''
    while [ $# -gt 0 ]; do
      case "$1" in
        --all) ALL_FLAG='true'; shift ;;
        *) shift ;;
      esac
    done
    i=1
    LIMIT="${TPU_COUNT}"
    if [ "${ALL_FLAG}" != 'true' ]; then LIMIT=1; fi
    while [ "${i}" -le "${LIMIT}" ]; do
      INSTANCE_NAME="${TPU_NAME}"
      if [ "${LIMIT}" -gt 1 ] && [ "${TPU_COUNT}" -gt 1 ]; then
        INSTANCE_NAME="${TPU_NAME}-${i}"
      fi
      log_info "Status for TPU VM ${INSTANCE_NAME} in zone ${TPU_ZONE}..."
      if [ "${TPU_USE_QUEUED_RESOURCE:-false}" = 'true' ]; then
        run_queued_resources_gcloud describe "${INSTANCE_NAME}-qr" --zone="${TPU_ZONE}" "${PROJECT_FLAG}" || true
      else
        gcloud compute tpus tpu-vm describe "${INSTANCE_NAME}" --zone="${TPU_ZONE}" "${PROJECT_FLAG}" || true
      fi
      i=$((i + 1))
    done
    ;;

  wait-ready)
    if [ -z "${TPU_NAME}" ]; then log_error 'Usage: tpu-vm wait-ready <name> [--timeout-sec 1800] [--poll-sec 15]'; exit 1; fi
    shift 2
    WAIT_TIMEOUT="${TPU_WAIT_TIMEOUT_SEC:-1800}"
    WAIT_POLL="${TPU_WAIT_POLL_SEC:-15}"
    while [ $# -gt 0 ]; do
      case "$1" in
        --timeout-sec=*) WAIT_TIMEOUT="${1#*=}"; shift ;;
        --timeout-sec) WAIT_TIMEOUT="$2"; shift 2 ;;
        --poll-sec=*) WAIT_POLL="${1#*=}"; shift ;;
        --poll-sec) WAIT_POLL="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    _elapsed=0
    while [ "${_elapsed}" -le "${WAIT_TIMEOUT}" ]; do
      if run_queued_resources_gcloud describe "${TPU_NAME}-qr" --zone="${TPU_ZONE}" "${PROJECT_FLAG}" --format=json >/tmp/libscript_qr_wait_$$.json 2>/dev/null; then
        _qstate=$(jq -r '.state.state // .state // "ACTIVE"' /tmp/libscript_qr_wait_$$.json 2>/dev/null || printf 'ACTIVE')
        rm -f /tmp/libscript_qr_wait_$$.json
        case "${_qstate}" in
          FAILED|SUSPENDED)
            log_error "Queued Resource ${TPU_NAME}-qr entered terminal state: ${_qstate}"
            exit 1
            ;;
          ACTIVE|READY)
            break
            ;;
          *)
            log_info "Queued Resource ${TPU_NAME}-qr state=${_qstate}; waiting (${_elapsed}/${WAIT_TIMEOUT}s)..."
            ;;
        esac
      elif gcloud compute tpus tpu-vm describe "${TPU_NAME}" --zone="${TPU_ZONE}" "${PROJECT_FLAG}" --format=json >/tmp/libscript_tpu_wait_$$.json 2>/dev/null; then
        _tstate=$(jq -r '.state // "READY"' /tmp/libscript_tpu_wait_$$.json 2>/dev/null || printf 'READY')
        rm -f /tmp/libscript_tpu_wait_$$.json
        if [ "${_tstate}" = 'READY' ] || [ "${_tstate}" = 'ACTIVE' ]; then
          break
        fi
      fi
      sleep "${WAIT_POLL}"
      _elapsed=$((_elapsed + WAIT_POLL))
    done
    if [ "${_elapsed}" -gt "${WAIT_TIMEOUT}" ]; then
      log_error "Timed out after ${WAIT_TIMEOUT}s waiting for TPU ${TPU_NAME} to become ACTIVE."
      exit 1
    fi
    _ssh_try=0
    while [ "${_ssh_try}" -lt 5 ]; do
      if gcloud compute tpus tpu-vm ssh "${TPU_NAME}" --zone="${TPU_ZONE}" "${PROJECT_FLAG}" --worker=all --command='true' >/dev/null 2>&1; then
        log_info "TPU ${TPU_NAME} is ACTIVE and SSH-reachable across all workers."
        exit 0
      fi
      _ssh_try=$((_ssh_try + 1))
      sleep "${WAIT_POLL}"
    done
    log_error "TPU ${TPU_NAME} became ACTIVE but SSH across --worker=all failed."
    exit 1
    ;;

  topology-info)
    if [ -z "${TPU_NAME}" ]; then log_error 'Usage: tpu-vm topology-info <name>'; exit 1; fi
    _desc_json=$(gcloud compute tpus tpu-vm describe "${TPU_NAME}" --zone="${TPU_ZONE}" "${PROJECT_FLAG}" --format=json)
    printf '%s\n' "${_desc_json}" | jq -c \
      --arg def_sku "${TPU_ACCELERATOR_TYPE}" \
      --arg def_rt "${TPU_VERSION}" \
      --arg def_tier "${TPU_SCHEDULING_TYPE}" '
      ([(.networkEndpoints // [])[] | (.ipAddress // .accessConfig.externalIp // "127.0.0.1")]) as $ips
      | (if ($ips | length) == 0 then ["127.0.0.1"] else $ips end) as $norm_ips
      | {
          name: ((.name // "") | split("/") | last),
          worker_count: ($norm_ips | length),
          worker0_internal_ip: $norm_ips[0],
          worker_ips: ($norm_ips | join(",")),
          accelerator_type: ((.acceleratorType // $def_sku) | split("/") | last),
          runtime_version: (.runtimeVersion // $def_rt),
          scheduling_type: (if .schedulingConfig.spot == true then "spot" elif .schedulingConfig.preemptible == true then "preemptible" else $def_tier end)
        }
    '
    ;;

  sync-repo)
    if [ -z "${TPU_NAME}" ]; then log_error 'Usage: tpu-vm sync-repo <name> <local_dir> <remote_dir> [--all-workers]'; exit 1; fi
    shift 2
    SYNC_LOCAL=''
    SYNC_REMOTE=''
    SYNC_ALL_WORKERS='0'
    while [ $# -gt 0 ]; do
      case "$1" in
        --all-workers) SYNC_ALL_WORKERS='1'; shift ;;
        *)
          if [ -z "${SYNC_LOCAL}" ]; then SYNC_LOCAL="$1"
          elif [ -z "${SYNC_REMOTE}" ]; then SYNC_REMOTE="$1"
          fi
          shift
          ;;
      esac
    done
    if [ -z "${SYNC_LOCAL}" ] || [ -z "${SYNC_REMOTE}" ] || [ ! -d "${SYNC_LOCAL}" ]; then
      log_error 'Usage: tpu-vm sync-repo <name> <local_dir> <remote_dir> [--all-workers]'
      exit 1
    fi
    _tree_hash=$(libscript_compute_tree_hash "${SYNC_LOCAL}")
    set -- compute tpus tpu-vm ssh "${TPU_NAME}" "--zone=${TPU_ZONE}" "${PROJECT_FLAG}"
    if [ "${SYNC_ALL_WORKERS}" = '1' ]; then set -- "$@" '--worker=all'; fi
    _remote_hashes=$(gcloud "$@" --command="cat ${SYNC_REMOTE}/.libscript_sync.sha256 2>/dev/null || printf 'MISSING'" 2>/dev/null || printf 'MISSING')
    _mismatch=0
    if [ -z "${_remote_hashes}" ]; then
      _mismatch=1
    else
      for _rh in ${_remote_hashes}; do
        if [ "${_rh}" != "${_tree_hash}" ]; then
          _mismatch=1
        fi
      done
    fi
    if [ "${_mismatch}" -eq 0 ]; then
      log_info "Remote directory ${SYNC_REMOTE} already matches tree digest ${_tree_hash}; skipping sync-repo idempotently."
      exit 0
    fi
    _tmp_tar="${TMPDIR:-/tmp}/libscript_sync_${TPU_NAME}_$$.tar.gz"
    trap 'rm -f "${_tmp_tar}"' EXIT
    if git -C "${SYNC_LOCAL}" rev-parse --is-inside-work-tree >/dev/null 2>&1 && [ -z "$(git -C "${SYNC_LOCAL}" status --porcelain 2>/dev/null)" ]; then
      git -C "${SYNC_LOCAL}" archive --format=tar.gz -o "${_tmp_tar}" HEAD
    else
      tar -czf "${_tmp_tar}" \
        --exclude='.git' \
        --exclude='.venv*' \
        --exclude='.tox' \
        --exclude='.pytest_cache' \
        --exclude='.ruff_cache' \
        --exclude='htmlcov' \
        --exclude='__pycache__' \
        --exclude='build' \
        --exclude='*.pyc' \
        -C "${SYNC_LOCAL}" .
    fi
    set -- compute tpus tpu-vm scp
    if [ "${SYNC_ALL_WORKERS}" = '1' ]; then set -- "$@" '--worker=all'; fi
    gcloud "$@" "${_tmp_tar}" "${TPU_NAME}:/tmp/libscript_repo_sync.tar.gz" "--zone=${TPU_ZONE}" "${PROJECT_FLAG}"
    set -- compute tpus tpu-vm ssh "${TPU_NAME}" "--zone=${TPU_ZONE}" "${PROJECT_FLAG}"
    if [ "${SYNC_ALL_WORKERS}" = '1' ]; then set -- "$@" '--worker=all'; fi
    gcloud "$@" --command="mkdir -p ${SYNC_REMOTE} && tar -xzf /tmp/libscript_repo_sync.tar.gz -C ${SYNC_REMOTE} && printf '%s\n' '${_tree_hash}' > ${SYNC_REMOTE}/.libscript_sync.sha256 && rm -f /tmp/libscript_repo_sync.tar.gz"
    rm -f "${_tmp_tar}"
    trap - EXIT
    log_info "Synced ${SYNC_LOCAL} -> ${TPU_NAME}:${SYNC_REMOTE} (digest=${_tree_hash})."
    ;;

  arm-ttl)
    if [ -z "${TPU_NAME}" ]; then log_error 'Usage: tpu-vm arm-ttl <name> [--minutes 180]'; exit 1; fi
    shift 2
    TTL_MINUTES="${TFRC_MAX_TTL_MINUTES:-180}"
    while [ $# -gt 0 ]; do
      case "$1" in
        --minutes=*) TTL_MINUTES="${1#*=}"; shift ;;
        --minutes) TTL_MINUTES="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    TTL_SECS=$((TTL_MINUTES * 60))
    _ttl_cmd="if [ -f /tmp/libscript_tfrc_ttl.pid ]; then kill \"\$(cat /tmp/libscript_tfrc_ttl.pid)\" 2>/dev/null || true; rm -f /tmp/libscript_tfrc_ttl.pid; fi; nohup sh -c 'sleep ${TTL_SECS}; gcloud compute tpus queued-resources delete ${TPU_NAME}-qr --zone=${TPU_ZONE} --project=${GCP_PROJECT_ID} --force --quiet >/dev/null 2>&1 || true; gcloud compute tpus tpu-vm delete ${TPU_NAME} --zone=${TPU_ZONE} --project=${GCP_PROJECT_ID} --quiet >/dev/null 2>&1 || true; /sbin/shutdown -h now >/dev/null 2>&1 || true' >/tmp/libscript_tfrc_ttl.log 2>&1 & printf '%s\n' \"\$!\" >/tmp/libscript_tfrc_ttl.pid"
    gcloud compute tpus tpu-vm ssh "${TPU_NAME}" --zone="${TPU_ZONE}" "${PROJECT_FLAG}" --worker=all --command="${_ttl_cmd}"
    log_info "Armed idempotent ${TTL_MINUTES}-minute dead-man's switch TTL on all workers of ${TPU_NAME}."
    ;;

  release-locks)
    if [ -z "${TPU_NAME}" ]; then log_error 'Usage: tpu-vm release-locks <name>'; exit 1; fi
    # shellcheck disable=SC2016
    _rel_cmd='fuser -k /dev/accel* /dev/vfio/* >/dev/null 2>&1 || true; _i=0; while [ "$_i" -lt 10 ]; do if ! fuser /dev/accel* /dev/vfio/* >/dev/null 2>&1; then exit 0; fi; sleep 1; _i=$((_i + 1)); done; exit 0'
    gcloud compute tpus tpu-vm ssh "${TPU_NAME}" --zone="${TPU_ZONE}" "${PROJECT_FLAG}" --worker=all --command="${_rel_cmd}"
    log_info "Released /dev/accel* and /dev/vfio/* device locks across all workers of ${TPU_NAME}."
    ;;

  profile)
    if [ -z "${TPU_NAME}" ]; then log_error 'Usage: tpu-vm profile <name> [--port 9012] [--duration 1000]'; exit 1; fi
    shift 2
    PORT='9012'
    DURATION='1000'
    while [ $# -gt 0 ]; do
      case "$1" in
        --port=*) PORT="${1#*=}"; shift ;;
        --port) PORT="$2"; shift 2 ;;
        --duration=*) DURATION="${1#*=}"; shift ;;
        --duration) DURATION="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    log_info "Initiating capture_tpu_profile session on ${TPU_NAME} in ${TPU_ZONE}..."
    TPU_PROFILE_LOGDIR="${TPU_PROFILE_LOGDIR:-${TMPDIR:-/tmp}/tpu_profile}"
    gcloud compute tpus tpu-vm ssh "${TPU_NAME}" --zone="${TPU_ZONE}" "${PROJECT_FLAG}" --worker=all --command="capture_tpu_profile --tpu=\$HOSTNAME --profiler_port=${PORT} --duration_ms=${DURATION} --logdir=${TPU_PROFILE_LOGDIR}"
    ;;

  scp|scp-from)
    if [ -z "${TPU_NAME}" ]; then log_error 'Usage: tpu-vm scp <name> <src> <dest> [--all-workers] [--worker=<id>] [--recurse]'; exit 1; fi
    shift 2
    WORKER_ARG=''
    RECURSE_FLAG=''
    SRC=''
    DEST=''
    while [ $# -gt 0 ]; do
      case "$1" in
        --all-workers) WORKER_ARG='--worker=all'; shift ;;
        --worker=*) WORKER_ARG="--worker=${1#*=}"; shift ;;
        --worker) WORKER_ARG="--worker=$2"; shift 2 ;;
        --recurse|-r) RECURSE_FLAG='--recurse'; shift ;;
        *)
          if [ -z "${SRC}" ]; then SRC="$1"
          elif [ -z "${DEST}" ]; then DEST="$1"
          else log_error 'Too many arguments for scp'; exit 1
          fi
          shift
          ;;
      esac
    done
    if [ -z "${SRC}" ] || [ -z "${DEST}" ]; then
      log_error 'Usage: tpu-vm scp <name> <src> <dest> [--all-workers]'
      exit 1
    fi
    log_info "Copying files for TPU VM ${TPU_NAME}..."
    set -- compute tpus tpu-vm scp
    if [ -n "${WORKER_ARG}" ]; then set -- "$@" "${WORKER_ARG}"; fi
    if [ -n "${RECURSE_FLAG}" ]; then set -- "$@" "${RECURSE_FLAG}"; fi
    if printf '%s\n' "${DEST}" | grep -q ':' || printf '%s\n' "${SRC}" | grep -q ':'; then
      gcloud "$@" "${SRC}" "${DEST}" "--zone=${TPU_ZONE}" "${PROJECT_FLAG}"
    else
      gcloud "$@" "${SRC}" "${TPU_NAME}:${DEST}" "--zone=${TPU_ZONE}" "${PROJECT_FLAG}"
    fi
    ;;

  ssh)
    if [ -z "${TPU_NAME}" ]; then log_error 'Usage: tpu-vm ssh <name> [--detached] [--forward-port <local>:<remote>] [--all-workers] [--worker=<id>] [command]'; exit 1; fi
    shift 2
    DETACHED=''
    WORKER_ARG=''
    FORWARD_PORT=''
    EXPLICIT_CMD=''
    while [ $# -gt 0 ]; do
      case "$1" in
        --detached) DETACHED='true'; shift ;;
        --forward-port=*) FORWARD_PORT="${1#*=}"; shift ;;
        --forward-port) FORWARD_PORT="$2"; shift 2 ;;
        --all-workers) WORKER_ARG='--worker=all'; shift ;;
        --worker=*) WORKER_ARG="--worker=${1#*=}"; shift ;;
        --worker) WORKER_ARG="--worker=$2"; shift 2 ;;
        --command=*) EXPLICIT_CMD="${1#*=}"; shift ;;
        --command) EXPLICIT_CMD="$2"; shift 2 ;;
        --) shift; break ;;
        *) break ;;
      esac
    done
    if [ -z "${EXPLICIT_CMD}" ] && [ $# -gt 0 ]; then
      EXPLICIT_CMD="$*"
    fi
    set -- compute tpus tpu-vm ssh "${TPU_NAME}" "--zone=${TPU_ZONE}" "${PROJECT_FLAG}"
    if [ -n "${WORKER_ARG}" ]; then set -- "$@" "${WORKER_ARG}"; fi
    if [ -n "${FORWARD_PORT}" ]; then
      log_info "Forwarding port ${FORWARD_PORT}..."
      set -- "$@" "--ssh-flag=-L${FORWARD_PORT}"
    fi
    log_info "Connecting to TPU VM ${TPU_NAME}..."
    if [ -n "${EXPLICIT_CMD}" ]; then
      if [ "${DETACHED}" = 'true' ]; then
        log_info "Running command in detached tmux session 'ml-session'"
        gcloud "$@" --command "tmux new-session -d -s ml-session \"${EXPLICIT_CMD}\""
      else
        gcloud "$@" --command "${EXPLICIT_CMD}"
      fi
    else
      gcloud "$@"
    fi
    ;;

  *)
    log_error "Unknown or missing action: ${ACTION}. Supported: create, delete, start, stop, ssh, scp, status, profile, wait-ready, topology-info, sync-repo, arm-ttl, release-locks, tfrc-audit."
    exit 1
    ;;
esac
