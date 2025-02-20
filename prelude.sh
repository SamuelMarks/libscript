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

STACK="${STACK:-:}${this_file}"':'
export STACK

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$( CDPATH='' cd -- "$( dirname -- "$( readlink -nf -- "${this_file}" )")" && pwd)}"
export LIBSCRIPT_ROOT_DIR

LIBSCRIPT_BUILD_DIR="${LIBSCRIPT_BUILD_DIR:-${TMPDIR:-/tmp}/libscript_build}"
export LIBSCRIPT_BUILD_DIR

LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"
export LIBSCRIPT_DATA_DIR

PATH="${HOME}"'/.cargo/bin:'"${HOME}"'/.local/share/fnm/aliases/default/bin:'"${LIBSCRIPT_DATA_DIR}"'/bin:'"${PATH}"
export PATH

[ -d "${LIBSCRIPT_BUILD_DIR}" ] || mkdir -p -- "${LIBSCRIPT_BUILD_DIR}"
[ -d "${LIBSCRIPT_DATA_DIR}" ] || mkdir -p -- "${LIBSCRIPT_DATA_DIR}"
