#!/bin/sh
# ## Overview
# Runs tests sequentially for libscript components on a local Windows 11 Vagrant VM
# (`bento/windows-11`). Results, execution logs, and statuses are written into tests_tmp/
# and the Supported Components table is automatically updated after each test.
#
# ## Usage
# ./tests/run_windows_tests.sh [TARGETS...|all]
# Example: ./tests/run_windows_tests.sh curl powershell sqlite
# Example: ./tests/run_windows_tests.sh all

set -e

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"
VAGRANT_DIR="$REPO_ROOT/vagrant/windows-11"
TESTS_TMP_DIR="$REPO_ROOT/tests_tmp"

mkdir -p "$TESTS_TMP_DIR"

TARGETS=""
STOP_AFTER=""
SKIP_UNINSTALL=""
LOOP_MODE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h|/?)
            echo "Usage: $(basename "$THIS_FILE") [TARGETS...|all] [--stop-after N] [--skip-uninstall] [--loop]"
            echo ""
            echo "Runs local tests sequentially on Windows 11 (bento/windows-11) Vagrant VM."
            echo ""
            echo "Arguments:"
            echo "  TARGETS...          A list of categories or components to test."
            echo "                      Defaults to 'all' if omitted."
            echo "  all                 Test all components in the _lib directory."
            echo "  --loop, -l          Continuously repeat testing in an automated loop."
            echo "  --stop-after N      Stop after running N component tests."
            echo "  --skip-uninstall    Skip uninstallation step after testing each component."
            echo "  --help, -h, /?      Show this help message."
            echo ""
            echo "Results are written to tests_tmp/ (*.windows.stdout, *.windows.stderr, *.windows.success/failure)."
            exit 0
            ;;
        --loop|-l)
            LOOP_MODE="1"
            shift
            ;;
        --stop-after)
            STOP_AFTER="$2"
            shift 2
            ;;
        --skip-uninstall)
            SKIP_UNINSTALL="1"
            shift
            ;;
        *)
            TARGETS="$TARGETS $1"
            shift
            ;;
    esac
done

if [ -z "$(echo "$TARGETS" | tr -d ' ')" ]; then
    TARGETS="all"
fi

if [ ! -d "$VAGRANT_DIR" ]; then
    echo "Error: Windows 11 Vagrant environment not found at $VAGRANT_DIR"
    exit 1
fi

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
            echo "Warning: Target '$arg' not found in _lib/."
        fi
    fi
done

UNIQUE_TARGETS=$(echo "$EXPANDED_TARGETS" | tr ' ' '
' | grep -v '^$' | sort -u | tr '
' ' ')

iteration=1

while true; do
    if [ "$LOOP_MODE" = "1" ]; then
        echo "============================================================"
        echo "Starting Windows 11 Test Loop (Iteration $iteration)"
        echo "============================================================"
    fi

    echo "=== Ensuring Windows 11 Vagrant VM is running ==="
    cd "$VAGRANT_DIR"
    vm_status=$(vagrant status 2>&1 || true)
    if ! echo "$vm_status" | grep -q "running"; then
        echo "Starting Windows 11 Vagrant VM..."
        vagrant up --no-provision
    fi

    echo "=== Syncing LibScript repository to Windows 11 ==="
    vagrant rsync

    test_count=0
    success_count=0
    failure_count=0
    skipped_count=0

    for target in $UNIQUE_TARGETS; do
        if [ -n "$STOP_AFTER" ] && [ "$test_count" -ge "$STOP_AFTER" ]; then
            echo "Reached limit of $STOP_AFTER tests. Stopping."
            break
        fi

        # Check manifest for OS support
        MANIFEST_PATH=$(find "$REPO_ROOT/_lib" -maxdepth 2 -type d -name "$target" -exec echo "{}/manifest.json" \; 2>/dev/null | head -n 1)
        if [ -f "$MANIFEST_PATH" ]; then
            SUPPORTED=$(awk '
            BEGIN { in_bl=0; in_wl=0; has_wl=0; wl_match=0; result="yes" }
            /"os_blacklist"\s*:/ {
                in_bl=1; in_wl=0
                if ($0 ~ /"windows"/) { result="no"; exit }
                if ($0 ~ /\]/) { in_bl=0 }
                next
            }
            /"os_whitelist"\s*:/ {
                in_wl=1; in_bl=0; has_wl=1
                if ($0 ~ /"windows"/ || $0 ~ /"all"/) { wl_match=1 }
                if ($0 ~ /\]/) { in_wl=0 }
                next
            }
            in_bl {
                if ($0 ~ /"windows"/) { result="no"; exit }
                if ($0 ~ /\]/) { in_bl=0 }
            }
            in_wl {
                if ($0 ~ /"windows"/ || $0 ~ /"all"/) { wl_match=1 }
                if ($0 ~ /\]/) { in_wl=0 }
            }
            END { if (result == "yes" && has_wl && !wl_match) { result="no" }; print result }
            ' "$MANIFEST_PATH")
            if [ "$SUPPORTED" = "no" ]; then
                echo "Skipping $target (not supported on windows)"
                skipped_count=$((skipped_count + 1))
                continue
            fi
        fi

        echo "============================================================"
        echo "Running test for $target on windows-11..."
        echo "============================================================"
        test_count=$((test_count + 1))

        stdout_file="$TESTS_TMP_DIR/$target.windows.stdout"
        stderr_file="$TESTS_TMP_DIR/$target.windows.stderr"
        success_file="$TESTS_TMP_DIR/$target.windows.success"
        failure_file="$TESTS_TMP_DIR/$target.windows.failure"

        rm -f "$success_file" "$failure_file"

        # Execute test via vagrant ssh
        test_cmd='Set-Location C:\libscript; cmd.exe /c "C:\libscript\libscript.cmd install '$target'" ; $iExit = $LASTEXITCODE; cmd.exe /c "C:\libscript\libscript.cmd test '$target'" ; $tExit = $LASTEXITCODE; if ($tExit -ne 0) { exit $tExit } elseif ($iExit -ne 0) { exit $iExit }'

        if vagrant ssh -c "$test_cmd" > "$stdout_file" 2> "$stderr_file"; then
            echo "Success" > "$success_file"
            echo "[OK] $target"
            success_count=$((success_count + 1))
        else
            echo "Failure" > "$failure_file"
            echo "[FAILED] $target"
            failure_count=$((failure_count + 1))
        fi

        if [ -x "$REPO_ROOT/tests/update_results.sh" ]; then
            "$REPO_ROOT/tests/update_results.sh" || true
        fi

        # Clean up installed files to keep the VM clean
        if [ -z "$SKIP_UNINSTALL" ]; then
            cleanup_cmd="cd C:\libscript; & C:\libscript\libscript.cmd uninstall $target *>&1 | Out-Null; Remove-Item -Recurse -Force \"\$env:USERPROFILE\.libscript\\$target\" -ErrorAction SilentlyContinue"
            vagrant ssh -c "powershell -Command \"$cleanup_cmd\"" >/dev/null 2>&1 || true
        fi
    done

    echo ""
    echo "============================================================"
    echo "Windows 11 Tests Complete (Iteration $iteration)"
    echo "Ran: $test_count | Passed: $success_count | Failed: $failure_count | Skipped: $skipped_count"
    echo "Results in: $TESTS_TMP_DIR"
    echo "============================================================"

    if [ "$LOOP_MODE" != "1" ]; then
        break
    fi

    iteration=$((iteration + 1))
    echo "Loop mode active. Restarting test loop in 3 seconds..."
    sleep 3
done
