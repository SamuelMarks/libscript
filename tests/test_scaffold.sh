#!/bin/sh
# ## Overview
# End-to-end test suite for the LibScript component-package-manager scaffolder
# (`cli/commands/scaffold/scaffold.sh`), testing both non-interactive JSON generation
# and interactive prompter mode, idempotency, and full audit compliance.
# ## Usage
# ./tests/test_scaffold.sh

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

TMP_JSON_SPEC="${TMPDIR:-/tmp}/libscript_test_scaffold_$$.json"
TMP_EXPORT_JSON="${TMPDIR:-/tmp}/libscript_test_scaffold_export_$$.json"
COMP_A_DIR="${LIBSCRIPT_ROOT_DIR}/_lib/utilities/scaftest_json"
COMP_B_DIR="${LIBSCRIPT_ROOT_DIR}/_lib/utilities/scaftest_interactive"

# ## cleanup_test_artifacts
# Removes temporary test components and JSON specification files on exit.
# shellcheck disable=SC2329
cleanup_test_artifacts() {
  rm -rf "$COMP_A_DIR" "$COMP_B_DIR" "$TMP_JSON_SPEC" "$TMP_EXPORT_JSON"
}

trap 'cleanup_test_artifacts' EXIT INT TERM HUP

printf '%s\n' '=== Test 1: Non-Interactive JSON Component Generation ==='
cat << 'EOF' > "$TMP_JSON_SPEC"
{
  "$schema": "./component-scaffold.schema.json",
  "name": "scaftest_json",
  "title": "Scaffold Test JSON Tool",
  "category": "utilities",
  "description": "A test utility generated from a non-interactive JSON specification.",
  "provides": ["scaftest_json"],
  "binary_name": "scaftest_json",
  "default_install_method": "libscript_native",
  "version_scheme": "github-release",
  "default_version": "latest",
  "version_aliases": ["latest", "lts"],
  "github_repo": "example/scaftest_json",
  "tag_prefix": "v",
  "os_whitelist": ["all"],
  "os_specific_scripts": ["debian"],
  "is_service": true,
  "ports": [9099],
  "enable_hooks": true,
  "multitenant": true
}
EOF

"${LIBSCRIPT_ROOT_DIR}/libscript.sh" scaffold --from-json="$TMP_JSON_SPEC"

for req_file in cli.sh cli.cmd setup.sh setup.cmd setup_generic.sh setup_generic.cmd setup_debian.sh setup_debian.cmd env.sh env.cmd service.sh service.cmd status.sh status.cmd logs.sh logs.cmd uninstall.sh uninstall.cmd uninstall_generic.sh uninstall_generic.cmd test.sh test.cmd manifest.json vars.schema.json README.md hooks/configure.sh hooks/configure.cmd hooks/provision_tenant.sh hooks/provision_tenant.cmd; do
  if [ ! -f "${COMP_A_DIR}/${req_file}" ]; then
    printf '[FAIL] Expected generated file missing: %s\n' "${COMP_A_DIR}/${req_file}" >&2
    exit 1
  fi
done

printf '%s\n' '=== Test 2: Idempotency Verification (Re-running without --force) ==='
printf '%s\n' '# custom marker' >> "${COMP_A_DIR}/test.sh"
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" scaffold --from-json="$TMP_JSON_SPEC"
if ! grep -q '# custom marker' "${COMP_A_DIR}/test.sh"; then
  printf '%s\n' '[FAIL] Idempotency check failed: existing file was overwritten without --force!' >&2
  exit 1
fi
# Restore clean file with --force
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" scaffold --from-json="$TMP_JSON_SPEC" --force

printf '%s\n' '=== Test 3: Audit Verification on JSON-Scaffolded Component ==='
"${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_standards.sh" \
  "${COMP_A_DIR}/cli.sh" "${COMP_A_DIR}/cli.cmd" \
  "${COMP_A_DIR}/setup.sh" "${COMP_A_DIR}/setup.cmd" \
  "${COMP_A_DIR}/setup_generic.sh" "${COMP_A_DIR}/setup_generic.cmd" \
  "${COMP_A_DIR}/setup_debian.sh" "${COMP_A_DIR}/setup_debian.cmd" \
  "${COMP_A_DIR}/env.sh" "${COMP_A_DIR}/env.cmd" \
  "${COMP_A_DIR}/service.sh" "${COMP_A_DIR}/service.cmd" \
  "${COMP_A_DIR}/status.sh" "${COMP_A_DIR}/status.cmd" \
  "${COMP_A_DIR}/logs.sh" "${COMP_A_DIR}/logs.cmd" \
  "${COMP_A_DIR}/uninstall.sh" "${COMP_A_DIR}/uninstall.cmd" \
  "${COMP_A_DIR}/uninstall_generic.sh" "${COMP_A_DIR}/uninstall_generic.cmd" \
  "${COMP_A_DIR}/test.sh" "${COMP_A_DIR}/test.cmd" \
  "${COMP_A_DIR}/manifest.json" "${COMP_A_DIR}/vars.schema.json" \
  "${COMP_A_DIR}/hooks/configure.sh" "${COMP_A_DIR}/hooks/configure.cmd"

"${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_version_manager.sh" "$COMP_A_DIR"
"${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_schema_vars.sh" "$COMP_A_DIR"

printf '%s\n' '=== Test 4: Interactive Prompter Mode + JSON Spec Export ==='
cat << EOF | "${LIBSCRIPT_ROOT_DIR}/libscript.sh" scaffold --interactive --export-json="$TMP_EXPORT_JSON"
scaftest_interactive
utilities
Scaffold Interactive Tool
A test utility generated via the interactive prompter wizard.
libscript_native
github-release
example/scaftest_interactive
v



latest,lts
scaftest_interactive
auto
auto
all

all
n
y
EOF

if [ ! -f "$TMP_EXPORT_JSON" ]; then
  printf '%s\n' '[FAIL] Expected exported JSON file was not created.' >&2
  exit 1
fi
if [ ! -f "${COMP_B_DIR}/cli.sh" ] || [ ! -f "${COMP_B_DIR}/cli.cmd" ]; then
  printf '%s\n' '[FAIL] Interactive prompter did not generate expected component files.' >&2
  exit 1
fi

"${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_version_manager.sh" "$COMP_B_DIR"
"${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_schema_vars.sh" "$COMP_B_DIR"

printf '%s\n' '[PASS] All component scaffolder tests passed!'
exit 0
