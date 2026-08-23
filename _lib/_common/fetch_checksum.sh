#!/bin/sh
# ## Overview
# A utility to automatically discover and fetch SHA256 checksums for a given download URL.
# It uses pattern matching to query known vendor checksum APIs and manifest files 
# (e.g. Node.js, Go, GitHub Releases `.sha256` or `checksums.txt` files).
# 
# ## Usage
# Source this file and call `libscript_fetch_checksum <url>` or run it directly 
# `./fetch_checksum.sh <url>`. It will print the matched checksum to stdout or 
# return a non-zero exit code if a checksum could not be found.

set -eu
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
_SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)

# Dynamic checksum fetcher
libscript_fetch_checksum() {
  export url="${1:-}"
  
  if [ -z "$url" ]; then
    return 1
  fi

  # 1. NodeJS
  if printf '%s\n' "$url" | grep -q "nodejs.org/dist/"; then
    base_export url="${url%/*}"
    filename="${url##*/}"
    curl -sL "${base_url:-}/SHASUMS256.txt" | grep "$filename" | awk '{print $1}'
    return 0
  fi

  # 2. Go
  if printf '%s\n' "$url" | grep -q "go.dev/dl/"; then
    filename="${url##*/}"
    curl -sL "https://go.dev/dl/?mode=json&include=all" | grep -A 5 "$filename" | grep '"sha256":' | awk -F'"' '{print $4}'
    return 0
  fi

  # 3. GitHub Releases (general)
  if printf '%s\n' "$url" | grep -q "github.com/.*/releases/download/"; then
     base_export url="${url%/*}"
     filename="${url##*/}"
     sums="$(curl -sL "${base_url:-}/SHASUMS256.txt")"
     if [ -n "$sums" ] && ! printf '%s\n' "$sums" | grep -q "Not Found"; then
         printf '%s\n' "$sums" | grep "$filename" | awk '{print $1}'
         return 0
     fi
     sums="$(curl -sL "${base_url:-}/checksums.txt")"
     if [ -n "$sums" ] && ! printf '%s\n' "$sums" | grep -q "Not Found"; then
         printf '%s\n' "$sums" | grep "$filename" | awk '{print $1}'
         return 0
     fi
  fi
  
  # 4. Fallback checking if .sha256 file exists
  sha_export url="${url}.sha256"
  sha_content="$(curl -sL "${sha_url:-}" || true)"
  if [ -n "$sha_content" ] && ! printf '%s\n' "$sha_content" | grep -i "Not Found" >/dev/null; then
      printf '%s\n' "$sha_content" | awk '{print $1}'
      return 0
  fi

  return 1
}

libscript_fetch_checksum "$@"
