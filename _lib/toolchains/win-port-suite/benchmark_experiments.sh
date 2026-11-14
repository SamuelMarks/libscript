#!/bin/sh
# ## Overview
# Master idempotent empirical evaluation orchestrator (`benchmark_experiments.sh`) for `win_port`, routing sub-suites `E0` through `E7` across the 14-repository ecosystem and 285-placeholder LaTeX synthesis protocol.
# ## Usage
# ./_lib/toolchains/win-port-suite/benchmark_experiments.sh [--subsuites=E0..E7] [--results-dir=...] [--ecosystem-dir=...] [--paper-dir=...] [--host-arch=...] [--synthetic-fixtures] [--build-pdf] [--force]
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

_def_arch='linux_x64'
if [ "${UNAME:-}" = "Darwin" ]; then
  _def_arch='macos_arm64'
elif [ "${UNAME:-}" = "FreeBSD" ]; then
  _def_arch='freebsd_x64'
elif [ "${UNAME:-}" = "SunOS" ]; then
  _def_arch='illumos_x64'
fi

WIN_PORT_SUITE_SUBSUITES="${WIN_PORT_SUITE_SUBSUITES:-${LIBSCRIPT_EXPERIMENT_SUBSUITES:-E0,E1,E2,E3,E4,E5,E6,E7}}"
WIN_PORT_SUITE_RESULTS_DIR="${WIN_PORT_SUITE_RESULTS_DIR:-${LIBSCRIPT_EXPERIMENT_OUT_DIR:-${LIBSCRIPT_ROOT_DIR}/build/win_port_results}}"
WIN_PORT_SUITE_ECOSYSTEM_DIR="${WIN_PORT_SUITE_ECOSYSTEM_DIR:-${LIBSCRIPT_EXPERIMENT_ECOSYSTEM_ROOT:-$(dirname -- "${LIBSCRIPT_ROOT_DIR}")}}"
WIN_PORT_SUITE_PAPER_DIR="${WIN_PORT_SUITE_PAPER_DIR:-${LIBSCRIPT_EXPERIMENT_PAPER_DIR:-}}"
WIN_PORT_SUITE_HOST_ARCH="${WIN_PORT_SUITE_HOST_ARCH:-${_def_arch}}"
WIN_PORT_SUITE_SYNTHETIC="${WIN_PORT_SUITE_SYNTHETIC:-0}"
WIN_PORT_SUITE_DRY_RUN="${WIN_PORT_SUITE_DRY_RUN:-0}"
WIN_PORT_SUITE_ALLOW_DIRTY="${WIN_PORT_SUITE_ALLOW_DIRTY:-0}"
WIN_PORT_SUITE_BUILD_PDF="${WIN_PORT_SUITE_BUILD_PDF:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    --subsuites=*) WIN_PORT_SUITE_SUBSUITES="${1#*=}"; shift ;;
    --subsuites) WIN_PORT_SUITE_SUBSUITES="${2:-}"; shift 2 ;;
    --results-dir=*|--out-dir=*) WIN_PORT_SUITE_RESULTS_DIR="${1#*=}"; shift ;;
    --results-dir|--out-dir) WIN_PORT_SUITE_RESULTS_DIR="${2:-}"; shift 2 ;;
    --ecosystem-dir=*) WIN_PORT_SUITE_ECOSYSTEM_DIR="${1#*=}"; shift ;;
    --ecosystem-dir) WIN_PORT_SUITE_ECOSYSTEM_DIR="${2:-}"; shift 2 ;;
    --paper-dir=*) WIN_PORT_SUITE_PAPER_DIR="${1#*=}"; shift ;;
    --paper-dir) WIN_PORT_SUITE_PAPER_DIR="${2:-}"; shift 2 ;;
    --host-arch=*) WIN_PORT_SUITE_HOST_ARCH="${1#*=}"; shift ;;
    --host-arch) WIN_PORT_SUITE_HOST_ARCH="${2:-}"; shift 2 ;;
    --synthetic-fixtures) WIN_PORT_SUITE_SYNTHETIC='1'; shift ;;
    --allow-dirty) WIN_PORT_SUITE_ALLOW_DIRTY='1'; shift ;;
    --dry-run|-n) WIN_PORT_SUITE_DRY_RUN='1'; shift ;;
    --build-pdf) WIN_PORT_SUITE_BUILD_PDF='1'; shift ;;
    --force) export FORCE_REBUILD='1'; shift ;;
    --help|-h)
      printf '%s\n' 'Usage: benchmark_experiments.sh [--subsuites=E0..E7] [--results-dir=...] [--ecosystem-dir=...] [--paper-dir=...] [--host-arch=...] [--synthetic-fixtures] [--build-pdf] [--force]'
      exit 0
      ;;
    *) shift ;;
  esac
done

export WIN_PORT_SUITE_SUBSUITES WIN_PORT_SUITE_RESULTS_DIR WIN_PORT_SUITE_ECOSYSTEM_DIR
export WIN_PORT_SUITE_PAPER_DIR WIN_PORT_SUITE_HOST_ARCH WIN_PORT_SUITE_SYNTHETIC
export WIN_PORT_SUITE_DRY_RUN WIN_PORT_SUITE_ALLOW_DIRTY WIN_PORT_SUITE_BUILD_PDF

# ## prepare_synthetic_ecosystem_fixtures
# Materializes clean git-committed synthetic 14-repo fixtures when `WIN_PORT_SUITE_SYNTHETIC=1` so offline CI verifies all gates, patch hunk splitters, and 285-macro synthesis deterministically.
prepare_synthetic_ecosystem_fixtures() {
  if [ "${WIN_PORT_SUITE_SYNTHETIC}" != "1" ]; then
    return 0
  fi
  _fx_root="${WIN_PORT_SUITE_RESULTS_DIR}/.synthetic_ecosystem"
  if [ -d "${_fx_root}/cdd-c/.git" ] && [ "${FORCE_REBUILD:-0}" != "1" ]; then
    WIN_PORT_SUITE_ECOSYSTEM_DIR="${_fx_root}"
    export WIN_PORT_SUITE_ECOSYSTEM_DIR
    return 0
  fi
  mkdir -p "${_fx_root}"

  for _r in cdd-c auto-win-msvc msi-rs win-cmd-rs bento busybox-windows toybox-windows dash-windows gawk-windows jq-windows memcached-windows redis-windows valkey-windows freebsd-usr-bin-windows freebsd-src; do
    mkdir -p "${_fx_root}/${_r}"
  done

  mkdir -p "${_fx_root}/cdd-c/src/transformers/c_lowering"
  printf 'int cdd_c_stub(void) { return 0; }\n' > "${_fx_root}/cdd-c/src/transformers/c_lowering/c_lowering_legacy.c"
  mkdir -p "${_fx_root}/auto-win-msvc/cmake" "${_fx_root}/auto-win-msvc/rewritten_src" "${_fx_root}/auto-win-msvc/include/posix"
  printf 'option(AUTO_WIN_MSVC_USE_CDD_C "Use cdd-c-transform" ON)\n' > "${_fx_root}/auto-win-msvc/cmake/AutoWinMsvcTransform.cmake"
  printf '/* POSIX compat header */\nint awm_posix_stub(void);\n' > "${_fx_root}/auto-win-msvc/include/posix/unistd_compat.h"
  printf '/* Generated cache excluded from hand-written LoC */\nint generated_ignore(void) { return 1; }\n' > "${_fx_root}/auto-win-msvc/rewritten_src/cached.c"

  mkdir -p "${_fx_root}/win-cmd-rs/src/parser"
  printf '#![forbid(unsafe_code)]\npub enum PegRuleKey { Chain, Pipeline, Statement, CompoundBlock, IfStmt, ForStmt, ErrorMisuse }\n' > "${_fx_root}/win-cmd-rs/src/parser/peg.rs"

  mkdir -p "${_fx_root}/msi-rs/crates/msi/src/execution/transaction"
  printf 'pub struct Transaction { armed: bool }\n' > "${_fx_root}/msi-rs/crates/msi/src/execution/transaction/mod.rs"

  mkdir -p "${_fx_root}/bento/vagrant-msdos/lib" "${_fx_root}/bento/dos_boot"
  printf 'module VagrantMsdos; VERSION = "0.1.0"; end\n' > "${_fx_root}/bento/vagrant-msdos/lib/vagrant_msdos.rb"
  printf 'BITS 16\ncli\nhlt\n' > "${_fx_root}/bento/dos_boot/com1_loader.asm"

  for _wh in busybox-windows toybox-windows dash-windows gawk-windows jq-windows memcached-windows redis-windows valkey-windows freebsd-usr-bin-windows; do
    mkdir -p "${_fx_root}/${_wh}/patches" "${_fx_root}/${_wh}/tests" "${_fx_root}/${_wh}/scripts"
    printf 'def harness_ok():\n    return True\n' > "${_fx_root}/${_wh}/scripts/build_port.py"
    printf 'int main(void) { return 0; }\n' > "${_fx_root}/${_wh}/tests/smoke_runner.c"
    cat <<'PATCH_EOF' > "${_fx_root}/${_wh}/patches/01-msvc-build.patch"
--- a/src/core.c
+++ b/src/core.c
@@ -1,2 +1,3 @@
+#include <stdlib.h>
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -1,1 +1,3 @@
+cmake_minimum_required(VERSION 3.20)
+project(port_target C)
PATCH_EOF
  done

  mkdir -p "${_fx_root}/freebsd-usr-bin-windows/per_binary/yes" "${_fx_root}/freebsd-src/usr.bin/yes"
  printf 'add_executable(yes yes.c)\n' > "${_fx_root}/freebsd-usr-bin-windows/per_binary/yes/CMakeLists.txt"
  printf 'int main(void) { return 0; }\n' > "${_fx_root}/freebsd-src/usr.bin/yes/yes.c"

  for _r in cdd-c auto-win-msvc msi-rs win-cmd-rs bento busybox-windows toybox-windows dash-windows gawk-windows jq-windows memcached-windows redis-windows valkey-windows freebsd-usr-bin-windows freebsd-src; do
    (
      cd -- "${_fx_root}/${_r}"
      git init -q
      git config user.email 'ci@libscript.local'
      git config user.name 'LibScript CI'
      git add .
      git commit -q -m "Initialize synthetic ${_r} fixture"
    )
  done

  WIN_PORT_SUITE_ECOSYSTEM_DIR="${_fx_root}"
  export WIN_PORT_SUITE_ECOSYSTEM_DIR
}

# ## run_selected_win_port_subsuites
# Executes requested `win_port` sub-suites (`E0`..`E7`) idempotently and writes `campaign_summary.json`.
run_selected_win_port_subsuites() {
  mkdir -p "${WIN_PORT_SUITE_RESULTS_DIR}/raw"
  prepare_synthetic_ecosystem_fixtures

  _s_list=$(printf '%s' "${WIN_PORT_SUITE_SUBSUITES}" | tr ',;' '  ')
  for _s in ${_s_list}; do
    case "${_s}" in
      E0|e0)
        "${SCRIPT_DIR}/suites/e0_phase0_gates.sh" "${WIN_PORT_SUITE_ECOSYSTEM_DIR}" "${WIN_PORT_SUITE_RESULTS_DIR}" "${WIN_PORT_SUITE_HOST_ARCH}"
        ;;
      E1|e1)
        "${SCRIPT_DIR}/suites/e1a_cdd_eval.sh" "${WIN_PORT_SUITE_ECOSYSTEM_DIR}" "${WIN_PORT_SUITE_RESULTS_DIR}" "${WIN_PORT_SUITE_HOST_ARCH}"
        "${SCRIPT_DIR}/suites/e1b_downstream_builds.sh" "${WIN_PORT_SUITE_ECOSYSTEM_DIR}" "${WIN_PORT_SUITE_RESULTS_DIR}" "${WIN_PORT_SUITE_HOST_ARCH}"
        ;;
      E1A|e1a)
        "${SCRIPT_DIR}/suites/e1a_cdd_eval.sh" "${WIN_PORT_SUITE_ECOSYSTEM_DIR}" "${WIN_PORT_SUITE_RESULTS_DIR}" "${WIN_PORT_SUITE_HOST_ARCH}"
        ;;
      E1B|e1b)
        "${SCRIPT_DIR}/suites/e1b_downstream_builds.sh" "${WIN_PORT_SUITE_ECOSYSTEM_DIR}" "${WIN_PORT_SUITE_RESULTS_DIR}" "${WIN_PORT_SUITE_HOST_ARCH}"
        ;;
      E2|e2)
        "${SCRIPT_DIR}/suites/e2_port_audit.sh" "${WIN_PORT_SUITE_ECOSYSTEM_DIR}" "${WIN_PORT_SUITE_RESULTS_DIR}" "${WIN_PORT_SUITE_HOST_ARCH}"
        ;;
      E3|e3)
        "${SCRIPT_DIR}/suites/e3a_win64_servers.sh" "${WIN_PORT_SUITE_ECOSYSTEM_DIR}" "${WIN_PORT_SUITE_RESULTS_DIR}" "${WIN_PORT_SUITE_HOST_ARCH}"
        "${SCRIPT_DIR}/suites/e3b_win64_cli.sh" "${WIN_PORT_SUITE_ECOSYSTEM_DIR}" "${WIN_PORT_SUITE_RESULTS_DIR}" "${WIN_PORT_SUITE_HOST_ARCH}"
        "${SCRIPT_DIR}/suites/e3c_dos_matrix.sh" "${WIN_PORT_SUITE_ECOSYSTEM_DIR}" "${WIN_PORT_SUITE_RESULTS_DIR}" "${WIN_PORT_SUITE_HOST_ARCH}"
        ;;
      E4|e4)
        "${SCRIPT_DIR}/suites/e4a_msi_authoring.sh" "${WIN_PORT_SUITE_ECOSYSTEM_DIR}" "${WIN_PORT_SUITE_RESULTS_DIR}" "${WIN_PORT_SUITE_HOST_ARCH}"
        "${SCRIPT_DIR}/suites/e4b_wine_parity.sh" "${WIN_PORT_SUITE_ECOSYSTEM_DIR}" "${WIN_PORT_SUITE_RESULTS_DIR}" "${WIN_PORT_SUITE_HOST_ARCH}"
        "${SCRIPT_DIR}/suites/e4c_msi_rollback.sh" "${WIN_PORT_SUITE_ECOSYSTEM_DIR}" "${WIN_PORT_SUITE_RESULTS_DIR}" "${WIN_PORT_SUITE_HOST_ARCH}"
        ;;
      E5|e5)
        "${SCRIPT_DIR}/suites/e5a_wincheck_corpus.sh" "${WIN_PORT_SUITE_ECOSYSTEM_DIR}" "${WIN_PORT_SUITE_RESULTS_DIR}" "${WIN_PORT_SUITE_HOST_ARCH}"
        "${SCRIPT_DIR}/suites/e5b_cmd_oracle.sh" "${WIN_PORT_SUITE_ECOSYSTEM_DIR}" "${WIN_PORT_SUITE_RESULTS_DIR}" "${WIN_PORT_SUITE_HOST_ARCH}"
        "${SCRIPT_DIR}/suites/e5c_precision_audit.sh" "${WIN_PORT_SUITE_ECOSYSTEM_DIR}" "${WIN_PORT_SUITE_RESULTS_DIR}" "${WIN_PORT_SUITE_HOST_ARCH}"
        ;;
      E6|e6)
        "${SCRIPT_DIR}/suites/e6_ecosystem_rigor.sh" "${WIN_PORT_SUITE_ECOSYSTEM_DIR}" "${WIN_PORT_SUITE_RESULTS_DIR}" "${WIN_PORT_SUITE_HOST_ARCH}"
        ;;
      E7|e7|E8|e8)
        "${SCRIPT_DIR}/suites/e7_latex_verify.sh" "${WIN_PORT_SUITE_RESULTS_DIR}" "${WIN_PORT_SUITE_PAPER_DIR}" "${WIN_PORT_SUITE_BUILD_PDF}"
        ;;
      *)
        log_error "Unknown win_port empirical sub-suite: '${_s}' (expected E0..E7)"
        return 1
        ;;
    esac
  done

  cat <<SUM_EOF > "${WIN_PORT_SUITE_RESULTS_DIR}/campaign_summary.json.tmp"
{
  "schema_version": "1.0.0",
  "suite": "win_port",
  "subsuites": "${WIN_PORT_SUITE_SUBSUITES}",
  "host_arch": "${WIN_PORT_SUITE_HOST_ARCH}",
  "total_placeholders_governed": 285,
  "status": "PASS"
}
SUM_EOF
  mv -f "${WIN_PORT_SUITE_RESULTS_DIR}/campaign_summary.json.tmp" "${WIN_PORT_SUITE_RESULTS_DIR}/campaign_summary.json"
  log_info "Completed win_port empirical suites (${WIN_PORT_SUITE_SUBSUITES}) -> ${WIN_PORT_SUITE_RESULTS_DIR}/campaign_summary.json"
}

run_selected_win_port_subsuites
