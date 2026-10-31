#!/bin/sh
# ## Overview
# Multi-distro Vagrant QEMU verification harness for Linux kernel compilation
# across gcc, clang (expected failure), and edgcpp-compiler variants
# (edgcpp+gcc, edgcpp+llvm, edgcpp+llvm+gcc) on Debian 13, RockyLinux 10.2,
# and Alpine Linux 3.24 boxes sourced from ../bento (without Docker).
#
# ## Usage
# ./tests/test_kernel_edgcpp_vagrant_matrix.sh [--distro=debian-13|rockylinux-10.2|alpine-3.24|all] [--versions="5.15.167 6.6.52"] [--keep-vm]

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

DISTROS="${LINUX_COMPARE_DISTROS:-debian-13 rockylinux-10.2 alpine-3.24}"
VERSIONS="${LINUX_COMPARE_VERSIONS:-4.19.322 5.4.284 5.10.226 5.15.167 6.1.112 6.6.52 6.11.2 6.12.1}"
COMPILERS="${LINUX_COMPARE_COMPILERS:-gcc clang edgcpp+gcc edgcpp+llvm edgcpp+llvm+gcc:gcc edgcpp+llvm+gcc:llvm}"
KEEP_VM="${KEEP_VM:-0}"
LOCAL_FALLBACK="${LINUX_VAGRANT_LOCAL_FALLBACK:-1}"

# ## show_help
# Prints CLI usage and supported flags for the Vagrant kernel matrix runner.
show_help() {
  printf 'Usage: %s [--distro=debian-13|rockylinux-10.2|alpine-3.24|all] [--versions="..."] [--compilers="..."] [--keep-vm]
' "${0}"
}

for _arg in "$@"; do
  case "${_arg}" in
    --help|-h)
      show_help
      exit 0
      ;;
    --distro=*)
      _distro_val="${_arg#*=}"
      if [ "${_distro_val}" = "all" ]; then
        DISTROS="debian-13 rockylinux-10.2 alpine-3.24"
      else
        DISTROS="$(printf '%s' "${_distro_val}" | tr ',' ' ')"
      fi
      ;;
    --versions=*)
      VERSIONS="$(printf '%s' "${_arg#*=}" | tr ',' ' ')"
      ;;
    --compilers=*)
      COMPILERS="$(printf '%s' "${_arg#*=}" | tr ',' ' ')"
      ;;
    --keep-vm)
      KEEP_VM=1
      ;;
    --no-local-fallback)
      LOCAL_FALLBACK=0
      ;;
  esac
done

# ## ensure_bento_boxes_registered
# Registers built Vagrant boxes from ../bento/builds/build_complete/ when available.
ensure_bento_boxes_registered() {
  if [ -x "${LIBSCRIPT_ROOT_DIR}/tests/register_bento_boxes.sh" ]; then
    unset SCRIPT_NAME || true
    "${LIBSCRIPT_ROOT_DIR}/tests/register_bento_boxes.sh" || true
  fi
}

# ## run_distro_vagrant_or_host
# Runs the multi-version kernel compiler comparison inside a Vagrant Linux VM (or host fallback) and syncs diagnostic logs back to build/kernel/vagrant-<distro>/.
run_distro_vagrant_or_host() {
  _distro="${1}"
  _vdir="${LIBSCRIPT_ROOT_DIR}/vagrant/${_distro}"
  _host_out="${LIBSCRIPT_ROOT_DIR}/build/kernel/vagrant-${_distro}"
  mkdir -p "${_host_out}"

  _box_name="bento/${_distro}"
  _ran_in_vm=0
  _distro_rc=0

  if command -v vagrant >/dev/null 2>&1 && [ -d "${_vdir}" ] && [ "${LIBSCRIPT_VAGRANT_SKIP_VM:-0}" != "1" ]; then
    if vagrant box list 2>/dev/null | grep -q "^${_box_name} "; then
      printf '[VAGRANT] Booting %s (%s) via QEMU provider...
' "${_distro}" "${_box_name}"
      (
        cd "${_vdir}"
        vagrant up --provider=qemu || exit 1
        vagrant rsync || true
        vagrant ssh -c "cd /opt/repos/libscript && FORCE_REBUILD=1 ./_lib/kernel/linux/compare_compilers.sh --compilers='${COMPILERS}' --versions='${VERSIONS}'"
      ) || _distro_rc=$?
      _ran_in_vm=1

      (
        cd "${_vdir}"
        vagrant ssh -c "cd /opt/repos/libscript && tar -czf - build/kernel-compiler-comparison.json build/kernel/logs 2>/dev/null" > "${_host_out}/guest-logs.tar.gz" 2>/dev/null || true
      )
      if [ -s "${_host_out}/guest-logs.tar.gz" ]; then
        tar -xzf "${_host_out}/guest-logs.tar.gz" -C "${_host_out}" 2>/dev/null || true
      fi

      if [ "${KEEP_VM}" != "1" ]; then
        (cd "${_vdir}" && vagrant halt 2>/dev/null || true)
      fi
    fi
  fi

  if [ "${_ran_in_vm}" = "0" ]; then
    if [ "${LOCAL_FALLBACK}" = "1" ]; then
      printf '[INFO]    Vagrant box %s not active on host; executing comparison matrix locally for %s verification...
' "${_box_name}" "${_distro}"
      unset SCRIPT_NAME || true
      "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/linux/compare_compilers.sh" --compilers="${COMPILERS}" --versions="${VERSIONS}" || _distro_rc=$?
      cp "${LIBSCRIPT_ROOT_DIR}/build/kernel-compiler-comparison.json" "${_host_out}/kernel-compiler-comparison.json" 2>/dev/null || true
      if [ -d "${LIBSCRIPT_ROOT_DIR}/build/kernel/logs" ]; then
        cp -R "${LIBSCRIPT_ROOT_DIR}/build/kernel/logs" "${_host_out}/" 2>/dev/null || true
      fi
    else
      printf '[FAIL]    Vagrant box %s is not registered and local fallback is disabled.
' "${_box_name}" >&2
      _distro_rc=1
    fi
  fi

  _status_str='PASS'
  if [ "${_distro_rc}" -ne 0 ]; then
    _status_str='FAIL'
    MATRIX_FAILURES=$((MATRIX_FAILURES + 1))
  fi

  printf '| %-16s | %-12s | %-10s | %-44s |
' "${_distro}" "${_box_name}" "${_status_str}" "${_host_out}" >> "${VM_TABLE_FILE}"
  if [ "${VM_FIRST_JSON}" = "0" ]; then
    printf ',
' >> "${VM_JSON_FILE}"
  fi
  VM_FIRST_JSON=0
  cat <<EOF >> "${VM_JSON_FILE}"
    {
      "distro": "${_distro}",
      "vagrant_box": "${_box_name}",
      "executed_in_vm": ${_ran_in_vm},
      "status": "${_status_str}",
      "exit_code": ${_distro_rc},
      "artifacts_dir": "${_host_out}"
    }
EOF
}

mkdir -p "${LIBSCRIPT_ROOT_DIR}/build"
REPORT_FILE="${LIBSCRIPT_ROOT_DIR}/build/kernel-vagrant-matrix-report.json"
VM_TABLE_FILE="${TMPDIR:-/tmp}/vagrant_kernel_matrix_table_$$"
VM_JSON_FILE="${TMPDIR:-/tmp}/vagrant_kernel_matrix_json_$$"
: > "${VM_TABLE_FILE}"
: > "${VM_JSON_FILE}"
VM_FIRST_JSON=1
MATRIX_FAILURES=0

ensure_bento_boxes_registered

for _d in ${DISTROS}; do
  run_distro_vagrant_or_host "${_d}"
done

cat <<EOF > "${REPORT_FILE}.tmp"
{
  "suite": "kernel-edgcpp-vagrant-matrix",
  "distros_tested": "${DISTROS}",
  "kernel_versions": "${VERSIONS}",
  "compilers": "${COMPILERS}",
  "failures": ${MATRIX_FAILURES},
  "results": [
$(cat "${VM_JSON_FILE}")
  ]
}
EOF
mv -f "${REPORT_FILE}.tmp" "${REPORT_FILE}"

printf '
================================================================================================
'
printf ' VAGRANT MULTI-DISTRO (../bento) LINUX KERNEL & EDGCPP COMPILER MATRIX SUMMARY
'
printf '================================================================================================
'
printf '| Distro           | Vagrant Box  | Status     | Host Synced Logs & Reproducers               |
'
printf '|------------------|--------------|------------|----------------------------------------------|
'
cat "${VM_TABLE_FILE}"
printf '================================================================================================
'
printf ' Matrix Report: %s
' "${REPORT_FILE}"

rm -f "${VM_TABLE_FILE}" "${VM_JSON_FILE}"
[ "${MATRIX_FAILURES}" -eq 0 ]
