#!/bin/sh

realpath -- "${0}"
set -xv
guard='H_'"$(realpath -- "${0}" | sed 's/[^a-zA-Z0-9_]/_/g')"
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
