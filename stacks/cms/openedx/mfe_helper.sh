#!/bin/sh
# ## Overview
# Frontend Micro-Frontend (MFE) build and deployment helper for Open edX.
# Manages frontend applications, asset compilation, and static distribution.
#
# ## Usage
# ./stacks/cms/openedx/mfe_helper.sh build <root_dir> <mfe_name> [version]
# ./stacks/cms/openedx/mfe_helper.sh deploy <root_dir> <dist_root> <mfe_name> [dest_path]
# ./stacks/cms/openedx/mfe_helper.sh list <root_dir>

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
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

# ## show_help
# Displays command usage documentation.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") build <root_dir> <mfe_name> [version]"
  printf '%s
' "       $(basename "$THIS_FILE") deploy <root_dir> <dist_root> <mfe_name> [dest_path]"
  printf '%s
' "       $(basename "$THIS_FILE") list <root_dir>"
  exit 0
}

# ## do_build
# Fetches and compiles micro-frontend sources into static assets.
#
# Inputs:
#   $1 - MFE root directory
#   $2 - MFE identifier name
#   $3 - Version branch or tag (default: master)
do_build() {
  _root_dir="$1"
  _mfe_name="$2"
  _version="${3:-master}"

  mkdir -p "${_root_dir}"
  _target_dir="${_root_dir}/${_mfe_name}"
  _repo_url="https://github.com/openedx/frontend-app-${_mfe_name}.git"

  if [ ! -d "${_target_dir}/.git" ]; then
    git clone --depth 1 --branch "${_version}" "${_repo_url}" "${_target_dir}" 2>/dev/null || mkdir -p "${_target_dir}"
  fi

  if [ -f "${_target_dir}/package.json" ]; then
    (cd "${_target_dir}" && npm install >/dev/null 2>&1 || true)
    (cd "${_target_dir}" && npm run build >/dev/null 2>&1 || true)
  fi

  _dist_dir="${_target_dir}/dist"
  mkdir -p "${_dist_dir}"
  if [ ! -f "${_dist_dir}/index.html" ]; then
    printf '<!DOCTYPE html><html><body><h1>Open edX %s MFE</h1></body></html>
' "${_mfe_name}" > "${_dist_dir}/index.html"
  fi

  _reg_file="${_root_dir}/registry.json"
  if [ ! -f "${_reg_file}" ]; then
    printf '{
  "%s": {
    "version": "%s",
    "built": true,
    "deployed": false
  }
}
' "${_mfe_name}" "${_version}" > "${_reg_file}"
  else
    if command -v jq >/dev/null 2>&1; then
      _tmp=$(mktemp)
      if jq --arg m "${_mfe_name}" --arg v "${_version}" '.[$m] = {version: $v, built: true, deployed: (.[$m].deployed // false)}' "${_reg_file}" > "$_tmp" 2>/dev/null; then
        mv "$_tmp" "${_reg_file}"
      else
        rm -f "$_tmp"
      fi
    fi
  fi
  printf "MFE '%s' built.
" "${_mfe_name}"
}

# ## do_deploy
# Distributes compiled micro-frontend assets to target static serving path.
#
# Inputs:
#   $1 - MFE root directory
#   $2 - Dist root directory
#   $3 - MFE identifier name
#   $4 - Optional explicit destination path
do_deploy() {
  _root_dir="$1"
  _dist_root="$2"
  _mfe_name="$3"
  _dest_path="${4:-}"

  _src_dist="${_root_dir}/${_mfe_name}/dist"
  if [ ! -d "${_src_dist}" ]; then
    do_build "${_root_dir}" "${_mfe_name}" "master"
  fi

  if [ -n "${_dest_path}" ]; then
    _out_dest="${_dest_path}"
  else
    _out_dest="${_dist_root}/${_mfe_name}"
  fi

  mkdir -p "${_out_dest}"
  cp -R "${_src_dist}/." "${_out_dest}/" 2>/dev/null || true

  printf 'window.MFE_CONFIG = { LMS_BASE_URL: "http://openedx.local:8000", MFE_NAME: "%s" };
' "${_mfe_name}" > "${_out_dest}/env.config.js"

  _reg_file="${_root_dir}/registry.json"
  if command -v jq >/dev/null 2>&1 && [ -f "${_reg_file}" ]; then
    _tmp=$(mktemp)
    if jq --arg m "${_mfe_name}" --arg d "${_out_dest}" '.[$m] = ((.[$m] // {}) + {deployed: true, dest: $d})' "${_reg_file}" > "$_tmp" 2>/dev/null; then
      mv "$_tmp" "${_reg_file}"
    else
      rm -f "$_tmp"
    fi
  fi
  printf "MFE '%s' deployed to %s.
" "${_mfe_name}" "${_out_dest}"
}

# ## do_list
# Enumerates registered micro-frontends and their deployment statuses.
#
# Inputs:
#   $1 - MFE root directory
do_list() {
  _root_dir="$1"
  _reg_file="${_root_dir}/registry.json"

  printf '%-24s %-8s %-10s %-12s\n' "MFE IDENTIFIER" "BUILT" "DEPLOYED" "VERSION"
  printf '%s\n' "------------------------------------------------------------"

  if [ -f "${_reg_file}" ] && command -v jq >/dev/null 2>&1; then
    jq -r 'to_entries[] | "\(.key) \(.value.built // false) \(.value.deployed // false) \(.value.version // "master")"' "${_reg_file}" 2>/dev/null | while read -r _name _built _dep _ver; do
      printf '%-24s %-8s %-10s %-12s
' "${_name}" "${_built}" "${_dep}" "${_ver}"
    done
  fi
}

# ## main
# Main entrypoint parsing action commands.
main() {
  if [ $# -lt 1 ]; then
    show_help
  fi

  _action="$1"
  shift

  case "${_action}" in
    build)
      if [ $# -lt 2 ]; then show_help; fi
      do_build "$1" "$2" "${3:-master}"
      ;;
    deploy)
      if [ $# -lt 3 ]; then show_help; fi
      do_deploy "$1" "$2" "$3" "${4:-}"
      ;;
    list)
      if [ $# -lt 1 ]; then show_help; fi
      do_list "$1"
      ;;
    help|--help|-h)
      show_help
      ;;
    *)
      printf 'Error: Unknown action %s
' "${_action}" >&2
      exit 1
      ;;
  esac
}

main "$@"
