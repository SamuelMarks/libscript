#!/bin/sh
# ## Overview
# Validates NSIS installer script generation for Open edX.
# Asserts inclusion of core sections, worker sections, demo content sections,
# Micro-Frontend deployment sections, and Start Menu shortcuts.
#
# ## Usage
# ./tests/test_openedx_nsis_generation.sh

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

TEST_TMP_DIR="${LIBSCRIPT_ROOT_DIR}/tests_tmp/test_openedx_nsis_$$"
mkdir -p "$TEST_TMP_DIR"
trap 'rm -rf "$TEST_TMP_DIR"' EXIT INT TERM

printf '=== Testing Open edX NSIS Script Generation ===
'

APP_NAME="Open edX"
APP_VERSION="1.0.0"
APP_PUBLISHER="LibScript Contributors"
OUT_FILE="OpenEdX_NSIS_Setup"

export APP_NAME APP_VERSION APP_PUBLISHER OUT_FILE

NSI_FILE="$TEST_TMP_DIR/output.nsi"
"${LIBSCRIPT_ROOT_DIR}/packaging/template_nsis.sh" openedx latest > "$NSI_FILE"

# ## assert_contains
# Asserts that a given string exists in the generated NSIS script.
assert_contains() {
  _pattern="$1"
  _desc="$2"
  if ! grep -q -- "$_pattern" "$NSI_FILE"; then
    printf '[FAIL] Assertion failed: %s (pattern: "%s")
' "$_desc" "$_pattern" >&2
    exit 1
  fi
  printf '[PASS] Verified: %s
' "$_desc"
}

assert_contains '!define APP_NAME "Open edX"' "Application name"
assert_contains 'Section "openedx" SEC_openedx' "Core Open edX section"
assert_contains 'healthcheck.cmd' "Post-install healthcheck execution"
assert_contains 'SEC_openedx_workers' "Celery workers section"
assert_contains 'workers.cmd' "Worker execution in workers section"
assert_contains 'SEC_openedx_demo' "Demo content ingestion section"
assert_contains 'SEC_openedx_mfes' "Micro-Frontend deployment section"
assert_contains 'SEC_openedx_shortcuts' "Administrative shortcuts section"
assert_contains 'Open edX Management Console.lnk' "Management console shortcut"
assert_contains 'Open edX Healthcheck.lnk' "Healthcheck shortcut"
assert_contains 'Open edX Database Console.lnk' "Database console shortcut"
assert_contains 'Open edX Backup and Restore.lnk' "Backup and restore shortcut"
assert_contains 'Section "Uninstall"' "Uninstaller section"

printf '=== Open edX NSIS generation tests completed successfully! ===
'
exit 0
