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

# ## libscript_expand_manifest_vars
# Pure POSIX awk-based expander for ${VAR:-default}, ${VAR}, and $VAR references in manifest strings.
libscript_expand_manifest_vars() {
  _emv_val="${1:-}"
  case "$_emv_val" in
    *'$'*)
      _emv_val=$(awk -v input="$_emv_val" '
        BEGIN {
          s = input
          for (pass = 0; pass < 3; pass++) {
            out = ""
            while (match(s, /\$\{[A-Za-z_][A-Za-z0-9_]*(:-[^}]*)?\}/)) {
              out = out substr(s, 1, RSTART - 1)
              token = substr(s, RSTART + 2, RLENGTH - 3)
              sep = index(token, ":-")
              if (sep > 0) {
                k = substr(token, 1, sep - 1)
                def_val = substr(token, sep + 2)
                v = (k in ENVIRON && ENVIRON[k] != "") ? ENVIRON[k] : def_val
              } else {
                k = token
                v = (k in ENVIRON) ? ENVIRON[k] : ""
              }
              out = out v
              s = substr(s, RSTART + RLENGTH)
            }
            s = out s
            out2 = ""
            while (match(s, /\$[A-Za-z_][A-Za-z0-9_]*/)) {
              out2 = out2 substr(s, 1, RSTART - 1)
              k = substr(s, RSTART + 1, RLENGTH - 1)
              v = (k in ENVIRON) ? ENVIRON[k] : ""
              out2 = out2 v
              s = substr(s, RSTART + RLENGTH)
            }
            s = out2 s
          }
          print s
        }
      ' 2>/dev/null || printf '%s' "$_emv_val")
      ;;
  esac
  printf '%s\n' "$_emv_val"
}

# ## libscript_ensure_default_env_vars
# Sets resilient fallback values for common deployment variables before sourcing .env files.
libscript_ensure_default_env_vars() {
  _ede_dir="${1:-.}"
  if [ -d "$_ede_dir" ]; then
    _ede_dir=$(cd -- "$_ede_dir" && pwd)
  fi
  _ede_default_user="${SERVICE_USER:-${REMOTE_USER:-${SUDO_USER:-${ADMIN_USER:-}}}}"
  if [ -z "$_ede_default_user" ]; then
    _ede_default_user=$(id -un 2>/dev/null || whoami 2>/dev/null || printf 'root')
  fi
  : "${REMOTE_USER:=$_ede_default_user}"
  : "${REMOTE_GROUP:=$REMOTE_USER}"
  if [ -z "${REMOTE_HOME:-}" ]; then
    if [ "$REMOTE_USER" = "root" ]; then
      REMOTE_HOME="/root"
    elif [ -r "/etc/passwd" ]; then
      REMOTE_HOME=$(awk -F: -v u="$REMOTE_USER" '$1==u {print $6; exit}' /etc/passwd 2>/dev/null || true)
    fi
    if [ -z "${REMOTE_HOME:-}" ]; then
      if [ -d "/home/${REMOTE_USER}" ]; then
        REMOTE_HOME="/home/${REMOTE_USER}"
      else
        REMOTE_HOME="${HOME:-/root}"
      fi
    fi
  fi
  : "${REMOTE_APP_DIR:=$_ede_dir}"
  : "${SERVICE_USER:=$REMOTE_USER}"
  : "${SERVICE_GROUP:=$REMOTE_GROUP}"
  : "${DATA_DISK_MOUNT:=/mnt/data}"
  : "${DATA_MOUNT_DIR:=/mnt/data}"
  : "${TMP_DATA_DIR:=/tmp/data}"
  export REMOTE_USER REMOTE_GROUP REMOTE_HOME REMOTE_APP_DIR SERVICE_USER SERVICE_GROUP DATA_DISK_MOUNT DATA_MOUNT_DIR TMP_DATA_DIR

  for _ede_bin_dir in "${REMOTE_HOME}/.local/bin" "${REMOTE_HOME}/.cargo/bin" "/root/.local/bin" "/usr/local/bin"; do
    if [ -d "$_ede_bin_dir" ]; then
      case ":${PATH:-}:" in
        *":${_ede_bin_dir}:"*) ;;
        *) export PATH="${_ede_bin_dir}:${PATH:-/usr/bin:/bin}" ;;
      esac
    fi
  done
  for _ede_node_bin in "${REMOTE_HOME}/.libscript/nodejs/"*/bin "/root/.libscript/nodejs/"*/bin "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/nodejs/"*/bin; do
    if [ -d "$_ede_node_bin" ]; then
      case ":${PATH:-}:" in
        *":${_ede_node_bin}:"*) ;;
        *) export PATH="${_ede_node_bin}:${PATH:-/usr/bin:/bin}" ;;
      esac
    fi
  done
}

# ## libscript_source_env_preserve_existing
# Sources an .env file without clobbering variables already set in the environment.
libscript_source_env_preserve_existing() {
  _sep_file="$1"
  [ -f "$_sep_file" ] || return 0
  _sep_snap=$(mktemp "${TMPDIR:-/tmp}/libscript_env_snap.XXXXXX" 2>/dev/null || printf '%s' "${TMPDIR:-/tmp}/libscript_env_snap.$$")
  export -p > "$_sep_snap" 2>/dev/null || true
  set -a
  set +u
  # shellcheck disable=SC1090
  . "$_sep_file" 2>/dev/null || true
  set -u
  set +a
  # shellcheck disable=SC1090
  . "$_sep_snap" 2>/dev/null || true
  rm -f "$_sep_snap"
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
                  docker)         printf 'ENV PATH="%s:$PATH"
' "$_p" ;;
                  docker_compose) printf 'PATH=%s:$PATH
' "$_p" ;;
                  powershell)     printf 'if ($env:PATH -notlike \047*%s*\047) {
  $env:PATH = "%s;" + $env:PATH
}
' "$_p" "$_p" ;;
                  cmd)            printf 'echo %%PATH%% | findstr /i /c:"%s" >nul || SET "PATH=%s;%%PATH%%"
' "$_p" "$_p" ;;
                  fish)           printf 'if not contains "%s" $PATH
  set -gx PATH "%s" $PATH
end
' "$_p" "$_p" ;;
                  *)              printf 'if case ":${PATH:-}:" in *":%s:"*) false;; *) true;; esac; then
  export PATH="%s:$PATH"
fi
' "$_p" "$_p" ;;
                esac
              done
              IFS="$_old_ifs"
            fi

            _filter="^(PWD|SHLVL|_|PATH|FORMAT|COMP_DIR|SCRIPT_DIR|PREFIX|STACK|SCRIPT_NAME|LIBSCRIPT_ROOT_DIR|LIBSCRIPT_HOME|LIBSCRIPT_DATA_DIR|HOME|USER|THIS_FILE)="

            case "$FORMAT" in
              docker)
                env | grep -vE "$_filter" | while read -r line; do
                  [ -z "$line" ] && continue
                  printf 'ENV %s="%s"
' "${line%%=*}" "${line#*=}"
                done
                ;;
              docker_compose)
                env | grep -vE "$_filter"
                ;;
              powershell)
                env | grep -vE "$_filter" | while read -r line; do
                  [ -z "$line" ] && continue
                  printf '$env:%s="%s"
' "${line%%=*}" "${line#*=}"
                done
                ;;
              cmd)
                env | grep -vE "$_filter" | while read -r line; do
                  [ -z "$line" ] && continue
                  printf 'SET "%s=%s"
' "${line%%=*}" "${line#*=}"
                done
                ;;
              json)
                if command -v jq >/dev/null 2>&1; then
                  env | grep -vE "^(PWD|SHLVL|_|FORMAT|COMP_DIR|SCRIPT_DIR|PREFIX|STACK|SCRIPT_NAME|LIBSCRIPT_ROOT_DIR|LIBSCRIPT_DATA_DIR|HOME|USER|THIS_FILE)=" | jq -R -s '
                    split("
") | map(select(length > 0)) |
                    map(split("=")) | map({(.[0]): (.[1:] | join("="))}) | add
                  '
                else
                  printf '{"PATH":"%s"}
' "${PREFIX:+$PREFIX/bin:}$PATH"
                fi
                ;;
              *)
                env | grep -vE "$_filter" | while read -r line; do
                  [ -z "$line" ] && continue
                  printf 'export %s="%s"
' "${line%%=*}" "${line#*=}"
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

  for _hm_ef in "$_hm_dir/.env" "$_hm_dir/.env.secrets" "$_hm_dir/.env.libscript"; do
    libscript_source_env_preserve_existing "$_hm_ef"
  done

  libscript_ensure_default_env_vars "$_hm_dir"

  command -v jq >/dev/null 2>&1 || return 0

  _hm_tmp=$(mktemp 2>/dev/null || printf '%s' "${TMPDIR:-/tmp}/libscript_hm_deps.$$")
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/resolve_stack.sh" ]; then
    env -u SCRIPT_NAME -u STACK "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/resolve_stack.sh" "$_hm_json" 2>/dev/null | jq -r '.selected[]? | "\(.name) \(.version // "latest")"' > "$_hm_tmp" 2>/dev/null || true
  fi
  if [ ! -s "$_hm_tmp" ]; then
    jq -r '
      def norm(n): (n | tostring | ascii_downcase) as $s | if $s == "postgresql" then "postgres" elif $s == "node" then "nodejs" elif $s == "redis" then "valkey" else $s end;
      (
        [ (.dependencies // .deps // {}) | if type == "object" then to_entries[] | select(.key != "runtime" and .key != "build" and .key != "optional") | "\(norm(.key)) \(if (.value | type) == "object" then (.value.version // "latest") elif (.value | type) == "string" or (.value | type) == "number" then .value else "latest" end)" elif type == "array" then .[] | if type == "string" then "\(norm(.)) latest" elif type == "object" and .name then "\(norm(.name)) \(.version // "latest")" else empty end else empty end ] +
        [ (.dependencies.runtime // [])[]? | if type == "string" then "\(norm(.)) latest" elif type == "object" and .name then "\(norm(.name)) \(.version // "latest")" else empty end ] +
        [ ((.databases // .infrastructure.databases) | if type == "object" then to_entries[] | select((.value | type) == "object") | "\(norm(.value.engine // .value.type // "postgres")) \(.value.version // "latest")" elif type == "array" then .[] | select(type == "object") | "\(norm(.engine // .type // "postgres")) \(.version // "latest")" else empty end) ]
      )[]
    ' "$_hm_json" > "$_hm_tmp" 2>/dev/null || true
  fi

  _hm_saved_script_dir="${SCRIPT_DIR:-}"
  _hm_saved_this_file="${THIS_FILE:-}"
  _hm_saved_stack="${STACK:-}"
  while read -r _dep_pkg _dep_ver <&3; do
    [ -z "$_dep_pkg" ] && continue
    [ "$_dep_ver" = "null" ] || [ -z "$_dep_ver" ] && _dep_ver="latest"
    _pkg_up=$(printf '%s' "$_dep_pkg" | tr '[:lower:]-' '[:upper:]_')
    export "${_pkg_up}_VERSION=${_dep_ver}"
    export LIBSCRIPT_VERSION="${_dep_ver}"
    for _cat_name in $(ls -1 "${LIBSCRIPT_ROOT_DIR}/_lib" 2>/dev/null || true); do
      _cat_dir="${LIBSCRIPT_ROOT_DIR}/_lib/${_cat_name}"
      if [ -f "${_cat_dir}/${_dep_pkg}/env.sh" ]; then
        STACK=""
        SCRIPT_NAME="${_cat_dir}/${_dep_pkg}/env.sh"
        # shellcheck disable=SC1090
        . "${SCRIPT_NAME}" </dev/null || true
        unset SCRIPT_NAME || true
      fi
    done
  done 3< "$_hm_tmp"
  SCRIPT_DIR="$_hm_saved_script_dir"
  THIS_FILE="$_hm_saved_this_file"
  STACK="$_hm_saved_stack"
  export STACK
  unset SCRIPT_NAME || true
  rm -f "$_hm_tmp"

  if [ -z "${UV_BIN:-}" ]; then
    UV_BIN=$(command -v uv 2>/dev/null || printf 'uv')
    export UV_BIN
  fi
  if [ -z "${NPX_BIN:-}" ]; then
    NPX_BIN=$(command -v npx 2>/dev/null || printf 'npx')
    export NPX_BIN
  fi
}

# ## libscript_print_manifest_env
# Prints the combined environment for all dependencies in a manifest file.
libscript_print_manifest_env() {
  _pm_fmt="${1:-sh}"
  _pm_json="${2:-libscript.json}"
  if [ ! -f "$_pm_json" ]; then
    printf 'Error: Manifest file %s not found.\n' "$_pm_json" >&2
    return 1
  fi
  command -v jq >/dev/null 2>&1 || return 1

  _pm_tmp=$(mktemp 2>/dev/null || printf '%s' "${TMPDIR:-/tmp}/libscript_pm_deps.$$")
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/resolve_stack.sh" ]; then
    env -u SCRIPT_NAME -u STACK "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/resolve_stack.sh" "$_pm_json" 2>/dev/null | jq -r '.selected[]? | "\(.name) \(.version // "latest")"' > "$_pm_tmp" 2>/dev/null || true
  fi
  if [ ! -s "$_pm_tmp" ]; then
    jq -r '
      def norm(n): (n | tostring | ascii_downcase) as $s | if $s == "postgresql" then "postgres" elif $s == "node" then "nodejs" elif $s == "redis" then "valkey" else $s end;
      (
        [ (.dependencies // .deps // {}) | if type == "object" then to_entries[] | select(.key != "runtime" and .key != "build" and .key != "optional") | "\(norm(.key)) \(if (.value | type) == "object" then (.value.version // "latest") elif (.value | type) == "string" or (.value | type) == "number" then .value else "latest" end)" elif type == "array" then .[] | if type == "string" then "\(norm(.)) latest" elif type == "object" and .name then "\(norm(.name)) \(.version // "latest")" else empty end else empty end ] +
        [ (.dependencies.runtime // [])[]? | if type == "string" then "\(norm(.)) latest" elif type == "object" and .name then "\(norm(.name)) \(.version // "latest")" else empty end ] +
        [ ((.databases // .infrastructure.databases) | if type == "object" then to_entries[] | select((.value | type) == "object") | "\(norm(.value.engine // .value.type // "postgres")) \(.value.version // "latest")" elif type == "array" then .[] | select(type == "object") | "\(norm(.engine // .type // "postgres")) \(.version // "latest")" else empty end) ]
      )[]
    ' "$_pm_json" > "$_pm_tmp" 2>/dev/null || true
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
  done 3< "$_pm_tmp" 2>/dev/null || true
  rm -f "$_pm_tmp"
}
