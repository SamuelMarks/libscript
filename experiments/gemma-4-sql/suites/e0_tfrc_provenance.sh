#!/bin/sh
# ## Overview
# Suite E0 runner (e0_tfrc_provenance.sh): Validates TFRC_CONFIG, records git SHA + dirty diff hash, TPU ICI topology, 5-family labels, per-venv wheel digests + versions, and Stage A probe telemetry into e0_provenance.json.
#
# ## Usage
# ./experiments/gemma-4-sql/suites/e0_tfrc_provenance.sh <repo_dir> <results_dir> [backends_csv]

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

_e0_this="${THIS_FILE}"
_e0_dir="${SCRIPT_DIR}"
for _lib in engine/common/log.sh engine/common/remote_sync.sh engine/common/tfrc_guard.sh workloads/ai/_common/tpu_matrix.sh experiments/gemma-4-sql/suites/stage_ab_telemetry.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _lib || true
THIS_FILE="${_e0_this}"
SCRIPT_DIR="${_e0_dir}"

REPO_ARG="${1:-$(pwd)}"
RESULTS_ARG="${2:-${LIBSCRIPT_ROOT_DIR}/build/experiment_results/gemma-4-sql}"
BACKENDS_CSV="${3:-${GEMMA_4_SQL_BACKENDS:-${TPU_ALL_BACKENDS}}}"
SHM_ROOT="${GEMMA_4_SQL_SHM_ROOT:-/dev/shm/libscript-tpu}"

# ## derive_ici_mesh
# Infers canonical TPU ICI mesh shape string from accelerator SKU and total chip count.
derive_ici_mesh() {
  _dim_sku="$1"
  _dim_chips="$2"
  case "${_dim_sku}" in
    v4-8) printf '2x2x1\n' ;;
    v4-16) printf '2x2x2\n' ;;
    v4-32) printf '2x2x4\n' ;;
    v5litepod-1|v5e-1|v6e-1) printf '1x1\n' ;;
    v5litepod-4|v5e-4|v6e-4) printf '2x2\n' ;;
    v5litepod-8|v5e-8|v6e-8) printf '2x4\n' ;;
    v5litepod-16|v5e-16|v6e-16) printf '4x4\n' ;;
    v5p-8) printf '2x2x1\n' ;;
    v5p-16) printf '2x2x2\n' ;;
    *) printf '1x%s\n' "${_dim_chips}" ;;
  esac
}

# ## run_e0_provenance
# Collects TFRC policy metadata, git provenance, TPU topology, and per-backend Stage A probes.
run_e0_provenance() {
  REPO_DIR=$(cd -- "${REPO_ARG}" && pwd)
  mkdir -p "${RESULTS_ARG}/raw"
  RESULTS_DIR=$(cd -- "${RESULTS_ARG}" && pwd)
  OUT_FILE="${RESULTS_DIR}/raw/e0_provenance.json"

  if libscript_tfrc_is_enabled; then
    libscript_tfrc_require_config "${REPO_DIR}"
    libscript_tfrc_enforce_zero_cost_env
  fi

  _git_sha='untracked'
  _dirty_hash='clean'
  if command -v git >/dev/null 2>&1 && git -C "${REPO_DIR}" rev-parse --verify HEAD >/dev/null 2>&1; then
    _git_sha=$(git -C "${REPO_DIR}" rev-parse HEAD)
    _diff_out=$(git -C "${REPO_DIR}" status --porcelain 2>/dev/null || true)
    if [ -n "${_diff_out}" ]; then
      _dirty_hash=$(printf '%s' "${_diff_out}" | cksum | awk '{print $1 "-" $2}')
    fi
  fi
  _tree_hash=$(libscript_compute_tree_hash "${REPO_DIR}")

  _sku="${TPU_ACCELERATOR_TYPE:-v4-8}"
  _zone="${TPU_ZONE:-us-central2-b}"
  _tier="${TPU_SCHEDULING_TYPE:-spot}"
  _w_cnt=1
  _tot_chips=4
  if [ -n "${TPU_NAME:-}" ] && [ "${GEMMA_4_SQL_LOCAL_EXEC:-0}" != '1' ]; then
    _topo=$("${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/gcp-tpu-vm/cli.sh" topology-info "${TPU_NAME}" 2>/dev/null || printf '{}')
    _sku=$(printf '%s' "${_topo}" | jq -r '.accelerator_type // "v4-8"')
    _zone=$(printf '%s' "${_topo}" | jq -r '.zone // "us-central2-b"')
    _w_cnt=$(printf '%s' "${_topo}" | jq -r '.worker_count // 1')
    _tot_chips=$(printf '%s' "${_topo}" | jq -r '.total_chips // 4')
  else
    case "${_sku}" in
      *-16) _w_cnt=2; _tot_chips=8 ;;
      *-32) _w_cnt=4; _tot_chips=16 ;;
      v5litepod-1|v5e-1|v6e-1) _w_cnt=1; _tot_chips=1 ;;
      v5litepod-8|v5e-8|v6e-8) _w_cnt=1; _tot_chips=8 ;;
    esac
  fi
  _chips_per_host=$(( _tot_chips / _w_cnt ))
  _ici_mesh=$(derive_ici_mesh "${_sku}" "${_tot_chips}")

  _probes_json='[]'
  _old_ifs="${IFS}"
  IFS=','
  for _bid in ${BACKENDS_CSV}; do
    IFS="${_old_ifs}"
    [ -n "${_bid}" ] || continue
    _vdir=$(libscript_tpu_prepare_backend_venv "${_bid}" "${REPO_DIR}" "${SHM_ROOT}")
    _spec=$(libscript_tpu_backend_spec "${_bid}" "${SHM_ROOT}")
    _vgroup=$(printf '%s' "${_spec}" | cut -d'|' -f1)
    _benv=$(printf '%s' "${_spec}" | cut -d'|' -f7)
    _fam=$(libscript_tpu_family_label "${_bid}")
    _stamp=$(cat "${_vdir}/.libscript_wheels.sha256" 2>/dev/null || printf 'none')

    _probe=$(for _kv in ${_benv}; do export "${_kv?}"; done; gemma_4_sql_stage_a_probe "${_bid}" "${_vdir}/bin/python")
    _wheel_vers=$(gemma_4_sql_collect_wheel_versions "${_vdir}/bin/python")

    _probes_json=$(printf '%s' "${_probes_json}" | jq \
      --argjson p "${_probe}" \
      --arg vg "${_vgroup}" \
      --arg fam "${_fam}" \
      --arg ws "${_stamp}" \
      --argjson wv "${_wheel_vers}" \
      '. + [($p + {comparison_family: $fam, venv_group: $vg, wheel_stamp: $ws, wheel_versions: $wv})]')
    IFS=','
  done
  IFS="${_old_ifs}"

  _tfrc_proj='none'
  if [ -n "${TFRC_CONFIG:-}" ] && [ -f "${TFRC_CONFIG}" ]; then
    _tfrc_proj=$(jq -r '.gcp_project_id // "none"' "${TFRC_CONFIG}")
  fi

  jq -n \
    --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --arg sha "${_git_sha}" \
    --arg dirty "${_dirty_hash}" \
    --arg th "${_tree_hash}" \
    --arg proj "${_tfrc_proj}" \
    --arg sku "${_sku}" \
    --arg zone "${_zone}" \
    --arg tier "${_tier}" \
    --arg ici "${_ici_mesh}" \
    --argjson hosts "${_w_cnt}" \
    --argjson cph "${_chips_per_host}" \
    --argjson total_c "${_tot_chips}" \
    --argjson probes "${_probes_json}" \
    '{
      suite: "E0",
      experiment_id: "gemma-4-sql",
      study_title: "gemma-4-sql: TPU performance comparisons betwixt JAX, Keras, and PyTorch on Google'\''s Gemma 4",
      status: "ok",
      timestamp_utc: $ts,
      git_sha: $sha,
      dirty_diff_hash: $dirty,
      tree_hash: $th,
      tfrc_project_id: $proj,
      topology: {
        accelerator_type: $sku,
        zone: $zone,
        scheduling_tier: $tier,
        host_count: $hosts,
        chips_per_host: $cph,
        total_chips: $total_c,
        ici_mesh: $ici
      },
      stage_a_probes: $probes
    }' > "${OUT_FILE}.tmp"
  jq -e . "${OUT_FILE}.tmp" >/dev/null
  mv -f "${OUT_FILE}.tmp" "${OUT_FILE}"
  log_info "Emitted E0 provenance artifact -> ${OUT_FILE}"
}

run_e0_provenance
