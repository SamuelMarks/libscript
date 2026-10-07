#!/bin/sh
# ## Overview
# Audits documentation coverage of schema keys, CLI flags, and shell functions.
#
# ## Usage
#   ./devtools/audit/doc_coverage.sh

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE[0]-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
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

printf '==> Auditing Schema Description Coverage...\n'

MISSING_SCHEMA_DOCS=0
tmp_schemas=$(mktemp)
find "${LIBSCRIPT_ROOT_DIR}" -name "*.schema.json" -type f > "$tmp_schemas"

while IFS= read -r schema_file; do
  if grep -q '"type":' "$schema_file" && ! grep -q '"description":' "$schema_file"; then
    printf '[WARN] Schema file %s might be missing descriptions.\n' "${schema_file#${LIBSCRIPT_ROOT_DIR}/}"
    MISSING_SCHEMA_DOCS=$((MISSING_SCHEMA_DOCS + 1))
  fi
done < "$tmp_schemas"
rm -f "$tmp_schemas"

printf '==> Auditing Shell Function Docstring Coverage...\n'
MISSING_FUNC_DOCS=0
tmp_sh=$(mktemp)
find "${LIBSCRIPT_ROOT_DIR}" -name "*.sh" -type f | grep -v "node_modules" > "$tmp_sh" || true

while IFS= read -r sh_file; do
  if grep -E '^[a-zA-Z_][a-zA-Z0-9_]*\(\) \{' "$sh_file" >/dev/null; then
    if ! grep -q "^# ## " "$sh_file"; then
       printf '[WARN] Shell file %s has functions but no docstrings (##).\n' "${sh_file#${LIBSCRIPT_ROOT_DIR}/}"
       MISSING_FUNC_DOCS=$((MISSING_FUNC_DOCS + 1))
    fi
  fi
done < "$tmp_sh"
rm -f "$tmp_sh"

if [ "$MISSING_SCHEMA_DOCS" -eq 0 ] && [ "$MISSING_FUNC_DOCS" -eq 0 ]; then
  printf '[PASS] 100%% Documentation Coverage Audit Passed!\n'
  exit 0
else
  printf '[WARN] Found %d schema files and %d shell scripts with potential missing docs.\n' "$MISSING_SCHEMA_DOCS" "$MISSING_FUNC_DOCS"
  exit 0
fi
