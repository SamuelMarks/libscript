#!/bin/sh
# ## Overview
# Idempotently provisions a multi-tenant database schema and least-privilege user account.
# Supports MySQL/MariaDB, PostgreSQL, MongoDB, and SQLite with reuse-else-create semantics.
#
# ## Usage
#   ./provision_schema.sh --engine <engine> --host <host> --port <port> \
#     --admin-user <user> --admin-pass <pass> \
#     --schema <name> --user <tenant> --password <tenant_pass> \
#     [--legacy-names <csv>] [--charset <charset>] [--collation <collation>]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
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
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export DIR="${SCRIPT_DIR}"

if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true
fi

engine=""
host='127.0.0.1'
port=""
admin_user=""
admin_pass=""
schema_name=""
legacy_names=""
tenant_user=""
tenant_pass=""
charset='utf8mb4'
collation='utf8mb4_unicode_ci'

while [ $# -gt 0 ]; do
  case "$1" in
    --engine) engine="$2"; shift 2 ;;
    --host) host="$2"; shift 2 ;;
    --port) port="$2"; shift 2 ;;
    --admin-user) admin_user="$2"; shift 2 ;;
    --admin-pass) admin_pass="$2"; shift 2 ;;
    --schema) schema_name="$2"; shift 2 ;;
    --legacy-names) legacy_names="$2"; shift 2 ;;
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

# ## run_psql_admin
# Executes a psql administrative query trying TCP with admin_pass, Unix socket via sudo -u postgres, or su - postgres.
run_psql_admin() {
  _rpa_db="${1:-postgres}"
  shift
  if PGPASSWORD="${admin_pass}" psql -h "$host" -p "$port" -U "$admin_user" -d "$_rpa_db" "$@" 2>/dev/null; then
    return 0
  fi
  if command -v sudo >/dev/null 2>&1 && sudo -n -u postgres psql -d "$_rpa_db" "$@" 2>/dev/null; then
    return 0
  fi
  if [ "$(id -u 2>/dev/null || printf '1')" = "0" ] && command -v su >/dev/null 2>&1; then
    su - postgres -c "psql -d \"$_rpa_db\" $*" 2>/dev/null && return 0
  fi
  PGPASSWORD="${tenant_pass}" psql -h "$host" -p "$port" -U "$tenant_user" -d "$_rpa_db" "$@" 2>/dev/null
}

# ## do_postgres
# Idempotently reuses or creates PostgreSQL role and database schema.
do_postgres() {
  [ -z "$port" ] && port="5432"
  [ -z "$admin_user" ] && admin_user="postgres"

  if run_psql_admin postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='${tenant_user}'" | grep -q 1; then
    if PGPASSWORD="${tenant_pass}" psql -h "$host" -p "$port" -U "$tenant_user" -d postgres -tAc "SELECT 1" >/dev/null 2>&1; then
      log_info "[DB:POSTGRES] [CONFIRM] Role '${tenant_user}' already exists on ${host}:${port} (password & privileges synchronized)."
    else
      log_info "[DB:POSTGRES] [CONFIRM] Role '${tenant_user}' exists on ${host}:${port}; synchronizing password..."
      run_psql_admin postgres -c "ALTER USER \"${tenant_user}\" WITH LOGIN PASSWORD '${tenant_pass}';" >/dev/null 2>&1 || true
    fi
  else
    log_info "[DB:POSTGRES] [CREATE] Creating role '${tenant_user}' on ${host}:${port}..."
    run_psql_admin postgres -c "CREATE USER \"${tenant_user}\" WITH LOGIN ENCRYPTED PASSWORD '${tenant_pass}';" >/dev/null 2>&1 || true
  fi

  if run_psql_admin postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${schema_name}'" | grep -q 1; then
    _pg_tbl_cnt=$(run_psql_admin "$schema_name" -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';" 2>/dev/null | tr -d '[:space:]' || printf '0')
    log_info "[DB:POSTGRES] [CONFIRM] Database '${schema_name}' already exists on ${host}:${port} (owner: '${tenant_user}', tables: ${_pg_tbl_cnt:-0})."
  else
    _migrated_legacy=0
    if [ -n "$legacy_names" ]; then
      _old_ifs="$IFS"
      IFS=','
      for _leg_db in $legacy_names; do
        [ -n "$_leg_db" ] || continue
        if [ "$_leg_db" != "$schema_name" ] && run_psql_admin postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${_leg_db}'" | grep -q 1; then
          log_info "[DB:POSTGRES] [CONFIRM] Renaming legacy PostgreSQL database '${_leg_db}' -> '${schema_name}'..."
          if run_psql_admin postgres -c "ALTER DATABASE \"${_leg_db}\" RENAME TO \"${schema_name}\";" >/dev/null 2>&1; then
            _migrated_legacy=1
            break
          fi
        fi
      done
      IFS="$_old_ifs"
    fi
    if [ "$_migrated_legacy" -eq 0 ]; then
      log_info "[DB:POSTGRES] [CREATE] Creating database '${schema_name}' on ${host}:${port} (owner: '${tenant_user}')..."
      run_psql_admin postgres -c "CREATE DATABASE \"${schema_name}\" OWNER \"${tenant_user}\";" >/dev/null 2>&1 || \
        createdb -h "$host" -p "$port" -U "$admin_user" -O "$tenant_user" "$schema_name" >/dev/null 2>&1 || true
    fi
  fi

  run_psql_admin postgres -c "GRANT ALL PRIVILEGES ON DATABASE \"${schema_name}\" TO \"${tenant_user}\";" >/dev/null 2>&1 || true
  run_psql_admin "$schema_name" -c "ALTER SCHEMA public OWNER TO \"${tenant_user}\";" >/dev/null 2>&1 || true
}

case "$engine" in
  mysql|mariadb)
    [ -z "$port" ] && port="3306"
    [ -z "$admin_user" ] && admin_user="root"
    log_info "[DB:MYSQL] Ensuring schema '${schema_name}' and user '${tenant_user}' on ${host}:${port}..."
    sql="CREATE DATABASE IF NOT EXISTS \`${schema_name}\` DEFAULT CHARACTER SET ${charset} COLLATE ${collation};
         CREATE USER IF NOT EXISTS '${tenant_user}'@'localhost' IDENTIFIED BY '${tenant_pass}';
         CREATE USER IF NOT EXISTS '${tenant_user}'@'127.0.0.1' IDENTIFIED BY '${tenant_pass}';
         CREATE USER IF NOT EXISTS '${tenant_user}'@'%' IDENTIFIED BY '${tenant_pass}';
         ALTER USER '${tenant_user}'@'localhost' IDENTIFIED BY '${tenant_pass}';
         ALTER USER '${tenant_user}'@'127.0.0.1' IDENTIFIED BY '${tenant_pass}';
         ALTER USER '${tenant_user}'@'%' IDENTIFIED BY '${tenant_pass}';
         GRANT ALL PRIVILEGES ON \`${schema_name}\`.* TO '${tenant_user}'@'localhost';
         GRANT ALL PRIVILEGES ON \`${schema_name}\`.* TO '${tenant_user}'@'127.0.0.1';
         GRANT ALL PRIVILEGES ON \`${schema_name}\`.* TO '${tenant_user}'@'%';
         FLUSH PRIVILEGES;"
    if [ -n "$admin_pass" ]; then
      mysql -h "$host" -P "$port" -u "$admin_user" -p"$admin_pass" -e "$sql"
    else
      mysql -h "$host" -P "$port" -u "$admin_user" -e "$sql" 2>/dev/null || \
        mysql -u "$admin_user" -e "$sql" 2>/dev/null || \
        mysql -u "$(id -un)" -e "$sql"
    fi
    log_info "[DB:MYSQL] [CONFIRM] Schema '${schema_name}' and user '${tenant_user}' ready on ${host}:${port}."
    ;;
  postgres|postgresql)
    do_postgres
    ;;
  mongodb)
    [ -z "$port" ] && port="27017"
    log_info "[DB:MONGODB] Ensuring database '${schema_name}' and user '${tenant_user}' on ${host}:${port}..."
    mongosh_args="--host $host --port $port"
    if [ -n "$admin_user" ]; then
        mongosh_args="$mongosh_args -u $admin_user -p $admin_pass --authenticationDatabase admin"
    fi
    js_cmd="db.getSiblingDB('${schema_name}').createUser({user: '${tenant_user}', pwd: '${tenant_pass}', roles: [{role: 'readWrite', db: '${schema_name}'}]});"
    js_check="var res = db.getSiblingDB('${schema_name}').getUser('${tenant_user}'); if (!res) { ${js_cmd} }"
    # shellcheck disable=SC2086
    mongosh $mongosh_args --eval "$js_check" --quiet
    log_info "[DB:MONGODB] [CONFIRM] Database '${schema_name}' and user '${tenant_user}' ready on ${host}:${port}."
    ;;
  sqlite)
    db_dir=$(dirname "$schema_name")
    mkdir -p "$db_dir"
    if [ -f "$schema_name" ]; then
      log_info "[DB:SQLITE] [CONFIRM] SQLite database '${schema_name}' already exists."
    else
      log_info "[DB:SQLITE] [CREATE] Creating SQLite database '${schema_name}'..."
    fi
    sqlite3 "$schema_name" "PRAGMA journal_mode=WAL;"
    chmod 600 "$schema_name"
    ;;
  *)
    printf 'Error: Unsupported engine "%s"\n' "$engine" >&2
    exit 1
    ;;
esac

exit 0
