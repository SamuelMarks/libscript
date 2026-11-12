#!/bin/sh
# ## Overview
# Unified rapid cloud & Bento multi-OS Vagrant matrix experimentation lifecycle orchestrator using lexicographically ordered named steps (`a_provision_instance` .. `i_deprovision_instance`).
# ## Usage
# ./_lib/cloud/core/experiment_cloud.sh [a_provision_instance|b_use_bento_fork|c_install_virtualization_stack|d_deploy_vagrant_box|e_snapshot_vagrant_box|f_test_libscript_components|g_collect_logs|h_pull_logs|i_deprovision_instance|bento_matrix|all] [--target-os=alpine-3.24]
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
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
export LIBSCRIPT_ROOT_DIR
unset SCRIPT_NAME || true

_EXP_SCRIPT_DIR="${SCRIPT_DIR}"
_EXP_THIS_FILE="${THIS_FILE}"
for LIB in "_lib/_common/log.sh" "_lib/_common/remote_sync.sh"; do
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
    a_provision_instance|b_use_bento_fork|c_install_virtualization_stack|d_deploy_vagrant_box|e_snapshot_vagrant_box|f_test_libscript_components|g_collect_logs|h_pull_logs|i_deprovision_instance|provision_instance|use_bento_fork|setup_bento_fork|bento_fork|install_virtualization_stack|install_bento_deps|deploy_vagrant_box|deploy_target_os|snapshot_vagrant_box|snapshot|test_libscript_components|run_libscript_matrix|send_logs_to_host|run_experiments|collect_logs|move_to_log_dir|pull_logs|move_log_dir_to_host|deprovision_instance|bento_matrix|os_matrix|full_bento_matrix|all|provision|run|collect|transfer|pull|deprovision|teardown|a|0|1|2|3|4|5|i)
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
      printf '%s\n' 'Usage: experiment_cloud.sh [a_provision_instance|b_use_bento_fork|c_install_virtualization_stack|d_deploy_vagrant_box|e_snapshot_vagrant_box|f_test_libscript_components|g_collect_logs|h_pull_logs|i_deprovision_instance|bento_matrix|all] [--target-os=alpine-3.24] [--bento-repo=https://github.com/SamuelMarks/bento.git] [--bento-branch=multi-os-qemu-aarch64] [--provider=azure] [--size="160-vCPU Standard_D160ads_v7"]'
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

[ -z "${CORE_EXPERIMENT_STEPS}" ] && CORE_EXPERIMENT_STEPS='a_provision_instance,b_use_bento_fork,c_install_virtualization_stack,d_deploy_vagrant_box,e_snapshot_vagrant_box,f_test_libscript_components,run_experiments,g_collect_logs,h_pull_logs,i_deprovision_instance'

# ## normalize_vm_sku
# Normalizes a descriptive instance label such as '160-vCPU Standard_D160ads_v7' into the exact cloud provider SKU 'Standard_D160ads_v7'.
normalize_vm_sku() {
  _raw_sz="${1:-160-vCPU Standard_D160ads_v7}"
  case "${_raw_sz}" in
    *"Standard_"*)
      printf '%s
' "Standard_${_raw_sz#*Standard_}" | awk '{print $1}'
      ;;
    *)
      printf '%s
' "${_raw_sz}" | awk '{print $NF}'
      ;;
  esac
}

RESOLVED_VM_SKU="$(normalize_vm_sku "${CORE_EXPERIMENT_SIZE}")"

# ## resolve_provider_cli
# Returns the path to the provider CLI script for the configured cloud vendor.
resolve_provider_cli() {
  _p_cli="${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/${CORE_EXPERIMENT_PROVIDER}/cli.sh"
  if [ ! -f "${_p_cli}" ]; then
    log_error "Unsupported cloud provider: ${CORE_EXPERIMENT_PROVIDER} (${_p_cli} not found)."
    return 1
  fi
  printf '%s
' "${_p_cli}"
}

# ## write_experiment_state
# Updates the persistent JSON state file tracking which named lifecycle phases have completed.
write_experiment_state() {
  _st_phase="${1}"
  _st_status="${2}"
  mkdir -p "$(dirname "${CORE_EXPERIMENT_STATE_FILE}")"
  _prev_prov='false'
  _prev_bento='false'
  _prev_vstack='false'
  _prev_deploy='false'
  _prev_snap='false'
  _prev_test='false'
  _prev_send='false'
  _prev_run='false'
  _prev_col='false'
  _prev_pull='false'
  _prev_deprov='false'
  if [ -f "${CORE_EXPERIMENT_STATE_FILE}" ]; then
    grep -q '"provision_instance": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && _prev_prov='true'
    grep -q '"use_bento_fork": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && _prev_bento='true'
    grep -q '"install_virtualization_stack": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && _prev_vstack='true'
    grep -q '"deploy_vagrant_box": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && _prev_deploy='true'
    grep -q '"snapshot_vagrant_box": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && _prev_snap='true'
    grep -q '"test_libscript_components": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && _prev_test='true'
    grep -q '"send_logs_to_host": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && _prev_send='true'
    grep -q '"run_experiments": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && _prev_run='true'
    grep -q '"collect_logs": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && _prev_col='true'
    grep -q '"pull_logs": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && _prev_pull='true'
    grep -q '"deprovision_instance": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && _prev_deprov='true'
  fi
  case "${_st_phase}" in
    provision_instance) _prev_prov="${_st_status}"; [ "${_st_status}" = "true" ] && _prev_deprov='false' ;;
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
  "remote_results_dir": "${CORE_EXPERIMENT_REMOTE_DIR}",
  "local_results_dir": "${CORE_EXPERIMENT_LOCAL_DIR}",
  "a_provision_instance": ${_prev_prov},
  "b_use_bento_fork": ${_prev_bento},
  "c_install_virtualization_stack": ${_prev_vstack},
  "d_deploy_vagrant_box": ${_prev_deploy},
  "e_snapshot_vagrant_box": ${_prev_snap},
  "f_test_libscript_components": ${_prev_test},
  "g_collect_logs": ${_prev_col},
  "h_pull_logs": ${_prev_pull},
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
# Step a_provision_instance: Idempotently provisions the cloud instance (default 160-vCPU Standard_D160ads_v7 on Azure), waits for SSH, and syncs the LibScript runtime.
provision_instance() {
  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -f "${CORE_EXPERIMENT_STATE_FILE}" ]; then
    if grep -q '"provision_instance": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && grep -q '"resolved_sku": "'"${RESOLVED_VM_SKU}"'"' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then
      log_info "[provision_instance] Cloud instance '${CORE_EXPERIMENT_NODE}' (${RESOLVED_VM_SKU} on ${CORE_EXPERIMENT_PROVIDER}) already provisioned."
      return 0
    fi
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
  "${_cli}" firewall create "${_nsg}" "${_ctx}" "22" --location "${CORE_EXPERIMENT_LOCATION}"
  "${_cli}" node create "${CORE_EXPERIMENT_NODE}" "${CORE_EXPERIMENT_OS}" "${_ctx}" --vnet-name "${_vnet}" --nsg "${_nsg}" --size "${RESOLVED_VM_SKU}" --admin-username "${CORE_EXPERIMENT_ADMIN_USER}"
  "${_cli}" node wait-ssh "${CORE_EXPERIMENT_NODE}" "${_ctx}"
  "${_cli}" node sync "${CORE_EXPERIMENT_NODE}" "${_ctx}"
  write_experiment_state "provision_instance" "true"
  log_info "[provision_instance] Instance '${CORE_EXPERIMENT_NODE}' (${RESOLVED_VM_SKU}) ready."
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

  _cli="$(resolve_provider_cli)"
  _ctx="${CORE_EXPERIMENT_RG}"
  if [ "${CORE_EXPERIMENT_PROVIDER}" = "aws" ] || [ "${CORE_EXPERIMENT_PROVIDER}" = "gcp" ]; then
    _ctx="${CORE_EXPERIMENT_LOCATION}"
  fi

  log_info "[use_bento_fork] Configuring Bento fork '${CORE_EXPERIMENT_BENTO_REPO}' at branch '${CORE_EXPERIMENT_BENTO_BRANCH}' (dir: ${CORE_EXPERIMENT_BENTO_DIR})..."
  _bento_cmd="cd ~/libscript && ./libscript.sh install git latest && if [ ! -d '${CORE_EXPERIMENT_BENTO_DIR}/.git' ]; then git clone --branch '${CORE_EXPERIMENT_BENTO_BRANCH}' '${CORE_EXPERIMENT_BENTO_REPO}' '${CORE_EXPERIMENT_BENTO_DIR}'; else git -C '${CORE_EXPERIMENT_BENTO_DIR}' fetch origin '${CORE_EXPERIMENT_BENTO_BRANCH}' && git -C '${CORE_EXPERIMENT_BENTO_DIR}' checkout '${CORE_EXPERIMENT_BENTO_BRANCH}'; fi"
  "${_cli}" node exec "${CORE_EXPERIMENT_NODE}" "${_ctx}" "${_bento_cmd}"

  write_experiment_state "use_bento_fork" "true"
  log_info "[use_bento_fork] Bento fork '${CORE_EXPERIMENT_BENTO_REPO}' @ '${CORE_EXPERIMENT_BENTO_BRANCH}' ready."
}

# ## install_virtualization_stack
# Step c_install_virtualization_stack: Idempotently installs Vagrant, Packer, Ruby, QEMU, VirtualBox, and ISO tools via LibScript's bento-builder component.
install_virtualization_stack() {
  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -f "${CORE_EXPERIMENT_STATE_FILE}" ]; then
    if grep -q '"install_virtualization_stack": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then
      log_info '[install_virtualization_stack] Virtualization stack (Vagrant, Packer, Ruby, QEMU, bento-builder) already installed.'
      return 0
    fi
  fi

  _cli="$(resolve_provider_cli)"
  _ctx="${CORE_EXPERIMENT_RG}"
  if [ "${CORE_EXPERIMENT_PROVIDER}" = "aws" ] || [ "${CORE_EXPERIMENT_PROVIDER}" = "gcp" ]; then
    _ctx="${CORE_EXPERIMENT_LOCATION}"
  fi

  log_info '[install_virtualization_stack] Installing Vagrant, Packer, Ruby, QEMU, and Bento Builder stack via LibScript...'
  _vstack_cmd="cd ~/libscript && BENTO_REPO_URL='${CORE_EXPERIMENT_BENTO_REPO}' BENTO_BRANCH='${CORE_EXPERIMENT_BENTO_BRANCH}' BENTO_DIR='${CORE_EXPERIMENT_BENTO_DIR}' ./libscript.sh install bento-builder latest && ./libscript.sh install vagrant latest && ./libscript.sh install packer latest && ./libscript.sh install ruby latest && ./libscript.sh install qemu latest"
  "${_cli}" node exec "${CORE_EXPERIMENT_NODE}" "${_ctx}" "${_vstack_cmd}"

  write_experiment_state "install_virtualization_stack" "true"
  log_info '[install_virtualization_stack] Virtualization stack (Vagrant, Packer, Ruby, QEMU) installed.'
}

# ## deploy_vagrant_box
# Step d_deploy_vagrant_box: Idempotently builds/registers and deploys the target OS(s) as Vagrant boxes using SamuelMarks/bento.
deploy_vagrant_box() {
  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -f "${CORE_EXPERIMENT_STATE_FILE}" ]; then
    if grep -q '"deploy_vagrant_box": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && grep -q '"target_os": "'"${CORE_EXPERIMENT_TARGET_OS}"'"' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then
      log_info "[deploy_vagrant_box] Target OS Vagrant box(es) '${CORE_EXPERIMENT_TARGET_OS}' already deployed."
      return 0
    fi
  fi

  _cli="$(resolve_provider_cli)"
  _ctx="${CORE_EXPERIMENT_RG}"
  if [ "${CORE_EXPERIMENT_PROVIDER}" = "aws" ] || [ "${CORE_EXPERIMENT_PROVIDER}" = "gcp" ]; then
    _ctx="${CORE_EXPERIMENT_LOCATION}"
  fi

  _os_list=$(printf '%s' "${CORE_EXPERIMENT_TARGET_OS}" | tr ',;' '  ')
  for _tgt_os in ${_os_list}; do
    log_info "[deploy_vagrant_box] Deploying target OS '${_tgt_os}' as a Vagrant box from Bento (${CORE_EXPERIMENT_BENTO_BRANCH})..."
    _deploy_cmd="cd ~/libscript && BENTO_DIR='${CORE_EXPERIMENT_BENTO_DIR}' ./tests/register_bento_boxes.sh && if [ -d 'vagrant/${_tgt_os}' ]; then (cd 'vagrant/${_tgt_os}' && vagrant up --no-provision); fi"
    "${_cli}" node exec "${CORE_EXPERIMENT_NODE}" "${_ctx}" "${_deploy_cmd}"
  done

  write_experiment_state "deploy_vagrant_box" "true"
  log_info "[deploy_vagrant_box] Target OS Vagrant box(es) '${CORE_EXPERIMENT_TARGET_OS}' deployed."
}

# ## snapshot_vagrant_box
# Step e_snapshot_vagrant_box: Idempotently captures the clean baseline ('vanilla') snapshot of the deployed target OS Vagrant box(es).
snapshot_vagrant_box() {
  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -f "${CORE_EXPERIMENT_STATE_FILE}" ]; then
    if grep -q '"snapshot_vagrant_box": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && grep -q '"target_os": "'"${CORE_EXPERIMENT_TARGET_OS}"'"' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && grep -q '"snapshot_name": "'"${CORE_EXPERIMENT_SNAPSHOT_NAME}"'"' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then
      log_info "[snapshot_vagrant_box] Snapshot '${CORE_EXPERIMENT_SNAPSHOT_NAME}' for '${CORE_EXPERIMENT_TARGET_OS}' already exists."
      return 0
    fi
  fi

  _cli="$(resolve_provider_cli)"
  _ctx="${CORE_EXPERIMENT_RG}"
  if [ "${CORE_EXPERIMENT_PROVIDER}" = "aws" ] || [ "${CORE_EXPERIMENT_PROVIDER}" = "gcp" ]; then
    _ctx="${CORE_EXPERIMENT_LOCATION}"
  fi

  _os_list=$(printf '%s' "${CORE_EXPERIMENT_TARGET_OS}" | tr ',;' '  ')
  for _tgt_os in ${_os_list}; do
    log_info "[snapshot_vagrant_box] Creating clean snapshot '${CORE_EXPERIMENT_SNAPSHOT_NAME}' for target OS '${_tgt_os}'..."
    _snap_cmd="cd ~/libscript && if [ -d 'vagrant/${_tgt_os}' ]; then (cd 'vagrant/${_tgt_os}' && vagrant snapshot save --force '${CORE_EXPERIMENT_SNAPSHOT_NAME}' 2>/dev/null || true); fi"
    "${_cli}" node exec "${CORE_EXPERIMENT_NODE}" "${_ctx}" "${_snap_cmd}"
  done

  write_experiment_state "snapshot_vagrant_box" "true"
  log_info "[snapshot_vagrant_box] Clean snapshot '${CORE_EXPERIMENT_SNAPSHOT_NAME}' ready for '${CORE_EXPERIMENT_TARGET_OS}'."
}

# ## test_libscript_components
# Step f_test_libscript_components: Runs through every component (or filtered component/version/pkg-mgr) of LibScript on the target OS Vagrant box, restoring the clean snapshot before each component and running twice (2x) to verify strict idempotency.
test_libscript_components() {
  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -f "${CORE_EXPERIMENT_STATE_FILE}" ]; then
    if grep -q '"test_libscript_components": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && grep -q '"target_os": "'"${CORE_EXPERIMENT_TARGET_OS}"'"' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && grep -q '"components": "'"${CORE_EXPERIMENT_COMPONENTS}"'"' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && grep -q '"component_version": "'"${CORE_EXPERIMENT_COMPONENT_VERSION}"'"' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && grep -q '"pkg_mgr": "'"${CORE_EXPERIMENT_PKG_MGR}"'"' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && grep -q '"install_method": "'"${CORE_EXPERIMENT_INSTALL_METHOD}"'"' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then
      log_info "[test_libscript_components] LibScript component matrix (components=${CORE_EXPERIMENT_COMPONENTS}@${CORE_EXPERIMENT_COMPONENT_VERSION}, pkg_mgr=${CORE_EXPERIMENT_PKG_MGR:-auto}, 2x idempotency + snapshot restore) already completed on '${CORE_EXPERIMENT_TARGET_OS}'."
      return 0
    fi
  fi

  _cli="$(resolve_provider_cli)"
  _ctx="${CORE_EXPERIMENT_RG}"
  if [ "${CORE_EXPERIMENT_PROVIDER}" = "aws" ] || [ "${CORE_EXPERIMENT_PROVIDER}" = "gcp" ]; then
    _ctx="${CORE_EXPERIMENT_LOCATION}"
  fi

  _extra_matrix_flags="--version '${CORE_EXPERIMENT_COMPONENT_VERSION}' --snapshot '${CORE_EXPERIMENT_SNAPSHOT_NAME}' --idempotency-runs '${CORE_EXPERIMENT_IDEMPOTENCY_RUNS}'"
  [ -n "${CORE_EXPERIMENT_PKG_MGR}" ] && _extra_matrix_flags="${_extra_matrix_flags} --pkg-mgr '${CORE_EXPERIMENT_PKG_MGR}'"
  [ -n "${CORE_EXPERIMENT_INSTALL_METHOD}" ] && _extra_matrix_flags="${_extra_matrix_flags} --install-method '${CORE_EXPERIMENT_INSTALL_METHOD}'"
  [ -n "${CORE_EXPERIMENT_TOOLCHAIN}" ] && _extra_matrix_flags="${_extra_matrix_flags} --toolchain '${CORE_EXPERIMENT_TOOLCHAIN}'"

  _os_list=$(printf '%s' "${CORE_EXPERIMENT_TARGET_OS}" | tr ',;' '  ')
  for _tgt_os in ${_os_list}; do
    log_info "[test_libscript_components] Running LibScript component(s) '${CORE_EXPERIMENT_COMPONENTS}' (version=${CORE_EXPERIMENT_COMPONENT_VERSION}, pkg_mgr=${CORE_EXPERIMENT_PKG_MGR:-auto}, install_method=${CORE_EXPERIMENT_INSTALL_METHOD:-auto}) on Vagrant OS '${_tgt_os}' with '${CORE_EXPERIMENT_SNAPSHOT_NAME}' snapshot restore and ${CORE_EXPERIMENT_IDEMPOTENCY_RUNS}x idempotency verification..."
    _matrix_cmd="cd ~/libscript && SNAPSHOT_NAME='${CORE_EXPERIMENT_SNAPSHOT_NAME}' IDEMPOTENCY_RUNS='${CORE_EXPERIMENT_IDEMPOTENCY_RUNS}' ./tests/run_local_tests.sh --os '${_tgt_os}' --reuse-vm ${_extra_matrix_flags}"
    if [ "${CORE_EXPERIMENT_COMPONENTS}" != "all" ]; then
      _comp_args=$(printf '%s' "${CORE_EXPERIMENT_COMPONENTS}" | tr ',' ' ')
      _matrix_cmd="cd ~/libscript && SNAPSHOT_NAME='${CORE_EXPERIMENT_SNAPSHOT_NAME}' IDEMPOTENCY_RUNS='${CORE_EXPERIMENT_IDEMPOTENCY_RUNS}' ./tests/run_local_tests.sh ${_comp_args} --os '${_tgt_os}' --reuse-vm ${_extra_matrix_flags}"
    fi
    "${_cli}" node exec "${CORE_EXPERIMENT_NODE}" "${_ctx}" "${_matrix_cmd}"
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

  write_experiment_state "test_libscript_components" "true"
  log_info "[test_libscript_components] Completed LibScript component matrix on '${CORE_EXPERIMENT_TARGET_OS}'."
}

# ## run_experiments
# Runs the experimental benchmark suite (EDG backends and/or LibScript Vagrant matrix when --suite=libscript|all) on the provisioned cloud host with idempotency.
run_experiments() {
  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -f "${CORE_EXPERIMENT_STATE_FILE}" ]; then
    if grep -q '"run_experiments": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then
      log_info "[run_experiments] Experiments already completed on '${CORE_EXPERIMENT_NODE}'."
      return 0
    fi
  fi

  if [ "${CORE_EXPERIMENT_SUITE}" = "libscript" ]; then
    test_libscript_components
    write_experiment_state "run_experiments" "true"
    return 0
  fi

  _cli="$(resolve_provider_cli)"
  _ctx="${CORE_EXPERIMENT_RG}"
  if [ "${CORE_EXPERIMENT_PROVIDER}" = "aws" ] || [ "${CORE_EXPERIMENT_PROVIDER}" = "gcp" ]; then
    _ctx="${CORE_EXPERIMENT_LOCATION}"
  fi

  log_info "[run_experiments] Running EDG backend experiments on '${CORE_EXPERIMENT_NODE}' (workloads=${CORE_EXPERIMENT_WORKLOADS}, compilers=${CORE_EXPERIMENT_COMPILERS}, runs=${CORE_EXPERIMENT_RUNS})..."
  _remote_cmd="cd ~/libscript && LIBSCRIPT_BENCH_PREPARE_HOST=1 LIBSCRIPT_BENCH_DROP_CACHES=1 ./_lib/languages/edgcpp/cli.sh experiments --workloads='${CORE_EXPERIMENT_WORKLOADS}' --compilers='${CORE_EXPERIMENT_COMPILERS}' --runs='${CORE_EXPERIMENT_RUNS}'"
  "${_cli}" node exec "${CORE_EXPERIMENT_NODE}" "${_ctx}" "${_remote_cmd}"

  if [ "${DRY_RUN_MODE}" = "1" ]; then
    "${LIBSCRIPT_ROOT_DIR}/_lib/languages/edgcpp/cli.sh" experiments --workloads="${CORE_EXPERIMENT_WORKLOADS}" --compilers="${CORE_EXPERIMENT_COMPILERS}" --runs="${CORE_EXPERIMENT_RUNS}" >/dev/null 2>&1 || true
  fi

  write_experiment_state "run_experiments" "true"
  log_info "[run_experiments] Experiments completed on '${CORE_EXPERIMENT_NODE}'."
}

# ## collect_logs
# Consolidates all experimental JSON reports, Vagrant component test logs (tests_tmp/), LaTeX tables, and JSONL telemetry into a single directory on the remote host.
collect_logs() {
  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -f "${CORE_EXPERIMENT_STATE_FILE}" ]; then
    if grep -q '"collect_logs": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then
      log_info "[collect_logs] Experimental log results already consolidated in '${CORE_EXPERIMENT_REMOTE_DIR}'."
      return 0
    fi
  fi

  _cli="$(resolve_provider_cli)"
  _ctx="${CORE_EXPERIMENT_RG}"
  if [ "${CORE_EXPERIMENT_PROVIDER}" = "aws" ] || [ "${CORE_EXPERIMENT_PROVIDER}" = "gcp" ]; then
    _ctx="${CORE_EXPERIMENT_LOCATION}"
  fi

  log_info "[collect_logs] Consolidating experimental and Vagrant component logs into '${CORE_EXPERIMENT_REMOTE_DIR}' on '${CORE_EXPERIMENT_NODE}'..."
  _collect_cmd="mkdir -p ${CORE_EXPERIMENT_REMOTE_DIR}/cells ${CORE_EXPERIMENT_REMOTE_DIR}/logs ${CORE_EXPERIMENT_REMOTE_DIR}/tests_tmp && cp -rf ~/libscript/tests_tmp/* ${CORE_EXPERIMENT_REMOTE_DIR}/tests_tmp/ 2>/dev/null || true && cp -f ~/libscript/build/edgcpp-experiments-report.json ${CORE_EXPERIMENT_REMOTE_DIR}/ 2>/dev/null || true && cp -f ~/libscript/build/edgcpp-experiments-tables.tex ${CORE_EXPERIMENT_REMOTE_DIR}/ 2>/dev/null || true && cp -f ~/libscript/build/edgcpp-torture-report.json ${CORE_EXPERIMENT_REMOTE_DIR}/ 2>/dev/null || true && cp -rf ~/libscript/build/experiments/* ${CORE_EXPERIMENT_REMOTE_DIR}/cells/ 2>/dev/null || true && cp -f ~/.libscript/edgcpp/compile_events.jsonl ${CORE_EXPERIMENT_REMOTE_DIR}/logs/ 2>/dev/null || true"
  "${_cli}" node exec "${CORE_EXPERIMENT_NODE}" "${_ctx}" "${_collect_cmd}"

  if [ "${DRY_RUN_MODE}" = "1" ]; then
    _local_staging="${LIBSCRIPT_ROOT_DIR}/build/experiment_bundle"
    mkdir -p "${_local_staging}/cells" "${_local_staging}/logs" "${_local_staging}/tests_tmp"
    [ -f "${LIBSCRIPT_ROOT_DIR}/build/edgcpp-experiments-report.json" ] && cp -f "${LIBSCRIPT_ROOT_DIR}/build/edgcpp-experiments-report.json" "${_local_staging}/"
    [ -f "${LIBSCRIPT_ROOT_DIR}/build/edgcpp-experiments-tables.tex" ] && cp -f "${LIBSCRIPT_ROOT_DIR}/build/edgcpp-experiments-tables.tex" "${_local_staging}/"
    [ -f "${LIBSCRIPT_ROOT_DIR}/build/edgcpp-torture-report.json" ] && cp -f "${LIBSCRIPT_ROOT_DIR}/build/edgcpp-torture-report.json" "${_local_staging}/"
  fi

  write_experiment_state "collect_logs" "true"
  log_info "[collect_logs] Consolidated experimental logs into '${CORE_EXPERIMENT_REMOTE_DIR}'."
}

# ## pull_logs
# Transfers the consolidated experimental and Vagrant component results directory from the cloud node to CORE_EXPERIMENT_LOCAL_DIR on the current host.
pull_logs() {
  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -f "${CORE_EXPERIMENT_STATE_FILE}" ] && [ -s "${CORE_EXPERIMENT_LOCAL_DIR}/transfer-manifest.json" ]; then
    if grep -q '"pull_logs": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null && grep -q '"target_os": "'"${CORE_EXPERIMENT_TARGET_OS}"'"' "${CORE_EXPERIMENT_LOCAL_DIR}/transfer-manifest.json" 2>/dev/null; then
      log_info "[pull_logs] Experimental results directory already transferred to '${CORE_EXPERIMENT_LOCAL_DIR}'."
      return 0
    fi
  fi

  _cli="$(resolve_provider_cli)"
  _ctx="${CORE_EXPERIMENT_RG}"
  if [ "${CORE_EXPERIMENT_PROVIDER}" = "aws" ] || [ "${CORE_EXPERIMENT_PROVIDER}" = "gcp" ]; then
    _ctx="${CORE_EXPERIMENT_LOCATION}"
  fi

  mkdir -p "${CORE_EXPERIMENT_LOCAL_DIR}"
  log_info "[pull_logs] Transferring '${CORE_EXPERIMENT_REMOTE_DIR}' from '${CORE_EXPERIMENT_NODE}' to local directory '${CORE_EXPERIMENT_LOCAL_DIR}'..."
  if [ "${DRY_RUN_MODE}" = "1" ]; then
    DRY_RUN='true' "${_cli}" node scp-from "${CORE_EXPERIMENT_NODE}" "${_ctx}" "${CORE_EXPERIMENT_REMOTE_DIR}" "${CORE_EXPERIMENT_LOCAL_DIR}"
    _local_staging="${LIBSCRIPT_ROOT_DIR}/build/experiment_bundle"
    if [ -d "${_local_staging}" ]; then
      for _item in edgcpp-experiments-report.json edgcpp-experiments-tables.tex edgcpp-torture-report.json matrix_results.json; do
        [ -f "${_local_staging}/${_item}" ] && cp -f "${_local_staging}/${_item}" "${CORE_EXPERIMENT_LOCAL_DIR}/"
      done
    fi
    if [ ! -f "${CORE_EXPERIMENT_LOCAL_DIR}/edgcpp-experiments-report.json" ] && [ -f "${LIBSCRIPT_ROOT_DIR}/build/edgcpp-experiments-report.json" ]; then
      cp -f "${LIBSCRIPT_ROOT_DIR}/build/edgcpp-experiments-report.json" "${CORE_EXPERIMENT_LOCAL_DIR}/"
    fi
    if [ ! -f "${CORE_EXPERIMENT_LOCAL_DIR}/edgcpp-experiments-tables.tex" ] && [ -f "${LIBSCRIPT_ROOT_DIR}/build/edgcpp-experiments-tables.tex" ]; then
      cp -f "${LIBSCRIPT_ROOT_DIR}/build/edgcpp-experiments-tables.tex" "${CORE_EXPERIMENT_LOCAL_DIR}/"
    fi
  else
    "${_cli}" node scp-from "${CORE_EXPERIMENT_NODE}" "${_ctx}" "${CORE_EXPERIMENT_REMOTE_DIR}" "${CORE_EXPERIMENT_LOCAL_DIR}"
  fi

  cat <<EOF > "${CORE_EXPERIMENT_LOCAL_DIR}/transfer-manifest.json.tmp"
{
  "provider": "${CORE_EXPERIMENT_PROVIDER}",
  "node": "${CORE_EXPERIMENT_NODE}",
  "instance_size": "${RESOLVED_VM_SKU}",
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
  write_experiment_state "pull_logs" "true"
  log_info "[pull_logs] Transferred experimental results to '${CORE_EXPERIMENT_LOCAL_DIR}'."
}

# ## send_logs_to_host
# Step h_pull_logs (send_logs_to_host): Consolidates all remote component test logs and transfers them back to the host.
send_logs_to_host() {
  collect_logs
  pull_logs
  write_experiment_state "send_logs_to_host" "true"
}

# ## deprovision_instance
# Step i_deprovision_instance: Idempotently deprovisions the cloud host and associated network/firewall resources while preserving local transferred results.
deprovision_instance() {
  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -f "${CORE_EXPERIMENT_STATE_FILE}" ]; then
    if grep -q '"deprovision_instance": true' "${CORE_EXPERIMENT_STATE_FILE}" 2>/dev/null; then
      log_info "[deprovision_instance] Cloud host '${CORE_EXPERIMENT_NODE}' is already deprovisioned."
      return 0
    fi
  fi

  log_info "[deprovision_instance] Deprovisioning cloud host '${CORE_EXPERIMENT_NODE}' (${CORE_EXPERIMENT_PROVIDER} / ${CORE_EXPERIMENT_RG})..."
  "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/teardown_cloud.sh" --provider "${CORE_EXPERIMENT_PROVIDER}" --node "${CORE_EXPERIMENT_NODE}" --rg "${CORE_EXPERIMENT_RG}" --location "${CORE_EXPERIMENT_LOCATION}" --purge-data
  write_experiment_state "deprovision_instance" "true"
  log_info "[deprovision_instance] Cloud host '${CORE_EXPERIMENT_NODE}' deprovisioned."
}

# ## run_selected_lifecycle_steps
# Parses CORE_EXPERIMENT_STEPS and executes each requested named step (`a_provision_instance`, `b_use_bento_fork`, `c_install_virtualization_stack`, `d_deploy_vagrant_box`, `e_snapshot_vagrant_box`, `f_test_libscript_components`, `g_collect_logs`, `h_pull_logs`, `i_deprovision_instance`) in sequence.
run_selected_lifecycle_steps() {
  _norm_steps=$(printf '%s' "${CORE_EXPERIMENT_STEPS}" | tr ',;' '  ')
  for _token in ${_norm_steps}; do
    case "${_token}" in
      all|full_bento_matrix)
        provision_instance
        use_bento_fork
        install_virtualization_stack
        deploy_vagrant_box
        snapshot_vagrant_box
        test_libscript_components
        run_experiments
        send_logs_to_host
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
      run_experiments|run)
        run_experiments
        ;;
      i_deprovision_instance|deprovision_instance|deprovision|teardown|i)
        deprovision_instance
        ;;
      *)
        log_error "Unknown experiment lifecycle step: '${_token}' (valid steps: a_provision_instance, b_use_bento_fork, c_install_virtualization_stack, d_deploy_vagrant_box, e_snapshot_vagrant_box, f_test_libscript_components, g_collect_logs, h_pull_logs, i_deprovision_instance, bento_matrix, all)"
        return 1
        ;;
    esac
  done
}

run_selected_lifecycle_steps
