#!/bin/sh
# ## Overview
# Hermetic regression test suite verifying global variable scoping, base_vars.schema.json cap (<=32),
# scoped variable packs (schemas/vars/*.schema.json), $ref integrity, and unbloated component READMEs.
#
# ## Usage
# ./tests/test_global_var_hygiene.sh

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
    if (return 0 2>/dev/null); then return 0; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

TEST_TMP="${LIBSCRIPT_ROOT_DIR}/tests_tmp/global_var_hygiene_$$"
mkdir -p "$TEST_TMP"

# ## cleanup_tmp
# Removes isolated temporary test artifacts on script exit.
cleanup_tmp() {
  rm -rf "$TEST_TMP"
}
trap 'cleanup_tmp' EXIT INT TERM

# ## fail_test
# Prints a failure diagnostic and exits with status 1.
fail_test() {
  printf '[FAIL] %s\n' "$1" >&2
  exit 1
}

BASE_SCHEMA="${LIBSCRIPT_ROOT_DIR}/engine/schemas/base_vars.schema.json"
[ -f "$BASE_SCHEMA" ] || fail_test 'Missing engine/schemas/base_vars.schema.json'

PROP_COUNT=$(jq -r '.properties | keys | length' "$BASE_SCHEMA")
if [ "$PROP_COUNT" -gt 32 ] || [ "$PROP_COUNT" -lt 20 ]; then
  fail_test "Expected base_vars.schema.json to have 20..32 core properties, got ${PROP_COUNT}"
fi

FORBIDDEN_HITS=$(jq -r '
  .properties | keys[]
  | select(test("^(TPU_|XPK_|JETSTREAM_|VAULT_TOKEN$|SERVE_FROM$|LIBSCRIPT_LOG_DRIVER$|LIBSCRIPT_LOG_HOST$|LIBSCRIPT_LOG_PORT$|LIBSCRIPT_TFRC_|LIBSCRIPT_EXPERIMENT_|LIBSCRIPT_BENCH_|LIBSCRIPT_RTOS_|LIBSCRIPT_FREEBSD_|LIBSCRIPT_FETCH_|LIBSCRIPT_OVERRIDE_CHANGED$|LIBSCRIPT_RESOLVED_)"))
' "$BASE_SCHEMA")
if [ -n "$FORBIDDEN_HITS" ]; then
  fail_test "Leaked or dead globals still present in base_vars.schema.json: ${FORBIDDEN_HITS}"
fi
printf '[PASS] base_vars.schema.json contains %s clean core globals (<=32) with zero leaked subsystem/dead keys.\n' "$PROP_COUNT"

for _pack in tpu tfrc experiment rtos image_synth cloud_tags source_toolchain; do
  _pf="${LIBSCRIPT_ROOT_DIR}/schemas/vars/${_pack}.schema.json"
  [ -f "$_pf" ] || fail_test "Missing scoped variable pack ${_pf}"
  jq empty "$_pf" >/dev/null 2>&1 || fail_test "Invalid JSON in ${_pf}"
done
printf '[PASS] All 7 scoped variable pack schemas exist and parse cleanly.\n'

for _unrel in "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/lynx/README.md" "${LIBSCRIPT_ROOT_DIR}/_lib/caches/hazelcast/README.md" "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/exim/README.md"; do
  [ -f "$_unrel" ] || fail_test "Missing component README ${_unrel}"
  if grep -Eq '(TPU_ZONE|JETSTREAM_IMAGE|LIBSCRIPT_EXPERIMENT_PAPER_DIR|LIBSCRIPT_RTOS_MCUBOOT)' "$_unrel"; then
    fail_test "Unrelated README ${_unrel} still contains leaked TPU/Experiment/RTOS global variables"
  fi
done
grep -q 'LIBSCRIPT_HOME' "${LIBSCRIPT_ROOT_DIR}/engine/common/README.md" || fail_test 'engine/common/README.md missing LIBSCRIPT_HOME documentation'
grep -q 'JETSTREAM_IMAGE' "${LIBSCRIPT_ROOT_DIR}/_lib/app-servers/jetstream/README.md" || fail_test 'jetstream/README.md missing JETSTREAM_IMAGE documentation'
printf '[PASS] Unrelated component READMEs are completely free of leaked subsystem globals.\n'

WRAP_REF=$(jq -r '."$ref" // empty' "${LIBSCRIPT_ROOT_DIR}/workloads/schemas/libscript.schema.json")
if [ "$WRAP_REF" != '../../libscript.schema.json' ] || [ ! -f "${LIBSCRIPT_ROOT_DIR}/workloads/schemas/${WRAP_REF}" ]; then
  fail_test "workloads/schemas/libscript.schema.json expected \$ref ../../libscript.schema.json, got ${WRAP_REF}"
fi

FAKE_COMP="${TEST_TMP}/fake_comp"
mkdir -p "$FAKE_COMP"
cat <<'EOF_M' > "${FAKE_COMP}/manifest.json"
{
  "name": "fake_comp",
  "title": "Fake Component",
  "description": "Temporary hermetic test fixture.",
  "category": "utilities"
}
EOF_M
cat <<'EOF_V' > "${FAKE_COMP}/vars.schema.json"
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "Fake Vars",
  "description": "Fixture schema with placeholder description.",
  "type": "object",
  "properties": {
    "FAKE_COMP_FOO": {
      "type": "string",
      "description": "Variable FAKE_COMP_FOO."
    }
  }
}
EOF_V

if STACK='' "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_schema_vars.sh" "$FAKE_COMP" >/dev/null 2>&1; then
  fail_test 'audit_schema_vars.sh failed to reject placeholder "Variable FAKE_COMP_FOO." description'
fi
printf '[PASS] audit_schema_vars.sh rejects placeholder descriptions and broken schema contracts.\n'
cleanup_tmp
exit 0
