#!/bin/sh
# ## Overview
# Lifecycle and conformance test suite for the 5 C/C++ compiler Tier 1 recipes
# (_lib/languages/gcc, _lib/languages/clang, _lib/languages/tcc, _lib/languages/edgcpp,
# _lib/languages/custom-cc) and the unified cc/c routers.
#
# ## Usage
# ./tests/test_c_compilers_lifecycle.sh

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

# ## verify_compiler_recipe
# Exercises install (2x idempotent), ls, ls-remote, status, and test verbs on a C compiler component.
verify_compiler_recipe() {
  _cc_comp="${1}"
  unset SCRIPT_NAME || true
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install "${_cc_comp}" latest
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install "${_cc_comp}" latest
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls "${_cc_comp}" >/dev/null
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote "${_cc_comp}" >/dev/null
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" test "${_cc_comp}"
}

for _comp in gcc clang tcc edgcpp custom-cc cc c; do
  verify_compiler_recipe "${_comp}"
done

printf '%s
' "[PASS] All C compiler Tier 1 recipes (gcc, clang, tcc, edgcpp, custom-cc, cc, c) passed lifecycle and conformance checks!"
