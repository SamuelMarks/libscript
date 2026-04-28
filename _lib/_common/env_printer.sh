#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'
# # LibScript Environment Printer Utility
#
# ## Overview
# This module provides a standardized way to print environment variables
# in various formats (sh, docker, docker_compose, powershell, cmd, json).
#
# ## Usage
# . "$LIBSCRIPT_ROOT_DIR/_lib/_common/env_printer.sh"
# libscript_print_env [FORMAT] [PREFIX_PATH]
#
# If PREFIX_PATH is provided, it will be added to the PATH variable.

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
      docker)         echo "ENV PATH=\"$_prefix_path/bin:\$PATH\"" ;;
      docker_compose) echo "PATH=$_prefix_path/bin:\$PATH" ;;
      powershell)     echo "\$env:PATH=\"$_prefix_path/bin;\" + \$env:PATH" ;;
      cmd)            echo "SET PATH=\"$_prefix_path/bin;%PATH%\"" ;;
      json)           # Handled later in the full env dump
        ;;
      *)              echo "export PATH=\"$_prefix_path/bin:\$PATH\"" ;;
    esac
  fi

  # 2. Source component's env.sh and print other variables
  # We use a subshell to avoid polluting the current environment
  if [ -f "$SCRIPT_DIR/env.sh" ]; then
    # We pass FORMAT and SCRIPT_DIR to the subshell
    env PATH="$PATH" \
           FORMAT="$_format" \
           SCRIPT_DIR="$SCRIPT_DIR" \
           PREFIX="$_prefix_path" \
           LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}" \
           sh -c '
      # Source the env.sh
      # shellcheck disable=SC1090
      . "$SCRIPT_DIR/env.sh" >/dev/null 2>&1
      if [ -f "$LIBSCRIPT_DATA_DIR/dyn_env.sh" ]; then
        . "$LIBSCRIPT_DATA_DIR/dyn_env.sh" >/dev/null 2>&1
      fi
      
      # Filter out internal variables
      _filter="^(PWD|SHLVL|_|PATH|FORMAT|SCRIPT_DIR|PREFIX|STACK|SCRIPT_NAME)="
      
      case "$FORMAT" in
        docker)
          env | grep -vE "$_filter" | while read -r line; do
            echo "ENV ${line%%=*}=\"${line#*=}\""
          done
          ;;
        docker_compose)
          env | grep -vE "$_filter"
          ;;
        powershell)
          env | grep -vE "$_filter" | while read -r line; do
            echo "\$env:${line%%=*}=\"${line#*=}\""
          done
          ;;
        cmd)
          env | grep -vE "$_filter" | while read -r line; do
            echo "SET ${line%%=*}=\"${line#*=}\""
          done
          ;;
        json)
          if command -v jq >/dev/null 2>&1; then
            env | grep -vE "$_filter" | jq -R -s "
              split(\"\n\") | map(select(length > 0)) | 
              map(split(\"=\")) | map({(.[0]): (.[1:] | join(\"=\"))}) | add
            "
          else
            # Minimal JSON fallback
            printf "{"
            first=1
            env | grep -vE "$_filter" | while read -r line; do
              [ "$first" = 0 ] && printf ","
              printf "\"%s\":\"%s\"" "${line%%=*}" "${line#*=}"
              first=0
            done
            printf "}\n"
          fi
          ;;
        *)
          env | grep -vE "$_filter" | while read -r line; do
            echo "export ${line%%=*}=\"${line#*=}\""
          done
          ;;
      esac
    '
  fi
}
