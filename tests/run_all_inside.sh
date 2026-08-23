#!/bin/sh
# ## Overview
# Runs tests for all components or a specific target component inside the environment.
#
# ## Usage
# ./tests/run_all_inside.sh [TARGET_COMP]

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

export LIBSCRIPT_ROOT_DIR=/opt/repos/libscript
cd /opt/repos/libscript
mkdir -p tests_tmp

TARGET_COMP="$1"

for cat_dir in _lib/*; do
    [ -d "$cat_dir" ] || continue
    [ "$(basename "$cat_dir")" = "_common" ] && continue
    for dir in "$cat_dir"/*; do
        [ -d "$dir" ] || continue
        target=$(basename "$dir")
        
        if [ -n "$TARGET_COMP" ] && [ "$TARGET_COMP" != "$target" ]; then
            continue
        fi

        # Skip if already tested
        if [ -f "tests_tmp/$target.linux.alpine.success" ] || [ -f "tests_tmp/$target.linux.alpine.failure" ]; then
            continue
        fi

        echo "Testing $target..."
        stdout_file="tests_tmp/$target.linux.alpine.stdout"
        stderr_file="tests_tmp/$target.linux.alpine.stderr"
        
        if sh libscript.sh install "$target" > "$stdout_file" 2> "$stderr_file" && sh libscript.sh test "$target" >> "$stdout_file" 2>> "$stderr_file"; then
            echo "Success" > "tests_tmp/$target.linux.alpine.success"
            echo "[OK] $target"
        else
            echo "Failure" > "tests_tmp/$target.linux.alpine.failure"
            echo "[FAILED] $target"
        fi
    done
done
