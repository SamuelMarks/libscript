#!/bin/sh
# ## Overview
# End-to-end integration and 2x idempotency test suite for `_lib/toolchains/libtpu-rs/benchmark_experiments.sh` covering Suites `E0`–`E8`, C11 `dlopen`/`ru_maxrss` compilation, safe-core `unsafe == 0` enforcement, `\tbd` placeholder rejection, and `FORCE_REBUILD=1` re-execution.
# ## Usage
# ./tests/test_libtpu_experiments.sh
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
export LIBSCRIPT_ROOT_DIR

WORK_DIR="${TMPDIR:-/tmp}/test_libtpu_exp_$$"
rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}/paper_clean" "${WORK_DIR}/paper_tbd"

cat <<'EOF' > "${WORK_DIR}/paper_clean/libtpu_paper.tex"
\documentclass{article}
\input{generated_metrics.tex}
\begin{document}
Warm client init: \MetricWarmClientInitMedMs{} ms.
\end{document}
EOF

cat <<'EOF' > "${WORK_DIR}/paper_tbd/libtpu_paper.tex"
\documentclass{article}
\begin{document}
Unresolved placeholder: \tbd and ???
\end{document}
EOF

# ## test_full_e0_to_e8_and_2x_idempotency
# Runs Suites E0-E8 twice consecutively and verifies atomic JSONs, generated_metrics.tex, and 2x cached idempotency.
test_full_e0_to_e8_and_2x_idempotency() {
  _res="${WORK_DIR}/results"
  # Pass 1
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" libtpu-rs experiments \
    --synthetic-fixtures \
    --subsuites='E0,E1,E2,E3,E4,E5,E6,E7,E8' \
    --warmup=2 \
    --trials=5 \
    --results-dir="${_res}" \
    --paper-dir="${WORK_DIR}/paper_clean"

  for _req in \
    e0_wheel_provenance.json \
    e0_tcb.json \
    e1_abi_parity.json \
    e1_disasm.json \
    e1_carver.json \
    e3_jax_single.json \
    e3_jax_spmd.json \
    e4_vs_google_linux_x64.json \
    e5_vmem_pack.json \
    e5_reg_spill.json \
    e6_modulo_speedup.json \
    e6_pass_ablations.json \
    e7_numerics.json \
    e7_sparsecore.json \
    generated_metrics.tex \
    campaign_summary.json; do
    [ -s "${_res}/${_req}" ]
  done
  grep -q '\\newcommand{\\MetricWarmClientInitMedMs}' "${_res}/generated_metrics.tex"
  grep -q '"safe_core_zero_unsafe_verified": true' "${_res}/e0_tcb.json"

  # Pass 2 (Idempotency check)
  _out2=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" libtpu-rs experiments \
    --synthetic-fixtures \
    --subsuites='E0,E1,E2,E3,E4,E5,E6,E7,E8' \
    --warmup=2 \
    --trials=5 \
    --results-dir="${_res}" \
    --paper-dir="${WORK_DIR}/paper_clean" 2>&1)
  printf '%s\n' "${_out2}" | grep -q 'Cached E0 artifacts already verified'

  # Pass 3 (--force re-execution + live PDF build & log audit when pdflatex is available)
  _pdf_arg=''
  if command -v pdflatex >/dev/null 2>&1; then
    cp -f "${_res}/generated_metrics.tex" "${WORK_DIR}/paper_clean/generated_metrics.tex"
    _pdf_arg='--build-pdf'
  fi
  # shellcheck disable=SC2086
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" libtpu-rs experiments \
    --synthetic-fixtures \
    --force \
    --subsuites='E0,E8' \
    --results-dir="${_res}" \
    --paper-dir="${WORK_DIR}/paper_clean" \
    ${_pdf_arg}
  if [ -n "${_pdf_arg}" ]; then
    [ -s "${WORK_DIR}/paper_clean/libtpu_paper.pdf" ]
  fi
}

# ## test_tbd_placeholder_and_unsafe_gates
# Verifies E8 rejects manuscripts with `\tbd`/`???` and E0.3 rejects safe-core `unsafe` blocks.
test_tbd_placeholder_and_unsafe_gates() {
  if "${LIBSCRIPT_ROOT_DIR}/libscript.sh" libtpu-rs experiments \
    --synthetic-fixtures \
    --subsuites='E8' \
    --results-dir="${WORK_DIR}/results" \
    --paper-dir="${WORK_DIR}/paper_tbd" 2>/dev/null; then
    printf '[FAIL] E8 accepted manuscript containing unresolved \\tbd / ???!\n' >&2
    exit 1
  fi

  _bad_core="${WORK_DIR}/bad_unsafe_repo"
  mkdir -p "${_bad_core}/crates/libtpu-core/src"
  printf 'pub fn bad() { unsafe { core::ptr::null::<u8>(); } }\n' > "${_bad_core}/crates/libtpu-core/src/lib.rs"
  (
    cd -- "${_bad_core}"
    git init -q
    git config user.email 'ci@libscript.local'
    git config user.name 'LibScript CI'
    git add .
    git commit -q -m 'unsafe violation'
  )
  if "${LIBSCRIPT_ROOT_DIR}/libscript.sh" libtpu-rs experiments \
    --synthetic-fixtures \
    --force \
    --subsuites='E0' \
    --repo-dir="${_bad_core}" \
    --results-dir="${WORK_DIR}/bad_results" 2>/dev/null; then
    printf '[FAIL] E0.3 accepted unsafe block inside safe core!\n' >&2
    exit 1
  fi
}

test_full_e0_to_e8_and_2x_idempotency
test_tbd_placeholder_and_unsafe_gates
rm -rf "${WORK_DIR}"
printf '[PASS] libtpu-rs E0-E8 empirical suites, gates, and 2x idempotency tests succeeded!\n'
