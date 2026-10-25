#!/bin/sh
# ## Overview
# Generates markdown documentation for the libscript codebase.
# 
# ## Usage
# Execute this script to rebuild the markdown documentation.


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

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  printf '%s\n' "Usage: $(basename "$0")"
  printf '%s\n' "Generates markdown documentation for the libscript codebase."
  printf '\n'
  printf '%s\n' "Options:"
  printf '%s\n' "  --help, -h, /?, -?  Show this help message."
  exit 0
fi
SCRIPT_DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
: "${ROOT_DIR:=$(cd "${SCRIPT_DIR}/../.." && pwd)}"

# ## normalize_markdown_section
# Normalizes a Markdown table or list stream so Prettier column-padding and blank-line differences are ignored when checking if semantic content changed.
normalize_markdown_section() {
  awk '
  {
    gsub(/\r/, "")
    line = $0
    sub(/^[ \t]+/, "", line)
    sub(/[ \t]+$/, "", line)
    if (line == "") next
    if (line ~ /^\|[ \t\-:|]+\|$/) {
      print "|---|---|---|---|"
      next
    }
    if (substr(line, 1, 1) == "|" && substr(line, length(line), 1) == "|") {
      inner = substr(line, 2, length(line) - 2)
      n = split(inner, cells, "|")
      out = "|"
      for (i = 1; i <= n; i++) {
        c = cells[i]
        sub(/^[ \t]+/, "", c)
        sub(/[ \t]+$/, "", c)
        out = out " " c " |"
      }
      print out
      next
    }
    print line
  }'
}

# ## extract_marker_section
# Extracts lines strictly between the first occurrence of begin_marker and end_marker in a file.
extract_marker_section() {
  _file="$1"
  _begin="$2"
  _end="$3"
  awk -v b="$_begin" -v e="$_end" '
  BEGIN { inside = 0; done = 0 }
  index($0, b) > 0 && !done { inside = 1; next }
  index($0, e) > 0 && inside { inside = 0; done = 1; next }
  inside { print }
  ' "$_file"
}

# ## handle_interrupt
# Signal handler to abort documentation generation immediately on interruption.
handle_interrupt() {
  trap - INT TERM HUP EXIT
  [ -n "${base_vars_tmp-}" ] && [ -f "${base_vars_tmp-}" ] && rm -f "$base_vars_tmp" 2>/dev/null || true
  [ -n "${vars_tmp-}" ] && [ -f "${vars_tmp-}" ] && rm -f "$vars_tmp" 2>/dev/null || true
  [ -n "${plat_tmp-}" ] && [ -f "${plat_tmp-}" ] && rm -f "$plat_tmp" 2>/dev/null || true
  [ -n "${modified_tmp-}" ] && [ -f "${modified_tmp-}" ] && rm -f "$modified_tmp" 2>/dev/null || true
  exit 130
}

trap 'handle_interrupt' INT TERM HUP

# Ensure markers exist
export ROOT_DIR
"${SCRIPT_DIR}/inject_markers.sh"

printf '%s\n' "Generating markdown docs..."

modified_tmp=$(mktemp)
base_vars_tmp=$(mktemp)
if [ -f "$ROOT_DIR/_lib/_common/base_vars.schema.json" ]; then
  jq -r '.properties | to_entries[] | "| `\(.key)` | \((.value.description // "") | gsub("[\r\n]+"; " ")) | `\(if (.value.default | type) == "array" and (.value.default | length) == 0 then "none" else (.value.default // "none") end)` | \([(.value.version_aliases[]?), (.value.examples[]?)] | join(", ")) |"' "$ROOT_DIR/_lib/_common/base_vars.schema.json" > "$base_vars_tmp"
  sed -i '' 's/ |"$/ |/' "$base_vars_tmp" 2>/dev/null || sed -i 's/ |"$/ |/' "$base_vars_tmp"
fi

plat_tmp=$(mktemp)
printf '%s\n' "- Linux" > "$plat_tmp"
printf '%s\n' "- macOS" >> "$plat_tmp"
printf '%s\n' "- Windows" >> "$plat_tmp"
plat_norm=$(normalize_markdown_section < "$plat_tmp")

# We need to process each component
find "$ROOT_DIR" -type f -name "README.md" | grep -E "(_lib|app-servers|topologies|payloads)" | while IFS= read -r readme; do
    dir="$(dirname "$readme")"
    
    # Check if vars.schema.json exists
    schema="$dir/vars.schema.json"
    if [ -f "$schema" ]; then
        vars_tmp=$(mktemp)
        
        # Build vars table
        printf '%s\n' "| Variable | Description | Default | Aliases/Examples |" > "$vars_tmp"
        printf '%s\n' "|---|---|---|---|" >> "$vars_tmp"
        
        # Process base_vars if it's a _lib component
        if case "$dir" in *"_lib/"*) true ;; *) false ;; esac && [ -s "$base_vars_tmp" ]; then
            cat "$base_vars_tmp" >> "$vars_tmp"
        fi
        
        # Process component vars
        jq -r '.properties | to_entries[] | "| `\(.key)` | \((.value.description // "") | gsub("[\r\n]+"; " ")) | `\(if (.value.default | type) == "array" and (.value.default | length) == 0 then "none" else (.value.default // "none") end)` | \([(.value.version_aliases[]?), (.value.examples[]?)] | join(", ")) |"' "$schema" >> "$vars_tmp"
        
        # Clean up commas in empty arrays and pipes
        sed -i '' 's/ |"$/ |/' "$vars_tmp" 2>/dev/null || sed -i 's/ |"$/ |/' "$vars_tmp"

        vars_norm=$(normalize_markdown_section < "$vars_tmp")
        existing_vars_norm=$(extract_marker_section "$readme" "<!-- BEGIN_VARS -->" "<!-- END_VARS -->" | normalize_markdown_section)
        existing_plat_norm=$(extract_marker_section "$readme" "<!-- BEGIN_PLATFORMS -->" "<!-- END_PLATFORMS -->" | normalize_markdown_section)

        if [ "$vars_norm" != "$existing_vars_norm" ] || [ "$plat_norm" != "$existing_plat_norm" ]; then
            # Inject using awk (replacing only first BEGIN_VARS and first BEGIN_PLATFORMS block)
            awk -v vars="$vars_tmp" -v plats="$plat_tmp" '
            BEGIN { in_vars = 0; in_plats = 0; done_vars = 0; done_plats = 0; }
            /<!-- BEGIN_VARS -->/ && !done_vars {
                print
                while ((getline line < vars) > 0) print line
                close(vars)
                in_vars = 1
                done_vars = 1
                next
            }
            /<!-- END_VARS -->/ && in_vars {
                in_vars = 0
                print
                next
            }
            /<!-- BEGIN_PLATFORMS -->/ && !done_plats {
                print
                while ((getline line < plats) > 0) print line
                close(plats)
                in_plats = 1
                done_plats = 1
                next
            }
            /<!-- END_PLATFORMS -->/ && in_plats {
                in_plats = 0
                print
                next
            }
            !in_vars && !in_plats { print }
            ' "$readme" > "${readme}.tmp"

            if ! cmp -s "${readme}.tmp" "$readme"; then
                mv "${readme}.tmp" "$readme"
                if command -v dos2unix >/dev/null 2>&1; then
                    dos2unix -q "$readme" 2>/dev/null || true
                fi
                printf '%s\n' "$readme" >> "$modified_tmp"
            else
                rm -f "${readme}.tmp"
            fi
        fi
        rm -f "$vars_tmp"
    fi
done

rm -f "$base_vars_tmp" "$plat_tmp"

if [ -s "$modified_tmp" ]; then
    if command -v prettier >/dev/null 2>&1; then
        xargs -n 40 prettier --write < "$modified_tmp" >/dev/null 2>&1 || true
    elif [ -x "$ROOT_DIR/node_modules/.bin/prettier" ]; then
        xargs -n 40 "$ROOT_DIR/node_modules/.bin/prettier" --write < "$modified_tmp" >/dev/null 2>&1 || true
    elif command -v npx >/dev/null 2>&1; then
        xargs -n 40 npx --yes prettier --write < "$modified_tmp" >/dev/null 2>&1 || true
    fi
fi
rm -f "$modified_tmp"

printf '%s\n' "Done."
