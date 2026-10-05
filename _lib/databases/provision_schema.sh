#!/bin/sh
# ## Overview
# Idempotently provisions a multi-tenant database schema and least-privilege user account.
# Supports MySQL/MariaDB, PostgreSQL, MongoDB, and SQLite.
#
# ## Usage
#   ./provision_schema.sh --engine <engine> --host <host> --port <port> \
#     --admin-user <user> --admin-pass <pass> \
#     --schema <name> --user <tenant> --password <tenant_pass> \
#     [--charset <charset>] [--collation <collation>]

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
export DIR="${SCRIPT_DIR}"

engine=""
host="127.0.0.1"
port=""
admin_user=""
admin_pass=""
schema_name=""
tenant_user=""
tenant_pass=""
charset="utf8mb4"
collation="utf8mb4_unicode_ci"

while [ $# -gt 0 ]; do
  case "$1" in
    --engine) engine="$2"; shift 2 ;;
    --host) host="$2"; shift 2 ;;
    --port) port="$2"; shift 2 ;;
    --admin-user) admin_user="$2"; shift 2 ;;
    --admin-pass) admin_pass="$2"; shift 2 ;;
    --schema) schema_name="$2"; shift 2 ;;
    --user) tenant_user="$2"; shift 2 ;;
    --password) tenant_pass="$2"; shift 2 ;;
    --charset) charset="$2"; shift 2 ;;
    --collation) collation="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [ -z "$engine" ] || [ -z "$schema_name" ] || [ -z "$tenant_user" ] || [ -z "$tenant_pass" ]; then
  printf 'Error: Missing required arguments.\n' >&2
  exit 1
fi

case "$engine" in
  mysql|mariadb)
    [ -z "$port" ] && port="3306"
    [ -z "$admin_user" ] && admin_user="root"
    sql="CREATE DATABASE IF NOT EXISTS \`${schema_name}\` DEFAULT CHARACTER SET ${charset} COLLATE ${collation};
         CREATE USER IF NOT EXISTS '${tenant_user}'@'localhost' IDENTIFIED BY '${tenant_pass}';
         CREATE USER IF NOT EXISTS '${tenant_user}'@'127.0.0.1' IDENTIFIED BY '${tenant_pass}';
         CREATE USER IF NOT EXISTS '${tenant_user}'@'%' IDENTIFIED BY '${tenant_pass}';
         GRANT ALL PRIVILEGES ON \`${schema_name}\`.* TO '${tenant_user}'@'localhost';
         GRANT ALL PRIVILEGES ON \`${schema_name}\`.* TO '${tenant_user}'@'127.0.0.1';
         GRANT ALL PRIVILEGES ON \`${schema_name}\`.* TO '${tenant_user}'@'%';
         FLUSH PRIVILEGES;"
    if [ -n "$admin_pass" ]; then
      mysql -h "$host" -P "$port" -u "$admin_user" -p"$admin_pass" -e "$sql"
    else
      mysql -h "$host" -P "$port" -u "$admin_user" -e "$sql"
    fi
    ;;
  postgres|postgresql)
    [ -z "$port" ] && port="5432"
    [ -z "$admin_user" ] && admin_user="postgres"
    export PGPASSWORD="$admin_pass"
    # Idempotent DB creation
    if ! psql -h "$host" -p "$port" -U "$admin_user" -tAc "SELECT 1 FROM pg_database WHERE datname='${schema_name}'" | grep -q 1; then
      psql -h "$host" -p "$port" -U "$admin_user" -c "CREATE DATABASE \"${schema_name}\";"
    fi
    # Idempotent Role creation
    if ! psql -h "$host" -p "$port" -U "$admin_user" -tAc "SELECT 1 FROM pg_roles WHERE rolname='${tenant_user}'" | grep -q 1; then
      psql -h "$host" -p "$port" -U "$admin_user" -c "CREATE USER \"${tenant_user}\" WITH ENCRYPTED PASSWORD '${tenant_pass}';"
    fi
    psql -h "$host" -p "$port" -U "$admin_user" -c "GRANT ALL PRIVILEGES ON DATABASE \"${schema_name}\" TO \"${tenant_user}\";"
    psql -h "$host" -p "$port" -U "$admin_user" -d "$schema_name" -c "ALTER SCHEMA public OWNER TO \"${tenant_user}\";"
    unset PGPASSWORD
    ;;
  mongodb)
    [ -z "$port" ] && port="27017"
    mongosh_args="--host $host --port $port"
    if [ -n "$admin_user" ]; then
        mongosh_args="$mongosh_args -u $admin_user -p $admin_pass --authenticationDatabase admin"
    fi
    js_cmd="db.getSiblingDB('${schema_name}').createUser({user: '${tenant_user}', pwd: '${tenant_pass}', roles: [{role: 'readWrite', db: '${schema_name}'}]});"
    # mongosh createUser throws if user exists, so we ignore errors or check first.
    js_check="var res = db.getSiblingDB('${schema_name}').getUser('${tenant_user}'); if (!res) { ${js_cmd} }"
    mongosh $mongosh_args --eval "$js_check" --quiet
    ;;
  sqlite)
    # schema_name is treated as the file path
    db_dir=$(dirname "$schema_name")
    mkdir -p "$db_dir"
    sqlite3 "$schema_name" "PRAGMA journal_mode=WAL;"
    chmod 600 "$schema_name"
    ;;
  *)
    printf 'Error: Unsupported engine "%s"\n' "$engine" >&2
    exit 1
    ;;
esac

exit 0