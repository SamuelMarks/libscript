#!/bin/sh

# shellcheck disable=SC2236
if [ ! -z "${BASH_VERSION+x}" ]; then
  # shellcheck disable=SC3040
  set -o pipefail
elif [ ! -z "${ZSH_VERSION+x}" ]; then
  # shellcheck disable=SC3040
  set -o pipefail
fi
set -feu

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_toolchain/wait4x/setup.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

if [ -z "${POSTGRES_URL+x}" ]; then
  POSTGRES_URL='postgres://'"${POSTGRES_USER}"':'"${POSTGRES_PASSWORD}"'@'"${POSTGRES_HOST}"'/'"${POSTGRES_DB}"
fi
/usr/local/bin/wait4x postgresql "${POSTGRES_URL}"'?sslmode=disable'
