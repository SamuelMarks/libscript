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
      printf '%s\n' "Usage: ./make.sh test_component <component_name>" >&2
      exit 1
    fi
    if [ "${LIBSCRIPT_USE_VAGRANT:-0}" = "1" ]; then
      "$SCRIPT_DIR/tests/run_local_tests.sh" "$2"
    else
      "$SCRIPT_DIR/libscript.sh" install "$2" latest
      "$SCRIPT_DIR/libscript.sh" test "$2"
    fi
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
  audit)
    "$SCRIPT_DIR/devtools/audit/audit_standards.sh" --all
    "$SCRIPT_DIR/devtools/audit/audit_posix.sh"
    "$SCRIPT_DIR/devtools/audit/audit_version_manager.sh"
    "$SCRIPT_DIR/devtools/audit/doc_coverage.sh" --strict
    "$SCRIPT_DIR/tests/test_doc_coverage.sh"
    "$SCRIPT_DIR/tests/test_vm_contract.sh"
    "$SCRIPT_DIR/tests/test_update_results.sh"
    ;;
  update_results)
    "$SCRIPT_DIR/tests/update_results.sh" --json
    ;;
  register_bento_boxes)
    "$SCRIPT_DIR/tests/register_bento_boxes.sh"
    ;;
  test_canary_6os)
    "$SCRIPT_DIR/tests/run_omnios_tests.sh" jq curl sqlite c cmake nodejs python rust postgres nginx
    "$SCRIPT_DIR/tests/run_alpine_tests.sh" jq curl sqlite c cmake nodejs python rust postgres nginx
    "$SCRIPT_DIR/tests/run_debian_tests.sh" jq curl sqlite c cmake nodejs python rust postgres nginx
    "$SCRIPT_DIR/tests/run_rockylinux_tests.sh" jq curl sqlite c cmake nodejs python rust postgres nginx
    "$SCRIPT_DIR/tests/run_freebsd_tests.sh" jq curl sqlite c cmake nodejs python rust postgres nginx
    "$SCRIPT_DIR/tests/run_windows_tests.sh" jq curl sqlite c cmake nodejs python rust postgres nginx
    ;;
  test_matrix_6os)
    "$SCRIPT_DIR/tests/run_vagrant_matrix.sh"
    ;;
  --help|-h|"/?")
    printf '%s\n' "Usage: ./make.sh <target> [component_name]"
    printf '%s\n' "Targets: audit, update_results, register_bento_boxes, test_canary_6os, test_matrix_6os, test, local_tests_all, test_component, local_tests_toolchain, local_tests_languages, local_tests_databases"
    exit 0
    ;;
  *)
    printf '%s\n' "Unknown target: $target" >&2
    printf '%s\n' "Usage: ./make.sh <target> [component_name]" >&2
    exit 1
    ;;
esac
