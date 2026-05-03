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
if ! command -v pkg >/dev/null 2>&1; then
  if [ "$(uname)" = "FreeBSD" ]; then
    if [ "$(id -u)" = "0" ]; then
      env ASSUME_ALWAYS_YES=YES pkg bootstrap
    else
      if command -v sudo >/dev/null 2>&1; then
        sudo ASSUME_ALWAYS_YES=YES pkg bootstrap
      else
        echo "Error: Must be root or have sudo to bootstrap pkg on FreeBSD." >&2
        exit 1
      fi
    fi
  else
    echo "Warning: The 'pkg' package manager is only applicable on FreeBSD. Skipping." >&2
  fi
fi
