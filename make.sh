#!/bin/sh
# ## Overview
# Entry point for common make tasks in POSIX shell environment.
#
# ## Usage
# ./make.sh <target> [component_name]
# Targets: test, local_tests_all, test_component, local_tests_toolchain, local_tests_languages, local_tests_databases

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
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)

target="${1:-}"

case "$target" in
  test|local_tests_all)
    "$SCRIPT_DIR/tests/run_local_tests.sh" all
    ;;
  test_component)
    if [ -z "${2:-}" ]; then
      printf '%s
' "Usage: ./make.sh test_component <component_name>" >&2
      exit 1
    fi
    "$SCRIPT_DIR/tests/run_local_tests.sh" "$2"
    ;;
  local_tests_toolchain)
    "$SCRIPT_DIR/tests/run_local_tests.sh" toolchains
    ;;
  local_tests_languages)
    "$SCRIPT_DIR/tests/run_local_tests.sh" languages
    ;;
  local_tests_databases)
    "$SCRIPT_DIR/tests/run_local_tests.sh" databases
    ;;
  --help|-h|"/?")
    printf '%s
' "Usage: ./make.sh <target> [component_name]"
    printf '%s
' "Targets: test, local_tests_all, test_component, local_tests_toolchain, local_tests_languages, local_tests_databases"
    exit 0
    ;;
  *)
    printf '%s
' "Unknown target: $target" >&2
    printf '%s
' "Usage: ./make.sh <target> [component_name]" >&2
    exit 1
    ;;
esac
