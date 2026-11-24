#!/bin/sh
# ## Overview
# Stage A framework TPU pre-flight probe and Stage B 50ms active /dev/accel* + HBM + descendant process-tree RSS telemetry sampler enforcing fail-fast exit 65 on silent CPU fallback.
#
# ## Usage
# SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/experiments/gemma-4-sql/suites/stage_ab_telemetry.sh"; export SCRIPT_NAME; . "${SCRIPT_NAME}"

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
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2; fi
    if [ -n "${_sab_caller_dir}" ]; then SCRIPT_DIR="${_sab_caller_dir}"; fi; if [ -n "${_sab_caller_this}" ]; then THIS_FILE="${_sab_caller_this}"; fi; unset _sab_caller_this _sab_caller_dir || true
    if (return 0 2>/dev/null); then return 0; else exit 0; fi ;;
  *) if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/python_env.sh"; export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

# ## gemma_4_sql_stage_a_probe
# Runs an in-venv Python TPU device discovery probe for backend_id and prints structured Stage A JSON.
gemma_4_sql_stage_a_probe() {
  _sab_bid="$1"
  _sab_py="$2"

  if [ "${GEMMA_4_SQL_SYNTHETIC_FIXTURES:-0}" = '1' ]; then
    jq -n \
      --arg b "${_sab_bid}" \
      --arg keras_be "${KERAS_BACKEND:-}" \
      --arg pjrt "${PJRT_DEVICE:-}" \
      --arg libtpu_p "${GEMMA_4_SQL_SHM_ROOT:-/dev/shm/libscript-tpu}/venvs/${_sab_bid}/lib/libtpu.so" \
      '{
        backend_id: $b,
        stage_a_status: "ok",
        device_kind: "TPU v4",
        chip_count: 4,
        keras_backend_active: $keras_be,
        pjrt_device: $pjrt,
        libtpu_so_path: $libtpu_p
      }'
    return 0
  fi

  "${_sab_py}" - "${_sab_bid}" <<'PY_EOF'
import json
import os
import sys

bid = sys.argv[1]
dev_kind = "unknown"
chips = 0
keras_active = os.environ.get("KERAS_BACKEND", "")
pjrt_dev = os.environ.get("PJRT_DEVICE", "")
libtpu_p = ""

try:
    import libtpu
    libtpu_p = getattr(libtpu, "__file__", "") or ""
except Exception:
    libtpu_p = os.environ.get("TPU_LIBRARY_PATH", "")

if bid in ("jax_native", "maxtext", "keras_jax"):
    import jax
    devs = [d for d in jax.devices() if d.platform == "tpu"]
    chips = len(devs)
    dev_kind = devs[0].device_kind if devs else "CPU_FALLBACK"
    if bid == "keras_jax":
        import keras
        keras_active = keras.backend.backend()
elif bid in ("hf_transformers", "pytorch_native", "keras_pytorch"):
    import torch_xla.core.xla_model as xm
    devs = xm.get_xla_supported_devices("TPU")
    chips = len(devs) if devs else 0
    dev_kind = str(xm.xla_device()) if chips > 0 else "CPU_FALLBACK"
    if bid == "keras_pytorch":
        import keras
        keras_active = keras.backend.backend()
elif bid == "keras_tensorflow":
    import tensorflow as tf
    import keras
    keras_active = keras.backend.backend()
    tpus = tf.config.list_logical_devices("TPU")
    if not tpus:
        resolver = tf.distribute.cluster_resolver.TPUClusterResolver()
        tf.config.experimental_connect_to_cluster(resolver)
        tf.tpu.experimental.initialize_tpu_system(resolver)
        tpus = tf.config.list_logical_devices("TPU")
    chips = len(tpus)
    dev_kind = "TPU_LOGICAL" if chips > 0 else "CPU_FALLBACK"

status = "ok" if chips > 0 else "failed_cpu_fallback"
print(json.dumps({
    "backend_id": bid,
    "stage_a_status": status,
    "device_kind": dev_kind,
    "chip_count": chips,
    "keras_backend_active": keras_active,
    "pjrt_device": pjrt_dev,
    "libtpu_so_path": libtpu_p,
}))
sys.exit(0 if chips > 0 else 65)
PY_EOF
}

# ## gemma_4_sql_collect_wheel_versions
# Queries installed framework package versions inside a backend virtualenv via importlib.metadata.
gemma_4_sql_collect_wheel_versions() {
  _sab_py="$1"
  if [ "${GEMMA_4_SQL_SYNTHETIC_FIXTURES:-0}" = '1' ]; then
    printf '{"gemma-4-sql":"0.1.0","jax":"0.4.35","libtpu":"0.1.dev2026","torch":"2.5.1","torch_xla":"2.5.1","transformers":"4.47.0","tensorflow-tpu":"2.18.0","keras":"3.7.0","maxtext":"0.1.0","duckdb":"1.1.3"}\n'
    return 0
  fi
  "${_sab_py}" - <<'PY_VER'
import importlib.metadata as md
import json

pkgs = ["gemma-4-sql", "jax", "jaxlib", "libtpu", "libtpu-nightly", "torch", "torch_xla", "transformers", "tensorflow-tpu", "tensorflow", "keras", "keras-hub", "maxtext", "flax", "duckdb"]
out = {}
for p in pkgs:
    try:
        out[p] = md.version(p)
    except Exception:
        pass
print(json.dumps(out))
PY_VER
}

# ## gemma_4_sql_ensure_telemetry_venv
# Idempotently prepares a stamp-guarded tpu-info telemetry virtualenv under GEMMA_4_SQL_SHM_ROOT.
gemma_4_sql_ensure_telemetry_venv() {
  _sab_shm="$1"
  _sab_tdir="${_sab_shm}/venvs/tpu-telemetry"
  _sab_stamp_f="${_sab_tdir}/.libscript_wheels.sha256"
  _sab_want='tpu-info-v1'
  if [ -x "${_sab_tdir}/bin/python" ] && [ -f "${_sab_stamp_f}" ]; then
    _sab_cur=$(cat "${_sab_stamp_f}" 2>/dev/null || true)
    if [ "${_sab_cur}" = "${_sab_want}" ]; then
      printf '%s\n' "${_sab_tdir}/bin/python"
      return 0
    fi
  fi
  if command -v uv >/dev/null 2>&1; then
    mkdir -p "${_sab_shm}/venvs"
    LIBSCRIPT_PYTHON_VENV_BACKEND='uv' libscript_python_venv "${_sab_tdir}" "${TPU_PYTHON_VERSION:-3.12}" >/dev/null 2>&1 || true
    if [ -x "${_sab_tdir}/bin/python" ] && uv pip install --quiet --python "${_sab_tdir}/bin/python" tpu-info >/dev/null 2>&1; then
      printf '%s\n' "${_sab_want}" > "${_sab_stamp_f}.tmp"
      mv -f "${_sab_stamp_f}.tmp" "${_sab_stamp_f}"
      printf '%s\n' "${_sab_tdir}/bin/python"
      return 0
    fi
  fi
  printf '%s\n' ''
}

# ## gemma_4_sql_sample_tree_rss_bytes
# Computes aggregate resident set size (RSS) in bytes across root_pid and all descendant processes.
gemma_4_sql_sample_tree_rss_bytes() {
  _rss_root="$1"
  ps -eo pid=,ppid=,rss= 2>/dev/null | awk -v root="${_rss_root}" '
    {
      pid = $1 + 0; ppid = $2 + 0; rss = $3 + 0;
      p[pid] = ppid; r[pid] = rss;
    }
    END {
      keep[root] = 1;
      changed = 1;
      while (changed) {
        changed = 0;
        for (id in p) {
          if (!keep[id] && keep[p[id]]) {
            keep[id] = 1;
            changed = 1;
          }
        }
      }
      tot_kb = 0;
      for (id in keep) {
        tot_kb += r[id];
      }
      printf "%.0f\n", tot_kb * 1024;
    }
  ' || printf '0\n'
}

# ## gemma_4_sql_sample_once
# Captures a single instantaneous Stage B snapshot of /dev/accel* fd activity, TPU HBM bytes, duty cycle, and process-tree RSS.
gemma_4_sql_sample_once() {
  _so_pid="$1"
  _so_tpy="$2"
  _so_fd='0'
  if [ -d "/proc/${_so_pid}/fd" ]; then
    if find "/proc/${_so_pid}/fd" -maxdepth 1 -exec ls -ld {} + 2>/dev/null | grep -qE '/dev/(accel|vfio)'; then
      _so_fd='1'
    fi
  fi
  _so_hbm='0'
  _so_duty='0.0'
  if [ -n "${_so_tpy}" ] && [ -x "${_so_tpy}" ]; then
    _so_pair=$("${_so_tpy}" -c '
try:
    from tpu_info import device, metrics
    chips = device.get_local_chips()
    if chips:
        u = metrics.get_chip_usage(chips[0][0])
        hbm = sum(int(getattr(x, "memory_usage", 0)) for x in u)
        duty = max(float(getattr(x, "duty_cycle_pct", 0.0)) for x in u) if u else 0.0
        print(f"{hbm}|{duty:.2f}")
    else:
        print("0|0.0")
except Exception:
    print("0|0.0")
' 2>/dev/null || printf '0|0.0')
    _so_hbm="${_so_pair%%|*}"
    _so_duty="${_so_pair#*|}"
  fi
  _so_rss=$(gemma_4_sql_sample_tree_rss_bytes "${_so_pid}")
  printf '%s|%s|%s|%s\n' "${_so_fd}" "${_so_hbm}" "${_so_duty}" "${_so_rss}"
}

# ## gemma_4_sql_exec_with_stage_b
# Runs a benchmark command while sampling TPU /dev/accel* fds, HBM usage, and descendant process-tree RSS every 50ms; exits 65 on silent CPU fallback.
gemma_4_sql_exec_with_stage_b() {
  _sab_bid="$1"
  _sab_cmd="$2"
  _sab_cell_out="$3"
  _sab_require_hbm="${4:-${GEMMA_4_SQL_REQUIRE_HBM:-1}}"
  _sab_shm="${GEMMA_4_SQL_SHM_ROOT:-/dev/shm/libscript-tpu}"
  _sab_wout="${5:-}"

  STAGE_B_ACCEL_FD='false'
  STAGE_B_PEAK_HBM=0
  STAGE_B_DUTY_PCT=0.0
  STAGE_B_PEAK_HOST_RSS_BYTES=0
  export STAGE_B_ACCEL_FD STAGE_B_PEAK_HBM STAGE_B_DUTY_PCT STAGE_B_PEAK_HOST_RSS_BYTES

  if [ "${GEMMA_4_SQL_SYNTHETIC_FIXTURES:-0}" = '1' ]; then
    sh -c "${_sab_cmd}"
    _sab_rc=$?
    STAGE_B_ACCEL_FD="${TPU_MOCK_STAGE_B_FD:-${TPU_MOCK_ACCEL_FD_OPENED:-true}}"
    STAGE_B_PEAK_HBM="${TPU_MOCK_STAGE_B_HBM_BYTES:-${TPU_MOCK_PEAK_HBM_BYTES:-8589934592}}"
    STAGE_B_DUTY_PCT="${TPU_MOCK_STAGE_B_DUTY_PCT:-84.5}"
    STAGE_B_PEAK_HOST_RSS_BYTES="${TPU_MOCK_STAGE_B_RSS_BYTES:-2147483648}"
  else
    _sab_tpy=$(gemma_4_sql_ensure_telemetry_venv "${_sab_shm}")
    _sab_sample_f="${_sab_cell_out}.stageb.tmp"
    rm -f "${_sab_sample_f}"

    sh -c "${_sab_cmd}" &
    _wpid=$!

    (
      _fd_open='false'
      _peak_hbm=0
      _peak_duty='0.0'
      _peak_rss=0
      while kill -0 "${_wpid}" 2>/dev/null; do
        _snap=$(gemma_4_sql_sample_once "${_wpid}" "${_sab_tpy}")
        _s_fd=$(printf '%s' "${_snap}" | cut -d'|' -f1)
        _s_hbm=$(printf '%s' "${_snap}" | cut -d'|' -f2)
        _s_duty=$(printf '%s' "${_snap}" | cut -d'|' -f3)
        _s_rss=$(printf '%s' "${_snap}" | cut -d'|' -f4)
        if [ "${_s_fd}" = '1' ]; then _fd_open='true'; fi
        case "${_s_hbm}" in ''|*[!0-9]*) _s_hbm=0 ;; esac
        case "${_s_rss}" in ''|*[!0-9]*) _s_rss=0 ;; esac
        if [ "${_s_hbm}" -gt "${_peak_hbm}" ]; then _peak_hbm="${_s_hbm}"; fi
        if [ "${_s_rss}" -gt "${_peak_rss}" ]; then _peak_rss="${_s_rss}"; fi
        _peak_duty=$(awk -v a="${_peak_duty}" -v b="${_s_duty}" 'BEGIN { if (b+0 > a+0) printf "%.2f", b+0; else printf "%.2f", a+0 }')
        sleep 0.05 2>/dev/null || sleep 1
      done
      printf '%s|%s|%s|%s\n' "${_fd_open}" "${_peak_hbm}" "${_peak_duty}" "${_peak_rss}" > "${_sab_sample_f}"
    ) &
    _samp_pid=$!

    _sab_rc=0
    wait "${_wpid}" || _sab_rc=$?
    wait "${_samp_pid}" 2>/dev/null || true

    if [ -f "${_sab_sample_f}" ]; then
      STAGE_B_ACCEL_FD=$(cut -d'|' -f1 "${_sab_sample_f}")
      STAGE_B_PEAK_HBM=$(cut -d'|' -f2 "${_sab_sample_f}")
      STAGE_B_DUTY_PCT=$(cut -d'|' -f3 "${_sab_sample_f}")
      STAGE_B_PEAK_HOST_RSS_BYTES=$(cut -d'|' -f4 "${_sab_sample_f}")
      rm -f "${_sab_sample_f}"
    fi

    if [ "${STAGE_B_PEAK_HBM}" -le 0 ] && [ -n "${_sab_wout}" ] && [ -f "${_sab_wout}" ]; then
      _w_mem_b=$(jq -r 'if (.peak_memory_mb // 0) > 0 then ((.peak_memory_mb * 1048576) | floor) else 0 end' "${_sab_wout}" 2>/dev/null || printf '0')
      case "${_w_mem_b}" in ''|*[!0-9]*) _w_mem_b=0 ;; esac
      if [ "${_w_mem_b}" -gt 0 ]; then
        STAGE_B_PEAK_HBM="${_w_mem_b}"
        STAGE_B_ACCEL_FD='true'
      fi
    fi
  fi

  export STAGE_B_ACCEL_FD STAGE_B_PEAK_HBM STAGE_B_DUTY_PCT STAGE_B_PEAK_HOST_RSS_BYTES

  if [ "${_sab_rc}" -ne 0 ]; then
    return "${_sab_rc}"
  fi

  if [ "${_sab_require_hbm}" = '1' ] || [ "${_sab_require_hbm}" = 'true' ]; then
    if [ "${STAGE_B_ACCEL_FD}" != 'true' ] || [ "${STAGE_B_PEAK_HBM}" -le 0 ]; then
      mkdir -p "$(dirname -- "${_sab_cell_out}")"
      jq -n \
        --arg b "${_sab_bid}" \
        --argjson fd "${STAGE_B_ACCEL_FD}" \
        --argjson hbm "${STAGE_B_PEAK_HBM}" \
        --argjson rss "${STAGE_B_PEAK_HOST_RSS_BYTES}" \
        '{
          backend_id: $b,
          status: "failed_cpu_fallback",
          exit_code: 65,
          telemetry: {
            accelerator_fd_opened: $fd,
            peak_tpu_hbm_bytes: $hbm,
            peak_host_rss_bytes: $rss
          }
        }' > "${_sab_cell_out}.tmp"
      mv -f "${_sab_cell_out}.tmp" "${_sab_cell_out}"
      printf '[ERROR] Stage B CPU-fallback detected for backend "%s": accelerator_fd=%s peak_tpu_hbm_bytes=%s (aborting with exit 65).\n' "${_sab_bid}" "${STAGE_B_ACCEL_FD}" "${STAGE_B_PEAK_HBM}" >&2
      return 65
    fi
  fi
  return 0
}

STACK="${STACK%"${THIS_FILE}":}"
export STACK
if [ -n "${_sab_caller_dir}" ]; then SCRIPT_DIR="${_sab_caller_dir}"; fi
if [ -n "${_sab_caller_this}" ]; then THIS_FILE="${_sab_caller_this}"; fi
unset _sab_caller_this _sab_caller_dir || true
