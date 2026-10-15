#!/bin/sh
# ## Overview
# Unit and contract test suite for the Dual-Layer Lifecycle Hook Dispatcher (_lib/_common/hooks.sh).
#
# ## Usage
# ./tests/test_hook_runner.sh

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/hooks.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

TEST_SYSROOT="$(mktemp -d "${TMPDIR:-/tmp}/libscript-hook-test.XXXXXX")"
# ## cleanup_test_sysroot
# Removes temporary test sysroot directory on exit.
cleanup_test_sysroot() {
  rm -rf "$TEST_SYSROOT"
}
trap cleanup_test_sysroot EXIT INT TERM

export LIBSCRIPT_TARGET_SYSROOT="$TEST_SYSROOT"
export LIBSCRIPT_INSTANCE_ROOT="${TEST_SYSROOT}/instance"

# 1. Verify libscript_has_hook
libscript_has_hook "postgres" "configure"
libscript_has_hook "postgres" "provision_tenant"

# 2. Verify physical hooks & 2x idempotency
libscript_exec_hook "postgres" "configure" --role leader
libscript_exec_hook "postgres" "configure" --role leader
libscript_exec_hook "postgres" "probe" readiness
announce_json="$(libscript_exec_hook "postgres" "announce")"
printf '%s\n' "$announce_json" | grep -q '"port":5432'
libscript_exec_hook "postgres" "log_stream" | grep -q '"format":"postgres"'
libscript_exec_hook "postgres" "metrics" | grep -q '"scrape_port":9187'
libscript_exec_hook "postgres" "backup" "${TEST_SYSROOT}/backups"
libscript_exec_hook "postgres" "restore" "${TEST_SYSROOT}/backups"
libscript_exec_hook "postgres" "upgrade" "15" "16"
libscript_exec_hook "postgres" "rollback" "15" "16"
libscript_exec_hook "postgres" "maintenance"

# 3. Verify logical multi-tenant hooks & 2x idempotency
libscript_exec_hook "postgres" "provision_tenant" --tenant wordpress --db-name wp_db --db-user wp_user
libscript_exec_hook "postgres" "provision_tenant" --tenant wordpress --db-name wp_db --db-user wp_user
libscript_exec_hook "postgres" "provision_tenant" --tenant openedx --db-name edx_db --db-user edx_user

count_wp="$(grep -c "BEGIN libscript-managed: wordpress" "${TEST_SYSROOT}/etc/libscript/tenants/postgres/tenants.conf")"
if [ "$count_wp" -ne 1 ]; then
  printf '[FAIL] Expected exactly 1 wordpress tenant block, found %s\n' "$count_wp" >&2
  exit 1
fi

libscript_exec_hook "postgres" "backup_tenant" --tenant wordpress "${TEST_SYSROOT}/tbackups"
libscript_exec_hook "postgres" "restore_tenant" --tenant wordpress "${TEST_SYSROOT}/tbackups"
libscript_exec_hook "postgres" "deprovision_tenant" --tenant wordpress
libscript_exec_hook "postgres" "deprovision_tenant" --tenant wordpress

# Ensure peer tenant openedx remains untouched
grep -q "BEGIN libscript-managed: openedx" "${TEST_SYSROOT}/etc/libscript/tenants/postgres/tenants.conf"

# 4. Verify remote strategy bypass
LIBSCRIPT_REMOTE_STRATEGY="remote" libscript_exec_hook "postgres" "provision_tenant" --tenant remote_app | grep -q '"bypassed_local_ddl"'

# 5. Verify optional hook on stateless component returns 0
libscript_exec_hook "jq" "backup"

printf '[PASS] Dual-layer lifecycle hook runner tests succeeded.\n'
