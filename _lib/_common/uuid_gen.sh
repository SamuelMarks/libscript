#!/bin/sh
# ## Overview
# Deterministic UUIDv5 generator utility for LibScript Windows Installer packaging.
# Generates reproducible GUIDs based on namespace and component name/version using
# pure POSIX /bin/sh primitives (awk, printf, sha1sum/shasum/openssl).
#
# ## Usage
#   _lib/_common/uuid_gen.sh <NAMESPACE_UUID> <NAME>

set -feu
_uuid_gen_caller_this="${THIS_FILE:-}"; _uuid_gen_caller_dir="${SCRIPT_DIR:-}"

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    [ -n "$_uuid_gen_caller_this" ] && THIS_FILE="$_uuid_gen_caller_this"
    [ -n "$_uuid_gen_caller_dir" ] && SCRIPT_DIR="$_uuid_gen_caller_dir"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

# ## generate_uuid_v5
# Computes a deterministic RFC 4122 UUIDv5 string from a namespace UUID and seed name
# using only POSIX shell utilities and standard SHA-1 digest commands.
generate_uuid_v5() {
  _ns="$1"
  _seed="$2"

  _ns_hex=$(printf '%s' "$_ns" | tr -d '-' | tr '[:upper:]' '[:lower:]')
  if [ "${#_ns_hex}" -ne 32 ]; then
    printf '[ERROR] Invalid namespace UUID: %s\n' "$_ns" >&2
    return 1
  fi

  _octal_ns=$(printf '%s' "$_ns_hex" | awk '{
    bs = sprintf("%c", 92)
    for (i = 1; i <= 32; i += 2) {
      b = substr($0, i, 2)
      hi = index("0123456789abcdef", substr(b, 1, 1)) - 1
      lo = index("0123456789abcdef", substr(b, 2, 1)) - 1
      val = hi * 16 + lo
      printf "%s0%03o", bs, val
    }
  }')

  _sha1_hex=""
  if command -v sha1sum >/dev/null 2>&1; then
    _sha1_hex=$( { printf '%b' "$_octal_ns"; printf '%s' "$_seed"; } | sha1sum | awk '{print tolower($1)}' )
  elif command -v shasum >/dev/null 2>&1; then
    _sha1_hex=$( { printf '%b' "$_octal_ns"; printf '%s' "$_seed"; } | shasum -a 1 | awk '{print tolower($1)}' )
  elif command -v openssl >/dev/null 2>&1; then
    _sha1_hex=$( { printf '%b' "$_octal_ns"; printf '%s' "$_seed"; } | openssl dgst -sha1 | awk '{print tolower($NF)}' )
  else
    printf '[ERROR] No SHA-1 utility (sha1sum, shasum, or openssl) found.\n' >&2
    return 1
  fi

  printf '%s' "$_sha1_hex" | awk '{
    b6_lo = index("0123456789abcdef", substr($0, 14, 1)) - 1
    b6_hex = sprintf("5%x", b6_lo)

    b8_hi = index("0123456789abcdef", substr($0, 17, 1)) - 1
    b8_lo = index("0123456789abcdef", substr($0, 18, 1)) - 1
    b8_new_hi = (b8_hi % 4) + 8
    b8_hex = sprintf("%x%x", b8_new_hi, b8_lo)

    u = substr($0, 1, 8) "-" substr($0, 9, 4) "-" b6_hex substr($0, 15, 2) "-" b8_hex substr($0, 19, 2) "-" substr($0, 21, 12)
    print toupper(u)
  }'
}

if [ $# -ge 2 ]; then
  NAMESPACE="$1"
  SEED_NAME="$2"
elif [ $# -eq 1 ]; then
  NAMESPACE='6ba7b810-9dad-11d1-80b4-00c04fd430c8'
  SEED_NAME="$1"
else
  NAMESPACE=""
  SEED_NAME=""
fi

if [ -z "${NAMESPACE}" ]; then
  NAMESPACE='6ba7b810-9dad-11d1-80b4-00c04fd430c8'
fi

if [ -z "${SEED_NAME}" ]; then
  printf 'Usage: %s [NAMESPACE_UUID] <NAME>\n' "$(basename "$0")" >&2
  exit 1
fi

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_uuid_gen_caller_dir:-}" ] && SCRIPT_DIR="$_uuid_gen_caller_dir"
[ -n "${_uuid_gen_caller_this:-}" ] && THIS_FILE="$_uuid_gen_caller_this"
unset _uuid_gen_caller_this _uuid_gen_caller_dir || true
generate_uuid_v5 "${NAMESPACE}" "${SEED_NAME}"
