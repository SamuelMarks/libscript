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

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$( CDPATH='' cd -- "$( dirname -- "$( readlink -nf -- "${this_file}" )")" && pwd)}"
export LIBSCRIPT_ROOT_DIR

STACK="${STACK:-:}${this_file}"':'
export STACK

verbose=0
all_deps=0
help=0
output_folder="${LIBSCRIPT_ROOT_DIR}"'/tmp'
base="${BASE:-alpine:latest debian:bookworm-slim}"

while getopts 'a:f:o:vh' opt; do
    case ${opt} in
      (a)   all_deps="${OPTARG}" ;;
      (f)   filename="${OPTARG}" ;;
      (o)   output_folder="${OPTARG}" ;;
      (v)   # shellcheck disable=SC2003
            verbose=$(expr "${verbose}" + 1) ;;
      (h)   help=1 ;;
      (*) ;;
    esac
done
export verbose

shift "$((OPTIND - 1))"
remaining="$*"

help() {
    >&2 printf 'Create install scripts from JSON.\n
\t-a whether to install all dependencies (required AND optional)
\t-f filename
\t-o output folder (defaults to ./tmp)
\t-v verbosity (can be specified multiple times)
\t-b base images for docker (space seperated, default: "alpine:latest debian:bookworm-slim")
\t-h show help text\n\n'
}
if [ "${help}" -ge 1 ]; then
  # shellcheck disable=SC2016
  help
  exit 2
elif [ -z "${filename+x}" ]; then
  help
  # shellcheck disable=SC2016
  >&2 printf 'JSON file must be specified with `-f`\n'
  exit 2
elif [ ! -f "${filename}" ]; then
  help
  # shellcheck disable=SC2016
  >&2 printf 'JSON file specified with `-f` must exist\n'
  exit 2
fi

if [ -n "${remaining}" ]; then
  >&2 printf '[W] Extra arguments provided: %s\n' "${remaining}"
fi

export output_folder
export all_deps
export base

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/parse_installer_json.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

parse_json "${filename}"
