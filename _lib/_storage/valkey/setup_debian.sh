#!/bin/sh

realpath -- "${0}"
set -x
guard='H_'"$(realpath -- "${0}" | sed 's/[^a-zA-Z0-9_]/_/g')"
if env | grep -qF "${guard}"'=1'; then return ; fi
export "${guard}"=1
if [ "${ZSH_VERSION+x}" ] || [ "${BASH_VERSION+x}" ]; then
  # shellcheck disable=SC3040
  set -xeuo pipefail
fi

previous_wd="$(pwd)"
SCRIPT_ROOT_DIR="${SCRIPT_ROOT_DIR:-$(CDPATH='' cd -- "$(dirname -- "$(dirname -- "$( dirname -- "${0}" )" )" )")}"

# shellcheck disable=SC1091
. "${SCRIPT_ROOT_DIR}"'/conf.env.sh'
# shellcheck disable=SC1091
. "${SCRIPT_ROOT_DIR}"'/_lib/_os/_apt/apt.sh'
# shellcheck disable=SC1091
. "${SCRIPT_ROOT_DIR}"'/_lib/_git/git.sh'

get_priv

apt_depends git build-essential libsystemd-dev

target="${BUILD_DIR}"'/valkey'
git_get https://github.com/valkey-io/valkey "${target}"
# shellcheck disable=SC2164
cd "${target}"
make BUILD_TLS='yes' USE_SYSTEMD='yes'
"${PRIV}" make install

# shellcheck disable=SC2164
cd "${previous_wd}"
