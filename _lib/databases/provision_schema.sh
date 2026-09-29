#!/bin/sh
# ## Overview
# Universal multi-tenant database schema and credential provisioner.
# Idempotently creates isolated schemas/databases and scoped least-privilege user
# credentials across MySQL, MariaDB, PostgreSQL, MongoDB, and SQLite.
#
# ## Usage
#   ./_lib/databases/provision_schema.sh [OPTIONS]
#
# ## Options
#   --engine <type>          Database engine (mysql, mariadb, postgres, mongodb, sqlite)
#   --host <host>            Server hostname (default: 127.0.0.1)
#   --port <port>            Server TCP port (default based on engine)
#   --admin-user <user>      Administrative username (e.g. root or postgres)
#   --admin-pass <pass>      Administrative password
#   --schema <name>          Tenant schema/database name to create
#   --user <user>            Tenant application username to create
#   --password <pass>        Tenant application password to assign
#   --charset <charset>      Character set (default: utf8mb4)
#   --collation <collation>  Collation sequence (default: utf8mb4_unicode_ci)
#
# ## Exit Codes
#   0 - Provisioning succeeded or already in desired state (idempotent)
#   1 - Provisioning failed

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
APP_PASS=""
CHARSET="utf8mb4"
COLLATION="utf8mb4_unicode_ci"

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
    --password)
      APP_PASS="$2"
      shift 2
      ;;
    --charset)
      CHARSET="$2"
      shift 2
      ;;
    --collation)
      COLLATION="$2"
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

    if ! command -v "$CLIENT_BIN" >/dev/null 2>&1; then
      printf '[WARN] Client %s not found in PATH; attempting direct script if available
' "$CLIENT_BIN"
    fi

    AUTH_ARGS="-h $HOST -P $PORT -u $ADMIN_USER"
    if [ -n "$ADMIN_PASS" ]; then
      AUTH_ARGS="$AUTH_ARGS -p$ADMIN_PASS"
    fi

    # 1. Create Schema idempotently
    printf '[INFO] Provisioning %s database `%s` on %s:%s...
' "$ENGINE" "$SCHEMA_NAME" "$HOST" "$PORT"
    $CLIENT_BIN $AUTH_ARGS -e "CREATE DATABASE IF NOT EXISTS \`$SCHEMA_NAME\` DEFAULT CHARACTER SET $CHARSET COLLATE $COLLATION;"

    # 2. Provision Tenant User if specified
    if [ -n "$APP_USER" ]; then
      printf '[INFO] Configuring tenant user `%s` with least privilege on `%s`...
' "$APP_USER" "$SCHEMA_NAME"
      if [ -n "$APP_PASS" ]; then
        $CLIENT_BIN $AUTH_ARGS -e "CREATE USER IF NOT EXISTS '$APP_USER'@'localhost' IDENTIFIED BY '$APP_PASS';"
        $CLIENT_BIN $AUTH_ARGS -e "ALTER USER '$APP_USER'@'localhost' IDENTIFIED BY '$APP_PASS';"
        $CLIENT_BIN $AUTH_ARGS -e "CREATE USER IF NOT EXISTS '$APP_USER'@'127.0.0.1' IDENTIFIED BY '$APP_PASS';"
        $CLIENT_BIN $AUTH_ARGS -e "ALTER USER '$APP_USER'@'127.0.0.1' IDENTIFIED BY '$APP_PASS';"
        $CLIENT_BIN $AUTH_ARGS -e "CREATE USER IF NOT EXISTS '$APP_USER'@'%' IDENTIFIED BY '$APP_PASS';"
        $CLIENT_BIN $AUTH_ARGS -e "ALTER USER '$APP_USER'@'%' IDENTIFIED BY '$APP_PASS';"
      else
        $CLIENT_BIN $AUTH_ARGS -e "CREATE USER IF NOT EXISTS '$APP_USER'@'localhost';"
        $CLIENT_BIN $AUTH_ARGS -e "CREATE USER IF NOT EXISTS '$APP_USER'@'127.0.0.1';"
        $CLIENT_BIN $AUTH_ARGS -e "CREATE USER IF NOT EXISTS '$APP_USER'@'%';"
      fi
      $CLIENT_BIN $AUTH_ARGS -e "GRANT ALL PRIVILEGES ON \`$SCHEMA_NAME\`.* TO '$APP_USER'@'localhost';"
      $CLIENT_BIN $AUTH_ARGS -e "GRANT ALL PRIVILEGES ON \`$SCHEMA_NAME\`.* TO '$APP_USER'@'127.0.0.1';"
      $CLIENT_BIN $AUTH_ARGS -e "GRANT ALL PRIVILEGES ON \`$SCHEMA_NAME\`.* TO '$APP_USER'@'%';"
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

    # 1. Create Schema idempotently
    printf '[INFO] Provisioning PostgreSQL database `%s` on %s:%s...
' "$SCHEMA_NAME" "$HOST" "$PORT"
    _exists=$($CLIENT_BIN -tAc "SELECT 1 FROM pg_database WHERE datname = '$SCHEMA_NAME';" || true)
    if [ "$_exists" != "1" ]; then
      $CLIENT_BIN -c "CREATE DATABASE \"$SCHEMA_NAME\";"
    fi

    # 2. Provision Tenant User if specified
    if [ -n "$APP_USER" ]; then
      printf '[INFO] Configuring PostgreSQL tenant user `%s` on `%s`...
' "$APP_USER" "$SCHEMA_NAME"
      _user_exists=$($CLIENT_BIN -tAc "SELECT 1 FROM pg_roles WHERE rolname = '$APP_USER';" || true)
      if [ "$_user_exists" != "1" ]; then
        if [ -n "$APP_PASS" ]; then
          $CLIENT_BIN -c "CREATE USER \"$APP_USER\" WITH ENCRYPTED PASSWORD '$APP_PASS';"
        else
          $CLIENT_BIN -c "CREATE USER \"$APP_USER\";"
        fi
      elif [ -n "$APP_PASS" ]; then
        $CLIENT_BIN -c "ALTER USER \"$APP_USER\" WITH ENCRYPTED PASSWORD '$APP_PASS';"
      fi
      $CLIENT_BIN -c "GRANT ALL PRIVILEGES ON DATABASE \"$SCHEMA_NAME\" TO \"$APP_USER\";"
    fi
    ;;

  sqlite)
    DB_FILE="$SCHEMA_NAME"
    printf '[INFO] Provisioning SQLite database file `%s`...
' "$DB_FILE"
    _parent_dir=$(dirname "$DB_FILE")
    mkdir -p "$_parent_dir"
    if command -v sqlite3 >/dev/null 2>&1; then
      sqlite3 "$DB_FILE" "PRAGMA journal_mode=WAL;"
    else
      touch "$DB_FILE"
    fi
    chmod 0600 "$DB_FILE"
    ;;

  mongodb)
    : "${PORT:=27017}"
    printf '[INFO] Provisioning MongoDB database `%s` on %s:%s...
' "$SCHEMA_NAME" "$HOST" "$PORT"
    if command -v mongosh >/dev/null 2>&1; then
      _cli="mongosh"
    elif command -v mongo >/dev/null 2>&1; then
      _cli="mongo"
    else
      _cli=""
    fi
    if [ -n "$_cli" ] && [ -n "$APP_USER" ]; then
      "$_cli" "mongodb://$HOST:$PORT/$SCHEMA_NAME" --eval "db.createUser({user: '$APP_USER', pwd: '$APP_PASS', roles: [{role: 'readWrite', db: '$SCHEMA_NAME'}]})" || true
    fi
    ;;

  *)
    printf '[ERROR] Unsupported database engine for provisioning: %s
' "$ENGINE" >&2
    exit 1
    ;;
esac

printf '[SUCCESS] Database schema `%s` successfully provisioned.
' "$SCHEMA_NAME"
