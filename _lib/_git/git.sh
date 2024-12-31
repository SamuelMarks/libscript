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
git_get() {
    repo="${0}"
    target="${1}"
    branch="${2:-''}"
    GIT_DIR_="${target}"'/.git'
    if [ -d "${GIT_DIR_}" ]; then
        if [ "${branch}" = '' ]; then
            GIT_WORK_TREE="${target}" GIT_DIR="${GIT_DIR_}" git pull
        else
            GIT_WORK_TREE="${target}" GIT_DIR="${GIT_DIR_}" git fetch origin "${branch}":"${branch}"
        fi
    else
        mkdir -p "${target}"
        if [ "${branch}" = '' ]; then
            git clone --depth=1 --single-branch "${repo}" "${target}"
        else
            git clone --depth=1 --single-branch --branch "${branch}" "${repo}" "${target}"
        fi
    fi
}
