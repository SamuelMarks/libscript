#!/bin/sh
# ## Overview
# Verifies root router hygiene in libscript.sh and >10 argument forwarding parity in libscript.sh and libscript.cmd.
#
# ## Usage
# ./tests/test_cli_arg_forwarding.sh

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
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2; fi
    if (return 0 2>/dev/null); then return 0; else exit 0; fi ;;
  *)
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

# ## fail_test
# Prints a failure diagnostic and exits 1.
fail_test() {
  printf '[FAIL] %s\n' "$1" >&2
  exit 1
}

if grep -q 'Oh wait, we already shifted' "${LIBSCRIPT_ROOT_DIR}/libscript.sh"; then
  fail_test 'Scratchpad comments still present in libscript.sh'
fi

if grep -Eq '(netctl\\cli\.cmd|payloads\\engine\.cmd|topologies\\engine\.cmd|traits\\engine\.cmd|_lib\\cloud\\core\\cli\.cmd)" %2 %3 %4 %5 %6 %7 %8 %9' "${LIBSCRIPT_ROOT_DIR}/libscript.cmd"; then
  fail_test 'libscript.cmd still truncates subcommand arguments at %9'
fi

if grep -q 'for %%A in (%2 %3 %4 %5 %6)' "${LIBSCRIPT_ROOT_DIR}/traits/engine.cmd"; then
  fail_test 'traits/engine.cmd still truncates arguments at %6'
fi

# Verify trait list via libscript.sh accepts >10 arguments including --manifest=a,b without dropping trailing flags
TEST_TMP="${LIBSCRIPT_ROOT_DIR}/tests_tmp/cli_fwd_$$"
mkdir -p "$TEST_TMP"
trap 'rm -rf "$TEST_TMP"' EXIT INT TERM
printf '{"traits":[]}\n' > "${TEST_TMP}/m.json"

TRAIT_OUT=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" trait list --noop1 --noop2 --noop3 --noop4 --noop5 --noop6 --noop7 --noop8 --noop9 --noop10 "--manifest=${TEST_TMP}/m.json")
printf '%s\n' "$TRAIT_OUT" | grep -q 'firewall' || fail_test "libscript.sh trait list failed with >10 args: ${TRAIT_OUT}"

printf '[PASS] CLI router hygiene and >10 argument forwarding verified across libscript.sh and libscript.cmd.\n'
exit 0
