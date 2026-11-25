#!/bin/sh
# ## Overview
# Common T0 Git repository checkout and update utilities in pure POSIX `/bin/sh`.
# Provides `git_get <repo> <target> [branch]` for idempotent cloning and fast-forward resets.
#
# ## Usage
# SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/git.sh" export SCRIPT_NAME && . "${SCRIPT_NAME}"

set -feu; _git_caller_this="${THIS_FILE:-}"; _git_caller_dir="${SCRIPT_DIR:-}"
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    [ "${LIBSCRIPT_DEBUG:-0}" = '1' ] && printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    [ -n "${_git_caller_this}" ] && THIS_FILE="${_git_caller_this}"; [ -n "${_git_caller_dir}" ] && SCRIPT_DIR="${_git_caller_dir}"; unset SCRIPT_NAME _git_caller_this _git_caller_dir || true
    if (return 0 2>/dev/null); then return 0; else exit 0; fi ;;
  *) [ "${LIBSCRIPT_DEBUG:-0}" = '1' ] && printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

# ## git_get
# Clones a Git repository or fetches and updates an existing checkout idempotently.
git_get() {
  _gg_repo="${1}"
  _gg_target="${2}"
  _gg_branch="${3:-}"

  _gg_git_dir="${_gg_target}/.git"
  if [ -d "${_gg_git_dir}" ]; then
    if [ -n "${_gg_branch}" ]; then
      GIT_WORK_TREE="${_gg_target}" GIT_DIR="${_gg_git_dir}" git -c core.sshCommand=ssh -c "url.https://github.com/.insteadOf=ssh://git@github.com/" fetch origin "${_gg_branch}" 2>/dev/null || true
      GIT_WORK_TREE="${_gg_target}" GIT_DIR="${_gg_git_dir}" git reset --hard "origin/${_gg_branch}" 2>/dev/null || true
    else
      GIT_WORK_TREE="${_gg_target}" GIT_DIR="${_gg_git_dir}" git -c core.sshCommand=ssh -c "url.https://github.com/.insteadOf=ssh://git@github.com/" fetch --depth=1 origin HEAD 2>/dev/null || true
      GIT_WORK_TREE="${_gg_target}" GIT_DIR="${_gg_git_dir}" git reset --hard FETCH_HEAD 2>/dev/null || true
    fi
  else
    mkdir -p -- "${_gg_target}"
    if [ -n "${_gg_branch}" ]; then
      git -c core.sshCommand=ssh -c "url.https://github.com/.insteadOf=ssh://git@github.com/" clone --depth=1 --single-branch --branch "${_gg_branch}" -- "${_gg_repo}" "${_gg_target}"
    else
      git -c core.sshCommand=ssh -c "url.https://github.com/.insteadOf=ssh://git@github.com/" clone --depth=1 --single-branch -- "${_gg_repo}" "${_gg_target}"
    fi
  fi
  unset _gg_repo _gg_target _gg_branch _gg_git_dir || true
}

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_git_caller_dir:-}" ] && SCRIPT_DIR="${_git_caller_dir}"
[ -n "${_git_caller_this:-}" ] && THIS_FILE="${_git_caller_this}"
unset SCRIPT_NAME _git_caller_this _git_caller_dir || true
