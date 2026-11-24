#!/bin/sh
# ## Overview
# Hermetic build and integration test suite for the native C11 libscript-rest-api server,
# verifying RFC 8259 JSON, CSPRNG UUIDv4s, path-traversal rejection, and live HTTP/1.1 job polling.
# ## Usage
# ./tests/test_rest_api.sh
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
if ! command -v cmake >/dev/null 2>&1; then
  printf '[SKIP] cmake not installed; skipping C11 REST API build test.\n'
  exit 0
fi
TEST_TMP="${LIBSCRIPT_ROOT_DIR}/tests_tmp/rest_api_$$"
SRV_PID=''
mkdir -p "$TEST_TMP"

# ## cleanup_tmp
# Terminates any background HTTP test server and removes temporary build artifacts.
cleanup_tmp() {
  if [ -n "${SRV_PID:-}" ]; then
    kill "$SRV_PID" 2>/dev/null || true
    wait "$SRV_PID" 2>/dev/null || true
    SRV_PID=''
  fi
  rm -rf "$TEST_TMP"
}
trap 'cleanup_tmp' EXIT INT TERM

# ## fail_test
# Prints an error message and exits 1.
fail_test() {
  printf '[FAIL] %s\n' "$1" >&2
  exit 1
}

cmake -S "${LIBSCRIPT_ROOT_DIR}/libscript-rest-api" -B "${TEST_TMP}/build" >/dev/null
cmake --build "${TEST_TMP}/build" >/dev/null
REST_BIN="${TEST_TMP}/build/bin/libscript-rest-api"
[ -x "$REST_BIN" ] || fail_test "Built binary not found at ${REST_BIN}"

# 1. Valid RFC 8259 double-quoted JSON and unique CSPRNG UUIDv4s
J1=$("$REST_BIN" --dispatch-artifact rtos-zephyr firmware-uf2 sqlite qemu_cortex_m3)
J2=$("$REST_BIN" --dispatch-experiment gemma-4-sql tpu_matrix linux-x86_64)
ID1=$(printf '%s\n' "$J1" | jq -er '.job_id')
ID2=$(printf '%s\n' "$J2" | jq -er '.job_id')
[ "$ID1" != "$ID2" ] || fail_test "Expected unique CSPRNG UUIDv4s, got identical ${ID1}"
printf '%s\n' "$ID1" | grep -Eq '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' || fail_test "Invalid UUIDv4 format: ${ID1}"

# 2. Traversal and option-injection rejection
if "$REST_BIN" --dispatch topology up '../etc/passwd' >/dev/null 2>&1; then
  fail_test 'Expected ../etc/passwd traversal token to be rejected'
fi
if "$REST_BIN" --dispatch topology up '-malicious-flag' >/dev/null 2>&1; then
  fail_test 'Expected leading-dash option injection token to be rejected'
fi
printf '[PASS] CLI dispatch emits valid RFC 8259 JSON, unique UUIDv4s, and rejects traversal/injection tokens.\n'

# 3. Live HTTP/1.1 socket server + job status polling
if command -v curl >/dev/null 2>&1; then
  PORT_FILE="${TEST_TMP}/bound.port"
  "$REST_BIN" --bind 127.0.0.1 --port 0 --max-requests 10 --port-file "$PORT_FILE" >"${TEST_TMP}/srv.log" 2>&1 &
  SRV_PID=$!
  _tries=0
  while [ ! -s "$PORT_FILE" ] && [ "$_tries" -lt 50 ]; do
    sleep 0.1
    _tries=$((_tries + 1))
  done
  [ -s "$PORT_FILE" ] || fail_test 'HTTP server did not write bound port file'
  BOUND_PORT=$(tr -d '\r\n ' < "$PORT_FILE")

  # libscript-allow-raw-curl
  HEALTH_JSON=$(curl -fsS "http://127.0.0.1:${BOUND_PORT}/api/v1/health")
  [ "$(printf '%s\n' "$HEALTH_JSON" | jq -r '.status')" = 'ok' ] || fail_test "Unexpected /api/v1/health response: ${HEALTH_JSON}"

  # libscript-allow-raw-curl
  CAP_JSON=$(curl -fsS "http://127.0.0.1:${BOUND_PORT}/v1/recipes/glibc/capabilities")
  [ "$(printf '%s\n' "$CAP_JSON" | jq -r '.tier')" = 'T2' ] || fail_test "Expected T2 tier for glibc in /v1/recipes/glibc/capabilities, got: ${CAP_JSON}"

  # libscript-allow-raw-curl
  WL_JSON=$(curl -fsS -X POST "http://127.0.0.1:${BOUND_PORT}/v1/workloads" \
    -H 'Content-Type: application/json' \
    -d '{"action":"compile","target":"workloads/payloads/ai/vllm/payload.json"}')
  printf '%s\n' "$WL_JSON" | jq -er '.job_id' >/dev/null || fail_test "Expected job_id from POST /v1/workloads: ${WL_JSON}"

  # libscript-allow-raw-curl
  SUB_JSON=$(curl -fsS -X POST "http://127.0.0.1:${BOUND_PORT}/v1/synthesis" \
    -H 'Content-Type: application/json' \
    -d '{"kernel":"rtos-zephyr","format":"firmware-uf2","components":"sqlite","board":"qemu_cortex_m3"}')
  HTTP_JOB_ID=$(printf '%s\n' "$SUB_JSON" | jq -er '.job_id')

  # libscript-allow-raw-curl
  POLL_JSON=$(curl -fsS "http://127.0.0.1:${BOUND_PORT}/api/v1/jobs/${HTTP_JOB_ID}")
  [ "$(printf '%s\n' "$POLL_JSON" | jq -r '.status')" = 'succeeded' ] || fail_test "Unexpected job poll state: ${POLL_JSON}"

  # libscript-allow-raw-curl
  PKG_CAT=$(curl -fsS "http://127.0.0.1:${BOUND_PORT}/v1/package-as")
  printf '%s\n' "$PKG_CAT" | jq -er '.targets | index("linux-distro")' >/dev/null || fail_test "Missing linux-distro in GET /v1/package-as: ${PKG_CAT}"

  # libscript-allow-raw-curl
  PKG_JOB=$(curl -fsS -X POST "http://127.0.0.1:${BOUND_PORT}/v1/package-as" \
    -H 'Content-Type: application/json' \
    -d '{"target":"linux-distro","profile":"linux-minimal-headless-musl","format":"qcow2"}')
  PKG_JOB_ID=$(printf '%s\n' "$PKG_JOB" | jq -er '.job_id')

  # libscript-allow-raw-curl
  PKG_POLL=$(curl -fsS "http://127.0.0.1:${BOUND_PORT}/api/v1/jobs/${PKG_JOB_ID}")
  [ "$(printf '%s\n' "$PKG_POLL" | jq -r '.status')" = 'succeeded' ] || fail_test "Unexpected /v1/package-as job poll state: ${PKG_POLL}"

  # libscript-allow-raw-curl
  PKG_BAD=$(curl -sS -o /dev/null -w '%{http_code}' -X POST "http://127.0.0.1:${BOUND_PORT}/v1/package-as" \
    -H 'Content-Type: application/json' \
    -d '{"target":"linux-distro","profile":"../../etc/passwd","format":"qcow2"}')
  [ "$PKG_BAD" = '400' ] || fail_test "Expected HTTP 400 on /v1/package-as traversal profile, got ${PKG_BAD}"

  # libscript-allow-raw-curl
  BAD_CODE=$(curl -sS -o /dev/null -w '%{http_code}' -X POST "http://127.0.0.1:${BOUND_PORT}/api/v1/artifacts/generate" \
    -H 'Content-Type: application/json' \
    -d '{"kernel":"rtos-zephyr","format":"firmware-uf2","components":"../../etc/passwd"}')
  [ "$BAD_CODE" = '400' ] || fail_test "Expected HTTP 400 on traversal payload, got ${BAD_CODE}"

  wait "$SRV_PID"
  SRV_PID=''
  printf '[PASS] C11 HTTP/1.1 listener served /api/v1/health, /api/v1/artifacts/generate, /api/v1/jobs/{id}, and rejected traversal with HTTP 400.\n'
fi
cleanup_tmp
exit 0
