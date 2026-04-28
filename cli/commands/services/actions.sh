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
if [ "$cmd" = "start" ] || [ "$cmd" = "stop" ] || [ "$cmd" = "status" ] || [ "$cmd" = "health" ] || [ "$cmd" = "logs" ] || [ "$cmd" = "restart" ] || [ "$cmd" = "up" ] || [ "$cmd" = "down" ]; then
  action="$cmd"
  if [ "$action" = "up" ]; then action="start"; fi
  if [ "$action" = "down" ]; then action="stop"; fi
  follow_logs=0
  skip_hooks=0
  new_args=""
  for arg in "$@"; do
    if [ "$arg" = "-f" ] || [ "$arg" = "--follow" ]; then
      follow_logs=1
    elif [ "$arg" = "--no-hooks" ]; then
      skip_hooks=1
    else
      new_args="$new_args \"$arg\""
    fi
  done
  eval "set -- $new_args"
  
  if [ $# -eq 0 ] || [ "$1" = "libscript.json" ] || [ "${1##*.}" = "json" ]; then
    json_file="${1:-libscript.json}"
    if [ ! -f "$json_file" ]; then
      echo "Error: $json_file not found." >&2
      exit 1
    fi
    if ! command -v jq >/dev/null 2>&1; then
    if [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/utilities/jq/setup.sh" ]; then
      "${LIBSCRIPT_ROOT_DIR:-.}/_lib/utilities/jq/setup.sh"
    fi
  fi
  if ! command -v jq >/dev/null 2>&1; then
      echo "Error: jq is required to parse $json_file." >&2
      exit 1
    fi
    if [ "$skip_hooks" -eq 0 ]; then
      if [ "$action" = "start" ] || [ "$action" = "up" ]; then
        "${LIBSCRIPT_ROOT_DIR:-.}/scripts/run_hooks.sh" "$json_file" "build"
        "${LIBSCRIPT_ROOT_DIR:-.}/scripts/run_hooks.sh" "$json_file" "pre_start"
      fi
    fi

    deps=$("${LIBSCRIPT_ROOT_DIR:-.}/scripts/resolve_stack.sh" "$json_file" 2>/dev/null | jq -r '.selected[] | "\(.name) \(.version // "latest")"' 2>/dev/null || true)
    if [ -n "$deps" ]; then
      echo "$deps" > "$json_file.tmpdeps"
      while read -r pkg ver; do
        if [ -n "$pkg" ]; then
          if [ "$ver" = "null" ]; then ver="latest"; fi
          if [ "$action" = "logs" ] && [ "$follow_logs" = "1" ]; then
            "${this_file}" "$pkg" "$action" "$pkg" "$ver" -f 2>&1 | awk -v prefix="$pkg" '{print "\033[36m" prefix " |\033[0m " $0; fflush()}' &
          elif [ "$action" = "status" ] || [ "$action" = "health" ] || [ "$action" = "logs" ]; then
            echo "=== $pkg ==="
            "${this_file}" "$pkg" "$action" "$pkg" "$ver"
          else
            "${this_file}" "$pkg" "$action" "$pkg" "$ver" &
          fi
        fi
      done < "$json_file.tmpdeps"
      rm -f "$json_file.tmpdeps"
    fi

    if [ "$action" = "start" ] || [ "$action" = "up" ]; then
      "${LIBSCRIPT_ROOT_DIR:-.}/scripts/daemonize.sh" "$action" "$json_file"
      "${LIBSCRIPT_ROOT_DIR:-.}/scripts/setup_ingress.sh" "$action" "$json_file"
    elif [ "$action" = "stop" ] || [ "$action" = "down" ]; then
      "${LIBSCRIPT_ROOT_DIR:-.}/scripts/setup_ingress.sh" "$action" "$json_file"
      "${LIBSCRIPT_ROOT_DIR:-.}/scripts/daemonize.sh" "$action" "$json_file"
    elif [ "$action" = "status" ]; then
      "${LIBSCRIPT_ROOT_DIR:-.}/scripts/daemonize.sh" "$action" "$json_file"
    fi

    wait
    exit 0
  else
    for pkg in "$@"; do
      if [ "$action" = "logs" ] && [ "$follow_logs" = "1" ]; then
        "${this_file}" "$pkg" "$action" "$pkg" "latest" -f 2>&1 | awk -v prefix="$pkg" '{print "\033[36m" prefix " |\033[0m " $0; fflush()}' &
      elif [ "$action" = "status" ] || [ "$action" = "health" ] || [ "$action" = "logs" ]; then
        echo "=== $pkg ==="
        "${this_file}" "$pkg" "$action" "$pkg" "latest"
      else
        "${this_file}" "$pkg" "$action" "$pkg" "latest" &
      fi
    done
    wait
    exit 0
  fi
fi
