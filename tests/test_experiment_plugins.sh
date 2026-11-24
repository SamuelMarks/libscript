#!/bin/sh
# ## Overview
# Integration test suite verifying Pillar 4 (`EXP-01`..`EXP-14`): Open/Closed auto-discovery,
# zero-core-edit scaffolding and 2x-idempotent execution of a new research paper plugin,
# schema/flag validation, and 7-OS `README.md` + `matrix_results.json` synthesis without mutating `TODO_PLAN.md`.
#
# ## Usage
# ./tests/test_experiment_plugins.sh

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

TEST_TMP=$(mktemp -d)

# ## fail_exp
# Reports test failure, cleans up temporary directory, and exits 1.
fail_exp() {
  printf '[FAIL] %s\n' "$1" >&2
  rm -rf "${TEST_TMP}"
  exit 1
}

printf '%s\n' '=== 1. Auto-Discovery & Validation of All 5 Built-In Experiment Plugins ==='
LIST_OUT=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment list)
for _s in edgcpp-backends win-port libtpu-pjrt gemma-4-sql os-component-matrix; do
  printf '%s\n' "$LIST_OUT" | grep -q "^${_s}	" || fail_exp "Missing experiment suite ${_s} from auto-discovery"
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment validate "$_s" >/dev/null || fail_exp "Validation failed for ${_s}"
done

printf '%s\n' '=== 2. Open/Closed Onboarding of a Brand-New Research Suite (Zero Core Edits) ==='
cp -R "${LIBSCRIPT_ROOT_DIR}/experiments" "${TEST_TMP}/experiments"
export LIBSCRIPT_EXPERIMENTS_DIR="${TEST_TMP}/experiments"

"${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment scaffold sigplan-novel-2027 --title='Novel Compiler Study' --substrate=local-native
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment validate sigplan-novel-2027 --trials=7
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment run sigplan-novel-2027 --trials=7 --results-dir="${TEST_TMP}/novel_out"
SECOND_RUN=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment run sigplan-novel-2027 --trials=7 --results-dir="${TEST_TMP}/novel_out")
printf '%s\n' "$SECOND_RUN" | grep -q '\[SKIP\]' || fail_exp 'Second run did not hit 2x-idempotency stamp'
jq -e '.suite_id == "sigplan-novel-2027" and .trials == 7 and (.git_commit | length > 0)' "${TEST_TMP}/novel_out/metrics.json" >/dev/null || fail_exp 'Invalid metrics.json'
grep -q 'ExpTrials' "${TEST_TMP}/novel_out/macros.tex" || fail_exp 'Missing LaTeX macro output'

if "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment validate sigplan-novel-2027 --undeclared-flag=123 >/dev/null 2>&1; then
  fail_exp 'Expected undeclared suite flag to be rejected against vars.schema.json!'
fi
unset LIBSCRIPT_EXPERIMENTS_DIR

printf '%s\n' '=== 3. 7-OS Matrix Regeneration Without TODO_PLAN.md Side-Effect ==='
cp "${LIBSCRIPT_ROOT_DIR}/README.md" "${TEST_TMP}/README.copy.md"
TODO_SHA_BEFORE=$(cksum "${LIBSCRIPT_ROOT_DIR}/TODO_PLAN.md" | awk '{print $1}')
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment run os-component-matrix --results-dir="${TEST_TMP}/os_mat" --readme-out="${TEST_TMP}/README.copy.md" >/dev/null
TODO_SHA_AFTER=$(cksum "${LIBSCRIPT_ROOT_DIR}/TODO_PLAN.md" | awk '{print $1}')
[ "$TODO_SHA_BEFORE" = "$TODO_SHA_AFTER" ] || fail_exp 'update_results mutated TODO_PLAN.md without --sync-plan-checkboxes!'
jq -e '(.generated_at | length > 0) and (.components | type == "array")' "${TEST_TMP}/os_mat/matrix_results.json" >/dev/null || fail_exp 'Invalid matrix_results.json'

rm -rf "${TEST_TMP}"
printf '%s\n' '[PASS] All Pillar 4 Open/Closed Experiment Plugin tests passed!'
