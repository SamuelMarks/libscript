#!/bin/sh
# ## Overview
# Resolves workspace-pinned tool versions from `.libscript-version` and `libscript.json` without `eval`.
#
# ## Usage
# ./cli/commands/resolve_env.sh [--dir=<path>] [--format=sh|cmd|ps1|json] [--write=<file>]

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

RESOLVE_DIR="${PWD}"
RESOLVE_FMT='sh'
RESOLVE_WRITE=''

while [ $# -gt 0 ]; do
  case "$1" in
    --dir=*) RESOLVE_DIR="${1#*=}"; shift ;;
    --dir) RESOLVE_DIR="${2:-$PWD}"; shift 2 ;;
    --format=*) RESOLVE_FMT="${1#*=}"; shift ;;
    --format) RESOLVE_FMT="${2:-sh}"; shift 2 ;;
    --write=*) RESOLVE_WRITE="${1#*=}"; shift ;;
    --write) RESOLVE_WRITE="${2:-}"; shift 2 ;;
    --help|-h)
      printf '%s\n' 'Usage: libscript.sh resolve-env [--dir=<path>] [--format=sh|cmd|ps1|json] [--write=<file>]'
      exit 0
      ;;
    *) shift ;;
  esac
done

# ## parse_version_file
# Parses key=value or key:value tool pins from a .libscript-version file.
parse_version_file() {
  awk '
    {
      line = $0
      sub(/#.*/, "", line)
      gsub(/^[ \t\r]+|[ \t\r]+$/, "", line)
      if (line == "") next
      sep = index(line, "=")
      if (sep == 0) sep = index(line, ":")
      if (sep > 0) {
        k = tolower(substr(line, 1, sep - 1))
        v = substr(line, sep + 1)
        gsub(/^[ \t]+|[ \t]+$/, "", k)
        gsub(/^[ \t"]+|[" \t]+$/, "", v)
        if (k != "" && v != "") print k "=" v
      }
    }
  ' "$1" 2>/dev/null || true
}

# ## collect_workspace_pins
# Ascends from RESOLVE_DIR collecting nearest pkg=version entries from .libscript-version and libscript.json.
collect_workspace_pins() {
  _cwp_d=$(cd -- "$RESOLVE_DIR" && pwd)
  _cwp_seen=' '
  while :; do
    if [ -f "${_cwp_d}/.libscript-version" ]; then
      _cwp_parsed=$(parse_version_file "${_cwp_d}/.libscript-version")
      if [ -n "$_cwp_parsed" ]; then
        while IFS='=' read -r _k _v; do
          [ -z "$_k" ] && continue
          case "$_cwp_seen" in
            *" ${_k} "*) ;;
            *)
              printf '%s=%s\n' "$_k" "$_v"
              _cwp_seen="${_cwp_seen}${_k} "
              ;;
          esac
        done << EOF
${_cwp_parsed}
EOF
      fi
    fi
    if [ -f "${_cwp_d}/libscript.json" ] && command -v jq >/dev/null 2>&1; then
      _cwp_json=$(jq -r '
        ((.deps // {}) + (.dependencies // {}))
        | to_entries[]
        | "\(.key | ascii_downcase)=\(if (.value | type) == "object" then (.value.version // "latest") else (.value | tostring) end)"
      ' "${_cwp_d}/libscript.json" 2>/dev/null || true)
      if [ -n "$_cwp_json" ]; then
        while IFS='=' read -r _jk _jv; do
          [ -z "$_jk" ] && continue
          case "$_cwp_seen" in
            *" ${_jk} "*) ;;
            *)
              printf '%s=%s\n' "$_jk" "$_jv"
              _cwp_seen="${_cwp_seen}${_jk} "
              ;;
          esac
        done << EOF
${_cwp_json}
EOF
      fi
    fi
    _cwp_p="${_cwp_d%/*}"
    [ -z "$_cwp_p" ] && _cwp_p="/"
    [ "$_cwp_d" = "$_cwp_p" ] && break
    _cwp_d="$_cwp_p"
  done
}

# ## render_resolved_env
# Formats resolved workspace pin environment statements in sh, cmd, ps1, or json.
render_resolved_env() {
  _rre_home="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}"
  _rre_pins=$(collect_workspace_pins)
  _rre_bins=''
  if [ -d "${_rre_home}/bin" ]; then
    _rre_bins="${_rre_home}/bin"
  fi

  case "$RESOLVE_FMT" in
    json)
      _j_items=''
      if [ -n "$_rre_pins" ]; then
        while IFS='=' read -r _pk _pv; do
          [ -z "$_pk" ] && continue
          _pkg_bin="${_rre_home}/${_pk}/${_pv}/bin"
          if [ ! -d "$_pkg_bin" ] && [ -d "${_rre_home}/${_pk}/v${_pv}/bin" ]; then
            _pkg_bin="${_rre_home}/${_pk}/v${_pv}/bin"
          fi
          _j_items="${_j_items}${_j_items:+,}\"${_pk}\":{\"version\":\"${_pv}\",\"bin\":\"${_pkg_bin}\"}"
        done << EOF
${_rre_pins}
EOF
      fi
      printf '{"libscript_home":"%s","active_bin":"%s","pins":{%s}}\n' "${_rre_home}" "${_rre_home}/bin" "${_j_items}"
      ;;
    cmd)
      printf '%s\n' '@echo off'
      if [ -n "$_rre_pins" ]; then
        while IFS='=' read -r _pk _pv; do
          [ -z "$_pk" ] && continue
          _up=$(printf '%s' "$_pk" | tr '[:lower:]-' '[:upper:]_')
          _pkg_bin="${_rre_home}/${_pk}/${_pv}/bin"
          printf 'SET "%s_VERSION=%s"\n' "$_up" "$_pv"
          printf 'SET "PATH=%s;%%PATH%%"\n' "$_pkg_bin"
        done << EOF
${_rre_pins}
EOF
      fi
      printf 'SET "PATH=%s/bin;%%PATH%%"\n' "${_rre_home}"
      ;;
    ps1|powershell)
      if [ -n "$_rre_pins" ]; then
        while IFS='=' read -r _pk _pv; do
          [ -z "$_pk" ] && continue
          _up=$(printf '%s' "$_pk" | tr '[:lower:]-' '[:upper:]_')
          _pkg_bin="${_rre_home}/${_pk}/${_pv}/bin"
          # shellcheck disable=SC2016
          printf '$env:%s_VERSION = "%s"\n' "$_up" "$_pv"
          # shellcheck disable=SC2016
          printf '$env:PATH = "%s;" + $env:PATH\n' "$_pkg_bin"
        done << EOF
${_rre_pins}
EOF
      fi
      # shellcheck disable=SC2016
      printf '$env:PATH = "%s/bin;" + $env:PATH\n' "${_rre_home}"
      ;;
    *)
      if [ -n "$_rre_pins" ]; then
        while IFS='=' read -r _pk _pv; do
          [ -z "$_pk" ] && continue
          _up=$(printf '%s' "$_pk" | tr '[:lower:]-' '[:upper:]_')
          _pkg_dir="${_rre_home}/${_pk}/${_pv}"
          if [ ! -d "${_pkg_dir}/bin" ] && [ -d "${_rre_home}/${_pk}/v${_pv}/bin" ]; then
            _pkg_dir="${_rre_home}/${_pk}/v${_pv}"
          fi
          printf 'export %s_VERSION="%s"\n' "$_up" "$_pv"
          if [ "$_pk" = 'nodejs' ]; then
            printf 'export NPM_CONFIG_PREFIX="%s"\n' "$_pkg_dir"
            printf 'export COREPACK_HOME="%s/corepack"\n' "$_pkg_dir"
          elif [ "$_pk" = 'rust' ]; then
            printf 'export CARGO_HOME="%s/cargo"\n' "$_pkg_dir"
            printf 'export RUSTUP_HOME="%s/rustup"\n' "$_pkg_dir"
          fi
          _rre_bins="${_pkg_dir}/bin${_rre_bins:+:${_rre_bins}}"
        done << EOF
${_rre_pins}
EOF
      fi
      if [ -n "$_rre_bins" ]; then
        # shellcheck disable=SC2016
        printf 'export PATH="%s:${PATH}"\n' "$_rre_bins"
      fi
      ;;
  esac
}

if [ -n "$RESOLVE_WRITE" ]; then
  mkdir -p "$(dirname -- "$RESOLVE_WRITE")"
  render_resolved_env > "${RESOLVE_WRITE}.tmp"
  mv "${RESOLVE_WRITE}.tmp" "$RESOLVE_WRITE"
else
  render_resolved_env
fi
