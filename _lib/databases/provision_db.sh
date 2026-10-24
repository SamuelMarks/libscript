#!/bin/sh
# ## Overview
# Declarative database and cache provisioning engine for LibScript manifests.
# Initializes Postgres, MySQL/MariaDB, SQLite, DuckDB, and Valkey/Redis users/databases and exports connection URLs.
#
# ## Usage
# Run `provision_db.sh <libscript.json>` to provision declared databases and emit `.env.libscript`.

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

. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"

JSON_FILE="${1:-libscript.json}"
if [ ! -f "$JSON_FILE" ]; then
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

MANIFEST_DIR=$(cd -- "$(dirname -- "$JSON_FILE")" && pwd)
ENV_OUT="${MANIFEST_DIR}/.env.libscript"

DBS=$(jq -c '(.databases | if type == "object" then to_entries | map(.value + {name: (.value.name // .value.db_name // .key)}) elif type == "array" then map(. + {name: (.name // .db_name // .id)}) else [] end)[]?' "$JSON_FILE" 2>/dev/null || true)
if [ -z "$DBS" ]; then
  exit 0
fi

# ## set_env_var
# Idempotently sets or updates a KEY=VALUE pair in the target .env.libscript file.
set_env_var() {
  _key="$1"
  _val="$2"
  if [ -f "$ENV_OUT" ]; then
    _tmp_env=$(mktemp "${TMPDIR:-/tmp}/libscript_env.XXXXXX")
    grep -v "^${_key}=" "$ENV_OUT" > "$_tmp_env" 2>/dev/null || true
    mv "$_tmp_env" "$ENV_OUT"
  fi
  printf '%s=%s
' "$_key" "$_val" >> "$ENV_OUT"
}

printf '%s
' "$DBS" | while IFS= read -r db_entry; do
  [ -n "$db_entry" ] || continue
  ENGINE=$(printf '%s
' "$db_entry" | jq -r '(.engine // .type // "postgres") | ascii_downcase')
  DB_NAME=$(printf '%s
' "$db_entry" | jq -r '.name // .db_name // "app_db"')
  DB_USER=$(printf '%s
' "$db_entry" | jq -r '.user // .username // "postgres"')
  PASS_ENV=$(printf '%s
' "$db_entry" | jq -r '.password_env // empty')
  RAW_PASS=$(printf '%s
' "$db_entry" | jq -r '.password // empty')
  DB_HOST=$(printf '%s
' "$db_entry" | jq -r '.host // "127.0.0.1"')
  DB_PORT=$(printf '%s
' "$db_entry" | jq -r '.port // empty')
  ENV_VAR_NAME=$(printf '%s
' "$db_entry" | jq -r '.url_env // "DATABASE_URL"')

  DB_PASS="$RAW_PASS"
  if [ -z "$DB_PASS" ] && [ -n "$PASS_ENV" ]; then
    DB_PASS=$(printenv "$PASS_ENV" 2>/dev/null || true)
  fi
  if [ -z "$DB_PASS" ]; then
    DB_PASS="postgres"
  fi

  case "$ENGINE" in
    postgres|postgresql)
      : "${DB_PORT:=5432}"
      log_info "Provisioning PostgreSQL database '$DB_NAME' (user: '$DB_USER', host: $DB_HOST:$DB_PORT)..."
      if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/databases/postgres/cli.sh" ] && ! pg_isready -h "$DB_HOST" -p "$DB_PORT" >/dev/null 2>&1; then
        "${LIBSCRIPT_ROOT_DIR}/_lib/databases/postgres/cli.sh" start >/dev/null 2>&1 || true
      fi
      if command -v psql >/dev/null 2>&1; then
        export PGPASSWORD="${DB_PASS}"
        psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -tc "SELECT 1 FROM pg_roles WHERE rolname = '${DB_USER}'" 2>/dev/null | grep -q 1 || \
          psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -c "CREATE USER \"${DB_USER}\" WITH PASSWORD '${DB_PASS}';" >/dev/null 2>&1 || true
        psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'" 2>/dev/null | grep -q 1 || \
          psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -c "CREATE DATABASE \"${DB_NAME}\" OWNER \"${DB_USER}\";" >/dev/null 2>&1 || \
          createdb -h "$DB_HOST" -p "$DB_PORT" "$DB_NAME" >/dev/null 2>&1 || true
        psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE \"${DB_NAME}\" TO \"${DB_USER}\";" >/dev/null 2>&1 || true
      fi
      set_env_var "$ENV_VAR_NAME" "postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
      ;;
    mysql|mariadb)
      : "${DB_PORT:=3306}"
      log_info "Provisioning MySQL/MariaDB database '$DB_NAME' (user: '$DB_USER', host: $DB_HOST:$DB_PORT)..."
      if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/databases/mariadb/cli.sh" ]; then
        "${LIBSCRIPT_ROOT_DIR}/_lib/databases/mariadb/cli.sh" start >/dev/null 2>&1 || true
      fi
      if command -v mysql >/dev/null 2>&1; then
        mysql -h "$DB_HOST" -P "$DB_PORT" -u root -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME}; CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}'; GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%'; FLUSH PRIVILEGES;" >/dev/null 2>&1 || true
      fi
      set_env_var "$ENV_VAR_NAME" "mysql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
      ;;
    sqlite|sqlite3)
      DB_PATH=$(printf '%s
' "$db_entry" | jq -r '.path // .file // empty')
      if [ -z "$DB_PATH" ]; then
        DB_PATH="${MANIFEST_DIR}/data/${DB_NAME}.sqlite"
      elif [ "${DB_PATH#/}" = "$DB_PATH" ]; then
        DB_PATH="${MANIFEST_DIR}/${DB_PATH}"
      fi
      mkdir -p "$(dirname -- "$DB_PATH")"
      log_info "Provisioning SQLite database at '$DB_PATH'..."
      set_env_var "$ENV_VAR_NAME" "sqlite:///${DB_PATH}"
      set_env_var "SQLITE_PATH" "$DB_PATH"
      ;;
    duckdb)
      DB_PATH=$(printf '%s
' "$db_entry" | jq -r '.path // .file // empty')
      if [ -z "$DB_PATH" ]; then
        DB_PATH="${MANIFEST_DIR}/data/${DB_NAME}.duckdb"
      elif [ "${DB_PATH#/}" = "$DB_PATH" ]; then
        DB_PATH="${MANIFEST_DIR}/${DB_PATH}"
      fi
      mkdir -p "$(dirname -- "$DB_PATH")"
      log_info "Provisioning DuckDB database at '$DB_PATH'..."
      set_env_var "DUCKDB_PATH" "$DB_PATH"
      if [ "$ENV_VAR_NAME" != "DATABASE_URL" ]; then
        set_env_var "$ENV_VAR_NAME" "duckdb:///${DB_PATH}"
      fi
      ;;
    valkey|redis)
      : "${DB_PORT:=6379}"
      log_info "Provisioning Valkey/Redis cache endpoint ($DB_HOST:$DB_PORT)..."
      if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/caches/valkey/cli.sh" ]; then
        "${LIBSCRIPT_ROOT_DIR}/_lib/caches/valkey/cli.sh" start >/dev/null 2>&1 || true
      fi
      set_env_var "REDIS_URL" "redis://${DB_HOST}:${DB_PORT}/0"
      set_env_var "VALKEY_URL" "redis://${DB_HOST}:${DB_PORT}/0"
      ;;
  esac
done
