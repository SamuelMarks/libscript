#!/bin/sh
# ## Overview
# Handles operations related to the component '.githooks'.
# 
# ## Usage
# Execute this script to perform actions for .githooks.

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

# Ensure we run from the git repository root
cd "$(git rev-parse --show-toplevel)"

if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/languages/nodejs/env.sh" ]; then
  _pc_saved_this="${THIS_FILE:-}"
  _pc_saved_dir="${SCRIPT_DIR:-}"
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/languages/nodejs/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}" >/dev/null 2>&1 || true
  unset SCRIPT_NAME || true
  THIS_FILE="$_pc_saved_this"
  SCRIPT_DIR="$_pc_saved_dir"
  unset _pc_saved_this _pc_saved_dir || true
fi

printf '%s\n' 'Running pre-commit hooks...'

AUDIT_MODE='--staged'
STAGED_FILES=$(git diff --no-ext-diff --cached --name-only --diff-filter=ACM)
if [ "${1:-}" = "--all" ]; then
    CHECK_FILES=$(git ls-files)
    AUDIT_MODE='--all'
else
    CHECK_FILES="$STAGED_FILES"
fi

if [ -z "$STAGED_FILES" ]; then
    printf '%s\n' 'No staged files to reformat.'
else
    # 1. Enforce line endings and indent
    printf '%s\n' 'Enforcing line endings and indent...'
    _tmp_crlf=$(mktemp)
    _tmp_lf=$(mktemp)
    _tmp_fmt=$(mktemp)
    printf '%s\n' "$STAGED_FILES" | while IFS= read -r file; do
        [ -f "$file" ] || continue
        ext="${file##*.}"
        filename=$(basename "$file")
        if [ "$ext" = "cmd" ] || [ "$ext" = "bat" ]; then
            printf '%s\n' "$file" >> "$_tmp_crlf"
        elif [ "$ext" = "sh" ] || [ "$ext" = "bash" ] || [ "$ext" = "zsh" ] || [ "$ext" = "conf" ] || [ "$ext" = "md" ] || [ "$ext" = "json" ] || [ "$ext" = "yml" ] || [ "$ext" = "yaml" ] || [ "$ext" = "py" ] || [ "$ext" = "ps1" ] || printf '%s\n' "$filename" | grep -q "Dockerfile" || [ "$filename" = ".gitignore" ] || [ "$filename" = ".gitattributes" ] || [ "$filename" = ".dockerignore" ] || [ "$filename" = ".editorconfig" ]; then
            printf '%s\n' "$file" >> "$_tmp_lf"
        fi
        if [ "$ext" = "json" ] || [ "$ext" = "yml" ] || [ "$ext" = "yaml" ] || [ "$ext" = "md" ]; then
            printf '%s\n' "$file" >> "$_tmp_fmt"
        fi
    done
    if [ -s "$_tmp_crlf" ] && command -v unix2dos >/dev/null 2>&1; then
        xargs -n 100 unix2dos -q < "$_tmp_crlf" 2>/dev/null || true
    fi
    if [ -s "$_tmp_lf" ] && command -v dos2unix >/dev/null 2>&1; then
        xargs -n 100 dos2unix -q < "$_tmp_lf" 2>/dev/null || true
    fi
    if [ -s "$_tmp_fmt" ]; then
        if command -v prettier >/dev/null 2>&1; then
            xargs -n 100 prettier --write < "$_tmp_fmt" >/dev/null 2>&1 || true
        elif [ -x "node_modules/.bin/prettier" ]; then
            xargs -n 100 node_modules/.bin/prettier --write < "$_tmp_fmt" >/dev/null 2>&1 || true
        elif command -v npx >/dev/null 2>&1; then
            xargs -n 100 npx --yes prettier --write < "$_tmp_fmt" >/dev/null 2>&1 || true
        fi
    fi
    rm -f "$_tmp_crlf" "$_tmp_lf" "$_tmp_fmt"
    printf '%s\n' "$STAGED_FILES" | xargs -n 100 git add -- 2>/dev/null || true
fi

if [ -n "$CHECK_FILES" ]; then
    # 2. Spellcheck
    printf '%s\n' 'Running spellcheck...'
    _cspell_cmd=""
    if command -v cspell >/dev/null 2>&1; then
        _cspell_cmd='cspell'
    elif [ -x "node_modules/.bin/cspell" ]; then
        _cspell_cmd='node_modules/.bin/cspell'
    elif command -v npx >/dev/null 2>&1; then
        _cspell_cmd="npx --yes --quiet cspell"
    fi
    if [ -n "$_cspell_cmd" ]; then
        tmp_files=$(mktemp)
        trap 'rm -f "$tmp_files" 2>/dev/null || true' EXIT INT TERM HUP
        printf '%s\n' "$CHECK_FILES" | while IFS= read -r file; do
             if [ -f "$file" ]; then
                 printf '%s\n' "$file"
             fi
        done > "$tmp_files"
        
        if [ -s "$tmp_files" ]; then
             # shellcheck disable=SC2086
             if ! $_cspell_cmd lint --no-progress --no-summary --no-must-find-files --file-list stdin < "$tmp_files"; then
                 rm -f "$tmp_files"
                 trap - EXIT INT TERM HUP
                 printf '%s\n' '[ERROR] Spellcheck failed. Please fix spelling errors or update .cspell.json.' >&2
                 exit 1
             fi
        fi
        rm -f "$tmp_files"
        trap - EXIT INT TERM HUP
    fi
fi

# 3. LibScript Standards Audit
printf '%s\n' 'Running LibScript engineering standards audit...'
if [ -x "devtools/audit/audit_standards.sh" ]; then
    ./devtools/audit/audit_standards.sh "$AUDIT_MODE"
fi

if [ -x "devtools/audit/audit_version_manager.sh" ]; then
    if [ "$AUDIT_MODE" = "--all" ] || printf '%s\n' "$CHECK_FILES" | grep -q '^_lib/'; then
        ./devtools/audit/audit_version_manager.sh
    fi
fi

if [ -x "devtools/audit/audit_schema_vars.sh" ]; then
    if [ "$AUDIT_MODE" = "--all" ] || printf '%s\n' "$CHECK_FILES" | grep -qE '^(_lib/|.*\.schema\.json$)'; then
        ./devtools/audit/audit_schema_vars.sh "$AUDIT_MODE"
    fi
fi

# 4. Shellcheck
if command -v shellcheck >/dev/null 2>&1; then
  printf '%s\n' 'Running shellcheck...'
  SHELLCHECK_OPT_ARGS=""
  if shellcheck --list-optional 2>/dev/null | grep -q "useless-use-of-cat"; then
    SHELLCHECK_OPT_ARGS="-o useless-use-of-cat"
  fi
  if printf "%s\n" "$CHECK_FILES" | grep "\.sh$" | grep -vE "node_modules|\.git|top\.sh|bottom\.sh|template_.*\.sh|patch_.*\.sh|fix_.*\.sh|update_.*\.sh|.*_gen\.sh|gen/.*" >/dev/null 2>&1; then
    # shellcheck disable=SC2086
    printf "%s\n" "$CHECK_FILES" | grep "\.sh$" | grep -vE "node_modules|\.git|top\.sh|bottom\.sh|template_.*\.sh|patch_.*\.sh|fix_.*\.sh|update_.*\.sh|.*_gen\.sh|gen/.*" | xargs -n 50 -P 4 shellcheck -s sh $SHELLCHECK_OPT_ARGS -e SC2086,SC2317,SC2148,SC1090,SC1091,SC2129,SC2016,SC2296,SC2209,SC2154,SC2034,SC2038,SC1083,SC2018,SC2019,SC1003,SC2251,SC2081,SC2054
  fi
fi

# 5. Regenerate Markdown Readmes
printf '%s\n' 'Regenerating markdown readme files interpolating the json...'
if [ -x "devtools/docs-gen/generate_markdown_docs.sh" ]; then
    ./devtools/docs-gen/generate_markdown_docs.sh
    # Re-add any modified README.md files
    _mod_readmes=$(git ls-files -m | grep "README.md$" || true)
    if [ -n "$_mod_readmes" ]; then
        if command -v dos2unix >/dev/null 2>&1; then printf '%s\n' "$_mod_readmes" | xargs -n 100 dos2unix -q 2>/dev/null || true; fi
        if command -v prettier >/dev/null 2>&1; then printf '%s\n' "$_mod_readmes" | xargs -n 100 prettier --write >/dev/null 2>&1 || true; fi
        printf '%s\n' "$_mod_readmes" | xargs -n 100 git add -- 2>/dev/null || true
    fi
fi

printf '%s\n' 'Updating Supported Components in README.md...'
if [ -x "tests/update_results.sh" ]; then
    ./tests/update_results.sh
fi

printf '%s\n' 'Updating Doc Coverage shield in README.md...'
if [ -x "devtools/audit/doc_coverage.sh" ]; then
    ./devtools/audit/doc_coverage.sh --update-readme
fi

if ! git diff --quiet -- README.md 2>/dev/null; then
    if command -v dos2unix >/dev/null 2>&1; then
        dos2unix -q README.md 2>/dev/null || true
    fi
    if command -v prettier >/dev/null 2>&1; then
        prettier --write README.md >/dev/null 2>&1 || true
    elif [ -x "node_modules/.bin/prettier" ]; then
        node_modules/.bin/prettier --write README.md >/dev/null 2>&1 || true
    elif command -v npx >/dev/null 2>&1; then
        npx --yes prettier --write README.md >/dev/null 2>&1 || true
    fi

    git add README.md
fi
printf '%s\n' 'Pre-commit hook completed successfully.'
