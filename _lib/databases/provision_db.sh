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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

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

if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_printer.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_printer.sh"
  # shellcheck disable=SC1090,SC1091
  . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_printer.sh"
  unset SCRIPT_NAME || true
  libscript_hydrate_manifest_env "$JSON_FILE" || true
  for _pdb_sub_ef in "${MANIFEST_DIR}"/*/.env; do
    [ -f "$_pdb_sub_ef" ] && libscript_source_env_preserve_existing "$_pdb_sub_ef"
  done
else
  for _pdb_ef in "${MANIFEST_DIR}/.env" "${MANIFEST_DIR}/.env.secrets" "${MANIFEST_DIR}/.env.libscript"; do
    if [ -f "$_pdb_ef" ]; then
      set -a
      set +u
      # shellcheck disable=SC1090,SC1091
      . "$_pdb_ef" 2>/dev/null || true
      set -u
      set +a
    fi
  done
fi

if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/python_env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/python_env.sh"
  # shellcheck disable=SC1090,SC1091
  . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/python_env.sh"
  unset SCRIPT_NAME || true
fi

# ## ensure_manifest_python_venvs
# Ensures Python virtual environments exist in MANIFEST_DIR and immediate subdirectories before running seed_command.
ensure_manifest_python_venvs() {
  _emp_py_ver=$(jq -r '(.deps.python // .dependencies.python // (.dependencies.runtime[]? | select(.name=="python") | .version) // "3.12")' "$JSON_FILE" 2>/dev/null | head -n 1 || printf '3.12')
  [ -z "$_emp_py_ver" ] || [ "$_emp_py_ver" = "null" ] && _emp_py_ver="3.12"
  _emp_user="${SVC_OWNER_USER:-${SERVICE_USER:-${REMOTE_USER:-${SUDO_USER:-}}}}"
  _emp_home="${REMOTE_HOME:-}"
  if [ -n "$_emp_user" ] && [ -z "$_emp_home" ]; then
    if [ -r "/etc/passwd" ]; then
      _emp_home=$(awk -F: -v u="$_emp_user" '$1==u {print $6; exit}' /etc/passwd 2>/dev/null || true)
    fi
    if [ -z "$_emp_home" ] && [ -d "/home/${_emp_user}" ]; then
      _emp_home="/home/${_emp_user}"
    fi
  fi
  if [ -n "$_emp_home" ] && [ -d "$_emp_home" ]; then
    export UV_PYTHON_INSTALL_DIR="${_emp_home}/.local/share/uv/python"
    export UV_CACHE_DIR="${_emp_home}/.cache/uv"
  fi
  for _emp_proj in "$MANIFEST_DIR" "$MANIFEST_DIR"/*; do
    [ -d "$_emp_proj" ] || continue
    if [ -f "${_emp_proj}/pyproject.toml" ] || [ -f "${_emp_proj}/requirements.txt" ]; then
      if [ -L "${_emp_proj}/.venv/bin/python" ] || [ -L "${_emp_proj}/.venv/bin/python3" ]; then
        _emp_py_target=$(readlink -f "${_emp_proj}/.venv/bin/python3" 2>/dev/null || readlink "${_emp_proj}/.venv/bin/python3" 2>/dev/null || true)
        case "$_emp_py_target" in
          /root/*)
            if [ -n "$_emp_user" ] && [ "$_emp_user" != "root" ]; then
              rm -rf "${_emp_proj}/.venv"
            fi
            ;;
        esac
      fi
      if [ ! -x "${_emp_proj}/.venv/bin/python" ]; then
        if command -v uv >/dev/null 2>&1; then
          if type libscript_python_venv >/dev/null 2>&1; then
            HOME="${_emp_home:-${HOME:-/root}}" LIBSCRIPT_PYTHON_VENV_BACKEND=uv libscript_python_venv "${_emp_proj}/.venv" "$_emp_py_ver" 2>/dev/null || true
          fi
          (cd "$_emp_proj" && HOME="${_emp_home:-${HOME:-/root}}" uv sync --python "$_emp_py_ver" 2>/dev/null || HOME="${_emp_home:-${HOME:-/root}}" uv sync 2>/dev/null || true)
        elif type libscript_python_venv >/dev/null 2>&1; then
          libscript_python_venv "${_emp_proj}/.venv" "$_emp_py_ver" 2>/dev/null || true
        fi
      fi
      if [ -n "$_emp_user" ] && id "$_emp_user" >/dev/null 2>&1 && [ -d "${_emp_proj}/.venv" ]; then
        chown -R "${_emp_user}:${SERVICE_GROUP:-${REMOTE_GROUP:-$_emp_user}}" "${_emp_proj}/.venv" "${_emp_home:-/home/$_emp_user}/.local" "${_emp_home:-/home/$_emp_user}/.cache" 2>/dev/null || true
      fi
    fi
  done
}

# ## expand_manifest_vars
# Expands ${VAR:-default}, ${VAR}, and $VAR environment references inside a manifest string value.
expand_manifest_vars() {
  if type libscript_expand_manifest_vars >/dev/null 2>&1; then
    libscript_expand_manifest_vars "${1:-}"
  else
    printf '%s\n' "${1:-}"
  fi
}

DBS=$(jq -c '((.databases // .infrastructure.databases) | if type == "object" then to_entries | map(.value + {name: (.value.name // .value.db_name // .key)}) elif type == "array" then map(. + {name: (.name // .db_name // .id)}) else [] end)[]?' "$JSON_FILE" 2>/dev/null || true)
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
    cat "$_tmp_env" > "$ENV_OUT"
    rm -f "$_tmp_env"
  fi
  printf '%s=%s\n' "$_key" "$_val" >> "$ENV_OUT"
  chmod 0644 "$ENV_OUT" 2>/dev/null || true
  if [ -n "${SVC_OWNER_USER:-}" ] && id "$SVC_OWNER_USER" >/dev/null 2>&1; then
    chown "$SVC_OWNER_USER" "$ENV_OUT" 2>/dev/null || true
  fi
  export "${_key}=${_val}"
}

# ## resolve_db_asset_path
# Resolves a file or directory path relative to MANIFEST_DIR when not absolute.
resolve_db_asset_path() {
  _rap="$1"
  if [ -z "$_rap" ]; then
    return 0
  elif [ "${_rap#/}" != "$_rap" ]; then
    printf '%s\n' "$_rap"
  else
    printf '%s\n' "${MANIFEST_DIR}/${_rap}"
  fi
}

# ## ensure_duckdb_cli
# Ensures the duckdb binary is available in PATH by sourcing _lib/databases/duckdb/env.sh or installing it.
ensure_duckdb_cli() {
  if command -v duckdb >/dev/null 2>&1; then
    return 0
  fi
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/databases/duckdb/env.sh" ]; then
    STACK=""
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/databases/duckdb/env.sh"
    # shellcheck disable=SC1090,SC1091
    . "${LIBSCRIPT_ROOT_DIR}/_lib/databases/duckdb/env.sh" || true
    unset SCRIPT_NAME || true
  fi
  if ! command -v duckdb >/dev/null 2>&1 && [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/databases/duckdb/cli.sh" ]; then
    "${LIBSCRIPT_ROOT_DIR}/_lib/databases/duckdb/cli.sh" install latest >/dev/null 2>&1 || true
  fi
  command -v duckdb >/dev/null 2>&1
}

# ## exec_duckdb_sql_file
# Executes a SQL file against a DuckDB database using the duckdb CLI.
exec_duckdb_sql_file() {
  _eds_db="$1"
  _eds_sql_file="$2"
  if ensure_duckdb_cli; then
    duckdb "$_eds_db" < "$_eds_sql_file" >/dev/null 2>&1
  fi
}

# ## import_duckdb_table_file
# Imports a CSV or Parquet file into DuckDB as a table matching the filename stem.
import_duckdb_table_file() {
  _import_db="$1"
  _import_file="$2"
  _import_base=$(basename -- "$_import_file")
  _import_tbl="${_import_base%.*}"
  _import_sql="CREATE TABLE IF NOT EXISTS \"${_import_tbl}\" AS SELECT * FROM '${_import_file}';"
  if ensure_duckdb_cli; then
    duckdb "$_import_db" -c "$_import_sql" >/dev/null 2>&1
  fi
}

SVC_OWNER_USER=$(jq -r '((.services // .infrastructure.services) | if type == "object" then [to_entries[].value] elif type == "array" then . else [] end) | .[0].user // empty' "$JSON_FILE" 2>/dev/null || true)
SVC_OWNER_USER=$(expand_manifest_vars "$SVC_OWNER_USER")
if [ -z "$SVC_OWNER_USER" ]; then
  SVC_OWNER_USER="${SERVICE_USER:-${REMOTE_USER:-${SUDO_USER:-${ADMIN_USER:-}}}}"
fi

while IFS= read -r db_entry <&3; do
  [ -n "$db_entry" ] || continue
  ENGINE=$(printf '%s\n' "$db_entry" | jq -r '(.engine // .type // "postgres") | ascii_downcase')
  DB_NAME=$(printf '%s\n' "$db_entry" | jq -r '.name // .db_name // "app_db"')
  DB_USER=$(printf '%s\n' "$db_entry" | jq -r '.user // .username // "postgres"')
  PASS_ENV=$(printf '%s\n' "$db_entry" | jq -r '.password_env // empty')
  RAW_PASS=$(printf '%s\n' "$db_entry" | jq -r '.password // empty')
  DB_HOST=$(printf '%s\n' "$db_entry" | jq -r '.host // "127.0.0.1"')
  DB_PORT=$(printf '%s\n' "$db_entry" | jq -r '.port // empty')
  ENV_VAR_NAME=$(printf '%s\n' "$db_entry" | jq -r '.url_env // "DATABASE_URL"')
  SEED_FILE=$(printf '%s\n' "$db_entry" | jq -r '.seed_file // empty')
  SEED_DIR=$(printf '%s\n' "$db_entry" | jq -r '.seed_dir // empty')
  MIGRATION_DIR=$(printf '%s\n' "$db_entry" | jq -r '.migration_dir // empty')
  SEED_CMD=$(printf '%s\n' "$db_entry" | jq -r '.seed_command // empty')
  SEED_CMD=$(expand_manifest_vars "$SEED_CMD")

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
      set_env_var "$ENV_VAR_NAME" "postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
      if command -v psql >/dev/null 2>&1; then
        if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_schema.sh" ]; then
          env -u SCRIPT_NAME -u STACK "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_schema.sh" \
            --engine postgres --host "$DB_HOST" --port "$DB_PORT" \
            --admin-user postgres --admin-pass "$DB_PASS" \
            --schema "$DB_NAME" --user "$DB_USER" --password "$DB_PASS" >/dev/null 2>&1 || true
        fi
        export PGPASSWORD="${DB_PASS}"
        psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -c "ALTER USER \"${DB_USER}\" WITH PASSWORD '${DB_PASS}';" >/dev/null 2>&1 || \
          su - postgres -c "psql -c \"ALTER USER \\\"${DB_USER}\\\" WITH PASSWORD '${DB_PASS}';\"" >/dev/null 2>&1 || true
        psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'" 2>/dev/null | grep -q 1 || \
          su - postgres -c "psql -c \"CREATE DATABASE \\\"${DB_NAME}\\\" OWNER \\\"${DB_USER}\\\";\"" >/dev/null 2>&1 || \
          createdb -h "$DB_HOST" -p "$DB_PORT" "$DB_NAME" >/dev/null 2>&1 || true

        if [ -n "$MIGRATION_DIR" ]; then
          RES_MIG_DIR=$(resolve_db_asset_path "$MIGRATION_DIR")
          if [ -d "$RES_MIG_DIR" ]; then
            for _mig_sql in "$RES_MIG_DIR"/*.sql; do
              [ -f "$_mig_sql" ] || continue
              psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$_mig_sql" >/dev/null 2>&1 || true
            done
          fi
        fi
        if [ -n "$SEED_FILE" ]; then
          RES_SEED_FILE=$(resolve_db_asset_path "$SEED_FILE")
          if [ -f "$RES_SEED_FILE" ]; then
            psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$RES_SEED_FILE" >/dev/null 2>&1 || true
          fi
        fi
      fi
      if [ -n "$SEED_CMD" ]; then
        ensure_manifest_python_venvs
        log_info "Running PostgreSQL seed_command for '$DB_NAME': $SEED_CMD"
        (cd "$MANIFEST_DIR" && sh -c "$SEED_CMD")
      fi
      ;;
    mysql|mariadb)
      : "${DB_PORT:=3306}"
      log_info "Provisioning MySQL/MariaDB database '$DB_NAME' (user: '$DB_USER', host: $DB_HOST:$DB_PORT)..."
      if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/databases/mariadb/cli.sh" ]; then
        "${LIBSCRIPT_ROOT_DIR}/_lib/databases/mariadb/cli.sh" start >/dev/null 2>&1 || true
      fi
      if command -v mysql >/dev/null 2>&1 && [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_schema.sh" ]; then
        env -u SCRIPT_NAME -u STACK "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_schema.sh" \
          --engine mysql --host "$DB_HOST" --port "$DB_PORT" \
          --admin-user root --schema "$DB_NAME" --user "$DB_USER" --password "$DB_PASS" >/dev/null 2>&1 || true
      fi
      set_env_var "$ENV_VAR_NAME" "mysql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
      if [ -n "$SEED_CMD" ]; then
        ensure_manifest_python_venvs
        log_info "Running MySQL/MariaDB seed_command for '$DB_NAME': $SEED_CMD"
        (cd "$MANIFEST_DIR" && sh -c "$SEED_CMD")
      fi
      ;;
    sqlite|sqlite3)
      DB_PATH=$(printf '%s\n' "$db_entry" | jq -r '.path // .file // .db_path // empty')
      DB_PATH=$(expand_manifest_vars "$DB_PATH")
      if [ -z "$DB_PATH" ]; then
        DB_PATH="${MANIFEST_DIR}/data/${DB_NAME}.sqlite"
      elif [ "${DB_PATH#/}" = "$DB_PATH" ]; then
        DB_PATH="${MANIFEST_DIR}/${DB_PATH}"
      fi
      mkdir -p "$(dirname -- "$DB_PATH")"
      log_info "Provisioning SQLite database at '$DB_PATH'..."
      if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_schema.sh" ] && command -v sqlite3 >/dev/null 2>&1; then
        env -u SCRIPT_NAME -u STACK "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_schema.sh" \
          --engine sqlite --schema "$DB_PATH" --user "$DB_USER" --password "$DB_PASS" >/dev/null 2>&1 || true
      fi
      set_env_var "$ENV_VAR_NAME" "sqlite:///${DB_PATH}"
      set_env_var "SQLITE_PATH" "$DB_PATH"
      if [ -n "$SEED_FILE" ] && command -v sqlite3 >/dev/null 2>&1; then
        RES_SEED_FILE=$(resolve_db_asset_path "$SEED_FILE")
        if [ -f "$RES_SEED_FILE" ]; then
          sqlite3 "$DB_PATH" < "$RES_SEED_FILE" >/dev/null 2>&1 || true
        fi
      fi
      if [ -n "$SEED_CMD" ]; then
        ensure_manifest_python_venvs
        log_info "Running SQLite seed_command for '$DB_NAME': $SEED_CMD"
        (cd "$MANIFEST_DIR" && sh -c "$SEED_CMD")
      fi
      ;;
    duckdb)
      DB_PATH=$(printf '%s\n' "$db_entry" | jq -r '.path // .file // .db_path // empty')
      DB_PATH=$(expand_manifest_vars "$DB_PATH")
      if [ -z "$DB_PATH" ]; then
        if [ -d "/mnt/data" ] && [ -w "/mnt/data" ]; then
          DB_PATH="/mnt/data/${DB_NAME}.duckdb"
        else
          DB_PATH="${MANIFEST_DIR}/data/${DB_NAME}.duckdb"
        fi
      elif [ "${DB_PATH#/}" = "$DB_PATH" ]; then
        DB_PATH="${MANIFEST_DIR}/${DB_PATH}"
      fi
      DB_PARENT_DIR=$(dirname -- "$DB_PATH")
      mkdir -p "$DB_PARENT_DIR"
      log_info "Provisioning DuckDB database at '$DB_PATH'..."
      PATH_ENV_VAR=$(printf '%s\n' "$db_entry" | jq -r '.path_env // .env_var // "DUCKDB_PATH"')
      set_env_var "$PATH_ENV_VAR" "$DB_PATH"
      if [ "$PATH_ENV_VAR" != "DUCKDB_PATH" ]; then
        set_env_var "DUCKDB_PATH" "$DB_PATH"
      fi
      if [ "$ENV_VAR_NAME" != "DATABASE_URL" ]; then
        set_env_var "$ENV_VAR_NAME" "duckdb:///${DB_PATH}"
      fi
      if [ ! -s "$DB_PATH" ]; then
        if ensure_duckdb_cli; then
          duckdb "$DB_PATH" -c "SELECT 1;" >/dev/null 2>&1 || true
        fi
      fi
      if [ -n "$SEED_FILE" ]; then
        RES_SEED_FILE=$(resolve_db_asset_path "$SEED_FILE")
        if [ -f "$RES_SEED_FILE" ]; then
          exec_duckdb_sql_file "$DB_PATH" "$RES_SEED_FILE" || true
        fi
      fi
      if [ -n "$SEED_DIR" ]; then
        RES_SEED_DIR=$(resolve_db_asset_path "$SEED_DIR")
        if [ -d "$RES_SEED_DIR" ]; then
          for _sd_item in "$RES_SEED_DIR"/*; do
            [ -f "$_sd_item" ] || continue
            case "$_sd_item" in
              *.sql) exec_duckdb_sql_file "$DB_PATH" "$_sd_item" || true ;;
              *.csv|*.parquet) import_duckdb_table_file "$DB_PATH" "$_sd_item" || true ;;
            esac
          done
        fi
      fi
      if [ -n "$SEED_CMD" ]; then
        ensure_manifest_python_venvs
        log_info "Running DuckDB seed_command for '$DB_NAME': $SEED_CMD"
        (cd "$MANIFEST_DIR" && sh -c "$SEED_CMD")
      fi
      DB_OWNER=$(printf '%s\n' "$db_entry" | jq -r '.user // empty')
      DB_OWNER=$(expand_manifest_vars "$DB_OWNER")
      if [ -z "$DB_OWNER" ] || [ "$DB_OWNER" = "postgres" ]; then
        DB_OWNER="$SVC_OWNER_USER"
      fi
      if [ -n "$DB_OWNER" ] && id "$DB_OWNER" >/dev/null 2>&1; then
        for _own_target in "$DB_PARENT_DIR" "$DB_PATH" "${DB_PATH}.wal" "${T1D_SESSIONS_DB_PATH:-}" "${MANIFEST_DIR}/data"; do
          if [ -n "$_own_target" ] && [ -e "$_own_target" ]; then
            chown -R "$DB_OWNER" "$_own_target" 2>/dev/null || sudo chown -R "$DB_OWNER" "$_own_target" 2>/dev/null || true
            chmod -R u+rwX,go+rX "$_own_target" 2>/dev/null || sudo chmod -R u+rwX,go+rX "$_own_target" 2>/dev/null || true
          fi
        done
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
done 3<< EOF_DBS
$DBS
EOF_DBS
