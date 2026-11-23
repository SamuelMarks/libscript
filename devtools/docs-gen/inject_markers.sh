#!/bin/sh
# ## Overview
# Injects specific markers or tags into documentation files.
# ## Usage
# Execute this script to apply structural markers to docs.
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
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2; fi
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/parallel.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

if [ "${1:-}" = '--help' ] || [ "${1:-}" = '-h' ] || [ "${1:-}" = '/?' ] || [ "${1:-}" = '-?' ]; then
  printf '%s\n' "Usage: $(basename "$THIS_FILE")"
  printf '%s\n' 'Injects specific markers or tags into documentation files.'
  printf '\n'
  printf '%s\n' 'Options:'
  printf '%s\n' '  --help, -h, /?, -?  Show this help message.'
  exit 0
fi

: "${ROOT_DIR:=${LIBSCRIPT_ROOT_DIR}}"
IM_WORK=$(libscript_make_tmpdir 'markers')
trap 'rm -rf "$IM_WORK"' EXIT INT TERM

# shellcheck disable=SC2329
# ## inject_one_readme
# Ensures BEGIN_VARS and BEGIN_PLATFORMS markers exist in a single README.md file.
inject_one_readme() {
  README_PATH="$1"
  [ -f "$README_PATH" ] || return 0
  if grep -q '<!-- BEGIN_VARS -->' "$README_PATH" && grep -q '<!-- BEGIN_PLATFORMS -->' "$README_PATH"; then
    return 0
  fi

  TEMP_README="${README_PATH}.inj.$$.tmp"
  if ! grep -q '<!-- BEGIN_VARS -->' "$README_PATH"; then
    if grep -qE '^## (Configuration Options|Variables|Environment Variables)' "$README_PATH"; then
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
        /^## / && in_config { in_config = 0; print; next }
        !in_config { print }
      ' "$README_PATH" > "$TEMP_README"
      mv -f "$TEMP_README" "$README_PATH"
    elif grep -q '^## Platform Support' "$README_PATH"; then
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
      mv -f "$TEMP_README" "$README_PATH"
    else
      # shellcheck disable=SC2016
      printf '\n## Configuration Options\n\nThe following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.\n\n<!-- BEGIN_VARS -->\n<!-- END_VARS -->\n' >> "$README_PATH"
    fi
  fi

  if ! grep -q '<!-- BEGIN_PLATFORMS -->' "$README_PATH"; then
    if grep -q '^## Platform Support' "$README_PATH"; then
      awk '
        /^## Platform Support/ {
          print
          print ""
          print "<!-- BEGIN_PLATFORMS -->"
          print "<!-- END_PLATFORMS -->"
          in_plat = 1
          next
        }
        /^## / && in_plat { in_plat = 0; print; next }
        !in_plat { print }
      ' "$README_PATH" > "$TEMP_README"
      mv -f "$TEMP_README" "$README_PATH"
    else
      printf '\n## Platform Support\n\n<!-- BEGIN_PLATFORMS -->\n<!-- END_PLATFORMS -->\n' >> "$README_PATH"
    fi
  fi
  rm -f "$TEMP_README" 2>/dev/null || true
}

READMES_LIST="${IM_WORK}/READMES.TXT"
: > "$READMES_LIST"
set +f
for component_dir in "$ROOT_DIR"/_lib/*/* "$ROOT_DIR"/_lib/*/*/* "$ROOT_DIR"/topologies/* "$ROOT_DIR"/payloads/*/*; do
  if [ -d "$component_dir" ] && [ -f "$component_dir/README.md" ]; then
    printf '%s\n' "$component_dir/README.md" >> "$READMES_LIST"
  fi
done
set -f

if [ -s "$READMES_LIST" ]; then
  libscript_parallel_map "$READMES_LIST" inject_one_readme
fi
