#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'
if [ "$cmd" = "db-search" ]; then
  query="$1"
  DB_FILE="${LIBSCRIPT_ROOT_DIR:-$SCRIPT_DIR}/libscript.sqlite"
  if [ ! -f "$DB_FILE" ]; then
    echo "Error: Database not found. Run update-db first." >&2
    exit 1
  fi
  sqlite3 -column -header "$DB_FILE" "
    SELECT c.name, v.version, f.url, f.checksum 
    FROM components c 
    LEFT JOIN versions v ON c.id = v.component_id 
    LEFT JOIN files f ON v.id = f.version_id 
    WHERE c.name LIKE '%$query%' OR v.version LIKE '%$query%'
  "
  exit 0
fi
