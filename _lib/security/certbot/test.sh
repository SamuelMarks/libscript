#!/bin/sh
# ## Overview
# Smoke test suite for the certbot component.
# Verifies cli.sh --help, dry-run setup, and certbot environment loading.
# ## Usage
# ./_lib/security/certbot/test.sh

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

"${SCRIPT_DIR}/cli.sh" --help >/dev/null

_cb_tmp=$(mktemp -d "${TMPDIR:-/tmp}/certbot_test.XXXXXX")
LIBSCRIPT_HOME="$_cb_tmp" LIBSCRIPT_DRY_RUN_PKG_MGR=1 LIBSCRIPT_ALLOW_CERTBOT_SHIM=1 "${SCRIPT_DIR}/setup.sh" >/dev/null

if [ -f "${SCRIPT_DIR}/env.sh" ]; then
  _test_saved_this="${THIS_FILE}"
  _test_saved_dir="${SCRIPT_DIR}"
  LIBSCRIPT_HOME="$_cb_tmp"
  export LIBSCRIPT_HOME
  SCRIPT_NAME="${SCRIPT_DIR}/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
  THIS_FILE="${_test_saved_this}"
  SCRIPT_DIR="${_test_saved_dir}"
fi

command -v certbot >/dev/null 2>&1
certbot --version >/dev/null 2>&1
rm -rf "$_cb_tmp"
printf '%s\n' '[PASS] certbot component smoke test passed.'
