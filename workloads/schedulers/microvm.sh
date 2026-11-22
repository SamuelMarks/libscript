#!/bin/sh
# ## Overview
# Tier 4 MicroVM & Unikernel Scheduler targeting Firecracker, Cloud-Hypervisor, and Solo5.
#
# ## Usage
# ./workloads/schedulers/microvm.sh <compile|submit|status|logs|stop|destroy> <payload.json_or_id> [--vmm <firecracker|cloud-hypervisor|solo5>]

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

# ## compile_microvm_spec
# Emits Firecracker, Cloud-Hypervisor, or Solo5 tender configuration JSON from payload.json.
compile_microvm_spec() {
  pf="$1"
  vmm="${2:-firecracker}"
  jq --arg vmm "$vmm" '{
    vmm: $vmm,
    "boot-source": {
      kernel_image_path: (.artifact.kernel_path // (if .artifact.profile_ref then ("/var/lib/libscript/images/" + .artifact.profile_ref + ".img") else "/var/lib/libscript/vmlinux.bin" end)),
      boot_args: "console=ttyS0 reboot=k panic=1 pci=off"
    },
    "machine-config": {
      vcpu_count: (.resources.cpu_cores | floor),
      mem_size_mib: .resources.memory_mb
    }
  }' "$pf"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 <compile|submit|status|logs|stop|destroy> <payload.json_or_id> [--vmm <vmm>]"
  exit 0
fi

ACTION="${1:-compile}"
TARGET="${2:-}"
VMM="${LIBSCRIPT_VMM:-firecracker}"
if [ "${3:-}" = "--vmm" ]; then
  VMM="${4:-firecracker}"
fi

case "$ACTION" in
  compile) compile_microvm_spec "$TARGET" "$VMM" ;;
  submit)
    _mvm_dir="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript-state}/schedulers/microvm"
    mkdir -p "$_mvm_dir"
    _mvm_id=$(basename -- "$TARGET" .json)
    [ -f "$TARGET" ] && _mvm_id=$(jq -r '.name // "microvm"' "$TARGET")
    compile_microvm_spec "$TARGET" "$VMM" > "${_mvm_dir}/${_mvm_id}.spec.json"
    if [ "${LIBSCRIPT_SCHEDULER_LIVE:-0}" = "1" ] && command -v "$VMM" >/dev/null 2>&1; then
      case "$VMM" in
        firecracker)
          rm -f "${_mvm_dir}/${_mvm_id}.sock"
          firecracker --api-sock "${_mvm_dir}/${_mvm_id}.sock" --config-file "${_mvm_dir}/${_mvm_id}.spec.json" > "${_mvm_dir}/${_mvm_id}.log" 2>&1 &
          printf '%s\n' "$!" > "${_mvm_dir}/${_mvm_id}.pid"
          ;;
        cloud-hypervisor)
          cloud-hypervisor --api-socket "${_mvm_dir}/${_mvm_id}.sock" > "${_mvm_dir}/${_mvm_id}.log" 2>&1 &
          printf '%s\n' "$!" > "${_mvm_dir}/${_mvm_id}.pid"
          ;;
      esac
    fi
    printf '{"scheduler":"microvm","vmm":"%s","action":"submit","workload":"%s","state":"RUNNING","status":"ok"}\n' "$VMM" "$TARGET" | tee "${_mvm_dir}/${_mvm_id}.state.json"
    ;;
  status|logs|stop|destroy)
    _mvm_dir="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript-state}/schedulers/microvm"
    _mvm_id=$(basename -- "$TARGET" .json)
    [ -f "$TARGET" ] && _mvm_id=$(jq -r '.name // "microvm"' "$TARGET")
    if [ "$ACTION" = "stop" ] || [ "$ACTION" = "destroy" ]; then
      if [ -f "${_mvm_dir}/${_mvm_id}.pid" ]; then
        kill "$(cat "${_mvm_dir}/${_mvm_id}.pid")" 2>/dev/null || true
        rm -f "${_mvm_dir}/${_mvm_id}.pid" "${_mvm_dir}/${_mvm_id}.sock"
      fi
      [ "$ACTION" = "destroy" ] && rm -f "${_mvm_dir}/${_mvm_id}.state.json" "${_mvm_dir}/${_mvm_id}.spec.json"
    fi
    printf '{"scheduler":"microvm","vmm":"%s","action":"%s","workload":"%s","status":"ok"}\n' "$VMM" "$ACTION" "$TARGET"
    ;;
  *) exit 1 ;;
esac
