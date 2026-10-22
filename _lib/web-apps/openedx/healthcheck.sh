#!/bin/sh
# ## Overview
# Full-stack diagnostic and health probe module for Open edX.
# Validates MySQL, MongoDB, Redis, Meilisearch, Celery, LMS HTTP, CMS HTTP, and SMTP listeners.
#
# ## Usage
#   ./healthcheck.sh [--json|help]

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
export DIR="${SCRIPT_DIR}"

# ## Parameters
# - `--json`: Formats diagnostic health report in JSON rather than human-readable tabular format.
#
# ## Environment Variables
# - `OPENEDX_INSTALL_DIR`: Path to openedx installation directory.
# - `LMS_HOST`: Public LMS host (default: 127.0.0.1).
# - `LMS_PORT`: Port for LMS service (default: 8000).
# - `CMS_HOST`: Public Studio CMS host (default: 127.0.0.1).
# - `CMS_PORT`: Port for CMS service (default: 8001).
# - `MYSQL_HOST`: Host for MySQL (default: 127.0.0.1).
# - `MYSQL_PORT`: Port for MySQL (default: 3306).
# - `MONGODB_HOST`: Host for MongoDB (default: 127.0.0.1).
# - `MONGODB_PORT`: Port for MongoDB (default: 27017).
# - `REDIS_HOST`: Host for Redis (default: 127.0.0.1).
# - `REDIS_PORT`: Port for Redis (default: 6379).
# - `MEILISEARCH_HOST`: Host for Meilisearch (default: 127.0.0.1).
# - `MEILISEARCH_PORT`: Port for Meilisearch (default: 7700).
# - `SMTP_PORT`: Port for local SMTP mail relay (default: 25).
#
# ## Exit Codes
# - `0`: All required endpoints are healthy.
# - `1`: One or more health checks failed or returned an error.

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/log.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR:-${LIBSCRIPT_HOME:-$HOME/.libscript}/openedx}"
export OPENEDX_INSTALL_DIR
LMS_HOST="${LMS_HOST:-127.0.0.1}"
LMS_PORT="${LMS_PORT:-8000}"
CMS_HOST="${CMS_HOST:-127.0.0.1}"
CMS_PORT="${CMS_PORT:-8001}"
MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MONGODB_HOST="${MONGODB_HOST:-127.0.0.1}"
MONGODB_PORT="${MONGODB_PORT:-27017}"
REDIS_HOST="${REDIS_HOST:-127.0.0.1}"
REDIS_PORT="${REDIS_PORT:-6379}"
MEILISEARCH_HOST="${MEILISEARCH_HOST:-127.0.0.1}"
MEILISEARCH_PORT="${MEILISEARCH_PORT:-7700}"
SMTP_HOST="${SMTP_HOST:-127.0.0.1}"
SMTP_PORT="${SMTP_PORT:-25}"

# ## show_help
# Displays healthcheck CLI usage documentation.
show_help() {
  cat <<EOF
Open edX Healthcheck Diagnostics CLI

Usage:
  $0 [--json]
  $0 help

Options:
  --json    Emit structured machine-readable JSON status report
  help      Display this help documentation
EOF
  exit 0
}

JSON_OUTPUT="0"
if [ "${1:-}" = "--json" ]; then
  JSON_OUTPUT="1"
elif [ "${1:-}" = "help" ] || [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  show_help
fi

exec "${SCRIPT_DIR}/health_helper.sh" "${JSON_OUTPUT}" "${LMS_HOST}" "${LMS_PORT}" "${CMS_HOST}" "${CMS_PORT}" "${MYSQL_HOST}" "${MYSQL_PORT}" "${MONGODB_HOST}" "${MONGODB_PORT}" "${REDIS_HOST}" "${REDIS_PORT}" "${MEILISEARCH_HOST}" "${MEILISEARCH_PORT}" "${SMTP_HOST}" "${SMTP_PORT}"
