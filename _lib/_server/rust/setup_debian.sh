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

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/common.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_git/git.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_toolchain/rust/setup.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

previous_wd="$(pwd)"
if [ -z "${DEST+x}" ]; then
  LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"
  DEST="${LIBSCRIPT_DATA_DIR}"'/'"$(env LC_CTYPE='C' tr -cd '[:lower:]' < '/dev/urandom' | head -c 8)"
  [ -d "${DEST}" ] || mkdir -p "${DEST}"
fi
cd "${DEST}"
. "${HOME}"'/.cargo/env'

cargo build --release

cd "${previous_wd}"
