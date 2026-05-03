#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
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
