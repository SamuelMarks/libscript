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
# @description Automatically handles run_hooks for the run_hooks.sh (orchestration) component.
# @file run_hooks.sh


# run_hooks.sh <json_file> <hook_type>
JSON_FILE="$1"
HOOK_TYPE="$2"

if [ ! -f "$JSON_FILE" ]; then exit 0; fi

HOOKS=$(jq -c ".hooks.${HOOK_TYPE}[]?" "$JSON_FILE" 2>/dev/null || true)

if [ -z "$HOOKS" ]; then exit 0; fi

log_info "Running $HOOK_TYPE hooks..."
echo "$HOOKS" | while read -r hook; do
    NAME=$(echo "$hook" | jq -r '.name // "unnamed_hook"')
    cmd=$(echo "$hook" | jq -r '.command // empty')
    COND=$(echo "$hook" | jq -r '.condition // empty')

    if [ -n "$COND" ]; then
        if echo "$COND" | grep -q "^unless_exists "; then
            FILE=$(echo "$COND" | sed 's/^unless_exists //')
            if [ -e "$FILE" ]; then
                log_info "Skipping hook '$NAME': $FILE exists"
                continue
            fi
        fi
    fi

    if [ -n "$cmd" ]; then
        log_info "Executing hook '$NAME': $cmd"
        eval "$cmd"
    fi
done
