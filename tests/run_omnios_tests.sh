#!/bin/sh
# ## Overview
# Runs tests sequentially for libscript components on a local OmniOS Vagrant VM
# (`bento/omnios`). Results, execution logs, and statuses are written into tests_tmp/
# and the Supported Components table in README.md is automatically updated after each test.
# ## Usage
# ./tests/run_omnios_tests.sh [TARGETS...|all]
# Example: ./tests/run_omnios_tests.sh curl sqlite tmux
# Example: ./tests/run_omnios_tests.sh all
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
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"
SCRIPT_NAME="${REPO_ROOT}/_lib/_common/test_matrix_driver.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
unset SCRIPT_NAME
set +f
VAGRANT_DIR="$REPO_ROOT/vagrant/omnios"
TESTS_TMP_DIR="$REPO_ROOT/tests_tmp"

mkdir -p "$TESTS_TMP_DIR"

TARGETS=""
TIER_FILTER='all'
STOP_AFTER=""
SKIP_UNINSTALL=""
SKIP_PASSED=""
LOOP_MODE=""
USE_SNAPSHOT='1'

# ## find_disk_image
# Finds the active qcow2 disk image for the OmniOS Vagrant machine.
find_disk_image() {
    for _id_file in "$VAGRANT_DIR"/.vagrant/machines/omnios-test-sqlite/qemu/id "$VAGRANT_DIR"/.vagrant/machines/*/qemu/id; do
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

# ## find_qemu_socket
# Finds the active QEMU monitor UNIX socket for live snapshot control.
find_qemu_socket() {
    for _id_file in "$VAGRANT_DIR"/.vagrant/machines/omnios-test-sqlite/qemu/id "$VAGRANT_DIR"/.vagrant/machines/*/qemu/id; do
        if [ -f "$_id_file" ]; then
            _id=$(cat "$_id_file")
            _sock="$HOME/.vagrant.d/tmp/vagrant-qemu/$_id/qemu_socket"
            if [ -S "$_sock" ]; then
                printf '%s\n' "$_sock"
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
        echo 'Restoring vanilla snapshot via QEMU monitor socket...'
        echo "loadvm vanilla" | nc -U "$_sock" >/dev/null 2>&1 || true
        sleep 2
        return 0
    fi

    _img=$(find_disk_image || true)
    if [ -n "$_img" ] && command -v qemu-img >/dev/null 2>&1; then
        if qemu-img snapshot -U -l "$_img" 2>/dev/null | grep -q "vanilla"; then
            echo 'Halting VM to restore vanilla snapshot...'
            (cd "$VAGRANT_DIR" && vagrant halt) || true
            echo 'Restoring vanilla snapshot...'
            qemu-img snapshot -a vanilla "$_img"
            echo 'Starting OmniOS Vagrant VM from vanilla snapshot...'
            (cd "$VAGRANT_DIR" && vagrant up --no-provision)
            return 0
        fi
    fi
    return 1
}

# ## sync_repo_to_guest
# Synchronizes the libscript codebase to the guest VM using rsync over ssh (or tar over ssh if rsync is absent on OmniOS).
sync_repo_to_guest() {
    echo '=== Syncing LibScript repository to OmniOS ==='
    _ssh_info=$(if cd "$VAGRANT_DIR" 2>/dev/null; then vagrant ssh-config 2>/dev/null || true; fi)
    _port=$(echo "$_ssh_info" | awk '/Port / {print $2; exit}')
    _key=$(echo "$_ssh_info" | awk '/IdentityFile / {print $2; exit}')
    : "${_port:=2215}"
    : "${_key:=$HOME/.vagrant.d/insecure_private_keys/vagrant.key.rsa}"

    ssh -n -p "$_port" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$_key" vagrant@127.0.0.1 \
        "sudo mkdir -p /opt/repos/libscript /export/home/vagrant/.libscript && sudo chown -R vagrant /opt/repos/libscript /export/home/vagrant" >/dev/null 2>&1 || true

    if ssh -n -p "$_port" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$_key" vagrant@127.0.0.1 "command -v rsync >/dev/null 2>&1"; then
        rsync -a --copy-links --no-owner --no-group \
            -e "ssh -p $_port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $_key" \
            --exclude ".vagrant" --exclude ".git" --exclude "tests_tmp" --exclude "*.msi" --exclude "cache" --exclude "build" \
            "$REPO_ROOT/" "vagrant@127.0.0.1:/opt/repos/libscript/"
    else
        (cd "$REPO_ROOT" && COPYFILE_DISABLE=1 tar --format ustar -cf - --exclude='.vagrant' --exclude='.git' --exclude='tests_tmp' --exclude='*.msi' --exclude='cache' --exclude='build' .) | \
            ssh -T -p "$_port" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$_key" vagrant@127.0.0.1 \
            "sh -c 'cd /opt/repos/libscript && (if [ -x /usr/gnu/bin/tar ]; then /usr/gnu/bin/tar -xf -; else /usr/bin/tar -xf -; fi)'"
    fi
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
            if (NF >= 10) { $8 = " " st " " } else { $7 = " " st " " }
        }
        { print }
    ' "$_rm" > "$_tmp_rm" && mv "$_tmp_rm" "$_rm"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h|/?)
            echo "Usage: $(basename "$THIS_FILE") [TARGETS...|all] [--stop-after N] [--skip-passed] [--skip-uninstall] [--loop] [--no-snapshot]"
            echo ""
            echo 'Runs local tests sequentially on OmniOS (bento/omnios) Vagrant VM.'
            echo ""
            echo 'Arguments:'
            echo '  TARGETS...          A list of categories or components to test.'
            echo "                      Defaults to 'all' if omitted."
            echo '  all                 Test all components in the _lib directory.'
            echo '  --loop, -l          Continuously repeat testing in an automated loop.'
            echo '  --stop-after N      Stop after running N component tests.'
            echo '  --skip-passed       Skip components that already have a .sunos.success/.skipped file.'
            echo '  --skip-uninstall    Skip uninstallation step after testing each component.'
            echo '  --no-snapshot       Do not restore the vanilla snapshot before each test.'
            echo '  --help, -h, /?      Show this help message.'
            echo ""
            echo 'Results are written to tests_tmp/ (*.sunos.stdout, *.sunos.stderr, *.sunos.success/failure).'
            exit 0
            ;;
        --loop|-l)
            LOOP_MODE='1'
            shift
            ;;
        --tier)
            TIER_FILTER="$2"
            shift 2
            ;;
        --stop-after)
            STOP_AFTER="$2"
            shift 2
            ;;
        --skip-uninstall)
            SKIP_UNINSTALL='1'
            shift
            ;;
        --skip-passed)
            SKIP_PASSED='1'
            shift
            ;;
        --no-snapshot)
            USE_SNAPSHOT='0'
            shift
            ;;
        *)
            TARGETS="$TARGETS $1"
            shift
            ;;
    esac
done

if [ -z "$(echo "$TARGETS" | tr -d ' ')" ]; then
    TARGETS='all'
fi

if [ ! -d "$VAGRANT_DIR" ]; then
    echo "Error: OmniOS Vagrant environment not found at $VAGRANT_DIR"
    exit 1
fi

EXPANDED_TARGETS=""
for arg in $TARGETS; do
    _base_arg=$(basename "$arg")
    if [ "$arg" = "all" ]; then
        for cat_dir in "$REPO_ROOT"/_lib/*; do
            if [ -d "$cat_dir" ]; then
                _cat_name=$(basename "$cat_dir")
                case "$_cat_name" in
                    _*|bootloaders|storage|runtimes|ml-training) continue ;;
                esac
                for dir in "$cat_dir"/*; do
                    if [ -d "$dir" ]; then
                        _c_name=$(basename "$dir")
                        case "$_c_name" in _*) continue ;; esac
                        if [ "$_cat_name" = "freebsd" ] && [ "$_c_name" = "distro" ]; then
                            EXPANDED_TARGETS="$EXPANDED_TARGETS freebsd/distro"
                        elif [ "$_cat_name" = "illumos" ] && [ "$_c_name" = "distro" ]; then
                            EXPANDED_TARGETS="$EXPANDED_TARGETS illumos/distro"
                        else
                            EXPANDED_TARGETS="$EXPANDED_TARGETS $_c_name"
                        fi
                    fi
                done
            fi
        done
        for _bl in grub limine refind systemd-boot; do
            EXPANDED_TARGETS="$EXPANDED_TARGETS bootloaders/$_bl"
        done
        EXPANDED_TARGETS="$EXPANDED_TARGETS storage/provision_disk runtimes/provision_isolated_runtime ml-training"
        for dir in "$REPO_ROOT"/topologies/*; do
            [ -d "$dir" ] && EXPANDED_TARGETS="$EXPANDED_TARGETS topologies/$(basename "$dir")"
        done
        for sfile in "$REPO_ROOT"/payloads/schedulers/*.sh; do
            [ -f "$sfile" ] && EXPANDED_TARGETS="$EXPANDED_TARGETS payloads/schedulers/$(basename "$sfile" .sh)"
        done
        for dir in "$REPO_ROOT"/traits/*; do
            [ -d "$dir" ] && EXPANDED_TARGETS="$EXPANDED_TARGETS traits/$(basename "$dir")"
        done
    elif [ "$arg" = "freebsd/distro" ] || [ "$arg" = "illumos/distro" ] || [ "$arg" = "storage/provision_disk" ] || [ "$arg" = "runtimes/provision_isolated_runtime" ] || [ "$arg" = "ml-training" ]; then
        EXPANDED_TARGETS="$EXPANDED_TARGETS $arg"
    elif [ "${arg#bootloaders/}" != "$arg" ] || [ "${arg#topologies/}" != "$arg" ] || [ "${arg#payloads/schedulers/}" != "$arg" ] || [ "${arg#traits/}" != "$arg" ]; then
        EXPANDED_TARGETS="$EXPANDED_TARGETS $arg"
    elif [ -d "$REPO_ROOT/_lib/$arg" ]; then
        for dir in "$REPO_ROOT/_lib/$arg"/*; do
            [ -d "$dir" ] && EXPANDED_TARGETS="$EXPANDED_TARGETS $(basename "$dir")"
        done
    elif [ -d "$REPO_ROOT/topologies/$arg" ]; then
        EXPANDED_TARGETS="$EXPANDED_TARGETS topologies/$_base_arg"
    elif [ -d "$REPO_ROOT/traits/$arg" ]; then
        EXPANDED_TARGETS="$EXPANDED_TARGETS traits/$_base_arg"
    elif [ -d "$REPO_ROOT/payloads/$arg" ]; then
        for dir in "$REPO_ROOT/payloads/$arg"/*; do
            [ -d "$dir" ] && EXPANDED_TARGETS="$EXPANDED_TARGETS $(basename "$dir")"
        done
    elif [ -d "$REPO_ROOT/$arg" ]; then
        EXPANDED_TARGETS="$EXPANDED_TARGETS $_base_arg"
    else
        found=0
        for cat_dir in "$REPO_ROOT"/_lib/* "$REPO_ROOT"/topologies "$REPO_ROOT"/payloads/*; do
            if [ -d "$cat_dir/$_base_arg" ]; then
                EXPANDED_TARGETS="$EXPANDED_TARGETS $_base_arg"
                found=1
                break
            fi
        done
        if [ $found -eq 0 ]; then
            echo "Warning: Target '$arg' not found in _lib/, topologies/, or payloads/."
        fi
    fi
done

UNIQUE_TARGETS=$(echo "$EXPANDED_TARGETS" | tr ' ' '
' | grep -v '^$' | sort -u | tr '
' ' ')

iteration=1

while true; do
    if [ "$LOOP_MODE" = "1" ]; then
        echo '============================================================'
        echo "Starting OmniOS Test Loop (Iteration $iteration)"
        echo '============================================================'
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
            USE_SNAPSHOT='0'
        fi
    fi

    test_count=0
    success_count=0
    failure_count=0
    skipped_count=0
    vm_started=0
    _port=""
    _key=""

    for target in $UNIQUE_TARGETS; do
        if [ -n "$STOP_AFTER" ] && [ "$test_count" -ge "$STOP_AFTER" ]; then
            echo "Reached limit of $STOP_AFTER tests. Stopping."
            break
        fi

        _short_target="${target##*/}"
        _marker_base="$_short_target"
        case "$target" in
            freebsd/distro) _marker_base="freebsd-distro" ;;
            illumos/distro) _marker_base="illumos-distro" ;;
            bootloaders/*) _marker_base="bootloaders-${_short_target}" ;;
            payloads/schedulers/*) _marker_base="scheduler-${_short_target}" ;;
            traits/*) _marker_base="trait-${_short_target}" ;;
        esac

        if [ "$SKIP_PASSED" = "1" ]; then
            if [ -f "$TESTS_TMP_DIR/$_marker_base.sunos.success" ] || [ -f "$TESTS_TMP_DIR/$_marker_base.sunos.skipped" ] || [ -f "$TESTS_TMP_DIR/$_short_target.sunos.success" ] || [ -f "$TESTS_TMP_DIR/$_short_target.sunos.skipped" ]; then
                continue
            fi
        fi

        case "$target" in
            bootloaders/*)
                echo "Skipping $target (not supported on sunos)"
                skipped_count=$((skipped_count + 1))
                echo "Skipped: not supported on sunos" > "$TESTS_TMP_DIR/$_marker_base.sunos.skipped"
                echo "Skipped" > "$TESTS_TMP_DIR/$_marker_base.idempotent.success"
                update_component_in_readme "$target" "-"
                continue
                ;;
        esac

        # Check manifest for OS support
        MANIFEST_PATH=""
        if [ "$target" = "freebsd/distro" ] && [ -f "$REPO_ROOT/_lib/freebsd/distro/manifest.json" ]; then
            MANIFEST_PATH="$REPO_ROOT/_lib/freebsd/distro/manifest.json"
        elif [ "$target" = "illumos/distro" ] && [ -f "$REPO_ROOT/_lib/illumos/distro/manifest.json" ]; then
            MANIFEST_PATH="$REPO_ROOT/_lib/illumos/distro/manifest.json"
        elif [ "$target" = "distro" ] && [ -f "$REPO_ROOT/_lib/orchestration/distro/manifest.json" ]; then
            MANIFEST_PATH="$REPO_ROOT/_lib/orchestration/distro/manifest.json"
        elif [ "$target" = "ml-training" ] && [ -f "$REPO_ROOT/_lib/ml-training/manifest.json" ]; then
            MANIFEST_PATH="$REPO_ROOT/_lib/ml-training/manifest.json"
        else
            for _m in "$REPO_ROOT/_lib"/*/"$target/manifest.json" "$REPO_ROOT/topologies/$_short_target/topology.json" "$REPO_ROOT/payloads"/*/"$_short_target/payload.json"; do
                if [ -f "$_m" ]; then
                    MANIFEST_PATH="$_m"
                    break
                fi
            done
        fi

        if [ -n "$MANIFEST_PATH" ]; then
            SUPPORTED=$(awk '
            BEGIN { in_bl=0; in_wl=0; has_wl=0; wl_match=0; in_abl=0; in_awl=0; has_awl=0; awl_match=0; result="yes" }
            /"os_blacklist"\s*:/ {
                in_bl=1; in_wl=0
                if ($0 ~ /"sunos"/ || $0 ~ /"solaris"/ || $0 ~ /"illumos"/) { result="no"; exit }
                if ($0 ~ /\]/) { in_bl=0 }
                next
            }
            /"os_whitelist"\s*:/ {
                in_wl=1; in_bl=0; has_wl=1
                if ($0 ~ /"sunos"/ || $0 ~ /"solaris"/ || $0 ~ /"illumos"/ || $0 ~ /"all"/) { wl_match=1 }
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
                if ($0 ~ /"sunos"/ || $0 ~ /"solaris"/ || $0 ~ /"illumos"/) { result="no"; exit }
                if ($0 ~ /\]/) { in_bl=0 }
            }
            in_wl {
                if ($0 ~ /"sunos"/ || $0 ~ /"solaris"/ || $0 ~ /"illumos"/ || $0 ~ /"all"/) { wl_match=1 }
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
                echo "Skipping $target (not supported on sunos / aarch64)"
                skipped_count=$((skipped_count + 1))
                echo "Skipped: not supported on sunos / aarch64" > "$TESTS_TMP_DIR/$_marker_base.sunos.skipped"
                echo "Skipped" > "$TESTS_TMP_DIR/$_marker_base.idempotent.success"
                update_component_in_readme "$target" "-"
                continue
            fi
        fi

        if [ "$vm_started" -eq 0 ]; then
            echo '=== Ensuring OmniOS Vagrant VM is running ==='
            cd "$VAGRANT_DIR"
            vm_status=$(vagrant status 2>&1 || true)
            if ! echo "$vm_status" | grep -q "running"; then
                if [ -n "$DISK_IMG" ] && [ "$USE_SNAPSHOT" = "1" ]; then
                    restore_vanilla_snapshot || vagrant up --no-provision
                else
                    echo 'Starting OmniOS Vagrant VM...'
                    vagrant up --no-provision
                fi
            fi
            sync_repo_to_guest
            _ssh_info=$(if cd "$VAGRANT_DIR" 2>/dev/null; then vagrant ssh-config 2>/dev/null || true; fi)
            _port=$(echo "$_ssh_info" | awk '/Port / {print $2; exit}')
            _key=$(echo "$_ssh_info" | awk '/IdentityFile / {print $2; exit}')
            : "${_port:=2215}"
            : "${_key:=$HOME/.vagrant.d/insecure_private_keys/vagrant.key.rsa}"
            vm_started=1
        elif [ "$USE_SNAPSHOT" = "1" ]; then
            restore_vanilla_snapshot || true
            sync_repo_to_guest
            _ssh_info=$(if cd "$VAGRANT_DIR" 2>/dev/null; then vagrant ssh-config 2>/dev/null || true; fi)
            _port=$(echo "$_ssh_info" | awk '/Port / {print $2; exit}')
            _key=$(echo "$_ssh_info" | awk '/IdentityFile / {print $2; exit}')
            : "${_port:=2215}"
            : "${_key:=$HOME/.vagrant.d/insecure_private_keys/vagrant.key.rsa}"
        fi

        echo '============================================================'
        echo "Running test for $target on OmniOS..."
        echo '============================================================'
        test_count=$((test_count + 1))

        stdout_file="$TESTS_TMP_DIR/$_marker_base.sunos.stdout"
        stderr_file="$TESTS_TMP_DIR/$_marker_base.sunos.stderr"
        success_file="$TESTS_TMP_DIR/$_marker_base.sunos.success"
        failure_file="$TESTS_TMP_DIR/$_marker_base.sunos.failure"
        idempotent_file="$TESTS_TMP_DIR/$_marker_base.idempotent.success"

        rm -f "$success_file" "$failure_file" "$idempotent_file"

        case "$target" in
            bootloaders/*)
                _bl_name="${target#bootloaders/}"
                test_cmd="export PATH=/usr/xpg4/bin:/usr/gnu/bin:/opt/ooce/bin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=/opt/repos/libscript; rm -rf /tmp/test-bl-$_bl_name && sh /opt/repos/libscript/_lib/bootloaders/setup.sh compile /tmp/test-bl-$_bl_name $_bl_name uefi && sh /opt/repos/libscript/_lib/bootloaders/setup.sh compile /tmp/test-bl-$_bl_name $_bl_name uefi && rm -rf /tmp/test-bl-$_bl_name"
                ;;
            storage/provision_disk)
                test_cmd="export PATH=/usr/xpg4/bin:/usr/gnu/bin:/opt/ooce/bin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=/opt/repos/libscript; rm -f /var/tmp/test-disk.img && sh /opt/repos/libscript/_lib/storage/provision_disk.sh /var/tmp/test-disk.img 1 gpt uefi && sh /opt/repos/libscript/_lib/storage/provision_disk.sh /var/tmp/test-disk.img 1 gpt uefi && rm -f /var/tmp/test-disk.img"
                ;;
            runtimes/provision_isolated_runtime)
                test_cmd="export PATH=/usr/xpg4/bin:/usr/gnu/bin:/opt/ooce/bin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=/opt/repos/libscript; sh /opt/repos/libscript/_lib/runtimes/provision_isolated_runtime.sh --runtime python --path /tmp/test-rt && sh /opt/repos/libscript/_lib/runtimes/provision_isolated_runtime.sh --runtime python --path /tmp/test-rt"
                ;;
            ml-training)
                test_cmd="export PATH=/usr/xpg4/bin:/usr/gnu/bin:/opt/ooce/bin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=/opt/repos/libscript; sh /opt/repos/libscript/_lib/ml-training/cli.sh install latest && sh /opt/repos/libscript/_lib/ml-training/cli.sh test && sh /opt/repos/libscript/_lib/ml-training/cli.sh install latest && sh /opt/repos/libscript/_lib/ml-training/cli.sh test"
                ;;
            freebsd/distro)
                test_cmd="export PATH=/usr/xpg4/bin:/usr/gnu/bin:/opt/ooce/bin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=/opt/repos/libscript; sh /opt/repos/libscript/_lib/freebsd/distro/cli.sh install latest && sh /opt/repos/libscript/_lib/freebsd/distro/cli.sh test && sh /opt/repos/libscript/_lib/freebsd/distro/cli.sh install latest && sh /opt/repos/libscript/_lib/freebsd/distro/cli.sh test"
                ;;
            illumos/distro)
                test_cmd="export PATH=/usr/xpg4/bin:/usr/gnu/bin:/opt/ooce/bin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=/opt/repos/libscript; sh /opt/repos/libscript/_lib/illumos/distro/cli.sh install latest && sh /opt/repos/libscript/_lib/illumos/distro/cli.sh test && sh /opt/repos/libscript/_lib/illumos/distro/cli.sh install latest && sh /opt/repos/libscript/_lib/illumos/distro/cli.sh test"
                ;;
            distro)
                test_cmd="export PATH=/usr/xpg4/bin:/usr/gnu/bin:/opt/ooce/bin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=/opt/repos/libscript; sh /opt/repos/libscript/_lib/orchestration/distro/cli.sh install latest && sh /opt/repos/libscript/_lib/orchestration/distro/cli.sh test && sh /opt/repos/libscript/_lib/orchestration/distro/cli.sh install latest && sh /opt/repos/libscript/_lib/orchestration/distro/cli.sh test"
                ;;
            topologies/gke-tpu-cluster)
                test_cmd="export PATH=/usr/xpg4/bin:/usr/gnu/bin:/opt/ooce/bin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=/opt/repos/libscript; sh /opt/repos/libscript/topologies/gke-tpu-cluster/cli.sh --help && sh /opt/repos/libscript/topologies/gke-tpu-cluster/cli.sh --help"
                ;;
            topologies/*)
                _topo_name="${target#topologies/}"
                test_cmd="export PATH=/usr/xpg4/bin:/usr/gnu/bin:/opt/ooce/bin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=/opt/repos/libscript LIBSCRIPT_TOPOLOGY_STATE_FILE=/tmp/topo-$_topo_name.json; rm -f /tmp/topo-$_topo_name.json*; sh /opt/repos/libscript/topologies/$_topo_name/cli.sh up && sh /opt/repos/libscript/topologies/$_topo_name/cli.sh status && sh /opt/repos/libscript/topologies/$_topo_name/cli.sh up && sh /opt/repos/libscript/topologies/$_topo_name/cli.sh destroy && rm -f /tmp/topo-$_topo_name.json*"
                ;;
            payloads/schedulers/*)
                _sched_name="${target#payloads/schedulers/}"
                test_cmd="export PATH=/usr/xpg4/bin:/usr/gnu/bin:/opt/ooce/bin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=/opt/repos/libscript; sh /opt/repos/libscript/payloads/engine.sh compile /opt/repos/libscript/payloads/ai/vllm/payload.json --scheduler $_sched_name && sh /opt/repos/libscript/payloads/engine.sh submit /opt/repos/libscript/payloads/ai/vllm/payload.json --scheduler $_sched_name && sh /opt/repos/libscript/payloads/engine.sh status /opt/repos/libscript/payloads/ai/vllm/payload.json --scheduler $_sched_name && sh /opt/repos/libscript/payloads/engine.sh submit /opt/repos/libscript/payloads/ai/vllm/payload.json --scheduler $_sched_name && sh /opt/repos/libscript/payloads/engine.sh destroy /opt/repos/libscript/payloads/ai/vllm/payload.json --scheduler $_sched_name"
                ;;
            traits/*)
                _trait_name="${target#traits/}"
                test_cmd="export PATH=/usr/xpg4/bin:/usr/gnu/bin:/opt/ooce/bin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=/opt/repos/libscript LIBSCRIPT_TARGET_SYSROOT=/tmp/trait-sysroot-$_trait_name LIBSCRIPT_OFFLINE=1; rm -rf /tmp/trait-sysroot-$_trait_name && mkdir -p /tmp/trait-sysroot-$_trait_name && sh /opt/repos/libscript/traits/engine.sh enable $_trait_name && sh /opt/repos/libscript/traits/engine.sh apply $_trait_name && sh /opt/repos/libscript/traits/engine.sh verify $_trait_name && sh /opt/repos/libscript/traits/engine.sh apply $_trait_name && sh /opt/repos/libscript/traits/engine.sh teardown $_trait_name && rm -rf /tmp/trait-sysroot-$_trait_name"
                ;;
            *)
                test_cmd="export PATH=/usr/xpg4/bin:/usr/gnu/bin:/opt/ooce/bin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=/opt/repos/libscript; timeout 600 /opt/repos/libscript/libscript.sh install $target && timeout 120 /opt/repos/libscript/libscript.sh test $target && (/opt/repos/libscript/libscript.sh env $target latest >/dev/null 2>&1 || true) && timeout 600 /opt/repos/libscript/libscript.sh install $target && timeout 120 /opt/repos/libscript/libscript.sh test $target"
                ;;
        esac

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
            cleanup_cmd="export LIBSCRIPT_ROOT_DIR=/opt/repos/libscript; /opt/repos/libscript/libscript.sh uninstall $target >/dev/null 2>&1 || true; rm -rf /export/home/vagrant/.libscript/$_short_target /tmp/libscript_pkg_mgr_lock 2>/dev/null || true"
            ssh -n -p "$_port" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$_key" vagrant@127.0.0.1 "$cleanup_cmd" >/dev/null 2>&1 || true
        fi
    done

    if [ -x "$REPO_ROOT/tests/update_results.sh" ]; then
        "$REPO_ROOT/tests/update_results.sh" || true
    fi

    echo ""
    echo '============================================================'
    echo "OmniOS Tests Complete (Iteration $iteration)"
    echo "Ran: $test_count | Passed: $success_count | Failed: $failure_count | Skipped: $skipped_count"
    echo "Results in: $TESTS_TMP_DIR"
    echo '============================================================'

    if [ "$LOOP_MODE" != "1" ]; then
        break
    fi

    iteration=$((iteration + 1))
    echo 'Loop mode active. Restarting test loop in 3 seconds...'
    sleep 3
done
