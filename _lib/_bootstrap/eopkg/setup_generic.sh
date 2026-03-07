#!/bin/sh
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

if ! command -v eopkg >/dev/null 2>&1; then
  printf 'Info: %s is not available on this system. Skipping.\n' "eopkg"
  if (return 0 2>/dev/null); then return; else exit 0; fi
fi

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR:-..}"'/_lib/_common/priv.sh'
export SCRIPT_NAME
. "${SCRIPT_NAME}"

priv eopkg update-repo || true
