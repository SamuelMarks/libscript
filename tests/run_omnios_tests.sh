#!/bin/sh
# ## Overview
# Runs tests sequentially for libscript components on a local OmniOS Vagrant VM
# (`bento/omnios`). Results, execution logs, and statuses are written into tests_tmp/
# and the Supported Components table in README.md is automatically updated after each test.
#
# ## Usage
# ./tests/run_omnios_tests.sh [TARGETS...|all]
# Example: ./tests/run_omnios_tests.sh curl sqlite tmux
# Example: ./tests/run_omnios_tests.sh all

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
VAGRANT_DIR="$REPO_ROOT/vagrant/omnios"
TESTS_TMP_DIR="$REPO_ROOT/tests_tmp"

mkdir -p "$TESTS_TMP_DIR"

TARGETS=""
STOP_AFTER=""
SKIP_UNINSTALL=""
LOOP_MODE=""
USE_SNAPSHOT="1"

# ## find_disk_image
# Finds the active qcow2 disk image for the OmniOS Vagrant machine.
find_disk_image() {
    for _id_file in "$VAGRANT_DIR"/.vagrant/machines/*/qemu/id; do
        if [ -f "$_id_file" ]; then
            _id=$(cat "$_id_file")
            _m_dir=$(dirname "$_id_file")
            _img="$_m_dir/$_id/linked-box.img"
            if [ -f "$_img" ]; then
                printf '%s
' "$_img"
                return 0
            fi
        fi
    done
    return 1
}

# ## find_qemu_socket
# Finds the active QEMU monitor UNIX socket for live snapshot control.
find_qemu_socket() {
    for _id_file in "$VAGRANT_DIR"/.vagrant/machines/*/qemu/id; do
        if [ -f "$_id_file" ]; then
            _id=$(cat "$_id_file")
            _sock="$HOME/.vagrant.d/tmp/vagrant-qemu/$_id/qemu_socket"
            if [ -S "$_sock" ]; then
                printf '%s
' "$_sock"
                return 0
            fi
        fi
    done
    return 1
}

# ## restore_vanilla_snapshot
# Restores the vanilla snapshot on the OmniOS VM via QEMU monitor socket or qemu-img.
restore_vanilla_snapshot() {
    _sock=$(find_qemu_socket || true)
    if [ -n "$_sock" ] && command -v nc >/dev/null 2>&1; then
        echo "Restoring vanilla snapshot via QEMU monitor socket..."
        echo "loadvm vanilla" | nc -U "$_sock" >/dev/null 2>&1 || true
        sleep 2
        return 0
    fi

    _img=$(find_disk_image || true)
    if [ -n "$_img" ] && command -v qemu-img >/dev/null 2>&1; then
        if qemu-img snapshot -U -l "$_img" 2>/dev/null | grep -q "vanilla"; then
            echo "Halting VM to restore vanilla snapshot..."
            (cd "$VAGRANT_DIR" && vagrant halt) || true
            echo "Restoring vanilla snapshot..."
            qemu-img snapshot -a vanilla "$_img"
            echo "Starting OmniOS Vagrant VM from vanilla snapshot..."
            (cd "$VAGRANT_DIR" && vagrant up --no-provision)
            return 0
        fi
    fi
    return 1
}

# ## sync_repo_to_guest
# Synchronizes the libscript codebase to the guest VM using rsync over ssh.
sync_repo_to_guest() {
    echo "=== Syncing LibScript repository to OmniOS ==="
    _ssh_info=$(cd "$VAGRANT_DIR" && vagrant ssh-config 2>/dev/null || true)
    _port=$(echo "$_ssh_info" | awk '/Port / {print $2; exit}')
    _key=$(echo "$_ssh_info" | awk '/IdentityFile / {print $2; exit}')
    : "${_port:=50022}"
    : "${_key:=$HOME/.vagrant.d/insecure_private_keys/vagrant.key.rsa}"

    rsync -av --copy-links --no-owner --no-group \
        -e "ssh -p $_port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $_key" \
        --exclude ".vagrant" --exclude ".git" --exclude "tests_tmp" --exclude "*.msi" --exclude "cache" \
        "$REPO_ROOT/" "vagrant@127.0.0.1:/opt/repos/libscript/"
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
        $2 ~ "^[ 	]*`" comp "`[ 	]*$" {
            $7 = " " st " "
        }
        { print }
    ' "$_rm" > "$_tmp_rm" && mv "$_tmp_rm" "$_rm"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h|/?)
            echo "Usage: $(basename "$THIS_FILE") [TARGETS...|all] [--stop-after N] [--skip-uninstall] [--loop] [--no-snapshot]"
            echo ""
            echo "Runs local tests sequentially on OmniOS (bento/omnios) Vagrant VM."
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
            echo "Results are written to tests_tmp/ (*.sunos.stdout, *.sunos.stderr, *.sunos.success/failure)."
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
    echo "Error: OmniOS Vagrant environment not found at $VAGRANT_DIR"
    exit 1
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
    elif [ -d "$REPO_ROOT/_lib/$arg" ]; then
        for dir in "$REPO_ROOT/_lib/$arg"/*; do
            [ -d "$dir" ] && EXPANDED_TARGETS="$EXPANDED_TARGETS $(basename "$dir")"
        done
    elif [ -d "$REPO_ROOT/stacks/$arg" ]; then
        for dir in "$REPO_ROOT/stacks/$arg"/*; do
            [ -d "$dir" ] && EXPANDED_TARGETS="$EXPANDED_TARGETS $(basename "$dir")"
        done
    elif [ -d "$REPO_ROOT/$arg" ]; then
        EXPANDED_TARGETS="$EXPANDED_TARGETS $_base_arg"
    else
        found=0
        for cat_dir in "$REPO_ROOT"/_lib/* "$REPO_ROOT"/stacks/*; do
            if [ -d "$cat_dir/$_base_arg" ]; then
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
        echo "Starting OmniOS Test Loop (Iteration $iteration)"
        echo "============================================================"
    fi

    DISK_IMG=""
    QEMU_SOCK=""
    if [ "$USE_SNAPSHOT" = "1" ]; then
        QEMU_SOCK=$(find_qemu_socket || true)
        DISK_IMG=$(find_disk_image || true)
        _has_vanilla=0
        if [ -n "$QEMU_SOCK" ] && command -v nc >/dev/null 2>&1; then
            if echo "info snapshots" | nc -U "$QEMU_SOCK" 2>/dev/null | grep -q "vanilla"; then
                _has_vanilla=1
            fi
        elif [ -n "$DISK_IMG" ] && command -v qemu-img >/dev/null 2>&1; then
            if qemu-img snapshot -U -l "$DISK_IMG" 2>/dev/null | grep -q "vanilla"; then
                _has_vanilla=1
            fi
        fi

        if [ "$_has_vanilla" = "0" ]; then
            echo "Notice: No 'vanilla' snapshot found. Disabling snapshot restoration."
            USE_SNAPSHOT="0"
        fi
    fi

    echo "=== Ensuring OmniOS Vagrant VM is running ==="
    cd "$VAGRANT_DIR"
    vm_status=$(vagrant status 2>&1 || true)
    if ! echo "$vm_status" | grep -q "running"; then
        if [ -n "$DISK_IMG" ] && [ "$USE_SNAPSHOT" = "1" ]; then
            restore_vanilla_snapshot || vagrant up --no-provision
        else
            echo "Starting OmniOS Vagrant VM..."
            vagrant up --no-provision
        fi
    fi

    sync_repo_to_guest

    _ssh_info=$(cd "$VAGRANT_DIR" && vagrant ssh-config 2>/dev/null || true)
    _port=$(echo "$_ssh_info" | awk '/Port / {print $2; exit}')
    _key=$(echo "$_ssh_info" | awk '/IdentityFile / {print $2; exit}')
    : "${_port:=50022}"
    : "${_key:=$HOME/.vagrant.d/insecure_private_keys/vagrant.key.rsa}"

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
                if ($0 ~ /"sunos"/) { result="no"; exit }
                if ($0 ~ /\]/) { in_bl=0 }
                next
            }
            /"os_whitelist"\s*:/ {
                in_wl=1; in_bl=0; has_wl=1
                if ($0 ~ /"sunos"/ || $0 ~ /"all"/) { wl_match=1 }
                if ($0 ~ /\]/) { in_wl=0 }
                next
            }
            in_bl {
                if ($0 ~ /"sunos"/) { result="no"; exit }
                if ($0 ~ /\]/) { in_bl=0 }
            }
            in_wl {
                if ($0 ~ /"sunos"/ || $0 ~ /"all"/) { wl_match=1 }
                if ($0 ~ /\]/) { in_wl=0 }
            }
            END { if (result == "yes" && has_wl && !wl_match) { result="no" }; print result }
            ' "$MANIFEST_PATH")
            if [ "$SUPPORTED" = "no" ]; then
                echo "Skipping $target (not supported on sunos)"
                skipped_count=$((skipped_count + 1))
                update_component_in_readme "$target" "-"
                continue
            fi
        fi

        echo "============================================================"
        echo "Running test for $target on OmniOS..."
        echo "============================================================"
        test_count=$((test_count + 1))

        # Restore vanilla snapshot before running if enabled and not the very first run
        if [ "$USE_SNAPSHOT" = "1" ] && [ "$test_count" -gt 1 ]; then
            restore_vanilla_snapshot || true
            sync_repo_to_guest
        fi

        stdout_file="$TESTS_TMP_DIR/$target.sunos.stdout"
        stderr_file="$TESTS_TMP_DIR/$target.sunos.stderr"
        success_file="$TESTS_TMP_DIR/$target.sunos.success"
        failure_file="$TESTS_TMP_DIR/$target.sunos.failure"
        idempotent_file="$TESTS_TMP_DIR/$target.idempotent.success"

        rm -f "$success_file" "$failure_file" "$idempotent_file"

        # Execute test via ssh: install -> test -> install (idempotency) -> test (verification)
        test_cmd="export PATH=/usr/gnu/bin:/opt/ooce/bin:\$PATH; export LIBSCRIPT_ROOT_DIR=/opt/repos/libscript; timeout 600 /opt/repos/libscript/libscript.sh install $target && timeout 120 /opt/repos/libscript/libscript.sh test $target && timeout 600 /opt/repos/libscript/libscript.sh install $target && timeout 120 /opt/repos/libscript/libscript.sh test $target"

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
            cleanup_cmd="export LIBSCRIPT_ROOT_DIR=/opt/repos/libscript; /opt/repos/libscript/libscript.sh uninstall $target >/dev/null 2>&1 || true; rm -rf /export/home/vagrant/.libscript/$target 2>/dev/null || true"
            ssh -p "$_port" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$_key" vagrant@127.0.0.1 "$cleanup_cmd" >/dev/null 2>&1 || true
        fi
    done

    if [ -x "$REPO_ROOT/tests/update_results.sh" ]; then
        "$REPO_ROOT/tests/update_results.sh" || true
    fi

    echo ""
    echo "============================================================"
    echo "OmniOS Tests Complete (Iteration $iteration)"
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
