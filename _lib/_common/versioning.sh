#!/bin/sh
# ## Overview
# Provides common utilities for managing component versions and aliases on Unix systems.
# It defines functions (`libscript_get_version_dir`, `libscript_symlink_alias`,
# `libscript_check_installed_version`) to resolve installation paths, create symlinks for
# version aliasing, and inspect existing installations with reuse-else-create semantics.
# 
# ## Usage
# Source this file to utilize its version path resolution, aliasing, and inspection utilities.

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
_SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)

# versioning.sh
# Common utilities for managing native libscript installations and version aliases.

# ## libscript_get_version_dir
# Performs the libscript_get_version_dir operation and updates component state.
libscript_get_version_dir() {
  component="$1"
  version="$2"
  printf '%s\n' "${LIBSCRIPT_HOME:-$HOME/.libscript}/${component}/${version}"
}

# ## libscript_symlink_alias
# Performs the libscript_symlink_alias operation and updates component state.
libscript_symlink_alias() {
  component="$1"
  alias_name="$2"
  exact_version="$3"
  
  base_dir="${LIBSCRIPT_HOME:-$HOME/.libscript}/${component}"
  mkdir -p "${base_dir}"
  
  if [ "${alias_name}" != "${exact_version}" ]; then
    if [ -L "${base_dir}/${alias_name}" ] || [ -f "${base_dir}/${alias_name}" ]; then
      rm -f "${base_dir}/${alias_name}"
    elif [ -d "${base_dir}/${alias_name}" ]; then
      rm -rf "${base_dir:?}/${alias_name:?}"
    fi
    if ! (cd "${base_dir}" && ln -sfn "${exact_version}" "${alias_name}" 2>/dev/null); then
      (cd "${base_dir}" && ln -sf "${exact_version}" "${alias_name}")
    fi
  fi
}

# ## libscript_check_installed_version
# Checks whether a component satisfying the requested version is already installed in LIBSCRIPT_HOME or system PATH.
libscript_check_installed_version() {
  _civ_comp="$1"
  _civ_req="${2:-latest}"
  _civ_home="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}"
  _civ_user_home="${REMOTE_HOME:-${HOME:-/root}}"
  _civ_prefix=$(printf '%s' "$_civ_req" | sed -e 's/^v//' -e 's/\.x$//' -e 's/\.\*$//')

  case "$_civ_comp" in
    nodejs|node)
      if [ -x "${_civ_home}/nodejs/${_civ_req}/bin/node" ]; then
        printf '%s\n' "${_civ_home}/nodejs/${_civ_req}/bin"
        return 0
      fi
      if [ -d "${_civ_home}/nodejs" ]; then
        for _civ_d in "${_civ_home}/nodejs"/*; do
          [ -x "${_civ_d}/bin/node" ] || continue
          _civ_v=$("${_civ_d}/bin/node" -v 2>/dev/null | sed 's/^v//' || true)
          if [ "$_civ_req" = "latest" ] || [ "$_civ_req" = "lts" ] || [ "${_civ_v#"${_civ_prefix}".}" != "$_civ_v" ] || [ "$_civ_v" = "$_civ_prefix" ]; then
            libscript_symlink_alias "nodejs" "$_civ_req" "$(basename -- "$_civ_d")" 2>/dev/null || true
            printf '%s\n' "${_civ_d}/bin"
            return 0
          fi
        done
      fi
      if command -v node >/dev/null 2>&1; then
        _civ_v=$(node -v 2>/dev/null | sed 's/^v//' || true)
        if [ "$_civ_req" = "latest" ] || [ "$_civ_req" = "lts" ] || [ "${_civ_v#"${_civ_prefix}".}" != "$_civ_v" ] || [ "$_civ_v" = "$_civ_prefix" ]; then
          dirname -- "$(command -v node)"
          return 0
        fi
      fi
      return 1
      ;;
    python|python3)
      if [ -x "${_civ_home}/python/${_civ_req}/bin/python3" ]; then
        printf '%s\n' "${_civ_home}/python/${_civ_req}/bin"
        return 0
      fi
      if [ "$_civ_prefix" != "latest" ] && command -v "python${_civ_prefix}" >/dev/null 2>&1; then
        dirname -- "$(command -v "python${_civ_prefix}")"
        return 0
      fi
      for _civ_uv_py_dir in "${UV_PYTHON_INSTALL_DIR:-}" "${_civ_user_home}/.local/share/uv/python" "/root/.local/share/uv/python"; do
        [ -n "$_civ_uv_py_dir" ] && [ -d "$_civ_uv_py_dir" ] || continue
        for _civ_pyd in "$_civ_uv_py_dir"/cpython-"${_civ_prefix}"*; do
          if [ -x "${_civ_pyd}/bin/python3" ]; then
            printf '%s\n' "${_civ_pyd}/bin"
            return 0
          fi
        done
      done
      if command -v python3 >/dev/null 2>&1; then
        _civ_pyv=$(python3 -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>/dev/null || true)
        if [ "$_civ_req" = "latest" ] || [ "$_civ_pyv" = "$_civ_prefix" ]; then
          dirname -- "$(command -v python3)"
          return 0
        fi
      fi
      return 1
      ;;
    uv)
      for _civ_uv_bin in "${_civ_home}/uv/${_civ_req}/bin/uv" "${_civ_home}/uv/default/bin/uv" "${_civ_user_home}/.local/bin/uv" "/root/.local/bin/uv" "$(command -v uv 2>/dev/null || true)"; do
        if [ -n "$_civ_uv_bin" ] && [ -x "$_civ_uv_bin" ]; then
          dirname -- "$_civ_uv_bin"
          return 0
        fi
      done
      return 1
      ;;
    postgres|postgresql)
      if command -v pg_isready >/dev/null 2>&1 && pg_isready -q 2>/dev/null; then
        dirname -- "$(command -v pg_isready)"
        return 0
      fi
      if command -v psql >/dev/null 2>&1 && { command -v postgres >/dev/null 2>&1 || [ -d "/etc/postgresql" ] || [ -d "/var/lib/postgresql" ]; }; then
        dirname -- "$(command -v psql)"
        return 0
      fi
      return 1
      ;;
    valkey|redis)
      for _civ_vk_bin in "${_civ_home}/${_civ_comp}/${_civ_req}/bin/valkey-server" "${_civ_home}/${_civ_comp}/${_civ_req}/bin/redis-server" "/usr/local/bin/valkey-server" "/usr/bin/valkey-server" "/usr/bin/redis-server" "$(command -v valkey-server 2>/dev/null || true)" "$(command -v redis-server 2>/dev/null || true)"; do
        if [ -n "$_civ_vk_bin" ] && [ -x "$_civ_vk_bin" ]; then
          dirname -- "$_civ_vk_bin"
          return 0
        fi
      done
      return 1
      ;;
    duckdb)
      for _civ_dk_bin in "${_civ_home}/duckdb/${_civ_req}/bin/duckdb" "${_civ_home}/duckdb/default/bin/duckdb" "${_civ_user_home}/.local/bin/duckdb" "/usr/local/bin/duckdb" "$(command -v duckdb 2>/dev/null || true)"; do
        if [ -n "$_civ_dk_bin" ] && [ -x "$_civ_dk_bin" ]; then
          dirname -- "$_civ_dk_bin"
          return 0
        fi
      done
      return 1
      ;;
    nginx)
      for _civ_nx_bin in "${_civ_home}/nginx/${_civ_req}/bin/nginx" "/usr/sbin/nginx" "/usr/local/bin/nginx" "$(command -v nginx 2>/dev/null || true)"; do
        if [ -n "$_civ_nx_bin" ] && [ -x "$_civ_nx_bin" ]; then
          dirname -- "$_civ_nx_bin"
          return 0
        fi
      done
      return 1
      ;;
    ollama)
      for _civ_ol_bin in "${_civ_home}/ollama/${_civ_req}/bin/ollama" "/usr/local/bin/ollama" "/usr/bin/ollama" "$(command -v ollama 2>/dev/null || true)"; do
        if [ -n "$_civ_ol_bin" ] && [ -x "$_civ_ol_bin" ]; then
          dirname -- "$_civ_ol_bin"
          return 0
        fi
      done
      return 1
      ;;
    *)
      if [ -d "${_civ_home}/${_civ_comp}/${_civ_req}/bin" ]; then
        printf '%s\n' "${_civ_home}/${_civ_comp}/${_civ_req}/bin"
        return 0
      fi
      if command -v "$_civ_comp" >/dev/null 2>&1; then
        dirname -- "$(command -v "$_civ_comp")"
        return 0
      fi
      return 1
      ;;
  esac
}
