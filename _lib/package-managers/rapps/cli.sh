#!/bin/sh
# ## Overview
# Command-line interface router for ReactOS Applications Manager (rapps).
# Supports standard Version Manager verbs via component_core.sh plus parse-ini, search, and prefetch.
#
# ## Usage
# ./_lib/package-managers/rapps/cli.sh <install|ls|ls-remote|use|uninstall|parse-ini|search|prefetch> [args]

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

# ## parse_rapps_ini
# Parses a RAPPS .txt INI file for the requested architecture (i686 or x86_64) and prints key=value pairs.
parse_rapps_ini() {
  _ini_file="$1"
  _target_arch="${2:-${LIBSCRIPT_RAPPS_ARCH:-i686}}"
  if [ ! -f "$_ini_file" ]; then
    printf '[ERROR] RAPPS INI file not found: %s\n' "$_ini_file" >&2
    return 1
  fi
  _arch_sec='x86'
  case "$_target_arch" in
    x86_64|amd64) _arch_sec='amd64' ;;
    *) _arch_sec='x86' ;;
  esac

  awk -v asec="$_arch_sec" '
    BEGIN { sec = ""; name = ""; ver = ""; url = ""; sha256 = ""; sha1 = ""; inst = ""; silent = "" }
    {
      sub(/\r$/, "")
      if ($0 ~ /^[[:space:]]*;/ || $0 ~ /^[[:space:]]*$/) next
      if ($0 ~ /^\[.*\]$/) {
        sec = $0
        gsub(/^\[|\]$/, "", sec)
        next
      }
      eq = index($0, "=")
      if (eq == 0) next
      k = substr($0, 1, eq - 1)
      v = substr($0, eq + 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", k)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
      if (sec == "Section") {
        if (k == "Name") name = v
        else if (k == "Version") ver = v
        else if (k == "URLDownload" || k == "URL") { if (url == "") url = v }
        else if (k == "SHA256") { if (sha256 == "") sha256 = v }
        else if (k == "SHA1") { if (sha1 == "") sha1 = v }
        else if (k == "Installer") { if (inst == "") inst = v }
        else if (k == "SilentParameters") { if (silent == "") silent = v }
      } else if (sec == ("Section." asec)) {
        if (k == "Name") name = v
        else if (k == "Version") ver = v
        else if (k == "URLDownload" || k == "URL") url = v
        else if (k == "SHA256") sha256 = v
        else if (k == "SHA1") sha1 = v
        else if (k == "Installer") inst = v
        else if (k == "SilentParameters") silent = v
      }
    }
    END {
      if (silent == "") {
        if (url ~ /\.msi$/ || inst == "msi") silent = "/qn AGREE_ALL_LICENSES=1"
        else if (inst == "inno") silent = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
        else silent = "/S"
      }
      printf "NAME=%s\nVERSION=%s\nURL=%s\nSHA256=%s\nSHA1=%s\nINSTALLER=%s\nSILENT_ARGS=%s\n", name, ver, url, sha256, sha1, inst, silent
    }
  ' "$_ini_file"
}

# ## ensure_rapps_db
# Ensures the local rapps-db directory exists and returns its path.
ensure_rapps_db() {
  _ver="${RAPPS_VERSION:-${LIBSCRIPT_RAPPS_VERSION:-0.4.16}}"
  [ "$_ver" = "latest" ] && _ver='0.4.16'
  _db="${LIBSCRIPT_RAPPS_DB_DIR:-${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/rapps/${_ver}/db}"
  if [ ! -d "$_db" ]; then
    ACTION="install" "${SCRIPT_DIR}/setup_generic.sh" >/dev/null
  fi
  printf '%s\n' "$_db"
}

# ## prefetch_rapps_pkg
# Resolves a RAPPS package ID, writes silent metadata/flags, and downloads the installer when online.
prefetch_rapps_pkg() {
  _pkg_id=""
  _arch="${LIBSCRIPT_RAPPS_ARCH:-i686}"
  _dest="${LIBSCRIPT_RAPPS_CACHE_DIR:-${LIBSCRIPT_CACHE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache}/rapps}"
  _ini_override=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --arch=*) _arch="${1#*=}" ;;
      --arch) shift; _arch="${1:-i686}" ;;
      --dest=*) _dest="${1#*=}" ;;
      --dest) shift; _dest="${1:-$_dest}" ;;
      --ini=*) _ini_override="${1#*=}" ;;
      --ini) shift; _ini_override="${1:-}" ;;
      -*) ;;
      *) [ -z "$_pkg_id" ] && _pkg_id="$1" ;;
    esac
    shift
  done

  if [ -z "$_pkg_id" ]; then
    printf '[ERROR] Package ID required for rapps prefetch.\n' >&2
    return 1
  fi

  mkdir -p "$_dest"
  _stamp="${_dest}/${_pkg_id}.${_arch}.stamp"
  if [ -f "$_stamp" ]; then
    printf '[SKIP] RAPPS package %s (%s) already prefetched at %s.\n' "$_pkg_id" "$_arch" "$_dest"
    return 0
  fi

  if [ -n "$_ini_override" ]; then
    _ini_path="$_ini_override"
  else
    _db_dir=$(ensure_rapps_db)
    _ini_path="${_db_dir}/${_pkg_id}.txt"
  fi

  if [ ! -f "$_ini_path" ]; then
    printf '[ERROR] RAPPS definition not found for "%s" at %s\n' "$_pkg_id" "$_ini_path" >&2
    return 1
  fi

  _meta=$(parse_rapps_ini "$_ini_path" "$_arch")
  _url=$(printf '%s\n' "$_meta" | awk -F= '$1=="URL"{sub(/^URL=/,""); print}')
  _sha=$(printf '%s\n' "$_meta" | awk -F= '$1=="SHA256"{sub(/^SHA256=/,""); print}')
  _silent=$(printf '%s\n' "$_meta" | awk -F= '$1=="SILENT_ARGS"{sub(/^SILENT_ARGS=/,""); print}')

  printf '%s\n' "$_meta" > "${_dest}/${_pkg_id}.meta"
  printf '%s\n' "$_silent" > "${_dest}/${_pkg_id}.flags"

  if [ -n "$_url" ] && [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mgr.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
    unset SCRIPT_NAME || true
    _ext='exe'
    case "$_url" in
      *.msi) _ext='msi' ;;
      *.zip) _ext='zip' ;;
    esac
    [ -z "$_sha" ] && _sha='SKIP'
    libscript_download "$_url" "${_dest}/${_pkg_id}.${_ext}" "$_sha"
  fi

  date -u +"%Y-%m-%dT%H:%M:%SZ" > "${_stamp}.tmp"
  mv "${_stamp}.tmp" "$_stamp"
  ln -sf "${_pkg_id}.${_arch}.stamp" "${_dest}/${_pkg_id}.stamp"
  printf '[OK] Prefetched RAPPS metadata for %s (%s) -> %s\n' "$_pkg_id" "$_arch" "$_dest"
}

case "${1:-}" in
  parse-ini)
    shift
    parse_rapps_ini "${1:-}" "${2:-${LIBSCRIPT_RAPPS_ARCH:-i686}}"
    exit $?
    ;;
  prefetch)
    shift
    prefetch_rapps_pkg "$@"
    exit $?
    ;;
  search)
    shift
    _q="${1:-}"
    _db_dir=$(ensure_rapps_db)
    set +f
    for _f in "${_db_dir}"/*.txt; do
      [ -f "$_f" ] || continue
      _bn="${_f##*/}"
      _bn="${_bn%.txt}"
      if [ -z "$_q" ] || printf '%s\n' "$_bn" | grep -qi "$_q" || grep -qi "$_q" "$_f"; then
        printf '%s\n' "$_bn"
      fi
    done
    set -f
    exit 0
    ;;
esac

: "${PACKAGE_NAME:=$(basename "$SCRIPT_DIR")}"
SCRIPT_NAME="${SCRIPT_DIR}/../../_common/component_core.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
