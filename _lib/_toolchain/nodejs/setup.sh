#!/bin/sh

realpath -- "${0}"
set -xv
if [ -n "${ZSH_VERSION}" ] || [ -n "${BASH_VERSION}" ]; then
  set -xveuo pipefail
fi
DIR="$( dirname -- "${0}" )"
export DIR

SCRIPT_ROOT_DIR="${SCRIPT_ROOT_DIR:-$( dirname -- "$(dirname -- "$( dirname -- "${DIR}" )" )" )}"
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
