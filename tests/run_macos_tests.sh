#!/bin/sh
# ## Overview
# Runs tests sequentially for libscript components on macOS (Darwin).
# Supports testing via a local macOS Vagrant VM (`bento/macos-14-arm64`) using
# UTM snapshot restoration (snapshot vanilla; run process; check result; restore snapshot; repeat)
# or direct native execution on macOS hosts. Results, execution logs, and statuses are written
# into tests_tmp/ and the Supported Components table in README.md is updated after each test.
#
# ## Usage
# ./tests/run_macos_tests.sh [TARGETS...|all] [--loop] [--stop-after N] [--skip-uninstall] [--no-snapshot] [--native]
# Example: ./tests/run_macos_tests.sh curl sqlite tmux
# Example: ./tests/run_macos_tests.sh all

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
VAGRANT_DIR="$REPO_ROOT/vagrant/macos-14-arm64"
TESTS_TMP_DIR="$REPO_ROOT/tests_tmp"

mkdir -p "$TESTS_TMP_DIR"

TARGETS=""
STOP_AFTER=""
SKIP_UNINSTALL=""
LOOP_MODE=""
USE_SNAPSHOT="1"
USE_NATIVE=""

# ## find_utm_vm_name
# Discovers the active or configured UTM virtual machine name for macOS.
find_utm_vm_name() {
    _found=""
    if command -v utmctl >/dev/null 2>&1; then
        _found=$(utmctl list 2>/dev/null | awk '/macos/ {print $2; exit}' || true)
    elif [ -x "/Applications/UTM.app/Contents/MacOS/utmctl" ]; then
        _found=$(/Applications/UTM.app/Contents/MacOS/utmctl list 2>/dev/null | awk '/macos/ {print $2; exit}' || true)
    fi
    if [ -n "$_found" ]; then
        printf '%s
' "$_found"
        return 0
    fi
    return 1
}

# ## restore_vanilla_snapshot
# Restores the vanilla snapshot on the macOS Vagrant VM using vagrant snapshot or utmctl.
restore_vanilla_snapshot() {
    echo "Restoring macOS vanilla snapshot..."
    if [ -d "$VAGRANT_DIR" ]; then
        if (cd "$VAGRANT_DIR" && vagrant snapshot restore vanilla --no-provision 2>/dev/null); then
            echo "Successfully restored vanilla snapshot via Vagrant."
            return 0
        fi
    fi
    _vm_name=$(find_utm_vm_name || true)
    if [ -n "$_vm_name" ]; then
        _utmctl="utmctl"
        [ ! -x "$(command -v utmctl 2>/dev/null)" ] && [ -x "/Applications/UTM.app/Contents/MacOS/utmctl" ] && _utmctl="/Applications/UTM.app/Contents/MacOS/utmctl"
        if "$_utmctl" list 2>/dev/null | grep -q "${_vm_name}-snapshot-vanilla"; then
            "$_utmctl" stop "$_vm_name" 2>/dev/null || true
            "$_utmctl" delete "$_vm_name" 2>/dev/null || true
            "$_utmctl" clone "${_vm_name}-snapshot-vanilla" --name "$_vm_name" 2>/dev/null || true
            "$_utmctl" start "$_vm_name" 2>/dev/null || true
            return 0
        fi
    fi
    return 1
}

# ## save_vanilla_snapshot
# Creates a vanilla snapshot on the running macOS VM if not already present.
save_vanilla_snapshot() {
    echo "Creating vanilla snapshot for macOS VM..."
    if [ -d "$VAGRANT_DIR" ]; then
        if (cd "$VAGRANT_DIR" && vagrant snapshot save vanilla 2>/dev/null); then
            echo "Successfully saved vanilla snapshot."
            return 0
        fi
    fi
    _vm_name=$(find_utm_vm_name || true)
    if [ -n "$_vm_name" ]; then
        _utmctl="utmctl"
        [ ! -x "$(command -v utmctl 2>/dev/null)" ] && [ -x "/Applications/UTM.app/Contents/MacOS/utmctl" ] && _utmctl="/Applications/UTM.app/Contents/MacOS/utmctl"
        "$_utmctl" clone "$_vm_name" --name "${_vm_name}-snapshot-vanilla" 2>/dev/null || true
        return 0
    fi
    return 1
}

# ## sync_repo_to_guest
# Synchronizes the libscript codebase to the macOS Vagrant VM.
sync_repo_to_guest() {
    echo "=== Syncing LibScript repository to macOS Vagrant VM ==="
    (cd "$VAGRANT_DIR" && vagrant rsync 2>/dev/null) || true
}

# ## update_component_in_readme
# Updates the status of a single component in README.md Supported Components table (macOS column).
update_component_in_readme() {
    _comp="$1"
    _status="$2"
    _rm="$REPO_ROOT/README.md"
    [ ! -f "$_rm" ] && return 0
    _tmp_rm=$(mktemp "${TMPDIR:-/tmp}/readme_line.XXXXXX")
    awk -v comp="$_comp" -v st="$_status" '
        BEGIN { FS="|"; OFS="|" }
        $2 ~ "^[ 	]*`" comp "`[ 	]*$" {
            $9 = " " st " "
        }
        { print }
    ' "$_rm" > "$_tmp_rm" && mv "$_tmp_rm" "$_rm"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h|/?)
            echo "Usage: $(basename "$THIS_FILE") [TARGETS...|all] [--stop-after N] [--skip-uninstall] [--loop] [--no-snapshot] [--native]"
            echo ""
            echo "Runs local tests sequentially on macOS (Darwin)."
            echo ""
            echo "Arguments:"
            echo "  TARGETS...          A list of categories or components to test."
            echo "                      Defaults to 'all' if omitted."
            echo "  all                 Test all components in the _lib directory."
            echo "  --loop, -l          Continuously repeat testing in an automated loop."
            echo "  --stop-after N      Stop after running N component tests."
            echo "  --skip-uninstall    Skip uninstallation step after testing each component."
            echo "  --no-snapshot       Do not restore the vanilla snapshot before each test."
            echo "  --native            Execute tests natively on the current macOS host."
            echo "  --help, -h, /?      Show this help message."
            echo ""
            echo "Results are written to tests_tmp/ (*.darwin.stdout, *.darwin.stderr, *.darwin.success/failure)."
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
        --no-snapshot)
            USE_SNAPSHOT="0"
            shift
            ;;
        --native)
            USE_NATIVE="1"
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

EXPANDED_TARGETS=""
for arg in $TARGETS; do
    _base_arg=$(basename "$arg")
    if [ "$arg" = "all" ]; then
        for cat_dir in "$REPO_ROOT"/_lib/* "$REPO_ROOT"/stacks/*; do
            if [ -d "$cat_dir" ] && [ "$(basename "$cat_dir")" != "_common" ]; then
                for dir in "$cat_dir"/*; do
                    [ -d "$dir" ] && EXPANDED_TARGETS="$EXPANDED_TARGETS $(basename "$dir")"
                done
            fi
        done
    elif [ -f "$REPO_ROOT/_lib/$arg/manifest.json" ] || [ -f "$REPO_ROOT/_lib/$arg/cli.sh" ]; then
        EXPANDED_TARGETS="$EXPANDED_TARGETS $_base_arg"
    elif [ -f "$REPO_ROOT/stacks/$arg/manifest.json" ] || [ -f "$REPO_ROOT/stacks/$arg/cli.sh" ]; then
        EXPANDED_TARGETS="$EXPANDED_TARGETS $_base_arg"
    elif [ -d "$REPO_ROOT/_lib/$arg" ] && [ ! -f "$REPO_ROOT/_lib/$arg/manifest.json" ]; then
        for dir in "$REPO_ROOT/_lib/$arg"/*; do
            [ -d "$dir" ] && EXPANDED_TARGETS="$EXPANDED_TARGETS $(basename "$dir")"
        done
    elif [ -d "$REPO_ROOT/stacks/$arg" ] && [ ! -f "$REPO_ROOT/stacks/$arg/manifest.json" ]; then
        for dir in "$REPO_ROOT/stacks/$arg"/*; do
            [ -d "$dir" ] && EXPANDED_TARGETS="$EXPANDED_TARGETS $(basename "$dir")"
        done
    elif [ -d "$REPO_ROOT/$arg" ]; then
        EXPANDED_TARGETS="$EXPANDED_TARGETS $_base_arg"
    else
        found=0
        for cat_dir in "$REPO_ROOT"/_lib/* "$REPO_ROOT"/stacks/*; do
            if [ -d "$cat_dir/$_base_arg" ] && { [ -f "$cat_dir/$_base_arg/manifest.json" ] || [ -f "$cat_dir/$_base_arg/cli.sh" ]; }; then
                EXPANDED_TARGETS="$EXPANDED_TARGETS $_base_arg"
                found=1
                break
            fi
        done
        if [ $found -eq 0 ]; then
            echo "Warning: Target '$arg' not found in _lib/ or stacks/."
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
        echo "Starting macOS Test Loop (Iteration $iteration)"
        echo "============================================================"
    fi

    # Determine execution mode: Vagrant VM vs Native macOS
    VAGRANT_ACTIVE=0
    if [ "$USE_NATIVE" != "1" ] && [ -d "$VAGRANT_DIR" ]; then
        cd "$VAGRANT_DIR"
        vm_status=$(env VAGRANT_DEFAULT_PROVIDER=utm vagrant status 2>&1 || true)
        if echo "$vm_status" | grep -q "running"; then
            VAGRANT_ACTIVE=1
        fi
        cd "$REPO_ROOT"
    fi

    if [ "$VAGRANT_ACTIVE" = "1" ]; then
        echo "=== Connected to macOS Vagrant VM ==="
        if [ "$USE_SNAPSHOT" = "1" ]; then
            restore_vanilla_snapshot || true
        fi
        sync_repo_to_guest
        _ssh_info=$(cd "$VAGRANT_DIR" && vagrant ssh-config 2>/dev/null || true)
        _port=$(echo "$_ssh_info" | awk '/Port / {print $2; exit}')
        _key=$(echo "$_ssh_info" | awk '/IdentityFile / {print $2; exit}')
        : "${_port:=22}"
        : "${_key:=$HOME/.vagrant.d/insecure_private_key}"
    else
        echo "=== Running tests natively on macOS host ==="
    fi

    test_count=0
    success_count=0
    failure_count=0
    skipped_count=0

    for target in $UNIQUE_TARGETS; do
        if [ -n "$STOP_AFTER" ] && [ "$test_count" -ge "$STOP_AFTER" ]; then
            echo "Reached limit of $STOP_AFTER tests. Stopping."
            break
        fi

        # Check manifest for macOS support
        MANIFEST_PATH=""
        for _m in "$REPO_ROOT/_lib"/*/"$target/manifest.json" "$REPO_ROOT/stacks"/*/"$target/manifest.json"; do
            if [ -f "$_m" ]; then
                MANIFEST_PATH="$_m"
                break
            fi
        done

        if [ -n "$MANIFEST_PATH" ]; then
            SUPPORTED=$(awk '
            BEGIN { in_bl=0; in_wl=0; has_wl=0; wl_match=0; result="yes" }
            /"os_blacklist"\s*:/ {
                in_bl=1; in_wl=0
                if ($0 ~ /"darwin"/ || $0 ~ /"macos"/) { result="no"; exit }
                if ($0 ~ /\]/) { in_bl=0 }
                next
            }
            /"os_whitelist"\s*:/ {
                in_wl=1; in_bl=0; has_wl=1
                if ($0 ~ /"darwin"/ || $0 ~ /"macos"/ || $0 ~ /"all"/) { wl_match=1 }
                if ($0 ~ /\]/) { in_wl=0 }
                next
            }
            in_bl {
                if ($0 ~ /"darwin"/ || $0 ~ /"macos"/) { result="no"; exit }
                if ($0 ~ /\]/) { in_bl=0 }
            }
            in_wl {
                if ($0 ~ /"darwin"/ || $0 ~ /"macos"/ || $0 ~ /"all"/) { wl_match=1 }
                if ($0 ~ /\]/) { in_wl=0 }
            }
            END { if (result == "yes" && has_wl && !wl_match) { result="no" }; print result }
            ' "$MANIFEST_PATH")
            if [ "$SUPPORTED" = "no" ]; then
                echo "Skipping $target (not supported on macOS)"
                skipped_count=$((skipped_count + 1))
                update_component_in_readme "$target" "-"
                echo "Unsupported" > "$TESTS_TMP_DIR/$target.darwin.unsupported"
                continue
            fi
        fi

        echo "============================================================"
        echo "Running test for $target on macOS..."
        echo "============================================================"
        test_count=$((test_count + 1))

        # Restore vanilla snapshot before running if enabled and in Vagrant mode
        if [ "$VAGRANT_ACTIVE" = "1" ] && [ "$USE_SNAPSHOT" = "1" ] && [ "$test_count" -gt 1 ]; then
            restore_vanilla_snapshot || true
            sync_repo_to_guest
        fi

        stdout_file="$TESTS_TMP_DIR/$target.darwin.stdout"
        stderr_file="$TESTS_TMP_DIR/$target.darwin.stderr"
        success_file="$TESTS_TMP_DIR/$target.darwin.success"
        failure_file="$TESTS_TMP_DIR/$target.darwin.failure"
        idempotent_file="$TESTS_TMP_DIR/$target.idempotent.success"

        rm -f "$success_file" "$failure_file" "$idempotent_file"

        # Execute test: install -> test -> install (idempotency) -> test (verification)
        if [ "$VAGRANT_ACTIVE" = "1" ]; then
            test_cmd="export PATH=/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:\$PATH; export LIBSCRIPT_ROOT_DIR=/Users/vagrant/libscript; /Users/vagrant/libscript/libscript.sh install $target && /Users/vagrant/libscript/libscript.sh test $target && /Users/vagrant/libscript/libscript.sh install $target && /Users/vagrant/libscript/libscript.sh test $target"
            if ssh -p "$_port" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$_key" vagrant@127.0.0.1 "$test_cmd" > "$stdout_file" 2> "$stderr_file"; then
                echo "Success" > "$success_file"
                echo "Idempotent" > "$idempotent_file"
                echo "[OK] $target (2x install + test verified)"
                success_count=$((success_count + 1))
                update_component_in_readme "$target" "✅"
            else
                echo "Failure" > "$failure_file"
                echo "[FAILED] $target"
                failure_count=$((failure_count + 1))
                update_component_in_readme "$target" "❌"
            fi
        else
            # Native macOS execution
            export LIBSCRIPT_ROOT_DIR="$REPO_ROOT"
            export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH}"
            if "$REPO_ROOT/libscript.sh" install "$target" > "$stdout_file" 2> "$stderr_file" && 
               "$REPO_ROOT/libscript.sh" test "$target" >> "$stdout_file" 2>> "$stderr_file" && 
               "$REPO_ROOT/libscript.sh" install "$target" >> "$stdout_file" 2>> "$stderr_file" && 
               "$REPO_ROOT/libscript.sh" test "$target" >> "$stdout_file" 2>> "$stderr_file"; then
                echo "Success" > "$success_file"
                echo "Idempotent" > "$idempotent_file"
                echo "[OK] $target (2x install + test verified)"
                success_count=$((success_count + 1))
                update_component_in_readme "$target" "✅"
            else
                echo "Failure" > "$failure_file"
                echo "[FAILED] $target"
                failure_count=$((failure_count + 1))
                update_component_in_readme "$target" "❌"
            fi
        fi

        # Cleanup if requested
        if [ "$USE_SNAPSHOT" != "1" ] && [ -z "$SKIP_UNINSTALL" ]; then
            if [ "$VAGRANT_ACTIVE" = "1" ]; then
                cleanup_cmd="export LIBSCRIPT_ROOT_DIR=/Users/vagrant/libscript; /Users/vagrant/libscript/libscript.sh uninstall $target >/dev/null 2>&1 || true; rm -rf /Users/vagrant/.libscript/$target 2>/dev/null || true"
                ssh -p "$_port" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$_key" vagrant@127.0.0.1 "$cleanup_cmd" >/dev/null 2>&1 || true
            else
                "$REPO_ROOT/libscript.sh" uninstall "$target" >/dev/null 2>&1 || true
                rm -rf "$HOME/.libscript/$target" 2>/dev/null || true
            fi
        fi
    done

    if [ -x "$REPO_ROOT/tests/update_results.sh" ]; then
        "$REPO_ROOT/tests/update_results.sh" || true
    fi

    echo ""
    echo "============================================================"
    echo "macOS Tests Complete (Iteration $iteration)"
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
