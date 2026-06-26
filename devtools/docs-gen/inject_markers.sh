#!/bin/sh

set -feu
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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
[ -z "${LIBSCRIPT_ROOT_DIR:-}" ] && LIBSCRIPT_ROOT_DIR=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; echo "$d")
for component_dir in "$LIBSCRIPT_ROOT_DIR"/_lib/*/*; do
    if [ ! -d "$component_dir" ]; then
        continue
    fi

    if [ ! -f "$component_dir/README.md" ]; then
        continue
    fi

    README_PATH="$component_dir/README.md"
    
    # Check if markers already exist
    if ! grep -q "<!-- BEGIN_VARS -->" "$README_PATH"; then
        # Replace existing Configuration Options table area with markers
        # If it doesn't exist, we just append it
        if grep -q "## Configuration Options" "$README_PATH"; then
           TEMP_README=$(mktemp)
           awk '
           /## Configuration Options/ {
               print
               print "The following environment variables can be passed to the CLI (\`--KEY=VALUE\`) or exported before running the setup script."
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
           rm -f "$TEMP_README"
        else
           printf "\n## Configuration Options\n\n<!-- BEGIN_VARS -->\n<!-- END_VARS -->\n" >> "$README_PATH"
        fi
    fi

    if ! grep -q "<!-- BEGIN_PLATFORMS -->" "$README_PATH"; then
        if grep -q "## Platform Support" "$README_PATH"; then
           TEMP_README=$(mktemp)
           awk '
           /## Platform Support/ {
               print
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
           rm -f "$TEMP_README"
        else
            printf "\n## Platform Support\n\n<!-- BEGIN_PLATFORMS -->\n<!-- END_PLATFORMS -->\n" >> "$README_PATH"
        fi
    fi

    # Cleanup any accidental duplication of trailing text
    if grep -q "<!-- END_PLATFORMS -->" "$README_PATH"; then
        TEMP_CLEAN=$(mktemp)
        awk '
        { print }
        /<!-- END_PLATFORMS -->/ { exit }
        ' "$README_PATH" > "$TEMP_CLEAN"
        cat "$TEMP_CLEAN" > "$README_PATH"
        rm -f "$TEMP_CLEAN"
    fi
done
echo "Markers injected."
