#!/bin/sh
# ## Overview
# Validates update_results.sh execution, verifying component discovery,
# markdown table updating in README.md, and task tracking in TODO_PLAN.md.
#
# ## Usage
# ./tests/test_update_results.sh

set -eu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
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
THIS_DIR="${SCRIPT_DIR}"
: "${THIS_DIR}"
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

# ## run_tests
# Creates a temporary mock environment and verifies update_results.sh behavior.
run_tests() {
  _test_tmp=$(mktemp -d "${TMPDIR:-/tmp}/test_update_results.XXXXXX")

  # Setup mock directory structure
  mkdir -p "${_test_tmp}/_lib/catA/compA"
  mkdir -p "${_test_tmp}/_lib/catB/compB"
  mkdir -p "${_test_tmp}/_lib/_common/helper"
  mkdir -p "${_test_tmp}/tests_tmp"

  touch "${_test_tmp}/libscript.sh"

  cat <<'EOF_README' >"${_test_tmp}/README.md"
# Mock Project

## Supported Components

| Component | Linux (apk) | Linux (deb) | Linux (rpm) | Windows | SunOS | FreeBSD |
|---|---|---|---|---|---|---|
| `compA` | ❓ | ❓ | ❓ | - | - | - |

## License
MIT
EOF_README

  cat <<'EOF_TODO' >"${_test_tmp}/TODO_PLAN.md"
- [ ] _lib/catA/compA
- [ ] compB
- [ ] compC
- [x] already_done
EOF_TODO

  # Create mock test result files
  touch "${_test_tmp}/tests_tmp/compA.linux.alpine.success"
  touch "${_test_tmp}/tests_tmp/compB.windows.failure"

  # Execute update_results.sh
  "${REPO_ROOT}/tests/update_results.sh" "${_test_tmp}"

  # Verification 1: compA has success checkmark in README
  # shellcheck disable=SC2016
  if ! grep -q '| `compA` | ✅ |' "${_test_tmp}/README.md"; then
    printf 'Error: compA success status not found in README.md\n' >&2
    rm -rf "${_test_tmp}"
    exit 1
  fi

  # Verification 2: compB has failure mark for windows in README
  # shellcheck disable=SC2016
  if ! grep -q '| `compB` | ❓ | ❓ | ❓ | ❌ |' "${_test_tmp}/README.md"; then
    printf 'Error: compB failure status not found in README.md\n' >&2
    rm -rf "${_test_tmp}"
    exit 1
  fi

  # Verification 3: _common / helper must NOT be in the table
  if grep -q "helper" "${_test_tmp}/README.md"; then
    printf 'Error: helper from _common found in README.md table\n' >&2
    rm -rf "${_test_tmp}"
    exit 1
  fi

  # Verification 4: TODO_PLAN.md updated completed items
  if ! grep -q -- "- \[x\] _lib/catA/compA" "${_test_tmp}/TODO_PLAN.md"; then
    printf 'Error: _lib/catA/compA not checked in TODO_PLAN.md\n' >&2
    rm -rf "${_test_tmp}"
    exit 1
  fi

  if ! grep -q -- "- \[x\] compB" "${_test_tmp}/TODO_PLAN.md"; then
    printf 'Error: compB not checked in TODO_PLAN.md\n' >&2
    rm -rf "${_test_tmp}"
    exit 1
  fi

  if ! grep -q -- "- \[ \] compC" "${_test_tmp}/TODO_PLAN.md"; then
    printf 'Error: compC unexpectedly modified in TODO_PLAN.md\n' >&2
    rm -rf "${_test_tmp}"
    exit 1
  fi

  # Verification 5: FreeBSD success and custom output + JSON export
  touch "${_test_tmp}/tests_tmp/compA.freebsd.success"
  cp "${_test_tmp}/README.md" "${_test_tmp}/CUSTOM_REPORT.md"

  "${REPO_ROOT}/tests/update_results.sh" "${_test_tmp}" \
    --output "${_test_tmp}/CUSTOM_REPORT.md" \
    --json "${_test_tmp}/tests_tmp/matrix_results.json"

  # shellcheck disable=SC2016
  if ! grep -q '| `compA` |.*| ✅ |' "${_test_tmp}/CUSTOM_REPORT.md"; then
    printf 'Error: compA FreeBSD status not updated in CUSTOM_REPORT.md\n' >&2
    rm -rf "${_test_tmp}"
    exit 1
  fi

  if [ ! -f "${_test_tmp}/tests_tmp/matrix_results.json" ]; then
    printf 'Error: matrix_results.json was not generated\n' >&2
    rm -rf "${_test_tmp}"
    exit 1
  fi

  if ! grep -q '"component": "compA"' "${_test_tmp}/tests_tmp/matrix_results.json"; then
    printf 'Error: compA not found in matrix_results.json\n' >&2
    rm -rf "${_test_tmp}"
    exit 1
  fi

  rm -rf "${_test_tmp}"
  printf '%s\n' "All tests in test_update_results.sh passed successfully."
}

run_tests
