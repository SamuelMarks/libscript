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

if [ -x "$HOME/.pyenv/bin/pyenv" ]; then
  export PATH="$HOME/.pyenv/bin:$PATH"
fi

if ! command -v pyenv >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    brew install pyenv
  else
    if command -v curl >/dev/null 2>&1; then
      curl https://pyenv.run | bash
    elif command -v wget >/dev/null 2>&1; then
      wget -qO- https://pyenv.run | bash
    else
      printf "Error: curl or wget is required to bootstrap pyenv.\n" >&2
      exit 1
    fi
  fi
fi

if ! command -v pyenv >/dev/null 2>&1 && [ -x "$HOME/.pyenv/bin/pyenv" ]; then
  export PATH="$HOME/.pyenv/bin:$PATH"
fi
