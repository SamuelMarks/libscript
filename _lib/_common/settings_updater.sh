#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
[ -z "${LIBSCRIPT_ROOT_DIR:-}" ] && LIBSCRIPT_ROOT_DIR=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; echo "$d")
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
