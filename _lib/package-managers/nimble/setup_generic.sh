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

if ! command -v nimble >/dev/null 2>&1; then
  echo "Installing nimble via choosenim..."
  if command -v curl >/dev/null 2>&1; then
    curl https://nim-lang.org/choosenim/init.sh -sSf | sh
  else
    echo "Error: curl is required to install choosenim." >&2
    exit 1
  fi
  if [ -d "$HOME/.nimble/bin" ]; then
    export PATH="$HOME/.nimble/bin:$PATH"
  fi
fi
