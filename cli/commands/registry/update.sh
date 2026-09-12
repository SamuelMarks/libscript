#!/bin/sh
# ## Overview
# Updates the local package registry with the latest upstream information.
# 
# ## Usage
# Execute this script to refresh registry indices.


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

DB_FILE="${LIBSCRIPT_ROOT_DIR}/libscript.sqlite"

if ! command -v sqlite3 >/dev/null 2>&1; then
  printf '%s
' "Error: sqlite3 is required to update database." >&2
  exit 1
fi

printf '%s
' "Updating database at $DB_FILE..."
sqlite3 "$DB_FILE" "
  CREATE TABLE IF NOT EXISTS components (id INTEGER PRIMARY KEY, name TEXT UNIQUE);
  CREATE TABLE IF NOT EXISTS versions (id INTEGER PRIMARY KEY, component_id INTEGER, version TEXT);
  CREATE TABLE IF NOT EXISTS files (id INTEGER PRIMARY KEY, version_id INTEGER, url TEXT, checksum TEXT);
"

for comp_path in "$LIBSCRIPT_ROOT_DIR"/_lib/*/*; do
  [ -d "$comp_path" ] || continue
  comp_name="$(basename "$comp_path")"
  sqlite3 "$DB_FILE" "INSERT OR IGNORE INTO components (name) VALUES ('$comp_name');"
done

printf '%s
' "Registry database updated successfully."
