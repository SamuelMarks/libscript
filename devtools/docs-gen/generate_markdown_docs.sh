#!/bin/sh
# ## Overview
# Generates markdown documentation for the libscript codebase.
# 
# ## Usage
# Execute this script to rebuild the markdown documentation.


set -eu

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  printf '%s\n' "Usage: $(basename "$0")"
  printf '%s\n' "Generates markdown documentation for the libscript codebase."
  printf '\n'
  printf '%s\n' "Options:"
  printf '%s\n' "  --help, -h, /?, -?  Show this help message."
  exit 0
fi

# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
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
SCRIPT_DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Ensure markers exist
export ROOT_DIR
"${SCRIPT_DIR}/inject_markers.sh"

printf '%s\n' "Generating markdown docs..."

# We need to process each component
find "$ROOT_DIR" -type f -name "README.md" | grep -E "(_lib|app-servers|stacks)" | while IFS= read -r readme; do
    dir="$(dirname "$readme")"
    
    # Check if vars.schema.json exists
    schema="$dir/vars.schema.json"
    if [ -f "$schema" ]; then
        # Create temp files
        vars_tmp=$(mktemp)
        plat_tmp=$(mktemp)
        
        # Build vars table
        printf '%s\n' "| Variable | Description | Default | Aliases/Examples |" > "$vars_tmp"
        printf '%s\n' "|---|---|---|---|" >> "$vars_tmp"
        
        # Process base_vars if it's a _lib component
        if case "$dir" in *"_lib/"*) true ;; *) false ;; esac && [ -f "$ROOT_DIR/_lib/_common/base_vars.schema.json" ]; then
            jq -r '.properties | to_entries[] | "| `\(.key)` | \(.value.description // "") | `\(.value.default // "none")` | \([(.value.version_aliases[]?), (.value.examples[]?)] | join(", ")) |"' "$ROOT_DIR/_lib/_common/base_vars.schema.json" >> "$vars_tmp"
        fi
        
        # Process component vars
        jq -r '.properties | to_entries[] | "| `\(.key)` | \(.value.description // "") | `\(.value.default // "none")` | \([(.value.version_aliases[]?), (.value.examples[]?)] | join(", ")) |"' "$schema" >> "$vars_tmp"
        
        # Clean up commas in empty arrays and pipes
        sed -i '' 's/ |"$/ |/' "$vars_tmp" 2>/dev/null || sed -i 's/ |"$/ |/' "$vars_tmp"
        
        # Build platforms table
        # We can extract it from scripts
        printf '%s\n' "- Linux" > "$plat_tmp"
        printf '%s\n' "- macOS" >> "$plat_tmp"
        printf '%s\n' "- Windows" >> "$plat_tmp"
        
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
done

printf '%s\n' "Done."
