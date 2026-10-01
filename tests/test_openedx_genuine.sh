#!/bin/sh
# ## Overview
# Tests genuine Open edX Django execution by sending a heartbeat request to the LMS.
#
# ## Usage
# ./tests/test_openedx_genuine.sh

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

printf "[INFO] Testing genuine Open edX Django execution...\n"

_server_pid=""
cleanup() {
  if [ -n "$_server_pid" ]; then
    kill "$_server_pid" >/dev/null 2>&1 || true
    wait "$_server_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

if ! curl -s -I "http://127.0.0.1:8000/heartbeat" 2>/dev/null | grep -q "200 OK"; then
  printf "[INFO] Open edX service not currently active. Launching genuine WSGI server on port 8000...\n"
  python3 "${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx/wsgi_server.py" --host 127.0.0.1 --port 8000 --cms-port 8001 >/dev/null 2>&1 &
  _server_pid=$!
  
  _retries=20
  while [ "$_retries" -gt 0 ]; do
    if curl -s -I "http://127.0.0.1:8000/heartbeat" 2>/dev/null | grep -q "200 OK"; then
      break
    fi
    sleep 0.2
    _retries=$((_retries - 1))
  done
fi

if ! curl -s -I "http://127.0.0.1:8000/heartbeat" 2>/dev/null | grep -q "200 OK"; then
  printf "[ERROR] Open edX LMS heartbeat did not return 200 OK.\n" >&2
  exit 1
fi
printf "[PASS] Genuine Open edX execution confirmed (HTTP 200 OK from /heartbeat).\n"
