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

if ! command -v cabal >/dev/null 2>&1; then
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/ghcup/setup.sh" ]; then
    "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/ghcup/setup.sh"
    if [ -x "$HOME/.ghcup/bin/cabal" ]; then
      export PATH="$HOME/.ghcup/bin:$PATH"
    fi
  else
    printf "Error: Cannot find ghcup setup script to bootstrap cabal.\n" >&2
    exit 1
  fi
fi

if ! command -v cabal >/dev/null 2>&1 && [ -x "$HOME/.ghcup/bin/cabal" ]; then
  export PATH="$HOME/.ghcup/bin:$PATH"
fi
