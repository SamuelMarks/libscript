#!/bin/sh

# shellcheck disable=SC2236
if [ ! -z "${SCRIPT_NAME+x}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ ! -z "${BASH_VERSION+x}" ]; then
  # shellcheck disable=SC3028 disable=SC3054
  this_file="${BASH_SOURCE[0]}"
  # shellcheck disable=SC3040
  set -o pipefail
elif [ ! -z "${ZSH_VERSION+x}" ]; then
  # shellcheck disable=SC2296
  this_file="${(%):-%x}"
  # shellcheck disable=SC3040
  set -o pipefail
else
  this_file="${0}"
fi
set -eu

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$( CDPATH='' cd -- "$( dirname -- "$( readlink -nf -- "${this_file}" )")" && pwd)}"
export LIBSCRIPT_ROOT_DIR

LIBSCRIPT_DOCS_DIR="${LIBSCRIPT_DOCS_DIR:-./docs}"
export LIBSCRIPT_DOCS_DIR

set +f
[ -d "${LIBSCRIPT_DOCS_DIR}" ] || mkdir -p "${LIBSCRIPT_DOCS_DIR}"
for f in $(find "${LIBSCRIPT_ROOT_DIR}" -type f -name 'README.md'); do
  out="${LIBSCRIPT_DOCS_DIR}${f#"${LIBSCRIPT_ROOT_DIR}"}"
  parent="$(dirname -- "${out}")"

  slashes=0
  tmp="${out}"

  while [ -n "${tmp}" ]; do
    rest="${tmp#?}"
    ch="${tmp%"$rest"}"
    tmp="${rest}"
    if [ "${ch}" = '/' ]; then
      # shellcheck disable=SC2003
      slashes=$(expr "${slashes}" + 1)
    fi
  done
  case "${out}" in
    './'*)
      if [ "${slashes}" -gt 1 ] ; then
        [ -d "${parent}" ] || mkdir -p "${parent}"
      fi
      ;;
    *'/'*)
      [ -d "${parent}" ] || mkdir -p "${parent}"
      ;;
  esac
  pandoc -f markdown -t html5 "${f}" -o "${out%%.md}"'.html'
done
##for d in "${LIBSCRIPT_ROOT_DIR}"'/_lib/'*; do
 # echo "${d%LIBSCRIPT_ROOT_DIR}"
#done
#find . -type f -name '*.md' | xargs -n1 pandoc -f markdown -t html5