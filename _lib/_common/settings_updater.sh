#!/bin/sh
# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145



set -feu
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE}"

elif [ "${ZSH_VERSION-}" ]; then
  this_file="${0}"

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

LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"
export LIBSCRIPT_DATA_DIR

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/pkg_mgr.sh'
export SCRIPT_NAME
. "${SCRIPT_NAME}"

db_file="${LIBSCRIPT_DATA_DIR}"'/libscript.db'

if [ -z "${sql3+x}" ]; then
  if command -v -- 'sqlite3' >/dev/null 2>&1; then
    sql3=1
  else
    sql3=0
  fi
fi

try_create_table() {
  if [ "${sql3}" -eq 1 ] ; then
    sqlite3 "${db_file}" '
      CREATE TABLE IF NOT EXISTS T(
        location text,
        key text PRIMARY_KEY,
        val text,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
      );'
  fi
}

# `try_create_table` only needs to be called once; though it's guarded by `IF NOT EXISTS`
STACK="${STACK:-:}"
case "${STACK}" in
  *':'"${this_file}"':'*) ;;
  *)
    mkdir -p -- "${LIBSCRIPT_DATA_DIR}"
    try_create_table ;;
esac
export STACK="${STACK:-}${this_file}"':'

lang_export() {
  language="${1}"
  var_name="${2}"
  var_value="${3}"

  is_digit=1
  case "${var_value}" in
      ''|*[![:digit:]]*) is_digit=0 ;;
  esac

  case "${language}" in
    'cmd')
      prefix='SET'
      quote='"'
      ;;
    'sqlite')
      prefix=''
      quote="'" ;;
    'sh')
      prefix='export'
      quote="'"
      ;;
    *)
      >&2 printf 'Unsupported language: %s\n' "${language}"
      exit 5
      ;;
  esac
  if [ "${is_digit}" -eq 1 ]; then quote=''; fi

  case "${language}" in
    'cmd')
      printf '%s %s=%s%s%s\n' "${prefix}" "${var_name}" "${quote}" "${var_value}" "${quote}"
      ;;
    'sh')
      printf '%s %s=%s%s%s\n' "${prefix}" "${var_name}" "${quote}" "${var_value}" "${quote}"
      ;;
    'sqlite')
      if [ "${sql3}" -eq 1 ] ; then
        try_create_table
        sqlite3 "${db_file}" '
          INSERT INTO T (key, val) VALUES
            ( '"'${var_name}'"', '"'${var_value}'"' );'
      fi
      ;;
  esac
}
