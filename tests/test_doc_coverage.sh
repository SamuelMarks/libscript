#!/bin/sh
# ## Overview
# Unit test suite for devtools/audit/doc_coverage.sh and the README.md % doc coverage shield.
# Verifies 100% doc coverage calculation across component README.md files and .sh/.cmd/.ps1
# script headers, shield injection and idempotency in README.md, and failure detection
# when a component README.md or script markdown header is missing.
#
# ## Usage
# ./tests/test_doc_coverage.sh

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

# ## assert_contains
# Asserts that a file contains a given pattern.
assert_contains() {
  _file="$1"
  _pattern="$2"
  _desc="$3"
  if grep -q "$_pattern" "$_file"; then
    printf '[PASS] %s\n' "$_desc"
  else
    printf '[FAIL] %s (pattern "%s" not found in %s)\n' "$_desc" "$_pattern" "$_file" >&2
    FAILURES=$((FAILURES + 1))
  fi
}

printf '=== LibScript Doc Coverage Shield & Hook Test Suite ===\n'

# 1. Test shield injection and 100% coverage on repository
cp "${LIBSCRIPT_ROOT_DIR}/README.md" "${TMP_TEST_DIR}/README.md"
sh "${LIBSCRIPT_ROOT_DIR}/devtools/audit/doc_coverage.sh" --update-readme "${TMP_TEST_DIR}/README.md"

assert_contains "${TMP_TEST_DIR}/README.md" '\[!\[Doc Coverage\](https://img\.shields\.io/badge/doc%20coverage-100%25-brightgreen\.svg)\](DOCS_ROADMAP\.md)' "Injects 100% Doc Coverage shield into README.md"

# 2. Test idempotency (2x consecutive runs produce identical README.md)
cp "${TMP_TEST_DIR}/README.md" "${TMP_TEST_DIR}/README.pass1.md"
sh "${LIBSCRIPT_ROOT_DIR}/devtools/audit/doc_coverage.sh" --update-readme "${TMP_TEST_DIR}/README.md"

if cmp -s "${TMP_TEST_DIR}/README.pass1.md" "${TMP_TEST_DIR}/README.md"; then
  printf '[PASS] 2x consecutive runs of doc_coverage.sh --update-readme are 100%% idempotent.\n'
else
  printf '[FAIL] 2x consecutive runs of doc_coverage.sh --update-readme mutated README.md!\n' >&2
  FAILURES=$((FAILURES + 1))
fi

# 3. Test synthetic sandbox with missing component README and missing script header
SANDBOX="${TMP_TEST_DIR}/sandbox"
mkdir -p "${SANDBOX}/_lib/utilities/foo" "${SANDBOX}/_lib/utilities/bar"

cat <<'EOF' > "${SANDBOX}/README.md"
# Sandbox
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
EOF

cat <<'EOF' > "${SANDBOX}/_lib/utilities/foo/README.md"
# Foo
EOF

cat <<'EOF' > "${SANDBOX}/_lib/utilities/foo/setup.sh"
#!/bin/sh
# ## Overview
# Foo setup.
# ## Usage
# ./setup.sh
EOF

cat <<'EOF' > "${SANDBOX}/_lib/utilities/bar/setup.sh"
#!/bin/sh
echo "missing header"
EOF

if sh "${LIBSCRIPT_ROOT_DIR}/devtools/audit/doc_coverage.sh" --repo-root "${SANDBOX}" --update-readme "${SANDBOX}/README.md" >/dev/null 2>&1; then
  printf '[FAIL] Expected non-zero exit code when docs are missing in sandbox\n' >&2
  FAILURES=$((FAILURES + 1))
else
  printf '[PASS] Correctly exits non-zero when component README.md or script headers are missing\n'
fi

assert_contains "${SANDBOX}/README.md" '\[!\[Doc Coverage\](https://img\.shields\.io/badge/doc%20coverage-50%25-red\.svg)\](DOCS_ROADMAP\.md)' "Calculates 50% coverage (2/4 items) and updates shield color to red"

if [ "$FAILURES" -gt 0 ]; then
  printf '[FAIL] test_doc_coverage failed with %d error(s).\n' "$FAILURES" >&2
  exit 1
fi

printf '=== All Doc Coverage Shield & Hook Checks Passed! ===\n'
exit 0
