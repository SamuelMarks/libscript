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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/priv.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

if [ ! -f /usr/local/bin/wait4x ]; then
  DOWNLOAD_DIR=${DOWNLOAD_DIR:-${LIBSCRIPT_DATA_DIR}/Downloads}
  [ -d "${DOWNLOAD_DIR}" ] || mkdir -p "${DOWNLOAD_DIR}"
  previous_wd="$(pwd)"
  cd "${DOWNLOAD_DIR}"
  curl -#LO https://github.com/atkrad/wait4x/releases/latest/download/wait4x-linux-amd64.tar.gz
  tar --one-top-level -xvf wait4x-linux-amd64.tar.gz
  "${PRIV}" install ./wait4x-linux-amd64/wait4x /usr/local/bin/wait4x
  # rm wait4x-linux-amd64.tar.gz
  cd "${previous_wd}"
fi
