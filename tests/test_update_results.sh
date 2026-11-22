#!/bin/sh
# ## Overview
# Unit test suite for tests/update_results.sh verifying metadata-driven T1-T5 + Plane A (Traits)
# Supported Components tables, OS alias mapping, JSON matrix export, and 2x idempotency.
#
# ## Usage
# ./tests/test_update_results.sh

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
export LIBSCRIPT_ROOT_DIR

TMP_TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_TEST_DIR"' EXIT INT TERM

FAILURES=0

# ## assert_file_contains
# Asserts that a file contains a specific regex/string pattern.
assert_file_contains() {
  _file="$1"
  _pattern="$2"
  _desc="$3"
  if grep -Eq "$_pattern" "$_file"; then
    printf '[PASS] %s\n' "$_desc"
  else
    printf '[FAIL] %s (pattern "%s" not found in %s)\n' "$_desc" "$_pattern" "$_file" >&2
    FAILURES=$((FAILURES + 1))
  fi
}

printf '=== LibScript T1-T5 + Plane A README Table Generator Test Suite ===\n'

cp "${LIBSCRIPT_ROOT_DIR}/README.md" "${TMP_TEST_DIR}/README.md"
JSON_OUT="${TMP_TEST_DIR}/matrix_results.json"

sh "${LIBSCRIPT_ROOT_DIR}/tests/update_results.sh" "${LIBSCRIPT_ROOT_DIR}" --output "${TMP_TEST_DIR}/README.md" --json "${JSON_OUT}"

_bt=$(printf '\140')
assert_file_contains "${TMP_TEST_DIR}/README.md" "### T1: Atomic Userland & Daemon Recipes" "Renders T1 heading"
assert_file_contains "${TMP_TEST_DIR}/README.md" "### T2: OS, Kernel & System Plumbing Recipes" "Renders T2 heading"
assert_file_contains "${TMP_TEST_DIR}/README.md" "### T3: Image, OS & Artifact Synthesis" "Renders T3 heading"
assert_file_contains "${TMP_TEST_DIR}/README.md" "### T4: Infrastructure Providers & Cluster Substrates" "Renders T4 heading"
assert_file_contains "${TMP_TEST_DIR}/README.md" "### T5: Declarative Workloads, Application Stacks & Stateful Constellations" "Renders T5 heading"
assert_file_contains "${TMP_TEST_DIR}/README.md" "### Plane A \\(Traits\\): Unified Cross-Cutting Node Traits" "Renders Plane A (Traits) heading"
assert_file_contains "${TMP_TEST_DIR}/README.md" "\\|[[:space:]]*${_bt}envoy${_bt}" "Renders envoy component row in T1 table"
assert_file_contains "${JSON_OUT}" '"tier":' "JSON output contains tier field"
assert_file_contains "${JSON_OUT}" '"category":' "JSON output contains category field"
assert_file_contains "${JSON_OUT}" '"idempotent":' "JSON output contains idempotent field"

cp "${TMP_TEST_DIR}/README.md" "${TMP_TEST_DIR}/README.pass1.md"
sh "${LIBSCRIPT_ROOT_DIR}/tests/update_results.sh" "${LIBSCRIPT_ROOT_DIR}" --output "${TMP_TEST_DIR}/README.md" --json "${JSON_OUT}"

if cmp -s "${TMP_TEST_DIR}/README.pass1.md" "${TMP_TEST_DIR}/README.md"; then
  printf '[PASS] 2x consecutive runs of update_results.sh are 100%% idempotent (zero diff).\n'
else
  printf '[FAIL] 2x consecutive runs of update_results.sh produced a diff!\n' >&2
  FAILURES=$((FAILURES + 1))
fi

SYNTH_DIR="${TMP_TEST_DIR}/synth_repo"
mkdir -p "${SYNTH_DIR}/_lib/virtualization/apple_vm" \
         "${SYNTH_DIR}/_lib/utilities/no_darwin" \
         "${SYNTH_DIR}/_lib/init-systems/illumos_init" \
         "${SYNTH_DIR}/synthesis/distro/reactos" \
         "${SYNTH_DIR}/workloads/ai/tpu-trainer" \
         "${SYNTH_DIR}/tests_tmp"
: > "${SYNTH_DIR}/libscript.sh"
printf '%s\n' '{"name":"apple_vm","tier":"T1","provides":["apple_vm"],"os_whitelist":["linux","macos","windows"]}' > "${SYNTH_DIR}/_lib/virtualization/apple_vm/manifest.json"
printf '%s\n' '{"name":"no_darwin","tier":"T1","provides":["no_darwin"],"os_blacklist":["windows","macos"]}' > "${SYNTH_DIR}/_lib/utilities/no_darwin/manifest.json"
printf '%s\n' '{"name":"illumos_init","tier":"T2","provides":["illumos_init"],"os_whitelist":["illumos"]}' > "${SYNTH_DIR}/_lib/init-systems/illumos_init/manifest.json"
printf '%s\n' '{"name":"reactos-distro","provides":["reactos-distro"],"os_whitelist":["all"]}' > "${SYNTH_DIR}/synthesis/distro/reactos/manifest.json"
: > "${SYNTH_DIR}/tests_tmp/apple_vm.linux.alpine.success"
printf '# Synth\n\n## Supported Components\n\n## License\n' > "${SYNTH_DIR}/README.md"

sh "${LIBSCRIPT_ROOT_DIR}/tests/update_results.sh" "${SYNTH_DIR}" --sync-plans
assert_file_contains "${SYNTH_DIR}/README.md" "\\|[[:space:]]*${_bt}apple_vm${_bt}[[:space:]]*\\|[[:space:]]*${_bt}virtualization${_bt}[[:space:]]*\\|[[:space:]]*✅[[:space:]]*\\|[[:space:]]*❓[[:space:]]*\\|[[:space:]]*❓[[:space:]]*\\|[[:space:]]*❓[[:space:]]*\\|[[:space:]]*-[[:space:]]*\\|[[:space:]]*-[[:space:]]*\\|[[:space:]]*❓[[:space:]]*\\|" "update_results.sh maps os_whitelist macos to darwin column"
assert_file_contains "${SYNTH_DIR}/README.md" "\\|[[:space:]]*${_bt}no_darwin${_bt}[[:space:]]*\\|[[:space:]]*${_bt}utilities${_bt}[[:space:]]*\\|[[:space:]]*❓[[:space:]]*\\|[[:space:]]*❓[[:space:]]*\\|[[:space:]]*❓[[:space:]]*\\|[[:space:]]*-[[:space:]]*\\|[[:space:]]*❓[[:space:]]*\\|[[:space:]]*❓[[:space:]]*\\|[[:space:]]*-[[:space:]]*\\|" "update_results.sh maps os_blacklist macos to darwin column"
assert_file_contains "${SYNTH_DIR}/README.md" "\\|[[:space:]]*${_bt}illumos_init${_bt}[[:space:]]*\\|[[:space:]]*${_bt}init-systems${_bt}[[:space:]]*\\|[[:space:]]*-[[:space:]]*\\|[[:space:]]*-[[:space:]]*\\|[[:space:]]*-[[:space:]]*\\|[[:space:]]*-[[:space:]]*\\|[[:space:]]*❓[[:space:]]*\\|[[:space:]]*-[[:space:]]*\\|[[:space:]]*-[[:space:]]*\\|" "update_results.sh maps os_whitelist illumos to sunos column"
assert_file_contains "${SYNTH_DIR}/README.md" "\\|[[:space:]]*${_bt}synthesis/distro/reactos${_bt}[[:space:]]*\\|[[:space:]]*${_bt}distro${_bt}[[:space:]]*\\|" "update_results.sh discovers synthesis/distro/reactos in T3"
assert_file_contains "${SYNTH_DIR}/README.md" "\\|[[:space:]]*${_bt}workloads/ai/tpu-trainer${_bt}[[:space:]]*\\|[[:space:]]*${_bt}ai${_bt}[[:space:]]*\\|" "update_results.sh discovers workloads/ai/tpu-trainer in T5"

if [ "$FAILURES" -gt 0 ]; then
  printf '[FAIL] test_update_results failed with %d error(s).\n' "$FAILURES" >&2
  exit 1
fi
printf '[PASS] All T1-T5 + Plane A matrix checks succeeded.\n'
