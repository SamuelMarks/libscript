#!/bin/sh
# ## Overview
# Suite E0 runner (e0_tfrc_provenance.sh): Validates TFRC_CONFIG, records git SHA + dirty diff hash, TPU topology, per-venv wheel digests + versions, and Stage A probe telemetry into e0_provenance.json.
#
# ## Usage
# ./experiments/gemma-tpu/suites/e0_tfrc_provenance.sh <repo_dir> <results_dir> <backends_csv>
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

for _e0_lib in engine/common/log.sh engine/common/remote_sync.sh engine/common/tfrc_guard.sh workloads/ai/_common/tpu_matrix.sh experiments/gemma-tpu/suites/stage_ab_telemetry.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_e0_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _e0_lib || true

REPO_DIR="$1"
RESULTS_DIR="$2"
BACKENDS_CSV="${3:-${TPU_ALL_BACKENDS}}"
SHM_ROOT="${GEMMA_TPU_SUITE_SHM_ROOT:-/dev/shm/libscript-tpu}"
OUT_FILE="${RESULTS_DIR}/raw/e0_provenance.json"
mkdir -p "${RESULTS_DIR}/raw"

# ## derive_ici_mesh
# Computes a human-readable ICI mesh descriptor string for a TPU accelerator SKU and total chip count.
derive_ici_mesh() {
  _dim_sku="$1"
  _dim_chips="$2"
  case "${_dim_sku}" in
    v4-8) printf '2x2x1\n' ;;
    v4-16) printf '2x2x2\n' ;;
    v4-32) printf '2x2x4\n' ;;
    v5litepod-8|v5e-8|v6e-8) printf '2x4\n' ;;
    v5litepod-16|v5e-16|v6e-16) printf '4x4\n' ;;
    *) printf '1x%s\n' "${_dim_chips}" ;;
  esac
}

# ## run_e0_provenance
# Collects TFRC policy, git SHA + dirty diff hash, TPU topology, wheel stamps + versions, and Stage A probes into e0_provenance.json.
run_e0_provenance() {
  if libscript_tfrc_is_enabled; then
    libscript_tfrc_require_config "${REPO_DIR}"
  fi
  _tree_hash=$(libscript_compute_tree_hash "${REPO_DIR}")
  _git_sha='untracked'
  _dirty_hash='clean'
  if git -C "${REPO_DIR}" rev-parse HEAD >/dev/null 2>&1; then
    _git_sha=$(git -C "${REPO_DIR}" rev-parse HEAD)
    _porcelain=$(git -C "${REPO_DIR}" status --porcelain 2>/dev/null || true)
    if [ -n "${_porcelain}" ]; then
      _dirty_hash=$( { printf '%s\n' "${_porcelain}"; git -C "${REPO_DIR}" diff HEAD 2>/dev/null || true; } | cksum | awk '{print $1 "-" $2}' )
    fi
  fi

  if [ "${GEMMA_TPU_SUITE_RESUME:-1}" = '1' ] && [ -f "${OUT_FILE}" ]; then
    if jq -e --arg th "${_tree_hash}" '.status == "ok" and .tree_hash == $th' "${OUT_FILE}" >/dev/null 2>&1; then
      log_info "E0 provenance artifact already valid for tree_hash=${_tree_hash}; skipping idempotently."
      return 0
    fi
  fi

  _sku="${TPU_ACCELERATOR_TYPE:-v4-8}"
  _topo_pair=$(libscript_tfrc_derive_topology "${_sku}" "${TPU_COUNT:-1}")
  _w_cnt="${_topo_pair%% *}"
  _tot_chips="${_topo_pair##* }"
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
    _kbe=$(printf '%s' "${_spec}" | cut -d'|' -f3)
    _probe_f="${RESULTS_DIR}/raw/probe_${_bid}.json"
    KERAS_BACKEND="${_kbe}" PJRT_DEVICE='TPU' gemma_tpu_stage_a_probe "${_bid}" "${_vdir}/bin/python" "${_probe_f}"
    _wheel_stamp=$(cat "${_vdir}/.libscript_wheels.sha256" 2>/dev/null || printf 'none')
    _wheel_vers=$(gemma_tpu_collect_wheel_versions "${_vdir}/bin/python")
    _probes_json=$(printf '%s' "${_probes_json}" | jq \
      --slurpfile p "${_probe_f}" \
      --arg vg "${_vgroup}" \
      --arg ws "${_wheel_stamp}" \
      --argjson wv "${_wheel_vers}" \
      '. + [($p[0] + {venv_group: $vg, wheel_stamp: $ws, wheel_versions: $wv})]')
  done
  IFS="${_old_ifs}"

  jq -n \
    --arg git_sha "${_git_sha}" \
    --arg dirty_hash "${_dirty_hash}" \
    --arg tree_hash "${_tree_hash}" \
    --arg sku "${_sku}" \
    --arg rt "${TPU_VERSION:-auto}" \
    --arg zone "${TPU_ZONE:-local}" \
    --arg tfrc_cfg "${TFRC_CONFIG:-}" \
    --arg ici "${_ici_mesh}" \
    --argjson wcnt "${_w_cnt}" \
    --argjson cph "${_chips_per_host}" \
    --argjson tot_chips "${_tot_chips}" \
    --argjson probes "${_probes_json}" \
    '{
      subsuite: "E0",
      status: "ok",
      git_commit: $git_sha,
      dirty_diff_hash: $dirty_hash,
      tree_hash: $tree_hash,
      tfrc_config: $tfrc_cfg,
      tpu_zone: $zone,
      accelerator_type: $sku,
      runtime_version: $rt,
      topology: {
        worker_count: $wcnt,
        chips_per_host: $cph,
        total_chips: $tot_chips,
        ici_mesh: $ici
      },
      stage_a_probes: $probes
    }' > "${OUT_FILE}.tmp"
  jq -e . "${OUT_FILE}.tmp" >/dev/null
  mv -f "${OUT_FILE}.tmp" "${OUT_FILE}"
  log_info "Emitted E0 provenance artifact -> ${OUT_FILE}"
}

run_e0_provenance
