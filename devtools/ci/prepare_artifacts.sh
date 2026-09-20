#!/bin/sh
# ## Overview
# Validates generated installer artifact packages and produces cryptographic
# SHA256 checksums (.sha256) for release distribution.
#
# ## Usage
# ./devtools/ci/prepare_artifacts.sh <artifact_path> [artifact_path...]

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
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"

# ## show_help
# Displays usage instructions and available parameters.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") <artifact_path> [artifact_path...]"
  printf '%s
' "Validates artifact files and produces companion .sha256 checksum files."
  printf '
'
  printf '%s
' "Options:"
  printf '%s
' "  --help, -h, /?, -?  Show this help message."
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  show_help
  exit 0
fi

if [ $# -lt 1 ]; then
  printf '[ERROR] No artifact paths specified.
' >&2
  show_help >&2
  exit 1
fi

# ## compute_sha256
# Computes the SHA256 cryptographic hash of a file using available system tools.
compute_sha256() {
  _target="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$_target" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$_target" | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "$_target" | awk '{print $NF}'
  else
    printf '[ERROR] No SHA256 utility found (sha256sum, shasum, openssl)
' >&2
    return 1
  fi
}

# ## prepare_single_artifact
# Verifies target artifact file exists and generates companion .sha256 checksum file.
prepare_single_artifact() {
  _file="$1"
  if [ ! -f "$_file" ]; then
    printf '[ERROR] Artifact not found: %s
' "$_file" >&2
    return 1
  fi

  _size=$(wc -c < "$_file" 2>/dev/null | tr -d ' ' || printf '0')
  if [ "$_size" = "0" ]; then
    printf '[ERROR] Artifact file is empty: %s
' "$_file" >&2
    return 1
  fi

  _base=$(basename "$_file")
  _hash=$(compute_sha256 "$_file")
  _sha_file="${_file}.sha256"

  printf '%s  %s
' "$_hash" "$_base" > "$_sha_file"
  printf '[INFO] Successfully prepared: %s (%s bytes, SHA256: %s)
' "$_file" "$_size" "$_hash"
}

for artifact in "$@"; do
  prepare_single_artifact "$artifact"
done

exit 0
