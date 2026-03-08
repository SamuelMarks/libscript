#!/bin/sh
# shellcheck disable=SC3054,SC3040,SC2296,SC2128,SC2039,SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145



set -feu
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE}"

elif [ "${ZSH_VERSION-}" ]; then
  this_file="${0}"

else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'

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
