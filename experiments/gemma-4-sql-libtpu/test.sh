#!/bin/sh
# ## Overview
# Smoke validation, Stage A SHA-256 distinctness guard check, and idempotent A/B LaTeX synthesis test for `gemma-4-sql-libtpu`.
# ## Usage
# ./experiments/gemma-4-sql-libtpu/test.sh

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

# ## run_gemma4_libtpu_ab_smoke_test
# Validates manifest/schema, --dry-run, distinct SHA-256 enforcement (exit 65 on collision), and idempotent A/B synthesis.
run_gemma4_libtpu_ab_smoke_test() {
  STACK='' "${LIBSCRIPT_ROOT_DIR}/experiments/engine.sh" validate 'gemma-4-sql-libtpu' >/dev/null
  _t_dir=$(mktemp -d)
  mkdir -p "${_t_dir}/out/og/raw" "${_t_dir}/out/rs/raw"

  STACK='' "${SCRIPT_DIR}/run.sh" --dry-run --repo-dir="${_t_dir}" --results-dir="${_t_dir}/out" >/dev/null

  cat <<'OG_EOF' > "${_t_dir}/out/og/raw/e0_provenance.json"
{"suite":"E0","libtpu_provider":"og","stage_a_probes":[{"backend_id":"jax_native","libtpu_mapped_so_sha256":"aaaa1111"}]}
OG_EOF
  cat <<'RS_EOF' > "${_t_dir}/out/rs/raw/e0_provenance.json"
{"suite":"E0","libtpu_provider":"rs","stage_a_probes":[{"backend_id":"jax_native","libtpu_mapped_so_sha256":"bbbb2222"}]}
RS_EOF
  cat <<'E1_OG' > "${_t_dir}/out/og/raw/e1_inference_jax_native.json"
{"prefill_tokens_per_sec":1200,"decode_tokens_per_sec":140,"cold_compile_ms":25.0,"latency_ms":{"p50":7.1,"p99":7.9},"telemetry":{"peak_tpu_hbm_bytes":4000000000}}
E1_OG
  cat <<'E1_RS' > "${_t_dir}/out/rs/raw/e1_inference_jax_native.json"
{"prefill_tokens_per_sec":1320,"decode_tokens_per_sec":154,"cold_compile_ms":12.5,"latency_ms":{"p50":6.4,"p99":7.1},"telemetry":{"peak_tpu_hbm_bytes":3800000000}}
E1_RS

  STACK='' "${SCRIPT_DIR}/run.sh" --render-latex --repo-dir="${_t_dir}" --results-dir="${_t_dir}/out" --backends='jax_native' >/dev/null
  STACK='' "${SCRIPT_DIR}/run.sh" --render-latex --repo-dir="${_t_dir}" --results-dir="${_t_dir}/out" --backends='jax_native' >/dev/null

  [ -s "${_t_dir}/out/ab_comparison_summary.json" ]
  [ -s "${_t_dir}/out/ab_comparison_summary.csv" ]
  [ -s "${_t_dir}/out/ab_comparison_summary.md" ]
  [ -s "${_t_dir}/out/generated_metrics.tex" ]
  grep -q 'gemmaFourSqlAbJaxNativeDecodeSpeedupX' "${_t_dir}/out/generated_metrics.tex"

  cat <<'COLL_EOF' > "${_t_dir}/out/rs/raw/e0_provenance.json"
{"suite":"E0","libtpu_provider":"rs","stage_a_probes":[{"backend_id":"jax_native","libtpu_mapped_so_sha256":"aaaa1111"}]}
COLL_EOF
  _rc=0
  STACK='' "${SCRIPT_DIR}/run.sh" --render-latex --repo-dir="${_t_dir}" --results-dir="${_t_dir}/out" --backends='jax_native' >/dev/null 2>&1 || _rc=$?
  [ "${_rc}" -eq 65 ]

  rm -rf "${_t_dir}"
}

run_gemma4_libtpu_ab_smoke_test
