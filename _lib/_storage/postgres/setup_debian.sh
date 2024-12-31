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

guard='H_'"$(printf '%s' "${this_file}" | sed 's/[^a-zA-Z0-9_]/_/g')"
if test "${guard}" ; then
  echo '[STOP]     processing '"${this_file}"
  return
else
  echo '[CONTINUE] processing '"${this_file}"
fi
export "${guard}"=1

SCRIPT_ROOT_DIR="${SCRIPT_ROOT_DIR:-$(d="$(CDPATH='' cd -- "$(dirname -- "$(dirname -- "$( dirname -- "${DIR}" )" )" )")"; if [ -d "$d" ]; then echo "$d"; else echo './'"$d"; fi)}"

# shellcheck disable=SC1091
. "${SCRIPT_ROOT_DIR}"'/conf.env.sh'
# shellcheck disable=SC1091
. "${SCRIPT_ROOT_DIR}"'/_lib/_os/_apt/apt.sh'

get_priv

apt_depends postgresql-common
"${PRIV}" /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
apt_depends postgresql-server-dev-"${POSTGRESQL_VERSION}" postgresql-"${POSTGRESQL_VERSION}"
