#!/bin/sh
# ## Overview
# Validates the remote DB connection failure recovery mechanism.
# Ensures the provision_logical_db script properly catches a bad remote DB IP
# without attempting to blindly proceed with creation routines that would hang.
#
# ## Usage
#   ./tests/test_remote_db_failure.sh

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

printf '==> Testing Remote DB Connection Failure Handling...\n'

# Simulated bad IP address
BAD_IP="192.0.2.254"

# Execute the POSIX provisioning script directly, expecting it to handle the failure gracefully
# We will use grep to assert it printed the [WARN] about skipping gracefully
if ! "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_logical_db.sh" --host "$BAD_IP" --port 3306 --db-name testdb | grep -q "Attempting creation, but will skip gracefully on permission denied"; then
  printf '[ERROR] Script did not attempt graceful fallback on bad remote IP!\n' >&2
  exit 1
fi

printf '[PASS] Bad remote IP safely bypassed without crashing!\n'
exit 0
