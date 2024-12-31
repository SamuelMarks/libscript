#!/bin/sh

# shellcheck disable=SC2236
if [ ! -z "${BASH_VERSION+x}" ]; then
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

guard='H_'"$(realpath -- "${this_file}" | sed 's/[^a-zA-Z0-9_]/_/g')"
test "${guard}" && return
export "${guard}"=1

export RUST_INSTALL=0
export NODEJS_INSTALL=0
export PYTHON_INSTALL=0
export POSTGRESQL_INSTALL=0
export VALKEY_INSTALL=0
export NGINX_INSTALL=0
export CELERY_INSTALL=0
export WWWROOT_INSTALL=0
export JUPYTER_NOTEBOOK_INSTALL=0
