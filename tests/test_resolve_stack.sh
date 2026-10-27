#!/bin/sh
# ## Overview
# Verifies that _lib/orchestration/resolve_stack.sh resolves multi-component stacks
# across all 300+ component manifests without command-line argument overflow.
#
# ## Usage
# ./tests/test_resolve_stack.sh

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

_TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/libscript_resolve_test.XXXXXX")
trap 'rm -rf "$_TMP_DIR"' EXIT INT TERM

cat > "${_TMP_DIR}/libscript.json" << 'JSON_EOF'
{
  "deps": {
    "nodejs": "20",
    "postgres": "17",
    "python": "3.12"
  }
}
JSON_EOF

"${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/resolve_stack.sh" "${_TMP_DIR}/libscript.json" "${_TMP_DIR}/plan.json"

for _pkg in nodejs postgres python; do
  if ! jq -e --arg p "$_pkg" '.selected[] | select(.name == $p)' "${_TMP_DIR}/plan.json" >/dev/null 2>&1; then
    printf '[FAIL] Expected %s in resolved execution plan\n' "$_pkg" >&2
    cat "${_TMP_DIR}/plan.json" >&2
    exit 1
  fi
done

printf '[PASS] resolve_stack.sh resolved multi-component stack across all manifests.\n'
exit 0
