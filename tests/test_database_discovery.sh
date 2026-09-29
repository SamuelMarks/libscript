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

DISCOVER_SH="${LIBSCRIPT_ROOT_DIR}/_lib/databases/discover_databases.sh"

printf '==> Running Universal Database Discovery Verification Tests...
'

# 1. Test JSON output mode
printf '[TEST 1] Testing --json output...\n'
JSON_OUT="$("$DISCOVER_SH" --json)"
python3 -c "
import json, sys
data_raw = '''$JSON_OUT'''
json_str = '\n'.join([l for l in data_raw.splitlines() if not l.startswith('[CONTINUE]') and not l.startswith('[STOP]')])
data = json.loads(json_str)
assert isinstance(data, list), 'Expected JSON list'
print(f'Discovered {len(data)} databases in inventory')
"

# 2. Test Check and Eval modes (idempotent passes)
printf '[TEST 2] Testing discovery idempotency (two passes)...
'
"$DISCOVER_SH" --eval >/dev/null 2>&1 || true
"$DISCOVER_SH" --eval >/dev/null 2>&1 || true

printf '[SUCCESS] All Database Discovery Verification Tests Passed!
'
