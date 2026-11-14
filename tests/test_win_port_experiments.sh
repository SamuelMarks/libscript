#!/bin/sh
# ## Overview
# Integration, `\tbd{???}` placeholder tamper-rejection, dual-manuscript (`win_port_paper.tex` + `win_port_appendix.tex`) PDF audit, and 2x idempotency test suite for `_lib/toolchains/win-port-suite/`.
# ## Usage
# ./tests/test_win_port_experiments.sh
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

TEST_DIR="${TMPDIR:-/tmp}/test_win_port_exp_$$"
rm -rf "${TEST_DIR}"
mkdir -p "${TEST_DIR}/paper"

# ## run_win_port_suite_and_idempotency_tests
# Runs E0-E7 twice (2x idempotency), verifies 285 synthesized macros, verifies \tbd{???} rejection, and tests clean dual-manuscript verification.
run_win_port_suite_and_idempotency_tests() {
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" win-port-suite experiments \
    --synthetic-fixtures \
    --subsuites='E0,E1,E2,E3,E4,E5,E6,E7' \
    --results-dir="${TEST_DIR}/results"

  for _req in \
    metadata.json e0_phase0_gates.json e1_cdd_transform.json e1b_downstream_compile_ctest.json \
    e2_port_audit.json e3a_win64_servers.json e3b_win64_cli.json e3c_dos_matrix.json \
    e4a_msi_authoring.json e4b_wine_warm_Linux_x86_64.json e4b_wine_cold_Linux_x86_64.json \
    e4b_wine_warm_Darwin_arm64.json e4b_wine_cold_Darwin_arm64.json e4c_msi_rollback.json \
    e5a_wincheck_corpus.json e5b_win11_ground_truth.json e5b_cmd_oracle_comparison.json \
    e5c_precision_summary.json e6_ecosystem_rigor.json; do
    [ -s "${TEST_DIR}/results/raw/${_req}" ]
  done
  [ -s "${TEST_DIR}/results/raw/e5c_precision_sample.csv" ]
  [ "$(wc -l < "${TEST_DIR}/results/raw/e5c_precision_sample.csv" | awk '{print $1+0}')" -eq 121 ]
  [ "$(grep -Ec '^\\providecommand\{\\wpMetric' "${TEST_DIR}/results/generated_metrics.tex")" -eq 285 ]

  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" win-port-suite experiments \
    --synthetic-fixtures \
    --subsuites='E0,E1,E2,E3,E4,E5,E6,E7' \
    --results-dir="${TEST_DIR}/results"

  cat <<'BAD_TEX' > "${TEST_DIR}/paper/win_port_paper.tex"
\documentclass{article}
\input{generated_metrics.tex}
\begin{document}
Unresolved empirical value: \tbd{???}
\end{document}
BAD_TEX
  if "${LIBSCRIPT_ROOT_DIR}/libscript.sh" win-port-suite experiments \
    --synthetic-fixtures --subsuites='E7' \
    --results-dir="${TEST_DIR}/results" \
    --paper-dir="${TEST_DIR}/paper" 2>/dev/null; then
    printf '%s\n' '[FAIL] E7 failed to reject unresolved \tbd{???} placeholder!' >&2
    exit 1
  fi

  cat <<'OK_PAPER' > "${TEST_DIR}/paper/win_port_paper.tex"
\documentclass{article}
\input{generated_metrics.tex}
\begin{document}
Verified C89 CST metric: \wpMetricAbsAA{} and total slot \wpMetricAppABentoAB{}.
\end{document}
OK_PAPER
  cat <<'OK_APP' > "${TEST_DIR}/paper/win_port_appendix.tex"
\documentclass{article}
\input{generated_metrics.tex}
\begin{document}
AnonDosVM Vagrant plugin metric: \wpMetricAppABentoAA{} and NASM metric: \wpMetricAppABentoAB{}.
\end{document}
OK_APP

  _pdf_flag=''
  if command -v pdflatex >/dev/null 2>&1; then
    _pdf_flag='--build-pdf'
  fi
  # shellcheck disable=SC2086
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" win-port-suite experiments \
    --synthetic-fixtures --subsuites='E7' \
    --results-dir="${TEST_DIR}/results" \
    --paper-dir="${TEST_DIR}/paper" ${_pdf_flag}
}

run_win_port_suite_and_idempotency_tests
rm -rf "${TEST_DIR}"
printf '%s\n' '[PASS] win_port E0-E7 empirical suites, 285-macro gate, and 2x idempotency tests succeeded!'
