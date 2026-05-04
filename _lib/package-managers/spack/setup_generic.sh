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
if ! command -v spack >/dev/null 2>&1; then
  log_info "Installing spack..."
  if ! command -v git >/dev/null 2>&1; then echo "git is required"; exit 1; fi
  if [ ! -d "$HOME/spack" ]; then
    git clone -c feature.manyFiles=true https://github.com/spack/spack.git "$HOME/spack"
  fi
  log_info "You must run 'source ~/spack/share/spack/setup-env.sh' to use spack"
fi
