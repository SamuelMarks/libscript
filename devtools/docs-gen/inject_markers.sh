#!/bin/sh
# ## Overview
# Injects specific markers or tags into documentation files.
# 
# ## Usage
# Execute this script to apply structural markers to docs.


set -eu


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

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  printf '%s\n' "Usage: $(basename "$0")"
  printf '%s\n' "Injects specific markers or tags into documentation files."
  printf '\n'
  printf '%s\n' "Options:"
  printf '%s\n' "  --help, -h, /?, -?  Show this help message."
  exit 0
fi
for component_dir in "$LIBSCRIPT_ROOT_DIR"/_lib/*/* "$LIBSCRIPT_ROOT_DIR"/_lib/*/*/* "$LIBSCRIPT_ROOT_DIR"/stacks/*/* "$LIBSCRIPT_ROOT_DIR"/stacks/*/*/*; do
    if [ ! -d "$component_dir" ]; then
        continue
    fi

    if [ ! -f "$component_dir/README.md" ]; then
        continue
    fi

    README_PATH="$component_dir/README.md"
    
    # Check if markers already exist
    if ! grep -q "<!-- BEGIN_VARS -->" "$README_PATH"; then
        TEMP_README=$(mktemp)
        if grep -q -E "^## (Configuration Options|Variables|Environment Variables)" "$README_PATH"; then
           awk '
           /^## (Configuration Options|Variables|Environment Variables)/ {
               print "## Configuration Options"
               print ""
               print "The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script."
               print ""
               print "<!-- BEGIN_VARS -->"
               print "<!-- END_VARS -->"
               in_config = 1
               next
           }
           /^## / && in_config {
               in_config = 0
               print
               next
           }
           !in_config { print }
           ' "$README_PATH" > "$TEMP_README"
           cat "$TEMP_README" > "$README_PATH"
        elif grep -q "^## Platform Support" "$README_PATH"; then
           awk '
           /^## Platform Support/ {
               print "## Configuration Options"
               print ""
               print "The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script."
               print ""
               print "<!-- BEGIN_VARS -->"
               print "<!-- END_VARS -->"
               print ""
           }
           { print }
           ' "$README_PATH" > "$TEMP_README"
           cat "$TEMP_README" > "$README_PATH"
        else
           printf "\n## Configuration Options\n\nThe following environment variables can be passed to the CLI (\`--KEY=VALUE\`) or exported before running the setup script.\n\n<!-- BEGIN_VARS -->\n<!-- END_VARS -->\n" >> "$README_PATH"
        fi
        rm -f "$TEMP_README" 2>/dev/null || true
    fi

    if ! grep -q "<!-- BEGIN_PLATFORMS -->" "$README_PATH"; then
        TEMP_README=$(mktemp)
        if grep -q "^## Platform Support" "$README_PATH"; then
           awk '
           /^## Platform Support/ {
               print
               print ""
               print "<!-- BEGIN_PLATFORMS -->"
               print "<!-- END_PLATFORMS -->"
               in_plat = 1
               next
           }
           /^## / && in_plat {
               in_plat = 0
               print
               next
           }
           !in_plat { print }
           ' "$README_PATH" > "$TEMP_README"
           cat "$TEMP_README" > "$README_PATH"
        elif grep -q "^## Orchestrated Components" "$README_PATH"; then
           awk '
           /^## Orchestrated Components/ {
               print "## Platform Support"
               print ""
               print "<!-- BEGIN_PLATFORMS -->"
               print "<!-- END_PLATFORMS -->"
               print ""
           }
           { print }
           ' "$README_PATH" > "$TEMP_README"
           cat "$TEMP_README" > "$README_PATH"
        else
            printf "\n## Platform Support\n\n<!-- BEGIN_PLATFORMS -->\n<!-- END_PLATFORMS -->\n" >> "$README_PATH"
        fi
        rm -f "$TEMP_README" 2>/dev/null || true
    fi
done
printf '%s\n' "Markers injected."
