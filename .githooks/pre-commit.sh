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
cat <<'TABLE' >components_table.tmp
## Supported Components

| Component | Linux (apk) | Linux (deb) | Linux (rpm) | Windows | SunOS | FreeBSD |
|---|---|---|---|---|---|---|
TABLE

# Find all components excluding _common
find _lib -mindepth 2 -maxdepth 2 -type d ! -path "_lib/_common*" | sed 's|.*/||' | sort -u | while read -r comp; do
    # Extract existing statuses from README.md if present
    existing_line=$(grep "^| \`$comp\` |" README.md || true)
    existing_apk="❓"
    existing_deb="❓"
    existing_rpm="❓"
    if [ -n "$existing_line" ]; then
        existing_apk=$(echo "$existing_line" | awk -F'|' '{print $3}' | xargs)
        existing_deb=$(echo "$existing_line" | awk -F'|' '{print $4}' | xargs)
        existing_rpm=$(echo "$existing_line" | awk -F'|' '{print $5}' | xargs)
    fi

    # Alpine (.apk)
    apk_status="$existing_apk"
    if [ -f "tests_tmp/$comp.linux.alpine.success" ]; then
        apk_status="✅"
    elif [ -f "tests_tmp/$comp.linux.alpine.failure" ]; then
        apk_status="❌"
    fi
    
    # Debian (.deb)
    deb_status="$existing_deb"
    if ls tests_tmp/"$comp".linux.debian.success >/dev/null 2>&1 || ls tests_tmp/"$comp".linux.ubuntu.success >/dev/null 2>&1; then
        deb_status="✅"
    elif ls tests_tmp/"$comp".linux.debian.failure >/dev/null 2>&1 || ls tests_tmp/"$comp".linux.ubuntu.failure >/dev/null 2>&1; then
        deb_status="❌"
    fi
    
    # RHEL/Fedora (.rpm)
    rpm_status="$existing_rpm"
    if ls tests_tmp/"$comp".linux.rhel.success >/dev/null 2>&1 || ls tests_tmp/"$comp".linux.fedora.success >/dev/null 2>&1 || ls tests_tmp/"$comp".linux.almalinux.success >/dev/null 2>&1 || ls tests_tmp/"$comp".linux.centos.success >/dev/null 2>&1; then
        rpm_status="✅"
    elif ls tests_tmp/"$comp".linux.rhel.failure >/dev/null 2>&1 || ls tests_tmp/"$comp".linux.fedora.failure >/dev/null 2>&1 || ls tests_tmp/"$comp".linux.almalinux.failure >/dev/null 2>&1 || ls tests_tmp/"$comp".linux.centos.failure >/dev/null 2>&1; then
        rpm_status="❌"
    fi
    
    printf "| \`%s\` | %s | %s | %s | - | - | - |\n" "$comp" "$apk_status" "$deb_status" "$rpm_status" >>components_table.tmp
done

if grep -q "## Supported Components" README.md; then
  awk '
    /## Supported Components/ {
        in_ci = 1;
        while ((getline line < "components_table.tmp") > 0) print line;
        print "";
        next;
    }
    /^## / && in_ci {
        in_ci = 0;
    }
    !in_ci {
        print
    }
    ' README.md >README.tmp && mv README.tmp README.md
else
  awk '
    /^## License/ {
        while ((getline line < "components_table.tmp") > 0) print line;
        print "";
    }
    { print }
  ' README.md >README.tmp && mv README.tmp README.md
fi
rm -f components_table.tmp

git add README.md
printf '%s\n' "Pre-commit hook completed successfully."
