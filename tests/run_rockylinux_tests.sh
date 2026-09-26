#!/bin/sh
# ## Overview
# Runs tests sequentially for libscript components on a local Rocky Linux Vagrant VM
# (`bento/rockylinux-10.2`). Restores the vanilla snapshot before each test, verifies
# installation and test idempotency (2x run), writes logs to tests_tmp/, and automatically
# updates the Supported Components table in README.md and task completion in TODO_PLAN.md.
#
# ## Usage
# ./tests/run_rockylinux_tests.sh [TARGETS...|all]
# Example: ./tests/run_rockylinux_tests.sh curl sqlite jq
# Example: ./tests/run_rockylinux_tests.sh all
# Example: ./tests/run_rockylinux_tests.sh all --loop --stop-after 10

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
VAGRANT_DIR="$REPO_ROOT/vagrant/rockylinux-10.2"
TESTS_TMP_DIR="$REPO_ROOT/tests_tmp"

mkdir -p "$TESTS_TMP_DIR"

TARGETS=""
STOP_AFTER=""
SKIP_UNINSTALL=""
LOOP_MODE=""
USE_SNAPSHOT="1"

# ## find_disk_image
# Finds the active qcow2 disk image for the Rocky Linux Vagrant machine.
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

# ## restore_vanilla_snapshot
# Halts the VM, restores the vanilla snapshot on the disk image, and starts the VM.
restore_vanilla_snapshot() {
    _img=$(find_disk_image || true)
    if [ -n "$_img" ] && command -v qemu-img >/dev/null 2>&1; then
        if qemu-img snapshot -U -l "$_img" 2>/dev/null | grep -q "vanilla"; then
            echo "Halting Rocky Linux VM to restore vanilla snapshot..."
            (cd "$VAGRANT_DIR" && vagrant halt) || true
            echo "Restoring vanilla snapshot..."
            qemu-img snapshot -a vanilla "$_img"
            echo "Starting Rocky Linux Vagrant VM from vanilla snapshot..."
            (cd "$VAGRANT_DIR" && vagrant up --no-provision)
            return 0
        fi
    fi
    return 1
}

# ## sync_repo_to_guest
# Synchronizes the libscript codebase to the guest Rocky Linux VM using rsync over SSH.
sync_repo_to_guest() {
    echo "=== Syncing LibScript repository to Rocky Linux ==="
    _ssh_info=$(cd "$VAGRANT_DIR" && vagrant ssh-config 2>/dev/null || true)
    _port=$(echo "$_ssh_info" | awk '/Port / {print $2; exit}')
    _key=$(echo "$_ssh_info" | awk '/IdentityFile / {print $2; exit}')
    : "${_port:=50022}"
    : "${_key:=$HOME/.vagrant.d/insecure_private_keys/vagrant.key.ed25519}"

    rsync -av --copy-links --no-owner --no-group \
        -e "ssh -p $_port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $_key" \
        --exclude ".vagrant" --exclude ".git" --exclude "tests_tmp" --exclude "tmp" --exclude "*.msi" --exclude "cache" \
        "$REPO_ROOT/" "vagrant@127.0.0.1:/opt/repos/libscript/"
}

# ## update_component_in_readme
# Updates the status of a single component in the Linux (rpm) column of README.md.
update_component_in_readme() {
    _comp="$1"
    _status="$2"
    _rm="$REPO_ROOT/README.md"
    [ ! -f "$_rm" ] && return 0
    _tmp_rm=$(mktemp "${TMPDIR:-/tmp}/readme_line.XXXXXX")
    awk -v comp="$_comp" -v st="$_status" '
        BEGIN { FS="|"; OFS="|" }
        $2 ~ "^[ 	]*`" comp "`[ 	]*$" {
            $5 = " " st " "
        }
        { print }
    ' "$_rm" > "$_tmp_rm" && mv "$_tmp_rm" "$_rm"
}

# Parse command line options
while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h|/?)
            echo "Usage: $(basename "$THIS_FILE") [TARGETS...|all] [--stop-after N] [--skip-uninstall] [--loop] [--no-snapshot]"
            echo ""
            echo "Runs local tests sequentially on Rocky Linux (bento/rockylinux-10.2) Vagrant VM."
            echo ""
            echo "Arguments:"
            echo "  TARGETS...          A list of categories or components to test."
            echo "                      Defaults to 'all' if omitted."
            echo "  all                 Test all components in the _lib and stacks directories."
            echo "  --loop, -l          Continuously repeat testing in an automated loop."
            echo "  --stop-after N      Stop after running N component tests."
            echo "  --skip-uninstall    Skip uninstallation step after testing each component."
            echo "  --no-snapshot       Do not restore the vanilla snapshot before each test."
            echo "  --help, -h, /?      Show this help message."
            echo ""
            echo "Results are written to tests_tmp/ (*.linux.rocky.stdout, *.linux.rocky.stderr, *.linux.rocky.success/failure)."
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
    echo "Error: Rocky Linux Vagrant environment not found at $VAGRANT_DIR"
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
    elif [ -d "$REPO_ROOT/$arg" ]; then
        EXPANDED_TARGETS="$EXPANDED_TARGETS $_base_arg"
    elif [ -d "$REPO_ROOT/_lib/$arg" ]; then
        _has_subdirs=0
        for dir in "$REPO_ROOT/_lib/$arg"/*; do
            if [ -d "$dir" ] && [ -f "$dir/manifest.json" ]; then
                EXPANDED_TARGETS="$EXPANDED_TARGETS $(basename "$dir")"
                _has_subdirs=1
            fi
        done
        if [ "$_has_subdirs" -eq 0 ]; then
            for cat_dir in "$REPO_ROOT"/_lib/* "$REPO_ROOT"/stacks/*; do
                if [ -d "$cat_dir/$_base_arg" ] && [ -f "$cat_dir/$_base_arg/manifest.json" ]; then
                    EXPANDED_TARGETS="$EXPANDED_TARGETS $_base_arg"
                    _has_subdirs=1
                    break
                fi
            done
        fi
    elif [ -d "$REPO_ROOT/stacks/$arg" ]; then
        for dir in "$REPO_ROOT/stacks/$arg"/*; do
            [ -d "$dir" ] && EXPANDED_TARGETS="$EXPANDED_TARGETS $(basename "$dir")"
        done
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
        echo "Starting Rocky Linux Test Loop (Iteration $iteration)"
        echo "============================================================"
    fi

    DISK_IMG=""
    if [ "$USE_SNAPSHOT" = "1" ]; then
        DISK_IMG=$(find_disk_image || true)
        _has_vanilla=0
        if [ -n "$DISK_IMG" ] && command -v qemu-img >/dev/null 2>&1; then
            if qemu-img snapshot -U -l "$DISK_IMG" 2>/dev/null | grep -q "vanilla"; then
                _has_vanilla=1
            fi
        fi

        if [ "$_has_vanilla" = "0" ]; then
            echo "Notice: No 'vanilla' snapshot found on $DISK_IMG. Creating it now..."
            (cd "$VAGRANT_DIR" && vagrant halt) || true
            qemu-img snapshot -c vanilla "$DISK_IMG"
            _has_vanilla=1
        fi
    fi

    echo "=== Ensuring Rocky Linux Vagrant VM is running ==="
    cd "$VAGRANT_DIR"
    vm_status=$(vagrant status 2>&1 || true)
    if ! echo "$vm_status" | grep -q "running"; then
        if [ -n "$DISK_IMG" ] && [ "$USE_SNAPSHOT" = "1" ]; then
            restore_vanilla_snapshot || vagrant up --no-provision
        else
            echo "Starting Rocky Linux Vagrant VM..."
            vagrant up --no-provision
        fi
    fi

    sync_repo_to_guest

    _ssh_info=$(cd "$VAGRANT_DIR" && vagrant ssh-config 2>/dev/null || true)
    _port=$(echo "$_ssh_info" | awk '/Port / {print $2; exit}')
    _key=$(echo "$_ssh_info" | awk '/IdentityFile / {print $2; exit}')
    : "${_port:=50022}"
    : "${_key:=$HOME/.vagrant.d/insecure_private_keys/vagrant.key.ed25519}"

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
            BEGIN { in_bl=0; in_wl=0; has_wl=0; wl_match=0; in_abl=0; in_awl=0; has_awl=0; awl_match=0; result="yes" }
            /"os_blacklist"\s*:/ {
                in_bl=1; in_wl=0
                if ($0 ~ /"rhel"/ || $0 ~ /"rocky"/ || $0 ~ /"linux"/) { result="no"; exit }
                if ($0 ~ /\]/) { in_bl=0 }
                next
            }
            /"os_whitelist"\s*:/ {
                in_wl=1; in_bl=0; has_wl=1
                if ($0 ~ /"rhel"/ || $0 ~ /"rocky"/ || $0 ~ /"linux"/ || $0 ~ /"all"/) { wl_match=1 }
                if ($0 ~ /\]/) { in_wl=0 }
                next
            }
            /"arch_whitelist"\s*:/ {
                in_awl=1; in_bl=0; in_wl=0; in_abl=0; has_awl=1
                if ($0 ~ /"aarch64"/ || $0 ~ /"arm64"/ || $0 ~ /"all"/) { awl_match=1 }
                if ($0 ~ /\]/) { in_awl=0 }
                next
            }
            /"arch_blacklist"\s*:/ {
                in_abl=1; in_bl=0; in_wl=0; in_awl=0
                if ($0 ~ /"aarch64"/ || $0 ~ /"arm64"/) { result="no"; exit }
                if ($0 ~ /\]/) { in_abl=0 }
                next
            }
            in_bl {
                if ($0 ~ /"rhel"/ || $0 ~ /"rocky"/ || $0 ~ /"linux"/) { result="no"; exit }
                if ($0 ~ /\]/) { in_bl=0 }
            }
            in_wl {
                if ($0 ~ /"rhel"/ || $0 ~ /"rocky"/ || $0 ~ /"linux"/ || $0 ~ /"all"/) { wl_match=1 }
                if ($0 ~ /\]/) { in_wl=0 }
            }
            in_abl {
                if ($0 ~ /"aarch64"/ || $0 ~ /"arm64"/) { result="no"; exit }
                if ($0 ~ /\]/) { in_abl=0 }
            }
            in_awl {
                if ($0 ~ /"aarch64"/ || $0 ~ /"arm64"/ || $0 ~ /"all"/) { awl_match=1 }
                if ($0 ~ /\]/) { in_awl=0 }
            }
            END {
                if (result == "yes" && has_wl && !wl_match) { result="no" }
                if (result == "yes" && has_awl && !awl_match) { result="no" }
                print result
            }
            ' "$MANIFEST_PATH")
            if [ "$SUPPORTED" = "no" ]; then
                echo "Skipping $target (not supported on rocky / aarch64)"
                skipped_count=$((skipped_count + 1))
                update_component_in_readme "$target" "-"
                echo "Skipped: not supported on rocky / aarch64" > "$TESTS_TMP_DIR/$target.linux.rocky.skipped"
                echo "Skipped" > "$TESTS_TMP_DIR/$target.idempotent.success"
                continue
            fi
        fi

        echo "============================================================"
        echo "Running test for $target on Rocky Linux..."
        echo "============================================================"
        test_count=$((test_count + 1))

        # Restore vanilla snapshot before running if enabled
        if [ "$USE_SNAPSHOT" = "1" ]; then
            restore_vanilla_snapshot || true
            sync_repo_to_guest
        fi

        stdout_file="$TESTS_TMP_DIR/$target.linux.rocky.stdout"
        stderr_file="$TESTS_TMP_DIR/$target.linux.rocky.stderr"
        success_file="$TESTS_TMP_DIR/$target.linux.rocky.success"
        failure_file="$TESTS_TMP_DIR/$target.linux.rocky.failure"
        idempotent_file="$TESTS_TMP_DIR/$target.idempotent.success"

        rm -f "$success_file" "$failure_file" "$idempotent_file"

        # Execute test via ssh: install -> test -> install (idempotency) -> test (verification)
        test_cmd="export PATH=/usr/local/sbin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=/opt/repos/libscript; timeout 600 /opt/repos/libscript/libscript.sh install $target && timeout 120 /opt/repos/libscript/libscript.sh test $target && timeout 600 /opt/repos/libscript/libscript.sh install $target && timeout 120 /opt/repos/libscript/libscript.sh test $target"
        if ssh -n -p "$_port" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$_key" vagrant@127.0.0.1 "$test_cmd" > "$stdout_file" 2> "$stderr_file"; then
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
            cleanup_cmd="export LIBSCRIPT_ROOT_DIR=/opt/repos/libscript; /opt/repos/libscript/libscript.sh uninstall $target >/dev/null 2>&1 || true; rm -rf /home/vagrant/.libscript/$target /tmp/libscript_pkg_mgr_lock 2>/dev/null || true"
            ssh -p "$_port" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$_key" vagrant@127.0.0.1 "$cleanup_cmd" >/dev/null 2>&1 || true
        fi
    done

    if [ -x "$REPO_ROOT/tests/update_results.sh" ]; then
        "$REPO_ROOT/tests/update_results.sh" || true
    fi

    echo ""
    echo "============================================================"
    echo "Rocky Linux Tests Complete (Iteration $iteration)"
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
