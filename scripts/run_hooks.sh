#!/bin/sh
# run_hooks.sh <json_file> <hook_type>
set -e
json_file="$1"
hook_type="$2"

if [ ! -f "$json_file" ]; then exit 0; fi

hooks=$(jq -c ".hooks.${hook_type}[]?" "$json_file" 2>/dev/null || true)

if [ -z "$hooks" ]; then exit 0; fi

echo "Running $hook_type hooks..."
echo "$hooks" | while read -r hook; do
    name=$(echo "$hook" | jq -r '.name // "unnamed_hook"')
    cmd=$(echo "$hook" | jq -r '.command // empty')
    cond=$(echo "$hook" | jq -r '.condition // empty')

    if [ -n "$cond" ]; then
        if echo "$cond" | grep -q "^unless_exists "; then
            file=$(echo "$cond" | sed 's/^unless_exists //')
            if [ -e "$file" ]; then
                echo "Skipping hook '$name': $file exists"
                continue
            fi
        fi
    fi

    if [ -n "$cmd" ]; then
        echo "Executing hook '$name': $cmd"
        eval "$cmd"
    fi
done
