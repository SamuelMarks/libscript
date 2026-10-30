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
_ver_caller_this="${THIS_FILE:-}"; _ver_caller_dir="${SCRIPT_DIR:-}"
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
    [ -n "$_ver_caller_this" ] && THIS_FILE="$_ver_caller_this"
    [ -n "$_ver_caller_dir" ] && SCRIPT_DIR="$_ver_caller_dir"
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
  printf '%s\n' "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/${component}/${version}"
}

# ## libscript_symlink_alias
# Performs the libscript_symlink_alias operation and updates component state.
libscript_symlink_alias() {
  component="$1"
  alias_name="$2"
  exact_version="$3"
  
  base_dir="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/${component}"
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
        if [ -z "$_civ_uv_py_dir" ] || [ ! -d "$_civ_uv_py_dir" ]; then
          continue
        fi
        for _civ_pyd in "$_civ_uv_py_dir"/cpython-"${_civ_prefix}"*; do
          if [ -x "${_civ_pyd}/bin/python3" ]; then
            printf '%s\n' "${_civ_pyd}/bin"
            return 0
          fi
        done
      done
      if command -v python3 >/dev/null 2>&1; then
        _civ_pyv=$(python3 --version 2>&1 | awk '{print $2}' | cut -d. -f1,2 || true)
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

# ## libscript_sort_versions
# Sorts semantic version strings from stdin in ascending numeric order using pure POSIX awk and sort.
libscript_sort_versions() {
  awk '
    {
      orig = $0
      v = $0
      sub(/^[^0-9]*/, "", v)
      n = split(v, parts, /[^0-9]+/)
      p1 = (n >= 1 && parts[1] != "") ? parts[1] + 0 : 0
      p2 = (n >= 2 && parts[2] != "") ? parts[2] + 0 : 0
      p3 = (n >= 3 && parts[3] != "") ? parts[3] + 0 : 0
      p4 = (n >= 4 && parts[4] != "") ? parts[4] + 0 : 0
      printf "%010d.%010d.%010d.%010d\t%s\n", p1, p2, p3, p4, orig
    }
  ' | sort -k1,1 | cut -f2-
}

# ## libscript_sed_in_place
# Portably applies a sed expression in-place to a target file without GNU vs BSD sed -i flags.
libscript_sed_in_place() {
  _sip_expr="$1"
  _sip_file="$2"
  [ -f "$_sip_file" ] || return 0
  _sip_tmp="${_sip_file}.libscript_tmp.$$"
  if sed "$_sip_expr" "$_sip_file" > "$_sip_tmp"; then
    cat "$_sip_tmp" > "$_sip_file"
    rm -f "$_sip_tmp"
  else
    rm -f "$_sip_tmp"
    return 1
  fi
}

# ## libscript_resolve_repo_url
# Resolves the canonical upstream repository URL for a component from its manifest.json or default argument.
libscript_resolve_repo_url() {
  _rru_comp="${1:-}"
  _rru_dir="${2:-${DIR:-${SCRIPT_DIR:-}}}"
  _rru_default="${3:-}"
  if [ -n "$_rru_dir" ] && [ -f "${_rru_dir}/manifest.json" ]; then
    _rru_m=$(grep -E '"repository"[[:space:]]*:' "${_rru_dir}/manifest.json" 2>/dev/null | head -n 1 | sed -e 's/.*"repository"[[:space:]]*:[[:space:]]*"//' -e 's/".*//' || true)
    if [ -n "$_rru_m" ]; then
      printf '%s\n' "$_rru_m"
      return 0
    fi
  fi
  printf '%s\n' "$_rru_default"
}

# ## libscript_handle_generic_action
# Centralizes common version manager lifecycle actions (ls, ls-remote, use, download, service, install-service, uninstall-service, uninstall) for setup_generic.sh scripts.
libscript_handle_generic_action() {
  _hga_comp="${1:-${PACKAGE_NAME:-}}"
  _hga_action="${2:-${ACTION:-install}}"
  _hga_ver="${3:-${VERSION:-latest}}"
  _hga_method="${4:-libscript_native}"
  _hga_dl_url="${5:-}"
  _hga_rel_url="${6:-}"
  _hga_repo_url="${7:-}"
  if [ -n "${7:-}" ]; then shift 7; elif [ $# -gt 0 ]; then shift $#; fi

  case "$_hga_action" in
    ls)
      if [ "$_hga_method" = "system" ]; then
        printf '%s\n' 'System packages do not support ls here.'
      else
        ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/${_hga_comp}/" 2>/dev/null || true
      fi
      exit 0
      ;;
    ls-remote)
      if [ "$_hga_method" = "system" ]; then
        printf '%s\n' 'System packages do not support ls-remote here.'
      elif [ -n "$_hga_rel_url" ]; then
        libscript_fetch_stdout "$_hga_rel_url" | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
      else
        _hga_resolved_repo=$(libscript_resolve_repo_url "$_hga_comp" "${DIR:-${SCRIPT_DIR:-}}" "$_hga_repo_url")
        if [ -n "$_hga_resolved_repo" ]; then
          git ls-remote --tags "$_hga_resolved_repo" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
        else
          printf '%s\n' 'No versions found'
        fi
      fi
      exit 0
      ;;
    use)
      if [ "$_hga_method" = "system" ]; then
        printf '%s\n' 'System packages do not support use here.'
      else
        if type resolve_exact_version >/dev/null 2>&1; then
          resolve_exact_version
        else
          EXACT_VERSION="${_hga_ver}"
        fi
        libscript_symlink_alias "$_hga_comp" "$_hga_ver" "$EXACT_VERSION"
        libscript_symlink_alias "$_hga_comp" "default" "$EXACT_VERSION"
        _hga_target="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/${_hga_comp}/${EXACT_VERSION}"
        if [ ! -d "$_hga_target" ]; then
          log_info "${_hga_comp} ${EXACT_VERSION} is not installed. Installing it now..."
          unset SCRIPT_NAME || true
          ACTION="install" sh "${DIR:-$SCRIPT_DIR}/setup.sh" install "$_hga_comp" "" || exit 1
        fi
        libscript_symlink_alias "$_hga_comp" "default" "$EXACT_VERSION"
        log_info "Set default ${_hga_comp} version to ${EXACT_VERSION}."
        log_info 'To apply to the current shell, run:'
        log_info "  . \"${DIR:-$SCRIPT_DIR}/env.sh\" # or: . \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env ${_hga_comp} \"$_hga_ver\")"
      fi
      exit 0
      ;;
    download)
      if [ "$_hga_method" = "libscript_native" ]; then
        log_info "Downloading ${_hga_comp} ${_hga_ver} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/${_hga_comp}..."
        mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/${_hga_comp}"
        if [ -n "$_hga_dl_url" ]; then
          _hga_ext='tar.gz'
          case "$_hga_dl_url" in *.zip) _hga_ext="zip" ;; esac
          libscript_download "$_hga_dl_url" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/${_hga_comp}/${_hga_comp}-${_hga_ver}.${_hga_ext}"
        else
          log_warn "Download URL is not defined for ${_hga_comp} ${_hga_ver}."
        fi
      fi
      exit 0
      ;;
    start|stop|restart|status|health|logs|up|down)
      if [ "$_hga_method" = "libscript_native" ] || [ "$_hga_method" = "system" ]; then
        SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
        export SCRIPT_NAME
        # shellcheck disable=SC1090,SC1091
        . "${SCRIPT_NAME}"
        _hga_svc="${LIBSCRIPT_SERVICE_NAME:-}"
        if [ -z "$_hga_svc" ]; then
          if [ "$_hga_comp" = "postgres" ] && { [ -f "/lib/systemd/system/postgresql.service" ] || [ -f "/etc/init.d/postgresql" ]; }; then
            _hga_svc='postgresql'
          else
            _hga_svc="libscript_${PACKAGE_NAME:-$_hga_comp}"
          fi
        fi
        libscript_service "$_hga_action" "$_hga_svc" "$@"
      else
        log_info "$_hga_action not natively implemented for $_hga_method."
      fi
      exit 0
      ;;
    install-service)
      if [ "$_hga_method" = "libscript_native" ] || [ "$_hga_method" = "system" ]; then
        SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
        export SCRIPT_NAME
        # shellcheck disable=SC1090,SC1091
        . "${SCRIPT_NAME}"
        _hga_svc="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-$_hga_comp}}"
        libscript_install_service "$_hga_svc" "$@"
      else
        log_info "install-service not implemented for $_hga_method."
      fi
      exit 0
      ;;
    uninstall-service)
      if [ "$_hga_method" = "libscript_native" ] || [ "$_hga_method" = "system" ]; then
        SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
        export SCRIPT_NAME
        # shellcheck disable=SC1090,SC1091
        . "${SCRIPT_NAME}"
        _hga_svc="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-$_hga_comp}}"
        libscript_uninstall_service "$_hga_svc" "$@"
      else
        log_info "uninstall-service not implemented for $_hga_method."
      fi
      exit 0
      ;;
    uninstall)
      if [ "$_hga_method" = "libscript_native" ]; then
        if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${_hga_ver}"; fi
        log_info "Uninstalling ${_hga_comp} ${_hga_ver}..."
        rm -rf "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/${_hga_comp}/${EXACT_VERSION}"
        rm -f "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/${_hga_comp}/${_hga_ver}"
      else
        log_info "Uninstall not implemented or supported for $_hga_method."
      fi
      exit 0
      ;;
  esac
  return 1
}

# ## libscript_resolve_github_latest
# Resolves the latest release tag for a GitHub repository (owner/repo) while respecting offline mode.
libscript_resolve_github_latest() {
  _rgl_repo="${1:-}"
  _rgl_fallback="${2:-v0.5.7}"
  if [ "${LIBSCRIPT_OFFLINE:-0}" = "1" ] || [ -z "$_rgl_repo" ]; then
    printf '%s\n' "$_rgl_fallback"
    return 0
  fi
  _rgl_tag=$(git ls-remote --tags --refs "https://github.com/${_rgl_repo}.git" 2>/dev/null | awk -F'/' '{print $NF}' | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' | tail -n 1 || true)
  if [ -n "$_rgl_tag" ]; then
    printf '%s\n' "$_rgl_tag"
  else
    printf '%s\n' "$_rgl_fallback"
  fi
}

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_ver_caller_dir:-}" ] && SCRIPT_DIR="$_ver_caller_dir"
[ -n "${_ver_caller_this:-}" ] && THIS_FILE="$_ver_caller_this"
unset _ver_caller_this _ver_caller_dir || true
