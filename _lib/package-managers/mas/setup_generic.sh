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
if [ "$(uname -s)" != "Darwin" ]; then
  printf 'Info: mas is only supported on macOS. Skipping.\n'
  if (return 0 2>/dev/null); then return; else exit 0; fi
fi

if ! command -v mas >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    brew install mas
  elif command -v port >/dev/null 2>&1; then
    sudo port install mas
  else
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/brew/setup.sh" ]; then
      "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/brew/setup.sh"
      brew install mas
    else
      printf 'Error: Cannot install mas without Homebrew or MacPorts.\n' >&2
      exit 1
    fi
  fi
fi
