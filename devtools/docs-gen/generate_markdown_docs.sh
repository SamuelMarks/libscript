#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Ensure markers exist
export ROOT_DIR
"${SCRIPT_DIR}/inject_markers.sh"

echo "Generating markdown docs..."

# We need to process each component
while IFS= read -r readme; do
    dir="$(dirname "$readme")"
    
    # Check if vars.schema.json exists
    schema="$dir/vars.schema.json"
    if [ -f "$schema" ]; then
        # Create temp files
        vars_tmp=$(mktemp)
        plat_tmp=$(mktemp)
        
        # Build vars table
        echo "| Variable | Description | Default | Aliases/Examples |" > "$vars_tmp"
        echo "|---|---|---|---|" >> "$vars_tmp"
        
        # Process base_vars if it's a _lib component
        if [[ "$dir" == *"_lib/"* ]] && [ -f "$ROOT_DIR/_lib/_common/base_vars.schema.json" ]; then
            jq -r '.properties | to_entries[] | "| `\(.key)` | \(.value.description // "") | `\(.value.default // "none")` | \([(.value.version_aliases[]?), (.value.examples[]?)] | join(", ")) |"' "$ROOT_DIR/_lib/_common/base_vars.schema.json" >> "$vars_tmp"
        fi
        
        # Process component vars
        jq -r '.properties | to_entries[] | "| `\(.key)` | \(.value.description // "") | `\(.value.default // "none")` | \([(.value.version_aliases[]?), (.value.examples[]?)] | join(", ")) |"' "$schema" >> "$vars_tmp"
        
        # Clean up commas in empty arrays and pipes
        sed -i '' 's/ |"$/ |/' "$vars_tmp" 2>/dev/null || sed -i 's/ |"$/ |/' "$vars_tmp"
        
        # Build platforms table
        # We can extract it from scripts
        echo "- Linux" > "$plat_tmp"
        echo "- macOS" >> "$plat_tmp"
        echo "- Windows" >> "$plat_tmp"
        
        # Inject using awk
        awk -v vars="$vars_tmp" -v plats="$plat_tmp" '
        BEGIN { in_vars = 0; in_plats = 0; }
        /<!-- BEGIN_VARS -->/ {
            print
            while ((getline line < vars) > 0) print line
            in_vars = 1
            next
        }
        /<!-- END_VARS -->/ {
            in_vars = 0
            print
            next
        }
        /<!-- BEGIN_PLATFORMS -->/ {
            print
            while ((getline line < plats) > 0) print line
            in_plats = 1
            next
        }
        /<!-- END_PLATFORMS -->/ {
            in_plats = 0
            print
            next
        }
        !in_vars && !in_plats { print }
        ' "$readme" > "${readme}.tmp"
        
        mv "${readme}.tmp" "$readme"
        rm -f "$vars_tmp" "$plat_tmp"
    fi
done < <(find "$ROOT_DIR" -type f -name "README.md" | grep -E "(_lib|app-servers|stacks)")

echo "Done."
