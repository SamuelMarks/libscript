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
USE_SNAPSHOT="1"

# ## find_disk_image
# Finds the active qcow2 disk image for the Windows 11 Vagrant machine.
find_disk_image() {
    for _id_file in "$VAGRANT_DIR"/.vagrant/machines/*/qemu/id; do
        if [ -f "$_id_file" ]; then
            _id=$(cat "$_id_file")
            _m_dir=$(dirname "$_id_file")
            _img="$_m_dir/$_id/linked-box.img"
            if [ -f "$_img" ]; then
                printf '%s\n' "$_img"
                return 0
            fi
        fi
    done
    return 1
}

# ## restore_vanilla_snapshot
# Stops the VM and restores the vanilla snapshot on the disk image.
restore_vanilla_snapshot() {
    _img="$1"
    if [ -n "$_img" ] && command -v qemu-img >/dev/null 2>&1; then
        if qemu-img snapshot -U -l "$_img" 2>/dev/null | grep -q "vanilla"; then
            echo "Halting VM to restore vanilla snapshot..."
            (cd "$VAGRANT_DIR" && vagrant halt) || true
            echo "Restoring vanilla snapshot..."
            qemu-img snapshot -a vanilla "$_img"
            echo "Starting Windows 11 Vagrant VM from vanilla snapshot..."
            (cd "$VAGRANT_DIR" && vagrant up --no-provision)
            return 0
        fi
    fi
    return 1
}

# ## sync_repo_to_guest
# Synchronizes the libscript codebase to the guest VM using rsync over ssh.
sync_repo_to_guest() {
    echo "=== Syncing LibScript repository to Windows 11 ==="
    _ssh_info=$(cd "$VAGRANT_DIR" && vagrant ssh-config 2>/dev/null || true)
    _port=$(echo "$_ssh_info" | awk '/Port / {print $2; exit}')
    _key=$(echo "$_ssh_info" | awk '/IdentityFile / {print $2; exit}')
    : "${_port:=50022}"
    : "${_key:=$HOME/.vagrant.d/insecure_private_key}"

    rsync -av --copy-links --no-owner --no-group \
        -e "ssh -p $_port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $_key" \
        --exclude ".vagrant" --exclude ".git" --exclude "tests_tmp" --exclude "*.msi" \
        "$REPO_ROOT/" "vagrant@127.0.0.1:/cygdrive/c/libscript/"
}

# ## update_component_in_readme
# Updates the status of a single component in README.md Supported Components table.
update_component_in_readme() {
    _comp="$1"
    _status="$2"
    _rm="$REPO_ROOT/README.md"
    [ ! -f "$_rm" ] && return 0
    _tmp_rm=$(mktemp "${TMPDIR:-/tmp}/readme_line.XXXXXX")
    awk -v comp="$_comp" -v st="$_status" '
        BEGIN { FS="|"; OFS="|" }
        $2 ~ "^[ \t]*`" comp "`[ \t]*$" {
            $6 = " " st " "
        }
        { print }
    ' "$_rm" > "$_tmp_rm" && mv "$_tmp_rm" "$_rm"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h|/?)
            echo "Usage: $(basename "$THIS_FILE") [TARGETS...|all] [--stop-after N] [--skip-uninstall] [--loop] [--no-snapshot]"
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
            echo "  --no-snapshot       Do not restore the vanilla snapshot before each test."
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
        --no-snapshot)
            USE_SNAPSHOT="0"
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
        for cat_dir in "$REPO_ROOT"/_lib/* "$REPO_ROOT"/stacks/*; do
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
    elif [ -d "$REPO_ROOT/stacks/$arg" ]; then
        for dir in "$REPO_ROOT/stacks/$arg"/*; do
            [ -d "$dir" ] && EXPANDED_TARGETS="$EXPANDED_TARGETS $(basename "$dir")"
        done
    else
        found=0
        for cat_dir in "$REPO_ROOT"/_lib/* "$REPO_ROOT"/stacks/*; do
            if [ -d "$cat_dir/$arg" ]; then
                EXPANDED_TARGETS="$EXPANDED_TARGETS $arg"
                found=1
                break
            fi
        done
        if [ $found -eq 0 ]; then
            echo "Warning: Target '$arg' not found in _lib/ or stacks/."
        fi
    fi
done

UNIQUE_TARGETS=$(echo "$EXPANDED_TARGETS" | tr ' ' '\n' | grep -v '^$' | sort -u | tr '\n' ' ')

iteration=1

while true; do
    if [ "$LOOP_MODE" = "1" ]; then
        echo "============================================================"
        echo "Starting Windows 11 Test Loop (Iteration $iteration)"
        echo "============================================================"
    fi

    DISK_IMG=""
    if [ "$USE_SNAPSHOT" = "1" ]; then
        DISK_IMG=$(find_disk_image || true)
        if [ -n "$DISK_IMG" ] && command -v qemu-img >/dev/null 2>&1; then
            if ! qemu-img snapshot -U -l "$DISK_IMG" 2>/dev/null | grep -q "vanilla"; then
                echo "Notice: No 'vanilla' snapshot found on $DISK_IMG. Disabling snapshot restoration and enabling in-place cleanup."
                USE_SNAPSHOT="0"
            fi
        fi
    fi

    echo "=== Ensuring Windows 11 Vagrant VM is running ==="
    cd "$VAGRANT_DIR"
    vm_status=$(vagrant status 2>&1 || true)
    if ! echo "$vm_status" | grep -q "running"; then
        if [ -n "$DISK_IMG" ] && [ "$USE_SNAPSHOT" = "1" ]; then
            restore_vanilla_snapshot "$DISK_IMG" || vagrant up --no-provision
        else
            echo "Starting Windows 11 Vagrant VM..."
            vagrant up --no-provision
        fi
    fi

    sync_repo_to_guest

    _ssh_info=$(cd "$VAGRANT_DIR" && vagrant ssh-config 2>/dev/null || true)
    _port=$(echo "$_ssh_info" | awk '/Port / {print $2; exit}')
    _key=$(echo "$_ssh_info" | awk '/IdentityFile / {print $2; exit}')
    : "${_port:=50022}"
    : "${_key:=$HOME/.vagrant.d/insecure_private_key}"

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
                update_component_in_readme "$target" "-"
                continue
            fi
        fi

        echo "============================================================"
        echo "Running test for $target on windows-11..."
        echo "============================================================"
        test_count=$((test_count + 1))

        # Restore vanilla snapshot before running if enabled and not the very first run
        if [ "$USE_SNAPSHOT" = "1" ] && [ -n "$DISK_IMG" ] && [ "$test_count" -gt 1 ]; then
            restore_vanilla_snapshot "$DISK_IMG" || true
            sync_repo_to_guest
        fi

        stdout_file="$TESTS_TMP_DIR/$target.windows.stdout"
        stderr_file="$TESTS_TMP_DIR/$target.windows.stderr"
        success_file="$TESTS_TMP_DIR/$target.windows.success"
        failure_file="$TESTS_TMP_DIR/$target.windows.failure"
        idempotent_file="$TESTS_TMP_DIR/$target.idempotent.success"

        rm -f "$success_file" "$failure_file" "$idempotent_file"

        # Execute test via ssh: install -> test -> install (idempotency) -> test (verification)
        test_cmd="cmd.exe /c \"C:\\libscript\\libscript.cmd install $target && C:\\libscript\\libscript.cmd test $target && C:\\libscript\\libscript.cmd install $target && C:\\libscript\\libscript.cmd test $target\""

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

        # Clean up installed files if snapshot restoration is disabled
        if [ "$USE_SNAPSHOT" != "1" ] && [ -z "$SKIP_UNINSTALL" ]; then
            cleanup_cmd="cmd.exe /c \"C:\\libscript\\libscript.cmd uninstall $target & rmdir /s /q %USERPROFILE%\\.libscript\\$target\""
            ssh -p "$_port" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$_key" vagrant@127.0.0.1 "$cleanup_cmd" >/dev/null 2>&1 || true
        fi
    done

    if [ -x "$REPO_ROOT/tests/update_results.sh" ]; then
        "$REPO_ROOT/tests/update_results.sh" || true
    fi

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
