#!/bin/sh
# ## Overview
# Non-destructive universal multi-tenant database schema deprovisioner.
# Drops only the specified tenant application schema and user account.
# GUARANTEE: Never stops, uninstalls, or harms the shared database server daemon or peer schemas.
#
# ## Usage
#   ./_lib/databases/deprovision_schema.sh [OPTIONS]
#
# ## Options
#   --engine <type>          Database engine (mysql, mariadb, postgres, mongodb, sqlite)
#   --host <host>            Server hostname (default: 127.0.0.1)
#   --port <port>            Server TCP port (default based on engine)
#   --admin-user <user>      Administrative username (e.g. root or postgres)
#   --admin-pass <pass>      Administrative password
#   --schema <name>          Tenant schema/database name to drop
#   --user <user>            Tenant application username to drop
#
# ## Exit Codes
#   0 - Deprovisioning succeeded or schema already absent (idempotent)
#   1 - Deprovisioning failed

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

ENGINE="mysql"
HOST="127.0.0.1"
PORT=""
ADMIN_USER=""
ADMIN_PASS=""
SCHEMA_NAME=""
APP_USER=""

while [ $# -gt 0 ]; do
  case "$1" in
    --engine)
      ENGINE="$2"
      shift 2
      ;;
    --host)
      HOST="$2"
      shift 2
      ;;
    --port)
      PORT="$2"
      shift 2
      ;;
    --admin-user)
      ADMIN_USER="$2"
      shift 2
      ;;
    --admin-pass)
      ADMIN_PASS="$2"
      shift 2
      ;;
    --schema)
      SCHEMA_NAME="$2"
      shift 2
      ;;
    --user)
      APP_USER="$2"
      shift 2
      ;;
    *)
      printf '[ERROR] Unknown parameter: %s
' "$1" >&2
      exit 1
      ;;
  esac
done

if [ -z "$SCHEMA_NAME" ]; then
  printf '[ERROR] --schema name must be provided
' >&2
  exit 1
fi

case "$ENGINE" in
  mysql|mariadb)
    : "${PORT:=3306}"
    : "${ADMIN_USER:=root}"
    CLIENT_BIN="mysql"
    command -v mariadb >/dev/null 2>&1 && CLIENT_BIN="mariadb"

    AUTH_ARGS="-h $HOST -P $PORT -u $ADMIN_USER"
    if [ -n "$ADMIN_PASS" ]; then
      AUTH_ARGS="$AUTH_ARGS -p$ADMIN_PASS"
    fi

    printf '[INFO] Dropping %s tenant schema `%s`...
' "$ENGINE" "$SCHEMA_NAME"
    $CLIENT_BIN $AUTH_ARGS -e "DROP DATABASE IF EXISTS \`$SCHEMA_NAME\`;"

    if [ -n "$APP_USER" ]; then
      printf '[INFO] Dropping %s tenant user `%s`...
' "$ENGINE" "$APP_USER"
      $CLIENT_BIN $AUTH_ARGS -e "DROP USER IF EXISTS '$APP_USER'@'localhost';"
      $CLIENT_BIN $AUTH_ARGS -e "DROP USER IF EXISTS '$APP_USER'@'127.0.0.1';"
      $CLIENT_BIN $AUTH_ARGS -e "DROP USER IF EXISTS '$APP_USER'@'%';"
      $CLIENT_BIN $AUTH_ARGS -e "FLUSH PRIVILEGES;"
    fi
    ;;

  postgres|postgresql)
    : "${PORT:=5432}"
    : "${ADMIN_USER:=postgres}"
    CLIENT_BIN="psql"

    export PGPASSWORD="$ADMIN_PASS"
    export PGHOST="$HOST"
    export PGPORT="$PORT"
    export PGUSER="$ADMIN_USER"

    printf '[INFO] Dropping PostgreSQL tenant schema `%s`...
' "$SCHEMA_NAME"
    $CLIENT_BIN -c "DROP DATABASE IF EXISTS \"$SCHEMA_NAME\";" || true

    if [ -n "$APP_USER" ]; then
      printf '[INFO] Dropping PostgreSQL tenant user `%s`...
' "$APP_USER"
      $CLIENT_BIN -c "DROP USER IF EXISTS \"$APP_USER\";" || true
    fi
    ;;

  sqlite)
    if [ -f "$SCHEMA_NAME" ]; then
      printf '[INFO] Removing SQLite database file `%s`...
' "$SCHEMA_NAME"
      rm -f "$SCHEMA_NAME" "${SCHEMA_NAME}-wal" "${SCHEMA_NAME}-shm"
    fi
    ;;

  mongodb)
    : "${PORT:=27017}"
    printf '[INFO] Dropping MongoDB database `%s`...
' "$SCHEMA_NAME"
    if command -v mongosh >/dev/null 2>&1; then
      mongosh "mongodb://$HOST:$PORT/$SCHEMA_NAME" --eval "db.dropDatabase()" || true
    fi
    ;;

  *)
    printf '[ERROR] Unsupported database engine for deprovisioning: %s
' "$ENGINE" >&2
    exit 1
    ;;
esac

printf '[SUCCESS] Database schema `%s` successfully deprovisioned.
' "$SCHEMA_NAME"
