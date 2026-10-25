#!/bin/sh
# ## Overview
# Manifest-driven application state exporter for LibScript.
# Exports PostgreSQL dumps, DuckDB/SQLite files, and environment configuration files
# declared in `libscript.json` into a staging directory.
#
# ## Usage
# ./_lib/databases/export_db.sh <libscript.json> <stage_dir>

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

# shellcheck disable=SC1091
. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"

JSON_FILE="${1:-libscript.json}"
STAGE_DIR="${2:-/tmp/libscript_export_stage}"

if [ ! -f "$JSON_FILE" ] || ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

MANIFEST_DIR=$(cd -- "$(dirname -- "$JSON_FILE")" && pwd)
APP_NAME=$(jq -r '.name // empty' "$JSON_FILE" 2>/dev/null || true)
[ -n "$APP_NAME" ] || APP_NAME=$(basename "$MANIFEST_DIR")
APP_STAGE="${STAGE_DIR}/${APP_NAME}"
mkdir -p "${APP_STAGE}/postgres" "${APP_STAGE}/duckdb" "${APP_STAGE}/config"

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
  _emv_val="${1:-}"
  case "$_emv_val" in
    *'$'*)
      if command -v python3 >/dev/null 2>&1; then
        # libscript-allow-interp
        _emv_val=$(python3 -c '
import os, re, sys
s = sys.argv[1]
def repl_default(m):
    k, d = m.group(1), m.group(2)
    v = os.environ.get(k, "")
    return v if v != "" else d
for _ in range(3):
    s = re.sub(r"\$\{([A-Za-z_][A-Za-z0-9_]*):-([^}]*)\}", repl_default, s)
    s = os.path.expandvars(s)
s = re.sub(r"\$\{[A-Za-z_][A-Za-z0-9_]*\}", "", s)
print(s)
' "$_emv_val" 2>/dev/null || printf '%s' "$_emv_val")
      fi
      ;;
  esac
  printf '%s\n' "$_emv_val"
}

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
      if command -v pg_dump >/dev/null 2>&1; then
        _candidates="$DB_NAME $(printf '%s\n' "$db_entry" | jq -r '.legacy_names[]? // empty' 2>/dev/null | tr '\n' ' ')"
        for _cand_db in $_candidates; do
          [ -n "$_cand_db" ] || continue
          _out_sql="${APP_STAGE}/postgres/${_cand_db}.sql"
          log_info "Exporting PostgreSQL database '$_cand_db' to '$_out_sql'..."
          PGPASSWORD="$DB_PASS" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" --clean --if-exists --no-owner --no-privileges -f "$_out_sql" "$_cand_db" 2>/dev/null || \
            sudo -u postgres pg_dump --clean --if-exists --no-owner --no-privileges -f "$_out_sql" "$_cand_db" 2>/dev/null || rm -f "$_out_sql"
        done
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
      if [ -f "$DB_PATH" ]; then
        log_info "Exporting $ENGINE file '$DB_PATH'..."
        cp -f "$DB_PATH" "${APP_STAGE}/duckdb/$(basename "$DB_PATH")"
      fi
      _extra_paths=$(printf '%s\n' "$db_entry" | jq -r '.fallback_paths[]? // .extra_paths[]? // empty' 2>/dev/null || true)
      if [ -n "$_extra_paths" ]; then
        printf '%s\n' "$_extra_paths" | while IFS= read -r _ep; do
          [ -n "$_ep" ] || continue
          _ep=$(expand_manifest_vars "$_ep")
          [ "${_ep#/}" = "$_ep" ] && _ep="${MANIFEST_DIR}/${_ep}"
          if [ -f "$_ep" ] && [ ! -f "${APP_STAGE}/duckdb/$(basename "$_ep")" ]; then
            cp -f "$_ep" "${APP_STAGE}/duckdb/$(basename "$_ep")"
          fi
        done
      fi
      ;;
  esac
done 3<< EOF_EXP_DBS
$DBS
EOF_EXP_DBS

for _cfg_f in .env .env.secrets .env.libscript; do
  if [ -f "${MANIFEST_DIR}/${_cfg_f}" ]; then
    cp -f "${MANIFEST_DIR}/${_cfg_f}" "${APP_STAGE}/config/${_cfg_f#.}"
  fi
done

_svc_efs=$(jq -r '(.env_files[]?, (.services | if type == "object" then .[].env_files[]? elif type == "array" then .[].env_files[]? else empty end))' "$JSON_FILE" 2>/dev/null | sort -u || true)
if [ -n "$_svc_efs" ]; then
  printf '%s\n' "$_svc_efs" | while IFS= read -r _sef; do
    [ -n "$_sef" ] || continue
    case "$_sef" in
      .env|.env.secrets|.env.libscript|../.env|../.env.secrets|../.env.libscript) continue ;;
    esac
    if [ -f "${MANIFEST_DIR}/${_sef}" ]; then
      _safe_name=$(printf '%s' "$_sef" | tr '/' '_')
      cp -f "${MANIFEST_DIR}/${_sef}" "${APP_STAGE}/config/${_safe_name}"
    fi
  done
fi

chmod -R a+rX "$STAGE_DIR" 2>/dev/null || sudo chmod -R a+rX "$STAGE_DIR" 2>/dev/null || true
log_info "Exported state for '$APP_NAME' into '$APP_STAGE'."
exit 0
