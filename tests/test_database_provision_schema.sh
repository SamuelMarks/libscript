#!/bin/sh
# ## Overview
# Verification test suite for universal multi-tenant schema provisioning and deprovisioning.
#
# ## Usage
#   ./tests/test_database_provision_schema.sh

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
export DIR="${SCRIPT_DIR}"

PROVISION_SH="${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_schema.sh"
DEPROVISION_SH="${LIBSCRIPT_ROOT_DIR}/_lib/databases/deprovision_schema.sh"

printf '==> Running Universal Schema Provisioning Verification Tests...
'

TEST_SQLITE_DB="$(mktemp "${TMPDIR:-/tmp}/test_schema_XXXXXX.db")"
trap 'rm -f "$TEST_SQLITE_DB"' EXIT INT TERM

# Setup Mock Environment for DB CLIs
MOCK_DIR=$(mktemp -d)
trap 'rm -rf "$MOCK_DIR"; rm -f "$TEST_SQLITE_DB"' EXIT INT TERM

export MOCK_MYSQL_LOG="$MOCK_DIR/mysql_log"
cat <<'EOF' > "$MOCK_DIR/mysql"
#!/bin/sh
echo "MYSQL CALLED WITH: $@" >> "$MOCK_MYSQL_LOG"
EOF
chmod +x "$MOCK_DIR/mysql"

export MOCK_PSQL_LOG="$MOCK_DIR/psql_log"
cat <<'EOF' > "$MOCK_DIR/psql"
#!/bin/sh
echo "PSQL CALLED WITH: $@" >> "$MOCK_PSQL_LOG"
# Mock SELECT 1 returns
if echo "$@" | grep -q "SELECT 1 FROM pg_database"; then
  if [ "${PSQL_MOCK_DB_EXISTS:-0}" = "1" ]; then echo "1"; else echo ""; fi
elif echo "$@" | grep -q "SELECT 1 FROM pg_roles"; then
  if [ "${PSQL_MOCK_ROLE_EXISTS:-0}" = "1" ]; then echo "1"; else echo ""; fi
fi
EOF
chmod +x "$MOCK_DIR/psql"

export MOCK_MONGOSH_LOG="$MOCK_DIR/mongosh_log"
cat <<'EOF' > "$MOCK_DIR/mongosh"
#!/bin/sh
echo "MONGOSH CALLED WITH: $@" >> "$MOCK_MONGOSH_LOG"
EOF
chmod +x "$MOCK_DIR/mongosh"

export PATH="$MOCK_DIR:$PATH"

# 1. Test Idempotent SQLite Provisioning (Two passes)
printf '[TEST 1] Testing SQLite provisioning idempotency (Pass 1)...\n'
"$PROVISION_SH" --engine sqlite --schema "$TEST_SQLITE_DB" --user u --password p
[ -f "$TEST_SQLITE_DB" ] || exit 1

printf '[TEST 1] Testing SQLite provisioning idempotency (Pass 2)...\n'
"$PROVISION_SH" --engine sqlite --schema "$TEST_SQLITE_DB" --user u --password p
[ -f "$TEST_SQLITE_DB" ] || exit 1

# 2. Test Idempotent MySQL Provisioning
printf '[TEST 2] Testing MySQL provisioning idempotency...\n'
rm -f "$MOCK_MYSQL_LOG"
"$PROVISION_SH" --engine mysql --schema "testdb" --user "testuser" --password "testpass"
grep -q "CREATE DATABASE IF NOT EXISTS \`testdb\`" "$MOCK_MYSQL_LOG" || exit 1
grep -q "CREATE USER IF NOT EXISTS 'testuser'@'localhost'" "$MOCK_MYSQL_LOG" || exit 1

# 3. Test Idempotent Postgres Provisioning
printf '[TEST 3] Testing Postgres provisioning idempotency (Pass 1 - Create)...\n'
rm -f "$MOCK_PSQL_LOG"
export PSQL_MOCK_DB_EXISTS=0
export PSQL_MOCK_ROLE_EXISTS=0
"$PROVISION_SH" --engine postgres --schema "testdb" --user "testuser" --password "testpass"
grep -q "CREATE DATABASE \\\"testdb\\\"" "$MOCK_PSQL_LOG" || exit 1
grep -q "CREATE USER \\\"testuser\\\"" "$MOCK_PSQL_LOG" || exit 1

printf '[TEST 3] Testing Postgres provisioning idempotency (Pass 2 - Exists)...\n'
rm -f "$MOCK_PSQL_LOG"
export PSQL_MOCK_DB_EXISTS=1
export PSQL_MOCK_ROLE_EXISTS=1
"$PROVISION_SH" --engine postgres --schema "testdb" --user "testuser" --password "testpass"
if grep -q "CREATE DATABASE" "$MOCK_PSQL_LOG"; then echo "Failed idempotency"; exit 1; fi
if grep -q "CREATE USER" "$MOCK_PSQL_LOG"; then echo "Failed idempotency"; exit 1; fi

# 4. Test Idempotent MongoDB Provisioning
printf '[TEST 4] Testing MongoDB provisioning idempotency...\n'
rm -f "$MOCK_MONGOSH_LOG"
"$PROVISION_SH" --engine mongodb --schema "testdb" --user "testuser" --password "testpass"
grep -q "createUser" "$MOCK_MONGOSH_LOG" || exit 1

printf '[SUCCESS] All Schema Provisioning Verification Tests Passed!\n'
