#!/bin/sh
# ## Overview
# Audits documentation coverage of schema keys, CLI flags, shell functions, and batch/powershell files.
#
# ## Usage
#   ./devtools/audit/doc_coverage.sh

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
  missing_in_file=$(awk -v file="${sh_file#${LIBSCRIPT_ROOT_DIR}/}" '
    BEGIN { has_doc = 0; prev_hdr = "" }
    /^# ## / {
        if ($0 == prev_hdr) {
            print file ":" NR " (duplicate docstring header)";
        }
        prev_hdr = $0
        has_doc = 1
        next
    }
    /^# Executes .* (functionality|logic)\.$/ {
        print file ":" NR " (placeholder docstring)";
    }
    /^[a-zA-Z_][a-zA-Z0-9_]*\(\) *\{/ {
        if (!has_doc) {
            print file ":" NR;
        }
        has_doc = 0
        prev_hdr = ""
    }
    /^[^#]/ && NF > 0 && !/^[a-zA-Z_][a-zA-Z0-9_]*\(\) *\{/ { has_doc = 0; prev_hdr = "" }
  ' "$sh_file")
  
  if [ -n "$missing_in_file" ]; then
    printf '[WARN] Missing or invalid function docstring(s) in %s:\n%s\n' "${sh_file#${LIBSCRIPT_ROOT_DIR}/}" "$missing_in_file"
    MISSING_FUNC_DOCS=$((MISSING_FUNC_DOCS + 1))
  fi
done < "$tmp_sh"
rm -f "$tmp_sh"

printf '==> Auditing Batch Label Docstring Coverage...\n'
MISSING_CMD_DOCS=0
tmp_cmd=$(mktemp)
find "${LIBSCRIPT_ROOT_DIR}" -name "*.cmd" -type f | grep -v "node_modules" > "$tmp_cmd" || true

while IFS= read -r cmd_file; do
  missing_in_file=$(awk -v file="${cmd_file#${LIBSCRIPT_ROOT_DIR}/}" '
    BEGIN { has_doc = 0; prev_hdr = "" }
    { sub(/\r$/, "", $0) }
    /^:: ## / {
        if ($0 == prev_hdr) {
            print file ":" NR " (duplicate docstring header)";
        }
        prev_hdr = $0
        has_doc = 1
        next
    }
    /^:: Executes .* (functionality|logic)\.$/ {
        print file ":" NR " (placeholder docstring)";
    }
    /^:[a-zA-Z0-9_]+/ && !/^:EOF/ && !/^:eof/ && !/^:root_found/ && !/^:find_root/ { 
        if (!has_doc) {
            print file ":" NR;
        }
        has_doc = 0
        prev_hdr = ""
    }
    /^[^:]/ && NF > 0 { has_doc = 0; prev_hdr = "" }
  ' "$cmd_file")
  
  if [ -n "$missing_in_file" ]; then
    printf '[WARN] Missing or invalid label docstring(s) in %s:\n%s\n' "${cmd_file#${LIBSCRIPT_ROOT_DIR}/}" "$missing_in_file"
    MISSING_CMD_DOCS=$((MISSING_CMD_DOCS + 1))
  fi
done < "$tmp_cmd"
rm -f "$tmp_cmd"

printf '==> Auditing PowerShell Header Coverage...\n'
MISSING_PS1_DOCS=0
tmp_ps1=$(mktemp)
find "${LIBSCRIPT_ROOT_DIR}" -name "*.ps1" -type f | grep -v "node_modules" > "$tmp_ps1" || true

while IFS= read -r ps1_file; do
  if ! head -n 30 "$ps1_file" | grep -q "## Overview"; then
    printf '[WARN] Missing ## Overview in %s\n' "${ps1_file#${LIBSCRIPT_ROOT_DIR}/}"
    MISSING_PS1_DOCS=$((MISSING_PS1_DOCS + 1))
  elif ! head -n 30 "$ps1_file" | grep -q "## Usage"; then
    printf '[WARN] Missing ## Usage in %s\n' "${ps1_file#${LIBSCRIPT_ROOT_DIR}/}"
    MISSING_PS1_DOCS=$((MISSING_PS1_DOCS + 1))
  fi
done < "$tmp_ps1"
rm -f "$tmp_ps1"

TOTAL_ERRORS=$((MISSING_SCHEMA_DOCS + MISSING_FUNC_DOCS + MISSING_CMD_DOCS + MISSING_PS1_DOCS))

if [ "$TOTAL_ERRORS" -eq 0 ]; then
  printf '[PASS] 100%% Documentation Coverage Audit Passed!\n'
  exit 0
else
  printf '[ERROR] Found %d schema files, %d shell scripts, %d batch files, and %d powershell scripts with missing or placeholder docs.\n' "$MISSING_SCHEMA_DOCS" "$MISSING_FUNC_DOCS" "$MISSING_CMD_DOCS" "$MISSING_PS1_DOCS" >&2
  exit 1
fi
