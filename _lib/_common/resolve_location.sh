#!/bin/sh
# ## Overview
# Translates Windows MSI location variables (e.g., [ProgramFiles64Folder]) into
# robust cross-platform absolute paths for the current target operating system.
#
# ## Usage
#   resolved_path=$(./resolve_location.sh "[ProgramFiles64Folder]LibScript/MySQL")

set -feu

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
export DIR="${SCRIPT_DIR}"

INPUT="${1:-}"

if [ -z "$INPUT" ]; then
    echo "Usage: $0 <path_with_variables>" >&2
    exit 1
fi

INPUT=$(echo "$INPUT" | sed 's/\\/\//g')

OUTPUT="$INPUT"
OUTPUT=$(echo "$OUTPUT" | sed 's/\[ProgramFiles64Folder\]/\/opt\//g')
OUTPUT=$(echo "$OUTPUT" | sed 's/\[ProgramFilesFolder\]/\/opt\//g')
OUTPUT=$(echo "$OUTPUT" | sed 's/\[CommonAppDataFolder\]/\/var\/lib\//g')
OUTPUT=$(echo "$OUTPUT" | sed 's/\[AppDataFolder\]/~\/.local\/share\//g')
OUTPUT=$(echo "$OUTPUT" | sed 's/\[LocalAppDataFolder\]/~\/.local\/share\//g')

OUTPUT=$(echo "$OUTPUT" | sed 's/\/\//\//g')

printf '%s\n' "$OUTPUT"
