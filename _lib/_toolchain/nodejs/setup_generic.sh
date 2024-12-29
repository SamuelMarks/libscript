#!/bin/sh

realpath -- "${0}"
set -x
guard='H_'"$(realpath -- "${0}" | sed 's/[^a-zA-Z0-9_]/_/g')"
if env | grep -qF "${guard}"'=1'; then return ; fi
export "${guard}"=1
if [ -n "${ZSH_VERSION}" ] || [ -n "${BASH_VERSION}" ]; then
  set -xeuo pipefail
fi

SCRIPT_ROOT_DIR="${SCRIPT_ROOT_DIR:-$( dirname -- "$( dirname -- "$( dirname -- "${0}" )" )" )}"

# shellcheck disable=SC1091
. "${SCRIPT_ROOT_DIR}"'/conf.env.sh'

curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n | sh bash -s install lts
npm i -g npm
