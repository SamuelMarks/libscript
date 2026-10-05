#!/bin/sh
# ## Overview
# Safely deprovisions a multi-tenant database schema and user account.
# Supports MySQL/MariaDB, PostgreSQL, MongoDB.
#
# ## Usage
#   ./deprovision_schema.sh --engine <engine> --host <host> --port <port> \
#     --admin-user <user> --admin-pass <pass> \
#     --schema <name> --user <tenant>

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

while [ $# -gt 0 ]; do
  case "$1" in
    --engine) engine="$2"; shift 2 ;;
    --host) host="$2"; shift 2 ;;
    --port) port="$2"; shift 2 ;;
    --admin-user) admin_user="$2"; shift 2 ;;
    --admin-pass) admin_pass="$2"; shift 2 ;;
    --schema) schema_name="$2"; shift 2 ;;
    --user) tenant_user="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [ -z "$engine" ] || [ -z "$schema_name" ] || [ -z "$tenant_user" ]; then
  printf 'Error: Missing required arguments.\n' >&2
  exit 1
fi

case "$engine" in
  mysql|mariadb)
    [ -z "$port" ] && port="3306"
    [ -z "$admin_user" ] && admin_user="root"
    sql="DROP DATABASE IF EXISTS \`${schema_name}\`;
         DROP USER IF EXISTS '${tenant_user}'@'localhost';
         DROP USER IF EXISTS '${tenant_user}'@'127.0.0.1';
         DROP USER IF EXISTS '${tenant_user}'@'%';
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
    psql -h "$host" -p "$port" -U "$admin_user" -c "DROP DATABASE IF EXISTS \"${schema_name}\";"
    psql -h "$host" -p "$port" -U "$admin_user" -c "DROP USER IF EXISTS \"${tenant_user}\";"
    unset PGPASSWORD
    ;;
  mongodb)
    [ -z "$port" ] && port="27017"
    mongosh_args="--host $host --port $port"
    if [ -n "$admin_user" ]; then
        mongosh_args="$mongosh_args -u $admin_user -p $admin_pass --authenticationDatabase admin"
    fi
    js_cmd="db.getSiblingDB('${schema_name}').dropDatabase(); db.getSiblingDB('${schema_name}').dropUser('${tenant_user}');"
    mongosh $mongosh_args --eval "$js_cmd" --quiet
    ;;
  sqlite)
    if [ -f "$schema_name" ]; then
        rm -f "$schema_name" "${schema_name}-wal" "${schema_name}-shm"
    fi
    ;;
  *)
    printf 'Error: Unsupported engine "%s"\n' "$engine" >&2
    exit 1
    ;;
esac

exit 0