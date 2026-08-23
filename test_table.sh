#!/bin/sh
# ## Overview
# Generates a markdown table displaying the testing status of components.
#
# ## Usage
# Run this script to generate `components_table.tmp` and print it.

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
_SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)

cat <<'TABLE' >components_table.tmp
## Supported Components

| Component | Linux | Windows | DOS | SunOS | FreeBSD |
|---|---|---|---|---|---|
TABLE

find _lib -mindepth 2 -maxdepth 2 -type d ! -path "_lib/_common*" | awk -F'/' '{print $3}' | sort -u | while read -r comp; do
    linux_status="❓"
    if [ -f "tests_tmp/$comp.linux.alpine.success" ]; then
        linux_status="✅"
    elif [ -f "tests_tmp/$comp.linux.alpine.failure" ]; then
        linux_status="❌"
    fi
    printf "| \`%s\` | %s | - | - | - | - |\n" "$comp" "$linux_status" >>components_table.tmp
done
cat components_table.tmp
