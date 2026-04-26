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
# @description Automatically handles run_hooks for the run_hooks.sh (orchestration) component.
# @file run_hooks.sh


# run_hooks.sh <json_file> <hook_type>
set -e
json_file="$1"
hook_type="$2"

if [ ! -f "$json_file" ]; then exit 0; fi

hooks=$(jq -c ".hooks.${hook_type}[]?" "$json_file" 2>/dev/null || true)

if [ -z "$hooks" ]; then exit 0; fi

echo "Running $hook_type hooks..."
echo "$hooks" | while read -r hook; do
    name=$(echo "$hook" | jq -r '.name // "unnamed_hook"')
    cmd=$(echo "$hook" | jq -r '.command // empty')
    cond=$(echo "$hook" | jq -r '.condition // empty')

    if [ -n "$cond" ]; then
        if echo "$cond" | grep -q "^unless_exists "; then
            file=$(echo "$cond" | sed 's/^unless_exists //')
            if [ -e "$file" ]; then
                echo "Skipping hook '$name': $file exists"
                continue
            fi
        fi
    fi

    if [ -n "$cmd" ]; then
        echo "Executing hook '$name': $cmd"
        eval "$cmd"
    fi
done
