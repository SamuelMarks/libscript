#!/bin/sh
# ## Overview
# Provider-agnostic Vagrant and Bento fork substrate (`Step 0`) managing boxes, multi-provider workspaces, and clean `"vanilla"` snapshots.
# ## Usage
# ./experiments/_common/vagrant_substrate.sh <resolve-os|resolve-provider|provision|boot|snapshot-ensure|snapshot-restore|assert-clean|exec|upload|download|teardown> [args...]
set -feu
_vs_caller_this="${THIS_FILE:-}"; _vs_caller_dir="${SCRIPT_DIR:-}"
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
    if [ -n "$_vs_caller_this" ]; then THIS_FILE="$_vs_caller_this"; fi; if [ -n "$_vs_caller_dir" ]; then SCRIPT_DIR="$_vs_caller_dir"; fi
    unset SCRIPT_NAME || true; if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

for _vs_lib in 'engine/common/os_info.sh' 'engine/common/pkg_mgr.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_vs_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "$SCRIPT_NAME"
done
unset SCRIPT_NAME || true

# ## vs_resolve_target_os
# Normalizes shorthand OS names into canonical Bento box OS slugs while preserving explicit slugs.
vs_resolve_target_os() {
  _vs_raw_os="${1:-windows-11}"
  case "$_vs_raw_os" in
    windows|win|win11) printf '%s\n' 'windows-11' ;;
    debian) printf '%s\n' 'debian-13' ;;
    rocky|rockylinux|rhel) printf '%s\n' 'rockylinux-10.2' ;;
    freebsd) printf '%s\n' 'freebsd-15.1' ;;
    macos|darwin) printf '%s\n' 'macos-14-arm64' ;;
    alpine) printf '%s\n' 'alpine-3.24' ;;
    illumos|omnios) printf '%s\n' 'omnios' ;;
    *) printf '%s\n' "$_vs_raw_os" ;;
  esac
}

# ## vs_guest_os_family
# Classifies a target Bento OS slug into windows, macos, linux, bsd, or posix.
vs_guest_os_family() {
  _vs_gos="${1:-windows-11}"
  case "$_vs_gos" in
    windows*|win*) printf '%s\n' 'windows' ;;
    macos*|darwin*) printf '%s\n' 'macos' ;;
    freebsd*|openbsd*|netbsd*) printf '%s\n' 'bsd' ;;
    alpine*|debian*|ubuntu*|rocky*|alma*|fedora*|rhel*|arch*|suse*) printf '%s\n' 'linux' ;;
    *) printf '%s\n' 'posix' ;;
  esac
}

# ## vs_resolve_provider
# Resolves `auto` or validates an explicit Vagrant provider across virtualbox, libvirt, hyperv, vmware_desktop, qemu, and utm.
vs_resolve_provider() {
  _vs_req_prov="${1:-auto}"
  case "$_vs_req_prov" in
    virtualbox|libvirt|hyperv|vmware_desktop|qemu|utm)
      printf '%s\n' "$_vs_req_prov"
      return 0
      ;;
    auto|'')
      if command -v VBoxManage >/dev/null 2>&1; then
        printf '%s\n' 'virtualbox'
      elif [ "${UNAME_LOWER:-}" = 'darwin' ] && command -v utmctl >/dev/null 2>&1; then
        printf '%s\n' 'utm'
      elif [ "${UNAME_LOWER:-}" = 'darwin' ] && command -v qemu-system-aarch64 >/dev/null 2>&1; then
        printf '%s\n' 'qemu'
      elif command -v virsh >/dev/null 2>&1; then
        printf '%s\n' 'libvirt'
      elif command -v vmrun >/dev/null 2>&1; then
        printf '%s\n' 'vmware_desktop'
      elif command -v qemu-system-x86_64 >/dev/null 2>&1; then
        printf '%s\n' 'qemu'
      else
        printf '%s\n' 'virtualbox'
      fi
      return 0
      ;;
    *)
      printf '[ERROR] Unsupported Vagrant provider: %s\n' "$_vs_req_prov" >&2
      return 1
      ;;
  esac
}

# ## vs_register_bento_box
# Idempotently ensures `<bento_prefix>/<target_os>` is registered in Vagrant from local Bento builds, URL template, or registry.
vs_register_bento_box() {
  _vs_prefix="${1:-bento}"
  _vs_os=$(vs_resolve_target_os "${2:-windows-11}")
  _vs_prov=$(vs_resolve_provider "${3:-auto}")
  _vs_bento_dir="${4:-}"
  _vs_url_tpl="${5:-}"
  _vs_box_name="${_vs_prefix}/${_vs_os}"

  if ! command -v vagrant >/dev/null 2>&1; then
    printf '[PROVISION] Installing Vagrant via LibScript...\n' >&2
    STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install vagrant latest
  fi

  _vs_box_list=$(vagrant box list 2>/dev/null || true)
  if printf '%s\n' "$_vs_box_list" | grep -F "${_vs_box_name} " | grep -F "(${_vs_prov}," >/dev/null 2>&1; then
    printf '[SKIP] Vagrant box %s (%s) is already registered.\n' "$_vs_box_name" "$_vs_prov" >&2
    printf '%s\n' "$_vs_box_name"
    return 0
  fi

  if [ -z "$_vs_bento_dir" ] && [ -d "${LIBSCRIPT_ROOT_DIR}/../bento/builds/build_complete" ]; then
    _vs_bento_dir="${LIBSCRIPT_ROOT_DIR}/../bento"
  fi

  if [ -n "$_vs_bento_dir" ] && [ -d "${_vs_bento_dir}/builds/build_complete" ]; then
    set +f
    for _vs_cand in "${_vs_bento_dir}/builds/build_complete/${_vs_os}"*".${_vs_prov}.box" "${_vs_bento_dir}/builds/build_complete/${_vs_os}"*".box"; do
      if [ -f "$_vs_cand" ]; then
        printf '[BOX] Registering local Bento fork box %s from %s...\n' "$_vs_box_name" "$_vs_cand" >&2
        vagrant box add --name "$_vs_box_name" --provider "$_vs_prov" "$_vs_cand" >&2
        set -f
        printf '%s\n' "$_vs_box_name"
        return 0
      fi
    done
    set -f
  fi

  if [ -n "$_vs_url_tpl" ]; then
    _vs_url=$(printf '%s' "$_vs_url_tpl" | sed "s|{prefix}|${_vs_prefix}|g; s|{os}|${_vs_os}|g; s|{provider}|${_vs_prov}|g")
    _vs_cache="${LIBSCRIPT_CACHE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache}/bento/${_vs_prefix}_${_vs_os}_${_vs_prov}.box"
    mkdir -p "$(dirname "$_vs_cache")"
    libscript_download "$_vs_url" "$_vs_cache" >&2
    vagrant box add --name "$_vs_box_name" --provider "$_vs_prov" "$_vs_cache" >&2
    printf '%s\n' "$_vs_box_name"
    return 0
  fi

  printf '[BOX] Deferring box pull of %s (%s) to vagrant up...\n' "$_vs_box_name" "$_vs_prov" >&2
  printf '%s\n' "$_vs_box_name"
}

# ## vs_prepare_workspace
# Generates an isolated Vagrant workspace directory and multi-provider Vagrantfile without mutating repo Vagrantfiles.
vs_prepare_workspace() {
  _vs_suite="${1:?suite-id required}"
  _vs_prefix="${2:-bento}"
  _vs_os=$(vs_resolve_target_os "${3:-windows-11}")
  _vs_prov=$(vs_resolve_provider "${4:-auto}")
  _vs_cpus="${5:-4}"
  _vs_mem="${6:-8192}"
  _vs_fam=$(vs_guest_os_family "$_vs_os")
  _vs_box="${_vs_prefix}/${_vs_os}"
  _vs_ws="${LIBSCRIPT_ROOT_DIR}/tests_tmp/experiments/${_vs_suite}/${_vs_os}-${_vs_prov}"
  mkdir -p "$_vs_ws"

  cat << EOF_VF > "${_vs_ws}/Vagrantfile"
# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|
  config.vm.box = "${_vs_box}"
  config.vm.synced_folder ".", "/vagrant", disabled: true
  if "${_vs_fam}" == "windows"
    config.vm.guest = :windows
    config.vm.communicator = "winrm"
    config.winrm.username = ENV.fetch("VAGRANT_WINRM_USER", "vagrant")
    config.winrm.password = ENV.fetch("VAGRANT_WINRM_PASS", "vagrant")
    config.winrm.timeout = 600
  end
  config.vm.provider "virtualbox" do |v|
    v.cpus = ${_vs_cpus}
    v.memory = ${_vs_mem}
    v.gui = ("${_vs_fam}" == "windows" || "${_vs_fam}" == "macos")
  end
  config.vm.provider "libvirt" do |v|
    v.cpus = ${_vs_cpus}
    v.memory = ${_vs_mem}
  end
  config.vm.provider "hyperv" do |v|
    v.cpus = ${_vs_cpus}
    v.memory = ${_vs_mem}
  end
  config.vm.provider "vmware_desktop" do |v|
    v.vmx["numvcpus"] = "${_vs_cpus}"
    v.vmx["memsize"] = "${_vs_mem}"
    v.gui = ("${_vs_fam}" == "windows" || "${_vs_fam}" == "macos")
  end
  config.vm.provider "qemu" do |qe|
    qe.cpus = ${_vs_cpus}
    qe.memory = "${_vs_mem}M"
  end
  config.vm.provider "utm" do |u|
    u.cpus = ${_vs_cpus}
    u.memory = ${_vs_mem}
  end
end
EOF_VF
  printf '%s\n' "$_vs_ws"
}

# ## vs_exec_guest
# Runs a command inside the Vagrant guest via `vagrant winrm` (Windows) or `vagrant ssh` (POSIX) with retry/backoff.
vs_exec_guest() {
  _vs_ws="${1:?workspace required}"
  _vs_fam="${2:?os-family required}"
  _vs_cmd="${3:?command required}"
  _vs_attempt=0
  while [ "$_vs_attempt" -lt 5 ]; do
    if [ "$_vs_fam" = 'windows' ]; then
      if (cd "$_vs_ws" && vagrant winrm --shell powershell -c "$_vs_cmd"); then
        return 0
      fi
    else
      if (cd "$_vs_ws" && vagrant ssh -c "$_vs_cmd"); then
        return 0
      fi
    fi
    _vs_attempt=$((_vs_attempt + 1))
    sleep 3
  done
  printf '[ERROR] Guest command failed after %d attempts in %s\n' "$_vs_attempt" "$_vs_ws" >&2
  return 1
}

# ## vs_boot_vm
# Boots the Vagrant VM idempotently under the target provider and waits until guest communicator responds.
vs_boot_vm() {
  _vs_ws="${1:?workspace required}"
  _vs_prov="${2:?provider required}"
  _vs_fam="${3:?os-family required}"
  (cd "$_vs_ws" && vagrant up --no-provision --provider="$_vs_prov")
  if [ "$_vs_fam" = 'windows' ]; then
    vs_exec_guest "$_vs_ws" "$_vs_fam" 'Write-Output "READY"' >/dev/null
  else
    vs_exec_guest "$_vs_ws" "$_vs_fam" 'printf "%s\n" READY' >/dev/null
  fi
}

# ## vs_upload_guest
# Transfers a local host file or directory into the guest VM using `vagrant upload`.
vs_upload_guest() {
  _vs_ws="${1:?workspace required}"
  _vs_src="${2:?source path required}"
  _vs_dst="${3:?guest destination required}"
  (cd "$_vs_ws" && vagrant upload "$_vs_src" "$_vs_dst")
}

# ## vs_download_guest
# Transfers a file from inside the guest VM back to the host using communicator stdout/base64 streaming without raw scp.
vs_download_guest() {
  _vs_ws="${1:?workspace required}"
  _vs_fam="${2:?os-family required}"
  _vs_remote="${3:?guest file required}"
  _vs_local="${4:?host destination required}"
  mkdir -p "$(dirname "$_vs_local")"
  if [ "$_vs_fam" = 'windows' ]; then
    _vs_b64="${_vs_local}.b64"
    vs_exec_guest "$_vs_ws" 'windows' "[Convert]::ToBase64String([System.IO.File]::ReadAllBytes('${_vs_remote}'))" | tr -d '\r\n ' > "$_vs_b64"
    if base64 --decode < "$_vs_b64" > "$_vs_local" 2>/dev/null; then
      :
    else
      base64 -D < "$_vs_b64" > "$_vs_local"
    fi
    rm -f "$_vs_b64"
  else
    (cd "$_vs_ws" && vagrant ssh -c "cat '${_vs_remote}'" > "$_vs_local")
  fi
}

# ## vs_assert_vanilla_clean
# Verifies clean_state_probes from suite.json inside the guest VM so no residual install paths or listening ports exist.
vs_assert_vanilla_clean() {
  _vs_ws="${1:?workspace required}"
  _vs_fam="${2:?os-family required}"
  _vs_suite_json="${3:-}"
  if [ -z "$_vs_suite_json" ] || [ ! -f "$_vs_suite_json" ]; then
    return 0
  fi

  _vs_probes=$(jq -c '.installer_e2e.vagrant.clean_state_probes[]? // empty' "$_vs_suite_json")
  if [ -z "$_vs_probes" ]; then
    return 0
  fi

  _vs_old_ifs="$IFS"
  IFS='
'
  for _vs_p in $_vs_probes; do
    _vs_kind=$(printf '%s' "$_vs_p" | jq -r '.kind')
    _vs_tgt=$(printf '%s' "$_vs_p" | jq -r '.target')
    _vs_probe_fam=$(printf '%s' "$_vs_p" | jq -r '.os_family // "any"')
    if [ "$_vs_probe_fam" != 'any' ] && [ "$_vs_probe_fam" != "$_vs_fam" ]; then
      if [ "$_vs_probe_fam" = 'posix' ] && [ "$_vs_fam" != 'windows' ]; then
        :
      else
        continue
      fi
    fi
    case "${_vs_fam}:${_vs_kind}" in
      windows:path_absent)
        vs_exec_guest "$_vs_ws" 'windows' "if (Test-Path '${_vs_tgt}') { exit 1 } else { exit 0 }" >/dev/null
        ;;
      windows:port_closed)
        vs_exec_guest "$_vs_ws" 'windows' "\$c = New-Object System.Net.Sockets.TcpClient; try { \$c.Connect('127.0.0.1', ${_vs_tgt}); \$c.Close(); exit 1 } catch { exit 0 }" >/dev/null
        ;;
      windows:service_absent)
        vs_exec_guest "$_vs_ws" 'windows' "if (Get-Service -Name '${_vs_tgt}' -ErrorAction SilentlyContinue) { exit 1 } else { exit 0 }" >/dev/null
        ;;
      *:path_absent)
        vs_exec_guest "$_vs_ws" "$_vs_fam" "test ! -e '${_vs_tgt}'" >/dev/null
        ;;
      *:port_closed)
        vs_exec_guest "$_vs_ws" "$_vs_fam" "if command -v nc >/dev/null 2>&1 && nc -z 127.0.0.1 '${_vs_tgt}' >/dev/null 2>&1; then exit 1; fi; exit 0" >/dev/null
        ;;
      *:service_absent)
        vs_exec_guest "$_vs_ws" "$_vs_fam" "test ! -f '/etc/systemd/system/${_vs_tgt}.service'" >/dev/null
        ;;
    esac
  done
  IFS="$_vs_old_ifs"
}

# ## vs_ensure_vanilla_snapshot
# Idempotently captures the `"vanilla"` VM snapshot once on a verified clean guest, with qemu-img/copy fallback for qemu/utm.
vs_ensure_vanilla_snapshot() {
  _vs_ws="${1:?workspace required}"
  _vs_prov="${2:?provider required}"
  _vs_fam="${3:?os-family required}"
  _vs_snap="${4:-vanilla}"
  _vs_suite_json="${5:-}"

  case "$_vs_prov" in
    qemu|utm)
      _vs_marker="${_vs_ws}/.snapshot_${_vs_snap}_ready"
      if [ -f "$_vs_marker" ]; then
        printf '[SKIP] Snapshot "%s" already recorded for %s (%s).\n' "$_vs_snap" "$_vs_ws" "$_vs_prov" >&2
        return 0
      fi
      vs_assert_vanilla_clean "$_vs_ws" "$_vs_fam" "$_vs_suite_json"
      (cd "$_vs_ws" && vagrant halt)
      set +f
      for _vs_img in "${_vs_ws}/.vagrant/machines/default/${_vs_prov}"/*/linked-box.img "${_vs_ws}/.vagrant/machines/default/${_vs_prov}"/*/*.qcow2; do
        if [ -f "$_vs_img" ]; then
          if command -v qemu-img >/dev/null 2>&1; then
            qemu-img snapshot -c "$_vs_snap" "$_vs_img"
          else
            cp -c "$_vs_img" "${_vs_img}.${_vs_snap}" 2>/dev/null || cp "$_vs_img" "${_vs_img}.${_vs_snap}"
          fi
        fi
      done
      set -f
      date -u '+%Y-%m-%dT%H:%M:%SZ' > "$_vs_marker"
      vs_boot_vm "$_vs_ws" "$_vs_prov" "$_vs_fam"
      ;;
    *)
      _vs_snaps=$(if cd "$_vs_ws"; then vagrant snapshot list 2>/dev/null || true; fi)
      if printf '%s\n' "$_vs_snaps" | grep -Fx "$_vs_snap" >/dev/null 2>&1; then
        printf '[SKIP] Vagrant snapshot "%s" already exists in %s.\n' "$_vs_snap" "$_vs_ws" >&2
        return 0
      fi
      vs_assert_vanilla_clean "$_vs_ws" "$_vs_fam" "$_vs_suite_json"
      (cd "$_vs_ws" && vagrant snapshot save "$_vs_snap")
      ;;
  esac
}

# ## vs_restore_vanilla_snapshot
# Restores the guest VM to its `"vanilla"` snapshot and verifies clean-state probes before an install mode starts.
vs_restore_vanilla_snapshot() {
  _vs_ws="${1:?workspace required}"
  _vs_prov="${2:?provider required}"
  _vs_fam="${3:?os-family required}"
  _vs_snap="${4:-vanilla}"
  _vs_suite_json="${5:-}"

  case "$_vs_prov" in
    qemu|utm)
      (cd "$_vs_ws" && vagrant halt)
      set +f
      for _vs_img in "${_vs_ws}/.vagrant/machines/default/${_vs_prov}"/*/linked-box.img "${_vs_ws}/.vagrant/machines/default/${_vs_prov}"/*/*.qcow2; do
        if [ -f "$_vs_img" ]; then
          if [ -f "${_vs_img}.${_vs_snap}" ]; then
            cp -c "${_vs_img}.${_vs_snap}" "$_vs_img" 2>/dev/null || cp "${_vs_img}.${_vs_snap}" "$_vs_img"
          elif command -v qemu-img >/dev/null 2>&1; then
            qemu-img snapshot -a "$_vs_snap" "$_vs_img"
          fi
        fi
      done
      set -f
      vs_boot_vm "$_vs_ws" "$_vs_prov" "$_vs_fam"
      ;;
    *)
      (cd "$_vs_ws" && vagrant snapshot restore --no-provision "$_vs_snap")
      if [ "$_vs_fam" = 'windows' ]; then
        vs_exec_guest "$_vs_ws" 'windows' 'Write-Output "READY"' >/dev/null
      else
        vs_exec_guest "$_vs_ws" "$_vs_fam" 'printf "%s\n" READY' >/dev/null
      fi
      ;;
  esac
  vs_assert_vanilla_clean "$_vs_ws" "$_vs_fam" "$_vs_suite_json"
}

# ## vs_teardown_vm
# Halts or destroys the Vagrant workspace VM cleanly.
vs_teardown_vm() {
  _vs_ws="${1:?workspace required}"
  _vs_destroy="${2:-0}"
  if [ ! -d "$_vs_ws" ] || [ ! -f "${_vs_ws}/Vagrantfile" ]; then
    return 0
  fi
  if [ "$_vs_destroy" = '1' ]; then
    (cd "$_vs_ws" && vagrant destroy -f)
  else
    (cd "$_vs_ws" && vagrant halt)
  fi
}

# ## vs_cli_main
# CLI router when `vagrant_substrate.sh` is executed directly rather than sourced.
vs_cli_main() {
  _vs_act="${1:-}"
  shift 2>/dev/null || true
  case "$_vs_act" in
    resolve-os) vs_resolve_target_os "$@" ;;
    os-family) vs_guest_os_family "$@" ;;
    resolve-provider) vs_resolve_provider "$@" ;;
    provision) vs_register_bento_box "$@" ;;
    prepare-workspace) vs_prepare_workspace "$@" ;;
    boot) vs_boot_vm "$@" ;;
    snapshot-ensure) vs_ensure_vanilla_snapshot "$@" ;;
    snapshot-restore) vs_restore_vanilla_snapshot "$@" ;;
    assert-clean) vs_assert_vanilla_clean "$@" ;;
    exec) vs_exec_guest "$@" ;;
    upload) vs_upload_guest "$@" ;;
    download) vs_download_guest "$@" ;;
    teardown) vs_teardown_vm "$@" ;;
    --help|-h|'')
      printf '%s\n' 'Usage: vagrant_substrate.sh <resolve-os|os-family|resolve-provider|provision|prepare-workspace|boot|snapshot-ensure|snapshot-restore|assert-clean|exec|upload|download|teardown> [args...]'
      ;;
    *)
      printf '[ERROR] Unknown vagrant_substrate action: %s\n' "$_vs_act" >&2
      return 1
      ;;
  esac
}

if (return 0 2>/dev/null); then
  STACK="${STACK%"${THIS_FILE}":}"
  export STACK
  if [ -n "$_vs_caller_this" ]; then THIS_FILE="$_vs_caller_this"; fi
  if [ -n "$_vs_caller_dir" ]; then SCRIPT_DIR="$_vs_caller_dir"; fi
  unset _vs_caller_this _vs_caller_dir || true
else
  vs_cli_main "$@"
fi
