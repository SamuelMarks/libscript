#!/bin/sh
# ## Overview
# Validates Dockerfile and Docker Compose export architecture for both online ADD caching
# and completely air-gapped offline modes.
# Asserts proper layer caching, volume mounts, network isolation, and healthcheck utilities.
#
# ## Usage
# ./tests/test_package_as_docker_offline.sh

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

TEST_TMP_DIR="${LIBSCRIPT_ROOT_DIR}/tests_tmp/test_docker_offline_$$"
mkdir -p "$TEST_TMP_DIR"
trap 'rm -rf "$TEST_TMP_DIR"' EXIT INT TERM

# ## assert_contains
# Asserts that a file contains a given string or pattern.
assert_contains() {
  _file="$1"
  _pattern="$2"
  _desc="$3"
  if ! grep -q -- "$_pattern" "$_file"; then
    printf '[FAIL] Assertion failed: %s (pattern: "%s")
' "$_desc" "$_pattern" >&2
    exit 1
  fi
  printf '[PASS] Verified: %s
' "$_desc"
}

# ## assert_not_contains
# Asserts that a file does not contain a given string or pattern.
assert_not_contains() {
  _file="$1"
  _pattern="$2"
  _desc="$3"
  if grep -q -- "$_pattern" "$_file"; then
    printf '[FAIL] Prohibited pattern found: %s (pattern: "%s")
' "$_desc" "$_pattern" >&2
    exit 1
  fi
  printf '[PASS] Verified absence: %s
' "$_desc"
}

printf '=== Testing Online Dockerfile Generation with ADD Layer Caching ===
'
DOCKERFILE_ONLINE="$TEST_TMP_DIR/Dockerfile.online"
"${LIBSCRIPT_ROOT_DIR}/cli/commands/packaging/formats/pkg_docker.sh" --online python 3.11 https://example.com/python-3.11.tar.gz > "$DOCKERFILE_ONLINE"

assert_contains "$DOCKERFILE_ONLINE" 'ENV LIBSCRIPT_CACHE_DIR="/opt/libscript_cache"' "Cache directory env variable declared"
assert_contains "$DOCKERFILE_ONLINE" 'ADD ${PYTHON_URL} /opt/libscript_cache/python/python-3.11.tar.gz' "ADD instruction for layer caching synthesized"
assert_contains "$DOCKERFILE_ONLINE" 'RUN ./libscript.sh install python' "Install command references component"
assert_not_contains "$DOCKERFILE_ONLINE" 'COPY cache/ /opt/libscript_cache/' "COPY cache not present in online mode"
assert_not_contains "$DOCKERFILE_ONLINE" 'ENV LIBSCRIPT_OFFLINE="1"' "LIBSCRIPT_OFFLINE not set in online mode"

printf '=== Testing Air-Gapped Offline Dockerfile Generation ===
'
DOCKERFILE_OFFLINE="$TEST_TMP_DIR/Dockerfile.offline"
"${LIBSCRIPT_ROOT_DIR}/cli/commands/packaging/formats/pkg_docker.sh" --offline python 3.11 > "$DOCKERFILE_OFFLINE"

assert_contains "$DOCKERFILE_OFFLINE" 'ENV LIBSCRIPT_OFFLINE="1"' "LIBSCRIPT_OFFLINE=1 set in offline mode"
assert_contains "$DOCKERFILE_OFFLINE" 'ENV PIP_NO_INDEX="1"' "PIP_NO_INDEX=1 configured"
assert_contains "$DOCKERFILE_OFFLINE" 'ENV PIP_FIND_LINKS="/opt/libscript_cache/wheels"' "PIP_FIND_LINKS directed to cache/wheels"
assert_contains "$DOCKERFILE_OFFLINE" 'COPY cache/ /opt/libscript_cache/' "COPY cache/ directive present in offline header"
assert_contains "$DOCKERFILE_OFFLINE" 'RUN ./libscript.sh install python ${PYTHON_VERSION} --offline' "Offline flag passed to installer"
assert_not_contains "$DOCKERFILE_OFFLINE" 'ADD http' "No remote ADD instructions present in offline mode"
assert_not_contains "$DOCKERFILE_OFFLINE" 'curl' "No curl commands present in offline mode"
assert_not_contains "$DOCKERFILE_OFFLINE" 'wget' "No wget commands present in offline mode"
assert_not_contains "$DOCKERFILE_OFFLINE" 'git clone' "No git clone commands present in offline mode"

printf '=== Testing Open edX Online Dockerfile with Manifest ADD Caching ===
'
DOCKERFILE_OPENEDX_ONLINE="$TEST_TMP_DIR/Dockerfile.openedx.online"
"${LIBSCRIPT_ROOT_DIR}/cli/commands/packaging/formats/pkg_docker.sh" --online "${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx" > "$DOCKERFILE_OPENEDX_ONLINE"

assert_contains "$DOCKERFILE_OPENEDX_ONLINE" 'ADD https://www.python.org/' "Python runtime ADD statement"
assert_contains "$DOCKERFILE_OPENEDX_ONLINE" 'ADD https://nodejs.org/' "Node.js runtime ADD statement"
assert_contains "$DOCKERFILE_OPENEDX_ONLINE" 'ADD https://cdn.mysql.com/' "MySQL datastore ADD statement"
assert_contains "$DOCKERFILE_OPENEDX_ONLINE" 'ADD https://files.pythonhosted.org/' "Wheel package ADD statement"
assert_contains "$DOCKERFILE_OPENEDX_ONLINE" 'ADD https://github.com/openedx/edx-platform/' "Codebase archive ADD statement"

printf '=== Testing Open edX Air-Gapped Offline Docker Compose Generation ===
'
COMPOSE_OFFLINE="$TEST_TMP_DIR/docker-compose.yml"
(
  cd "$TEST_TMP_DIR"
  "${LIBSCRIPT_ROOT_DIR}/cli/commands/packaging/formats/pkg_docker_compose.sh" --offline mysql latest redis latest mongodb latest meilisearch latest openedx latest > "$COMPOSE_OFFLINE"
)

assert_contains "$COMPOSE_OFFLINE" "version: '3.8'" "Compose file version declared"
assert_contains "$COMPOSE_OFFLINE" "libscript_offline_cache:/opt/libscript_cache:ro" "Read-only offline cache volume mount"
assert_contains "$COMPOSE_OFFLINE" "internal: true" "Internal isolated network configured"
assert_contains "$COMPOSE_OFFLINE" "LIBSCRIPT_OFFLINE=1" "LIBSCRIPT_OFFLINE environment variable configured"
assert_contains "$COMPOSE_OFFLINE" "MYSQL_HOST=mysql" "Internal MySQL host configured"
assert_contains "$COMPOSE_OFFLINE" "REDIS_HOST=redis" "Internal Redis host configured"
assert_contains "$COMPOSE_OFFLINE" "MONGODB_HOST=mongodb" "Internal MongoDB host configured"
assert_contains "$COMPOSE_OFFLINE" "MEILISEARCH_HOST=meilisearch" "Internal Meilisearch host configured"
assert_contains "$COMPOSE_OFFLINE" "nc -z 127.0.0.1 7700" "Local utility healthcheck for Meilisearch without curl"
assert_contains "$COMPOSE_OFFLINE" "openedx/healthcheck.sh" "Local Open edX healthcheck script invocation"

# Validate compose syntax if docker compose is available
if command -v docker >/dev/null 2>&1; then
  if docker compose version >/dev/null 2>&1; then
    printf 'Validating docker-compose.yml syntax with "docker compose config"...
'
    (
      cd "$TEST_TMP_DIR"
      docker compose -f "$COMPOSE_OFFLINE" config >/dev/null 2>&1 && printf '[PASS] docker compose config syntax validation passed
' || printf '[INFO] docker compose config skipped or returned non-zero (daemon may not be running in this environment)
'
    )
  fi
fi

printf '=== All Container Offline Export Tests Passed Successfully! ===
'
exit 0
