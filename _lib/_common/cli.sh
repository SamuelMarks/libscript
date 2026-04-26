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
# # LibScript CLI Utility Module (POSIX)
#
# ## Overview
# This module provides reusable CLI utilities for LibScript components, 
# primarily focused on consistent argument parsing and standardized output.
#
# ## Usage
# Source this script in your component's `cli.sh`.
#
# ```sh
# . "$LIBSCRIPT_ROOT_DIR/_lib/_common/cli.sh"
# parse_args "$@"
# ```
#
# ## Functions
#
# ### parse_args "$@"
# Parses common LibScript arguments and sets corresponding environment variables.
#
# Supported Arguments:
#   --tags <T>          Sets CUSTOM_TAGS.
#   --no-default-tags   Sets USE_DEFAULT_TAGS=false.
#   --bootstrap <S>     Sets BOOTSTRAP_SCRIPT.
#   --dry-run           Sets DRY_RUN=true.
#
# Remaining non-option arguments are stored in the `ARGS` variable.

# Standardized logging
info()  { printf "[INFO]  %s\n" "$*" >&2; }
warn()  { printf "[WARN]  %s\n" "$*" >&2; }
error() { printf "[ERROR] %s\n" "$*" >&2; }
debug() { [ "${LIBSCRIPT_DEBUG:-0}" = "1" ] && printf "[DEBUG] %s\n" "$*" >&2; }

parse_args() {
  USE_DEFAULT_TAGS=true
  CUSTOM_TAGS=""
  BOOTSTRAP_SCRIPT=""
  DRY_RUN="${DRY_RUN:-false}"
  ARGS=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --help|-h)
        echo "Usage: [OPTIONS]"
        exit 0
        ;;

      --no-default-tags)
        USE_DEFAULT_TAGS=false
        shift
        ;;
      --tags)
        if [ -n "$CUSTOM_TAGS" ]; then
          CUSTOM_TAGS="$CUSTOM_TAGS $2"
        else
          CUSTOM_TAGS="$2"
        fi
        shift 2
        ;;
      --bootstrap)
        BOOTSTRAP_SCRIPT="$2"
        shift 2
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      *)
        if [ -z "$ARGS" ]; then
          ARGS="$1"
        else
          ARGS="$ARGS $1"
        fi
        shift
        ;;
    esac
  done
  
  export USE_DEFAULT_TAGS CUSTOM_TAGS BOOTSTRAP_SCRIPT DRY_RUN
}
