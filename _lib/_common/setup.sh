#!/bin/sh

if [ -n "${BASH_VERSION}" ]; then
  # shellcheck disable=SC3028 disable=SC3054
  this_file="${BASH_SOURCE[0]}"
  # shellcheck disable=SC3040
  set -xeuo pipefail
elif [ -n "${ZSH_VERSION}" ]; then
  # shellcheck disable=SC2296
  this_file="${(%):-%x}"
  # shellcheck disable=SC3040
  set -xeuo pipefail
else
  this_file="${0}"
  printf 'argv[%d] = "%s"\n' "0" "${0}";
  printf 'argv[%d] = "%s"\n' "1" "${1}";
  printf 'argv[%d] = "%s"\n' "2" "${2}";
fi

guard='H_'"$(realpath -- "${this_file}" | sed 's/[^a-zA-Z0-9_]/_/g')"

if env | grep -qF "${guard}"'=1'; then return ; fi
export "${guard}"=1

if [ "${ZSH_VERSION+x}" ] || [ "${BASH_VERSION+x}" ]; then
  # shellcheck disable=SC3040
  set -xeuo pipefail
fi
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
