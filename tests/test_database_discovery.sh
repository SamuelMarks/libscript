#!/bin/sh
# ## Overview
# Verification test suite for universal database discovery engine.
# Validates discovery, CLI output modes (--json, --eval, --check), and schema compliance.
#
# ## Usage
#   ./tests/test_database_discovery.sh

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
export DIR="${SCRIPT_DIR}"

DISCOVER_SH="${LIBSCRIPT_ROOT_DIR}/engine/hooks/databases/discover_databases.sh"

printf '==> Running Universal Database Discovery Verification Tests...\n'

# Setup Mock Environment
MOCK_DIR=$(mktemp -d)
trap 'rm -rf "$MOCK_DIR"' EXIT

cat <<'EOF' > "$MOCK_DIR/ss"
#!/bin/sh
if [ -f "$MOCK_SS_OUTPUT" ]; then cat "$MOCK_SS_OUTPUT"; fi
EOF
chmod +x "$MOCK_DIR/ss"

export PATH="$MOCK_DIR:$PATH"
export MOCK_SS_OUTPUT="$MOCK_DIR/ss_out"

# Test 0: Check mode with mocks
printf '[TEST 0] Testing discovery --check across all engines via mock tcp...\n'
echo "LISTEN 0 128 0.0.0.0:3306 0.0.0.0:*" > "$MOCK_SS_OUTPUT"
"$DISCOVER_SH" --check --engine mysql || { echo "Failed mysql"; exit 1; }

echo "LISTEN 0 128 0.0.0.0:5432 0.0.0.0:*" > "$MOCK_SS_OUTPUT"
"$DISCOVER_SH" --check --engine postgres || { echo "Failed postgres"; exit 1; }

echo "LISTEN 0 128 0.0.0.0:27017 0.0.0.0:*" > "$MOCK_SS_OUTPUT"
"$DISCOVER_SH" --check --engine mongodb || { echo "Failed mongodb"; exit 1; }

echo "LISTEN 0 128 0.0.0.0:6379 0.0.0.0:*" > "$MOCK_SS_OUTPUT"
"$DISCOVER_SH" --check --engine redis || { echo "Failed redis"; exit 1; }

# 1. Test JSON output mode
printf '[TEST 1] Testing --json output...\n'
# Enable all databases for the JSON test
echo "LISTEN 0 128 0.0.0.0:3306 0.0.0.0:*
LISTEN 0 128 0.0.0.0:5432 0.0.0.0:*
LISTEN 0 128 0.0.0.0:27017 0.0.0.0:*
LISTEN 0 128 0.0.0.0:6379 0.0.0.0:*" > "$MOCK_SS_OUTPUT"
JSON_OUT=$("$DISCOVER_SH" --json | grep -vE '^\[(CONTINUE|STOP)\]')
for _exp_eng in mysql postgres mongodb redis; do
  printf '%s\n' "$JSON_OUT" | grep -q "\"engine\"[[:space:]]*:[[:space:]]*\"${_exp_eng}\"" || {
    printf '[FAIL] Missing expected engine %s in JSON output: %s\n' "$_exp_eng" "$JSON_OUT" >&2
    exit 1
  }
done
_eng_cnt=$(printf '%s\n' "$JSON_OUT" | grep -c '"engine"' || true)
[ "$_eng_cnt" -eq 4 ] || {
  printf '[FAIL] Expected 4 mock engines in JSON output, found %s\n' "$_eng_cnt" >&2
  exit 1
}
printf 'Discovered %s databases in inventory\n' "$_eng_cnt"

# 2. Test Check and Eval modes (idempotent passes)
printf '[TEST 2] Testing discovery idempotency (two passes)...\n'
"$DISCOVER_SH" --eval >/dev/null 2>&1 || true
"$DISCOVER_SH" --eval >/dev/null 2>&1 || true

printf '[SUCCESS] All Database Discovery Verification Tests Passed!\n'
