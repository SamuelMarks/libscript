#!/bin/sh
# ## Overview
# End-to-end regression test verifying multi-component PATH inheritance,
# transitive stack resolution (nodejs + postgres + python + uv + duckdb),
# environment variable persistence, and strict PATH idempotency on repeated hydration.
#
# ## Usage
# ./tests/test_path_inheritance.sh

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

TEST_TMP=$(mktemp -d 2>/dev/null || printf '%s' "${TMPDIR:-/tmp}/libscript_test_path_inh.$$")
mkdir -p "${TEST_TMP}/home/.libscript/nodejs/lts/bin"
mkdir -p "${TEST_TMP}/home/.libscript/python/3.12/bin"
mkdir -p "${TEST_TMP}/home/.libscript/uv/latest/bin"
mkdir -p "${TEST_TMP}/home/.libscript/postgres/17/bin"
mkdir -p "${TEST_TMP}/home/.libscript/duckdb/latest/bin"

cat << 'EOF_MANIFEST' > "${TEST_TMP}/libscript.json"
{
  "name": "backend-deploy-test",
  "dependencies": {
    "nodejs": "lts",
    "python": "3.12",
    "uv": "latest"
  },
  "databases": {
    "primary_pg": {
      "engine": "postgres",
      "version": "17",
      "name": "app_db",
      "user": "app_user"
    },
    "analytics_duck": {
      "engine": "duckdb",
      "path": "${DATA_DIR:-./data}/analytics.duckdb"
    }
  }
}
EOF_MANIFEST

export LIBSCRIPT_HOME="${TEST_TMP}/home/.libscript"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_printer.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

# 1. Hydrate manifest environment (Pass 1)
libscript_hydrate_manifest_env "${TEST_TMP}/libscript.json"
PATH_PASS_1="$PATH"

# Verify all 5 component bin paths are present in PATH simultaneously
for req_seg in \
  "${LIBSCRIPT_HOME}/nodejs/lts/bin" \
  "${LIBSCRIPT_HOME}/python/3.12/bin" \
  "${LIBSCRIPT_HOME}/uv/latest/bin" \
  "${LIBSCRIPT_HOME}/postgres/17/bin" \
  "${LIBSCRIPT_HOME}/duckdb/latest/bin"; do
  case ":${PATH_PASS_1}:" in
    *":${req_seg}:"*) ;;
    *)
      printf '[FAIL] Missing expected component PATH segment: %s\nActual PATH: %s\n' "$req_seg" "$PATH_PASS_1" >&2
      rm -rf "$TEST_TMP"
      exit 1
      ;;
  esac
done

# Verify environment variables were exported
if [ -z "${POSTGRES_URL:-}" ] || [ -z "${PYTHON_VERSION:-}" ] || [ -z "${NODEJS_VERSION:-}" ]; then
  printf '[FAIL] Component environment variables (POSTGRES_URL, PYTHON_VERSION, NODEJS_VERSION) were not exported!\n' >&2
  rm -rf "$TEST_TMP"
  exit 1
fi

# 2. Hydrate manifest environment a second time (Pass 2 - Idempotency Check)
libscript_hydrate_manifest_env "${TEST_TMP}/libscript.json"
PATH_PASS_2="$PATH"

if [ "$PATH_PASS_1" != "$PATH_PASS_2" ]; then
  printf '[FAIL] PATH mutated on second hydration (idempotency violation)!\nPass 1: %s\nPass 2: %s\n' "$PATH_PASS_1" "$PATH_PASS_2" >&2
  rm -rf "$TEST_TMP"
  exit 1
fi

# 3. Verify pure POSIX variable expansion
EXPANDED_VAL=$(libscript_expand_manifest_vars '${DATA_DIR:-/var/data}/analytics.duckdb')
if [ "$EXPANDED_VAL" != "/var/data/analytics.duckdb" ]; then
  printf '[FAIL] libscript_expand_manifest_vars returned "%s" (expected "/var/data/analytics.duckdb")\n' "$EXPANDED_VAL" >&2
  rm -rf "$TEST_TMP"
  exit 1
fi

rm -rf "$TEST_TMP"
printf '[PASS] Multi-component PATH inheritance and idempotency verified successfully.\n'
exit 0
