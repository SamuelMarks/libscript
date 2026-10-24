#!/bin/sh
# ## Overview
# Environment variable exporter and formatting utility for LibScript.
# Supports single-component evaluation (`libscript_print_env <format> <prefix>`)
# and manifest-wide multi-component evaluation (`libscript_print_manifest_env <format> <manifest>`).
#
# ## Usage
# Outputs environment configurations for evaluated components.

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

# ## _emit_path_entry
# Emits a single PATH directory addition in the requested shell/container format.
_emit_path_entry() {
  _ep_fmt="${1:-sh}"
  _ep_dir="${2:-}"
  [ -z "$_ep_dir" ] && return 0
  case "$_ep_fmt" in
    docker)
      printf '%s
' "ENV PATH="${_ep_dir}:\$PATH""
      ;;
    docker_compose)
      printf '%s
' "PATH=${_ep_dir}:\$PATH"
      ;;
    powershell)
      cat <<EOF
if (\$env:PATH -notlike '*${_ep_dir}*') {
  \$env:PATH = "${_ep_dir};" + \$env:PATH
}
EOF
      ;;
    cmd)
      cat <<EOF
echo %PATH% | findstr /i /c:"${_ep_dir}" >nul || SET "PATH=${_ep_dir};%PATH%"
EOF
      ;;
    fish)
      cat <<EOF
if not contains "${_ep_dir}" \$PATH
  set -gx PATH "${_ep_dir}" \$PATH
end
EOF
      ;;
    json)
      ;;
    *)
      cat <<EOF
if case ":\${PATH:-}:" in *":${_ep_dir}:"*) false;; *) true;; esac; then
  export PATH="${_ep_dir}:\$PATH"
fi
EOF
      ;;
  esac
}

# ## libscript_print_env
# Evaluates a component's env.sh and emits PATH and exported variables in the target format.
libscript_print_env() {
  _format="${1:-sh}"
  _prefix_path="${2:-}"
  _comp_dir="${COMP_DIR:-$SCRIPT_DIR}"

  case "$_format" in
    dockerfile) _format="docker" ;;
    envfile)    _format="docker_compose" ;;
    ps1)        _format="powershell" ;;
  esac

  if [ -n "$_prefix_path" ] && [ "$_format" != "json" ]; then
    _emit_path_entry "$_format" "${_prefix_path}/bin"
  fi

  if [ -f "$_comp_dir/env.sh" ]; then
    _comp_name=$(basename "$_comp_dir")
    _comp_up=$(printf '%s' "$_comp_name" | tr '[:lower:]-' '[:upper:]_')
    _comp_ver="${VERSION:-}"
    if [ -z "$_comp_ver" ] && [ -n "$_prefix_path" ]; then
      _comp_ver=$(basename "$_prefix_path")
    fi
    env -i PATH="/usr/bin:/bin" FORMAT="$_format" COMP_DIR="$_comp_dir" PREFIX="$_prefix_path" "${_comp_up}_VERSION=${_comp_ver:-latest}" LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR}" LIBSCRIPT_HOME="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}" LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}" HOME="${HOME:-/root}" USER="${USER:-root}" sh << 'EOF_SH'
            SCRIPT_NAME="$COMP_DIR/env.sh"
            export SCRIPT_NAME
            # shellcheck disable=SC1090
            . "$COMP_DIR/env.sh" >/dev/null 2>&1 || true
            if [ -f "$LIBSCRIPT_DATA_DIR/dyn_env.sh" ]; then
              # shellcheck disable=SC1090
              . "$LIBSCRIPT_DATA_DIR/dyn_env.sh" >/dev/null 2>&1 || true
            fi

            if [ "$FORMAT" != "json" ]; then
              _old_ifs="$IFS"
              IFS=":"
              for _p in $PATH; do
                [ -z "$_p" ] && continue
                [ "$_p" = "/usr/bin" ] || [ "$_p" = "/bin" ] && continue
                [ -n "$PREFIX" ] && [ "$_p" = "$PREFIX/bin" ] && continue
                case "$FORMAT" in
                  docker)         printf 'ENV PATH="%s:$PATH"\n' "$_p" ;;
                  docker_compose) printf 'PATH=%s:$PATH\n' "$_p" ;;
                  powershell)     printf 'if ($env:PATH -notlike \047*%s*\047) {\n  $env:PATH = "%s;" + $env:PATH\n}\n' "$_p" "$_p" ;;
                  cmd)            printf 'echo %%PATH%% | findstr /i /c:"%s" >nul || SET "PATH=%s;%%PATH%%"\n' "$_p" "$_p" ;;
                  fish)           printf 'if not contains "%s" $PATH\n  set -gx PATH "%s" $PATH\nend\n' "$_p" "$_p" ;;
                  *)              printf 'if case ":${PATH:-}:" in *":%s:"*) false;; *) true;; esac; then\n  export PATH="%s:$PATH"\nfi\n' "$_p" "$_p" ;;
                esac
              done
              IFS="$_old_ifs"
            fi

            _filter="^(PWD|SHLVL|_|PATH|FORMAT|COMP_DIR|SCRIPT_DIR|PREFIX|STACK|SCRIPT_NAME|LIBSCRIPT_ROOT_DIR|LIBSCRIPT_HOME|LIBSCRIPT_DATA_DIR|HOME|USER|THIS_FILE)="

            case "$FORMAT" in
              docker)
                env | grep -vE "$_filter" | while read -r line; do
                  [ -z "$line" ] && continue
                  printf 'ENV %s="%s"\n' "${line%%=*}" "${line#*=}"
                done
                ;;
              docker_compose)
                env | grep -vE "$_filter"
                ;;
              powershell)
                env | grep -vE "$_filter" | while read -r line; do
                  [ -z "$line" ] && continue
                  printf '$env:%s="%s"\n' "${line%%=*}" "${line#*=}"
                done
                ;;
              cmd)
                env | grep -vE "$_filter" | while read -r line; do
                  [ -z "$line" ] && continue
                  printf 'SET "%s=%s"\n' "${line%%=*}" "${line#*=}"
                done
                ;;
              json)
                if command -v jq >/dev/null 2>&1; then
                  env | grep -vE "^(PWD|SHLVL|_|FORMAT|COMP_DIR|SCRIPT_DIR|PREFIX|STACK|SCRIPT_NAME|LIBSCRIPT_ROOT_DIR|LIBSCRIPT_DATA_DIR|HOME|USER|THIS_FILE)=" | jq -R -s '
                    split("\n") | map(select(length > 0)) |
                    map(split("=")) | map({(.[0]): (.[1:] | join("="))}) | add
                  '
                else
                  printf '{"PATH":"%s"}\n' "${PREFIX:+$PREFIX/bin:}$PATH"
                fi
                ;;
              *)
                env | grep -vE "$_filter" | while read -r line; do
                  [ -z "$line" ] && continue
                  printf 'export %s="%s"\n' "${line%%=*}" "${line#*=}"
                done
                ;;
            esac
EOF_SH
  elif [ "$_format" = "json" ] && [ -n "$_prefix_path" ]; then
    printf '{"PATH":"%s/bin"}
' "$_prefix_path"
  fi
}

# ## libscript_hydrate_manifest_env
# Sources env.sh for all dependencies declared in a libscript.json manifest into the current shell.
libscript_hydrate_manifest_env() {
  _hm_json="${1:-libscript.json}"
  [ ! -f "$_hm_json" ] && return 0
  _hm_dir=$(cd -- "$(dirname -- "$_hm_json")" && pwd)

  if [ -f "$_hm_dir/.env.libscript" ]; then
    set -a
    # shellcheck disable=SC1090,SC1091
    . "$_hm_dir/.env.libscript"
    set +a
  fi

  command -v jq >/dev/null 2>&1 || return 0

  _hm_tmp=$(mktemp 2>/dev/null || printf '%s' "${TMPDIR:-/tmp}/libscript_hm_deps.$$")
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/resolve_stack.sh" ]; then
    "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/resolve_stack.sh" "$_hm_json" 2>/dev/null | jq -r '.selected[]? | "\(.name) \(.version // "latest")"' > "$_hm_tmp" 2>/dev/null || true
  fi
  if [ ! -s "$_hm_tmp" ]; then
    jq -r '(.dependencies // {}) | to_entries[]? | "\(.key) \(if (.value | type) == "object" then (.value.version // "latest") elif (.value | type) == "string" then .value else "latest" end)"' "$_hm_json" > "$_hm_tmp" 2>/dev/null || true
  fi

  while read -r _dep_pkg _dep_ver <&3; do
    [ -z "$_dep_pkg" ] && continue
    [ "$_dep_ver" = "null" ] || [ -z "$_dep_ver" ] && _dep_ver="latest"
    _pkg_up=$(printf '%s' "$_dep_pkg" | tr '[:lower:]-' '[:upper:]_')
    export "${_pkg_up}_VERSION=${_dep_ver}"
    for _cat_name in $(ls -1 "${LIBSCRIPT_ROOT_DIR}/_lib" 2>/dev/null || true); do
      _cat_dir="${LIBSCRIPT_ROOT_DIR}/_lib/${_cat_name}"
      if [ -f "${_cat_dir}/${_dep_pkg}/env.sh" ]; then
        STACK=""
        SCRIPT_NAME="${_cat_dir}/${_dep_pkg}/env.sh"
        export SCRIPT_NAME
        # shellcheck disable=SC1090
        . "${SCRIPT_NAME}" </dev/null || true
      fi
    done
  done 3< "$_hm_tmp"
  rm -f "$_hm_tmp"
}

# ## libscript_print_manifest_env
# Prints the combined environment for all dependencies in a manifest file.
libscript_print_manifest_env() {
  _pm_fmt="${1:-sh}"
  _pm_json="${2:-libscript.json}"
  if [ ! -f "$_pm_json" ]; then
    printf 'Error: Manifest file %s not found.
' "$_pm_json" >&2
    return 1
  fi
  command -v jq >/dev/null 2>&1 || return 1

  _pm_tmp=$(mktemp 2>/dev/null || printf '%s' "${TMPDIR:-/tmp}/libscript_pm_deps.$$")
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/resolve_stack.sh" ]; then
    "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/resolve_stack.sh" "$_pm_json" 2>/dev/null | jq -r '.selected[]? | "\(.name) \(.version // "latest")"' > "$_pm_tmp" 2>/dev/null || true
  fi
  if [ ! -s "$_pm_tmp" ]; then
    jq -r '(.dependencies // {}) | to_entries[]? | "\(.key) \(if (.value | type) == "object" then (.value.version // "latest") elif (.value | type) == "string" then .value else "latest" end)"' "$_pm_json" > "$_pm_tmp" 2>/dev/null || true
  fi

  while read -r _dep_pkg _dep_ver <&3; do
    [ -z "$_dep_pkg" ] && continue
    [ "$_dep_ver" = "null" ] || [ -z "$_dep_ver" ] && _dep_ver="latest"
    _pkg_up=$(printf '%s' "$_dep_pkg" | tr '[:lower:]-' '[:upper:]_')
    export "${_pkg_up}_VERSION=${_dep_ver}"
    for _cat_name in $(ls -1 "${LIBSCRIPT_ROOT_DIR}/_lib" 2>/dev/null || true); do
      _cat_dir="${LIBSCRIPT_ROOT_DIR}/_lib/${_cat_name}"
      if [ -f "${_cat_dir}/${_dep_pkg}/env.sh" ]; then
        COMP_DIR="${_cat_dir}/${_dep_pkg}"
        export COMP_DIR
        libscript_print_env "$_pm_fmt" "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/${_dep_pkg}/${_dep_ver}" </dev/null
      fi
    done
  done 3< "$_pm_tmp"
  rm -f "$_pm_tmp"
}
