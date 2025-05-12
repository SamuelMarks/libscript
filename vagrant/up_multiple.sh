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

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)

previous_wd="$(pwd)"
VAGRANT_IMAGE_DIR="${VAGRANT_IMAGE_DIR:-debian12}"
VAGRANT_N="${VAGRANT_N:-VAGRANT_N}"
cd "${DIR}"'/'"${VAGRANT_IMAGE_DIR}"
for i in dc -e '0 1 '"${VAGRANT_N}"'  stsisb[pli+dlt>a]salblax'; do
  vagrant up "${VAGRANT_IMAGE_DIR}${i}"
done
cd "${previous_wd}"
