#!/bin/sh
# ## Overview
# Unified 6-OS test matrix driver and per-component 4-stage lifecycle contract probe.
# Provides shared functions for VM snapshot management (`vanilla`), manifest OS/architecture
# filtering, 4-stage component verification (`install` -> `test` -> `which/env/ls` ->
# `2x idempotent install+test` -> `uninstall`), and live `tests/update_results.sh` updates.
#
# ## Usage
# . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/test_matrix_driver.sh"

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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

# ## matrix_driver_find_disk_image
# Locates the active QEMU qcow2 disk image inside a Vagrant environment directory.
matrix_driver_find_disk_image() {
  _vdir="$1"
  set +f
  for _id_file in "${_vdir}"/.vagrant/machines/*/qemu/id; do
    if [ -f "${_id_file}" ]; then
      _id=$(cat "${_id_file}")
      _m_dir=$(dirname "${_id_file}")
      _img="${_m_dir}/${_id}/linked-box.img"
      if [ -f "${_img}" ]; then
        set -f
        printf '%s
' "${_img}"
        return 0
      fi
    fi
  done
  set -f
  return 1
}

# ## matrix_driver_restore_vanilla_snapshot
# Restores the baseline `vanilla` QEMU snapshot before running a component test.
matrix_driver_restore_vanilla_snapshot() {
  _vdir="$1"
  _img=$(matrix_driver_find_disk_image "${_vdir}" || true)
  if [ -n "${_img}" ] && command -v qemu-img >/dev/null 2>&1; then
    if qemu-img snapshot -U -l "${_img}" 2>/dev/null | grep -q "vanilla"; then
      (cd "${_vdir}" && vagrant halt) || true
      qemu-img snapshot -a vanilla "${_img}"
      (cd "${_vdir}" && vagrant up --no-provision)
      return 0
    fi
  fi
  return 1
}

# ## matrix_driver_check_manifest_support
# Evaluates a component manifest.json against target OS, OS family, and CPU architecture.
matrix_driver_check_manifest_support() {
  _manifest="$1"
  _target_os="$2"
  _target_family="$3"
  _target_arch="${4:-aarch64}"

  if [ ! -f "${_manifest}" ]; then
    printf 'yes
'
    return 0
  fi

  awk -v os="${_target_os}" -v fam="${_target_family}" -v arch="${_target_arch}" '
    BEGIN {
      in_bl=0; in_wl=0; has_wl=0; wl_match=0;
      in_abl=0; in_awl=0; has_awl=0; awl_match=0;
      result="yes"; q="""
    }
    /"os_blacklist"\s*:/ {
      in_bl=1; in_wl=0
      if ($0 ~ q os q || (fam != "" && $0 ~ q fam q)) { result="no"; exit }
      if ($0 ~ /\]/) { in_bl=0 }
      next
    }
    /"os_whitelist"\s*:/ {
      in_wl=1; in_bl=0; has_wl=1
      if ($0 ~ q os q || (fam != "" && $0 ~ q fam q) || $0 ~ q "all" q) { wl_match=1 }
      if ($0 ~ /\]/) { in_wl=0 }
      next
    }
    /"arch_blacklist"\s*:/ {
      in_abl=1; in_awl=0
      if ($0 ~ q arch q) { result="no"; exit }
      if ($0 ~ /\]/) { in_abl=0 }
      next
    }
    /"arch_whitelist"\s*:/ {
      in_awl=1; in_abl=0; has_awl=1
      if ($0 ~ q arch q || $0 ~ q "all" q) { awl_match=1 }
      if ($0 ~ /\]/) { in_awl=0 }
      next
    }
    in_bl {
      if ($0 ~ q os q || (fam != "" && $0 ~ q fam q)) { result="no"; exit }
      if ($0 ~ /\]/) { in_bl=0 }
    }
    in_wl {
      if ($0 ~ q os q || (fam != "" && $0 ~ q fam q) || $0 ~ q "all" q) { wl_match=1 }
      if ($0 ~ /\]/) { in_wl=0 }
    }
    in_abl {
      if ($0 ~ q arch q) { result="no"; exit }
      if ($0 ~ /\]/) { in_abl=0 }
    }
    in_awl {
      if ($0 ~ q arch q || $0 ~ q "all" q) { awl_match=1 }
      if ($0 ~ /\]/) { in_awl=0 }
    }
    END {
      if (result == "yes" && has_wl && !wl_match) { result="no" }
      if (result == "yes" && has_awl && !awl_match) { result="no" }
      print result
    }
  ' "${_manifest}"
}

# ## matrix_driver_build_4stage_probe
# Builds the 4-stage contract command string for executing inside a POSIX guest VM.
matrix_driver_build_4stage_probe() {
  _target="$1"
  _guest_root="${2:-/opt/repos/libscript}"
  printf 'export LIBSCRIPT_ROOT_DIR="%s"; timeout 600 "%s/libscript.sh" install "%s" && timeout 120 "%s/libscript.sh" test "%s" && "%s/libscript.sh" which "%s" latest >/dev/null 2>&1 || true; "%s/libscript.sh" env "%s" latest >/dev/null 2>&1 || true; "%s/libscript.sh" ls "%s" >/dev/null 2>&1 || true; timeout 600 "%s/libscript.sh" install "%s" && timeout 120 "%s/libscript.sh" test "%s"\n' \
    "${_guest_root}" "${_guest_root}" "${_target}" "${_guest_root}" "${_target}" \
    "${_guest_root}" "${_target}" "${_guest_root}" "${_target}" "${_guest_root}" "${_target}" \
    "${_guest_root}" "${_target}" "${_guest_root}" "${_target}"
}
