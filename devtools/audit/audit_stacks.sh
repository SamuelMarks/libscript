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
SCRIPT_DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
[ -z "${LIBSCRIPT_ROOT_DIR:-}" ] && LIBSCRIPT_ROOT_DIR=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; echo "$d")
for stack_dir in "$LIBSCRIPT_ROOT_DIR"/stacks/*/*; do
    if [ ! -d "$stack_dir" ]; then continue; fi
    stack_name="$(basename "$stack_dir")"
    
    README_PATH="$stack_dir/README.md"
    
    if [ ! -f "$README_PATH" ]; then
        echo "WARNING: Stack $stack_name is missing a README.md"
        continue
    fi
    
    # Check if they list orchestrated components
    if ! grep -i -q "components" "$README_PATH" && ! grep -i -q "orchestrates" "$README_PATH" && ! grep -i -q "libscript.json" "$README_PATH"; then
        echo "WARNING: Stack $stack_name README may not explicitly list orchestrated _lib components or libscript.json usage."
        # Inject a placeholder if they don't have one
        if ! grep -q "## Orchestrated Components" "$README_PATH"; then
             printf "\n## Orchestrated Components\nThis stack orchestrates the following LibScript components:\n- (Please document required components here)\n" >> "$README_PATH"
        fi
    fi
done
echo "Stack audit complete."