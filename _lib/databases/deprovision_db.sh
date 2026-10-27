#!/bin/sh
# ## Overview
# Manifest-driven database deprovisioning engine for LibScript.
# Parses `.databases` and `.infrastructure.databases` from `libscript.json` and delegates
# schema/file removal to `_lib/databases/deprovision_schema.sh`.
#
# ## Usage
# ./_lib/databases/deprovision_db.sh [libscript.json]

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

JSON_FILE="${1:-libscript.json}"
if [ ! -f "$JSON_FILE" ] || ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

MANIFEST_DIR=$(cd -- "$(dirname -- "$JSON_FILE")" && pwd)

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

DBS=$(jq -c '((.databases // .infrastructure.databases) | if type == "object" then to_entries | map(.value + {name: (.value.name // .value.db_name // .key)}) elif type == "array" then map(. + {name: (.name // .db_name // .id)}) else [] end)[]?' "$JSON_FILE" 2>/dev/null || true)

while IFS= read -r db_entry <&3; do
  [ -n "$db_entry" ] || continue
  ENGINE=$(printf '%s\n' "$db_entry" | jq -r '(.engine // .type // "postgres") | ascii_downcase')
  DB_NAME=$(printf '%s\n' "$db_entry" | jq -r '.name // .db_name // "app_db"')
  DB_USER=$(printf '%s\n' "$db_entry" | jq -r '.user // .username // "postgres"')
  DB_HOST=$(printf '%s\n' "$db_entry" | jq -r '.host // "127.0.0.1"')
  DB_PORT=$(printf '%s\n' "$db_entry" | jq -r '.port // empty')
  PASS_ENV=$(printf '%s\n' "$db_entry" | jq -r '.password_env // empty')
  RAW_PASS=$(printf '%s\n' "$db_entry" | jq -r '.password // empty')
  DB_PASS="$RAW_PASS"
  if [ -z "$DB_PASS" ] && [ -n "$PASS_ENV" ]; then
    DB_PASS=$(printenv "$PASS_ENV" 2>/dev/null || true)
  fi
  [ -n "$DB_PASS" ] || DB_PASS="postgres"

  case "$ENGINE" in
    postgres|postgresql|mysql|mariadb|mongodb)
      log_info "Deprovisioning $ENGINE database '$DB_NAME'..."
      STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/databases/deprovision_schema.sh" --engine "$ENGINE" --host "$DB_HOST" ${DB_PORT:+--port "$DB_PORT"} --admin-user "postgres" --admin-pass "$DB_PASS" --schema "$DB_NAME" --user "$DB_USER" || true
      _leg_dbs=$(printf '%s\n' "$db_entry" | jq -r '.legacy_names[]? // empty' 2>/dev/null || true)
      if [ -n "$_leg_dbs" ]; then
        printf '%s\n' "$_leg_dbs" | while IFS= read -r _ldb; do
          [ -n "$_ldb" ] || continue
          STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/databases/deprovision_schema.sh" --engine "$ENGINE" --host "$DB_HOST" ${DB_PORT:+--port "$DB_PORT"} --admin-user "postgres" --admin-pass "$DB_PASS" --schema "$_ldb" --user "$DB_USER" || true
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
      log_info "Deprovisioning $ENGINE file '$DB_PATH'..."
      STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/databases/deprovision_schema.sh" --engine "duckdb" --schema "$DB_PATH" --user "$DB_USER" || true
      _extra_paths=$(printf '%s\n' "$db_entry" | jq -r '.fallback_paths[]? // .extra_paths[]? // empty' 2>/dev/null || true)
      if [ -n "$_extra_paths" ]; then
        printf '%s\n' "$_extra_paths" | while IFS= read -r _ep; do
          [ -n "$_ep" ] || continue
          _ep=$(expand_manifest_vars "$_ep")
          [ "${_ep#/}" = "$_ep" ] && _ep="${MANIFEST_DIR}/${_ep}"
          STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/databases/deprovision_schema.sh" --engine "duckdb" --schema "$_ep" --user "$DB_USER" || true
        done
      fi
      ;;
  esac
done 3<< EOF_DEPROVISION_DBS
$DBS
EOF_DEPROVISION_DBS
exit 0
