#!/bin/sh
# ## Overview
# Integration test suite for the unified rapid cloud and Bento multi-OS Vagrant matrix experimentation lifecycle interface (`experiment_cloud.sh`).
# ## Usage
# ./tests/test_cloud_experiment_lifecycle.sh
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

chmod +x "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/experiment_cloud.sh" "${LIBSCRIPT_ROOT_DIR}/cli/commands/cloud/experiment.sh"

# ## verify_step_by_step_execution
# Verifies that provision_instance, run_experiments, collect_logs (move_to_log_dir), pull_logs (move_log_dir_to_host), and deprovision_instance can each be executed one at a time with idempotency on rerun.
verify_step_by_step_execution() {
  _t_dir="${TMPDIR:-/tmp}/test_cloud_exp_step_$$"
  _st_file="${_t_dir}/state.json"
  _loc_dir="${_t_dir}/transferred_results"
  rm -rf "${_t_dir}"
  mkdir -p "${_t_dir}"

  # a_provision_instance / provision_instance (default '160-vCPU Standard_D160ads_v7' on azure)
  DRY_RUN=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment provision_instance --state-file="${_st_file}" --local-dir="${_loc_dir}"
  [ -s "${_st_file}" ]
  grep -q '"provider": "azure"' "${_st_file}"
  grep -q '"requested_size": "160-vCPU Standard_D160ads_v7"' "${_st_file}"
  grep -q '"resolved_sku": "Standard_D160ads_v7"' "${_st_file}"
  grep -q '"provision_instance": true' "${_st_file}"
  grep -q '"a_provision_instance": true' "${_st_file}"

  # Re-run provision_instance to verify idempotency
  _out0="$(LIBSCRIPT_LOG_LEVEL=0 DRY_RUN=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment provision_instance --state-file="${_st_file}" --local-dir="${_loc_dir}" 2>&1)"
  printf '%s
' "${_out0}" | grep -q "already provisioned"

  # run_experiments
  DRY_RUN=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment run_experiments --workloads="sqlite3" --compilers="EDG-LLVM" --runs=1 --state-file="${_st_file}" --local-dir="${_loc_dir}"
  grep -q '"run_experiments": true' "${_st_file}"

  # g_collect_logs / collect_logs (also supports alias move_to_log_dir)
  DRY_RUN=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment collect_logs --state-file="${_st_file}" --local-dir="${_loc_dir}"
  grep -q '"collect_logs": true' "${_st_file}"
  grep -q '"g_collect_logs": true' "${_st_file}"
  grep -q '"move_to_log_dir": true' "${_st_file}"

  # h_pull_logs / pull_logs (also supports alias move_log_dir_to_host)
  DRY_RUN=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment pull_logs --state-file="${_st_file}" --local-dir="${_loc_dir}"
  grep -q '"pull_logs": true' "${_st_file}"
  grep -q '"h_pull_logs": true' "${_st_file}"
  grep -q '"move_log_dir_to_host": true' "${_st_file}"
  [ -s "${_loc_dir}/transfer-manifest.json" ]
  grep -q '"instance_size": "Standard_D160ads_v7"' "${_loc_dir}/transfer-manifest.json"

  # i_deprovision_instance / deprovision_instance
  DRY_RUN=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment deprovision_instance --state-file="${_st_file}" --local-dir="${_loc_dir}"
  grep -q '"deprovision_instance": true' "${_st_file}"
  grep -q '"i_deprovision_instance": true' "${_st_file}"
  [ -s "${_loc_dir}/transfer-manifest.json" ]

  rm -rf "${_t_dir}"
}

# ## verify_bento_multi_os_experiment_runner
# Verifies lexicographically ordered named steps (a_provision_instance .. i_deprovision_instance) and testing multiple target OSs between provision and deprovision.
verify_bento_multi_os_experiment_runner() {
  _t_dir="${TMPDIR:-/tmp}/test_bento_exp_$$"
  _st_file="${_t_dir}/bento_state.json"
  _loc_dir="${_t_dir}/bento_results"
  rm -rf "${_t_dir}"
  mkdir -p "${_t_dir}"

  # a_provision_instance: Provision instance once
  DRY_RUN=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment a_provision_instance --state-file="${_st_file}" --local-dir="${_loc_dir}"
  grep -q '"a_provision_instance": true' "${_st_file}"

  # b_use_bento_fork: Use SamuelMarks/bento fork at multi-os-qemu-aarch64 branch
  DRY_RUN=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment b_use_bento_fork --state-file="${_st_file}" --local-dir="${_loc_dir}"
  grep -q '"b_use_bento_fork": true' "${_st_file}"
  grep -q '"bento_repo": "https://github.com/SamuelMarks/bento.git"' "${_st_file}"
  grep -q '"bento_branch": "multi-os-qemu-aarch64"' "${_st_file}"

  # c_install_virtualization_stack: Install Vagrant, Packer, Ruby, QEMU, etc.
  DRY_RUN=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment c_install_virtualization_stack --state-file="${_st_file}" --local-dir="${_loc_dir}"
  grep -q '"c_install_virtualization_stack": true' "${_st_file}"

  # d_deploy_vagrant_box .. h_pull_logs on OS #1 (alpine-3.24)
  DRY_RUN=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment --steps="d_deploy_vagrant_box,e_snapshot_vagrant_box,f_test_libscript_components,g_collect_logs,h_pull_logs" --target-os="alpine-3.24" --state-file="${_st_file}" --local-dir="${_loc_dir}"
  grep -q '"d_deploy_vagrant_box": true' "${_st_file}"
  grep -q '"e_snapshot_vagrant_box": true' "${_st_file}"
  grep -q '"f_test_libscript_components": true' "${_st_file}"
  grep -q '"g_collect_logs": true' "${_st_file}"
  grep -q '"h_pull_logs": true' "${_st_file}"
  grep -q '"idempotency_runs": 2' "${_st_file}"
  grep -q '"target_os": "alpine-3.24"' "${_loc_dir}/transfer-manifest.json"

  # bento_matrix on OS #2 (debian-13) before deprovisioning (b_use_bento_fork and c_install_virtualization_stack are idempotent no-ops)
  DRY_RUN=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment bento_matrix --target-os="debian-13" --state-file="${_st_file}" --local-dir="${_loc_dir}"
  grep -q '"target_os": "debian-13"' "${_st_file}"
  grep -q '"target_os": "debian-13"' "${_loc_dir}/transfer-manifest.json"

  # i_deprovision_instance: Deprovision instance after testing multiple OSs
  DRY_RUN=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment i_deprovision_instance --state-file="${_st_file}" --local-dir="${_loc_dir}"
  grep -q '"i_deprovision_instance": true' "${_st_file}"

  # Verify concise single-character phase aliases (a, 0..5, i) as positional and --steps tokens
  _st_short="${_t_dir}/short_state.json"
  DRY_RUN=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment a --state-file="${_st_short}" --local-dir="${_loc_dir}"
  grep -q '"provision_instance": true' "${_st_short}"
  DRY_RUN=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment --steps="0,1,2,3,4,5" --target-os="alpine-3.24" --state-file="${_st_short}" --local-dir="${_loc_dir}"
  grep -q '"send_logs_to_host": true' "${_st_short}"
  DRY_RUN=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment i --state-file="${_st_short}" --local-dir="${_loc_dir}"
  grep -q '"deprovision_instance": true' "${_st_short}"

  rm -rf "${_t_dir}"
}

# ## verify_single_component_version_pkg_mgr_execution
# Verifies testing a single component-version and package-manager or source toolchain on one OS using named steps.
verify_single_component_version_pkg_mgr_execution() {
  _t_dir="${TMPDIR:-/tmp}/test_single_comp_exp_$$"
  _st_file="${_t_dir}/single_state.json"
  _loc_dir="${_t_dir}/single_results"
  rm -rf "${_t_dir}"
  mkdir -p "${_t_dir}"

  # Test single component@version with a specific package manager on debian-13
  DRY_RUN=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment bento_matrix --target-os="debian-13" --component="postgres@16.2" --pkg-mgr="apt-get" --state-file="${_st_file}" --local-dir="${_loc_dir}"
  grep -q '"target_os": "debian-13"' "${_st_file}"
  grep -q '"components": "postgres"' "${_st_file}"
  grep -q '"component_version": "16.2"' "${_st_file}"
  grep -q '"pkg_mgr": "apt-get"' "${_st_file}"
  grep -q '"install_method": "system"' "${_st_file}"
  grep -q '"component_version": "16.2"' "${_loc_dir}/transfer-manifest.json"
  grep -q '"pkg_mgr": "apt-get"' "${_loc_dir}/transfer-manifest.json"

  # Test single component with explicit --version, --from-source, and --toolchain=edgcpp on alpine-3.24
  DRY_RUN=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment --steps="f_test_libscript_components,g_collect_logs,h_pull_logs" --target-os="alpine-3.24" --component="sqlite" --version="3.46.1" --from-source --toolchain="edgcpp" --state-file="${_st_file}" --local-dir="${_loc_dir}"
  grep -q '"target_os": "alpine-3.24"' "${_st_file}"
  grep -q '"components": "sqlite"' "${_st_file}"
  grep -q '"component_version": "3.46.1"' "${_st_file}"
  grep -q '"install_method": "from-source"' "${_st_file}"
  grep -q '"toolchain": "edgcpp"' "${_st_file}"

  rm -rf "${_t_dir}"
}

# ## verify_combined_all_steps_execution
# Verifies that all named steps can be executed together in a single invocation.
verify_combined_all_steps_execution() {
  _t_dir="${TMPDIR:-/tmp}/test_cloud_exp_all_$$"
  _st_file="${_t_dir}/state_all.json"
  _loc_dir="${_t_dir}/results_all"
  rm -rf "${_t_dir}"
  mkdir -p "${_t_dir}"

  DRY_RUN=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment --steps="provision_instance,run_experiments,move_to_log_dir,move_log_dir_to_host,deprovision_instance" --workloads="sqlite3" --compilers="EDG-LLVM" --runs=1 --state-file="${_st_file}" --local-dir="${_loc_dir}"
  [ -s "${_st_file}" ]
  grep -q '"resolved_sku": "Standard_D160ads_v7"' "${_st_file}"
  grep -q '"run_experiments": true' "${_st_file}"
  grep -q '"collect_logs": true' "${_st_file}"
  grep -q '"pull_logs": true' "${_st_file}"
  grep -q '"deprovision_instance": true' "${_st_file}"
  [ -s "${_loc_dir}/transfer-manifest.json" ]

  rm -rf "${_t_dir}"
}

# ## verify_libtpu_dual_isa_and_tpu_vm_campaign
# Verifies `--suite=libtpu` Dual-ISA (`linux_x64` + `macos_arm64`) multi-host artifact consolidation, `gcp-tpu-vm` routing, and LaTeX macro emission.
verify_libtpu_dual_isa_and_tpu_vm_campaign() {
  _t_dir="${TMPDIR:-/tmp}/test_cloud_libtpu_$$"
  _st_x64="${_t_dir}/state_x64.json"
  _st_tpu="${_t_dir}/state_tpu.json"
  _loc_dir="${_t_dir}/consolidated_results"
  rm -rf "${_t_dir}"
  mkdir -p "${_t_dir}"

  # Host 1: Dedicated Linux x86_64 node
  DRY_RUN=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment libtpu_campaign \
    --suite='libtpu' \
    --host-arch='linux_x64' \
    --subsuites='E0,E1,E2,E3,E4,E5,E6,E7,E8' \
    --warmup=1 \
    --trials=3 \
    --state-file="${_st_x64}" \
    --local-dir="${_loc_dir}"

  [ -s "${_loc_dir}/results/e2_startup_linux_x64.json" ]
  [ -s "${_loc_dir}/results/generated_metrics.tex" ]

  # Host 2: Second architecture tag + gcp-tpu-vm provider without clobbering linux_x64 artifacts
  DRY_RUN=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment libtpu_campaign \
    --suite='libtpu' \
    --provider='gcp-tpu-vm' \
    --size='v6e-8' \
    --location='us-east5-a' \
    --rg='libtpu-eval-proj' \
    --host-arch='macos_arm64' \
    --subsuites='E0,E2,E8' \
    --warmup=1 \
    --trials=3 \
    --state-file="${_st_tpu}" \
    --local-dir="${_loc_dir}"

  [ -s "${_loc_dir}/results/e2_startup_linux_x64.json" ]
  [ -s "${_loc_dir}/results/e2_startup_macos_arm64.json" ]
  grep -q '"provider": "gcp-tpu-vm"' "${_st_tpu}"
  grep -q '"emit_latex_and_verify_pdf": true' "${_st_tpu}"

  rm -rf "${_t_dir}"
}

verify_step_by_step_execution
verify_bento_multi_os_experiment_runner
verify_single_component_version_pkg_mgr_execution
verify_combined_all_steps_execution
verify_libtpu_dual_isa_and_tpu_vm_campaign
printf '[PASS] Named rapid cloud experimentation lifecycle tests succeeded!\n'
