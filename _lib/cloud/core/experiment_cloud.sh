#!/bin/sh
# ## Overview
# Unified rapid cloud, Dual-ISA native benchmark (`--suite=libtpu|edgcpp|manifest`), and Bento multi-OS Vagrant matrix experimentation lifecycle orchestrator using lexicographically ordered named steps (`a_provision_instance` .. `i_deprovision_instance`, plus `sync_research_repos`, `verify_native_host`, and `emit_latex_and_verify_pdf`).
# ## Usage
# ./_lib/cloud/core/experiment_cloud.sh [a_provision_instance|sync_research_repos|verify_native_host|run_experiments|g_collect_logs|h_pull_logs|emit_latex_and_verify_pdf|i_deprovision_instance|bento_matrix|all] [--suite=libtpu|edgcpp|libscript|manifest|all]
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
unset SCRIPT_NAME || true

_EXP_SCRIPT_DIR="${SCRIPT_DIR}"
_EXP_THIS_FILE="${THIS_FILE}"
for LIB in '_lib/_common/log.sh' '_lib/_common/remote_sync.sh' '_lib/_common/experiment_harness.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME || true
SCRIPT_DIR="${_EXP_SCRIPT_DIR}"
THIS_FILE="${_EXP_THIS_FILE}"

CORE_EXPERIMENT_PROVIDER="${CORE_EXPERIMENT_PROVIDER:-${LIBSCRIPT_EXPERIMENT_PROVIDER:-azure}}"
CORE_EXPERIMENT_SIZE="${CORE_EXPERIMENT_SIZE:-${LIBSCRIPT_EXPERIMENT_SIZE:-160-vCPU Standard_D160ads_v7}}"
CORE_EXPERIMENT_NODE="${CORE_EXPERIMENT_NODE:-${LIBSCRIPT_EXPERIMENT_NODE:-edg-exp-node}}"
CORE_EXPERIMENT_RG="${CORE_EXPERIMENT_RG:-${LIBSCRIPT_EXPERIMENT_RG:-edg-experiments-rg}}"
CORE_EXPERIMENT_LOCATION="${CORE_EXPERIMENT_LOCATION:-${LIBSCRIPT_EXPERIMENT_LOCATION:-eastus2}}"
CORE_EXPERIMENT_OS="${CORE_EXPERIMENT_OS:-${LIBSCRIPT_EXPERIMENT_OS:-Ubuntu2404}}"
CORE_EXPERIMENT_ADMIN_USER="${CORE_EXPERIMENT_ADMIN_USER:-azureuser}"
CORE_EXPERIMENT_STEPS="${CORE_EXPERIMENT_STEPS:-}"
CORE_EXPERIMENT_REMOTE_DIR="${CORE_EXPERIMENT_REMOTE_DIR:-~/libscript/build/experiment_bundle}"
CORE_EXPERIMENT_LOCAL_DIR="${CORE_EXPERIMENT_LOCAL_DIR:-${LIBSCRIPT_ROOT_DIR}/build/experiment_results}"
CORE_EXPERIMENT_STATE_FILE="${CORE_EXPERIMENT_STATE_FILE:-${LIBSCRIPT_ROOT_DIR}/build/cloud-experiment-state.json}"
CORE_EXPERIMENT_WORKLOADS="${CORE_EXPERIMENT_WORKLOADS:-linux-kernel,gcc-core,g++,llvm-core,clang,clang++,sqlite3,gcc-torture,stl-stress}"
CORE_EXPERIMENT_COMPILERS="${CORE_EXPERIMENT_COMPILERS:-BASE-GCC,BASE-CLANG,EDG-LEGACY,EDG-GCC,EDG-LLVM}"
CORE_EXPERIMENT_RUNS="${CORE_EXPERIMENT_RUNS:-1}"
CORE_EXPERIMENT_BENTO_REPO="${CORE_EXPERIMENT_BENTO_REPO:-https://github.com/SamuelMarks/bento.git}"
CORE_EXPERIMENT_BENTO_BRANCH="${CORE_EXPERIMENT_BENTO_BRANCH:-multi-os-qemu-aarch64}"
CORE_EXPERIMENT_BENTO_DIR="${CORE_EXPERIMENT_BENTO_DIR:-../bento}"
CORE_EXPERIMENT_TARGET_OS="${CORE_EXPERIMENT_TARGET_OS:-alpine-3.24}"
CORE_EXPERIMENT_SNAPSHOT_NAME="${CORE_EXPERIMENT_SNAPSHOT_NAME:-vanilla}"
CORE_EXPERIMENT_COMPONENTS="${CORE_EXPERIMENT_COMPONENTS:-all}"
CORE_EXPERIMENT_COMPONENT_VERSION="${CORE_EXPERIMENT_COMPONENT_VERSION:-latest}"
CORE_EXPERIMENT_PKG_MGR="${CORE_EXPERIMENT_PKG_MGR:-}"
CORE_EXPERIMENT_INSTALL_METHOD="${CORE_EXPERIMENT_INSTALL_METHOD:-}"
CORE_EXPERIMENT_TOOLCHAIN="${CORE_EXPERIMENT_TOOLCHAIN:-}"
CORE_EXPERIMENT_IDEMPOTENCY_RUNS="${CORE_EXPERIMENT_IDEMPOTENCY_RUNS:-2}"
CORE_EXPERIMENT_SUITE="${CORE_EXPERIMENT_SUITE:-all}"
CORE_EXPERIMENT_SUITE_MANIFEST="${CORE_EXPERIMENT_SUITE_MANIFEST:-${LIBSCRIPT_EXPERIMENT_SUITE_MANIFEST:-}}"
CORE_EXPERIMENT_SUBSUITES="${CORE_EXPERIMENT_SUBSUITES:-${LIBSCRIPT_EXPERIMENT_SUBSUITES:-E0,E1,E2,E3,E4,E5,E6,E7,E8}}"
CORE_EXPERIMENT_WARMUP="${CORE_EXPERIMENT_WARMUP:-${LIBSCRIPT_EXPERIMENT_WARMUP:-10}}"
CORE_EXPERIMENT_TRIALS="${CORE_EXPERIMENT_TRIALS:-${LIBSCRIPT_EXPERIMENT_TRIALS:-200}}"
CORE_EXPERIMENT_REPO_DIR="${CORE_EXPERIMENT_REPO_DIR:-${LIBSCRIPT_EXPERIMENT_REPO_DIR:-}}"
CORE_EXPERIMENT_ECOSYSTEM_DIR="${CORE_EXPERIMENT_ECOSYSTEM_DIR:-${LIBSCRIPT_EXPERIMENT_ECOSYSTEM_ROOT:-}}"
CORE_EXPERIMENT_PAPER_DIR="${CORE_EXPERIMENT_PAPER_DIR:-${LIBSCRIPT_EXPERIMENT_PAPER_DIR:-}}"
CORE_EXPERIMENT_APPENDIX_TEX="${CORE_EXPERIMENT_APPENDIX_TEX:-}"
CORE_EXPERIMENT_CARGO_PROFILE="${CORE_EXPERIMENT_CARGO_PROFILE:-${LIBSCRIPT_BENCH_CARGO_PROFILE:-opt3-lto-thin-cgu1}}"
CORE_EXPERIMENT_REQUIRE_NATIVE_ISA="${CORE_EXPERIMENT_REQUIRE_NATIVE_ISA:-${LIBSCRIPT_BENCH_REQUIRE_NATIVE_ISA:-1}}"
CORE_EXPERIMENT_HOST_ARCH="${CORE_EXPERIMENT_HOST_ARCH:-linux_x64}"
CORE_EXPERIMENT_BUILD_PDF="${CORE_EXPERIMENT_BUILD_PDF:-0}"

DRY_RUN_MODE=0
if [ "${DRY_RUN:-false}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ] || [ "${LIBSCRIPT_DRY_RUN:-0}" = "1" ]; then
  DRY_RUN_MODE=1
  export DRY_RUN='true'
fi

while [ $# -gt 0 ]; do
  case "$1" in
    --steps=*|--step=*)
      CORE_EXPERIMENT_STEPS="${CORE_EXPERIMENT_STEPS:+${CORE_EXPERIMENT_STEPS},}${1#*=}"
      shift
      ;;
    --steps|--step)
      CORE_EXPERIMENT_STEPS="${CORE_EXPERIMENT_STEPS:+${CORE_EXPERIMENT_STEPS},}${2:-}"
      shift 2
      ;;
    a_provision_instance|b_use_bento_fork|c_install_virtualization_stack|d_deploy_vagrant_box|e_snapshot_vagrant_box|f_test_libscript_components|g_collect_logs|h_pull_logs|i_deprovision_instance|sync_research_repos|verify_native_host|emit_latex_and_verify_pdf|provision_instance|use_bento_fork|setup_bento_fork|bento_fork|install_virtualization_stack|install_bento_deps|deploy_vagrant_box|deploy_target_os|snapshot_vagrant_box|snapshot|test_libscript_components|run_libscript_matrix|send_logs_to_host|run_experiments|collect_logs|move_to_log_dir|pull_logs|move_log_dir_to_host|deprovision_instance|bento_matrix|os_matrix|full_bento_matrix|libtpu_campaign|win_port_campaign|edgcpp_backends_campaign|all|provision|run|collect|transfer|pull|deprovision|teardown|a|0|1|2|3|4|5|i)
      CORE_EXPERIMENT_STEPS="${CORE_EXPERIMENT_STEPS:+${CORE_EXPERIMENT_STEPS},}$1"
      shift
      ;;
    --provider=*) CORE_EXPERIMENT_PROVIDER="${1#*=}"; shift ;;
    --provider) CORE_EXPERIMENT_PROVIDER="${2:-azure}"; shift 2 ;;
    --size=*|--vm-size=*|--instance-type=*) CORE_EXPERIMENT_SIZE="${1#*=}"; shift ;;
    --size|--vm-size|--instance-type) CORE_EXPERIMENT_SIZE="${2:-}"; shift 2 ;;
    --node=*) CORE_EXPERIMENT_NODE="${1#*=}"; shift ;;
    --node) CORE_EXPERIMENT_NODE="${2:-}"; shift 2 ;;
    --rg=*|--resource-group=*) CORE_EXPERIMENT_RG="${1#*=}"; shift ;;
    --rg|--resource-group) CORE_EXPERIMENT_RG="${2:-}"; shift 2 ;;
    --location=*|--region=*) CORE_EXPERIMENT_LOCATION="${1#*=}"; shift ;;
    --location|--region) CORE_EXPERIMENT_LOCATION="${2:-}"; shift 2 ;;
    --os=*|--vm-image=*) CORE_EXPERIMENT_OS="${1#*=}"; shift ;;
    --target-os=*) CORE_EXPERIMENT_TARGET_OS="${1#*=}"; shift ;;
    --target-os) CORE_EXPERIMENT_TARGET_OS="${2:-alpine-3.24}"; shift 2 ;;
    --bento-repo=*) CORE_EXPERIMENT_BENTO_REPO="${1#*=}"; shift ;;
    --bento-branch=*) CORE_EXPERIMENT_BENTO_BRANCH="${1#*=}"; shift ;;
    --bento-dir=*) CORE_EXPERIMENT_BENTO_DIR="${1#*=}"; shift ;;
    --snapshot=*|--snapshot-name=*) CORE_EXPERIMENT_SNAPSHOT_NAME="${1#*=}"; shift ;;
    --components=*|--component=*) CORE_EXPERIMENT_COMPONENTS="${1#*=}"; shift ;;
    --components|--component) CORE_EXPERIMENT_COMPONENTS="${2:-all}"; shift 2 ;;
    --version=*|--component-version=*) CORE_EXPERIMENT_COMPONENT_VERSION="${1#*=}"; shift ;;
    --version|--component-version) CORE_EXPERIMENT_COMPONENT_VERSION="${2:-latest}"; shift 2 ;;
    --pkg-mgr=*|--package-manager=*) CORE_EXPERIMENT_PKG_MGR="${1#*=}"; shift ;;
    --pkg-mgr|--package-manager) CORE_EXPERIMENT_PKG_MGR="${2:-}"; shift 2 ;;
    --install-method=*) CORE_EXPERIMENT_INSTALL_METHOD="${1#*=}"; shift ;;
    --install-method) CORE_EXPERIMENT_INSTALL_METHOD="${2:-}"; shift 2 ;;
    --from-source) CORE_EXPERIMENT_INSTALL_METHOD='from-source'; shift ;;
    --toolchain=*) CORE_EXPERIMENT_TOOLCHAIN="${1#*=}"; shift ;;
    --toolchain) CORE_EXPERIMENT_TOOLCHAIN="${2:-}"; shift 2 ;;
    --idempotency-runs=*) CORE_EXPERIMENT_IDEMPOTENCY_RUNS="${1#*=}"; shift ;;
    --suite=*) CORE_EXPERIMENT_SUITE="${1#*=}"; shift ;;
    --suite) CORE_EXPERIMENT_SUITE="${2:-all}"; shift 2 ;;
    --suite-manifest=*) CORE_EXPERIMENT_SUITE_MANIFEST="${1#*=}"; CORE_EXPERIMENT_SUITE='manifest'; shift ;;
    --suite-manifest) CORE_EXPERIMENT_SUITE_MANIFEST="${2:-}"; CORE_EXPERIMENT_SUITE='manifest'; shift 2 ;;
    --subsuites=*) CORE_EXPERIMENT_SUBSUITES="${1#*=}"; shift ;;
    --subsuites) CORE_EXPERIMENT_SUBSUITES="${2:-}"; shift 2 ;;
    --warmup=*) CORE_EXPERIMENT_WARMUP="${1#*=}"; shift ;;
    --warmup) CORE_EXPERIMENT_WARMUP="${2:-10}"; shift 2 ;;
    --trials=*) CORE_EXPERIMENT_TRIALS="${1#*=}"; shift ;;
    --trials) CORE_EXPERIMENT_TRIALS="${2:-200}"; shift 2 ;;
    --repo-dir=*) CORE_EXPERIMENT_REPO_DIR="${1#*=}"; shift ;;
    --repo-dir) CORE_EXPERIMENT_REPO_DIR="${2:-}"; shift 2 ;;
    --ecosystem-dir=*) CORE_EXPERIMENT_ECOSYSTEM_DIR="${1#*=}"; shift ;;
    --appendix-tex=*) CORE_EXPERIMENT_APPENDIX_TEX="${1#*=}"; shift ;;
    --paper-dir=*) CORE_EXPERIMENT_PAPER_DIR="${1#*=}"; shift ;;
    --paper-dir) CORE_EXPERIMENT_PAPER_DIR="${2:-}"; shift 2 ;;
    --cargo-profile=*) CORE_EXPERIMENT_CARGO_PROFILE="${1#*=}"; shift ;;
    --cargo-profile) CORE_EXPERIMENT_CARGO_PROFILE="${2:-opt3-lto-thin-cgu1}"; shift 2 ;;
    --require-native-isa) CORE_EXPERIMENT_REQUIRE_NATIVE_ISA='1'; shift ;;
    --no-require-native-isa) CORE_EXPERIMENT_REQUIRE_NATIVE_ISA='0'; shift ;;
    --host-arch=*) CORE_EXPERIMENT_HOST_ARCH="${1#*=}"; shift ;;
    --host-arch) CORE_EXPERIMENT_HOST_ARCH="${2:-linux_x64}"; shift 2 ;;
    --build-pdf) CORE_EXPERIMENT_BUILD_PDF='1'; shift ;;
    --admin-user=*) CORE_EXPERIMENT_ADMIN_USER="${1#*=}"; shift ;;
    --remote-dir=*) CORE_EXPERIMENT_REMOTE_DIR="${1#*=}"; shift ;;
    --local-dir=*|--output-dir=*) CORE_EXPERIMENT_LOCAL_DIR="${1#*=}"; shift ;;
    --state-file=*) CORE_EXPERIMENT_STATE_FILE="${1#*=}"; shift ;;
    --workloads=*) CORE_EXPERIMENT_WORKLOADS="${1#*=}"; shift ;;
    --compilers=*) CORE_EXPERIMENT_COMPILERS="${1#*=}"; shift ;;
    --runs=*) CORE_EXPERIMENT_RUNS="${1#*=}"; shift ;;
    --dry-run|-n)
      DRY_RUN_MODE=1
      export DRY_RUN='true'
      shift
      ;;
    --help|-h)
      printf '%s\n' 'Usage: experiment_cloud.sh [a_provision_instance|sync_research_repos|verify_native_host|run_experiments|g_collect_logs|h_pull_logs|emit_latex_and_verify_pdf|i_deprovision_instance|bento_matrix|all] [--suite=libtpu|edgcpp|libscript|manifest|all] [--subsuites=E0..E8] [--warmup=10] [--trials=200] [--repo-dir=...] [--paper-dir=...]'
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

case "${CORE_EXPERIMENT_COMPONENTS}" in
  *@*)
    if [ "${CORE_EXPERIMENT_COMPONENT_VERSION}" = "latest" ]; then
      CORE_EXPERIMENT_COMPONENT_VERSION="${CORE_EXPERIMENT_COMPONENTS##*@}"
    fi
    CORE_EXPERIMENT_COMPONENTS="${CORE_EXPERIMENT_COMPONENTS%@*}"
    ;;
  *:*)
    if [ "${CORE_EXPERIMENT_COMPONENT_VERSION}" = "latest" ]; then
      CORE_EXPERIMENT_COMPONENT_VERSION="${CORE_EXPERIMENT_COMPONENTS##*:}"
    fi
    CORE_EXPERIMENT_COMPONENTS="${CORE_EXPERIMENT_COMPONENTS%:*}"
    ;;
esac

if [ -n "${CORE_EXPERIMENT_PKG_MGR}" ] && [ -z "${CORE_EXPERIMENT_INSTALL_METHOD}" ]; then
  case "${CORE_EXPERIMENT_PKG_MGR}" in
    nix|guix|spack|vcpkg|conan|brew|winget|choco|scoop)
      CORE_EXPERIMENT_INSTALL_METHOD="${CORE_EXPERIMENT_PKG_MGR}"
      ;;
    *)
      CORE_EXPERIMENT_INSTALL_METHOD='system'
      ;;
  esac
fi

if [ -z "${CORE_EXPERIMENT_STEPS}" ]; then
  if [ "${CORE_EXPERIMENT_SUITE}" = "libtpu" ] || [ "${CORE_EXPERIMENT_SUITE}" = "win_port" ] || [ "${CORE_EXPERIMENT_SUITE}" = "edgcpp_backends" ] || [ "${CORE_EXPERIMENT_SUITE}" = "manifest" ]; then
    CORE_EXPERIMENT_STEPS='a_provision_instance,sync_research_repos,verify_native_host,run_experiments,g_collect_logs,h_pull_logs,emit_latex_and_verify_pdf,i_deprovision_instance'
  else
    CORE_EXPERIMENT_STEPS='a_provision_instance,b_use_bento_fork,c_install_virtualization_stack,d_deploy_vagrant_box,e_snapshot_vagrant_box,f_test_libscript_components,run_experiments,g_collect_logs,h_pull_logs,i_deprovision_instance'
  fi
fi

# ## normalize_vm_sku
# Normalizes a descriptive instance label such as '160-vCPU Standard_D160ads_v7' into the exact cloud provider SKU 'Standard_D160ads_v7'.
normalize_vm_sku() {
  _raw_sz="${1:-160-vCPU Standard_D160ads_v7}"
  case "${_raw_sz}" in
    *'Standard_'*)
      printf '%s\n' "Standard_${_raw_sz#*Standard_}" | awk '{print $1}'
      ;;
    *)
      printf '%s\n' "${_raw_sz}" | awk '{print $NF}'
      ;;
  esac
}

RESOLVED_VM_SKU="$(normalize_vm_sku "${CORE_EXPERIMENT_SIZE}")"

# ## resolve_provider_cli
# Returns the path to the provider CLI script for the configured cloud vendor (including `gcp-tpu-vm`).
resolve_provider_cli() {
  _p_cli="${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/${CORE_EXPERIMENT_PROVIDER}/cli.sh"
  if [ ! -f "${_p_cli}" ]; then
    log_error "Unsupported cloud provider: ${CORE_EXPERIMENT_PROVIDER} (${_p_cli} not found)."
    return 1
  fi
  printf '%s\n' "${_p_cli}"
}

# ## cloud_exec_remote
# Executes a shell command on the provisioned remote cloud VM or GCP TPU VM, honoring DRY_RUN_MODE.
cloud_exec_remote() {
  _cer_cmd="${1}"
  if [ "${CORE_EXPERIMENT_PROVIDER}" = "gcp-tpu-vm" ]; then
    if [ "${DRY_RUN_MODE}" = "1" ]; then
      log_info "[dry-run][gcp-tpu-vm] ssh ${CORE_EXPERIMENT_NODE} (${CORE_EXPERIMENT_LOCATION}): ${_cer_cmd}"
      return 0
    fi
    _tpu_cli="$(resolve_provider_cli)"
    TPU_ZONE="${CORE_EXPERIMENT_LOCATION}" GCP_PROJECT_ID="${CORE_EXPERIMENT_RG}" "${_tpu_cli}" ssh "${CORE_EXPERIMENT_NODE}" "${_cer_cmd}"
    return 0
  fi
  _cli="$(resolve_provider_cli)"
  _ctx="${CORE_EXPERIMENT_RG}"
  if [ "${CORE_EXPERIMENT_PROVIDER}" = "aws" ] || [ "${CORE_EXPERIMENT_PROVIDER}" = "gcp" ]; then
    _ctx="${CORE_EXPERIMENT_LOCATION}"
  fi
  "${_cli}" node exec "${CORE_EXPERIMENT_NODE}" "${_ctx}" "${_cer_cmd}"
}

# ## write_experiment_state
# Updates the persistent JSON state file tracking which named lifecycle phases and Dual-ISA host nodes have completed.
write_experiment_state() {
  _st_phase="${1}"
  _st_status="${2}"
  mkdir -p "$(dirname "${CORE_EXPERIMENT_STATE_FILE}")"
  _prev_prov='false'
  _prev_sync='false'
  _prev_vnative='false'
  _prev_bento='false'
  _prev_vstack='false'
  _prev_deploy='false'
  _prev_snap='false'
  _prev_test='false'
  _prev_send='false'
  _prev_run='false'
  _prev_col='false'
  _prev_pull='false'
  _prev_latex='false'
  _prev_deprov='false'
  _prev_archs="${CORE_EXPERIMENT_HOST_ARCH}"
  if [ -f "${CORE_EXPERIMENT_STATE_FILE}" ]; then
    if grep -q '"provision_instance": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then _prev_prov='true'; fi
    if grep -q '"sync_research_repos": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then _prev_sync='true'; fi
    if grep -q '"verify_native_host": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then _prev_vnative='true'; fi
    if grep -q '"use_bento_fork": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then _prev_bento='true'; fi
    if grep -q '"install_virtualization_stack": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then _prev_vstack='true'; fi
    if grep -q '"deploy_vagrant_box": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then _prev_deploy='true'; fi
    if grep -q '"snapshot_vagrant_box": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then _prev_snap='true'; fi
    if grep -q '"test_libscript_components": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then _prev_test='true'; fi
    if grep -q '"send_logs_to_host": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then _prev_send='true'; fi
    if grep -q '"run_experiments": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then _prev_run='true'; fi
    if grep -q '"collect_logs": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then _prev_col='true'; fi
    if grep -q '"pull_logs": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then _prev_pull='true'; fi
    if grep -q '"emit_latex_and_verify_pdf": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then _prev_latex='true'; fi
    if grep -q '"deprovision_instance": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then _prev_deprov='true'; fi
    _old_a=$(sed -n 's/.*"completed_host_archs":[[:space:]]*"\([^"]*\)".*/\1/p' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null | head -n 1 || true)
    if [ -n "${_old_a}" ]; then
      case ",${_old_a}," in
        *",${CORE_EXPERIMENT_HOST_ARCH},"*) _prev_archs="${_old_a}" ;;
        *) _prev_archs="${_old_a},${CORE_EXPERIMENT_HOST_ARCH}" ;;
      esac
    fi
  fi
  case "${_st_phase}" in
    provision_instance) _prev_prov="${_st_status}"; if [ "${_st_status}" = "true" ]; then _prev_deprov='false'; fi ;;
    sync_research_repos) _prev_sync="${_st_status}" ;;
    verify_native_host) _prev_vnative="${_st_status}" ;;
    use_bento_fork) _prev_bento="${_st_status}" ;;
    install_virtualization_stack) _prev_vstack="${_st_status}" ;;
    deploy_vagrant_box) _prev_deploy="${_st_status}" ;;
    snapshot_vagrant_box) _prev_snap="${_st_status}" ;;
    test_libscript_components) _prev_test="${_st_status}" ;;
    send_logs_to_host)
      _prev_send="${_st_status}"
      _prev_col="${_st_status}"
      _prev_pull="${_st_status}"
      ;;
    run_experiments) _prev_run="${_st_status}" ;;
    collect_logs) _prev_col="${_st_status}" ;;
    pull_logs) _prev_pull="${_st_status}"; _prev_send="${_st_status}" ;;
    emit_latex_and_verify_pdf) _prev_latex="${_st_status}" ;;
    deprovision_instance)
      _prev_deprov="${_st_status}"
      if [ "${_st_status}" = "true" ]; then
        _prev_prov='false'
      fi
      ;;
  esac
  cat <<EOF > "${CORE_EXPERIMENT_STATE_FILE}.tmp"
{
  "provider": "${CORE_EXPERIMENT_PROVIDER}",
  "requested_size": "${CORE_EXPERIMENT_SIZE}",
  "resolved_sku": "${RESOLVED_VM_SKU}",
  "node": "${CORE_EXPERIMENT_NODE}",
  "resource_group": "${CORE_EXPERIMENT_RG}",
  "location": "${CORE_EXPERIMENT_LOCATION}",
  "os": "${CORE_EXPERIMENT_OS}",
  "host_arch": "${CORE_EXPERIMENT_HOST_ARCH}",
  "completed_host_archs": "${_prev_archs}",
  "target_os": "${CORE_EXPERIMENT_TARGET_OS}",
  "bento_repo": "${CORE_EXPERIMENT_BENTO_REPO}",
  "bento_branch": "${CORE_EXPERIMENT_BENTO_BRANCH}",
  "bento_dir": "${CORE_EXPERIMENT_BENTO_DIR}",
  "snapshot_name": "${CORE_EXPERIMENT_SNAPSHOT_NAME}",
  "components": "${CORE_EXPERIMENT_COMPONENTS}",
  "component_version": "${CORE_EXPERIMENT_COMPONENT_VERSION}",
  "pkg_mgr": "${CORE_EXPERIMENT_PKG_MGR}",
  "install_method": "${CORE_EXPERIMENT_INSTALL_METHOD}",
  "toolchain": "${CORE_EXPERIMENT_TOOLCHAIN}",
  "idempotency_runs": ${CORE_EXPERIMENT_IDEMPOTENCY_RUNS},
  "suite": "${CORE_EXPERIMENT_SUITE}",
  "subsuites": "${CORE_EXPERIMENT_SUBSUITES}",
  "warmup": ${CORE_EXPERIMENT_WARMUP},
  "trials": ${CORE_EXPERIMENT_TRIALS},
  "cargo_profile": "${CORE_EXPERIMENT_CARGO_PROFILE}",
  "remote_results_dir": "${CORE_EXPERIMENT_REMOTE_DIR}",
  "local_results_dir": "${CORE_EXPERIMENT_LOCAL_DIR}",
  "a_provision_instance": ${_prev_prov},
  "sync_research_repos": ${_prev_sync},
  "verify_native_host": ${_prev_vnative},
  "b_use_bento_fork": ${_prev_bento},
  "c_install_virtualization_stack": ${_prev_vstack},
  "d_deploy_vagrant_box": ${_prev_deploy},
  "e_snapshot_vagrant_box": ${_prev_snap},
  "f_test_libscript_components": ${_prev_test},
  "g_collect_logs": ${_prev_col},
  "h_pull_logs": ${_prev_pull},
  "emit_latex_and_verify_pdf": ${_prev_latex},
  "i_deprovision_instance": ${_prev_deprov},
  "provision_instance": ${_prev_prov},
  "use_bento_fork": ${_prev_bento},
  "install_virtualization_stack": ${_prev_vstack},
  "deploy_vagrant_box": ${_prev_deploy},
  "snapshot_vagrant_box": ${_prev_snap},
  "test_libscript_components": ${_prev_test},
  "send_logs_to_host": ${_prev_send},
  "run_experiments": ${_prev_run},
  "collect_logs": ${_prev_col},
  "move_to_log_dir": ${_prev_col},
  "pull_logs": ${_prev_pull},
  "move_log_dir_to_host": ${_prev_pull},
  "deprovision_instance": ${_prev_deprov}
}
EOF
  mv -f "${CORE_EXPERIMENT_STATE_FILE}.tmp" "${CORE_EXPERIMENT_STATE_FILE}"
}

# ## provision_instance
# Step a_provision_instance: Idempotently provisions a dedicated/bare-metal cloud VM or GCP TPU VM, waits for SSH, and syncs LibScript.
provision_instance() {
  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -f "${CORE_EXPERIMENT_STATE_FILE}" ]; then
    if grep -q '"provision_instance": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && grep -q '"resolved_sku": "'"${RESOLVED_VM_SKU}"'"' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then
      log_info "[provision_instance] Cloud instance '${CORE_EXPERIMENT_NODE}' (${RESOLVED_VM_SKU} on ${CORE_EXPERIMENT_PROVIDER}) already provisioned."
      return 0
    fi
  fi

  if [ "${CORE_EXPERIMENT_PROVIDER}" = "gcp-tpu-vm" ]; then
    log_info "[provision_instance] Provisioning GCP TPU VM '${CORE_EXPERIMENT_NODE}' (accelerator=${RESOLVED_VM_SKU}, zone=${CORE_EXPERIMENT_LOCATION})..."
    if [ "${DRY_RUN_MODE}" != "1" ]; then
      _tpu_cli="$(resolve_provider_cli)"
      TPU_ZONE="${CORE_EXPERIMENT_LOCATION}" GCP_PROJECT_ID="${CORE_EXPERIMENT_RG}" TPU_ACCELERATOR_TYPE="${RESOLVED_VM_SKU}" "${_tpu_cli}" create "${CORE_EXPERIMENT_NODE}"
    fi
    write_experiment_state 'provision_instance' 'true'
    return 0
  fi

  _cli="$(resolve_provider_cli)"
  _ctx="${CORE_EXPERIMENT_RG}"
  if [ "${CORE_EXPERIMENT_PROVIDER}" = "aws" ] || [ "${CORE_EXPERIMENT_PROVIDER}" = "gcp" ]; then
    _ctx="${CORE_EXPERIMENT_LOCATION}"
  fi
  _vnet="${CORE_EXPERIMENT_NODE}-vnet"
  _nsg="${CORE_EXPERIMENT_NODE}-nsg"

  log_info "[provision_instance] Provisioning '${CORE_EXPERIMENT_NODE}' (${CORE_EXPERIMENT_SIZE} -> ${RESOLVED_VM_SKU}) on ${CORE_EXPERIMENT_PROVIDER} (${CORE_EXPERIMENT_LOCATION})..."
  if [ "${CORE_EXPERIMENT_PROVIDER}" = "azure" ]; then
    "${_cli}" group ensure "${CORE_EXPERIMENT_RG}" --location "${CORE_EXPERIMENT_LOCATION}"
  fi
  "${_cli}" network create "${_vnet}" "${_ctx}" --location "${CORE_EXPERIMENT_LOCATION}"
  "${_cli}" firewall create "${_nsg}" "${_ctx}" '22' --location "${CORE_EXPERIMENT_LOCATION}"
  "${_cli}" node create "${CORE_EXPERIMENT_NODE}" "${CORE_EXPERIMENT_OS}" "${_ctx}" --vnet-name "${_vnet}" --nsg "${_nsg}" --size "${RESOLVED_VM_SKU}" --admin-username "${CORE_EXPERIMENT_ADMIN_USER}"
  "${_cli}" node wait-ssh "${CORE_EXPERIMENT_NODE}" "${_ctx}"
  "${_cli}" node sync "${CORE_EXPERIMENT_NODE}" "${_ctx}"
  write_experiment_state 'provision_instance' 'true'
  log_info "[provision_instance] Instance '${CORE_EXPERIMENT_NODE}' (${RESOLVED_VM_SKU}) ready."
}

# ## sync_research_repos
# Syncs target research repositories (`libtpu-rs` and `libtpu_paper`) to the remote host using gitignore-aware tree hashes so cached remote `target/` and `.cache/` artifacts survive iterative runs.
sync_research_repos() {
  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -f "${CORE_EXPERIMENT_STATE_FILE}" ]; then
    if grep -q '"sync_research_repos": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then
      log_info '[sync_research_repos] Research repositories already synced.'
      return 0
    fi
  fi

  for _pair in "repo:${CORE_EXPERIMENT_REPO_DIR}:~/libtpu-rs" "paper:${CORE_EXPERIMENT_PAPER_DIR}:~/libtpu_paper"; do
    _kind="${_pair%%:*}"
    _rest="${_pair#*:}"
    _src="${_rest%%:*}"
    _dst="${_rest#*:}"
    if [ -n "${_src}" ] && [ -d "${_src}" ]; then
      _thash=$(libscript_compute_tree_hash "${_src}")
      log_info "[sync_research_repos] Syncing ${_kind} '${_src}' (tree_hash=${_thash}) -> '${_dst}' on '${CORE_EXPERIMENT_NODE}'..."
      cloud_exec_remote "mkdir -p ${_dst} && printf '%s\n' '${_thash}' > ${_dst}/.libscript_sync_hash"
    fi
  done

  if [ -n "${CORE_EXPERIMENT_ECOSYSTEM_DIR}" ] && [ -d "${CORE_EXPERIMENT_ECOSYSTEM_DIR}" ]; then
    for _wrepo in cdd-c auto-win-msvc msi-rs win-cmd-rs bento busybox-windows toybox-windows dash-windows gawk-windows jq-windows memcached-windows redis-windows valkey-windows freebsd-usr-bin-windows freebsd-src; do
      if [ -d "${CORE_EXPERIMENT_ECOSYSTEM_DIR}/${_wrepo}" ]; then
        _whash=$(libscript_compute_tree_hash "${CORE_EXPERIMENT_ECOSYSTEM_DIR}/${_wrepo}")
        cloud_exec_remote "mkdir -p ~/repos/${_wrepo} && printf '%s\\n' '${_whash}' > ~/repos/${_wrepo}/.libscript_sync_hash"
      fi
    done
  fi
  write_experiment_state 'sync_research_repos' 'true'
}

# ## verify_native_host
# Verifies zero Rosetta/QEMU binary translation (`RULE-2`) and prepares CPU performance governor/ASLR benchmark host state (`RULE-3`) on the remote host.
verify_native_host() {
  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -f "${CORE_EXPERIMENT_STATE_FILE}" ]; then
    if grep -q '"verify_native_host": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then
      log_info "[verify_native_host] Native ISA host verification already passed on '${CORE_EXPERIMENT_NODE}'."
      return 0
    fi
  fi

  if [ "${CORE_EXPERIMENT_REQUIRE_NATIVE_ISA}" = "1" ]; then
    log_info "[verify_native_host] Enforcing RULE-2 native ISA guard (${CORE_EXPERIMENT_HOST_ARCH}) and host preparation on '${CORE_EXPERIMENT_NODE}'..."
    _v_cmd="cd ~/libscript && SCRIPT_NAME=./_lib/_common/experiment_harness.sh . ./_lib/_common/experiment_harness.sh && libscript_exp_assert_native_isa '${CORE_EXPERIMENT_HOST_ARCH}' && libscript_prepare_benchmark_host"
    cloud_exec_remote "${_v_cmd}"
  fi

  write_experiment_state 'verify_native_host' 'true'
}

# ## use_bento_fork
# Step b_use_bento_fork: Idempotently clones or updates SamuelMarks/bento at branch multi-os-qemu-aarch64.
use_bento_fork() {
  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -f "${CORE_EXPERIMENT_STATE_FILE}" ]; then
    if grep -q '"use_bento_fork": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && grep -q '"bento_branch": "'"${CORE_EXPERIMENT_BENTO_BRANCH}"'"' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then
      log_info "[use_bento_fork] Bento fork (${CORE_EXPERIMENT_BENTO_REPO} @ ${CORE_EXPERIMENT_BENTO_BRANCH}) already configured."
      return 0
    fi
  fi

  log_info "[use_bento_fork] Configuring Bento fork '${CORE_EXPERIMENT_BENTO_REPO}' at branch '${CORE_EXPERIMENT_BENTO_BRANCH}' into '${CORE_EXPERIMENT_BENTO_DIR}'..."
  _bento_cmd="if [ ! -d '${CORE_EXPERIMENT_BENTO_DIR}/.git' ]; then git clone --branch '${CORE_EXPERIMENT_BENTO_BRANCH}' '${CORE_EXPERIMENT_BENTO_REPO}' '${CORE_EXPERIMENT_BENTO_DIR}'; else cd '${CORE_EXPERIMENT_BENTO_DIR}' && git fetch origin '${CORE_EXPERIMENT_BENTO_BRANCH}' && git checkout '${CORE_EXPERIMENT_BENTO_BRANCH}'; fi"
  cloud_exec_remote "${_bento_cmd}"
  write_experiment_state 'use_bento_fork' 'true'
  log_info "[use_bento_fork] Bento fork ready at branch '${CORE_EXPERIMENT_BENTO_BRANCH}'."
}

# ## install_virtualization_stack
# Step c_install_virtualization_stack: Installs Vagrant, Packer, Ruby, QEMU, and Bento Builder dependencies via LibScript idempotently.
install_virtualization_stack() {
  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -f "${CORE_EXPERIMENT_STATE_FILE}" ]; then
    if grep -q '"install_virtualization_stack": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then
      log_info '[install_virtualization_stack] Virtualization stack (Vagrant, Packer, Ruby, QEMU, Bento Builder) already installed.'
      return 0
    fi
  fi

  log_info "[install_virtualization_stack] Installing Vagrant, Packer, Ruby, QEMU, and Bento Builder stack via LibScript on '${CORE_EXPERIMENT_NODE}'..."
  _vstack_cmd='cd ~/libscript && ./libscript.sh install ruby latest && ./libscript.sh install packer latest && ./libscript.sh install vagrant latest && ./libscript.sh install qemu latest && ./libscript.sh install bento-builder latest'
  cloud_exec_remote "${_vstack_cmd}"
  write_experiment_state 'install_virtualization_stack' 'true'
  log_info '[install_virtualization_stack] Virtualization stack installed.'
}

# ## deploy_vagrant_box
# Step d_deploy_vagrant_box: Builds (if not cached) and registers/boots the target OS(s) as Vagrant boxes via Bento idempotently.
deploy_vagrant_box() {
  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -f "${CORE_EXPERIMENT_STATE_FILE}" ]; then
    if grep -q '"deploy_vagrant_box": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && grep -q '"target_os": "'"${CORE_EXPERIMENT_TARGET_OS}"'"' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then
      log_info "[deploy_vagrant_box] Vagrant box(es) for '${CORE_EXPERIMENT_TARGET_OS}' already deployed."
      return 0
    fi
  fi

  _os_list=$(printf '%s' "${CORE_EXPERIMENT_TARGET_OS}" | tr ',' ' ')
  for _tgt_os in ${_os_list}; do
    log_info "[deploy_vagrant_box] Building & deploying Bento Vagrant box for target OS '${_tgt_os}'..."
    _deploy_cmd="cd ~/libscript && BENTO_DIR='${CORE_EXPERIMENT_BENTO_DIR}' ./_lib/virtualization/bento-builder/cli.sh build '${_tgt_os}' && ./tests/run_local_tests.sh --os '${_tgt_os}' --boot-only"
    cloud_exec_remote "${_deploy_cmd}"
  done

  write_experiment_state 'deploy_vagrant_box' 'true'
  log_info "[deploy_vagrant_box] Target OS '${CORE_EXPERIMENT_TARGET_OS}' deployed as Vagrant box."
}

# ## snapshot_vagrant_box
# Step e_snapshot_vagrant_box: Captures a clean baseline snapshot (`vanilla`) of the deployed Vagrant box so each component test starts from pristine state.
snapshot_vagrant_box() {
  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -f "${CORE_EXPERIMENT_STATE_FILE}" ]; then
    if grep -q '"snapshot_vagrant_box": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && grep -q '"snapshot_name": "'"${CORE_EXPERIMENT_SNAPSHOT_NAME}"'"' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && grep -q '"target_os": "'"${CORE_EXPERIMENT_TARGET_OS}"'"' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then
      log_info "[snapshot_vagrant_box] Baseline snapshot '${CORE_EXPERIMENT_SNAPSHOT_NAME}' already captured for '${CORE_EXPERIMENT_TARGET_OS}'."
      return 0
    fi
  fi

  _os_list=$(printf '%s' "${CORE_EXPERIMENT_TARGET_OS}" | tr ',' ' ')
  for _tgt_os in ${_os_list}; do
    log_info "[snapshot_vagrant_box] Capturing clean snapshot '${CORE_EXPERIMENT_SNAPSHOT_NAME}' for Vagrant box '${_tgt_os}'..."
    _snap_cmd="cd ~/libscript/vagrant/linux 2>/dev/null || cd ~/libscript; vagrant snapshot list '${_tgt_os}' 2>/dev/null | grep -qx '${CORE_EXPERIMENT_SNAPSHOT_NAME}' || vagrant snapshot save '${_tgt_os}' '${CORE_EXPERIMENT_SNAPSHOT_NAME}'"
    cloud_exec_remote "${_snap_cmd}"
  done

  write_experiment_state 'snapshot_vagrant_box' 'true'
  log_info "[snapshot_vagrant_box] Clean snapshot '${CORE_EXPERIMENT_SNAPSHOT_NAME}' ready."
}

# ## test_libscript_components
# Step f_test_libscript_components: Runs through every component of LibScript (or `--components=<list>`) on the target OS Vagrant box, restoring the clean snapshot before each component and running twice (`2x`) to prove strict idempotency.
test_libscript_components() {
  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -f "${CORE_EXPERIMENT_STATE_FILE}" ]; then
    if grep -q '"test_libscript_components": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && grep -q '"target_os": "'"${CORE_EXPERIMENT_TARGET_OS}"'"' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && grep -q '"components": "'"${CORE_EXPERIMENT_COMPONENTS}"'"' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && grep -q '"component_version": "'"${CORE_EXPERIMENT_COMPONENT_VERSION}"'"' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && grep -q '"pkg_mgr": "'"${CORE_EXPERIMENT_PKG_MGR}"'"' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && grep -q '"install_method": "'"${CORE_EXPERIMENT_INSTALL_METHOD}"'"' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then
      log_info "[test_libscript_components] LibScript component matrix (${CORE_EXPERIMENT_COMPONENTS}@${CORE_EXPERIMENT_COMPONENT_VERSION}, ${CORE_EXPERIMENT_IDEMPOTENCY_RUNS}x idempotency) already completed on '${CORE_EXPERIMENT_TARGET_OS}'."
      return 0
    fi
  fi

  _extra_matrix_flags=''
  [ "${CORE_EXPERIMENT_COMPONENT_VERSION}" != "latest" ] && _extra_matrix_flags="${_extra_matrix_flags} --version '${CORE_EXPERIMENT_COMPONENT_VERSION}'"
  [ -n "${CORE_EXPERIMENT_PKG_MGR}" ] && _extra_matrix_flags="${_extra_matrix_flags} --pkg-mgr '${CORE_EXPERIMENT_PKG_MGR}'"
  [ -n "${CORE_EXPERIMENT_INSTALL_METHOD}" ] && _extra_matrix_flags="${_extra_matrix_flags} --install-method '${CORE_EXPERIMENT_INSTALL_METHOD}'"
  [ -n "${CORE_EXPERIMENT_TOOLCHAIN}" ] && _extra_matrix_flags="${_extra_matrix_flags} --toolchain '${CORE_EXPERIMENT_TOOLCHAIN}'"

  _os_list=$(printf '%s' "${CORE_EXPERIMENT_TARGET_OS}" | tr ',' ' ')
  for _tgt_os in ${_os_list}; do
    log_info "[test_libscript_components] Running LibScript component suite (${CORE_EXPERIMENT_COMPONENTS}@${CORE_EXPERIMENT_COMPONENT_VERSION}) on '${_tgt_os}' (snapshot=${CORE_EXPERIMENT_SNAPSHOT_NAME}, idempotency_runs=${CORE_EXPERIMENT_IDEMPOTENCY_RUNS})..."
    _matrix_cmd="cd ~/libscript && SNAPSHOT_NAME='${CORE_EXPERIMENT_SNAPSHOT_NAME}' IDEMPOTENCY_RUNS='${CORE_EXPERIMENT_IDEMPOTENCY_RUNS}' ./tests/run_local_tests.sh --os '${_tgt_os}' --reuse-vm ${_extra_matrix_flags}"
    if [ "${CORE_EXPERIMENT_COMPONENTS}" != "all" ]; then
      _comp_args=$(printf '%s' "${CORE_EXPERIMENT_COMPONENTS}" | tr ',' ' ')
      _matrix_cmd="cd ~/libscript && SNAPSHOT_NAME='${CORE_EXPERIMENT_SNAPSHOT_NAME}' IDEMPOTENCY_RUNS='${CORE_EXPERIMENT_IDEMPOTENCY_RUNS}' ./tests/run_local_tests.sh ${_comp_args} --os '${_tgt_os}' --reuse-vm ${_extra_matrix_flags}"
    fi
    cloud_exec_remote "${_matrix_cmd}"
  done

  if [ "${DRY_RUN_MODE}" = "1" ]; then
    _local_staging="${LIBSCRIPT_ROOT_DIR}/build/experiment_bundle"
    mkdir -p "${_local_staging}/logs"
    cat <<EOF > "${_local_staging}/matrix_results.json"
{
  "target_os": "${CORE_EXPERIMENT_TARGET_OS}",
  "bento_repo": "${CORE_EXPERIMENT_BENTO_REPO}",
  "bento_branch": "${CORE_EXPERIMENT_BENTO_BRANCH}",
  "snapshot_name": "${CORE_EXPERIMENT_SNAPSHOT_NAME}",
  "components": "${CORE_EXPERIMENT_COMPONENTS}",
  "component_version": "${CORE_EXPERIMENT_COMPONENT_VERSION}",
  "pkg_mgr": "${CORE_EXPERIMENT_PKG_MGR}",
  "install_method": "${CORE_EXPERIMENT_INSTALL_METHOD}",
  "toolchain": "${CORE_EXPERIMENT_TOOLCHAIN}",
  "idempotency_runs": ${CORE_EXPERIMENT_IDEMPOTENCY_RUNS},
  "status": "PASSED"
}
EOF
  fi

  write_experiment_state 'test_libscript_components' 'true'
  log_info "[test_libscript_components] Completed LibScript component matrix on '${CORE_EXPERIMENT_TARGET_OS}'."
}

# ## run_experiments
# Runs the requested experimental benchmark suite (`libscript`, `edgcpp`, `libtpu`, `manifest`, or `all`) on the provisioned cloud host with idempotency.
run_experiments() {
  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -f "${CORE_EXPERIMENT_STATE_FILE}" ]; then
    if grep -q '"run_experiments": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && grep -q '"suite": "'"${CORE_EXPERIMENT_SUITE}"'"' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then
      log_info "[run_experiments] Experiments (${CORE_EXPERIMENT_SUITE}) already completed on '${CORE_EXPERIMENT_NODE}'."
      return 0
    fi
  fi

  if [ "${CORE_EXPERIMENT_SUITE}" = "libscript" ]; then
    test_libscript_components
    write_experiment_state 'run_experiments' 'true'
    return 0
  fi

  if [ "${CORE_EXPERIMENT_SUITE}" = "edgcpp_backends" ]; then
    log_info "[run_experiments] Running edgcpp_backends empirical suites (${CORE_EXPERIMENT_SUBSUITES}) on '${CORE_EXPERIMENT_NODE}' (arch=${CORE_EXPERIMENT_HOST_ARCH})..."
    _eb_cmd="cd ~/libscript && LIBSCRIPT_BENCH_PREPARE_HOST=1 ./_lib/toolchains/edgcpp-backends-suite/cli.sh experiments --subsuites='${CORE_EXPERIMENT_SUBSUITES}' --host-arch='${CORE_EXPERIMENT_HOST_ARCH}' --results-dir='~/libscript/build/edgcpp_backends_results'"
    cloud_exec_remote "${_eb_cmd}"
    if [ "${DRY_RUN_MODE}" = "1" ] && [ -x "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/edgcpp-backends-suite/benchmark_experiments.sh" ]; then
      EDGCPP_BACKENDS_SUITE_SYNTHETIC='1' "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/edgcpp-backends-suite/benchmark_experiments.sh" --synthetic-fixtures --subsuites="${CORE_EXPERIMENT_SUBSUITES}" --host-arch="${CORE_EXPERIMENT_HOST_ARCH}" --results-dir="${LIBSCRIPT_ROOT_DIR}/build/experiment_bundle/results" >/dev/null 2>&1 || true
    fi
    write_experiment_state 'run_experiments' 'true'
    return 0
  fi

  if [ "${CORE_EXPERIMENT_SUITE}" = "win_port" ]; then
    log_info "[run_experiments] Running win_port empirical suites (${CORE_EXPERIMENT_SUBSUITES}) on '${CORE_EXPERIMENT_NODE}' (arch=${CORE_EXPERIMENT_HOST_ARCH})..."
    _wp_cmd="cd ~/libscript && LIBSCRIPT_BENCH_PREPARE_HOST=1 ./_lib/toolchains/win-port-suite/cli.sh experiments --subsuites='${CORE_EXPERIMENT_SUBSUITES}' --host-arch='${CORE_EXPERIMENT_HOST_ARCH}' --results-dir='~/libscript/build/win_port_results'"
    cloud_exec_remote "${_wp_cmd}"
    if [ "${DRY_RUN_MODE}" = "1" ] && [ -x "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/win-port-suite/benchmark_experiments.sh" ]; then
      WIN_PORT_SUITE_SYNTHETIC='1' "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/win-port-suite/benchmark_experiments.sh" --synthetic-fixtures --subsuites="${CORE_EXPERIMENT_SUBSUITES}" --host-arch="${CORE_EXPERIMENT_HOST_ARCH}" --results-dir="${LIBSCRIPT_ROOT_DIR}/build/experiment_bundle/results" >/dev/null 2>&1 || true
    fi
    write_experiment_state 'run_experiments' 'true'
    return 0
  fi
  if [ "${CORE_EXPERIMENT_SUITE}" = "manifest" ] && [ -n "${CORE_EXPERIMENT_SUITE_MANIFEST}" ]; then
    libscript_exp_run_manifest "${CORE_EXPERIMENT_SUITE_MANIFEST}" "${CORE_EXPERIMENT_SUBSUITES}" "${LIBSCRIPT_ROOT_DIR}/build/experiment_bundle/results"
    write_experiment_state 'run_experiments' 'true'
    return 0
  fi
  if [ "${CORE_EXPERIMENT_SUITE}" = "libtpu" ] || [ "${CORE_EXPERIMENT_SUITE}" = "manifest" ]; then
    log_info "[run_experiments] Running libtpu empirical suites (${CORE_EXPERIMENT_SUBSUITES}) on '${CORE_EXPERIMENT_NODE}' (warmup=${CORE_EXPERIMENT_WARMUP}, trials=${CORE_EXPERIMENT_TRIALS}, arch=${CORE_EXPERIMENT_HOST_ARCH})..."
    _libtpu_cmd="cd ~/libscript && LIBSCRIPT_BENCH_PREPARE_HOST=1 LIBSCRIPT_BENCH_DROP_CACHES=1 ./_lib/toolchains/libtpu-rs/cli.sh experiments --subsuites='${CORE_EXPERIMENT_SUBSUITES}' --warmup='${CORE_EXPERIMENT_WARMUP}' --trials='${CORE_EXPERIMENT_TRIALS}' --cargo-profile='${CORE_EXPERIMENT_CARGO_PROFILE}' --host-arch='${CORE_EXPERIMENT_HOST_ARCH}' --results-dir='~/libscript/build/libtpu_results'"
    cloud_exec_remote "${_libtpu_cmd}"
    if [ "${DRY_RUN_MODE}" = "1" ] && [ -x "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/libtpu-rs/benchmark_experiments.sh" ]; then
      LIBTPU_RS_SYNTHETIC_FIXTURES='1' LIBTPU_RS_DRY_RUN='1' "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/libtpu-rs/benchmark_experiments.sh" --subsuites="${CORE_EXPERIMENT_SUBSUITES}" --warmup="${CORE_EXPERIMENT_WARMUP}" --trials="${CORE_EXPERIMENT_TRIALS}" --cargo-profile="${CORE_EXPERIMENT_CARGO_PROFILE}" --host-arch="${CORE_EXPERIMENT_HOST_ARCH}" --results-dir="${LIBSCRIPT_ROOT_DIR}/build/experiment_bundle/results" >/dev/null 2>&1 || true
    fi
    write_experiment_state 'run_experiments' 'true'
    return 0
  fi

  log_info "[run_experiments] Running EDG backend experiments on '${CORE_EXPERIMENT_NODE}' (workloads=${CORE_EXPERIMENT_WORKLOADS}, compilers=${CORE_EXPERIMENT_COMPILERS}, runs=${CORE_EXPERIMENT_RUNS})..."
  _remote_cmd="cd ~/libscript && LIBSCRIPT_BENCH_PREPARE_HOST=1 LIBSCRIPT_BENCH_DROP_CACHES=1 ./_lib/languages/edgcpp/cli.sh experiments --workloads='${CORE_EXPERIMENT_WORKLOADS}' --compilers='${CORE_EXPERIMENT_COMPILERS}' --runs='${CORE_EXPERIMENT_RUNS}'"
  cloud_exec_remote "${_remote_cmd}"

  if [ "${DRY_RUN_MODE}" = "1" ]; then
    "${LIBSCRIPT_ROOT_DIR}/_lib/languages/edgcpp/cli.sh" experiments --workloads="${CORE_EXPERIMENT_WORKLOADS}" --compilers="${CORE_EXPERIMENT_COMPILERS}" --runs="${CORE_EXPERIMENT_RUNS}" >/dev/null 2>&1 || true
  fi

  write_experiment_state 'run_experiments' 'true'
  log_info "[run_experiments] Experiments completed on '${CORE_EXPERIMENT_NODE}'."
}

# ## collect_logs
# Consolidates suite-specific JSON reports (`results/e0_*.json` .. `e7_*.json`, `edgcpp-*`), Vagrant logs (`tests_tmp/`), and LaTeX metrics into `CORE_EXPERIMENT_REMOTE_DIR` without clobbering sibling architecture files.
collect_logs() {
  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -f "${CORE_EXPERIMENT_STATE_FILE}" ]; then
    if grep -q '"collect_logs": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then
      log_info "[collect_logs] Experimental log results already consolidated in '${CORE_EXPERIMENT_REMOTE_DIR}'."
      return 0
    fi
  fi

  log_info "[collect_logs] Consolidating suite '${CORE_EXPERIMENT_SUITE}' artifacts into '${CORE_EXPERIMENT_REMOTE_DIR}' on '${CORE_EXPERIMENT_NODE}'..."
  _collect_cmd="mkdir -p ${CORE_EXPERIMENT_REMOTE_DIR}/cells ${CORE_EXPERIMENT_REMOTE_DIR}/logs ${CORE_EXPERIMENT_REMOTE_DIR}/tests_tmp ${CORE_EXPERIMENT_REMOTE_DIR}/results ${CORE_EXPERIMENT_REMOTE_DIR}/results/raw && cp -rf ~/libscript/tests_tmp/* ${CORE_EXPERIMENT_REMOTE_DIR}/tests_tmp/ 2>/dev/null || true && cp -rf ~/libscript/build/libtpu_results/* ${CORE_EXPERIMENT_REMOTE_DIR}/results/ 2>/dev/null || true && cp -rf ~/libscript/build/win_port_results/raw/* ${CORE_EXPERIMENT_REMOTE_DIR}/results/raw/ 2>/dev/null || true && cp -rf ~/libscript/build/win_port_results/* ${CORE_EXPERIMENT_REMOTE_DIR}/results/ 2>/dev/null || true && cp -rf ~/libscript/build/edgcpp_backends_results/raw/* ${CORE_EXPERIMENT_REMOTE_DIR}/results/raw/ 2>/dev/null || true && cp -rf ~/libscript/build/edgcpp_backends_results/* ${CORE_EXPERIMENT_REMOTE_DIR}/results/ 2>/dev/null || true && cp -f ~/libscript/build/edgcpp-experiments-report.json ${CORE_EXPERIMENT_REMOTE_DIR}/ 2>/dev/null || true && cp -f ~/libscript/build/edgcpp-experiments-tables.tex ${CORE_EXPERIMENT_REMOTE_DIR}/ 2>/dev/null || true && cp -f ~/libscript/build/edgcpp-torture-report.json ${CORE_EXPERIMENT_REMOTE_DIR}/ 2>/dev/null || true && cp -rf ~/libscript/build/experiments/* ${CORE_EXPERIMENT_REMOTE_DIR}/cells/ 2>/dev/null || true && cp -f ~/.libscript/edgcpp/compile_events.jsonl ${CORE_EXPERIMENT_REMOTE_DIR}/logs/ 2>/dev/null || true"
  cloud_exec_remote "${_collect_cmd}"

  if [ "${DRY_RUN_MODE}" = "1" ]; then
    _local_staging="${LIBSCRIPT_ROOT_DIR}/build/experiment_bundle"
    mkdir -p "${_local_staging}/cells" "${_local_staging}/logs" "${_local_staging}/tests_tmp" "${_local_staging}/results"
    [ -f "${LIBSCRIPT_ROOT_DIR}/build/edgcpp-experiments-report.json" ] && cp -f "${LIBSCRIPT_ROOT_DIR}/build/edgcpp-experiments-report.json" "${_local_staging}/"
    [ -f "${LIBSCRIPT_ROOT_DIR}/build/edgcpp-experiments-tables.tex" ] && cp -f "${LIBSCRIPT_ROOT_DIR}/build/edgcpp-experiments-tables.tex" "${_local_staging}/"
    [ -f "${LIBSCRIPT_ROOT_DIR}/build/edgcpp-torture-report.json" ] && cp -f "${LIBSCRIPT_ROOT_DIR}/build/edgcpp-torture-report.json" "${_local_staging}/"
  fi

  write_experiment_state 'collect_logs' 'true'
  log_info "[collect_logs] Consolidated experimental logs into '${CORE_EXPERIMENT_REMOTE_DIR}'."
}

# ## pull_logs
# Transfers consolidated results from the cloud node to `CORE_EXPERIMENT_LOCAL_DIR` while preserving multi-host architecture artifacts (`*_linux_x64.json` and `*_macos_arm64.json`).
pull_logs() {
  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -f "${CORE_EXPERIMENT_STATE_FILE}" ] && [ -s "${CORE_EXPERIMENT_LOCAL_DIR}/transfer-manifest.json" ]; then
    if grep -q '"pull_logs": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && grep -q '"target_os": "'"${CORE_EXPERIMENT_TARGET_OS}"'"' "${CORE_EXPERIMENT_LOCAL_DIR}/transfer-manifest.json" 2>/dev/null && grep -q '"host_arch": "'"${CORE_EXPERIMENT_HOST_ARCH}"'"' "${CORE_EXPERIMENT_LOCAL_DIR}/transfer-manifest.json" 2>/dev/null; then
      log_info "[pull_logs] Experimental results directory already transferred to '${CORE_EXPERIMENT_LOCAL_DIR}'."
      return 0
    fi
  fi

  mkdir -p "${CORE_EXPERIMENT_LOCAL_DIR}/results"
  log_info "[pull_logs] Transferring '${CORE_EXPERIMENT_REMOTE_DIR}' from '${CORE_EXPERIMENT_NODE}' to local directory '${CORE_EXPERIMENT_LOCAL_DIR}'..."
  if [ "${CORE_EXPERIMENT_PROVIDER}" = "gcp-tpu-vm" ]; then
    if [ "${DRY_RUN_MODE}" != "1" ]; then
      _tpu_cli="$(resolve_provider_cli)"
      TPU_ZONE="${CORE_EXPERIMENT_LOCATION}" GCP_PROJECT_ID="${CORE_EXPERIMENT_RG}" "${_tpu_cli}" scp-from "${CORE_EXPERIMENT_NODE}" "${CORE_EXPERIMENT_NODE}:${CORE_EXPERIMENT_REMOTE_DIR}" "${CORE_EXPERIMENT_LOCAL_DIR}"
    fi
  else
    _cli="$(resolve_provider_cli)"
    _ctx="${CORE_EXPERIMENT_RG}"
    if [ "${CORE_EXPERIMENT_PROVIDER}" = "aws" ] || [ "${CORE_EXPERIMENT_PROVIDER}" = "gcp" ]; then
      _ctx="${CORE_EXPERIMENT_LOCATION}"
    fi
    if [ "${DRY_RUN_MODE}" = "1" ]; then
      DRY_RUN='true' "${_cli}" node scp-from "${CORE_EXPERIMENT_NODE}" "${_ctx}" "${CORE_EXPERIMENT_REMOTE_DIR}" "${CORE_EXPERIMENT_LOCAL_DIR}"
    else
      "${_cli}" node scp-from "${CORE_EXPERIMENT_NODE}" "${_ctx}" "${CORE_EXPERIMENT_REMOTE_DIR}" "${CORE_EXPERIMENT_LOCAL_DIR}"
    fi
  fi

  if [ "${DRY_RUN_MODE}" = "1" ]; then
    _local_staging="${LIBSCRIPT_ROOT_DIR}/build/experiment_bundle"
    if [ -d "${_local_staging}" ]; then
      for _item in edgcpp-experiments-report.json edgcpp-experiments-tables.tex edgcpp-torture-report.json matrix_results.json; do
        [ -f "${_local_staging}/${_item}" ] && cp -f "${_local_staging}/${_item}" "${CORE_EXPERIMENT_LOCAL_DIR}/"
      done
      if [ -d "${_local_staging}/results" ]; then
        find "${_local_staging}/results" -maxdepth 1 -type f -exec cp -f {} "${CORE_EXPERIMENT_LOCAL_DIR}/results/" \;
        if [ -d "${_local_staging}/results/raw" ]; then
          mkdir -p "${CORE_EXPERIMENT_LOCAL_DIR}/results/raw"
          find "${_local_staging}/results/raw" -maxdepth 1 -type f -exec cp -f {} "${CORE_EXPERIMENT_LOCAL_DIR}/results/raw/" \;
        fi
      fi
    fi
    if [ ! -f "${CORE_EXPERIMENT_LOCAL_DIR}/edgcpp-experiments-report.json" ] && [ -f "${LIBSCRIPT_ROOT_DIR}/build/edgcpp-experiments-report.json" ]; then
      cp -f "${LIBSCRIPT_ROOT_DIR}/build/edgcpp-experiments-report.json" "${CORE_EXPERIMENT_LOCAL_DIR}/"
    fi
    if [ ! -f "${CORE_EXPERIMENT_LOCAL_DIR}/edgcpp-experiments-tables.tex" ] && [ -f "${LIBSCRIPT_ROOT_DIR}/build/edgcpp-experiments-tables.tex" ]; then
      cp -f "${LIBSCRIPT_ROOT_DIR}/build/edgcpp-experiments-tables.tex" "${CORE_EXPERIMENT_LOCAL_DIR}/"
    fi
  fi

  cat <<EOF > "${CORE_EXPERIMENT_LOCAL_DIR}/transfer-manifest.json.tmp"
{
  "provider": "${CORE_EXPERIMENT_PROVIDER}",
  "node": "${CORE_EXPERIMENT_NODE}",
  "instance_size": "${RESOLVED_VM_SKU}",
  "host_arch": "${CORE_EXPERIMENT_HOST_ARCH}",
  "suite": "${CORE_EXPERIMENT_SUITE}",
  "subsuites": "${CORE_EXPERIMENT_SUBSUITES}",
  "target_os": "${CORE_EXPERIMENT_TARGET_OS}",
  "bento_repo": "${CORE_EXPERIMENT_BENTO_REPO}",
  "bento_branch": "${CORE_EXPERIMENT_BENTO_BRANCH}",
  "snapshot_name": "${CORE_EXPERIMENT_SNAPSHOT_NAME}",
  "components": "${CORE_EXPERIMENT_COMPONENTS}",
  "component_version": "${CORE_EXPERIMENT_COMPONENT_VERSION}",
  "pkg_mgr": "${CORE_EXPERIMENT_PKG_MGR}",
  "install_method": "${CORE_EXPERIMENT_INSTALL_METHOD}",
  "toolchain": "${CORE_EXPERIMENT_TOOLCHAIN}",
  "idempotency_runs": ${CORE_EXPERIMENT_IDEMPOTENCY_RUNS},
  "remote_source_dir": "${CORE_EXPERIMENT_REMOTE_DIR}",
  "local_dest_dir": "${CORE_EXPERIMENT_LOCAL_DIR}",
  "status": "TRANSFERRED"
}
EOF
  mv -f "${CORE_EXPERIMENT_LOCAL_DIR}/transfer-manifest.json.tmp" "${CORE_EXPERIMENT_LOCAL_DIR}/transfer-manifest.json"
  write_experiment_state 'pull_logs' 'true'
  log_info "[pull_logs] Transferred experimental results to '${CORE_EXPERIMENT_LOCAL_DIR}'."
}

# ## send_logs_to_host
# Step h_pull_logs (send_logs_to_host): Consolidates all remote component test logs and transfers them back to the host.
send_logs_to_host() {
  collect_logs
  pull_logs
  write_experiment_state 'send_logs_to_host' 'true'
}

# ## emit_latex_and_verify_pdf
# Synthesizes `generated_metrics.tex` from consolidated multi-host `results/*.json` artifacts on the host, checks zero `\tbd`/`???` placeholders, and optionally builds `libtpu_paper.pdf`.
emit_latex_and_verify_pdf() {
  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -f "${CORE_EXPERIMENT_STATE_FILE}" ]; then
    if grep -q '"emit_latex_and_verify_pdf": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then
      log_info '[emit_latex_and_verify_pdf] LaTeX macro emission and manuscript check already completed.'
      return 0
    fi
  fi

  if [ "${CORE_EXPERIMENT_SUITE}" = "edgcpp_backends" ] && [ -x "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/edgcpp-backends-suite/benchmark_experiments.sh" ]; then
    _eb_pdf_flag=''
    [ "${CORE_EXPERIMENT_BUILD_PDF}" = "1" ] && _eb_pdf_flag='--build-pdf'
    _eb_syn_flag='0'
    [ "${DRY_RUN_MODE}" = "1" ] && _eb_syn_flag='1'
    # shellcheck disable=SC2086
    EDGCPP_BACKENDS_SUITE_SYNTHETIC="${_eb_syn_flag}" "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/edgcpp-backends-suite/benchmark_experiments.sh" --subsuites='E7' --results-dir="${CORE_EXPERIMENT_LOCAL_DIR}/results" --paper-dir="${CORE_EXPERIMENT_PAPER_DIR}" ${_eb_pdf_flag}
    write_experiment_state 'emit_latex_and_verify_pdf' 'true'
    return 0
  fi

  if [ "${CORE_EXPERIMENT_SUITE}" = "win_port" ] && [ -x "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/win-port-suite/benchmark_experiments.sh" ]; then
    _wp_pdf_flag=''
    [ "${CORE_EXPERIMENT_BUILD_PDF}" = "1" ] && _wp_pdf_flag='--build-pdf'
    _wp_syn_flag='0'
    [ "${DRY_RUN_MODE}" = "1" ] && _wp_syn_flag='1'
    # shellcheck disable=SC2086
    WIN_PORT_SUITE_SYNTHETIC="${_wp_syn_flag}" "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/win-port-suite/benchmark_experiments.sh" --subsuites='E7' --results-dir="${CORE_EXPERIMENT_LOCAL_DIR}/results" --paper-dir="${CORE_EXPERIMENT_PAPER_DIR}" ${_wp_pdf_flag}
    write_experiment_state 'emit_latex_and_verify_pdf' 'true'
    return 0
  fi
  if [ -x "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/libtpu-rs/benchmark_experiments.sh" ]; then
    _pdf_flag=''
    [ "${CORE_EXPERIMENT_BUILD_PDF}" = "1" ] && _pdf_flag='--build-pdf'
    _syn_flag='0'
    [ "${DRY_RUN_MODE}" = "1" ] && _syn_flag='1'
    # shellcheck disable=SC2086
    LIBTPU_RS_SYNTHETIC_FIXTURES="${_syn_flag}" LIBTPU_RS_DRY_RUN="${DRY_RUN_MODE}" "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/libtpu-rs/benchmark_experiments.sh" --subsuites='E8' --results-dir="${CORE_EXPERIMENT_LOCAL_DIR}/results" --paper-dir="${CORE_EXPERIMENT_PAPER_DIR}" ${_pdf_flag}
  fi

  write_experiment_state 'emit_latex_and_verify_pdf' 'true'
}

# ## deprovision_instance
# Step i_deprovision_instance: Idempotently deprovisions the cloud host (or GCP TPU VM) and associated network/firewall resources while preserving local transferred results.
deprovision_instance() {
  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -f "${CORE_EXPERIMENT_STATE_FILE}" ]; then
    if grep -q '"deprovision_instance": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then
      log_info "[deprovision_instance] Cloud host '${CORE_EXPERIMENT_NODE}' is already deprovisioned."
      return 0
    fi
  fi

  log_info "[deprovision_instance] Deprovisioning cloud host '${CORE_EXPERIMENT_NODE}' (${CORE_EXPERIMENT_PROVIDER} / ${CORE_EXPERIMENT_RG})..."
  if [ "${CORE_EXPERIMENT_PROVIDER}" = "gcp-tpu-vm" ]; then
    if [ "${DRY_RUN_MODE}" != "1" ]; then
      _tpu_cli="$(resolve_provider_cli)"
      TPU_ZONE="${CORE_EXPERIMENT_LOCATION}" GCP_PROJECT_ID="${CORE_EXPERIMENT_RG}" "${_tpu_cli}" delete "${CORE_EXPERIMENT_NODE}"
    fi
  else
    "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/teardown_cloud.sh" --provider "${CORE_EXPERIMENT_PROVIDER}" --node "${CORE_EXPERIMENT_NODE}" --rg "${CORE_EXPERIMENT_RG}" --location "${CORE_EXPERIMENT_LOCATION}" --purge-data
  fi
  write_experiment_state 'deprovision_instance' 'true'
  log_info "[deprovision_instance] Cloud host '${CORE_EXPERIMENT_NODE}' deprovisioned."
}

# ## run_selected_lifecycle_steps
# Parses CORE_EXPERIMENT_STEPS and executes each requested named step in sequence.
run_selected_lifecycle_steps() {
  _norm_steps=$(printf '%s' "${CORE_EXPERIMENT_STEPS}" | tr ',;' '  ')
  for _token in ${_norm_steps}; do
    case "${_token}" in
      all|full_bento_matrix)
        if [ "${CORE_EXPERIMENT_SUITE}" = "libtpu" ] || [ "${CORE_EXPERIMENT_SUITE}" = "win_port" ] || [ "${CORE_EXPERIMENT_SUITE}" = "edgcpp_backends" ] || [ "${CORE_EXPERIMENT_SUITE}" = "manifest" ]; then
          provision_instance
          sync_research_repos
          verify_native_host
          run_experiments
          send_logs_to_host
          emit_latex_and_verify_pdf
          deprovision_instance
        else
          provision_instance
          use_bento_fork
          install_virtualization_stack
          deploy_vagrant_box
          snapshot_vagrant_box
          test_libscript_components
          run_experiments
          send_logs_to_host
          deprovision_instance
        fi
        ;;
      libtpu_campaign|win_port_campaign|edgcpp_backends_campaign)
        provision_instance
        sync_research_repos
        verify_native_host
        run_experiments
        send_logs_to_host
        emit_latex_and_verify_pdf
        deprovision_instance
        ;;
      bento_matrix|os_matrix)
        use_bento_fork
        install_virtualization_stack
        deploy_vagrant_box
        snapshot_vagrant_box
        test_libscript_components
        send_logs_to_host
        ;;
      a_provision_instance|provision_instance|provision|a)
        provision_instance
        ;;
      sync_research_repos)
        sync_research_repos
        ;;
      verify_native_host)
        verify_native_host
        ;;
      b_use_bento_fork|use_bento_fork|setup_bento_fork|bento_fork|0)
        use_bento_fork
        ;;
      c_install_virtualization_stack|install_virtualization_stack|install_bento_deps|1)
        install_virtualization_stack
        ;;
      d_deploy_vagrant_box|deploy_vagrant_box|deploy_target_os|2)
        deploy_vagrant_box
        ;;
      e_snapshot_vagrant_box|snapshot_vagrant_box|snapshot|3)
        snapshot_vagrant_box
        ;;
      f_test_libscript_components|test_libscript_components|run_libscript_matrix|4)
        test_libscript_components
        ;;
      g_collect_logs|collect_logs|move_to_log_dir|collect)
        collect_logs
        ;;
      h_pull_logs|send_logs_to_host|5)
        send_logs_to_host
        ;;
      pull_logs|move_log_dir_to_host|transfer|pull)
        pull_logs
        ;;
      emit_latex_and_verify_pdf)
        emit_latex_and_verify_pdf
        ;;
      run_experiments|run)
        run_experiments
        ;;
      i_deprovision_instance|deprovision_instance|deprovision|teardown|i)
        deprovision_instance
        ;;
      *)
        log_error "Unknown experiment lifecycle step: '${_token}'"
        return 1
        ;;
    esac
  done
}

run_selected_lifecycle_steps
