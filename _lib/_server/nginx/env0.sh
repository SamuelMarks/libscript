#!/bin/sh

# shellcheck disable=SC2236
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
else
  if [ "${BASH_VERSION-}" ]; then
    # shellcheck disable=SC3028 disable=SC3054
    this_file="${BASH_SOURCE[0]}"
    # shellcheck disable=SC3040
    set -o pipefail
  elif [ "${ZSH_VERSION-}" ]; then
    # shellcheck disable=SC2296
    this_file="${(%):-%x}"
    # shellcheck disable=SC3040
    set -o pipefail
  else
    this_file="${0}"
  fi
  DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
  LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"
  candidate="${this_file}"
  case "${candidate}" in
         *'../'*)
           candidate="$(cd "$(dirname -- "${candidate}")"; pwd)/$(basename -- "${candidate}")"
        ;;
  esac
  printf 'candidate = "%s"\n' "${candidate}"
  # todo: remove parent most dir in this loop until file is found or no more dirs
  while [ ! -e "${LIBSCRIPT_ROOT_DIR}"'/'"${candidate}" ] ; do
    case "${candidate}" in
       *'../'*)
         candidate="$(cd "$(dirname -- "${candidate}")"; pwd)/$(basename -- "${candidate}")"
         if [ ! -f "${candidate}" ]; then
          break
         fi
         printf 'candidate = "%s"\n' "${candidate}"
         candidate="${this_file##*/}"
         ;;
       *'/'*)
         printf 'candidate = "%s"\n' "${candidate}"
         if [ ! -f "${candidate}" ]; then
           break
         fi
         candidate="${this_file##*/}"
         ;;
       *)
         >&2 printf 'Failed to find script path relative to LIBSCRIPT_ROOT_DIR\n'
         exit 3
         ;;
    esac
  done
  A_SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${candidate}"
  printf 'this_file = "%s"\n' "${this_file}"
  printf 'LIBSCRIPT_ROOT_DIR = "%s"\n' "${LIBSCRIPT_ROOT_DIR}"
  printf 'A_SCRIPT_NAME = "%s"\n' "${A_SCRIPT_NAME}"
fi
set -feu


STACK="${STACK:-:}"
case "${STACK}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    return ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'

