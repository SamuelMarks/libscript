#!/bin/sh
# ## Overview
# Portable POSIX sh counterpart for test_openedx_cli_integration.cmd.
# Tests Open edX component CLIs and help commands for parity.
#
# ## Usage
# Execute this script to test Open edX components in POSIX environments:
#   ./tests/test_openedx_cli_integration.sh

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
export DIR="${SCRIPT_DIR}"
export LIBSCRIPT_ROOT_DIR

printf '[TEST 1/9] Verifying nodeenv...
'
"${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/nodeenv/cli.sh" help >/dev/null

printf '[TEST 2/9] Verifying MySQL...
'
"${LIBSCRIPT_ROOT_DIR}/_lib/databases/mysql/cli.sh" help >/dev/null

printf '[TEST 3/9] Verifying Waitress...
'
"${LIBSCRIPT_ROOT_DIR}/_lib/app-servers/waitress/cli.sh" help >/dev/null

printf '[TEST 4/9] Verifying Uvicorn...
'
"${LIBSCRIPT_ROOT_DIR}/_lib/app-servers/uvicorn/cli.sh" help >/dev/null

printf '[TEST 5/9] Verifying Gunicorn...
'
"${LIBSCRIPT_ROOT_DIR}/_lib/app-servers/gunicorn/cli.sh" help >/dev/null

printf '[TEST 6/9] Verifying Meilisearch...
'
"${LIBSCRIPT_ROOT_DIR}/_lib/search/meilisearch/cli.sh" help >/dev/null

printf '[TEST 7/9] Verifying hMailServer dispatcher...
'
"${LIBSCRIPT_ROOT_DIR}/_lib/utilities/hmailserver/cli.sh" help >/dev/null

printf '[TEST 8/9] Verifying Exim...
'
"${LIBSCRIPT_ROOT_DIR}/_lib/utilities/exim/cli.sh" help >/dev/null

printf '[TEST 9/9] Verifying Open edX stack orchestrator and Tutor parity subcommands...\n'
"${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx/cli.sh" help >/dev/null
"${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx/cli.sh" user help >/dev/null
"${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx/cli.sh" demo help >/dev/null
"${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx/cli.sh" dbshell help >/dev/null
"${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx/cli.sh" healthcheck help >/dev/null
"${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx/cli.sh" config help >/dev/null
"${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx/cli.sh" backup help >/dev/null
"${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx/cli.sh" restore help >/dev/null
"${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx/cli.sh" workers help >/dev/null
"${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx/cli.sh" theme help >/dev/null
"${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx/cli.sh" xblock help >/dev/null
"${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx/cli.sh" upgrade help >/dev/null
"${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx/cli.sh" mfe help >/dev/null

printf '
==========================================================
'
printf '[SUCCESS] All Open edX components verified in POSIX environment!
'
printf '==========================================================
'
exit 0
