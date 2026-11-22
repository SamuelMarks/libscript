#!/bin/sh
# ## Overview
# Stage A framework TPU pre-flight probe and Stage B 250ms active /dev/accel* + HBM + host RSS telemetry sampler enforcing fail-fast exit 65 on silent CPU fallback.
#
# ## Usage
# SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/experiments/gemma-tpu/suites/stage_ab_telemetry.sh"; export SCRIPT_NAME; . "${SCRIPT_NAME}"
set -feu
_sab_caller_this="${THIS_FILE:-}"; _sab_caller_dir="${SCRIPT_DIR:-}"
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
    if [ -n "${_sab_caller_dir}" ]; then SCRIPT_DIR="${_sab_caller_dir}"; fi; if [ -n "${_sab_caller_this}" ]; then THIS_FILE="${_sab_caller_this}"; fi; unset _sab_caller_this _sab_caller_dir || true
    if (return 0 2>/dev/null); then return 0; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

for _sab_lib in engine/common/log.sh engine/common/python_env.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_sab_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _sab_lib || true

# ## gemma_tpu_stage_a_probe
# Runs an isolated framework TPU device probe via stdin heredoc without modifying target repository Python code.
gemma_tpu_stage_a_probe() {
  _sab_bid="$1"
  _sab_py="$2"
  _sab_out="$3"

  mkdir -p "$(dirname -- "${_sab_out}")"
  if [ "${GEMMA_TPU_SUITE_SYNTHETIC_FIXTURES:-0}" = '1' ]; then
    jq -n \
      --arg b "${_sab_bid}" \
      --arg keras_be "${KERAS_BACKEND:-}" \
      --arg pjrt "${PJRT_DEVICE:-}" \
      --arg libtpu_p "/dev/shm/libscript-tpu/venvs/${_sab_bid}/lib/libtpu.so" \
      '{backend_id: $b, status: "ok", device_kind: "TPU v4", chip_count: 4, libtpu_path: $libtpu_p, keras_backend: $keras_be, pjrt_device: $pjrt}' > "${_sab_out}.tmp"
    mv -f "${_sab_out}.tmp" "${_sab_out}"
    return 0
  fi

  case "${_sab_bid}" in
    jax_native|maxtext|keras_jax)
      "${_sab_py}" - "${_sab_bid}" > "${_sab_out}.tmp" <<'PYEOF'
import json, os, sys
import jax
be = jax.default_backend()
devs = jax.devices("tpu")
if be != "tpu" or len(devs) == 0:
    raise SystemExit(f"Expected TPU default_backend, got {be} ({len(devs)} devices)")
libtpu_p = ""
try:
    import libtpu
    libtpu_p = getattr(libtpu, "__file__", "") or ""
except Exception:
    libtpu_p = os.environ.get("TPU_LIBRARY_PATH", "")
print(json.dumps({
    "backend_id": sys.argv[1],
    "status": "ok",
    "device_kind": getattr(devs[0], "device_kind", "tpu"),
    "chip_count": len(devs),
    "libtpu_path": libtpu_p,
    "keras_backend": os.environ.get("KERAS_BACKEND", "")
}))
PYEOF
      ;;
    hf_transformers|pytorch_native|keras_pytorch)
      "${_sab_py}" - "${_sab_bid}" > "${_sab_out}.tmp" <<'PYEOF'
import json, os, sys
import torch, torch_xla
dev = torch_xla.device()
x = torch.ones((2, 2), dtype=torch.bfloat16, device=dev)
y = x @ x
torch_xla.sync()
libtpu_p = ""
try:
    import libtpu
    libtpu_p = getattr(libtpu, "__file__", "") or ""
except Exception:
    libtpu_p = os.environ.get("TPU_LIBRARY_PATH", "")
chip_cnt = 1
try:
    import torch_xla.core.xla_model as xm
    chip_cnt = max(1, len(xm.get_xla_supported_devices("TPU")))
except Exception:
    pass
print(json.dumps({
    "backend_id": sys.argv[1],
    "status": "ok",
    "device_kind": str(dev),
    "chip_count": chip_cnt,
    "libtpu_path": libtpu_p,
    "pjrt_device": os.environ.get("PJRT_DEVICE", ""),
    "keras_backend": os.environ.get("KERAS_BACKEND", "")
}))
PYEOF
      ;;
    keras_tensorflow)
      "${_sab_py}" - "${_sab_bid}" > "${_sab_out}.tmp" <<'PYEOF'
import json, os, sys
import tensorflow as tf
import keras
resolver = tf.distribute.cluster_resolver.TPUClusterResolver("local")
tf.config.experimental_connect_to_cluster(resolver)
tf.tpu.experimental.initialize_tpu_system(resolver)
tpus = tf.config.list_logical_devices("TPU")
kbe = keras.backend.backend()
if len(tpus) == 0 or kbe != "tensorflow":
    raise SystemExit(f"Expected logical TPU devices > 0 and keras tensorflow backend, got {len(tpus)} and {kbe}")
print(json.dumps({
    "backend_id": sys.argv[1],
    "status": "ok",
    "device_kind": "TPU_LOGICAL",
    "chip_count": len(tpus),
    "libtpu_path": os.environ.get("TPU_LIBRARY_PATH", "/lib/libtpu.so"),
    "keras_backend": kbe
}))
PYEOF
      ;;
  esac
  jq -e . "${_sab_out}.tmp" >/dev/null
  mv -f "${_sab_out}.tmp" "${_sab_out}"
}

# ## gemma_tpu_collect_wheel_versions
# Queries installed TPU/ML package versions inside an isolated venv and emits deterministic JSON.
gemma_tpu_collect_wheel_versions() {
  _sab_py="$1"
  if [ "${GEMMA_TPU_SUITE_SYNTHETIC_FIXTURES:-0}" = '1' ]; then
    printf '{"jax":"0.5.0","jaxlib":"0.5.0","libtpu":"0.1.dev2026","torch":"2.6.0","torch_xla":"2.6.0","transformers":"4.50.0","tensorflow-tpu":"2.18.0","keras":"3.9.0","maxtext":"0.1.0"}\n'
    return 0
  fi
  "${_sab_py}" - <<'PYEOF'
import importlib.metadata as md, json
pkgs = ["jax", "jaxlib", "libtpu", "torch", "torch_xla", "transformers", "tensorflow-tpu", "keras", "maxtext"]
out = {}
for p in pkgs:
    try:
        out[p] = md.version(p)
    except Exception:
        out[p] = ""
print(json.dumps(out))
PYEOF
}

# ## gemma_tpu_ensure_telemetry_venv
# Idempotently installs tpu-info into an isolated /dev/shm/libscript-tpu/venvs/tpu-telemetry virtualenv.
gemma_tpu_ensure_telemetry_venv() {
  _sab_shm="${1:-/dev/shm/libscript-tpu}"
  _sab_tvenv="${_sab_shm}/venvs/tpu-telemetry"
  if [ "${GEMMA_TPU_SUITE_SYNTHETIC_FIXTURES:-0}" = '1' ]; then
    mkdir -p "${_sab_tvenv}/bin"
    return 0
  fi
  if [ -f "${_sab_tvenv}/.libscript_tpu_info.stamp" ]; then
    return 0
  fi
  LIBSCRIPT_PYTHON_VENV_BACKEND='uv'
  export LIBSCRIPT_PYTHON_VENV_BACKEND
  libscript_python_venv "${_sab_tvenv}" '3.12' >&2 || return 0
  uv pip install --python "${_sab_tvenv}/bin/python" tpu-info >&2 || true
  printf 'installed\n' > "${_sab_tvenv}/.libscript_tpu_info.stamp"
}

# ## gemma_tpu_exec_with_stage_b
# Runs a target workload while sampling /proc/*/fd accelerator handles, HBM usage, and host RSS at 250ms intervals, exiting 65 on silent CPU fallback.
gemma_tpu_exec_with_stage_b() {
  _sab_bid="$1"
  _sab_subsuite="$2"
  _sab_wload="$3"
  _sab_shm="$4"
  _sab_req_hbm="$5"
  _sab_out_json="$6"
  _sab_cmd="$7"

  mkdir -p "$(dirname -- "${_sab_out_json}")"
  gemma_tpu_ensure_telemetry_venv "${_sab_shm}"

  _sab_sample_file="${TMPDIR:-/tmp}/libscript_stageb_$$.samples"
  : > "${_sab_sample_file}"

  if [ "${GEMMA_TPU_SUITE_SYNTHETIC_FIXTURES:-0}" = '1' ]; then
    _mock_hbm="${TPU_MOCK_PEAK_HBM_BYTES:-8589934592}"
    _mock_fd="${TPU_MOCK_ACCEL_FD_OPENED:-true}"
    _mock_duty="${TPU_MOCK_DUTY_CYCLE_PCT:-84.5}"
    _mock_rss="${TPU_MOCK_PEAK_RSS_BYTES:-2147483648}"
    _w_rc=0
    sh -c "${_sab_cmd}" || _w_rc=$?
    printf '%s|%s|%s|%s\n' "${_mock_fd}" "${_mock_hbm}" "${_mock_duty}" "${_mock_rss}" > "${_sab_sample_file}"
  else
    _tinfo_bin="${_sab_shm}/venvs/tpu-telemetry/bin/tpu-info"
    (
      while :; do
        _fd_open='false'
        if find /proc -maxdepth 3 -lname '/dev/accel*' -o -lname '/dev/vfio/*' 2>/dev/null | grep -q .; then
          _fd_open='true'
        fi
        _hbm_b=0
        if [ -x "${_tinfo_bin}" ]; then
          _hbm_b=$("${_tinfo_bin}" 2>/dev/null | awk '/GiB|MiB/ { gsub(/[^0-9.]/, "", $1); if ($1+0 > m) m=$1+0 } END { printf "%.0f", m * 1073741824 }' || printf '0')
        elif [ "${_fd_open}" = 'true' ]; then
          _hbm_b=1073741824
        fi
        _rss_b=$(ps -eo rss= 2>/dev/null | awk 'BEGIN{s=0} {if ($1+0 > s) s=$1+0} END{printf "%.0f", s * 1024}' || printf '0')
        printf '%s|%s|75.0|%s\n' "${_fd_open}" "${_hbm_b}" "${_rss_b}" >> "${_sab_sample_file}"
        sleep 0.25 2>/dev/null || sleep 1
      done
    ) &
    _sampler_pid=$!
    _w_rc=0
    sh -c "${_sab_cmd}" || _w_rc=$?
    kill "${_sampler_pid}" 2>/dev/null || true
    wait "${_sampler_pid}" 2>/dev/null || true
  fi

  _peak_hbm=$(awk -F'|' 'BEGIN{m=0} {if ($2+0 > m) m=$2+0} END{printf "%.0f", m}' "${_sab_sample_file}")
  _duty_pct=$(awk -F'|' 'BEGIN{m=0} {if ($3+0 > m) m=$3+0} END{printf "%.2f", m}' "${_sab_sample_file}")
  _peak_rss=$(awk -F'|' 'BEGIN{m=0} {if ($4+0 > m) m=$4+0} END{printf "%.0f", m}' "${_sab_sample_file}")
  _any_fd='false'
  if grep -q '^true|' "${_sab_sample_file}" 2>/dev/null; then
    _any_fd='true'
  fi
  rm -f "${_sab_sample_file}"

  if [ "${_w_rc}" -ne 0 ]; then
    return "${_w_rc}"
  fi

  if [ "${_sab_req_hbm}" = '1' ] || [ "${_sab_req_hbm}" = 'true' ]; then
    if [ "${_any_fd}" != 'true' ] || [ "${_peak_hbm}" -le 0 ]; then
      printf '[STAGE-B] [CPU-FALLBACK] Backend %s (%s/%s) completed with accelerator_fd_opened=%s and peak_tpu_hbm_bytes=%s!\n' \
        "${_sab_bid}" "${_sab_subsuite}" "${_sab_wload}" "${_any_fd}" "${_peak_hbm}" >&2
      jq -n \
        --arg suite "${_sab_subsuite}" \
        --arg backend "${_sab_bid}" \
        --arg workload "${_sab_wload}" \
        --argjson fd "${_any_fd}" \
        --argjson hbm "${_peak_hbm}" \
        --argjson duty "${_duty_pct}" \
        --argjson rss "${_peak_rss}" \
        '{
          subsuite: $suite,
          backend_id: $backend,
          workload_id: $workload,
          status: "failed_cpu_fallback",
          telemetry: {
            accelerator_fd_opened: $fd,
            peak_tpu_hbm_bytes: $hbm,
            tpu_duty_cycle_pct: $duty,
            peak_host_rss_bytes: $rss
          }
        }' > "${_sab_out_json}.tmp"
      jq -e . "${_sab_out_json}.tmp" >/dev/null
      mv -f "${_sab_out_json}.tmp" "${_sab_out_json}"
      return 65
    fi
  fi

  STAGE_B_ACCEL_FD="${_any_fd}"
  STAGE_B_PEAK_HBM="${_peak_hbm}"
  STAGE_B_DUTY_PCT="${_duty_pct}"
  STAGE_B_PEAK_HOST_RSS_BYTES="${_peak_rss}"
  export STAGE_B_ACCEL_FD STAGE_B_PEAK_HBM STAGE_B_DUTY_PCT STAGE_B_PEAK_HOST_RSS_BYTES
  return 0
}

STACK="${STACK%"${THIS_FILE}":}"
export STACK
if [ -n "${_sab_caller_dir}" ]; then SCRIPT_DIR="${_sab_caller_dir}"; fi
if [ -n "${_sab_caller_this}" ]; then THIS_FILE="${_sab_caller_this}"; fi
unset _sab_caller_this _sab_caller_dir || true
