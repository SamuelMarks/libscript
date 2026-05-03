#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
git_get() {
    repo="${1}"
    target="${2}"
    branch="${3:-}"

    GIT_DIR_="${target}"'/.git'
    if [ -d "${GIT_DIR_}" ]; then
        if [ -n "${branch}" ]; then
            GIT_WORK_TREE="${target}" GIT_DIR="${GIT_DIR_}" git fetch origin "${branch}":"${branch}"
        else
            GIT_WORK_TREE="${target}" GIT_DIR="${GIT_DIR_}" git pull --ff-only
        fi
    else
        mkdir -p -- "${target}"
        if [ -n "${branch}" ]; then
            git clone --depth=1 --single-branch --branch "${branch}" -- "${repo}" "${target}"
        else
            git clone --depth=1 --single-branch -- "${repo}" "${target}"
        fi
    fi
}
