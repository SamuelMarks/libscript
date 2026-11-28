#!/bin/sh
# ## Overview
# Smoke and idempotent Suite E9 + E8 synthesis validation test for the `libtpu-pjrt` experiment plugin.
# ## Usage
# ./experiments/libtpu-pjrt/test.sh

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

# ## run_libtpu_pjrt_smoke_test
# Validates suite.json/vars.schema.json and verifies idempotent synthetic E0 + E9 + E8 multi-framework comparison synthesis.
run_libtpu_pjrt_smoke_test() {
  STACK='' "${LIBSCRIPT_ROOT_DIR}/experiments/engine.sh" validate 'libtpu-pjrt' >/dev/null
  _t_dir=$(mktemp -d)
  STACK='' "${SCRIPT_DIR}/provision.sh" --dry-run >/dev/null
  STACK='' "${SCRIPT_DIR}/benchmark_experiments.sh" --synthetic-fixtures --subsuites='E0,E9,E8' --results-dir="${_t_dir}/res" >/dev/null
  STACK='' "${SCRIPT_DIR}/benchmark_experiments.sh" --synthetic-fixtures --subsuites='E0,E9,E8' --results-dir="${_t_dir}/res" >/dev/null
  [ -s "${_t_dir}/res/e9_jax_vs_og.json" ]
  [ -s "${_t_dir}/res/e9_keras_jax_vs_og.json" ]
  [ -s "${_t_dir}/res/e9_pytorch_tpu_vs_og.json" ]
  [ -s "${_t_dir}/res/e9_tensorflow_tpu_vs_og.json" ]
  [ -s "${_t_dir}/res/e9_framework_comparison.json" ]
  [ -s "${_t_dir}/res/e9_framework_comparison.csv" ]
  [ -s "${_t_dir}/res/e9_framework_comparison.md" ]
  [ -s "${_t_dir}/res/generated_metrics.tex" ]
  grep -q 'MetricJaxSpeedupVsOgX' "${_t_dir}/res/generated_metrics.tex"
  grep -q 'MetricKerasJaxSpeedupVsOgX' "${_t_dir}/res/generated_metrics.tex"
  grep -q 'MetricPytorchTpuSpeedupVsOgX' "${_t_dir}/res/generated_metrics.tex"
  grep -q 'MetricTensorflowTpuSpeedupVsOgX' "${_t_dir}/res/generated_metrics.tex"
  rm -rf "${_t_dir}"
}

run_libtpu_pjrt_smoke_test
