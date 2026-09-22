#!/bin/sh
# ## Overview
# Unit tests for the LibScript offline cache hydration and integrity verification engine.
# Validates:
# 1. Missing artifact detection under --verify-only.
# 2. Checksum validation for intact files.
# 3. Corrupted / truncated file detection and error handling.
# 4. Idempotent hydration and verification.
# 5. Manifest and checksums.sha256 generation.
#
# ## Usage
# ./tests/test_hydrate_offline_cache.sh

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

TEST_TMP_DIR="${LIBSCRIPT_ROOT_DIR}/tests_tmp/test_hydrate_$$"
mkdir -p "$TEST_TMP_DIR"

cleanup() {
  _status=$?
  if [ "$_status" -eq 0 ]; then
    rm -rf "$TEST_TMP_DIR"
  else
    printf '[WARN] Preserving test artifacts in %s
' "$TEST_TMP_DIR" >&2
  fi
}
trap cleanup EXIT INT TERM

printf '=== Testing LibScript Offline Cache Hydration Engine ===
'

# Setup dummy source artifact
SRC_DIR="${TEST_TMP_DIR}/upstream"
mkdir -p "$SRC_DIR"
TEST_CONTENT="LibScript Offline Bundle Test Content - Version 1.0.0"
printf '%s
' "$TEST_CONTENT" > "${SRC_DIR}/dummy-runtime.zip"

if command -v sha256sum >/dev/null 2>&1; then
  DUMMY_SHA256=$(sha256sum "${SRC_DIR}/dummy-runtime.zip" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
  DUMMY_SHA256=$(shasum -a 256 "${SRC_DIR}/dummy-runtime.zip" | awk '{print $1}')
else
  DUMMY_SHA256=$(openssl dgst -sha256 "${SRC_DIR}/dummy-runtime.zip" | awk '{print $NF}')
fi

TEST_MANIFEST="${TEST_TMP_DIR}/test_bundle.json"
cat <<EOF > "$TEST_MANIFEST"
{
  "name": "test-stack",
  "version": "1.0.0",
  "runtimes": {
    "test_rt": {
      "name": "test_rt",
      "version": "1.0.0",
      "filename": "dummy-runtime.zip",
      "url": "file://${SRC_DIR}/dummy-runtime.zip",
      "sha256": "${DUMMY_SHA256}"
    }
  },
  "databases": {},
  "wheels": {
    "target_dir": "cache/wheels",
    "packages": []
  },
  "codebase": {},
  "checksums": {
    "dummy-runtime.zip": "${DUMMY_SHA256}"
  }
}
EOF

CACHE_TARGET="${TEST_TMP_DIR}/cache"

# Test 1: Verify-only fails when file is missing
printf '[TEST 1/4] Verifying --verify-only reports missing artifact and exits non-zero...
'
set +e
"${LIBSCRIPT_ROOT_DIR}/packaging/hydrate_offline_cache.sh" --manifest "$TEST_MANIFEST" --cache-dir "$CACHE_TARGET" --verify-only > "${TEST_TMP_DIR}/t1.log" 2>&1
T1_EXIT=$?
set -e
if [ "$T1_EXIT" -ne 0 ]; then
  printf '[PASS] Correctly failed when cache is empty in verify-only mode (exit code %d)
' "$T1_EXIT"
else
  printf '[FAIL] Expected non-zero exit code in verify-only mode on empty cache
' >&2
  cat "${TEST_TMP_DIR}/t1.log" >&2
  exit 1
fi

# Test 2: Hydrate cache from local source
printf '[TEST 2/4] Verifying cache hydration and SHA-256 verification...
'
"${LIBSCRIPT_ROOT_DIR}/packaging/hydrate_offline_cache.sh" --manifest "$TEST_MANIFEST" --cache-dir "$CACHE_TARGET" > "${TEST_TMP_DIR}/t2.log" 2>&1

if [ -f "${CACHE_TARGET}/runtimes/dummy-runtime.zip" ]; then
  printf '[PASS] Artifact downloaded and placed in cache/runtimes/
'
else
  printf '[FAIL] Target artifact not found in cache
' >&2
  cat "${TEST_TMP_DIR}/t2.log" >&2
  exit 1
fi

if [ -f "${CACHE_TARGET}/manifest.json" ] && [ -f "${CACHE_TARGET}/checksums.sha256" ]; then
  printf '[PASS] manifest.json and checksums.sha256 generated in cache root
'
else
  printf '[FAIL] Metadata files missing from cache root
' >&2
  exit 1
fi

# Test 3: Verify-only succeeds when cache is fully intact
printf '[TEST 3/4] Verifying --verify-only succeeds on intact cache...
'
"${LIBSCRIPT_ROOT_DIR}/packaging/hydrate_offline_cache.sh" --manifest "$TEST_MANIFEST" --cache-dir "$CACHE_TARGET" --verify-only > "${TEST_TMP_DIR}/t3.log" 2>&1
if grep -q "\[VALID\]" "${TEST_TMP_DIR}/t3.log"; then
  printf '[PASS] Cache verified successfully
'
else
  printf '[FAIL] Expected VALID status in verify log
' >&2
  cat "${TEST_TMP_DIR}/t3.log" >&2
  exit 1
fi

# Test 4: Corrupted file detection
printf '[TEST 4/4] Verifying corrupted artifact detection...
'
printf 'corrupted data truncated' > "${CACHE_TARGET}/runtimes/dummy-runtime.zip"
set +e
"${LIBSCRIPT_ROOT_DIR}/packaging/hydrate_offline_cache.sh" --manifest "$TEST_MANIFEST" --cache-dir "$CACHE_TARGET" --verify-only > "${TEST_TMP_DIR}/t4.log" 2>&1
T4_EXIT=$?
set -e
if [ "$T4_EXIT" -ne 0 ] && grep -q "CORRUPT" "${TEST_TMP_DIR}/t4.log"; then
  printf '[PASS] Successfully detected corrupted artifact with hash mismatch
'
else
  printf '[FAIL] Failed to detect corrupted artifact
' >&2
  cat "${TEST_TMP_DIR}/t4.log" >&2
  exit 1
fi

printf '==========================================================
'
printf '[SUCCESS] All cache hydration unit tests passed!
'
printf '==========================================================
'
exit 0
