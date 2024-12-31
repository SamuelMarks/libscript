#!/bin/sh

if [ ! -z "${BASH_VERSION+x}" ]; then
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

guard='H_'"$(printf '%s' "${this_file}" | sed 's/[^a-zA-Z0-9_]/_/g')"
if test "${guard}" ; then
  echo '[STOP]     processing '"${this_file}"
  return
else
  echo '[CONTINUE] processing '"${this_file}"
fi
export "${guard}"=1

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
export DIR

SCRIPT_ROOT_DIR="${SCRIPT_ROOT_DIR:-$(d="$(CDPATH='' cd -- "$(dirname -- "$(dirname -- "$( dirname -- "${DIR}" )" )" )")"; if [ -d "$d" ]; then echo "$d"; else echo './'"$d"; fi)}"
export SCRIPT_ROOT_DIR

# shellcheck disable=SC1091
. "${SCRIPT_ROOT_DIR}"'/_lib/_common/os_info.sh'

env_script="${DIR}"'/conf.env.sh'
# shellcheck disable=SC1090
[ -f "${env_script}" ] && . "${env_script}"

os_setup_script="${DIR}"'/setup_'"${TARGET_OS}"'.sh'
if [ -f "${os_setup_script}" ]; then
  # shellcheck disable=SC1090
  . "${os_setup_script}"
else
  # shellcheck disable=SC1091
  . "${DIR}"'/setup_generic.sh'
fi
