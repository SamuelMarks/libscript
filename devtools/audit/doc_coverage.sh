#!/bin/sh
# ## Overview
# Audits documentation coverage of component README.md files, schema keys, CLI flags,
# shell functions, and script header comments (.sh, .cmd, .ps1), and optionally updates
# the % doc coverage shield in README.md.
#
# ## Usage
#   ./devtools/audit/doc_coverage.sh [--strict] [--update-readme [README_PATH]] [--repo-root REPO_ROOT]

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

# ## show_help
# Displays command-line usage instructions and available options.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") [--strict] [--update-readme [README_PATH]] [--repo-root REPO_ROOT] [--help]"
  printf '%s
' "Audits documentation coverage and updates the % doc coverage shield in README.md."
  printf '
'
  printf '%s
' "Options:"
  printf '%s
' "  --strict                       Fail with exit code 1 if coverage is below 100%."
  printf '%s
' "  --update-readme [README_PATH]  Update the Doc Coverage shield in README.md."
  printf '%s
' "  --repo-root REPO_ROOT          Override repository root directory."
  printf '%s
' "  --help, -h, /?, -?             Show this help message."
}

UPDATE_README=0
README_FILE=""
TARGET_ROOT="${LIBSCRIPT_ROOT_DIR}"

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h|/\?|-\?)
      show_help
      exit 0
      ;;
    --strict)
      shift
      ;;
    --update-readme)
      UPDATE_README=1
      if [ $# -gt 1 ] && [ "$(printf '%s' "$2" | cut -c1-2)" != "--" ]; then
        README_FILE="$2"
        shift 2
      else
        shift
      fi
      ;;
    --repo-root)
      if [ $# -gt 1 ]; then
        TARGET_ROOT="$2"
        shift 2
      else
        shift
      fi
      ;;
    *)
      shift
      ;;
  esac
done

if [ -z "$README_FILE" ]; then
  README_FILE="${TARGET_ROOT}/README.md"
fi

# ## update_readme_shield
# Inserts or updates the Doc Coverage shield badge in the target README.md file.
update_readme_shield() {
  _readme="$1"
  _pct="$2"
  [ -f "$_readme" ] || return 0

  _color='brightgreen'
  if [ "$_pct" -lt 100 ]; then
    if [ "$_pct" -ge 80 ]; then
      _color='yellow'
    else
      _color='red'
    fi
  fi

  _shield="[![Doc Coverage](https://img.shields.io/badge/doc%20coverage-${_pct}%25-${_color}.svg)](DOCS_ROADMAP.md)"
  _tmp_readme=$(mktemp "${TMPDIR:-/tmp}/doc_cov_readme.XXXXXX")

  if grep -q '\[!\[Doc Coverage\](https://img\.shields\.io/badge/doc%20coverage-' "$_readme"; then
    awk -v shield="$_shield" '
      /\[!\[Doc Coverage\]\(https:\/\/img\.shields\.io\/badge\/doc%20coverage-/ {
        print shield
        next
      }
      { print }
    ' "$_readme" > "$_tmp_readme"
  elif grep -q '\[!\[CI Tests\](' "$_readme"; then
    awk -v shield="$_shield" '
      /\[!\[CI Tests\]\(/ {
        print
        print shield
        next
      }
      { print }
    ' "$_readme" > "$_tmp_readme"
  elif grep -q '\[!\[License\](' "$_readme"; then
    awk -v shield="$_shield" '
      /\[!\[License\]\(/ {
        print
        print shield
        next
      }
      { print }
    ' "$_readme" > "$_tmp_readme"
  else
    {
      printf '%s
' "$_shield"
      cat "$_readme"
    } > "$_tmp_readme"
  fi

  if ! cmp -s "$_tmp_readme" "$_readme"; then
    mv "$_tmp_readme" "$_readme"
  else
    rm -f "$_tmp_readme"
  fi
}

printf '==> Auditing Component README.md Coverage...\n'
TOTAL_COMPS=0
MISSING_COMP_READMES=0
set +f
if [ -d "${TARGET_ROOT}/_lib" ]; then
  for _cat_dir in "${TARGET_ROOT}/_lib"/*; do
    [ -d "$_cat_dir" ] || continue
    [ "$(basename "$_cat_dir")" = "_common" ] && continue
    for _comp_dir in "$_cat_dir"/*; do
      [ -d "$_comp_dir" ] || continue
      TOTAL_COMPS=$((TOTAL_COMPS + 1))
      if [ ! -f "${_comp_dir}/README.md" ]; then
        printf '[WARN] Component %s is missing README.md\n' "${_comp_dir#"${TARGET_ROOT}"/}"
        MISSING_COMP_READMES=$((MISSING_COMP_READMES + 1))
      fi
    done
  done
fi
set -f

printf '==> Auditing Script Header Markdown Docstring Coverage (.sh, .cmd, .ps1)...
'
TOTAL_SCRIPTS=0
MISSING_SCRIPT_HEADERS=0
tmp_scripts=$(mktemp)
if [ -d "${TARGET_ROOT}/.git" ] && git -C "${TARGET_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "${TARGET_ROOT}" ls-files "*.sh" "*.cmd" "*.ps1" | grep -vE '^(\.git|gen|cache|tmp|tests_tmp|node_modules|vagrant)/' > "$tmp_scripts" || true
else
  (cd "${TARGET_ROOT}" && find . -maxdepth 2 \( -name "*.sh" -o -name "*.cmd" -o -name "*.ps1" \) -type f | grep -vE '^\./(\.git|creds|node_modules|\.venv|logs|test)/' | sed 's|^\./||') > "$tmp_scripts" || true
fi

while IFS= read -r rel_script; do
  [ -n "$rel_script" ] || continue
  script_path="${TARGET_ROOT}/${rel_script}"
  [ -f "$script_path" ] || continue
  TOTAL_SCRIPTS=$((TOTAL_SCRIPTS + 1))
  has_hdr=$(awk '
    BEGIN { ov = 0; us = 0 }
    NR <= 30 {
      if ($0 ~ /## Overview/) ov = 1
      if ($0 ~ /## Usage/) us = 1
    }
    NR > 30 { exit }
    END { if (ov && us) print "1"; else print "0" }
  ' "$script_path")
  if [ "$has_hdr" != "1" ]; then
    printf '[WARN] Missing markdown header comments (## Overview / ## Usage) in %s
' "$rel_script"
    MISSING_SCRIPT_HEADERS=$((MISSING_SCRIPT_HEADERS + 1))
  fi
done < "$tmp_scripts"
rm -f "$tmp_scripts"

printf '==> Auditing Schema Description Coverage...
'

MISSING_SCHEMA_DOCS=0
tmp_schemas=$(mktemp)
if [ -d "${TARGET_ROOT}/_lib" ]; then find "${TARGET_ROOT}" -name "*.schema.json" -type f > "$tmp_schemas"; else find "${TARGET_ROOT}" -maxdepth 1 -name "*.schema.json" -type f > "$tmp_schemas"; fi

while IFS= read -r schema_file; do
  if grep -q '"type":' "$schema_file" && ! grep -q '"description":' "$schema_file"; then
    printf '[WARN] Schema file %s might be missing descriptions.
' "${schema_file#"${TARGET_ROOT}"/}"
    MISSING_SCHEMA_DOCS=$((MISSING_SCHEMA_DOCS + 1))
  fi
done < "$tmp_schemas"
rm -f "$tmp_schemas"

printf '==> Auditing Shell Function Docstring Coverage...
'
MISSING_FUNC_DOCS=0
tmp_sh=$(mktemp)
if [ -d "${TARGET_ROOT}/_lib" ]; then find "${TARGET_ROOT}" -name "*.sh" -type f | grep -v "node_modules" > "$tmp_sh" || true; else find "${TARGET_ROOT}" -maxdepth 2 -name "*.sh" -type f | grep -vE "/(\.git|creds|node_modules|\.venv|logs|test)/" > "$tmp_sh" || true; fi

while IFS= read -r sh_file; do
  missing_in_file=$(awk -v file="${sh_file#"${TARGET_ROOT}"/}" '
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
    printf '[WARN] Missing or invalid function docstring(s) in %s:
%s
' "${sh_file#"${TARGET_ROOT}"/}" "$missing_in_file"
    MISSING_FUNC_DOCS=$((MISSING_FUNC_DOCS + 1))
  fi
done < "$tmp_sh"
rm -f "$tmp_sh"

printf '==> Auditing Batch Label Docstring Coverage...
'
MISSING_CMD_DOCS=0
tmp_cmd=$(mktemp)
if [ -d "${TARGET_ROOT}/_lib" ]; then find "${TARGET_ROOT}" -name "*.cmd" -type f | grep -v "node_modules" > "$tmp_cmd" || true; else find "${TARGET_ROOT}" -maxdepth 2 -name "*.cmd" -type f | grep -vE "/(\.git|creds|node_modules|\.venv|logs|test)/" > "$tmp_cmd" || true; fi

while IFS= read -r cmd_file; do
  missing_in_file=$(awk -v file="${cmd_file#"${TARGET_ROOT}"/}" '
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
    printf '[WARN] Missing or invalid label docstring(s) in %s:
%s
' "${cmd_file#"${TARGET_ROOT}"/}" "$missing_in_file"
    MISSING_CMD_DOCS=$((MISSING_CMD_DOCS + 1))
  fi
done < "$tmp_cmd"
rm -f "$tmp_cmd"

printf '==> Auditing PowerShell Header Coverage...
'
MISSING_PS1_DOCS=0
tmp_ps1=$(mktemp)
if [ -d "${TARGET_ROOT}/_lib" ]; then find "${TARGET_ROOT}" -name "*.ps1" -type f | grep -v "node_modules" > "$tmp_ps1" || true; else find "${TARGET_ROOT}" -maxdepth 1 -name "*.ps1" -type f > "$tmp_ps1" || true; fi

while IFS= read -r ps1_file; do
  if ! head -n 30 "$ps1_file" | grep -q "## Overview"; then
    printf '[WARN] Missing ## Overview in %s
' "${ps1_file#"${TARGET_ROOT}"/}"
    MISSING_PS1_DOCS=$((MISSING_PS1_DOCS + 1))
  elif ! head -n 30 "$ps1_file" | grep -q "## Usage"; then
    printf '[WARN] Missing ## Usage in %s
' "${ps1_file#"${TARGET_ROOT}"/}"
    MISSING_PS1_DOCS=$((MISSING_PS1_DOCS + 1))
  fi
  missing_ps1_functions=$(awk -v file="${ps1_file#"${TARGET_ROOT}"/}" '
    BEGIN { has_doc = 0; in_here_str = 0 }
    { sub(/\r$/, "", $0) }
    in_here_str {
      if ($0 ~ /^"@/ || $0 ~ /^'\''@/) in_here_str = 0
      next
    }
    /@"$/ || /@'\''$/ { in_here_str = 1; next }
    /^[[:space:]]*#[[:space:]]*##[[:space:]]+/ { has_doc = 1; next }
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*function[[:space:]]+[A-Za-z0-9_-]+/ {
      if (!has_doc) print file ":" NR ":" $0
      has_doc = 0
      next
    }
    /^[[:space:]]*$/ { next }
    { has_doc = 0 }
  ' "$ps1_file")
  if [ -n "$missing_ps1_functions" ]; then
    printf '[WARN] Missing PowerShell function docstring(s) in %s:
%s
' "${ps1_file#"${TARGET_ROOT}"/}" "$missing_ps1_functions"
    MISSING_PS1_DOCS=$((MISSING_PS1_DOCS + 1))
  fi
done < "$tmp_ps1"
rm -f "$tmp_ps1"

TOTAL_ITEMS=$((TOTAL_COMPS + TOTAL_SCRIPTS))
MISSING_ITEMS=$((MISSING_COMP_READMES + MISSING_SCRIPT_HEADERS))
DOCUMENTED_ITEMS=$((TOTAL_ITEMS - MISSING_ITEMS))
if [ "$TOTAL_ITEMS" -gt 0 ]; then
  COVERAGE_PCT=$((DOCUMENTED_ITEMS * 100 / TOTAL_ITEMS))
else
  COVERAGE_PCT=100
fi

printf '==> Documentation Coverage: %d%% (%d/%d documented: %d/%d component READMEs, %d/%d script headers)\n' "$COVERAGE_PCT" "$DOCUMENTED_ITEMS" "$TOTAL_ITEMS" "$((TOTAL_COMPS - MISSING_COMP_READMES))" "$TOTAL_COMPS" "$((TOTAL_SCRIPTS - MISSING_SCRIPT_HEADERS))" "$TOTAL_SCRIPTS"

if [ "$UPDATE_README" -eq 1 ]; then
  update_readme_shield "$README_FILE" "$COVERAGE_PCT"
fi

TOTAL_ERRORS=$((MISSING_COMP_READMES + MISSING_SCRIPT_HEADERS + MISSING_SCHEMA_DOCS + MISSING_FUNC_DOCS + MISSING_CMD_DOCS + MISSING_PS1_DOCS))

if [ "$TOTAL_ERRORS" -eq 0 ]; then
  printf '[PASS] 100%% Documentation Coverage Audit Passed!\n'
  exit 0
else
  printf '[ERROR] Found %d missing component READMEs, %d scripts missing header docs, %d schema files, %d shell scripts, %d batch files, and %d powershell scripts with missing or placeholder docs.\n' "$MISSING_COMP_READMES" "$MISSING_SCRIPT_HEADERS" "$MISSING_SCHEMA_DOCS" "$MISSING_FUNC_DOCS" "$MISSING_CMD_DOCS" "$MISSING_PS1_DOCS" >&2
  exit 1
fi
