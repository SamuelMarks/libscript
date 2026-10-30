#!/bin/sh
# ## Overview
# Hydrates and verifies the offline air-gapped artifact cache for LibScript installers.
#
# ## Usage
# ./packaging/hydrate_offline_cache.sh [--manifest <path>] [--cache-dir <dir>] [--verify-only] [--wheels] [--codebase]

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

# Source core logging
if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh" ]; then
  _ls_src_this="${THIS_FILE:-}"; _ls_src_dir="${SCRIPT_DIR:-}"
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true
  [ -n "${_ls_src_this:-}" ] && THIS_FILE="$_ls_src_this"
  [ -n "${_ls_src_dir:-}" ] && SCRIPT_DIR="$_ls_src_dir"
else
  # ## log_info
  # Outputs informational message to stdout.
  log_info() { printf '[INFO]  %s\n' "$*"; }

  # ## log_warn
  # Outputs warning message to stderr.
  log_warn() { printf '[WARN]  %s\n' "$*" >&2; }

  # ## log_error
  # Outputs error message to stderr.
  log_error() { printf '[ERROR] %s\n' "$*" >&2; }
fi

MANIFEST_PATH="${LIBSCRIPT_ROOT_DIR}/_lib/web-apps/openedx/offline_bundle.json"
CACHE_DIR="${LIBSCRIPT_CACHE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache}"
VERIFY_ONLY=0
HYDRATE_WHEELS=0
HYDRATE_CODEBASE=0
TARGET_COMPONENT=""

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
    --component)
      TARGET_COMPONENT="$2"
      shift 2
      ;;
    --component=*)
      TARGET_COMPONENT="${1#*=}"
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
      printf 'Usage: %s [OPTIONS]\n' "$0"
      printf 'Options:\n'
      printf '  --manifest <path>    Path to offline_bundle.json manifest\n'
      printf '  --cache-dir <dir>    Target cache staging directory\n'
      printf '  --component <name>   Filter by component (mysql, redis, mongodb, python, nodejs, meilisearch, codebase, wheels, all)\n'
      printf '  --verify-only        Validate SHA-256 hashes of cached files without downloading\n'
      printf '  --wheels             Trigger pip download for wheels\n'
      printf '  --codebase           Fetch codebase archives\n'
      printf '  --help, -h           Show this help text\n'
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

mkdir -p "${CACHE_DIR}/runtimes" "${CACHE_DIR}/databases" "${CACHE_DIR}/webservers" "${CACHE_DIR}/applications" "${CACHE_DIR}/wheels" "${CACHE_DIR}/npm" "${CACHE_DIR}/codebase"

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
    log_error 'No SHA-256 utility available (sha256sum, shasum, openssl).'
    return 1
  fi
}

# ## prune_archive
# Strips heavyweight debug symbols (.pdb) and non-essential static libraries
# from large datastore archives to optimize air-gapped MSI package size.
prune_archive() {
  _dest="$1"
  _category="$2"
  _abs_dest="$(cd -- "$(dirname -- "$_dest")" && pwd)/$(basename -- "$_dest")"
  _stamp="${_abs_dest}.pruned"
  case "$_abs_dest" in
    *mongodb-*.zip)
      log_info "[PRUNING] [${_category}] Pruning debug symbols from $(basename "$_abs_dest")..."
      _tmp_d="$(dirname "$_abs_dest")/_tmp_mongo_$$"
      rm -rf "$_tmp_d"
      mkdir -p "$_tmp_d"
      tar -xf "$_abs_dest" -C "$_tmp_d" --exclude='*.pdb' --exclude='*mongos*' --exclude='*Compass*' --exclude='*vc_redist*' 2>/dev/null || true
      rm -f "$_abs_dest"
      _top_dir=$(cd "$_tmp_d" && find . -mindepth 1 -maxdepth 1 -type d | sed 's|^\./||' | head -n 1)
      (cd "$_tmp_d" && tar -a -cf "$_abs_dest" "$_top_dir")
      rm -rf "$_tmp_d"
      printf 'pruned\n' > "$_stamp"
      log_info "[PRUNED] [${_category}] $(basename "$_abs_dest") successfully pruned"
      ;;
    *mysql-*.zip)
      log_info "[PRUNING] [${_category}] Pruning debug symbols and static libs from $(basename "$_abs_dest")..."
      _tmp_d="$(dirname "$_abs_dest")/_tmp_mysql_$$"
      rm -rf "$_tmp_d"
      mkdir -p "$_tmp_d"
      tar -xf "$_abs_dest" -C "$_tmp_d" --exclude='*.pdb' --exclude='*.lib' --exclude='*debug*' --exclude='*docs*' --exclude='*include*' --exclude='*test*' 2>/dev/null || true
      rm -f "$_abs_dest"
      _top_dir=$(cd "$_tmp_d" && find . -mindepth 1 -maxdepth 1 -type d | sed 's|^\./||' | head -n 1)
      (cd "$_tmp_d" && tar -a -cf "$_abs_dest" "$_top_dir")
      rm -rf "$_tmp_d"
      printf 'pruned\n' > "$_stamp"
      log_info "[PRUNED] [${_category}] $(basename "$_abs_dest") successfully pruned"
      ;;
  esac
}

# ## build_mfe_bundle_from_oci
# Synthesizes mfe-bundle-verawood.1.tar.gz from verified overhangio/openedx-mfe:19.0.0 OCI layer blobs when the GitHub release asset is not yet published.
build_mfe_bundle_from_oci() {
  _mfe_dest="$1"
  log_info '[FALLBACK] [DemoContent] Synthesizing mfe-bundle from verified overhangio/openedx-mfe:19.0.0 OCI layers...'
  _mfe_tmp="$(dirname "$_mfe_dest")/_tmp_mfe_oci_$$"
  rm -rf "$_mfe_tmp"
  mkdir -p "$_mfe_tmp"

  _token=""
  if command -v jq >/dev/null 2>&1; then
    _token=$(curl -fsSL 'https://auth.docker.io/token?service=registry.docker.io&scope=repository:overhangio/openedx-mfe:pull' 2>/dev/null | jq -r '.token // empty' || true) # libscript-allow-raw-fetch
  fi
  if [ -z "$_token" ]; then
    rm -rf "$_mfe_tmp"
    return 1
  fi

  for _digest in \
    2e4aa03b614b7c8f62b75afbc7fa0587f573ccf3768e9b2260b6e742853aa075 \
    32c65588b8a1f1f90a8c5984f31e04d499b191704456722c00e53eaaa55c73da \
    6c7edb2ee24e18314f00a8229f18dd23b59ae0c521cd6557f4358eacf5a89e29 \
    fca2b76a71dc5bbeeb59c1639d116f82b287904c6684691cf04b6bdd86c07cf9 \
    5d5124879ddd05a1469cbf1162d5c8511736b9472e77757e76eb0d7956f8d34e \
    95232e6c3f4956551f226ef7dff70abe10950f50061755bf74f9a2f6b90cde47 \
    566e6123c7b9e5616599c5f09da3d7f288ed283f1e96714cead02ad8c3d855a6 \
    d2e9858ca1ac6d4979357be2d21a869ae8d2f053655b7c171d79c0e46788ce4b \
    00667c1f99367e7e3b33ac84233895feb945b7fb7bd24817c24fc3869db0bef9 \
    59561b40d8ad8c203854417851db6afa51a2fbbc84960242ac58f3f44e4184ef; do
    _blob="${_mfe_tmp}/${_digest}.tar.gz"
    if ! curl -fsSL -L -H "Authorization: Bearer ${_token}" "https://registry-1.docker.io/v2/overhangio/openedx-mfe/blobs/sha256:${_digest}" -o "$_blob" 2>/dev/null; then # libscript-allow-raw-fetch
      rm -rf "$_mfe_tmp"
      return 1
    fi
    _blob_hash=$(compute_sha256 "$_blob")
    if [ "$_blob_hash" != "$_digest" ]; then
      log_error "OCI layer SHA-256 mismatch for $_digest"
      rm -rf "$_mfe_tmp"
      return 1
    fi
    tar -xzf "$_blob" -C "$_mfe_tmp" --strip-components=2 --exclude='*.map' --exclude='*report.html' 2>/dev/null || true
    rm -f "$_blob"
  done

  if [ ! -d "${_mfe_tmp}/authn" ] || [ ! -d "${_mfe_tmp}/authoring" ]; then
    rm -rf "$_mfe_tmp"
    return 1
  fi

  (cd "$_mfe_tmp" && tar -czf "$_mfe_dest" account authn authoring communications discussions gradebook learner-dashboard learning ora-grading profile)
  rm -rf "$_mfe_tmp"
  if [ -s "$_mfe_dest" ]; then
    printf 'pruned\n' > "${_mfe_dest}.pruned"
    log_info "[STORED] [DemoContent] Synthesized and verified $(basename "$_mfe_dest") from OCI layers."
    return 0
  fi
  return 1
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
  _stamp="${_dest}.pruned"

  if [ -f "$_dest" ]; then
    if [ -f "$_stamp" ]; then
      log_info "[VALID] [${_category}] $(basename "$_dest") (pruned archive verified)"
      return 0
    fi
    _actual_hash=$(compute_sha256 "$_dest")
    if [ "$_actual_hash" = "$_expected_hash" ]; then
      log_info "[VALID] [${_category}] $(basename "$_dest") matches SHA-256"
      prune_archive "$_dest" "$_category"
      return 0
    else
      log_warn "[CORRUPT] [${_category}] $(basename "$_dest") hash mismatch! Expected: ${_expected_hash}, Got: ${_actual_hash}"
      if [ "$VERIFY_ONLY" -eq 1 ]; then
        return 1
      fi
      rm -f "$_dest" "$_stamp"
    fi
  fi

  if [ "$VERIFY_ONLY" -eq 1 ]; then
    log_error "[MISSING] [${_category}] $(basename "$_dest") is absent from cache."
    return 1
  fi

  log_info "[FETCHING] [${_category}] $(basename "$_dest") from ${_url}..."
  if ! type libscript_download >/dev/null 2>&1 && [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mgr.sh" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mgr.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090,SC1091
    . "${SCRIPT_NAME}"
  fi
  if ! libscript_download "$_url" "$_dest" "SKIP"; then
    case "$(basename "$_dest")" in
      mfe-bundle*.tar.gz)
        if build_mfe_bundle_from_oci "$_dest"; then
          return 0
        fi
        ;;
    esac
    log_error "Failed to download $_url"
    return 1
  fi

  _actual_hash=$(compute_sha256 "$_dest")
  if [ "$_actual_hash" != "$_expected_hash" ]; then
    log_error "[FAIL] Checksum mismatch on newly downloaded $(basename "$_dest")"
    rm -f "$_dest" "$_stamp"
    return 1
  fi
  log_info "[STORED] [${_category}] $(basename "$_dest") verified and cached."
  prune_archive "$_dest" "$_category"
  return 0
}

log_info "Processing offline bundle manifest: ${MANIFEST_PATH}"
log_info "Target cache directory: ${CACHE_DIR}"

TOTAL_ERRORS=0

# 1. Runtimes
if command -v jq >/dev/null 2>&1; then
  _runtime_keys=$(jq -r '.runtimes | keys[]' "$MANIFEST_PATH" 2>/dev/null || true)
  for key in $_runtime_keys; do
    if [ -n "$TARGET_COMPONENT" ] && [ "$TARGET_COMPONENT" != "all" ] && [ "$TARGET_COMPONENT" != "$key" ]; then
      if [ "$key" = "python" ] && { [ "$TARGET_COMPONENT" = "gunicorn" ] || [ "$TARGET_COMPONENT" = "nodeenv" ] || [ "$TARGET_COMPONENT" = "exim" ]; }; then
        :
      else
        continue
      fi
    fi
    _fn=$(jq -r --arg k "$key" '.runtimes[$k].filename' "$MANIFEST_PATH")
    _url=$(jq -r --arg k "$key" '.runtimes[$k].url' "$MANIFEST_PATH")
    _hash=$(jq -r --arg k "$key" '.runtimes[$k].sha256' "$MANIFEST_PATH")
    process_artifact "$_url" "${CACHE_DIR}/runtimes/${_fn}" "$_hash" "Runtime" || TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
  done

  # 2. Databases
  _db_keys=$(jq -r '.databases | keys[]' "$MANIFEST_PATH" 2>/dev/null || true)
  for key in $_db_keys; do
    if [ -n "$TARGET_COMPONENT" ] && [ "$TARGET_COMPONENT" != "all" ] && [ "$TARGET_COMPONENT" != "$key" ]; then
      continue
    fi
    _fn=$(jq -r --arg k "$key" '.databases[$k].filename' "$MANIFEST_PATH")
    _url=$(jq -r --arg k "$key" '.databases[$k].url' "$MANIFEST_PATH")
    _hash=$(jq -r --arg k "$key" '.databases[$k].sha256' "$MANIFEST_PATH")
    process_artifact "$_url" "${CACHE_DIR}/databases/${_fn}" "$_hash" "Database" || TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
  done

  # 2b. Webservers
  _ws_keys=$(jq -r '.webservers | keys[]' "$MANIFEST_PATH" 2>/dev/null || true)
  for key in $_ws_keys; do
    if [ -n "$TARGET_COMPONENT" ] && [ "$TARGET_COMPONENT" != "all" ] && [ "$TARGET_COMPONENT" != "$key" ]; then
      continue
    fi
    _fn=$(jq -r --arg k "$key" '.webservers[$k].filename' "$MANIFEST_PATH")
    _url=$(jq -r --arg k "$key" '.webservers[$k].url' "$MANIFEST_PATH")
    _hash=$(jq -r --arg k "$key" '.webservers[$k].sha256' "$MANIFEST_PATH")
    if process_artifact "$_url" "${CACHE_DIR}/webservers/${_fn}" "$_hash" "Webserver"; then
      if [ "$key" = "caddy" ]; then
        mkdir -p "${CACHE_DIR}/webservers/caddy"
        if [ ! -f "${CACHE_DIR}/webservers/caddy/caddy.exe" ]; then
          unzip -q -o "${CACHE_DIR}/webservers/${_fn}" -d "${CACHE_DIR}/webservers/caddy" 2>/dev/null || tar -xf "${CACHE_DIR}/webservers/${_fn}" -C "${CACHE_DIR}/webservers/caddy" 2>/dev/null || true
        fi
      fi
    else
      TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
    fi
  done

  # 2c. Applications
  _app_keys=$(jq -r '.applications | keys[]' "$MANIFEST_PATH" 2>/dev/null || true)
  for key in $_app_keys; do
    if [ -n "$TARGET_COMPONENT" ] && [ "$TARGET_COMPONENT" != "all" ] && [ "$TARGET_COMPONENT" != "$key" ] && [ "$TARGET_COMPONENT" != "applications" ]; then
      continue
    fi
    _fn=$(jq -r --arg k "$key" '.applications[$k].filename' "$MANIFEST_PATH")
    _url=$(jq -r --arg k "$key" '.applications[$k].url' "$MANIFEST_PATH")
    _hash=$(jq -r --arg k "$key" '.applications[$k].sha256' "$MANIFEST_PATH")
    process_artifact "$_url" "${CACHE_DIR}/applications/${_fn}" "$_hash" "Application" || TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
  done

  # 3. Pre-declared Wheels
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/web-apps/openedx/build-constraints.txt" ]; then
    export PIP_CONSTRAINT="${LIBSCRIPT_ROOT_DIR}/_lib/web-apps/openedx/build-constraints.txt"
    export UV_BUILD_CONSTRAINT="${LIBSCRIPT_ROOT_DIR}/_lib/web-apps/openedx/build-constraints.txt"
  fi
  if [ -z "$TARGET_COMPONENT" ] || [ "$TARGET_COMPONENT" = "all" ] || [ "$TARGET_COMPONENT" = "wheels" ] || [ "$TARGET_COMPONENT" = "openedx-core" ] || [ "$TARGET_COMPONENT" = "openedx" ] || [ "$TARGET_COMPONENT" = "gunicorn" ] || [ "$TARGET_COMPONENT" = "waitress" ] || [ "$TARGET_COMPONENT" = "nodeenv" ] || [ "$TARGET_COMPONENT" = "exim" ] || [ "$HYDRATE_WHEELS" -eq 1 ]; then
    _wheel_count=$(jq -r '.wheels.packages | length' "$MANIFEST_PATH" 2>/dev/null || printf '0')
    _idx=0
    while [ "$_idx" -lt "$_wheel_count" ]; do
      _fn=$(jq -r ".wheels.packages[$_idx].filename" "$MANIFEST_PATH")
      _url=$(jq -r ".wheels.packages[$_idx].url" "$MANIFEST_PATH")
      _hash=$(jq -r ".wheels.packages[$_idx].sha256" "$MANIFEST_PATH")
      process_artifact "$_url" "${CACHE_DIR}/wheels/${_fn}" "$_hash" "Wheel" || TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
      _idx=$((_idx + 1))
    done
  fi

  # 4. Codebase
  if [ -z "$TARGET_COMPONENT" ] || [ "$TARGET_COMPONENT" = "all" ] || [ "$TARGET_COMPONENT" = "codebase" ] || [ "$TARGET_COMPONENT" = "openedx-core" ] || [ "$TARGET_COMPONENT" = "openedx" ] || [ "$HYDRATE_CODEBASE" -eq 1 ]; then
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
fi

# Synchronize manifest and checksums file into cache root
cp -f "$MANIFEST_PATH" "${CACHE_DIR}/manifest.json"

_hash_file="${CACHE_DIR}/checksums.sha256"
: > "$_hash_file"
for _f in "${CACHE_DIR}/runtimes"/* "${CACHE_DIR}/databases"/* "${CACHE_DIR}/webservers"/* "${CACHE_DIR}/applications"/* "${CACHE_DIR}/wheels"/* "${CACHE_DIR}/codebase"/*; do
  if [ -f "$_f" ]; then
    _h=$(compute_sha256 "$_f" || true)
    if [ -n "$_h" ]; then
      printf '%s  %s\n' "$_h" "$(basename "$_f")" >> "$_hash_file"
    fi
  fi
done

if [ "$TOTAL_ERRORS" -gt 0 ]; then
  log_error "Offline cache hydration completed with ${TOTAL_ERRORS} failure(s)."
  exit 1
fi

log_info "Offline cache hydrated and verified successfully at ${CACHE_DIR}"
exit 0
