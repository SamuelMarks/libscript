#!/bin/sh
# ## Overview
# Deterministic UUIDv5 generator utility for LibScript Windows Installer packaging.
# Generates reproducible GUIDs based on namespace and component name/version.
#
# ## Usage
#   _lib/_common/uuid_gen.sh <NAMESPACE_UUID> <NAME>
#
# ## Parameters
#   NAMESPACE_UUID  Base UUID namespace (e.g. 6ba7b810-9dad-11d1-80b4-00c04fd430c8)
#   NAME            Unique string seed (e.g. "libscript.mysql.8.0.39")

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

if [ $# -ge 2 ]; then
  NAMESPACE="$1"
  SEED_NAME="$2"
elif [ $# -eq 1 ]; then
  NAMESPACE="6ba7b810-9dad-11d1-80b4-00c04fd430c8"
  SEED_NAME="$1"
else
  NAMESPACE=""
  SEED_NAME=""
fi

if [ -z "${NAMESPACE}" ]; then
  NAMESPACE="6ba7b810-9dad-11d1-80b4-00c04fd430c8"
fi

if [ -z "${SEED_NAME}" ]; then
  printf 'Usage: %s [NAMESPACE_UUID] <NAME>
' "$(basename "$0")" >&2
  exit 1
fi

# Prefer Python if available
if command -v python3 >/dev/null 2>&1; then
  python3 -c "import sys, uuid; print(str(uuid.uuid5(uuid.UUID(sys.argv[1]), sys.argv[2])).upper())" "${NAMESPACE}" "${SEED_NAME}"
  exit 0
fi

if command -v python >/dev/null 2>&1; then
  python -c "import sys, uuid; print(str(uuid.uuid5(uuid.UUID(sys.argv[1]), sys.argv[2])).upper())" "${NAMESPACE}" "${SEED_NAME}"
  exit 0
fi

# Prefer PowerShell if available
if command -v pwsh >/dev/null 2>&1; then
  # shellcheck disable=SC2016
  pwsh -NoProfile -Command '$ns = [Guid]::Parse("'"${NAMESPACE}"'"); $bytes = $ns.ToByteArray(); [Array]::Reverse($bytes, 0, 4); [Array]::Reverse($bytes, 4, 2); [Array]::Reverse($bytes, 6, 2); $nameBytes = [System.Text.Encoding]::UTF8.GetBytes("'"${SEED_NAME}"'"); $sha = [System.Security.Cryptography.SHA1]::Create(); $hash = $sha.ComputeHash($bytes + $nameBytes); $hash[6] = ($hash[6] -band 0x0f) -bor 0x50; $hash[8] = ($hash[8] -band 0x3f) -bor 0x80; [Array]::Reverse($hash, 0, 4); [Array]::Reverse($hash, 4, 2); [Array]::Reverse($hash, 6, 2); [Guid]::new($hash[0..15]).ToString().ToUpper()'
  exit 0
fi

# Prefer Node.js if available
if command -v node >/dev/null 2>&1; then
  # shellcheck disable=SC2016
  node -e '
const crypto = require("crypto");
const nsStr = process.argv[1].replace(/-/g, "");
const nsBuf = Buffer.from(nsStr, "hex");
const nameBuf = Buffer.from(process.argv[2], "utf8");
const hash = crypto.createHash("sha1").update(Buffer.concat([nsBuf, nameBuf])).digest();
hash[6] = (hash[6] & 0x0f) | 0x50;
hash[8] = (hash[8] & 0x3f) | 0x80;
const h = hash.subarray(0, 16).toString("hex").toUpperCase();
console.log(`${h.slice(0,8)}-${h.slice(8,12)}-${h.slice(12,16)}-${h.slice(16,20)}-${h.slice(20,32)}`);
' "${NAMESPACE}" "${SEED_NAME}"
  exit 0
fi

printf '[ERROR] No Python, pwsh, or Node.js available to generate UUID.
' >&2
exit 1
