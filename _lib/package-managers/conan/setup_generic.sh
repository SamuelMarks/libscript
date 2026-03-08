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

if ! command -v conan >/dev/null 2>&1; then
  if command -v pipx >/dev/null 2>&1; then
    pipx install conan
  elif command -v pip3 >/dev/null 2>&1; then
    pip3 install --user conan
  elif command -v pip >/dev/null 2>&1; then
    pip install --user conan
  else
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/pipx/setup.sh" ]; then
      "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/pipx/setup.sh"
      pipx install conan || ~/.local/bin/pipx install conan
    else
      printf "Error: python pip or pipx is required to install conan.\n" >&2
      exit 1
    fi
  fi
fi

if ! command -v conan >/dev/null 2>&1 && [ -x "$HOME/.local/bin/conan" ]; then
  export PATH="$HOME/.local/bin:$PATH"
fi
