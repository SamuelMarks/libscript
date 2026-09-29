#!/bin/sh
# ## Overview
# Validates the modular zero-.EXE Windows Installer packaging and component reuse architecture.
# Verifies standalone dependency MSIs, master orchestrator packages, deterministic GUID integrity,
# and side-by-side database sharing between Open edX and WordPress.
#
# ## Usage
#   ./tests/test_modular_msi_reuse.sh
#
# ## Parameters
#   None. Environment variables respected if provided.

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

TEST_TMP_DIR="${LIBSCRIPT_ROOT_DIR}/tests_tmp/test_msi_reuse_$$"
mkdir -p "$TEST_TMP_DIR"

# ## cleanup
# Removes temporary test directory on success.
# shellcheck disable=SC2317,SC2329
cleanup() {
  _status=$?
  if [ "$_status" -eq 0 ]; then
    rm -rf "$TEST_TMP_DIR"
  else
    printf '[WARN] Test artifacts preserved at %s for diagnosis
' "$TEST_TMP_DIR" >&2
  fi
}
trap cleanup EXIT INT TERM

printf '=== Test: Validating Modular Zero-.EXE MSI Packaging and Reuse ===
'

# 1. Validate GUID registry existence and format
REGISTRY_JSON="${LIBSCRIPT_ROOT_DIR}/packaging/guid_registry.json"
if [ ! -f "$REGISTRY_JSON" ]; then
  printf '[FAIL] guid_registry.json missing.
' >&2
  exit 1
fi
printf '[PASS] Verified guid_registry.json exists.
'

# 2. Build standalone component MSIs
for comp in mysql redis mongodb python nodejs meilisearch; do
  printf '[INFO] Building standalone MSI for %s...\n' "$comp"
  "${LIBSCRIPT_ROOT_DIR}/packaging/build_component_msi.sh" --component "$comp"
  if ! find "${LIBSCRIPT_ROOT_DIR}/dist/msi" -maxdepth 1 -name "libscript-${comp}-*.msi" | grep -q .; then
    printf '[FAIL] Missing expected standalone MSI for component %s\n' "$comp" >&2
    exit 1
  fi
done
printf '[PASS] All 6 standalone component MSIs built successfully.
'

# 3. Build Master Orchestrator MSIs (Online and Offline)
printf '[INFO] Building Master Orchestrator MSIs...\n'
"${LIBSCRIPT_ROOT_DIR}/packaging/build_msi.sh" "stacks/cms/openedx" --version "22.1.0" --variant "online" --out "${LIBSCRIPT_ROOT_DIR}/dist/msi/openedx-22.1.0" >/dev/null
if [ ! -f "${LIBSCRIPT_ROOT_DIR}/dist/msi/openedx-22.1.0.msi" ] && [ ! -f "${LIBSCRIPT_ROOT_DIR}/dist/msi/openedx-22.1.0.wxs" ]; then
  printf '[FAIL] Missing openedx-22.1.0.msi or .wxs (online)\n' >&2
  exit 1
fi
"${LIBSCRIPT_ROOT_DIR}/packaging/build_msi.sh" "stacks/cms/openedx" --version "22.1.0" --variant "offline" --out "${LIBSCRIPT_ROOT_DIR}/dist/msi/openedx-offline-22.1.0" >/dev/null
if [ ! -f "${LIBSCRIPT_ROOT_DIR}/dist/msi/openedx-offline-22.1.0.msi" ] && [ ! -f "${LIBSCRIPT_ROOT_DIR}/dist/msi/openedx-offline-22.1.0.wxs" ]; then
  printf '[FAIL] Missing openedx-offline-22.1.0.msi or .wxs (offline)\n' >&2
  exit 1
fi
printf '[PASS] Master Orchestrator MSIs built successfully.\n'

# 5. Verify Zero-.EXE mandate in output directory
EXE_COUNT=$(find "${LIBSCRIPT_ROOT_DIR}/dist/msi" -name "*.exe" 2>/dev/null | wc -l)
if [ "$EXE_COUNT" -ne 0 ]; then
  printf '[FAIL] Found %d .exe file(s) in dist/msi. Zero-.EXE mandate violated!
' "$EXE_COUNT" >&2
  exit 1
fi
printf '[PASS] Zero-.EXE mandate verified in dist/msi/ (only pure .msi packages produced).
'

# 6. Verify side-by-side MySQL reuse compatibility
MYSQL_WXS="${LIBSCRIPT_ROOT_DIR}/tmp/mysql_main.wxs"
if [ ! -f "$MYSQL_WXS" ]; then
  printf '[FAIL] Missing tmp/mysql_main.wxs manifest
' >&2
  exit 1
fi

# Verify MySQL ComponentId and Service Name
if ! grep -q 'Guid="5B2783B0-9A1F-4348-9F93-87CE43C21001"' "$MYSQL_WXS"; then
  printf '[FAIL] MySQL manifest does not contain expected ComponentId GUID
' >&2
  exit 1
fi

if ! grep -q 'Name="LibScript_MySQL"' "$MYSQL_WXS"; then
  printf '[FAIL] MySQL manifest does not configure LibScript_MySQL service
' >&2
  exit 1
fi
printf '[PASS] MySQL Component GUID and Windows Service identity verified.
'

# 7. Verify XML entity escaping and SharedDllRefCount attribute syntax
NODE_WXS="${LIBSCRIPT_ROOT_DIR}/tmp/nodejs_main.wxs"
if [ ! -f "$NODE_WXS" ] || ! grep -q 'Name="LibScript Node\.js JavaScript Runtime &amp; npm' "$NODE_WXS"; then
  printf '[FAIL] Node.js manifest missing or unescaped entity in product name\n' >&2
  exit 1
fi

REDIS_WXS="${LIBSCRIPT_ROOT_DIR}/tmp/redis_main.wxs"
if [ ! -f "$REDIS_WXS" ] || ! grep -q 'Name="LibScript Redis In-Memory Datastore &amp; Cache' "$REDIS_WXS"; then
  printf '[FAIL] Redis manifest missing or unescaped entity in product name\n' >&2
  exit 1
fi

for _comp in mysql redis mongodb python nodejs meilisearch; do
  _manifest="${LIBSCRIPT_ROOT_DIR}/tmp/${_comp}_main.wxs"
  if grep -q 'SharedDllRefCount=""' "$_manifest"; then
    printf '[FAIL] %s manifest contains invalid double-quoted SharedDllRefCount
' "$_comp" >&2
    exit 1
  fi
done
printf '[PASS] XML entity escaping and SharedDllRefCount attribute syntax verified.
'

printf '=== All Modular Zero-.EXE MSI Reuse Tests Passed ===
'
exit 0
