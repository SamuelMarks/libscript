#!/bin/sh
# ## Overview
# Comprehensive unit, integration, idempotency, and negative integrity-gate test suite for `edgcpp-backends-suite` (E0-E7) and the hardened v7.0.1 `edg-cc`/`edg-cxx` driver.
# ## Usage
# ./tests/test_edgcpp_backends_experiments.sh
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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/experiment_harness.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

WORK_DIR="${TMPDIR:-/tmp}/test_edgcpp_backends_$$"
rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}"

# ## test_full_e0_to_e7_and_2x_idempotency
# Executes E0-E7 via `./libscript.sh edgcpp-backends-suite experiments --synthetic-fixtures`, verifies all 13 raw JSON files and 60 LaTeX macros, and asserts byte-identical 2x idempotency.
test_full_e0_to_e7_and_2x_idempotency() {
  _res="${WORK_DIR}/run_results"
  _paper="${WORK_DIR}/paper_clean"
  mkdir -p "${_paper}"
  cat <<'TEX_CLEAN' > "${_paper}/edgecpp_backends.tex"
% Clean manuscript fixture with zero unresolved placeholders
\documentclass{article}
\begin{document}
Coverage is \EdgGccBeCovLinePct\% and psABI passed \EdgPsabiFuzzPassedOfThousand/1,000.
\end{document}
TEX_CLEAN

  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" edgcpp-backends-suite experiments --synthetic-fixtures --results-dir="${_res}" --paper-dir="${_paper}"

  for _f in \
    metadata.json \
    exp0_coverage.json \
    exp0_bug4_ablation.json \
    exp1_compile_perf.json \
    exp2_sqlite_runtime.json \
    exp2_ablation.json \
    exp3_eh.json \
    exp4_coro.json \
    exp5_abi_fuzz.json \
    exp5_gcc_torture.json \
    exp5_diff_fuzz.json \
    exp6_projects.json \
    exp6_kernel.json; do
    [ -s "${_res}/raw/${_f}" ]
  done

  [ -s "${_res}/generated_metrics.tex" ]
  _macro_cnt=$(grep -c '^\\newcommand{' "${_res}/generated_metrics.tex")
  [ "${_macro_cnt}" -eq 60 ]
  cp "${_res}/generated_metrics.tex" "${WORK_DIR}/metrics_run1.tex"

  # 2x idempotency run must reuse cached outputs and produce byte-identical generated_metrics.tex
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" edgcpp-backends-suite experiments --synthetic-fixtures --results-dir="${_res}" --paper-dir="${_paper}"
  cmp -s "${WORK_DIR}/metrics_run1.tex" "${_res}/generated_metrics.tex"
}

# ## test_driver_no_gcc_trap_depfile_and_libedg_link
# Verifies `edgcpp_wrapper.sh` passes `--gnu_version=130200` without `--gcc` under `EDG_BACKEND=llvm`, emits `.d` depfiles, caches `--sys_include`, auto-links `libedg.a` under `EDG_BACKEND=gcc` C++, and logs JSONL.
test_driver_no_gcc_trap_depfile_and_libedg_link() {
  "${LIBSCRIPT_ROOT_DIR}/_lib/languages/edgcpp/test.sh"
}

# ## test_negative_integrity_gates
# Verifies hard failure on dirty git worktrees, zero SHAs, `-O0` vs `-O2` opt-parity violations, mismatched LLVM/GCC baselines, non-Linux Kbuild spoofing, and lingering `\tbd`/`???` tokens.
test_negative_integrity_gates() {
  # 1. Dirty git worktree must fail E0
  _dirty_repo="${WORK_DIR}/dirty_edg"
  mkdir -p "${_dirty_repo}"
  (
    cd -- "${_dirty_repo}"
    git init -q
    git config user.email 'ci@libscript.local'
    git config user.name 'LibScript CI'
    printf 'int x = 1;\n' > a.c
    git add a.c
    git commit -q -m 'init'
    printf 'int x = 2;\n' > a.c
  )
  if "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/edgcpp-backends-suite/suites/e0_phase0_gates.sh" "${_dirty_repo}" "${WORK_DIR}/dirty_out" 'macos_arm64' 2>/dev/null; then
    printf '[FAIL] E0 accepted dirty git worktree!\n' >&2
    exit 1
  fi

  # 2. Mismatched -O0 vs -O2 optimization flags must fail libscript_exp_compute_median_stddev
  printf '100\n200\n300\n' > "${WORK_DIR}/s.ns"
  if libscript_exp_compute_median_stddev "${WORK_DIR}/s.ns" "${WORK_DIR}/bad_opt.json" 200 '-O0' '-O2' 2>/dev/null; then
    printf '[FAIL] Opt-parity guard accepted -O0 vs -O2 speedup comparison!\n' >&2
    exit 1
  fi

  # 3. Mismatched LLVM version must fail libscript_exp_assert_matched_baselines
  _mock_clang="${WORK_DIR}/mock_clang_18"
  cat <<'MC_EOF' > "${_mock_clang}"
#!/bin/sh
printf 'clang version 18.1.8\n'
MC_EOF
  chmod +x "${_mock_clang}"
  if EXPECTED_CPFE_LLVM_MAJOR='19' libscript_exp_assert_matched_baselines "${WORK_DIR}/nonexistent_cpfe" "${_mock_clang}" 'cc' '' "${WORK_DIR}/bad_base.json" 2>/dev/null; then
    printf '[FAIL] Baseline alignment guard accepted LLVM 19 vs Clang 18 mismatch!\n' >&2
    exit 1
  fi

  # 4. Non-Linux host must refuse authentic Linux kernel Kbuild sweep when --synthetic-fixtures is off
  if [ "${UNAME:-}" != "Linux" ]; then
    if EDGCPP_BACKENDS_SUITE_SYNTHETIC='0' "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/edgcpp-backends-suite/suites/e6_corpus_and_kernel.sh" "${WORK_DIR}/run_results/.synthetic_edgcpp_repo" "${WORK_DIR}/bad_kbuild" 'macos_arm64' 2>/dev/null; then
      printf '[FAIL] E6 allowed fake Linux kernel Kbuild sweep on non-Linux host!\n' >&2
      exit 1
    fi
  fi

  # 5. Lingering \tbd or ??? placeholder in edgecpp_backends.tex must fail E7
  _bad_paper="${WORK_DIR}/paper_tbd"
  mkdir -p "${_bad_paper}"
  printf '\\documentclass{article}\n\\begin{document}\nLatency is \\tbd s (???).\n\\end{document}\n' > "${_bad_paper}/edgecpp_backends.tex"
  if "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/edgcpp-backends-suite/suites/e7_latex_verify.sh" "${WORK_DIR}/run_results" "${_bad_paper}" '0' 2>/dev/null; then
    printf '[FAIL] E7 accepted unresolved \\tbd / ??? placeholder in edgecpp_backends.tex!\n' >&2
    exit 1
  fi
}

test_full_e0_to_e7_and_2x_idempotency
test_driver_no_gcc_trap_depfile_and_libedg_link
test_negative_integrity_gates
rm -rf "${WORK_DIR}"
printf '[PASS] All edgcpp_backends E0-E7 empirical, idempotency, driver, and negative-gate tests succeeded!\n'
