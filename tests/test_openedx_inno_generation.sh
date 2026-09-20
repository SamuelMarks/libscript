#!/bin/sh
# ## Overview
# Validates Inno Setup (.iss) installer script generation for Open edX.
# Asserts inclusion of stack variables, background worker tasks, demo content tasks,
# Micro-Frontend deployment tasks, and Start Menu shortcuts.
#
# ## Usage
# ./tests/test_openedx_inno_generation.sh

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

TEST_TMP_DIR="${LIBSCRIPT_ROOT_DIR}/tests_tmp/test_openedx_inno_$$"
mkdir -p "$TEST_TMP_DIR"
trap 'rm -rf "$TEST_TMP_DIR"' EXIT INT TERM

printf '=== Testing Open edX Inno Setup Script Generation ===
'

APP_NAME="Open edX"
APP_VERSION="1.0.0"
APP_PUBLISHER="LibScript Contributors"
OUT_FILE="OpenEdX_Inno_Setup"

export APP_NAME APP_VERSION APP_PUBLISHER OUT_FILE

ISS_FILE="$TEST_TMP_DIR/output.iss"
"${LIBSCRIPT_ROOT_DIR}/packaging/template_inno.sh" openedx latest > "$ISS_FILE"

# ## assert_contains
# Asserts that a given string exists in the generated Inno Setup script.
assert_contains() {
  _pattern="$1"
  _desc="$2"
  if ! grep -q -- "$_pattern" "$ISS_FILE"; then
    printf '[FAIL] Assertion failed: %s (pattern: "%s")
' "$_desc" "$_pattern" >&2
    exit 1
  fi
  printf '[PASS] Verified: %s
' "$_desc"
}

assert_contains 'AppName=Open edX' "Application name"
assert_contains '[Tasks]' "Tasks section present"
assert_contains 'Name: "workers"' "Celery background workers task"
assert_contains 'Name: "demo_content"' "Demo content ingestion task"
assert_contains 'Name: "mfes"' "Micro-Frontend deployment task"
assert_contains '[Icons]' "Icons section present"
assert_contains 'Open edX Management Console' "Management console shortcut"
assert_contains 'Open edX Healthcheck' "Healthcheck shortcut"
assert_contains 'Open edX Database Console' "Database console shortcut"
assert_contains 'Open edX Backup and Restore' "Backup and restore shortcut"
assert_contains 'workers.cmd' "Worker start hook in Run section"
assert_contains 'workers.cmd' "Worker stop hook in UninstallRun section"
assert_contains 'import_demo.cmd' "Demo import hook in Run section"
assert_contains 'healthcheck.cmd' "Healthcheck hook in Run section"

printf '=== Open edX Inno Setup generation tests completed successfully! ===
'
exit 0
