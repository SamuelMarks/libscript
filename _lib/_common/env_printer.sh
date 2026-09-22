#!/bin/sh
# ## Overview
# Environment variable exporter and formatting utility for LibScript.
#
# ## Usage
# Outputs environment configurations for evaluated components.

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
# # LibScript Environment Printer Utility
#
#
# If PREFIX_PATH is provided, it will be added to the PATH variable.

# ## libscript_print_env
# Executes libscript_print_env functionality.
libscript_print_env() {
  _format="${1:-sh}"
  _prefix_path="${2:-}"

  # Standardize format names
  case "$_format" in
    dockerfile) _format="docker" ;;
    envfile)    _format="docker_compose" ;;
  esac

  # 1. Print PATH modification if prefix provided
  if [ -n "$_prefix_path" ]; then
    case "$_format" in
      docker)         printf '%s\n' "ENV PATH=\"$_prefix_path/bin:\$PATH\"" ;;
      docker_compose) printf '%s\n' "PATH=$_prefix_path/bin:\$PATH" ;;
      powershell)
        cat <<EOF
if (\$env:PATH -notlike '*$_prefix_path/bin*') {
  \$env:PATH = "$_prefix_path/bin;" + \$env:PATH
}
EOF
        ;;
      cmd)
        cat <<EOF
echo %PATH% | findstr /i /c:"$_prefix_path/bin" >nul || SET "PATH=$_prefix_path/bin;%PATH%"
EOF
        ;;
      json)           # Handled later in the full env dump
        ;;
      *)
        cat <<EOF
if case ":\${PATH:-}:" in *":$_prefix_path/bin:"*) false;; *) true;; esac; then
  export PATH="$_prefix_path/bin:\$PATH"
fi
EOF
        ;;
    esac
  fi

  # 2. Source component's env.sh and print other variables
  # We use an isolated subshell to avoid polluting or leaking the caller environment
  if [ -f "$SCRIPT_DIR/env.sh" ]; then
    _filter="^(PWD|SHLVL|_|PATH|FORMAT|SCRIPT_DIR|PREFIX|STACK|SCRIPT_NAME|LIBSCRIPT_DATA_DIR|HOME|USER)="
    env -i \
      PATH="$PATH" \
      FORMAT="$_format" \
      SCRIPT_DIR="$SCRIPT_DIR" \
      PREFIX="$_prefix_path" \
      LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}" \
      HOME="${HOME:-/root}" \
      USER="${USER:-root}" \
      sh << 'EOF_SH'
            # Source the env.sh
            # shellcheck disable=SC1090
            . "$SCRIPT_DIR/env.sh" >/dev/null 2>&1
            if [ -f "$LIBSCRIPT_DATA_DIR/dyn_env.sh" ]; then
              . "$LIBSCRIPT_DATA_DIR/dyn_env.sh" >/dev/null 2>&1
            fi

            # Filter out internal variables
            _filter="^(PWD|SHLVL|_|PATH|FORMAT|SCRIPT_DIR|PREFIX|STACK|SCRIPT_NAME|LIBSCRIPT_DATA_DIR|HOME|USER)="

            case "$FORMAT" in
            docker)
            env | grep -vE "$_filter" | while read -r line; do
              [ -z "$line" ] && continue
              printf '%s\n' "ENV ${line%%=*}=\"${line#*=}\""
            done
            ;;
            docker_compose)
            env | grep -vE "$_filter"
            ;;
            powershell)
            env | grep -vE "$_filter" | while read -r line; do
              [ -z "$line" ] && continue
              printf '%s\n' "\$env:${line%%=*}=\"${line#*=}\""
            done
            ;;
            cmd)
            env | grep -vE "$_filter" | while read -r line; do
              [ -z "$line" ] && continue
              printf '%s\n' "SET ${line%%=*}=\"${line#*=}\""
            done
            ;;
            json)
            if command -v jq >/dev/null 2>&1; then
            env | grep -vE "$_filter" | jq -R -s '
              split("\n") | map(select(length > 0)) |
              map(split("=")) | map({(.[0]): (.[1:] | join("="))}) | add
            '
            else
            # Minimal JSON fallback
            printf "{"
            first=1
            env | grep -vE "$_filter" | while read -r line; do
              [ -z "$line" ] && continue
              [ "$first" = 0 ] && printf ","
              printf "\"%s\":\"%s\"" "${line%%=*}" "${line#*=}"
              first=0
            done
            printf "}\n"
            fi
            ;;
            *)
            env | grep -vE "$_filter" | while read -r line; do
              [ -z "$line" ] && continue
              printf '%s\n' "export ${line%%=*}=\"${line#*=}\""
            done
            ;;
            esac
EOF_SH
  fi
}
