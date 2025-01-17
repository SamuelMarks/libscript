#!/bin/sh

# shellcheck disable=SC2236
if [ ! -z "${SCRIPT_NAME+x}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ ! -z "${BASH_VERSION+x}" ]; then
  # shellcheck disable=SC3028 disable=SC3054
  this_file="${BASH_SOURCE[0]}"
  # shellcheck disable=SC3040
  set -o pipefail
elif [ ! -z "${ZSH_VERSION+x}" ]; then
  # shellcheck disable=SC2296
  this_file="${(%):-%x}"
  # shellcheck disable=SC3040
  set -o pipefail
else
  this_file="${0}"
fi
set -feu

STACK="${STACK:-:}"
case "${STACK}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    return ;;
  *)
    printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
STACK="${STACK}${this_file}"':'
export STACK

export SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DIR="${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DIR:-${REPOS_DIR:-${TMPDIR:-/tmp}/serve-actix-diesel-auth-scaffold}/serve-actix-diesel-auth-scaffold}"
export SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_BUILD_DIR="${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_BUILD_DIR:-${BUILD_DIR:-${TMPDIR:-/tmp}/serve-actix-diesel-auth-scaffold}/serve-actix-diesel-auth-scaffold}"
