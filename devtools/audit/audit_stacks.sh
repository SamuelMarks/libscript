#!/bin/sh
# ## Overview
# Performs an audit and validation of all defined application stacks.
# ## Usage
# Execute this script to check the integrity of stack definitions.


set -feu


if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
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
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  printf '%s\n' "Usage: $(basename -- "${THIS_FILE}") [--fix] [--strict]"
  printf '%s\n' 'Performs an audit and validation of all defined application stacks.'
  printf '\n'
  printf '%s\n' 'Options:'
  printf '%s\n' '  --fix               Append missing Orchestrated Components section stub to README.md.'
  printf '%s\n' '  --strict            Exit with status 1 if any stack README violations are found.'
  printf '%s\n' '  --help, -h, /?, -?  Show this help message.'
  exit 0
fi
FIX_MODE=0
STRICT_MODE=0
for _arg in "$@"; do
  case "$_arg" in
    --fix) FIX_MODE=1 ;;
    --strict) STRICT_MODE=1 ;;
  esac
done
STACK_ERRORS=0
set +f
for stack_dir in "$LIBSCRIPT_ROOT_DIR"/workloads/apps/* "$LIBSCRIPT_ROOT_DIR"/workloads/constellations/* "$LIBSCRIPT_ROOT_DIR"/workloads/payloads/*/*; do
    if [ ! -d "$stack_dir" ]; then continue; fi
    stack_name="$(basename "$stack_dir")"
    
    README_PATH="$stack_dir/README.md"
    
    if [ ! -f "$README_PATH" ]; then
        printf '%s\n' "WARNING: Stack $stack_name is missing a README.md"
        STACK_ERRORS=$((STACK_ERRORS + 1))
        continue
    fi
    
    # Check if they list orchestrated components
    if ! grep -i -q "components" "$README_PATH" && ! grep -i -q "orchestrates" "$README_PATH" && ! grep -i -q "libscript.json" "$README_PATH"; then
        printf '%s\n' "WARNING: Stack $stack_name README may not explicitly list orchestrated _lib components or libscript.json usage."
        STACK_ERRORS=$((STACK_ERRORS + 1))
        if [ "$FIX_MODE" -eq 1 ] && ! grep -q "## Orchestrated Components" "$README_PATH"; then
             printf "\n## Orchestrated Components\nThis stack orchestrates the following LibScript components:\n- (Please document required components here)\n" >> "$README_PATH"
        fi
    fi
done
set -f
printf '%s\n' 'Stack audit complete.'
if [ "$STRICT_MODE" -eq 1 ] && [ "$STACK_ERRORS" -gt 0 ]; then
  exit 1
fi
