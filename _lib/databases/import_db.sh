#!/bin/sh
# ## Overview
# Manifest-driven application state importer for LibScript.
# Stops declared services, restores PostgreSQL SQL dumps, DuckDB/SQLite database files,
# and configuration `.env` files from a staging directory, normalizes ownership, and restarts services.
#
# ## Usage
# ./_lib/databases/import_db.sh <libscript.json> <stage_dir>

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
. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"

JSON_FILE="${1:-libscript.json}"
STAGE_DIR="${2:-/tmp/libscript_import_stage}"

if [ ! -f "$JSON_FILE" ] || ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

MANIFEST_DIR=$(cd -- "$(dirname -- "$JSON_FILE")" && pwd)
APP_NAME=$(jq -r '.name // empty' "$JSON_FILE" 2>/dev/null || true)
[ -n "$APP_NAME" ] || APP_NAME=$(basename "$MANIFEST_DIR")

APP_STAGE="${STAGE_DIR}/${APP_NAME}"
if [ ! -d "$APP_STAGE" ] && [ -d "$STAGE_DIR" ]; then
  APP_STAGE="$STAGE_DIR"
fi

if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_printer.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_printer.sh"
  # shellcheck disable=SC1090
  . "$SCRIPT_NAME"
  unset SCRIPT_NAME || true
  libscript_hydrate_manifest_env "$JSON_FILE" || true
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

"${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/daemonize.sh" stop "$JSON_FILE" >/dev/null 2>&1 || true

for _cfg_f in env env.secrets env.libscript; do
  if [ -f "${APP_STAGE}/config/${_cfg_f}" ]; then
    cp -f "${APP_STAGE}/config/${_cfg_f}" "${MANIFEST_DIR}/.${_cfg_f}"
  fi
done

DBS=$(jq -c '((.databases // .infrastructure.databases) | if type == "object" then to_entries | map(.value + {name: (.value.name // .value.db_name // .key)}) elif type == "array" then map(. + {name: (.name // .db_name // .id)}) else [] end)[]?' "$JSON_FILE" 2>/dev/null || true)

while IFS= read -r db_entry <&3; do
  [ -n "$db_entry" ] || continue
  ENGINE=$(printf '%s\n' "$db_entry" | jq -r '(.engine // .type // "postgres") | ascii_downcase')
  DB_NAME=$(printf '%s\n' "$db_entry" | jq -r '.name // .db_name // "app_db"')
  DB_USER=$(printf '%s\n' "$db_entry" | jq -r '.user // .username // "postgres"')
  DB_HOST=$(printf '%s\n' "$db_entry" | jq -r '.host // "127.0.0.1"')
  DB_PORT=$(printf '%s\n' "$db_entry" | jq -r '.port // "5432"')
  PASS_ENV=$(printf '%s\n' "$db_entry" | jq -r '.password_env // empty')
  RAW_PASS=$(printf '%s\n' "$db_entry" | jq -r '.password // empty')
  DB_PASS="$RAW_PASS"
  if [ -z "$DB_PASS" ] && [ -n "$PASS_ENV" ]; then
    DB_PASS=$(printenv "$PASS_ENV" 2>/dev/null || true)
  fi
  [ -n "$DB_PASS" ] || DB_PASS="postgres"

  case "$ENGINE" in
    postgres|postgresql)
      if command -v psql >/dev/null 2>&1; then
        _dump_file=""
        for _cand_sql in "${APP_STAGE}/postgres/${DB_NAME}.sql" "${STAGE_DIR}/postgres/${DB_NAME}.sql" "${STAGE_DIR}/postgres/"*.sql; do
          if [ -f "$_cand_sql" ]; then
            _dump_file="$_cand_sql"
            break
          fi
        done
        if [ -n "$_dump_file" ]; then
          _targets="$DB_NAME $(printf '%s\n' "$db_entry" | jq -r '.legacy_names[]? // empty' 2>/dev/null | tr '\n' ' ')"
          for _t_db in $_targets; do
            [ -n "$_t_db" ] || continue
            log_info "Importing PostgreSQL dump '$_dump_file' into '$_t_db'..."
            PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -tc "SELECT 1 FROM pg_database WHERE datname = '$_t_db'" 2>/dev/null | grep -q 1 || \
              PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -c "CREATE DATABASE \"$_t_db\";" 2>/dev/null || \
              sudo -u postgres psql -c "CREATE DATABASE \"$_t_db\";" 2>/dev/null || true
            PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$_t_db" -f "$_dump_file" >/dev/null 2>&1 || \
              sudo -u postgres psql -d "$_t_db" -f "$_dump_file" >/dev/null 2>&1 || true
          done
        fi
      fi
      ;;
    duckdb|sqlite|sqlite3)
      DB_PATH=$(printf '%s\n' "$db_entry" | jq -r '.path // .file // .db_path // empty')
      DB_PATH=$(expand_manifest_vars "$DB_PATH")
      if [ -z "$DB_PATH" ]; then
        DB_PATH="/mnt/data/${DB_NAME}.duckdb"
      elif [ "${DB_PATH#/}" = "$DB_PATH" ]; then
        DB_PATH="${MANIFEST_DIR}/${DB_PATH}"
      fi
      _base_db=$(basename "$DB_PATH")
      _src_db=""
      for _cand_duck in "${APP_STAGE}/duckdb/${_base_db}" "${STAGE_DIR}/duckdb/${_base_db}"; do
        if [ -f "$_cand_duck" ]; then
          _src_db="$_cand_duck"
          break
        fi
      done
      if [ -n "$_src_db" ]; then
        log_info "Importing $ENGINE file '$_src_db' -> '$DB_PATH'..."
        mkdir -p "$(dirname -- "$DB_PATH")" 2>/dev/null || sudo mkdir -p "$(dirname -- "$DB_PATH")" 2>/dev/null || true
        rm -f "${DB_PATH}.wal" "${DB_PATH}.shm" 2>/dev/null || sudo rm -f "${DB_PATH}.wal" "${DB_PATH}.shm" 2>/dev/null || true
        cp -f "$_src_db" "$DB_PATH" 2>/dev/null || sudo cp -f "$_src_db" "$DB_PATH"
        _extra_paths=$(printf '%s\n' "$db_entry" | jq -r '.fallback_paths[]? // .extra_paths[]? // empty' 2>/dev/null || true)
        if [ -n "$_extra_paths" ]; then
          printf '%s\n' "$_extra_paths" | while IFS= read -r _ep; do
            [ -n "$_ep" ] || continue
            _ep=$(expand_manifest_vars "$_ep")
            [ "${_ep#/}" = "$_ep" ] && _ep="${MANIFEST_DIR}/${_ep}"
            mkdir -p "$(dirname -- "$_ep")" 2>/dev/null || true
            rm -f "${_ep}.wal" 2>/dev/null || true
            cp -f "$_src_db" "$_ep" 2>/dev/null || sudo cp -f "$_src_db" "$_ep" 2>/dev/null || true
          done
        fi
      fi
      ;;
  esac
done 3<< EOF_IMP_DBS
$DBS
EOF_IMP_DBS

_owner="${SERVICE_USER:-${REMOTE_USER:-${ADMIN_USER:-${SUDO_USER:-}}}}"
if [ -n "$_owner" ] && id "$_owner" >/dev/null 2>&1; then
  for _d in "${DATA_DISK_MOUNT:-/mnt/data}" "$MANIFEST_DIR"; do
    [ -d "$_d" ] && { chown -R "${_owner}:${_owner}" "$_d" 2>/dev/null || sudo chown -R "${_owner}:${_owner}" "$_d" 2>/dev/null || true; }
  done
fi

"${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/daemonize.sh" start "$JSON_FILE"
log_info "Imported state for '$APP_NAME' from '$APP_STAGE'."
exit 0
