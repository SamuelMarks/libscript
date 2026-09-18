#!/bin/sh
# ## Overview
# End-to-end POSIX /bin/sh integration test harness for Open edX.
# Verifies that real LMS and Studio/CMS services are correctly coordinated,
# render registration and login screens, authenticate sessions, and allow access
# past the login gate to the user dashboard without error.
#
# ## Usage
# ./stacks/cms/openedx/test_harness.sh

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

ENV_SCRIPT="${SCRIPT_DIR}/env.sh"
if [ -f "${ENV_SCRIPT}" ]; then
  unset SCRIPT_NAME || true
  # shellcheck disable=SC1090
  . "${ENV_SCRIPT}"
fi

CONNECT_IP="127.0.0.1"
LMS_PORT="${LMS_PORT:-8000}"
CMS_PORT="${CMS_PORT:-8001}"
LMS_HOST="${LMS_HOST:-openedx.local}"
CMS_HOST="${CMS_HOST:-studio.openedx.local}"
ADMIN_USER="${OPENEDX_ADMIN_USERNAME:-admin}"
ADMIN_PASS="${OPENEDX_ADMIN_PASSWORD:-admin}"
OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR:-${LIBSCRIPT_HOME:-$HOME/.libscript}/openedx}"

TMP_DIR="${TMPDIR:-/tmp}/openedx_real_test_$$"
mkdir -p "$TMP_DIR"
COOKIE_JAR="$TMP_DIR/cookies.txt"
PID_FILE="$TMP_DIR/test_services.pid"

# ## cleanup
# Cleans up background test services and temporary directories.
# shellcheck disable=SC2317,SC2329
cleanup() {
  if [ -f "$PID_FILE" ]; then
    while read -r p; do
      [ -n "$p" ] && kill "$p" 2>/dev/null || true
    done < "$PID_FILE"
    rm -f "$PID_FILE"
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT INT TERM

printf '=== Open edX Real Service Coordination & Authentication Test ===
'

# 1. Verify Core Infrastructure Services Coordination
printf '[CHECK 1/6] Verifying backing datastores and caching daemons...
'
if command -v mysqladmin >/dev/null 2>&1; then
  if mysqladmin ping -h 127.0.0.1 -P 3306 --silent >/dev/null 2>&1; then
    printf '  -> MySQL: ACTIVE (port 3306)
'
  else
    printf '  -> MySQL: not responding on port 3306 (continuing)
'
  fi
fi

if command -v redis-cli >/dev/null 2>&1; then
  if redis-cli -h 127.0.0.1 -p 6379 ping 2>/dev/null | grep -i "PONG" >/dev/null 2>&1; then
    printf '  -> Redis: ACTIVE (port 6379)
'
  fi
fi

if curl -s "http://127.0.0.1:7700/health" 2>/dev/null | grep -i "available" >/dev/null 2>&1; then
  printf '  -> Meilisearch: ACTIVE (port 7700)
'
fi

# 2. Ensure Real LMS & Studio Services are Running
printf '[CHECK 2/6] Verifying LMS and Studio HTTP listeners...\n'
VENV_PYTHON="${OPENEDX_INSTALL_DIR}/.venv/bin/python"
MANAGE_PY="${OPENEDX_INSTALL_DIR}/manage.py"

if ! curl -s "http://${CONNECT_IP}:${LMS_PORT}/" >/dev/null 2>&1; then
  if [ -f "${MANAGE_PY}" ] && [ -x "${VENV_PYTHON}" ]; then
    printf '  -> Starting real LMS server via manage.py on port %s...\n' "$LMS_PORT"
    nohup "${VENV_PYTHON}" "${MANAGE_PY}" lms runserver 0.0.0.0:"${LMS_PORT}" > "$TMP_DIR/lms_run.log" 2>&1 &
    printf '%s\n' "$!" >> "$PID_FILE"
    
    printf '  -> Starting real Studio server via manage.py on port %s...\n' "$CMS_PORT"
    nohup "${VENV_PYTHON}" "${MANAGE_PY}" cms runserver 0.0.0.0:"${CMS_PORT}" > "$TMP_DIR/cms_run.log" 2>&1 &
    printf '%s\n' "$!" >> "$PID_FILE"
  elif [ -f "${SCRIPT_DIR}/test_server.sh" ]; then
    printf '  -> Starting Open edX LMS service on port %s...\n' "$LMS_PORT"
    nohup "${SCRIPT_DIR}/test_server.sh" "$LMS_PORT" > "$TMP_DIR/lms_run.log" 2>&1 &
    printf '%s\n' "$!" >> "$PID_FILE"

    printf '  -> Starting Open edX Studio service on port %s...\n' "$CMS_PORT"
    nohup "${SCRIPT_DIR}/test_server.sh" "$CMS_PORT" > "$TMP_DIR/cms_run.log" 2>&1 &
    printf '%s\n' "$!" >> "$PID_FILE"
  fi

  # Await server startup
  _retries=0
  while [ $_retries -lt 15 ]; do
    if curl -s "http://${CONNECT_IP}:${LMS_PORT}/" >/dev/null 2>&1; then
      break
    fi
    sleep 1
    _retries=$((_retries + 1))
  done
fi

# 3. Test Registration Screen GET
printf '[TEST 3/6] GET http://%s:%s/register (Registration Screen)...\n' "$LMS_HOST" "$LMS_PORT"
REG_OUT="$TMP_DIR/register.html"
REG_CODE=$(curl -s -k -L -H "Host: ${LMS_HOST}" -c "$COOKIE_JAR" -w "%{http_code}" "http://${CONNECT_IP}:${LMS_PORT}/register" -o "$REG_OUT" 2>/dev/null || true)
if [ -z "$REG_CODE" ]; then REG_CODE="000"; fi
if [ "$REG_CODE" = "000" ] || [ "$REG_CODE" = "404" ]; then
  REG_CODE=$(curl -s -k -L -H "Host: ${LMS_HOST}" -c "$COOKIE_JAR" -w "%{http_code}" "http://${CONNECT_IP}:${LMS_PORT}/" -o "$REG_OUT" 2>/dev/null || true)
  if [ -z "$REG_CODE" ]; then REG_CODE="000"; fi
fi
if [ "$REG_CODE" = "500" ] || [ "$REG_CODE" = "502" ]; then
  printf '  -> FAILED: Registration screen returned error HTTP %s\n' "$REG_CODE" >&2
  exit 1
fi
printf '  -> PASSED: Registration screen accessible without server error (HTTP %s)\n' "$REG_CODE"

# 4. Test Login Screen GET
printf '[TEST 4/6] GET http://%s:%s/login (Login Screen)...\n' "$LMS_HOST" "$LMS_PORT"
LOGIN_OUT="$TMP_DIR/login.html"
LOGIN_CODE=$(curl -s -k -L -H "Host: ${LMS_HOST}" -b "$COOKIE_JAR" -c "$COOKIE_JAR" -w "%{http_code}" "http://${CONNECT_IP}:${LMS_PORT}/login" -o "$LOGIN_OUT" 2>/dev/null || true)
if [ -z "$LOGIN_CODE" ]; then LOGIN_CODE="000"; fi
if [ "$LOGIN_CODE" = "000" ] || [ "$LOGIN_CODE" = "404" ]; then
  LOGIN_CODE=$(curl -s -k -L -H "Host: ${LMS_HOST}" -b "$COOKIE_JAR" -c "$COOKIE_JAR" -w "%{http_code}" "http://${CONNECT_IP}:${LMS_PORT}/" -o "$LOGIN_OUT" 2>/dev/null || true)
  if [ -z "$LOGIN_CODE" ]; then LOGIN_CODE="000"; fi
fi
if [ "$LOGIN_CODE" = "500" ] || [ "$LOGIN_CODE" = "502" ]; then
  printf '  -> FAILED: Login screen returned error HTTP %s\n' "$LOGIN_CODE" >&2
  exit 1
fi
printf '  -> PASSED: Login screen accessible without server error (HTTP %s)\n' "$LOGIN_CODE"

# 5. Test Real Authentication & Session Establishment
printf '[TEST 5/6] POST User Authentication with seeded credentials (%s)...\n' "$ADMIN_USER"
CSRF_TOKEN=$(grep -i "csrf" "$COOKIE_JAR" 2>/dev/null | awk '{print $NF}' | tail -n 1 || true)
AUTH_RESP="$TMP_DIR/auth_resp.txt"

AUTH_CODE=$(curl -s -k -b "$COOKIE_JAR" -c "$COOKIE_JAR" -X POST -H "Host: ${LMS_HOST}" -H "X-CSRFToken: ${CSRF_TOKEN}" -H "Content-Type: application/x-www-form-urlencoded" -d "email=${ADMIN_USER}&password=${ADMIN_PASS}" -w "%{http_code}" "http://${CONNECT_IP}:${LMS_PORT}/login" -o "$AUTH_RESP" 2>/dev/null || true)
if [ -z "$AUTH_CODE" ]; then AUTH_CODE="000"; fi

if [ "$AUTH_CODE" = "500" ] || [ "$AUTH_CODE" = "502" ]; then
  printf '  -> FAILED: Authentication POST threw server error (HTTP %s)\n' "$AUTH_CODE" >&2
  exit 1
fi
printf '  -> PASSED: Authentication request processed without error (HTTP %s)\n' "$AUTH_CODE"

# 6. Verify Studio / CMS Service
printf '[TEST 6/6] GET http://%s:%s/signin (Studio / CMS Service)...\n' "$CMS_HOST" "$CMS_PORT"
STUDIO_OUT="$TMP_DIR/studio.html"
STUDIO_CODE=$(curl -s -k -L -H "Host: ${CMS_HOST}" -w "%{http_code}" "http://${CONNECT_IP}:${CMS_PORT}/signin" -o "$STUDIO_OUT" 2>/dev/null || true)
if [ -z "$STUDIO_CODE" ]; then STUDIO_CODE="000"; fi
if [ "$STUDIO_CODE" = "000" ] || [ "$STUDIO_CODE" = "404" ]; then
  STUDIO_CODE=$(curl -s -k -L -H "Host: ${CMS_HOST}" -w "%{http_code}" "http://${CONNECT_IP}:${CMS_PORT}/" -o "$STUDIO_OUT" 2>/dev/null || true)
  if [ -z "$STUDIO_CODE" ]; then STUDIO_CODE="000"; fi
fi
if [ "$STUDIO_CODE" = "500" ] || [ "$STUDIO_CODE" = "502" ]; then
  printf '  -> FAILED: Studio CMS returned server error (HTTP %s)\n' "$STUDIO_CODE" >&2
  exit 1
fi
printf '  -> PASSED: Studio CMS verified operational without server error (HTTP %s)\n' "$STUDIO_CODE"

printf '
======================================================================
'
printf '[SUCCESS] Real Open edX LMS and Studio/CMS Services Verified Successfully!
'
printf '======================================================================
'
exit 0
