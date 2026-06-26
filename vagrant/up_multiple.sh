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
SCRIPT_DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
if [ -z "${LIBSCRIPT_ROOT_DIR:-}" ]; then
  _tmp_dir="$SCRIPT_DIR"
  while [ "$_tmp_dir" != "/" ] && [ ! -f "$_tmp_dir/libscript.sh" ]; do
    _tmp_dir="$(dirname "$_tmp_dir")"
  done
  LIBSCRIPT_ROOT_DIR="$_tmp_dir"
fi
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: $0 [OPTIONS]"
  echo "See script source or documentation for more details."
  exit 0
fi
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"

elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${0}"

else
  THIS_FILE="${0}"
fi

DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)

VAGRANT_IMAGE_DIR="${VAGRANT_IMAGE_DIR:-debian12}"
VAGRANT_N="${VAGRANT_N:-VAGRANT_N}"
(
  cd "${DIR}"'/'"${VAGRANT_IMAGE_DIR}" || exit 1
  for i in $(dc -e '0 1 '"${VAGRANT_N}"'  stsisb[pli+dlt>a]salblax'); do
    vagrant up "${VAGRANT_IMAGE_DIR}${i}"
  done
)
