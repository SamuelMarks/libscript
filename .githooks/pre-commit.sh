#!/bin/sh
# ## Overview
# Handles operations related to the component '.githooks'.
# 
# ## Usage
# Execute this script to perform actions for .githooks.

set -e
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
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
_SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)

# Ensure we run from the git repository root
cd "$(git rev-parse --show-toplevel)"

printf '%s\n' "Running pre-commit hooks..."

STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$STAGED_FILES" ]; then
    printf '%s\n' "No files to check."
else
    # 1. Enforce line endings and indent
    printf '%s\n' "Enforcing line endings and indent..."
    # Set IFS to newline only to handle spaces in filenames
    OIFS="$IFS"
    IFS='
'
    for file in $STAGED_FILES; do
        if [ ! -f "$file" ]; then continue; fi
        
        # Determine target line ending from gitattributes
        ext="${file##*.}"
        filename=$(basename "$file")
        
        # Enforce CRLF for Windows scripts
        if [ "$ext" = "cmd" ] || [ "$ext" = "bat" ]; then
            if command -v unix2dos >/dev/null 2>&1; then unix2dos -q "$file"; fi
        # Enforce LF for everything else typically
        elif [ "$ext" = "sh" ] || [ "$ext" = "bash" ] || [ "$ext" = "zsh" ] || [ "$ext" = "conf" ] || [ "$ext" = "md" ] || [ "$ext" = "json" ] || [ "$ext" = "yml" ] || [ "$ext" = "yaml" ] || [ "$ext" = "py" ] || [ "$ext" = "ps1" ] || printf '%s\n' "$filename" | grep -q "Dockerfile" || [ "$filename" = ".gitignore" ] || [ "$filename" = ".gitattributes" ] || [ "$filename" = ".dockerignore" ] || [ "$filename" = ".editorconfig" ]; then
            if command -v dos2unix >/dev/null 2>&1; then dos2unix -q "$file"; fi
        fi
        
        # Enforce Indent via Prettier where applicable
        if [ "$ext" = "json" ] || [ "$ext" = "yml" ] || [ "$ext" = "yaml" ] || [ "$ext" = "md" ]; then
             if command -v npx >/dev/null 2>&1; then
                 npx prettier --write "$file" >/dev/null 2>&1 || true
             fi
        fi
        
        git add "$file"
    done
    IFS="$OIFS"

    # 2. Spellcheck
    printf '%s\n' "Running spellcheck..."
    if command -v npx >/dev/null 2>&1; then
        tmp_files=$(mktemp)
        printf '%s\n' "$STAGED_FILES" | while IFS= read -r file; do
             if [ -f "$file" ]; then
                 printf "%s\0" "$file"
             fi
        done > "$tmp_files"
        
        if [ -s "$tmp_files" ]; then
             xargs -0 npx cspell lint --no-progress --no-summary < "$tmp_files" || printf '%s\n' "Spellcheck found potential issues, but continuing..."
        fi
        rm -f "$tmp_files"
    fi
fi

# 3. Shellcheck
printf '%s\n' "Running shellcheck..."
if printf "%s\n" "$STAGED_FILES" | grep "\.sh$" | grep -vE "node_modules|\.git|top\.sh|bottom\.sh|template_.*\.sh|netctl/lib/.*\.sh|libscript\.sh|patch_.*\.sh|fix_.*\.sh|update_.*\.sh|.*_gen\.sh|gen/.*|test_.*\.sh" >/dev/null 2>&1; then
  printf "%s\n" "$STAGED_FILES" | grep "\.sh$" | grep -vE "node_modules|\.git|top\.sh|bottom\.sh|template_.*\.sh|netctl/lib/.*\.sh|libscript\.sh|patch_.*\.sh|fix_.*\.sh|update_.*\.sh|.*_gen\.sh|gen/.*|test_.*\.sh" | xargs -n 50 -P 4 shellcheck -e SC2086,SC2317,SC2148,SC1090,SC1091,SC3043,SC3040,SC3025,SC2129,SC2016,SC3054,SC2296,SC2209,SC2154,SC2221,SC2222,SC2034,SC2038,SC1009,SC1083,SC1073,SC1072,SC1089,SC2018,SC2019,SC1003,SC1047,SC1046,SC1035,SC2295,SC2251,SC3059,SC2081,SC3010,SC2054,SC3045
fi

# 4. Regenerate Markdown Readmes
printf '%s\n' "Regenerating markdown readme files interpolating the json..."
if [ -x "devtools/docs-gen/generate_markdown_docs.sh" ]; then
    ./devtools/docs-gen/generate_markdown_docs.sh
    # Re-add any modified README.md files
    git ls-files -m | grep "README.md$" | xargs -I {} git add "{}" || true
fi



printf '%s\n' "Updating Supported Components in README.md..."
if [ -x "tests/update_results.sh" ]; then
    ./tests/update_results.sh
fi


git add README.md
printf '%s\n' "Pre-commit hook completed successfully."
