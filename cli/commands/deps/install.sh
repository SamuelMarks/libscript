#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
if [ -z "${LIBSCRIPT_ROOT_DIR:-}" ]; then
  _tmp_dir="$SCRIPT_DIR"
  while [ "$_tmp_dir" != "/" ] && [ ! -f "$_tmp_dir/libscript.sh" ]; do
    _tmp_dir="$(dirname "$_tmp_dir")"
  done
  LIBSCRIPT_ROOT_DIR="$_tmp_dir"
fi
if [ "$CMD" = "install-deps" ]; then
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

  if [ -z "${LIBSCRIPT_SECRETS:-}" ]; then
    json_secrets=$(jq -r 'if .secrets then .secrets else empty end' "$json_file" 2>/dev/null)
    if [ "$json_secrets" != "null" ] && [ -n "$json_secrets" ]; then
      export LIBSCRIPT_SECRETS="$json_secrets"
    else
      export LIBSCRIPT_SECRETS="${LIBSCRIPT_ROOT_DIR:-$SCRIPT_DIR}/secrets"
    fi
  fi

  deps=$("${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/resolve_stack.sh" "$json_file" 2>/dev/null | jq -r '.selected[] | "\(.name) \(.version // "latest") \(.override // "")"' 2>/dev/null || true)
  if [ -z "$deps" ]; then
    echo "No dependencies found in $json_file."
    exit 0
  fi

  # Parallel Download Phase
  echo "Downloading dependencies in parallel..."
  echo "$deps" | while read -r pkg ver override; do
    if [ -n "$pkg" ]; then
      if [ "$ver" = "null" ]; then ver="latest"; fi
      if [ -z "$override" ] || [ "$override" = "null" ]; then
        "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" download "$pkg" "$ver" &
      fi
    fi
  done
  wait

  # Serial Install Phase
  echo "Installing dependencies sequentially..."
  echo "$deps" | while read -r pkg ver override; do
    if [ -n "$pkg" ]; then
      if [ "$ver" = "null" ]; then ver="latest"; fi
      if [ -n "$override" ] && [ "$override" != "null" ]; then
        echo "Skipping installation of $pkg (override provided: $override)"
      else
        echo "Installing $pkg $ver..."
        "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" install "$pkg" "$ver"
      fi
    fi
  done
  exit 0
fi
