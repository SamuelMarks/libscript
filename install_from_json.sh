#!/bin/sh

verbose=0
all_deps=0

while getopts ':a:f:v' opt; do
    case $opt in
      (v)   # shellcheck disable=SC2003
            verbose=$(expr "${verbose}" + 1) ;;
      (f)   filename=$OPTARG ;;
      (a)   all_deps=$OPTARG ;;
      (*) ;;
    esac
done

shift "$((OPTIND - 1))"
remaining="$*"

if [ -z "${filename+x}" ]; then
  # shellcheck disable=SC2016
  >&2 printf 'JSON file must be specified with `-f`\n'
  exit 2
elif [ ! -f "${filename}" ]; then
  # shellcheck disable=SC2016
  >&2 printf 'JSON file must specified with `-f` must exist\n'
  exit 2
fi

if [ -n "${remaining}" ]; then
  >&2 printf '[W] Extra arguments provided: %s\n' "${remaining}"
fi
printf 'TODO: jq parse of = "%s"\n' "${filename}"
printf 'TODO: all_deps = %d\n' "${all_deps}"
