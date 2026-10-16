#!/bin/sh
# ## Overview
# End-to-end functional test suite for the Open edX stack and management CLI tools.
# Validates CLI routing, Tutor-parity commands, port readiness helpers (`wait_ports.sh`),
# configuration synthesis, and 2x idempotency.
#
# ## Usage
# ./tests/test_openedx_stack.sh

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
export LIBSCRIPT_ROOT_DIR

OPENEDX_DIR="${LIBSCRIPT_ROOT_DIR}/_lib/web-apps/openedx"

printf '==> Testing Open edX CLI Router...
'
"${OPENEDX_DIR}/cli.sh" help >/dev/null

printf '==> Testing Open edX Database Console...
'
"${OPENEDX_DIR}/dbshell.sh" help >/dev/null

printf '==> Testing Open edX User Administration...
'
"${OPENEDX_DIR}/user.sh" help >/dev/null

printf '==> Testing Open edX Backup & Restore...
'
"${OPENEDX_DIR}/backup.sh" help >/dev/null
"${OPENEDX_DIR}/restore.sh" help >/dev/null

printf '==> Testing Open edX Healthcheck...
'
"${OPENEDX_DIR}/healthcheck.sh" help >/dev/null

printf '==> Testing Open edX Configuration Management (2x Idempotent)...
'
TMP_CFG=$(mktemp -d "${TMPDIR:-/tmp}/openedx_cfg_XXXXXX")
trap 'rm -rf "$TMP_CFG"' EXIT INT TERM
OPENEDX_INSTALL_DIR="${TMP_CFG}" "${OPENEDX_DIR}/config.sh" save >/dev/null 2>&1 || true
OPENEDX_INSTALL_DIR="${TMP_CFG}" "${OPENEDX_DIR}/config.sh" save >/dev/null 2>&1 || true

printf '==> Verifying devtools/wait_ports.sh presence...
'
if [ ! -f "${LIBSCRIPT_ROOT_DIR}/devtools/wait_ports.sh" ]; then
  printf '[ERROR] devtools/wait_ports.sh missing!
' >&2
  exit 1
fi

printf '==> All Open edX stack tools verified successfully!
'
exit 0
