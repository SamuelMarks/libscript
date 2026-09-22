#!/bin/sh
# ## Overview
# Hydrates and verifies the offline air-gapped artifact cache for LibScript installers.
# Downloads runtimes (Python, Node.js), datastores (MySQL, Redis, MongoDB, Meilisearch),
# pre-compiled wheels, codebase archives, and demo courseware as defined in an offline
# manifest schema (e.g., stacks/cms/openedx/offline_bundle.json).
#
# ## Usage
# ./packaging/hydrate_offline_cache.sh [OPTIONS]
#
# Options:
#   --manifest <path>      Path to offline_bundle.json manifest (default: stacks/cms/openedx/offline_bundle.json)
#   --cache-dir <dir>      Target directory to stage artifacts (default: cache/)
#   --verify-only          Verify SHA-256 checksums of existing cached artifacts without downloading
#   --wheels               Download Python wheels matching requirements into cache/wheels/
#   --codebase             Download or clone edx-platform codebase archive into cache/codebase/
#   --help, -h             Show this help text

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

# Source core logging
if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh" ]; then
  . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"
else
  log_info() { printf '[INFO]  %s
' "$*"; }
  log_warn() { printf '[WARN]  %s
' "$*" >&2; }
  log_error() { printf '[ERROR] %s
' "$*" >&2; }
fi

MANIFEST_PATH="${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx/offline_bundle.json"
CACHE_DIR="${LIBSCRIPT_CACHE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache}"
VERIFY_ONLY=0
HYDRATE_WHEELS=0
HYDRATE_CODEBASE=0

# Option Parsing Loop
while [ $# -gt 0 ]; do
  case "$1" in
    --manifest)
      MANIFEST_PATH="$2"
      shift 2
      ;;
    --manifest=*)
      MANIFEST_PATH="${1#*=}"
      shift
      ;;
    --cache-dir)
      CACHE_DIR="$2"
      shift 2
      ;;
    --cache-dir=*)
      CACHE_DIR="${1#*=}"
      shift
      ;;
    --verify-only)
      VERIFY_ONLY=1
      shift
      ;;
    --wheels)
      HYDRATE_WHEELS=1
      shift
      ;;
    --codebase)
      HYDRATE_CODEBASE=1
      shift
      ;;
    --help|-h)
      printf 'Usage: %s [OPTIONS]
' "$0"
      printf 'Options:
'
      printf '  --manifest <path>    Path to offline_bundle.json manifest
'
      printf '  --cache-dir <dir>    Target cache staging directory
'
      printf '  --verify-only        Validate SHA-256 hashes of cached files without downloading
'
      printf '  --wheels             Trigger pip download for wheels
'
      printf '  --codebase           Fetch codebase archives
'
      printf '  --help, -h           Show this help text
'
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [ ! -f "$MANIFEST_PATH" ]; then
  log_error "Manifest file not found at: ${MANIFEST_PATH}"
  exit 1
fi

mkdir -p "${CACHE_DIR}/runtimes" "${CACHE_DIR}/databases" "${CACHE_DIR}/wheels" "${CACHE_DIR}/npm" "${CACHE_DIR}/codebase"

# ## compute_sha256
# Computes the 64-character lowercase SHA-256 checksum of a file.
compute_sha256() {
  _file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$_file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$_file" | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "$_file" | awk '{print $NF}'
  else
    log_error "No SHA-256 utility available (sha256sum, shasum, openssl)."
    return 1
  fi
}

# ## process_artifact
# Idempotently checks or downloads an artifact and validates its SHA-256 digest.
process_artifact() {
  _url="$1"
  _dest="$2"
  _expected_hash="$3"
  _category="$4"

  _dest_dir=$(dirname "$_dest")
  mkdir -p "$_dest_dir"

  if [ -f "$_dest" ]; then
    _actual_hash=$(compute_sha256 "$_dest")
    if [ "$_actual_hash" = "$_expected_hash" ]; then
      log_info "[VALID] [${_category}] $(basename "$_dest") matches SHA-256"
      return 0
    else
      log_warn "[CORRUPT] [${_category}] $(basename "$_dest") hash mismatch! Expected: ${_expected_hash}, Got: ${_actual_hash}"
      if [ "$VERIFY_ONLY" -eq 1 ]; then
        return 1
      fi
      rm -f "$_dest"
    fi
  fi

  if [ "$VERIFY_ONLY" -eq 1 ]; then
    log_error "[MISSING] [${_category}] $(basename "$_dest") is absent from cache."
    return 1
  fi

  log_info "[FETCHING] [${_category}] $(basename "$_dest") from ${_url}..."
  if command -v curl >/dev/null 2>&1; then
    if ! curl -fL -C - "$_url" -o "$_dest" 2>/dev/null; then
      # If resume (-C -) is unsupported by remote server, perform standard fetch
      curl -fL "$_url" -o "$_dest" || return 1
    fi
  elif command -v wget >/dev/null 2>&1; then
    wget -c "$_url" -O "$_dest" || return 1
  else
    log_error "curl or wget required for downloading."
    return 1
  fi

  _actual_hash=$(compute_sha256 "$_dest")
  if [ "$_actual_hash" != "$_expected_hash" ]; then
    log_error "[FAIL] Checksum mismatch on newly downloaded $(basename "$_dest")"
    rm -f "$_dest"
    return 1
  fi
  log_info "[STORED] [${_category}] $(basename "$_dest") verified and cached."
  return 0
}

log_info "Processing offline bundle manifest: ${MANIFEST_PATH}"
log_info "Target cache directory: ${CACHE_DIR}"

TOTAL_ERRORS=0

# 1. Runtimes
if command -v jq >/dev/null 2>&1; then
  _runtime_keys=$(jq -r '.runtimes | keys[]' "$MANIFEST_PATH" 2>/dev/null || true)
  for key in $_runtime_keys; do
    _fn=$(jq -r --arg k "$key" '.runtimes[$k].filename' "$MANIFEST_PATH")
    _url=$(jq -r --arg k "$key" '.runtimes[$k].url' "$MANIFEST_PATH")
    _hash=$(jq -r --arg k "$key" '.runtimes[$k].sha256' "$MANIFEST_PATH")
    process_artifact "$_url" "${CACHE_DIR}/runtimes/${_fn}" "$_hash" "Runtime" || TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
  done

  # 2. Databases
  _db_keys=$(jq -r '.databases | keys[]' "$MANIFEST_PATH" 2>/dev/null || true)
  for key in $_db_keys; do
    _fn=$(jq -r --arg k "$key" '.databases[$k].filename' "$MANIFEST_PATH")
    _url=$(jq -r --arg k "$key" '.databases[$k].url' "$MANIFEST_PATH")
    _hash=$(jq -r --arg k "$key" '.databases[$k].sha256' "$MANIFEST_PATH")
    process_artifact "$_url" "${CACHE_DIR}/databases/${_fn}" "$_hash" "Database" || TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
  done

  # 3. Pre-declared Wheels
  _wheel_count=$(jq -r '.wheels.packages | length' "$MANIFEST_PATH" 2>/dev/null || printf '0')
  _idx=0
  while [ "$_idx" -lt "$_wheel_count" ]; do
    _fn=$(jq -r ".wheels.packages[$_idx].filename" "$MANIFEST_PATH")
    _url=$(jq -r ".wheels.packages[$_idx].url" "$MANIFEST_PATH")
    _hash=$(jq -r ".wheels.packages[$_idx].sha256" "$MANIFEST_PATH")
    process_artifact "$_url" "${CACHE_DIR}/wheels/${_fn}" "$_hash" "Wheel" || TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
    _idx=$((_idx + 1))
  done

  # 4. Codebase
  _code_fn=$(jq -r '.codebase.archive_filename' "$MANIFEST_PATH" 2>/dev/null || true)
  if [ -n "$_code_fn" ] && [ "$_code_fn" != "null" ]; then
    _code_url=$(jq -r '.codebase.archive_url' "$MANIFEST_PATH")
    _code_hash=$(jq -r '.codebase.archive_sha256' "$MANIFEST_PATH")
    process_artifact "$_code_url" "${CACHE_DIR}/codebase/${_code_fn}" "$_code_hash" "Codebase" || TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
  fi

  # Demo Content
  _demo_count=$(jq -r '.codebase.demo_content | length' "$MANIFEST_PATH" 2>/dev/null || printf '0')
  _didx=0
  while [ "$_didx" -lt "$_demo_count" ]; do
    _dfn=$(jq -r ".codebase.demo_content[$_didx].filename" "$MANIFEST_PATH")
    _durl=$(jq -r ".codebase.demo_content[$_didx].url" "$MANIFEST_PATH")
    _dhash=$(jq -r ".codebase.demo_content[$_didx].sha256" "$MANIFEST_PATH")
    process_artifact "$_durl" "${CACHE_DIR}/codebase/${_dfn}" "$_dhash" "DemoContent" || TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
    _didx=$((_didx + 1))
  done
fi

# Synchronize manifest and checksums file into cache root
cp -f "$MANIFEST_PATH" "${CACHE_DIR}/manifest.json"

_hash_file="${CACHE_DIR}/checksums.sha256"
: > "$_hash_file"
for _f in "${CACHE_DIR}/runtimes"/* "${CACHE_DIR}/databases"/* "${CACHE_DIR}/wheels"/* "${CACHE_DIR}/codebase"/*; do
  if [ -f "$_f" ]; then
    _h=$(compute_sha256 "$_f" || true)
    if [ -n "$_h" ]; then
      printf '%s  %s
' "$_h" "$(basename "$_f")" >> "$_hash_file"
    fi
  fi
done

if [ "$TOTAL_ERRORS" -gt 0 ]; then
  log_error "Offline cache hydration completed with ${TOTAL_ERRORS} failure(s)."
  exit 1
fi

log_info "Offline cache hydrated and verified successfully at ${CACHE_DIR}"
exit 0
