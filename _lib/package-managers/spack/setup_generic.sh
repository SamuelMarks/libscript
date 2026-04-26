#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
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
if ! command -v spack >/dev/null 2>&1; then
  echo "Installing spack..."
  if ! command -v git >/dev/null 2>&1; then echo "git is required"; exit 1; fi
  if [ ! -d "$HOME/spack" ]; then
    git clone -c feature.manyFiles=true https://github.com/spack/spack.git "$HOME/spack"
  fi
  echo "You must run 'source ~/spack/share/spack/setup-env.sh' to use spack"
fi
