#!/bin/sh
# ## Overview
# Verifies traits/secrets/exec_with_secrets.sh template rendering and confirms zero secret leakage in process environment.
#
# ## Usage
# ./tests/test_secrets_zero_leak.sh

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

TEST_TMP="$(mktemp -d "${TMPDIR:-/tmp}/libscript-sec-test.XXXXXX")"
# ## cleanup_sec_test
# Removes temporary secret test directory on exit.
cleanup_sec_test() {
  rm -rf "$TEST_TMP"
}
trap cleanup_sec_test EXIT INT TERM

printf 'DB_PASSWORD=super_secret_val_998877\n' > "${TEST_TMP}/secrets.kv"
printf 'password_setting = ${DB_PASSWORD}\n' > "${TEST_TMP}/app.conf.tpl"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/traits/secrets/exec_with_secrets.sh" sh "${LIBSCRIPT_ROOT_DIR}/traits/secrets/exec_with_secrets.sh" --source "${TEST_TMP}/secrets.kv" --template "${TEST_TMP}/app.conf.tpl" --output "${TEST_TMP}/app.conf"

grep -q 'password_setting = super_secret_val_998877' "${TEST_TMP}/app.conf"

if env | grep -q 'super_secret_val_998877'; then
  printf '[FAIL] Secret leaked into environment variables!\n' >&2
  exit 1
fi

printf '[PASS] Zero-env-leak secrets trait test passed.\n'
