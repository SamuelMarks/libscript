#!/bin/sh
# ## Overview
# Handles operations related to the component '.githooks'.
# 
# ## Usage
# Execute this script to perform actions for .githooks.

set -e

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
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

printf '%s\n' "Running pre-commit hooks..."

STAGED_FILES=$(git diff --no-ext-diff --cached --name-only --diff-filter=ACM)

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
                 npx --yes prettier --write "$file" >/dev/null 2>&1 || true
             fi
        fi
        
        git add "$file"
    done
    IFS="$OIFS"

    # 2. Spellcheck
    printf '%s\n' "Running spellcheck..."
    if command -v npx >/dev/null 2>&1; then
        tmp_files=$(mktemp)
        trap 'rm -f "$tmp_files" 2>/dev/null || true' EXIT INT TERM HUP
        printf '%s\n' "$STAGED_FILES" | while IFS= read -r file; do
             if [ -f "$file" ]; then
                 printf '%s\n' "$file"
             fi
        done > "$tmp_files"
        
        if [ -s "$tmp_files" ]; then
             if ! npx --yes --quiet cspell lint --no-progress --no-summary --no-must-find-files --file-list stdin < "$tmp_files"; then
                 rm -f "$tmp_files"
                 trap - EXIT INT TERM HUP
                 printf '%s\n' "[ERROR] Spellcheck failed. Please fix spelling errors or update .cspell.json." >&2
                 exit 1
             fi
        fi
        rm -f "$tmp_files"
        trap - EXIT INT TERM HUP
    fi
fi

# 3. LibScript Standards Audit
printf '%s\n' "Running LibScript engineering standards audit..."
if [ -x "devtools/audit/audit_standards.sh" ]; then
    ./devtools/audit/audit_standards.sh --staged
fi

# 4. Shellcheck
printf '%s\n' "Running shellcheck..."
if printf "%s\n" "$STAGED_FILES" | grep "\.sh$" | grep -vE "node_modules|\.git|top\.sh|bottom\.sh|template_.*\.sh|netctl/lib/.*\.sh|libscript\.sh|patch_.*\.sh|fix_.*\.sh|update_.*\.sh|.*_gen\.sh|gen/.*|test_.*\.sh" >/dev/null 2>&1; then
  printf "%s\n" "$STAGED_FILES" | grep "\.sh$" | grep -vE "node_modules|\.git|top\.sh|bottom\.sh|template_.*\.sh|netctl/lib/.*\.sh|libscript\.sh|patch_.*\.sh|fix_.*\.sh|update_.*\.sh|.*_gen\.sh|gen/.*|test_.*\.sh" | xargs -n 50 -P 4 shellcheck -e SC2086,SC2317,SC2148,SC1090,SC1091,SC3043,SC3040,SC3025,SC2129,SC2016,SC3054,SC2296,SC2209,SC2154,SC2221,SC2222,SC2034,SC2038,SC1009,SC1083,SC1073,SC1072,SC1089,SC2018,SC2019,SC1003,SC1047,SC1046,SC1035,SC2295,SC2251,SC3059,SC2081,SC3010,SC2054,SC3045
fi

# 5. Regenerate Markdown Readmes
printf '%s\n' "Regenerating markdown readme files interpolating the json..."
if [ -x "devtools/docs-gen/generate_markdown_docs.sh" ]; then
    ./devtools/docs-gen/generate_markdown_docs.sh
    # Re-add any modified README.md files
    for rfile in $(git ls-files -m | grep "README.md$" || true); do
        if command -v dos2unix >/dev/null 2>&1; then dos2unix -q "$rfile" 2>/dev/null || true; fi
        if command -v npx >/dev/null 2>&1; then npx --yes prettier --write "$rfile" >/dev/null 2>&1 || true; fi
        git add "$rfile"
    done
fi

printf '%s\n' "Updating Supported Components in README.md..."
if [ -x "tests/update_results.sh" ]; then
    ./tests/update_results.sh
fi

if command -v dos2unix >/dev/null 2>&1; then
    dos2unix -q README.md 2>/dev/null || true
fi
if command -v npx >/dev/null 2>&1; then
    npx --yes prettier --write README.md >/dev/null 2>&1 || true
fi

git add README.md
printf '%s\n' "Pre-commit hook completed successfully."
