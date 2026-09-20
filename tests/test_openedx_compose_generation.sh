#!/bin/sh
# ## Overview
# Validates Docker Compose multi-container configuration generation for Open edX.
# Asserts declaration of LMS, Studio CMS, Celery workers, Celery Beat, supporting datastores,
# healthchecks, and persistent volume definitions.
#
# ## Usage
# ./tests/test_openedx_compose_generation.sh

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

TEST_TMP_DIR="${LIBSCRIPT_ROOT_DIR}/tests_tmp/test_openedx_compose_$$"
mkdir -p "$TEST_TMP_DIR"
trap 'rm -rf "$TEST_TMP_DIR"' EXIT INT TERM

printf '=== Testing Open edX Docker Compose Generation ===
'

YML_FILE="$TEST_TMP_DIR/docker-compose.yml"
(
  cd "$TEST_TMP_DIR"
  "${LIBSCRIPT_ROOT_DIR}/cli/commands/packaging/formats/pkg_docker_compose.sh" mysql latest redis latest mongodb latest meilisearch latest openedx latest > "$YML_FILE"
)

# ## assert_contains
# Asserts that a given pattern exists in the generated docker-compose.yml file.
assert_contains() {
  _pattern="$1"
  _desc="$2"
  if ! grep -q -- "$_pattern" "$YML_FILE"; then
    printf '[FAIL] Assertion failed: %s (pattern: "%s")
' "$_desc" "$_pattern" >&2
    exit 1
  fi
  printf '[PASS] Verified: %s
' "$_desc"
}

assert_contains "version: '3.8'" "Compose file version"
assert_contains "services:" "Services section present"
assert_contains "  mysql:" "MySQL database service"
assert_contains "  redis:" "Redis caching service"
assert_contains "  mongodb:" "MongoDB datastore service"
assert_contains "  meilisearch:" "Meilisearch service"
assert_contains "  openedx:" "Open edX core web service"
assert_contains '8000:8000' "LMS port mapping"
assert_contains '8001:8001' "CMS Studio port mapping"
assert_contains "  openedx-workers:" "Celery background workers service"
assert_contains "  openedx-beat:" "Celery Beat periodic scheduler service"
assert_contains "healthcheck:" "Healthcheck probe definition"
assert_contains "openedx/healthcheck.sh" "Open edX healthcheck script invocation"
assert_contains "volumes:" "Volumes section declared"
assert_contains "openedx_data:" "Persistent data volume declared"
assert_contains "openedx_logs:" "Persistent logs volume declared"
assert_contains "openedx_media:" "Persistent media uploads volume declared"
assert_contains "openedx_backups:" "Persistent automated backups volume declared"

printf '=== Open edX Docker Compose generation tests completed successfully! ===
'
exit 0
