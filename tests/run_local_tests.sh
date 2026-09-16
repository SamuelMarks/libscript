#!/bin/sh
# ## Overview
# Runs local tests using Vagrant across all toolchains, languages, and databases
# to verify libscript installation and testing on isolated Vagrant VMs.
#
# ## Usage
# Results are written to the tests_tmp directory.

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
THIS_DIR="${SCRIPT_DIR}"
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

OS_TARGET="alpine-3.24"
TARGETS=""
REUSE_VM=""

# First pass to capture OS_TARGET and handle help
while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h|/?)
            echo "Usage: $(basename "$THIS_FILE") [TARGETS...|all] [--os OS_NAME] [--reuse-vm]"
            echo ""
            echo "Runs local tests using Vagrant across specified categories or individual targets"
            echo "to verify libscript installation and testing."
            echo ""
            echo "Arguments:"
            echo "  TARGETS...     A list of categories (e.g., databases, languages) or specific targets."
            echo "                 If no targets are provided, defaults to: databases languages toolchains"
            echo "  all            Run tests across all categories in the _lib directory."
            echo "  --os OS_NAME   The OS environment to use from the vagrant/ folder (default: alpine-3.24)."
            echo "                 Example: --os debian-13, --os rockylinux-10.2, --os omnios"
            echo "  --reuse-vm     Reuse a running VM instead of creating/destroying a new VM per target."
            echo "  --fast         Alias for --reuse-vm."
            echo "  --help, -h, /? Show this help message."
            echo ""
            echo "Results are written to the tests_tmp directory."
            exit 0
            ;;
        --os)
            OS_TARGET="$2"
            shift 2
            ;;
        --reuse-vm|--fast)
            REUSE_VM=1
            shift
            ;;
        *)
            TARGETS="$TARGETS $1"
            shift
            ;;
    esac
done

if [ -z "$(echo "$TARGETS" | tr -d ' ')" ]; then
    TARGETS="databases caches languages toolchains"
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
OS_FAMILY=""
case "$OS_ID" in
    alpine) OS_TAG="linux.alpine"; OS_FAMILY="linux" ;;
    debian) OS_TAG="linux.debian"; OS_FAMILY="linux" ;;
    rhel|almalinux|centos|fedora|rocky|rockylinux) OS_TAG="linux.rhel"; OS_FAMILY="linux" ;;
    freebsd|bsd) OS_TAG="freebsd"; OS_FAMILY="bsd" ;;
    windows) OS_TAG="windows"; OS_FAMILY="windows" ;;
    omnios|sunos|solaris|illumos) OS_TAG="sunos"; OS_FAMILY="sunos" ;;
    *) OS_TAG="$OS_ID"; OS_FAMILY="" ;;
esac

if [ "$REUSE_VM" = "1" ]; then
    echo "=== Ensuring $OS_TARGET Vagrant VM is running ==="
    cd "$REPO_ROOT/vagrant/$OS_TARGET"
    if ! vagrant status 2>&1 | grep -q "running"; then
        echo "Starting $OS_TARGET Vagrant VM..."
        vagrant up --no-provision
        if [ "$OS_ID" = "debian" ] || [ "$OS_ID" = "ubuntu" ]; then
            vagrant ssh --no-tty -c "sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq && sudo DEBIAN_FRONTEND=noninteractive apt-get install -qq -y apt-utils curl jq rsync" >/dev/null 2>&1 || true
        elif [ "$OS_ID" = "rhel" ] || [ "$OS_ID" = "almalinux" ] || [ "$OS_ID" = "centos" ] || [ "$OS_ID" = "fedora" ] || [ "$OS_ID" = "rocky" ] || [ "$OS_ID" = "rockylinux" ]; then
            vagrant ssh --no-tty -c "sudo dnf install -y -q curl jq rsync findutils which" >/dev/null 2>&1 || true
        elif [ "$OS_ID" = "omnios" ] || [ "$OS_ID" = "sunos" ] || [ "$OS_ID" = "solaris" ] || [ "$OS_ID" = "illumos" ]; then
            vagrant ssh --no-tty -c "sudo pkg install --accept network/rsync developer/versioning/git" >/dev/null 2>&1 || true
        fi
    fi
    echo "=== Syncing LibScript repository to $OS_TARGET ==="
    vagrant rsync
fi

TARGET_ARCH=""
if [ "$OS_ID" = "windows" ]; then
    TARGET_ARCH=$(cd "$REPO_ROOT/vagrant/$OS_TARGET" && vagrant ssh --no-tty -c "powershell -Command \"\$env:PROCESSOR_ARCHITECTURE\"" 2>/dev/null | tr -d '\r\n' | tr '[:upper:]' '[:lower:]' || echo "amd64")
else
    TARGET_ARCH=$(cd "$REPO_ROOT/vagrant/$OS_TARGET" && vagrant ssh --no-tty -c "uname -m" 2>/dev/null | tr -d '\r\n' || echo "x86_64")
fi

for target in $UNIQUE_TARGETS; do
    MANIFEST_PATH=$(find "$REPO_ROOT/_lib" -maxdepth 2 -type d -name "$target" -exec echo "{}/manifest.json" \;)
    if [ -f "$MANIFEST_PATH" ]; then
        SUPPORTED=$(awk -v os="$OS_ID" -v family="$OS_FAMILY" -v arch="$TARGET_ARCH" '
        BEGIN { in_bl=0; in_wl=0; has_wl=0; wl_match=0; in_abl=0; in_awl=0; has_awl=0; awl_match=0; result="yes" }
        /"os_blacklist"\s*:/ {
            in_bl=1; in_wl=0; in_abl=0; in_awl=0
            if ($0 ~ "\"" os "\"" || (family != "" && $0 ~ "\"" family "\"")) { result="no"; exit }
            if ($0 ~ /\]/) { in_bl=0 }
            next
        }
        /"os_whitelist"\s*:/ {
            in_wl=1; in_bl=0; in_abl=0; in_awl=0; has_wl=1
            if ($0 ~ "\"" os "\"" || $0 ~ "\"all\"" || (family != "" && $0 ~ "\"" family "\"")) { wl_match=1 }
            if ($0 ~ /\]/) { in_wl=0 }
            next
        }
        /"arch_blacklist"\s*:/ {
            in_abl=1; in_bl=0; in_wl=0; in_awl=0
            if (arch != "" && ($0 ~ "\"" arch "\"" || (arch == "aarch64" && $0 ~ "\"arm64\"") || (arch == "arm64" && $0 ~ "\"aarch64\"") || (arch == "x86_64" && $0 ~ "\"amd64\"") || (arch == "amd64" && $0 ~ "\"x86_64\""))) { result="no"; exit }
            if ($0 ~ /\]/) { in_abl=0 }
            next
        }
        /"arch_whitelist"\s*:/ {
            in_awl=1; in_bl=0; in_wl=0; in_abl=0; has_awl=1
            if ($0 ~ "\"all\"" || (arch != "" && ($0 ~ "\"" arch "\"" || (arch == "aarch64" && $0 ~ "\"arm64\"") || (arch == "arm64" && $0 ~ "\"aarch64\"") || (arch == "x86_64" && $0 ~ "\"amd64\"") || (arch == "amd64" && $0 ~ "\"x86_64\"")))) { awl_match=1 }
            if ($0 ~ /\]/) { in_awl=0 }
            next
        }
        in_bl {
            if ($0 ~ "\"" os "\"" || (family != "" && $0 ~ "\"" family "\"")) { result="no"; exit }
            if ($0 ~ /\]/) { in_bl=0 }
        }
        in_wl {
            if ($0 ~ "\"" os "\"" || $0 ~ "\"all\"" || (family != "" && $0 ~ "\"" family "\"")) { wl_match=1 }
            if ($0 ~ /\]/) { in_wl=0 }
        }
        in_abl {
            if (arch != "" && ($0 ~ "\"" arch "\"" || (arch == "aarch64" && $0 ~ "\"arm64\"") || (arch == "arm64" && $0 ~ "\"aarch64\"") || (arch == "x86_64" && $0 ~ "\"amd64\"") || (arch == "amd64" && $0 ~ "\"x86_64\""))) { result="no"; exit }
            if ($0 ~ /\]/) { in_abl=0 }
        }
        in_awl {
            if ($0 ~ "\"all\"" || (arch != "" && ($0 ~ "\"" arch "\"" || (arch == "aarch64" && $0 ~ "\"arm64\"") || (arch == "arm64" && $0 ~ "\"aarch64\"") || (arch == "x86_64" && $0 ~ "\"amd64\"") || (arch == "amd64" && $0 ~ "\"x86_64\"")))) { awl_match=1 }
            if ($0 ~ /\]/) { in_awl=0 }
        }
        END {
            if (result == "yes" && has_wl && !wl_match) { result="no" }
            if (result == "yes" && has_awl && !awl_match) { result="no" }
            print result
        }
        ' "$MANIFEST_PATH")
        if [ "$SUPPORTED" = "no" ]; then
            echo "Skipping $target (not supported on $OS_ID / $TARGET_ARCH)"
            continue
        fi
    fi
    echo "============================================================"
    echo "Running test for $target on $OS_TARGET..."
    echo "============================================================"
    
    stdout_file="$TESTS_TMP_DIR/$target.$OS_TAG.stdout"
    stderr_file="$TESTS_TMP_DIR/$target.$OS_TAG.stderr"
    success_file="$TESTS_TMP_DIR/$target.$OS_TAG.success"
    failure_file="$TESTS_TMP_DIR/$target.$OS_TAG.failure"
    
    rm -f "$success_file" "$failure_file"

    if [ "$REUSE_VM" = "1" ]; then
        cd "$REPO_ROOT/vagrant/$OS_TARGET"
        if [ "$OS_ID" = "windows" ]; then
            test_cmd='Set-Location C:\libscript; cmd.exe /c "C:\libscript\libscript.cmd install '$target'" ; $iExit = $LASTEXITCODE; cmd.exe /c "C:\libscript\libscript.cmd test '$target'" ; $tExit = $LASTEXITCODE; if ($tExit -ne 0) { exit $tExit } elseif ($iExit -ne 0) { exit $iExit }'
            if vagrant ssh --no-tty -c "$test_cmd" > "$stdout_file" 2> "$stderr_file"; then
                echo "Success" > "$success_file"
                echo "[OK] $target"
            else
                echo "Failure" > "$failure_file"
                echo "[FAILED] $target"
            fi
            cleanup_cmd="cd C:\libscript; & C:\libscript\libscript.cmd uninstall $target *>&1 | Out-Null; Remove-Item -Recurse -Force \"\$env:USERPROFILE\.libscript\\$target\" -ErrorAction SilentlyContinue"
            vagrant ssh --no-tty -c "powershell -Command \"$cleanup_cmd\"" >/dev/null 2>&1 || true
        else
            test_cmd="export DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a LIBSCRIPT_ROOT_DIR=/opt/repos/libscript; timeout 300 /opt/repos/libscript/libscript.sh install $target && timeout 120 /opt/repos/libscript/libscript.sh test $target"
            if vagrant ssh --no-tty -c "$test_cmd" > "$stdout_file" 2> "$stderr_file"; then
                echo "Success" > "$success_file"
                echo "[OK] $target"
            else
                echo "Failure" > "$failure_file"
                echo "[FAILED] $target"
            fi
            cleanup_cmd="export LIBSCRIPT_ROOT_DIR=/opt/repos/libscript; /opt/repos/libscript/libscript.sh uninstall $target >/dev/null 2>&1 || true; rm -rf \"\$HOME/.libscript/$target\" /tmp/libscript_pkg_mgr_lock 2>/dev/null || true"
            vagrant ssh --no-tty -c "$cleanup_cmd" >/dev/null 2>&1 || true
        fi
    else
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
        
        if vagrant up > "$stdout_file" 2> "$stderr_file"; then
            echo "Success" > "$success_file"
            echo "[OK] $target"
        else
            echo "Failure" > "$failure_file"
            echo "[FAILED] $target"
        fi

        vagrant destroy -f >/dev/null 2>&1 || true
        sleep 2
    fi
    
    if [ -x "$THIS_DIR/update_results.sh" ]; then
        "$THIS_DIR/update_results.sh" || true
    fi
done

echo "All tests complete. Results are in $TESTS_TMP_DIR."
