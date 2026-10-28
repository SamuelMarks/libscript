#!/bin/sh
# ## Overview
# Declarative database content and connectivity health verifier for LibScript manifests.
# Validates PostgreSQL, DuckDB, SQLite, and Valkey/Redis connectivity, table counts, required tables, row counts, and custom health commands.
#
# ## Usage
# Run `health_db.sh <libscript.json>` to verify declared databases are reachable and populated.

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

# shellcheck disable=SC1091
_ls_src_this="${THIS_FILE:-}"; _ls_src_dir="${SCRIPT_DIR:-}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true
[ -n "${_ls_src_this:-}" ] && THIS_FILE="$_ls_src_this"
[ -n "${_ls_src_dir:-}" ] && SCRIPT_DIR="$_ls_src_dir"

JSON_FILE='libscript.json'
REMEDIATE_DB=0
for _h_arg in "$@"; do
  case "$_h_arg" in
    --remediate) REMEDIATE_DB=1 ;;
    -*) ;;
    *) JSON_FILE="$_h_arg" ;;
  esac
done
if [ ! -f "$JSON_FILE" ]; then
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

MANIFEST_DIR=$(cd -- "$(dirname -- "$JSON_FILE")" && pwd)

if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_printer.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_printer.sh"
  # shellcheck disable=SC1090,SC1091
  . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_printer.sh"
  unset SCRIPT_NAME || true
  libscript_hydrate_manifest_env "$JSON_FILE" || true
else
  for _hdb_ef in "${MANIFEST_DIR}/.env" "${MANIFEST_DIR}/.env.secrets" "${MANIFEST_DIR}/.env.libscript"; do
    if [ -f "$_hdb_ef" ]; then
      set -a
      set +u
      # shellcheck disable=SC1090,SC1091
      . "$_hdb_ef" 2>/dev/null || true
      set -u
      set +a
    fi
  done
fi

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

# ## resolve_min_rows
# Determines the minimum required row count for a given table from the database entry JSON.
resolve_min_rows() {
  _rmr_entry="$1"
  _rmr_table="$2"
  _rmr_val=$(printf '%s\n' "$_rmr_entry" | jq -r --arg tbl "$_rmr_table" '
    if (.min_rows | type) == "number" then .min_rows
    elif (.min_rows | type) == "object" then (.min_rows[$tbl] // 1)
    else 1 end
  ' 2>/dev/null || printf '1')
  if [ -z "$_rmr_val" ] || [ "$_rmr_val" = "null" ]; then
    _rmr_val=1
  fi
  printf '%s\n' "$_rmr_val"
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

# ## query_duckdb_scalar
# Executes a scalar SQL query against a DuckDB database file using the duckdb CLI with WAL snapshot fallback.
query_duckdb_scalar() {
  _qds_path="$1"
  _qds_sql="$2"
  _qds_mode="${3:-scalar}"
  _qds_out=""
  if ensure_duckdb_cli; then
    if [ "$_qds_mode" = "len" ]; then
      _qds_out=$(duckdb "$_qds_path" -readonly -csv -noheader -c "$_qds_sql" 2>/dev/null | awk 'NF {c++} END {print c+0}')
    else
      _qds_out=$(duckdb "$_qds_path" -readonly -csv -noheader -c "$_qds_sql" 2>/dev/null | tr -d '[:space:]' | head -n 1 || true)
    fi
    if { [ -z "$_qds_out" ] || [ "$_qds_out" = "0" ]; } && [ -f "${_qds_path}.wal" ]; then
      _qds_tmp=$(mktemp -d 2>/dev/null || printf '%s' "${TMPDIR:-/tmp}/libscript_duckdb_hc.$$")
      mkdir -p "$_qds_tmp"
      _qds_snap="${_qds_tmp}/$(basename -- "$_qds_path")"
      cp -f "$_qds_path" "$_qds_snap" 2>/dev/null || true
      if [ -f "${_qds_path}.wal" ]; then
        cp -f "${_qds_path}.wal" "${_qds_snap}.wal" 2>/dev/null || true
      fi
      if [ "$_qds_mode" = "len" ]; then
        _qds_out=$(duckdb "$_qds_snap" -readonly -csv -noheader -c "$_qds_sql" 2>/dev/null | awk 'NF {c++} END {print c+0}')
      else
        _qds_out=$(duckdb "$_qds_snap" -readonly -csv -noheader -c "$_qds_sql" 2>/dev/null | tr -d '[:space:]' | head -n 1 || true)
      fi
      rm -rf "$_qds_tmp"
    fi
  fi
  printf '%s\n' "${_qds_out:-0}"
}

HEALTH_DB_FAILED=0

while IFS= read -r db_entry <&3; do
  [ -n "$db_entry" ] || continue
  ENGINE=$(printf '%s\n' "$db_entry" | jq -r '(.engine // .type // "postgres") | ascii_downcase')
  DB_NAME=$(printf '%s\n' "$db_entry" | jq -r '.name // .db_name // "app_db"')
  DB_USER=$(printf '%s\n' "$db_entry" | jq -r '.user // .username // "postgres"')
  PASS_ENV=$(printf '%s\n' "$db_entry" | jq -r '.password_env // empty')
  RAW_PASS=$(printf '%s\n' "$db_entry" | jq -r '.password // empty')
  DB_HOST=$(printf '%s\n' "$db_entry" | jq -r '.host // "127.0.0.1"')
  DB_PORT=$(printf '%s\n' "$db_entry" | jq -r '.port // empty')
  MIN_TABLES=$(printf '%s\n' "$db_entry" | jq -r 'if .min_tables != null then .min_tables elif .require_populated == true then 1 else empty end' 2>/dev/null || true)
  REQ_TABLES=$(printf '%s\n' "$db_entry" | jq -r '.required_tables[]?' 2>/dev/null || true)
  HEALTH_CMD=$(printf '%s\n' "$db_entry" | jq -r '.health_command // empty' 2>/dev/null || true)
  HEALTH_CMD=$(expand_manifest_vars "$HEALTH_CMD")

  DB_PASS="$RAW_PASS"
  if [ -z "$DB_PASS" ] && [ -n "$PASS_ENV" ]; then
    DB_PASS=$(printenv "$PASS_ENV" 2>/dev/null || true)
  fi
  if [ -z "$DB_PASS" ]; then
    DB_PASS='postgres'
  fi

  case "$ENGINE" in
    postgres|postgresql)
      : "${DB_PORT:=5432}"
      if command -v psql >/dev/null 2>&1; then
        export PGPASSWORD="${DB_PASS}"
        if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tc "SELECT 1;" >/dev/null 2>&1; then
          log_error "PostgreSQL health check failed: cannot connect to database '$DB_NAME' on ${DB_HOST}:${DB_PORT} as '$DB_USER'."
          HEALTH_DB_FAILED=1
        else
          PG_TBL_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -Atc "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';" 2>/dev/null | tr -d '[:space:]' || printf '0')
          : "${PG_TBL_COUNT:=0}"
          if [ -n "$MIN_TABLES" ]; then
            if [ "$PG_TBL_COUNT" -lt "$MIN_TABLES" ] 2>/dev/null; then
              log_error "PostgreSQL database '$DB_NAME' has $PG_TBL_COUNT tables (expected >= $MIN_TABLES)."
              HEALTH_DB_FAILED=1
            fi
          fi
          _pg_tbl_summary=""
          if [ -n "$REQ_TABLES" ]; then
            while IFS= read -r req_tbl; do
              [ -n "$req_tbl" ] || continue
              MIN_ROWS_REQ=$(resolve_min_rows "$db_entry" "$req_tbl")
              _sql_q='SELECT count(*) FROM "'"$req_tbl"'";'
              PG_ROW_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -Atc "$_sql_q" 2>/dev/null | tr -d '[:space:]' || printf '%s' "-1")
              if [ -z "$PG_ROW_COUNT" ] || [ "$PG_ROW_COUNT" -lt "$MIN_ROWS_REQ" ] 2>/dev/null; then
                log_error "PostgreSQL database '$DB_NAME' required table '$req_tbl' missing or has insufficient rows (${PG_ROW_COUNT:-0} < $MIN_ROWS_REQ)."
                HEALTH_DB_FAILED=1
              else
                _pg_tbl_summary="${_pg_tbl_summary:+$_pg_tbl_summary, }${req_tbl}=${PG_ROW_COUNT} rows"
              fi
            done << EOF_PG_REQ
$REQ_TABLES
EOF_PG_REQ
          fi
          log_info "[DB:POSTGRES] [CONFIRM] Database '$DB_NAME' healthy (${PG_TBL_COUNT} table(s)${_pg_tbl_summary:+: $_pg_tbl_summary})."
        fi
      fi
      ;;
    duckdb)
      DB_PATH=$(printf '%s\n' "$db_entry" | jq -r '.path // .file // .db_path // empty')
      DB_PATH=$(expand_manifest_vars "$DB_PATH")
      if [ -z "$DB_PATH" ]; then
        if [ -f "/mnt/data/${DB_NAME}.duckdb" ]; then
          DB_PATH="/mnt/data/${DB_NAME}.duckdb"
        else
          DB_PATH="${MANIFEST_DIR}/data/${DB_NAME}.duckdb"
        fi
      elif [ "${DB_PATH#/}" = "$DB_PATH" ]; then
        DB_PATH="${MANIFEST_DIR}/${DB_PATH}"
      fi
      if [ ! -s "$DB_PATH" ]; then
        log_error "DuckDB database file '$DB_PATH' does not exist or is empty."
        HEALTH_DB_FAILED=1
      else
        DUCK_TBL_COUNT=$(query_duckdb_scalar "$DB_PATH" "SHOW TABLES;" "len" || printf '0')
        : "${DUCK_TBL_COUNT:=0}"
        if [ -n "$MIN_TABLES" ]; then
          if [ "$DUCK_TBL_COUNT" -lt "$MIN_TABLES" ] 2>/dev/null; then
            log_error "DuckDB database '$DB_PATH' has $DUCK_TBL_COUNT tables (expected >= $MIN_TABLES)."
            HEALTH_DB_FAILED=1
          fi
        fi
        _duck_tbl_summary=""
        if [ -n "$REQ_TABLES" ]; then
          while IFS= read -r req_tbl; do
            [ -n "$req_tbl" ] || continue
            MIN_ROWS_REQ=$(resolve_min_rows "$db_entry" "$req_tbl")
            _sql_q='SELECT COUNT(*) FROM "'"$req_tbl"'";'
            DUCK_ROW_COUNT=$(query_duckdb_scalar "$DB_PATH" "$_sql_q" "scalar" || printf '%s' "-1")
            if [ -z "$DUCK_ROW_COUNT" ] || [ "$DUCK_ROW_COUNT" -lt "$MIN_ROWS_REQ" ] 2>/dev/null; then
              log_error "DuckDB database '$DB_PATH' required table '$req_tbl' missing or has insufficient rows (${DUCK_ROW_COUNT:-0} < $MIN_ROWS_REQ)."
              HEALTH_DB_FAILED=1
            else
              _duck_tbl_summary="${_duck_tbl_summary:+$_duck_tbl_summary, }${req_tbl}=${DUCK_ROW_COUNT} rows"
            fi
          done << EOF_DUCK_REQ
$REQ_TABLES
EOF_DUCK_REQ
        fi
        log_info "[DB:DUCKDB] [CONFIRM] DuckDB '$DB_PATH' healthy (${DUCK_TBL_COUNT} table(s)${_duck_tbl_summary:+: $_duck_tbl_summary})."
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
      if [ ! -f "$DB_PATH" ]; then
        log_error "SQLite database file '$DB_PATH' does not exist."
        HEALTH_DB_FAILED=1
      elif command -v sqlite3 >/dev/null 2>&1; then
        SQLITE_TBL_COUNT=$(sqlite3 "$DB_PATH" "SELECT count(*) FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';" 2>/dev/null | tr -d '[:space:]' || printf '0')
        : "${SQLITE_TBL_COUNT:=0}"
        if [ -n "$MIN_TABLES" ]; then
          if [ "$SQLITE_TBL_COUNT" -lt "$MIN_TABLES" ] 2>/dev/null; then
            log_error "SQLite database '$DB_PATH' has $SQLITE_TBL_COUNT tables (expected >= $MIN_TABLES)."
            HEALTH_DB_FAILED=1
          fi
        fi
        _sqlite_tbl_summary=""
        if [ -n "$REQ_TABLES" ]; then
          while IFS= read -r req_tbl; do
            [ -n "$req_tbl" ] || continue
            MIN_ROWS_REQ=$(resolve_min_rows "$db_entry" "$req_tbl")
            _sql_q='SELECT count(*) FROM "'"$req_tbl"'";'
            SQLITE_ROW_COUNT=$(sqlite3 "$DB_PATH" "$_sql_q" 2>/dev/null | tr -d '[:space:]' || printf '%s' "-1")
            if [ -z "$SQLITE_ROW_COUNT" ] || [ "$SQLITE_ROW_COUNT" -lt "$MIN_ROWS_REQ" ] 2>/dev/null; then
              log_error "SQLite database '$DB_PATH' required table '$req_tbl' missing or has insufficient rows (${SQLITE_ROW_COUNT:-0} < $MIN_ROWS_REQ)."
              HEALTH_DB_FAILED=1
            else
              _sqlite_tbl_summary="${_sqlite_tbl_summary:+$_sqlite_tbl_summary, }${req_tbl}=${SQLITE_ROW_COUNT} rows"
            fi
          done << EOF_SQLITE_REQ
$REQ_TABLES
EOF_SQLITE_REQ
        fi
        log_info "[DB:SQLITE] [CONFIRM] SQLite '$DB_PATH' healthy (${SQLITE_TBL_COUNT} table(s)${_sqlite_tbl_summary:+: $_sqlite_tbl_summary})."
      fi
      ;;
    valkey|redis)
      : "${DB_PORT:=6379}"
      DB_IDX=$(printf '%s\n' "$db_entry" | jq -r '.db_index // .database // 0' 2>/dev/null || printf '0')
      [ -z "$DB_IDX" ] || [ "$DB_IDX" = "null" ] && DB_IDX="0"
      _vk_ok=0
      for _vk_cli in valkey-cli redis-cli; do
        if command -v "$_vk_cli" >/dev/null 2>&1; then
          if "$_vk_cli" -h "$DB_HOST" -p "$DB_PORT" -n "$DB_IDX" ping 2>/dev/null | grep -qi "PONG"; then
            _vk_ok=1
            log_info "[DB:VALKEY] [CONFIRM] Valkey/Redis endpoint ${DB_HOST}:${DB_PORT} (db ${DB_IDX}) healthy."
            break
          fi
        fi
      done
      if [ "$_vk_ok" -eq 0 ] && ! command -v valkey-cli >/dev/null 2>&1 && ! command -v redis-cli >/dev/null 2>&1; then
        _vk_ok=1
      fi
      if [ "$_vk_ok" -eq 0 ]; then
        log_error "Valkey/Redis health check failed: no PONG response on ${DB_HOST}:${DB_PORT} (db ${DB_IDX})."
        HEALTH_DB_FAILED=1
      fi
      ;;
  esac

  if [ -n "$HEALTH_CMD" ]; then
    log_info "Executing database health command for '$DB_NAME': $HEALTH_CMD"
    if ! (cd "$MANIFEST_DIR" && sh -c "$HEALTH_CMD"); then
      log_error "Database health_command failed for '$DB_NAME': $HEALTH_CMD"
      HEALTH_DB_FAILED=1
    fi
  fi
done 3<< EOF_DBS
$DBS
EOF_DBS

if [ "$HEALTH_DB_FAILED" -ne 0 ]; then
  if [ "$REMEDIATE_DB" -eq 1 ] && [ "${_HDB_REMEDIATING:-0}" != "1" ]; then
    log_info 'Database health check failed; stopping active services and attempting auto-remediation via provision_db.sh...'
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/daemonize.sh" ]; then
      STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/daemonize.sh" stop "$JSON_FILE" || true
    fi
    LIBSCRIPT_FORCE_SEED=1 "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_db.sh" "$JSON_FILE" || true
    "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/run_hooks.sh" "$JSON_FILE" "db_migrate" || true
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/daemonize.sh" ]; then
      STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/daemonize.sh" start "$JSON_FILE" || true
    fi
    _HDB_REMEDIATING=1 STACK="" exec "${THIS_FILE}" "$JSON_FILE"
  fi
  exit 1
fi
exit 0
