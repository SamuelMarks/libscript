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
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: $0 [OPTIONS]"
  echo "See script source or documentation for more details."
  exit 0
fi
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE}"

elif [ "${ZSH_VERSION-}" ]; then
  this_file="${0}"

else
  this_file="${0}"
fi

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)

previous_wd="$(pwd)"
VAGRANT_IMAGE_DIR="${VAGRANT_IMAGE_DIR:-debian12}"
VAGRANT_N="${VAGRANT_N:-VAGRANT_N}"
cd "${DIR}"'/'"${VAGRANT_IMAGE_DIR}"
for i in dc -e '0 1 '"${VAGRANT_N}"'  stsisb[pli+dlt>a]salblax'; do
  vagrant up "${VAGRANT_IMAGE_DIR}${i}"
done
cd "${previous_wd}"
