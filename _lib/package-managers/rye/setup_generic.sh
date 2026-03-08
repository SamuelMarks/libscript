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

if ! command -v rye >/dev/null 2>&1; then
  if command -v curl >/dev/null 2>&1; then
    curl -sSf https://rye.astral.sh/get | RYE_INSTALL_OPTION="--yes" bash
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- https://rye.astral.sh/get | RYE_INSTALL_OPTION="--yes" bash
  else
    echo "curl or wget is required to install rye." >&2
    exit 1
  fi
  export PATH="$HOME/.rye/shims:$PATH"
fi
