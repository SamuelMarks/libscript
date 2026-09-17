#!/bin/sh
# ## Overview
# Integration test suite for Open edX components and stack orchestration.
#
# ## Usage
# Run to verify CLI routing and setup scripts for all Open edX dependencies.

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

printf '==> Testing nodeenv CLI...
'
"${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/nodeenv/cli.sh" help

printf '==> Testing MySQL CLI...
'
"${LIBSCRIPT_ROOT_DIR}/_lib/databases/mysql/cli.sh" help

printf '==> Testing Gunicorn CLI...
'
"${LIBSCRIPT_ROOT_DIR}/_lib/app-servers/gunicorn/cli.sh" help

printf '==> Testing uWSGI CLI...
'
"${LIBSCRIPT_ROOT_DIR}/_lib/app-servers/uwsgi/cli.sh" help

printf '==> Testing Waitress CLI...
'
"${LIBSCRIPT_ROOT_DIR}/_lib/app-servers/waitress/cli.sh" help

printf '==> Testing Uvicorn CLI...
'
"${LIBSCRIPT_ROOT_DIR}/_lib/app-servers/uvicorn/cli.sh" help

printf '==> Testing Meilisearch CLI...
'
"${LIBSCRIPT_ROOT_DIR}/_lib/search/meilisearch/cli.sh" help

printf '==> Testing Elasticsearch CLI...
'
"${LIBSCRIPT_ROOT_DIR}/_lib/search/elasticsearch/cli.sh" help

printf '==> Testing Exim CLI...
'
"${LIBSCRIPT_ROOT_DIR}/_lib/utilities/exim/cli.sh" help

printf '==> Testing hMailServer CLI...
'
"${LIBSCRIPT_ROOT_DIR}/_lib/utilities/hmailserver/cli.sh" help

printf '==> Testing Open edX Stack CLI...
'
"${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx/cli.sh" help

printf '==> All Open edX components verified successfully!
'
