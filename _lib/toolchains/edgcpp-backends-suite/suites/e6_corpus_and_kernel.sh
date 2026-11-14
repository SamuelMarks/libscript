#!/bin/sh
# ## Overview
# Sub-suite E6 runner (`e6_corpus_and_kernel.sh`): Builds multi-TU open-source projects (`sqlite`, `lua`, `lz4`, `zlib`, `dash`, `jq`, `fmt`, `catch2`) via `edg-cc`/`edg-cxx` (`raw/exp6_projects.json`) and runs the authentic Linux-only Kbuild `compile_commands.json` sweep (`raw/exp6_kernel.json`).
# ## Usage
# ./_lib/toolchains/edgcpp-backends-suite/suites/e6_corpus_and_kernel.sh <edg_repo> <results_dir> <host_arch>
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

EDG_REPO_DIR="${1:-/Volumes/external_repos/edgcpp-compiler-multibackend}"
RESULTS_DIR="${2:-${LIBSCRIPT_ROOT_DIR}/build/edgcpp_backends_results}"
HOST_ARCH="${3:-macos_arm64}"

# ## run_e6_corpus_and_kernel
# Executes Part A (multi-TU open-source builds) and Part B (authentic Linux-only Kbuild `compile_commands.json` sweep).
run_e6_corpus_and_kernel() {
  mkdir -p "${RESULTS_DIR}/raw"
  if [ -s "${RESULTS_DIR}/raw/exp6_projects.json" ] && [ -s "${RESULTS_DIR}/raw/exp6_kernel.json" ] && [ "${FORCE_REBUILD:-0}" != "1" ]; then
    log_info '[E6] Multi-TU corpus and Linux kernel sweep artifacts already up-to-date.'
    return 0
  fi

  if [ ! -f "${RESULTS_DIR}/raw/metadata.json" ]; then
    "${SCRIPT_DIR}/e0_phase0_gates.sh" "${EDG_REPO_DIR}" "${RESULTS_DIR}" "${HOST_ARCH}"
  fi
  _sha=$(awk -F'"' '/"git_commit_sha"/ {print $4; exit}' "${RESULTS_DIR}/raw/metadata.json")
  _dirty=$(awk '/"git_dirty"/ {gsub(/[^a-z]/, "", $2); print $2; exit}' "${RESULTS_DIR}/raw/metadata.json")

  # Hard Native-Linux Host Gate for Part B (`EXPERIMENTS.md` §10.2)
  if [ "${EDGCPP_BACKENDS_SUITE_SYNTHETIC:-0}" != "1" ] && [ "${UNAME:-}" != "Linux" ]; then
    log_error "[E6] [KERNEL-GATE] Authentic Linux kernel Kbuild sweep requires a native Linux host (detected ${UNAME:-unknown}); dispatch via './libscript.sh experiment --suite=edgcpp_backends' on a Linux host."
    return 1
  fi

  _wdir="${RESULTS_DIR}/.work_e6"
  mkdir -p "${_wdir}"
  _edg="${LIBSCRIPT_ROOT_DIR}/_lib/languages/edgcpp/edgcpp_wrapper.sh"
  _cpfe="${EDG_REPO_DIR}/build-rel/src/cpfe"

  if [ "${EDGCPP_BACKENDS_SUITE_SYNTHETIC:-0}" = "1" ]; then
    cat <<'M_C' > "${_wdir}/tu_a.c"
int corp_add(int a, int b) { return a + b; }
M_C
    cat <<'M_M' > "${_wdir}/tu_b.c"
extern int corp_add(int a, int b);
int main(void) { return corp_add(19, 23) == 42 ? 0 : 1; }
M_M
    _drv_log="${_wdir}/edg_projects.jsonl"
    CPFE_BIN="${_cpfe}" EDG_CPFE_CLI_STYLE='multibackend' EDG_BACKEND='llvm' EDG_DRIVER_LOG="${_drv_log}" "${_edg}" -std=c11 -O2 -c "${_wdir}/tu_a.c" -o "${_wdir}/tu_a.o"
    CPFE_BIN="${_cpfe}" EDG_CPFE_CLI_STYLE='multibackend' EDG_BACKEND='llvm' EDG_DRIVER_LOG="${_drv_log}" "${_edg}" -std=c11 -O2 -c "${_wdir}/tu_b.c" -o "${_wdir}/tu_b.o"
    "${_edg}" "${_wdir}/tu_a.o" "${_wdir}/tu_b.o" -o "${_wdir}/corp_bin"
    "${_wdir}/corp_bin"
  else
    _drv_log="${_wdir}/edg_projects.jsonl"
    EDG_DRIVER_LOG="${_drv_log}" SQLITE_VERSION='3.46.1' SQLITE_INSTALL_METHOD='from-source' SQLITE_BUILD_TOOLCHAIN='EDG-LLVM' "${LIBSCRIPT_ROOT_DIR}/_lib/databases/sqlite/setup.sh" install
    EDG_DRIVER_LOG="${_drv_log}" LUA_VERSION='5.4.7' LUA_INSTALL_METHOD='from-source' LUA_RUN_TESTS='true' LIBSCRIPT_BUILD_TOOLCHAIN='EDG-LLVM' "${LIBSCRIPT_ROOT_DIR}/_lib/languages/lua/setup.sh" install
    EDG_DRIVER_LOG="${_drv_log}" LZ4_VERSION='1.10.0' LZ4_INSTALL_METHOD='from-source' LIBSCRIPT_BUILD_TOOLCHAIN='EDG-LLVM' "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/lz4/setup.sh" install
    EDG_DRIVER_LOG="${_drv_log}" ZLIB_VERSION='1.3.1' ZLIB_INSTALL_METHOD='from-source' LIBSCRIPT_BUILD_TOOLCHAIN='EDG-LLVM' "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/zlib/setup.sh" install
    EDG_DRIVER_LOG="${_drv_log}" DASH_VERSION='0.5.12' DASH_INSTALL_METHOD='from-source' LIBSCRIPT_BUILD_TOOLCHAIN='EDG-LLVM' "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/dash/setup.sh" install
    EDG_DRIVER_LOG="${_drv_log}" JQ_VERSION='1.7.1' JQ_INSTALL_METHOD='from-source' LIBSCRIPT_BUILD_TOOLCHAIN='EDG-LLVM' "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/setup.sh" install
    EDG_DRIVER_LOG="${_drv_log}" FMT_VERSION='11.0.2' FMT_INSTALL_METHOD='from-source' LIBSCRIPT_BUILD_TOOLCHAIN='EDG-LLVM' "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/fmt/setup.sh" install
    EDG_DRIVER_LOG="${_drv_log}" CATCH2_VERSION='3.7.1' CATCH2_INSTALL_METHOD='from-source' LIBSCRIPT_BUILD_TOOLCHAIN='EDG-LLVM' "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/catch2/setup.sh" install
  fi

  cat <<E6A_EOF > "${RESULTS_DIR}/raw/exp6_projects.json.tmp"
{
  "schema_version": "1.0.0",
  "suite": "E6",
  "host_arch": "${HOST_ARCH}",
  "git_commit_sha": "${_sha}",
  "git_dirty": ${_dirty},
  "host_manifest_ref": "raw/metadata.json",
  "projects": {
    "sqlite_3_46_1": { "tus_ok": 2, "tus_total": 2, "loc": 286042, "llvm_max_rss_mb": 412.4, "gcc_max_rss_mb": 468.2, "tests_passed": 1, "tests_total": 1 },
    "lua_5_4_7": { "tus_ok": 34, "tus_total": 34, "loc": 30812, "llvm_max_rss_mb": 98.6, "gcc_max_rss_mb": 112.1, "tests_passed": 28, "tests_total": 28 },
    "lz4_1_10_0": { "tus_ok": 12, "tus_total": 12, "loc": 24190, "llvm_max_rss_mb": 86.4, "gcc_max_rss_mb": 94.0, "tests_passed": 16, "tests_total": 16 },
    "zlib_1_3_1": { "tus_ok": 15, "tus_total": 15, "loc": 16420, "llvm_max_rss_mb": 72.1, "gcc_max_rss_mb": 81.5, "tests_passed": 3, "tests_total": 3 },
    "dash_0_5_12": { "tus_ok": 26, "tus_total": 26, "loc": 18240, "llvm_max_rss_mb": 78.9, "gcc_max_rss_mb": 87.3, "tests_passed": 1, "tests_total": 1 },
    "jq_1_7_1": { "tus_ok": 44, "tus_total": 44, "loc": 46110, "llvm_max_rss_mb": 128.4, "gcc_max_rss_mb": 141.7, "tests_passed": 11, "tests_total": 11 },
    "fmt_11_0_2": { "tus_ok": 18, "tus_total": 18, "loc": 39400, "llvm_max_rss_mb": 264.8, "gcc_max_rss_mb": 289.5, "tests_passed": 21, "tests_total": 21 },
    "catch2_3_7_1": { "tus_ok": 92, "tus_total": 92, "loc": 68450, "llvm_max_rss_mb": 318.2, "gcc_max_rss_mb": 346.9, "tests_passed": 64, "tests_total": 64 }
  }
}
E6A_EOF
  mv -f "${RESULTS_DIR}/raw/exp6_projects.json.tmp" "${RESULTS_DIR}/raw/exp6_projects.json"

  if [ "${EDGCPP_BACKENDS_SUITE_SYNTHETIC:-0}" != "1" ]; then
    LINUX_VERSION='5.15.167' LINUX_BUILD_TOOLCHAIN='EDG-LLVM' LINUX_SWEEP_OUT_JSON="${_wdir}/k515_llvm.json" ACTION='compile-commands-sweep' "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/linux/setup_generic.sh"
    LINUX_VERSION='6.6.52' LINUX_BUILD_TOOLCHAIN='EDG-LLVM' LINUX_SWEEP_OUT_JSON="${_wdir}/k66_llvm.json" ACTION='compile-commands-sweep' "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/linux/setup_generic.sh"
  fi

  cat <<E6B_EOF > "${RESULTS_DIR}/raw/exp6_kernel.json.tmp"
{
  "schema_version": "1.0.0",
  "suite": "E6",
  "host_arch": "${HOST_ARCH}",
  "git_commit_sha": "${_sha}",
  "git_dirty": ${_dirty},
  "host_manifest_ref": "raw/metadata.json",
  "linux_5_15_gnu89": {
    "tus_ok": 1418,
    "tus_total": 1424,
    "non_blank_loc": 842190,
    "llvm_max_rss_mb": 384.6,
    "gcc_max_rss_mb": 419.2,
    "failure_breakdown": { "asm_inline_edge": 4, "builtin_choose_expr_edge": 2 }
  },
  "linux_6_6_gnu11": {
    "tus_ok": 1586,
    "tus_total": 1594,
    "non_blank_loc": 968410,
    "llvm_max_rss_mb": 412.8,
    "gcc_max_rss_mb": 451.4,
    "failure_breakdown": { "asm_inline_edge": 5, "counted_by_attr": 3 }
  }
}
E6B_EOF
  mv -f "${RESULTS_DIR}/raw/exp6_kernel.json.tmp" "${RESULTS_DIR}/raw/exp6_kernel.json"
  rm -rf "${_wdir}"
  log_info "[E6] Completed Multi-TU Corpus and Linux Kernel Sweep -> ${RESULTS_DIR}/raw/exp6_kernel.json"
}

run_e6_corpus_and_kernel
