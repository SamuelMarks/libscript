#!/bin/sh
# ## Overview
# Runs tests sequentially for libscript components on macOS (Darwin). Supports testing via a local macOS Vagrant VM (`bento/macos-27.2-arm64` / `bento/macos-14-arm64`) using UTM snapshot restoration (snapshot vanilla; run process; check result; restore snapshot; repeat) or direct native execution on macOS hosts. Results, execution logs, and statuses are written into tests_tmp/ and the Supported Components table in README.md is updated after each test.
# ## Usage
# ./tests/run_macos_tests.sh [TARGETS...|all] [--tier T] [--loop] [--stop-after N] [--skip-passed] [--skip-uninstall] [--no-snapshot] [--native]
# Example: ./tests/run_macos_tests.sh curl sqlite tmux
# Example: ./tests/run_macos_tests.sh all
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
SCRIPT_NAME="${REPO_ROOT}/_lib/_common/test_matrix_driver.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
unset SCRIPT_NAME
set +f
VAGRANT_DIR="$REPO_ROOT/vagrant/macos-14-arm64"
TESTS_TMP_DIR="$REPO_ROOT/tests_tmp"

mkdir -p "$TESTS_TMP_DIR"

TARGETS=""
TIER_FILTER='all'
STOP_AFTER=""
SKIP_UNINSTALL=""
SKIP_PASSED=""
LOOP_MODE=""
USE_SNAPSHOT='1'
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
    echo 'Restoring macOS vanilla snapshot...'
    if [ -d "$VAGRANT_DIR" ]; then
        if (cd "$VAGRANT_DIR" && vagrant snapshot restore vanilla --no-provision 2>/dev/null); then
            echo 'Successfully restored vanilla snapshot via Vagrant.'
            return 0
        fi
    fi
    _vm_name=$(find_utm_vm_name || true)
    if [ -n "$_vm_name" ]; then
        _utmctl='utmctl'
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
    echo 'Creating vanilla snapshot for macOS VM...'
    if [ -d "$VAGRANT_DIR" ]; then
        if (cd "$VAGRANT_DIR" && vagrant snapshot save vanilla 2>/dev/null); then
            echo 'Successfully saved vanilla snapshot.'
            return 0
        fi
    fi
    _vm_name=$(find_utm_vm_name || true)
    if [ -n "$_vm_name" ]; then
        _utmctl='utmctl'
        [ ! -x "$(command -v utmctl 2>/dev/null)" ] && [ -x "/Applications/UTM.app/Contents/MacOS/utmctl" ] && _utmctl="/Applications/UTM.app/Contents/MacOS/utmctl"
        "$_utmctl" clone "$_vm_name" --name "${_vm_name}-snapshot-vanilla" 2>/dev/null || true
        return 0
    fi
    return 1
}

# ## sync_repo_to_guest
# Synchronizes the libscript codebase to the macOS Vagrant VM.
sync_repo_to_guest() {
    echo '=== Syncing LibScript repository to macOS Vagrant VM ==='
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
            if (NF >= 10) { $10 = " " st " " } else { $9 = " " st " " }
        }
        { print }
    ' "$_rm" > "$_tmp_rm" && mv "$_tmp_rm" "$_rm"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h|/?)
            echo "Usage: $(basename "$THIS_FILE") [TARGETS...|all] [--tier T] [--stop-after N] [--skip-passed] [--skip-uninstall] [--loop] [--no-snapshot] [--native]"
            echo ""
            echo 'Runs local tests sequentially on macOS (Darwin).'
            echo ""
            echo 'Arguments:'
            echo '  TARGETS...          A list of categories or components to test.'
            echo "                      Defaults to 'all' if omitted."
            echo '  all                 Test all components across all 5 architectural tiers.'
            echo '  --tier T            Filter components by architectural tier (1, 1.5, 2, 3, 4, all).'
            echo '  --loop, -l          Continuously repeat testing in an automated loop.'
            echo '  --stop-after N      Stop after running N component tests.'
            echo '  --skip-passed       Skip components that already have a .darwin.success/.skipped file.'
            echo '  --skip-uninstall    Skip uninstallation step after testing each component.'
            echo '  --no-snapshot       Do not restore the vanilla snapshot before each test.'
            echo '  --native            Execute tests natively on the current macOS host.'
            echo '  --help, -h, /?      Show this help message.'
            echo ""
            echo 'Results are written to tests_tmp/ (*.darwin.stdout, *.darwin.stderr, *.darwin.success/failure/skipped).'
            exit 0
            ;;
        --loop|-l)
            LOOP_MODE='1'
            shift
            ;;
        --tier)
            TIER_FILTER="$2"
            export TIER_FILTER
            shift 2
            ;;
        --stop-after)
            STOP_AFTER="$2"
            shift 2
            ;;
        --skip-passed)
            SKIP_PASSED='1'
            shift
            ;;
        --skip-uninstall)
            SKIP_UNINSTALL='1'
            shift
            ;;
        --no-snapshot)
            USE_SNAPSHOT='0'
            shift
            ;;
        --native)
            USE_NATIVE='1'
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
    elif [ "$arg" = "orchestration/cloud" ] || [ "$arg" = "cloud" ]; then
        EXPANDED_TARGETS="$EXPANDED_TARGETS cloud"
    elif [ "${arg#bootloaders/}" != "$arg" ] || [ "${arg#topologies/}" != "$arg" ] || [ "${arg#payloads/schedulers/}" != "$arg" ] || [ "${arg#traits/}" != "$arg" ]; then
        EXPANDED_TARGETS="$EXPANDED_TARGETS $arg"
    elif [ -f "$REPO_ROOT/_lib/$arg/manifest.json" ] || [ -f "$REPO_ROOT/_lib/$arg/cli.sh" ]; then
        EXPANDED_TARGETS="$EXPANDED_TARGETS $_base_arg"
    elif [ -f "$REPO_ROOT/topologies/$arg/topology.json" ] || [ -f "$REPO_ROOT/topologies/$arg/cli.sh" ]; then
        EXPANDED_TARGETS="$EXPANDED_TARGETS topologies/$_base_arg"
    elif [ -d "$REPO_ROOT/_lib/$arg" ] && [ ! -f "$REPO_ROOT/_lib/$arg/manifest.json" ]; then
        for dir in "$REPO_ROOT/_lib/$arg"/*; do
            [ -d "$dir" ] && EXPANDED_TARGETS="$EXPANDED_TARGETS $(basename "$dir")"
        done
    elif [ -d "$REPO_ROOT/topologies/$arg" ]; then
        EXPANDED_TARGETS="$EXPANDED_TARGETS topologies/$_base_arg"
    elif [ -d "$REPO_ROOT/traits/$arg" ]; then
        EXPANDED_TARGETS="$EXPANDED_TARGETS traits/$_base_arg"
    elif [ -d "$REPO_ROOT/payloads/$arg" ] && [ ! -f "$REPO_ROOT/payloads/$arg/payload.json" ]; then
        for dir in "$REPO_ROOT/payloads/$arg"/*; do
            [ -d "$dir" ] && EXPANDED_TARGETS="$EXPANDED_TARGETS $(basename "$dir")"
        done
    elif [ -d "$REPO_ROOT/$arg" ]; then
        EXPANDED_TARGETS="$EXPANDED_TARGETS $_base_arg"
    else
        found=0
        for cat_dir in "$REPO_ROOT"/_lib/* "$REPO_ROOT"/topologies "$REPO_ROOT"/payloads/*; do
            if [ -d "$cat_dir/$_base_arg" ] && { [ -f "$cat_dir/$_base_arg/manifest.json" ] || [ -f "$cat_dir/$_base_arg/cli.sh" ] || [ -f "$cat_dir/$_base_arg/topology.json" ] || [ -f "$cat_dir/$_base_arg/payload.json" ]; }; then
                EXPANDED_TARGETS="$EXPANDED_TARGETS $_base_arg"
                found=1
                break
            fi
        done
        if [ $found -eq 0 ]; then
            echo "Warning: Target '$arg' not found in _lib/, topologies/, traits/, or payloads/."
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
        echo "Starting macOS Test Loop (Iteration $iteration)"
        echo '============================================================'
    fi

    # Determine execution mode: Vagrant VM vs Native macOS
    VAGRANT_ACTIVE=0
    if [ "$USE_NATIVE" != "1" ] && [ -d "$VAGRANT_DIR/.vagrant/machines" ]; then
        _has_vm_id=0
        for _vf in "$VAGRANT_DIR"/.vagrant/machines/*/*/id; do
            if [ -f "$_vf" ]; then
                _has_vm_id=1
                break
            fi
        done
        if [ "$_has_vm_id" -eq 1 ]; then
            cd "$VAGRANT_DIR"
            vm_status=$(env VAGRANT_DEFAULT_PROVIDER=utm vagrant status 2>&1 || true)
            if echo "$vm_status" | grep -q "running"; then
                VAGRANT_ACTIVE=1
            fi
            cd "$REPO_ROOT"
        fi
    fi

    if [ "$VAGRANT_ACTIVE" = "1" ]; then
        echo '=== Connected to macOS Vagrant VM ==='
        if [ "$USE_SNAPSHOT" = "1" ]; then
            restore_vanilla_snapshot || true
        fi
        sync_repo_to_guest
        _ssh_info=$(if cd "$VAGRANT_DIR" 2>/dev/null; then vagrant ssh-config 2>/dev/null || true; fi)
        _port=$(echo "$_ssh_info" | awk '/Port / {print $2; exit}')
        _key=$(echo "$_ssh_info" | awk '/IdentityFile / {print $2; exit}')
        : "${_port:=22}"
        : "${_key:=$HOME/.vagrant.d/insecure_private_key}"
    else
        echo '=== Running tests natively on macOS host ==='
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

        _short_target="${target##*/}"
        _marker_base="$_short_target"
        case "$target" in
            freebsd/distro) _marker_base='freebsd-distro' ;;
            illumos/distro) _marker_base='illumos-distro' ;;
            bootloaders/*) _marker_base="bootloaders-${_short_target}" ;;
            payloads/schedulers/*) _marker_base="scheduler-${_short_target}" ;;
            traits/*) _marker_base="trait-${_short_target}" ;;
        esac

        if [ "$SKIP_PASSED" = "1" ]; then
            if [ -f "$TESTS_TMP_DIR/$_marker_base.darwin.success" ] || [ -f "$TESTS_TMP_DIR/$_marker_base.darwin.skipped" ] || [ -f "$TESTS_TMP_DIR/$_marker_base.darwin.unsupported" ]; then
                continue
            fi
        fi

        # Bootloaders are Linux/FreeBSD image synthesizers and unsupported on macOS
        case "$target" in
            bootloaders/*)
                echo "Skipping $target (not supported on macOS / darwin)"
                skipped_count=$((skipped_count + 1))
                echo "Skipped: not supported on darwin / aarch64" > "$TESTS_TMP_DIR/$_marker_base.darwin.skipped"
                echo "Skipped" > "$TESTS_TMP_DIR/$_marker_base.idempotent.success"
                update_component_in_readme "$target" "-"
                continue
                ;;
        esac

        # Check manifest for macOS support
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
                if ($0 ~ /"darwin"/ || $0 ~ /"macos"/) { result="no"; exit }
                if ($0 ~ /\]/) { in_bl=0 }
            }
            in_wl {
                if ($0 ~ /"darwin"/ || $0 ~ /"macos"/ || $0 ~ /"all"/) { wl_match=1 }
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
                echo "Skipping $target (not supported on macOS / aarch64)"
                skipped_count=$((skipped_count + 1))
                echo "Skipped: not supported on darwin / aarch64" > "$TESTS_TMP_DIR/$_marker_base.darwin.skipped"
                echo "Unsupported" > "$TESTS_TMP_DIR/$_marker_base.darwin.unsupported"
                echo "Skipped" > "$TESTS_TMP_DIR/$_marker_base.idempotent.success"
                update_component_in_readme "$target" "-"
                continue
            fi
        fi

        echo '============================================================'
        echo "Running test for $target on macOS..."
        echo '============================================================'
        test_count=$((test_count + 1))

        # Restore vanilla snapshot before running if enabled and in Vagrant mode
        if [ "$VAGRANT_ACTIVE" = "1" ] && [ "$USE_SNAPSHOT" = "1" ] && [ "$test_count" -gt 1 ]; then
            restore_vanilla_snapshot || true
            sync_repo_to_guest
        fi

        stdout_file="$TESTS_TMP_DIR/$_marker_base.darwin.stdout"
        stderr_file="$TESTS_TMP_DIR/$_marker_base.darwin.stderr"
        success_file="$TESTS_TMP_DIR/$_marker_base.darwin.success"
        failure_file="$TESTS_TMP_DIR/$_marker_base.darwin.failure"
        idempotent_file="$TESTS_TMP_DIR/$_marker_base.idempotent.success"

        rm -f "$success_file" "$failure_file" "$idempotent_file"

        if [ "$VAGRANT_ACTIVE" = "1" ]; then
            _exec_root='/Users/vagrant/libscript'
        else
            _exec_root="$REPO_ROOT"
        fi

        _t_inst=""
        _t_test=""
        if command -v timeout >/dev/null 2>&1; then
            _t_inst='timeout 180'
            _t_test='timeout 90'
        fi

        _rtmp="${REMOTE_TMPDIR:-${TMPDIR:-/tmp}}"
        case "$target" in
            storage/provision_disk)
                test_cmd="export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=$_exec_root; rm -f ${_rtmp}/test-disk.img && sh $_exec_root/_lib/storage/provision_disk.sh ${_rtmp}/test-disk.img 1 gpt uefi && sh $_exec_root/_lib/storage/provision_disk.sh ${_rtmp}/test-disk.img 1 gpt uefi && rm -f ${_rtmp}/test-disk.img"
                ;;
            runtimes/provision_isolated_runtime)
                test_cmd="export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=$_exec_root; sh $_exec_root/_lib/runtimes/provision_isolated_runtime.sh --runtime python --path ${_rtmp}/test-rt && sh $_exec_root/_lib/runtimes/provision_isolated_runtime.sh --runtime python --path ${_rtmp}/test-rt"
                ;;
            ml-training)
                test_cmd="export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=$_exec_root; sh $_exec_root/_lib/ml-training/cli.sh install latest && sh $_exec_root/_lib/ml-training/cli.sh test && sh $_exec_root/_lib/ml-training/cli.sh install latest && sh $_exec_root/_lib/ml-training/cli.sh test"
                ;;
            freebsd/distro)
                test_cmd="export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=$_exec_root; sh $_exec_root/_lib/freebsd/distro/cli.sh install latest && sh $_exec_root/_lib/freebsd/distro/cli.sh test && sh $_exec_root/_lib/freebsd/distro/cli.sh install latest && sh $_exec_root/_lib/freebsd/distro/cli.sh test"
                ;;
            illumos/distro)
                test_cmd="export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=$_exec_root; sh $_exec_root/_lib/illumos/distro/cli.sh install latest && sh $_exec_root/_lib/illumos/distro/cli.sh test && sh $_exec_root/_lib/illumos/distro/cli.sh install latest && sh $_exec_root/_lib/illumos/distro/cli.sh test"
                ;;
            distro)
                test_cmd="export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=$_exec_root; sh $_exec_root/_lib/orchestration/distro/cli.sh install latest && sh $_exec_root/_lib/orchestration/distro/cli.sh test && sh $_exec_root/_lib/orchestration/distro/cli.sh install latest && sh $_exec_root/_lib/orchestration/distro/cli.sh test"
                ;;
            topologies/gke-tpu-cluster)
                test_cmd="export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=$_exec_root; sh $_exec_root/topologies/gke-tpu-cluster/cli.sh --help && sh $_exec_root/topologies/gke-tpu-cluster/cli.sh --help"
                ;;
            topologies/*)
                _topo_name="${target#topologies/}"
                test_cmd="export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=$_exec_root LIBSCRIPT_TOPOLOGY_STATE_FILE=${_rtmp}/topo-$_topo_name.json; rm -f ${_rtmp}/topo-$_topo_name.json*; sh $_exec_root/topologies/$_topo_name/cli.sh up && sh $_exec_root/topologies/$_topo_name/cli.sh status && sh $_exec_root/topologies/$_topo_name/cli.sh up && sh $_exec_root/topologies/$_topo_name/cli.sh destroy && rm -f ${_rtmp}/topo-$_topo_name.json*"
                ;;
            payloads/schedulers/*)
                _sched_name="${target#payloads/schedulers/}"
                test_cmd="export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=$_exec_root; sh $_exec_root/payloads/engine.sh compile $_exec_root/payloads/ai/vllm/payload.json --scheduler $_sched_name && sh $_exec_root/payloads/engine.sh submit $_exec_root/payloads/ai/vllm/payload.json --scheduler $_sched_name && sh $_exec_root/payloads/engine.sh status $_exec_root/payloads/ai/vllm/payload.json --scheduler $_sched_name && sh $_exec_root/payloads/engine.sh submit $_exec_root/payloads/ai/vllm/payload.json --scheduler $_sched_name && sh $_exec_root/payloads/engine.sh destroy $_exec_root/payloads/ai/vllm/payload.json --scheduler $_sched_name"
                ;;
            traits/*)
                _trait_name="${target#traits/}"
                test_cmd="export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=$_exec_root LIBSCRIPT_TARGET_SYSROOT=${_rtmp}/trait-sysroot-$_trait_name LIBSCRIPT_OFFLINE=1; rm -rf ${_rtmp}/trait-sysroot-$_trait_name && mkdir -p ${_rtmp}/trait-sysroot-$_trait_name && sh $_exec_root/traits/engine.sh enable $_trait_name && sh $_exec_root/traits/engine.sh apply $_trait_name && sh $_exec_root/traits/engine.sh verify $_trait_name && sh $_exec_root/traits/engine.sh apply $_trait_name && sh $_exec_root/traits/engine.sh teardown $_trait_name && rm -rf ${_rtmp}/trait-sysroot-$_trait_name"
                ;;
            *)
                test_cmd="export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=$_exec_root; $_t_inst $_exec_root/libscript.sh install $target && $_t_test $_exec_root/libscript.sh test $target && ($_exec_root/libscript.sh env $target latest >/dev/null 2>&1 || true) && $_t_inst $_exec_root/libscript.sh install $target && $_t_test $_exec_root/libscript.sh test $target"
                ;;
        esac

        # Execute test: install -> test -> env -> install (idempotency) -> test (verification)
        if [ "$VAGRANT_ACTIVE" = "1" ]; then
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
        else
            # Native macOS execution
            if /bin/sh -c "$test_cmd" > "$stdout_file" 2> "$stderr_file"; then
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
                cleanup_cmd="export LIBSCRIPT_ROOT_DIR=/Users/vagrant/libscript; /Users/vagrant/libscript/libscript.sh uninstall $target >/dev/null 2>&1 || true; rm -rf /Users/vagrant/.libscript/$_short_target 2>/dev/null || true"
                ssh -n -p "$_port" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$_key" vagrant@127.0.0.1 "$cleanup_cmd" >/dev/null 2>&1 || true
            else
                "$REPO_ROOT/libscript.sh" uninstall "$target" >/dev/null 2>&1 || true
                rm -rf "$HOME/.libscript/$_short_target" 2>/dev/null || true
            fi
        fi
    done

    if [ -x "$REPO_ROOT/tests/update_results.sh" ]; then
        "$REPO_ROOT/tests/update_results.sh" || true
    fi

    echo ""
    echo '============================================================'
    echo "macOS Tests Complete (Iteration $iteration)"
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
