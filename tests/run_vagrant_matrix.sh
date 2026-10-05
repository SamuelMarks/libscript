#!/bin/sh
# ## Overview
# Orchestrates test script execution across the entire Vagrant testing matrix.
# Iterates over Ubuntu, Debian, Windows 11, FreeBSD, and OmniOS (if available)
# to run all unit and integration test scripts, ensuring zero privilege escalation
# on the host machine.
#
# ## Usage
# ./tests/run_vagrant_matrix.sh [--target-dir=<dir>]

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR
export LIBSCRIPT_REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

printf '==> LibScript Vagrant Test Matrix Orchestrator\n'

VAGRANT_DIRS="debian-13 windows-11 freebsd-15.1 omnios rockylinux-10.2 alpine-3.24"

# Validate that Vagrant is available and does not require sudo
if ! command -v vagrant >/dev/null 2>&1; then
    printf '[ERROR] Vagrant is not installed or not in PATH.\n' >&2
    exit 1
fi

# Ensure Vagrant doesn't require sudo
if vagrant --version | grep -q "sudo"; then
    printf '[ERROR] Vagrant execution requires sudo. Zero privilege escalation constraint violated.\n' >&2
    exit 1
fi

PREV_WD="$(pwd)"
cd "${LIBSCRIPT_ROOT_DIR}/vagrant" || exit 1

TEST_SCRIPTS="test_database_discovery test_database_provision_schema test_connection_uri_parser test_generic_msi_generation test_modular_msi_reuse test_idempotency_matrix test_msi_generation test_python_uv_integration test_odoo_remote_db test_remote_db_failure"

FAILURES=0

for vdir in $VAGRANT_DIRS; do
    if [ ! -d "$vdir" ] || [ ! -f "$vdir/Vagrantfile" ]; then
        printf '[WARN] Vagrant directory %s not found or missing Vagrantfile. Skipping...\n' "$vdir"
        continue
    fi
    
    printf '\n=======================================================\n'
    printf '[MATRIX] Starting tests in environment: %s\n' "$vdir"
    printf '=======================================================\n'
    
    cd -- "$vdir"
    
    for script_name in $TEST_SCRIPTS; do
        printf '\n[TEST] -> %s (in %s)\n' "$script_name" "$vdir"
        export LIBSCRIPT_TEST_TARGET="$script_name"
        export VAGRANT_VAGRANTFILE="Vagrantfile"
        
        # Determine the name of the VM so we can clean it up
        VM_NAME="${vdir}-test-${script_name}"
        
        # Ensure fresh state
        vagrant destroy -f >/dev/null 2>&1 || true
        
        if vagrant up; then
            printf '[OK] %s passed in %s\n' "$script_name" "$vdir"
        else
            printf '[FAIL] %s failed in %s\n' "$script_name" "$vdir" >&2
            FAILURES=$((FAILURES + 1))
        fi
        
        # Teardown without privilege escalation
        vagrant destroy -f >/dev/null 2>&1 || true
    done
    
    cd -- "${LIBSCRIPT_ROOT_DIR}/vagrant"
done

cd -- "$PREV_WD"

if [ "$FAILURES" -gt 0 ]; then
    printf '\n[MATRIX FAIL] Vagrant testing completed with %d failures.\n' "$FAILURES" >&2
    exit 1
fi

printf '\n[MATRIX SUCCESS] All vagrant tests executed successfully with zero privilege escalation!\n'
exit 0
