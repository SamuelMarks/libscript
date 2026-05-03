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
VERBOSE=0
ALL_DEPS=0
HELP=0
OUTPUT_FOLDER="${LIBSCRIPT_ROOT_DIR}"'/tmp'
BASE="${BASE:-alpine:latest debian:bookworm-slim}"

while getopts 'a:f:o:vh' opt; do
    case ${opt} in
      (a)   ALL_DEPS="${OPTARG}" ;;
      (f)   filename="${OPTARG}" ;;
      (o)   OUTPUT_FOLDER="${OPTARG}" ;;
      (v)   # shellcheck disable=SC2003
            VERBOSE=$(expr "${VERBOSE}" + 1) ;;
      (h)   HELP=1 ;;
      (*) ;;
    esac
done
export verbose

shift "$((OPTIND - 1))"
REMAINING="$*"

help() {
    >&2 printf 'Create install scripts from JSON.\n
\t-a whether to install all dependencies (required AND optional)
\t-f filename
\t-o output folder (defaults to ./tmp)
\t-v verbosity (can be specified multiple times)
\t-b base images for docker (space seperated, default: "alpine:latest debian:bookworm-slim")
\t-h show help text\n\n'
}
if [ "${HELP}" -ge 1 ]; then
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

if [ -n "${REMAINING}" ]; then
  >&2 printf '[W] Extra arguments provided: %s\n' "${REMAINING}"
fi

export output_folder
export all_deps
export base

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/parse_installer_json.sh'
export SCRIPT_NAME
. "${SCRIPT_NAME}"

parse_json "${filename}"
