#!/bin/sh
# ## Overview
# Cross-platform package name translation module backed by engine/common/pkg_map.tsv and dynamic repository probes.
# ## Usage
# Source via SCRIPT_NAME and call map_package "<generic_name>".
set -feu
_pmap_caller_this="${THIS_FILE:-}"
_pmap_caller_dir="${SCRIPT_DIR:-}"
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
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2; fi
    [ -n "$_pmap_caller_this" ] && THIS_FILE="$_pmap_caller_this"
    [ -n "$_pmap_caller_dir" ] && SCRIPT_DIR="$_pmap_caller_dir"
    unset SCRIPT_NAME _pmap_caller_this _pmap_caller_dir || true
    if (return 0 2>/dev/null); then return 0; else exit 0; fi ;;
  *) if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
# ## map_package_dynamic
# Handles dynamic repository-availability and architecture-dependent package mappings before consulting pkg_map.tsv.
map_package_dynamic() {
  _mpd_pkg="$1"
  _mpd_pm="${PKG_MGR:-}"
  case "${_mpd_pkg}:${_mpd_pm}" in
    postgres:apt-get|postgresql:apt-get)
      if command -v apt-cache >/dev/null 2>&1; then
        if apt-cache show postgresql-server-dev-17 >/dev/null 2>&1; then
          printf 'postgresql-common postgresql-server-dev-17 postgresql-17\n'; return 0
        elif apt-cache show postgresql-server-dev-16 >/dev/null 2>&1; then
          printf 'postgresql-common postgresql-server-dev-16 postgresql-16\n'; return 0
        elif apt-cache show postgresql-server-dev-15 >/dev/null 2>&1; then
          printf 'postgresql-common postgresql-server-dev-15 postgresql-15\n'; return 0
        elif apt-cache show postgresql-server-dev-14 >/dev/null 2>&1; then
          printf 'postgresql-common postgresql-server-dev-14 postgresql-14\n'; return 0
        fi
      fi
      printf 'postgresql postgresql-contrib\n'
      return 0
      ;;
    java:apt-get)
      if command -v apt-cache >/dev/null 2>&1 && apt-cache show default-jdk >/dev/null 2>&1; then
        printf 'default-jdk\n'
      else
        printf 'openjdk-17-jdk\n'
      fi
      return 0
      ;;
    alsa-lib:apt-get)
      if command -v apt-cache >/dev/null 2>&1 && apt-cache show libasound2t64 >/dev/null 2>&1; then
        printf 'libasound2t64\n'
      else
        printf 'libasound2\n'
      fi
      return 0
      ;;
    doas:apt-get)
      if command -v apt-cache >/dev/null 2>&1 && apt-cache show doas >/dev/null 2>&1; then
        printf 'doas\n'
      else
        printf 'opendoas\n'
      fi
      return 0
      ;;
    docker:dnf|docker:yum)
      if command -v dnf >/dev/null 2>&1 && dnf info docker-ce >/dev/null 2>&1; then
        printf 'docker-ce docker-ce-cli containerd.io\n'
      else
        printf 'podman-docker\n'
      fi
      return 0
      ;;
    qemu:dnf|qemu:yum)
      if [ "${ARCH:-}" = 'aarch64' ] || [ "${ARCH:-}" = 'arm64' ]; then
        printf 'qemu-kvm qemu-img edk2-aarch64 libvirt virt-install swtpm\n'
      else
        printf 'qemu-kvm qemu-img edk2-ovmf libvirt virt-install swtpm\n'
      fi
      return 0
      ;;
  esac
  return 1
}

# ## map_package
# Translates a generic package identifier into the native OS package manager name using pkg_map.tsv.
map_package() {
  pkg="$1"
  if map_package_dynamic "$pkg"; then
    return 0
  fi

  _mp_tsv="${LIBSCRIPT_ROOT_DIR}/engine/common/pkg_map.tsv"
  _mp_sel="${PKG_MGR:-}"
  _mp_os_sel=''
  if [ "$_mp_sel" = 'pkg' ] && { [ "${TARGET_OS:-}" = 'sunos' ] || [ "${UNAME:-}" = 'SunOS' ]; }; then
    _mp_os_sel='pkg:sunos'
  fi

  _mp_res=$(awk -F '\t' -v p="$pkg" -v os_sel="$_mp_os_sel" -v sel="$_mp_sel" '
    !/^#/ && $1 == p {
      if (os_sel != "" && $2 == os_sel) { exact_os = $3 }
      else if ($2 == sel) { exact_pm = $3 }
      else if ($2 == "*") { fallback = $3 }
    }
    END {
      if (exact_os != "") print exact_os
      else if (exact_pm != "") print exact_pm
      else if (fallback != "") print fallback
      else print p
    }
  ' "$_mp_tsv")

  if [ "$_mp_res" = '__UNSUPPORTED__' ]; then
    unset _mp_tsv _mp_sel _mp_os_sel _mp_res || true
    return 1
  fi
  if [ "$_mp_res" = '__NONE__' ]; then
    unset _mp_tsv _mp_sel _mp_os_sel _mp_res || true
    return 0
  fi
  printf '%s\n' "$_mp_res"
  unset _mp_tsv _mp_sel _mp_os_sel _mp_res || true
  return 0
}

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_pmap_caller_dir:-}" ] && SCRIPT_DIR="$_pmap_caller_dir"
[ -n "${_pmap_caller_this:-}" ] && THIS_FILE="$_pmap_caller_this"
unset SCRIPT_NAME _pmap_caller_this _pmap_caller_dir || true
