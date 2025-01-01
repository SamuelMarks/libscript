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
    printf '[STOP]     processing "%s" found in "%s"\n' "${this_file}" "${STACK}"
    return ;;
  *)
    printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
STACK="${STACK}${this_file}"':'
export STACK

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
