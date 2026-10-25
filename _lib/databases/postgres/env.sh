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
_EB_CALLER_THIS="${THIS_FILE}"
_EB_CALLER_DIR="${SCRIPT_DIR}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_base.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true
_pg_home="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/postgres"
export POSTGRES_VERSION="${POSTGRES_URL_VERSION:-${POSTGRES_VERSION:-${POSTGRESQL_VERSION:-latest}}}"
if [ "$POSTGRES_VERSION" = "latest" ]; then
  if [ -d "${_pg_home}/default/bin" ]; then
    export POSTGRES_VERSION="default"
  elif [ -d "${_pg_home}/latest/bin" ]; then
    export POSTGRES_VERSION="latest"
  elif [ -d "${_pg_home}/17/bin" ] || [ -d "/usr/lib/postgresql/17/bin" ] || [ -d "/opt/homebrew/opt/postgresql@17/bin" ]; then
    export POSTGRES_VERSION="17"
  elif [ -d "${_pg_home}/16/bin" ] || [ -d "/usr/lib/postgresql/16/bin" ] || [ -d "/opt/homebrew/opt/postgresql@16/bin" ]; then
    export POSTGRES_VERSION="16"
  elif [ -d "${_pg_home}/15/bin" ] || [ -d "/usr/lib/postgresql/15/bin" ] || [ -d "/opt/homebrew/opt/postgresql@15/bin" ]; then
    export POSTGRES_VERSION="15"
  else
    export POSTGRES_VERSION="17"
  fi
fi
export POSTGRESQL_VERSION="${POSTGRES_VERSION}"
if [ "${POSTGRES_PASSWORD_FILE-}" ] && [ -f "${POSTGRES_PASSWORD_FILE}" ]; then
  pass_contents="$(cat -- "${POSTGRES_PASSWORD_FILE}"; printf 'a')"
  pass_contents="${pass_contents%a}"
  export POSTGRES_PASSWORD="${pass_contents}"
fi
export POSTGRES_SERVICE_USER="${POSTGRES_SERVICE_USER:-postgres}"
export POSTGRES_SERVICE_GROUP="${POSTGRES_SERVICE_GROUP:-${POSTGRES_SERVICE_USER}}"

if [ -n "${POSTGRES_URL:-}" ] && [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/databases/parse_connection_uri.sh" ]; then
  _pg_parsed=$(env -u SCRIPT_NAME -u STACK "${LIBSCRIPT_ROOT_DIR}/_lib/databases/parse_connection_uri.sh" "$POSTGRES_URL" --eval 2>/dev/null || true)
  if [ -n "$_pg_parsed" ]; then
    _pg_u=$(printf '%s\n' "$_pg_parsed" | awk -F'"' '/^DB_USER=/{print $2}')
    _pg_p=$(printf '%s\n' "$_pg_parsed" | awk -F'"' '/^DB_PASS=/{print $2}')
    _pg_h=$(printf '%s\n' "$_pg_parsed" | awk -F'"' '/^DB_HOST=/{print $2}')
    _pg_port=$(printf '%s\n' "$_pg_parsed" | awk -F'"' '/^DB_PORT=/{print $2}')
    _pg_db=$(printf '%s\n' "$_pg_parsed" | awk -F'"' '/^DB_NAME=/{print $2}')
    [ -n "$_pg_u" ] && : "${POSTGRES_USER:=$_pg_u}"
    [ -n "$_pg_p" ] && : "${POSTGRES_PASSWORD:=$_pg_p}"
    [ -n "$_pg_h" ] && : "${POSTGRES_HOST:=$_pg_h}"
    [ -n "$_pg_port" ] && : "${POSTGRES_PORT:=$_pg_port}"
    [ -n "$_pg_db" ] && : "${POSTGRES_DB:=$_pg_db}"
  fi
fi

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

for _pg_cand in "${_pg_home}/${POSTGRES_VERSION}/bin" "${_pg_home}/latest/bin" "${_pg_home}/default/bin" "${_pg_home}/17/bin" "${_pg_home}/16/bin" "${_pg_home}/15/bin" "/usr/lib/postgresql/${POSTGRES_VERSION}/bin" "/usr/lib/postgresql/17/bin" "/usr/lib/postgresql/16/bin" "/usr/lib/postgresql/15/bin" "/opt/homebrew/opt/postgresql@${POSTGRES_VERSION}/bin" "/opt/homebrew/opt/postgresql@17/bin" "/opt/homebrew/opt/libpq/bin" "/usr/local/opt/postgresql@${POSTGRES_VERSION}/bin" "/opt/ooce/pgsql-${POSTGRES_VERSION}/bin" "/opt/ooce/pgsql-17/bin" "/opt/ooce/bin"; do
  if [ -d "$_pg_cand" ] || [ "$_pg_cand" = "${_pg_home}/${POSTGRES_VERSION}/bin" ]; then
    case ":${PATH:-}:" in
      *":${_pg_cand}:"*) ;;
      *) PATH="${_pg_cand}${PATH:+:${PATH}}" ;;
    esac
  fi
done
export PATH
