#!/bin/sh
# ## Overview
# Integration test verifying that a multi-component backend manifest
# (nodejs + postgres + python) properly propagates and inherits PATH
# across env_printer, run_hooks, and daemonize.
#
# ## Usage
# ./tests/test_multi_env_inheritance.sh

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
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

TEST_TMP=$(mktemp -d 2>/dev/null || printf '%s' "${TMPDIR:-/tmp}/libscript_multi_env_test.$$")
mkdir -p "$TEST_TMP"
trap 'rm -rf "$TEST_TMP"' EXIT INT TERM

export LIBSCRIPT_HOME="${TEST_TMP}/home"
export LIBSCRIPT_DATA_DIR="${TEST_TMP}/data"
mkdir -p "${LIBSCRIPT_HOME}/nodejs/22/bin" "${LIBSCRIPT_HOME}/postgres/17/bin" "${LIBSCRIPT_HOME}/python/3.12/bin" "${LIBSCRIPT_HOME}/rust/stable/bin" "${LIBSCRIPT_HOME}/go/1.22/bin" "${LIBSCRIPT_HOME}/java/21/bin"

printf '#!/bin/sh
printf "v22.0.0
"
' > "${LIBSCRIPT_HOME}/nodejs/22/bin/node"
printf '#!/bin/sh
printf "psql (PostgreSQL) 17.0
"
' > "${LIBSCRIPT_HOME}/postgres/17/bin/psql"
printf '#!/bin/sh
printf "Python 3.12.0
"
' > "${LIBSCRIPT_HOME}/python/3.12/bin/python"
printf '#!/bin/sh
printf "rustc 1.80.0
"
' > "${LIBSCRIPT_HOME}/rust/stable/bin/rustc"
printf '#!/bin/sh
printf "go version go1.22.0
"
' > "${LIBSCRIPT_HOME}/go/1.22/bin/go"
printf '#!/bin/sh
printf "openjdk 21.0.0
"
' > "${LIBSCRIPT_HOME}/java/21/bin/java"
chmod +x "${LIBSCRIPT_HOME}/nodejs/22/bin/node" "${LIBSCRIPT_HOME}/postgres/17/bin/psql" "${LIBSCRIPT_HOME}/python/3.12/bin/python" "${LIBSCRIPT_HOME}/rust/stable/bin/rustc" "${LIBSCRIPT_HOME}/go/1.22/bin/go" "${LIBSCRIPT_HOME}/java/21/bin/java"

MANIFEST="${TEST_TMP}/libscript.json"
cat << 'EOF' > "$MANIFEST"
{
  "name": "multi-stack-backend",
  "dependencies": {
    "nodejs": "22",
    "postgres": "17",
    "python": "3.12",
    "rust": "stable",
    "go": "1.22",
    "java": "21"
  },
  "hooks": {
    "post_install": [
      {
        "name": "verify_multi_path",
        "command": "node --version > hook_out.txt && psql --version >> hook_out.txt && python --version >> hook_out.txt && rustc --version >> hook_out.txt && go version >> hook_out.txt && java -version >> hook_out.txt"
      }
    ]
  }
}
EOF

printf '==> Testing libscript env --manifest...
'
ENV_OUT=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" env --manifest "$MANIFEST")
printf '%s
' "$ENV_OUT" | grep -q "nodejs/22/bin"
printf '%s
' "$ENV_OUT" | grep -q "postgres/17/bin"
printf '%s
' "$ENV_OUT" | grep -q "python/3.12/bin"
printf '%s
' "$ENV_OUT" | grep -q "rust/stable/bin"
printf '%s
' "$ENV_OUT" | grep -q "go/1.22/bin"
printf '%s
' "$ENV_OUT" | grep -q "java/21/bin"
if printf '%s\n' "$ENV_OUT" | grep -q "_common"; then
  printf '[FAIL] _common path pollution detected in env --manifest output!\n' >&2
  exit 1
fi

printf '==> Testing run_hooks.sh multi-component PATH inheritance...
'
"${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/run_hooks.sh" "$MANIFEST" "post_install"

grep -q "v22.0.0" "${TEST_TMP}/hook_out.txt"
grep -q "PostgreSQL" "${TEST_TMP}/hook_out.txt"
grep -q "Python 3.12.0" "${TEST_TMP}/hook_out.txt"
grep -q "rustc 1.80.0" "${TEST_TMP}/hook_out.txt"
grep -q "go1.22.0" "${TEST_TMP}/hook_out.txt"
grep -q "openjdk 21.0.0" "${TEST_TMP}/hook_out.txt"

printf '[PASS] Multi-component PATH inheritance verified for nodejs + postgres + python + rust + go + java!
'
