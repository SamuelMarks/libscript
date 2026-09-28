#!/bin/sh
# ## Overview
# Runs tests sequentially for libscript components on a local SunOS/OmniOS Vagrant VM
# (`bento/omnios`). Results, execution logs, and statuses are written into tests_tmp/
# and the Supported Components table in README.md is automatically updated after each test.
#
# ## Usage
# ./tests/run_illumos_tests.sh [TARGETS...|all]
# Example: ./tests/run_illumos_tests.sh curl sqlite tmux
# Example: ./tests/run_illumos_tests.sh all

set -feu

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
set +f
VAGRANT_DIR="$REPO_ROOT/vagrant/omnios"
TESTS_TMP_DIR="$REPO_ROOT/tests_tmp"

mkdir -p "$TESTS_TMP_DIR"

TARGETS=""
STOP_AFTER=""
SKIP_UNINSTALL=""
LOOP_MODE=""

# ## sync_repo_to_guest
# Synchronizes the libscript codebase to the guest VM using vagrant rsync.
sync_repo_to_guest() {
    echo "=== Syncing LibScript repository to SunOS/OmniOS ==="
    (cd "$VAGRANT_DIR" && vagrant rsync)
}

# ## update_component_in_readme
# Updates the status of a single component in README.md Supported Components table (illumos/SunOS column).
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
            echo "Usage: $(basename "$THIS_FILE") [TARGETS...|all] [--stop-after N] [--skip-uninstall] [--loop]"
            echo ""
            echo "Runs local tests sequentially on SunOS / OmniOS (bento/omnios) Vagrant VM."
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

echo "=== Ensuring SunOS/OmniOS Vagrant VM is running ==="
cd "$VAGRANT_DIR"
vm_status=$(vagrant status 2>&1 || true)
if ! echo "$vm_status" | grep -q "running"; then
    echo "Starting SunOS/OmniOS Vagrant VM..."
    vagrant up --no-provision
fi

sync_repo_to_guest

_ssh_info=$(cd "$VAGRANT_DIR" && vagrant ssh-config 2>/dev/null || true)
_port=$(echo "$_ssh_info" | awk '/Port / {print $2; exit}')
_key=$(echo "$_ssh_info" | awk '/IdentityFile / {print $2; exit}')
: "${_port:=50022}"
: "${_key:=$HOME/.vagrant.d/insecure_private_keys/vagrant.key.ed25519}"

echo "============================================================"
echo "SunOS / OmniOS Test Suite Ready."
echo "============================================================"
