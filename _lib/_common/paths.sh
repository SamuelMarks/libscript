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
# # LibScript Path Resolution Module
#
# ## Overview
# This module provides standardized path resolution for LibScript components.
# It ensures that downloads, logs, binaries, and data are stored in consistent 
# locations across the entire ecosystem.
#
# ## Usage
# Sourced by `setup_base.sh` or component scripts.
#
# ```sh
# . "$LIBSCRIPT_ROOT_DIR/_lib/_common/paths.sh"
# resolve_component_paths
# ```

resolve_component_paths() {
  # Requirement: PACKAGE_NAME and LIBSCRIPT_ROOT_DIR must be set.
  if [ -z "${PACKAGE_NAME:-}" ]; then
    PACKAGE_NAME=$(basename "$(pwd)")
  fi
  
  # 1. Base Cache & Download Directory
  # Default: <root>/cache/downloads/<package_name>
  _base_cache_dir="${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache}"
  DOWNLOAD_DIR="${DOWNLOAD_DIR:-$_base_cache_dir/downloads/$PACKAGE_NAME}"
  
  # 2. Local Data Directory (for binaries, etc.)
  # Default: /tmp/libscript_data/<package_name> (or via LIBSCRIPT_DATA_DIR)
  _global_data_dir="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"
  DATA_DIR="${DATA_DIR:-$_global_data_dir/$PACKAGE_NAME}"
  BIN_DIR="${BIN_DIR:-$DATA_DIR/bin}"
  
  # 3. Logs Directory
  # Default: /tmp/libscript_logs/<package_name> (or via LIBSCRIPT_LOGS_DIR)
  _global_logs_dir="${LIBSCRIPT_LOGS_DIR:-${TMPDIR:-/tmp}/libscript_logs}"
  LOGS_DIR="${LOGS_DIR:-$_global_logs_dir/$PACKAGE_NAME}"
  
  export DOWNLOAD_DIR DATA_DIR BIN_DIR LOGS_DIR
  
  # Ensure directories exist
  mkdir -p -- "$DOWNLOAD_DIR" "$DATA_DIR" "$BIN_DIR" "$LOGS_DIR"
  
  debug "Resolved paths for $PACKAGE_NAME:"
  debug "  DOWNLOAD_DIR: $DOWNLOAD_DIR"
  debug "  DATA_DIR:     $DATA_DIR"
  debug "  BIN_DIR:      $BIN_DIR"
  debug "  LOGS_DIR:     $LOGS_DIR"
}

# Standardized logging fallback if cli.sh wasn't sourced
if ! command -v debug >/dev/null 2>&1; then
  debug() { [ "${LIBSCRIPT_DEBUG:-0}" = "1" ] && printf "[DEBUG] %s\n" "$*" >&2; }
fi
