#!/bin/sh
# ## Overview
# Runs CI tests strictly for toolchains and databases components.
#
# ## Usage
# Execute this script without arguments. It will automatically discover and test
# all components within `_lib/toolchains` and `_lib/databases`.
# Optionally pass the target OS as the first argument (e.g., ubuntu-latest).

set -e
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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)

cd "${SCRIPT_DIR}/../.." || exit 1

TARGET_OS="${1:-ubuntu-latest}"
FAILED_COMPONENTS_FILE="${GITHUB_WORKSPACE:-$(pwd)}/failed_components.txt"

rm -f "$FAILED_COMPONENTS_FILE"

printf '%s\n' ">>> STARTING TESTS FOR TOOLCHAINS AND DATABASES <<<"

COMPONENTS=""
# POSIX-compliant iteration
for comp_type in "_lib/toolchains" "_lib/databases"; do
  for dir in "$comp_type"/*; do
    if [ -d "$dir" ]; then
      if [ -z "$COMPONENTS" ]; then
        COMPONENTS="$dir"
      else
        COMPONENTS="$COMPONENTS $dir"
      fi
    fi
  done
done

export TARGET_OS
export FAILED_COMPONENTS_FILE
# xargs with parallel jobs
if ! printf '%s\n' "$COMPONENTS" | tr ' ' '\n' | xargs -n 1 -P 4 -I {} sh -c 'devtools/ci/run_test_component.sh "{}" "$TARGET_OS" || echo "{}" >> "$FAILED_COMPONENTS_FILE"'; then
  printf '%s\n' "Error running xargs"
fi

if [ -f "$FAILED_COMPONENTS_FILE" ]; then
  FAILED_COMPONENTS=$(cat "$FAILED_COMPONENTS_FILE" | tr '\n' ' ')
  printf '%s\n' "The following components failed: $FAILED_COMPONENTS"
  exit 1
fi
