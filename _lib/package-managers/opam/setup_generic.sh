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

if ! command -v opam >/dev/null 2>&1; then
  echo "Installing opam..."
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR:-..}"'/_lib/_common/pkg_mgr.sh'
  export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091,SC2034
  . "${SCRIPT_NAME}"
  
  if ! depends opam; then
    if command -v curl >/dev/null 2>&1; then
      echo | bash -c "sh <(curl -fsLS https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh) --no-setup"
    else
      echo "Error: curl or system package manager is required to install opam." >&2
      exit 1
    fi
  fi
fi
