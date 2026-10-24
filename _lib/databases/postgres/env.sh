#!/bin/sh
# ## Overview
# Environment initialization for PostgreSQL.
#
# ## Usage
# Defines defaults such as `POSTGRES_VERSION`, `POSTGRES_URL`, and parses credentials.


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
export POSTGRES_VERSION="${POSTGRES_URL_VERSION:-${POSTGRES_VERSION:-${POSTGRESQL_VERSION:-15}}}"
if [ "$POSTGRES_VERSION" = "latest" ]; then
  export POSTGRES_VERSION="15"
fi
export POSTGRESQL_VERSION="${POSTGRES_VERSION}"
if [ "${POSTGRES_PASSWORD_FILE-}" ] && [ -f "${POSTGRES_PASSWORD_FILE}" ]; then
  pass_contents="$(cat -- "${POSTGRES_PASSWORD_FILE}"; printf 'a')"
  pass_contents="${pass_contents%a}"
  # TODO(security): Audit
  export POSTGRES_PASSWORD="${pass_contents}"
fi
export POSTGRES_SERVICE_USER="${POSTGRES_SERVICE_USER:-postgres}"
export POSTGRES_SERVICE_GROUP="${POSTGRES_SERVICE_GROUP:-${POSTGRES_SERVICE_USER}}"

export POSTGRES_USER="${POSTGRES_USER:-postgres}"
export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-password}"
export POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
export POSTGRES_PORT="${POSTGRES_PORT:-5432}"
export POSTGRES_DB="${POSTGRES_DB:-${POSTGRES_USER}}"

if [ "${POSTGRES_PORT}" = "5432" ]; then
  export POSTGRES_URL="${POSTGRES_URL:-postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}/${POSTGRES_DB}}"
else
  export POSTGRES_URL="${POSTGRES_URL:-postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}}"
fi

POSTGRES_VERSION="${POSTGRES_VERSION:-latest}"
_pg_home="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/postgres"
for _pg_cand in "${_pg_home}/${POSTGRES_VERSION}/bin" "${_pg_home}/default/bin" "/usr/lib/postgresql/${POSTGRES_VERSION}/bin" "/opt/homebrew/opt/postgresql@${POSTGRES_VERSION}/bin" "/opt/homebrew/opt/libpq/bin" "/usr/local/opt/postgresql@${POSTGRES_VERSION}/bin" "/opt/ooce/pgsql-${POSTGRES_VERSION}/bin" "/opt/ooce/pgsql-17/bin" "/opt/ooce/bin"; do
  if [ -d "$_pg_cand" ] || [ "$_pg_cand" = "${_pg_home}/${POSTGRES_VERSION}/bin" ]; then
    case ":${PATH:-}:" in
      *":${_pg_cand}:"*) ;;
      *) PATH="${_pg_cand}${PATH:+:${PATH}}" ;;
    esac
  fi
done
export PATH
