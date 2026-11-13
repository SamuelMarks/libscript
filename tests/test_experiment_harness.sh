#!/bin/sh
# ## Overview
# Unit test suite for `_lib/_common/experiment_harness.sh` verifying SIGPLAN `RULE-1` through `RULE-7` (provenance SHA/dirty-worktree rejection, Rosetta/QEMU ISA guard, cold/warm separation, exact `awk` quantiles/IQR/P99, OS-normalized `ru_maxrss`, pinned Cargo release profiles/stripping, and prerequisite gates).
# ## Usage
# ./tests/test_experiment_harness.sh
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

WORK_DIR="${TMPDIR:-/tmp}/test_exp_harness_$$"
rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}"

# ## test_rule1_provenance_envelope
# Verifies RULE-1 commit SHA provenance capture and rejection of zero-SHA or dirty worktrees.
test_rule1_provenance_envelope() {
  _repo="${WORK_DIR}/clean_repo"
  mkdir -p "${_repo}"
  printf 'hello\n' > "${_repo}/README.md"
  (
    cd -- "${_repo}"
    git init -q
    git config user.email 'test@libscript.local'
    git config user.name 'LibScript Test'
    git add README.md
    git commit -q -m 'initial'
  )
  _hw="${WORK_DIR}/hw.json"
  libscript_emit_hw_manifest_json "${_hw}"
  _prov="${WORK_DIR}/prov_clean.json"
  libscript_exp_capture_provenance "${_repo}" "${_prov}" '--trials=200' "${_hw}"
  libscript_exp_verify_json_provenance "${_prov}" '0'

  # Dirty worktree must be rejected when allow_dirty=0
  printf 'dirty\n' >> "${_repo}/README.md"
  _prov_dirty="${WORK_DIR}/prov_dirty.json"
  libscript_exp_capture_provenance "${_repo}" "${_prov_dirty}" '--trials=200' "${_hw}"
  if libscript_exp_verify_json_provenance "${_prov_dirty}" '0' 2>/dev/null; then
    printf '[FAIL] RULE-1 accepted dirty git worktree!\n' >&2
    exit 1
  fi
  libscript_exp_verify_json_provenance "${_prov_dirty}" '1'

  # Tampered zero SHA must always be rejected
  sed 's/"git_commit_sha": "[^"]*"/"git_commit_sha": "0000000000000000000000000000000000000000"/' "${_prov}" > "${WORK_DIR}/prov_zero.json"
  if libscript_exp_verify_json_provenance "${WORK_DIR}/prov_zero.json" '1' 2>/dev/null; then
    printf '[FAIL] RULE-1 accepted zero placeholder SHA!\n' >&2
    exit 1
  fi
}

# ## test_rule2_native_isa_guard
# Verifies RULE-2 native ISA pass path and simulated Rosetta/QEMU translation rejection.
test_rule2_native_isa_guard() {
  LIBSCRIPT_BENCH_FAKE_TRANSLATED_ISA='0' libscript_exp_assert_native_isa
  if LIBSCRIPT_BENCH_FAKE_TRANSLATED_ISA='1' libscript_exp_assert_native_isa 2>/dev/null; then
    printf '[FAIL] RULE-2 failed to reject simulated binary translation!\n' >&2
    exit 1
  fi
}

# ## test_rule3_and_rule4_trials_and_quantiles
# Verifies RULE-3 cold/warm trial separation (warmups excluded from recorded samples_ns) and RULE-4 exact sorted non-parametric quantiles.
test_rule3_and_rule4_trials_and_quantiles() {
  _probe="${WORK_DIR}/probe.sh"
  _cnt_f="${WORK_DIR}/invocations.txt"
  cat <<EOF > "${_probe}"
#!/bin/sh
printf '1\n' >> '${_cnt_f}'
EOF
  chmod +x "${_probe}"

  libscript_exp_run_cold "${WORK_DIR}/cold.json" "${_probe}"
  grep -q '"cold_latency_ns":' "${WORK_DIR}/cold.json"

  : > "${_cnt_f}"
  libscript_exp_run_warm_loop 3 7 "${WORK_DIR}/warm.samples_ns" "${_probe}"
  _total_inv=$(wc -l < "${_cnt_f}" | awk '{print $1+0}')
  _recorded_n=$(wc -l < "${WORK_DIR}/warm.samples_ns" | awk '{print $1+0}')
  [ "${_total_inv}" -eq 10 ]
  [ "${_recorded_n}" -eq 7 ]

  # Known 11-sample synthetic distribution: 10,20,30,40,50,60,70,80,90,100,1000
  cat <<'EOF' > "${WORK_DIR}/known.samples_ns"
90
10
1000
50
30
70
20
80
40
100
60
EOF
  libscript_exp_compute_stats "${WORK_DIR}/known.samples_ns" "${WORK_DIR}/known_stats.json"
  grep -q '"count": 11,' "${WORK_DIR}/known_stats.json"
  grep -q '"min_ns": 10,' "${WORK_DIR}/known_stats.json"
  grep -q '"p25_ns": 40,' "${WORK_DIR}/known_stats.json"
  grep -q '"median_p50_ns": 60,' "${WORK_DIR}/known_stats.json"
  grep -q '"p75_ns": 90,' "${WORK_DIR}/known_stats.json"
  grep -q '"iqr_ns": 50,' "${WORK_DIR}/known_stats.json"
  grep -q '"p99_ns": 1000,' "${WORK_DIR}/known_stats.json"
  grep -q '"max_ns": 1000,' "${WORK_DIR}/known_stats.json"
  libscript_exp_format_pgfplots_coords 'MLP' "${WORK_DIR}/known_stats.json" | grep -q '(MLP,'
}

# ## test_rule5_rss_normalization
# Verifies RULE-5 Darwin bytes vs. Linux KiB * 1024 normalization to MiB.
test_rule5_rss_normalization() {
  _dar_b=$(libscript_exp_normalize_rss_bytes '1048576' 'Darwin')
  _lin_b=$(libscript_exp_normalize_rss_bytes '1024' 'Linux')
  [ "${_dar_b}" = "1048576" ]
  [ "${_lin_b}" = "1048576" ]
  libscript_exp_emit_rss_json '3072' '1024' "${WORK_DIR}/rss_linux.json" 'Linux'
  grep -q '"baseline_rss_mib": 1.0000' "${WORK_DIR}/rss_linux.json"
  grep -q '"peak_rss_mib": 3.0000' "${WORK_DIR}/rss_linux.json"
  grep -q '"net_rss_delta_mib": 2.0000' "${WORK_DIR}/rss_linux.json"
}

# ## test_rule6_and_rule7_profile_and_prereqs
# Verifies RULE-6 pinned Cargo release profile & library stripping and RULE-7 prerequisite gating.
test_rule6_and_rule7_profile_and_prereqs() {
  libscript_exp_pin_cargo_release 'opt3-lto-thin-cgu1' "${WORK_DIR}/profile.json"
  [ "${CARGO_PROFILE_RELEASE_OPT_LEVEL}" = "3" ]
  [ "${CARGO_PROFILE_RELEASE_LTO}" = "thin" ]
  [ "${CARGO_PROFILE_RELEASE_CODEGEN_UNITS}" = "1" ]
  grep -q '"opt_level": 3' "${WORK_DIR}/profile.json"

  _bad_repo="${WORK_DIR}/bad_repo"
  mkdir -p "${_bad_repo}/scripts" "${_bad_repo}/crates/libtpu-core/src/compiler"
  printf '# stub without compile\n' > "${_bad_repo}/scripts/differential_oracle.py"
  printf 'let d = Dim::Bounded(0);\n' > "${_bad_repo}/crates/libtpu-core/src/compiler/hlo_bridge.rs"
  if libscript_exp_check_prereqs 'E4' "${_bad_repo}" "${WORK_DIR}/prereq_bad.json"; then
    printf '[FAIL] RULE-7 accepted unready E4 repository!\n' >&2
    exit 1
  fi
  printf '# calls PJRT_Compile\n' > "${_bad_repo}/scripts/differential_oracle.py"
  printf 'let d = Dim::Dynamic;\n' > "${_bad_repo}/crates/libtpu-core/src/compiler/hlo_bridge.rs"
  libscript_exp_check_prereqs 'E4' "${_bad_repo}" "${WORK_DIR}/prereq_ok.json"
}

test_rule1_provenance_envelope
test_rule2_native_isa_guard
test_rule3_and_rule4_trials_and_quantiles
test_rule5_rss_normalization
test_rule6_and_rule7_profile_and_prereqs
rm -rf "${WORK_DIR}"
printf '[PASS] All SIGPLAN RULE-1..RULE-7 experiment harness unit tests succeeded!\n'
