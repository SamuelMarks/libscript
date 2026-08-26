#!/bin/sh
# ## Overview
# Runs local tests using Vagrant across all toolchains, languages, and databases
# to verify libscript installation and testing on isolated Vagrant VMs.
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

OS_TARGET="alpine-3.24"
TARGETS=""

# First pass to capture OS_TARGET and handle help
while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h|/?)
            echo "Usage: $(basename "$THIS_FILE") [TARGETS...|all] [--os OS_NAME]"
            echo ""
            echo "Runs local tests using Vagrant across specified categories or individual targets"
            echo "to verify libscript installation and testing."
            echo ""
            echo "Arguments:"
            echo "  TARGETS...     A list of categories (e.g., databases, languages) or specific targets."
            echo "                 If no targets are provided, defaults to: databases languages toolchains"
            echo "  all            Run tests across all categories in the _lib directory."
            echo "  --os OS_NAME   The OS environment to use from the vagrant/ folder (default: alpine-3.24)."
            echo "                 Example: --os debian-13-arm64"
            echo "  --help, -h, /? Show this help message."
            echo ""
            echo "Results are written to the tests_tmp directory."
            exit 0
            ;;
        --os)
            OS_TARGET="$2"
            shift 2
            ;;
        *)
            TARGETS="$TARGETS $1"
            shift
            ;;
    esac
done

if [ -z "$(echo "$TARGETS" | tr -d ' ')" ]; then
    TARGETS="databases languages toolchains"
fi

if [ ! -d "$REPO_ROOT/vagrant/$OS_TARGET" ]; then
    echo "Error: Vagrant environment '$OS_TARGET' not found in $REPO_ROOT/vagrant/"
    exit 1
fi

TESTS_TMP_DIR="$REPO_ROOT/tests_tmp"
mkdir -p "$TESTS_TMP_DIR"

EXPANDED_TARGETS=""
for arg in $TARGETS; do
    if [ "$arg" = "all" ]; then
        for cat_dir in "$REPO_ROOT"/_lib/*; do
            if [ -d "$cat_dir" ] && [ "$(basename "$cat_dir")" != "_common" ]; then
                for dir in "$cat_dir"/*; do
                    [ -d "$dir" ] && EXPANDED_TARGETS="$EXPANDED_TARGETS $(basename "$dir")"
                done
            fi
        done
    elif [ -d "$REPO_ROOT/_lib/$arg" ]; then
        for dir in "$REPO_ROOT/_lib/$arg"/*; do
            [ -d "$dir" ] && EXPANDED_TARGETS="$EXPANDED_TARGETS $(basename "$dir")"
        done
    else
        found=0
        for cat_dir in "$REPO_ROOT"/_lib/*; do
            if [ -d "$cat_dir/$arg" ]; then
                EXPANDED_TARGETS="$EXPANDED_TARGETS $arg"
                found=1
                break
            fi
        done
        if [ $found -eq 0 ]; then
            echo "Warning: Target '$arg' not found."
        fi
    fi
done

UNIQUE_TARGETS=$(echo "$EXPANDED_TARGETS" | tr ' ' '\n' | grep -v '^$' | sort -u | tr '\n' ' ')
OS_ID=$(echo "$OS_TARGET" | cut -d'-' -f1)

for target in $UNIQUE_TARGETS; do
    echo "============================================================"
    echo "Running test for $target on $OS_TARGET..."
    echo "============================================================"
    
    export LIBSCRIPT_TEST_TARGET="$target"
    export LIBSCRIPT_REPO_ROOT="$REPO_ROOT"
    
    # Create an isolated environment for this run
    RUN_DIR="$TESTS_TMP_DIR/runs/$target-$OS_TARGET"
    mkdir -p "$RUN_DIR"
    cp "$REPO_ROOT/vagrant/$OS_TARGET/Vagrantfile" "$RUN_DIR/Vagrantfile"
    cd "$RUN_DIR"
    
    # Ensure clean state (in case of previous aborted runs in this dir)
    vagrant destroy -f >/dev/null 2>&1 || true
    sleep 2
    
    stdout_file="$TESTS_TMP_DIR/$target.linux.$OS_ID.stdout"
    stderr_file="$TESTS_TMP_DIR/$target.linux.$OS_ID.stderr"
    success_file="$TESTS_TMP_DIR/$target.linux.$OS_ID.success"
    failure_file="$TESTS_TMP_DIR/$target.linux.$OS_ID.failure"
    
    rm -f "$success_file" "$failure_file"
    
    if vagrant up > "$stdout_file" 2> "$stderr_file"; then
        echo "Success" > "$success_file"
        echo "[OK] $target"
    else
        echo "Failure" > "$failure_file"
        echo "[FAILED] $target"
    fi
    
    if command -v python3 >/dev/null 2>&1 && [ -f "$REPO_ROOT/update_results.py" ]; then
        (cd "$REPO_ROOT" && python3 update_results.py) || true
    fi
    
    vagrant destroy -f >/dev/null 2>&1 || true
    sleep 2
done

echo "All tests complete. Results are in $TESTS_TMP_DIR."
