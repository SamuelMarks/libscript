#!/bin/sh
# ## Overview
# Runs local tests using Vagrant across all toolchains, languages, and databases
# to verify libscript installation and testing on alpine-3.24.
#
# ## Usage
# Results are written to the tests_tmp directory.

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
THIS_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
REPO_ROOT=$(cd "$THIS_DIR/.." && pwd)

if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ "$1" = "/?" ]; then
    echo "Usage: $(basename "$THIS_FILE") [TARGETS...|all]"
    echo ""
    echo "Runs local tests using Vagrant across specified categories or individual targets"
    echo "to verify libscript installation and testing on alpine-3.24."
    echo ""
    echo "Arguments:"
    echo "  TARGETS...     A list of categories (e.g., databases, languages) or specific targets."
    echo "                 If no arguments are provided, defaults to: databases languages toolchains"
    echo "  all            Run tests across all categories in the _lib directory."
    echo "  --help, -h, /? Show this help message."
    echo ""
    echo "Results are written to the tests_tmp directory."
    exit 0
fi

TESTS_TMP_DIR="$REPO_ROOT/tests_tmp"
mkdir -p "$TESTS_TMP_DIR"

TARGETS=""
if [ $# -eq 0 ]; then
    set -- databases languages toolchains
fi

for arg in "$@"; do
    if [ "$arg" = "all" ]; then
        for cat_dir in "$REPO_ROOT"/_lib/*; do
            if [ -d "$cat_dir" ] && [ "$(basename "$cat_dir")" != "_common" ]; then
                for dir in "$cat_dir"/*; do
                    [ -d "$dir" ] && TARGETS="$TARGETS $(basename "$dir")"
                done
            fi
        done
    elif [ -d "$REPO_ROOT/_lib/$arg" ]; then
        for dir in "$REPO_ROOT/_lib/$arg"/*; do
            [ -d "$dir" ] && TARGETS="$TARGETS $(basename "$dir")"
        done
    else
        found=0
        for cat_dir in "$REPO_ROOT"/_lib/*; do
            if [ -d "$cat_dir/$arg" ]; then
                TARGETS="$TARGETS $arg"
                found=1
                break
            fi
        done
        if [ $found -eq 0 ]; then
            echo "Warning: Target '$arg' not found."
        fi
    fi
done

UNIQUE_TARGETS=$(echo "$TARGETS" | tr ' ' '\n' | grep -v '^$' | sort -u | tr '\n' ' ')

for target in $UNIQUE_TARGETS; do
    echo "============================================================"
    echo "Running test for $target on alpine-3.24..."
    echo "============================================================"
    
    export LIBSCRIPT_TEST_TARGET="$target"
    export LIBSCRIPT_REPO_ROOT="$REPO_ROOT"
    
    # Create an isolated environment for this run
    RUN_DIR="$TESTS_TMP_DIR/runs/$target"
    mkdir -p "$RUN_DIR"
    cp "$REPO_ROOT/vagrant/alpine-3.24/Vagrantfile" "$RUN_DIR/Vagrantfile"
    cd "$RUN_DIR"
    
    # Ensure clean state (in case of previous aborted runs in this dir)
    vagrant destroy -f >/dev/null 2>&1 || true
    sleep 2
    
    stdout_file="$TESTS_TMP_DIR/$target.linux.alpine.stdout"
    stderr_file="$TESTS_TMP_DIR/$target.linux.alpine.stderr"
    success_file="$TESTS_TMP_DIR/$target.linux.alpine.success"
    failure_file="$TESTS_TMP_DIR/$target.linux.alpine.failure"
    
    rm -f "$success_file" "$failure_file"
    
    if vagrant up > "$stdout_file" 2> "$stderr_file"; then
        echo "Success" > "$success_file"
        echo "[OK] $target"
    else
        echo "Failure" > "$failure_file"
        echo "[FAILED] $target"
    fi
    
    vagrant destroy -f >/dev/null 2>&1 || true
    sleep 2
done

echo "All tests complete. Results are in $TESTS_TMP_DIR."