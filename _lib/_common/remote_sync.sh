#!/bin/sh
# ## Overview
# Unified gitignore-aware, build-cache-preserving remote synchronization, SSH multiplexing, and VM IP TTL caching utilities.
# ## Usage
# Source (`. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/remote_sync.sh"`) or invoke: `./_lib/_common/remote_sync.sh [sync-app|sync-runtime|ssh-opts|compute-hash] ...`

set -feu
_rs_caller_this="${THIS_FILE:-}"; _rs_caller_dir="${SCRIPT_DIR:-}"
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
    [ -n "$_rs_caller_this" ] && THIS_FILE="$_rs_caller_this"
    [ -n "$_rs_caller_dir" ] && SCRIPT_DIR="$_rs_caller_dir"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

# ## libscript_ssh_mux_opts
# Prints OpenSSH connection and ControlMaster multiplexing options for fast reused SSH channels.
libscript_ssh_mux_opts() {
  _smo_base='-o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30'
  if [ "${LIBSCRIPT_DISABLE_SSH_MUX:-0}" = "1" ]; then
    printf '%s\n' "$_smo_base"
    return 0
  fi
  _smo_tmp="${TMPDIR:-/tmp}"
  _smo_tmp="${_smo_tmp%/}"
  if [ -n "${LIBSCRIPT_SSH_MUX_DIR:-}" ]; then
    _smo_dir="${LIBSCRIPT_SSH_MUX_DIR}"
  elif [ "${#_smo_tmp}" -gt 36 ]; then
    _smo_uid=$(id -u 2>/dev/null || printf '0')
    _smo_short_tmp="${LIBSCRIPT_SHORT_TMPDIR:-/tmp}"
    _smo_dir="${_smo_short_tmp%/}/ls_mux_${_smo_uid}"
  else
    _smo_dir="${_smo_tmp}/ls_mux"
  fi
  _smo_dir="${_smo_dir%/}"
  mkdir -p "$_smo_dir" 2>/dev/null || true
  chmod 0700 "$_smo_dir" 2>/dev/null || true
  if [ -d "$_smo_dir" ] && [ -w "$_smo_dir" ]; then
    printf '%s -o ControlMaster=auto -o ControlPersist=60s -o ControlPath=%s/%%C\n' "$_smo_base" "$_smo_dir"
  else
    printf '%s\n' "$_smo_base"
  fi
}

# ## libscript_get_cached_vm_ip
# Reads a cached public IP address for a cloud VM if the TTL cache file is fresh (default 300s).
libscript_get_cached_vm_ip() {
  _gci_provider="${1:-cloud}"
  _gci_rg="${2:-default}"
  _gci_node="${3:-node}"
  _gci_ttl="${LIBSCRIPT_IP_CACHE_TTL:-300}"
  if [ "${LIBSCRIPT_DISABLE_IP_CACHE:-0}" = "1" ]; then
    return 1
  fi
  _gci_safe=$(printf '%s_%s_%s' "$_gci_provider" "$_gci_rg" "$_gci_node" | tr -c 'A-Za-z0-9_.-' '_')
  _gci_file="${TMPDIR:-/tmp}/libscript_ip_cache_${_gci_safe}"
  if [ ! -f "$_gci_file" ]; then
    return 1
  fi
  _gci_now=$(date +%s 2>/dev/null || printf '0')
  _gci_ts=$(awk 'NR==1 {print $1}' "$_gci_file" 2>/dev/null || printf '0')
  _gci_ip=$(awk 'NR==1 {print $2}' "$_gci_file" 2>/dev/null || true)
  if [ -n "$_gci_ip" ] && [ "$_gci_ip" != "None" ] && [ "$_gci_ip" != "null" ]; then
    if [ "$_gci_now" -gt 0 ] && [ "$_gci_ts" -gt 0 ] && [ $((_gci_now - _gci_ts)) -le "$_gci_ttl" ]; then
      printf '%s\n' "$_gci_ip"
      return 0
    fi
  fi
  return 1
}

# ## libscript_set_cached_vm_ip
# Writes a resolved cloud VM public IP address and current UNIX timestamp to the local TTL cache.
libscript_set_cached_vm_ip() {
  _sci_provider="${1:-cloud}"
  _sci_rg="${2:-default}"
  _sci_node="${3:-node}"
  _sci_ip="${4:-}"
  if [ -z "$_sci_ip" ] || [ "$_sci_ip" = "None" ] || [ "$_sci_ip" = "null" ]; then
    return 0
  fi
  _sci_safe=$(printf '%s_%s_%s' "$_sci_provider" "$_sci_rg" "$_sci_node" | tr -c 'A-Za-z0-9_.-' '_')
  _sci_file="${TMPDIR:-/tmp}/libscript_ip_cache_${_sci_safe}"
  _sci_now=$(date +%s 2>/dev/null || printf '0')
  printf '%s %s\n' "$_sci_now" "$_sci_ip" > "$_sci_file" 2>/dev/null || true
}

# ## libscript_invalidate_cached_vm_ip
# Invalidates the cached public IP entry for a cloud VM (e.g., on delete or deprovision).
libscript_invalidate_cached_vm_ip() {
  _ici_provider="${1:-cloud}"
  _ici_rg="${2:-default}"
  _ici_node="${3:-node}"
  _ici_safe=$(printf '%s_%s_%s' "$_ici_provider" "$_ici_rg" "$_ici_node" | tr -c 'A-Za-z0-9_.-' '_')
  rm -f "${TMPDIR:-/tmp}/libscript_ip_cache_${_ici_safe}" 2>/dev/null || true
}

# ## libscript_compute_tree_hash
# Computes a deterministic SHA-256 or cksum digest for a local application or runtime directory,
# honoring .gitignore and excluding local build/cache directories.
libscript_compute_tree_hash() {
  _cth_dir="${1:-.}"
  if [ ! -d "$_cth_dir" ]; then
    printf '%s\n' 'none'
    return 0
  fi
  _cth_git_head='no-git'
  _cth_git_dirty='clean'
  if command -v git >/dev/null 2>&1 && git -C "$_cth_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    _cth_git_head=$(git -C "$_cth_dir" rev-parse HEAD 2>/dev/null || printf 'no-head')
    _cth_git_dirty=$(git -C "$_cth_dir" status --porcelain 2>/dev/null | cksum | awk '{print $1"_"$2}' || printf 'dirty')
  fi
  _cth_manifest='no-manifest'
  if [ -f "${_cth_dir}/libscript.json" ]; then
    _cth_manifest=$(cksum "${_cth_dir}/libscript.json" 2>/dev/null | awk '{print $1"_"$2}' || printf 'manifest')
  fi
  _cth_locks=$(
    cd "$_cth_dir" 2>/dev/null && {
      for _cth_lf in package.json package-lock.json pnpm-lock.yaml yarn.lock requirements.txt requirements-prod.txt pyproject.toml uv.lock angular.json; do
        if [ -f "$_cth_lf" ]; then
          cksum "$_cth_lf" 2>/dev/null || true
        fi
      done
      set +f
      for _cth_vf in vite.config.* */package.json */package-lock.json */pnpm-lock.yaml */yarn.lock */requirements*.txt */pyproject.toml */uv.lock */angular.json */vite.config.*; do
        if [ -f "$_cth_vf" ]; then
          cksum "$_cth_vf" 2>/dev/null || true
        fi
      done
      set -f
    } | sort | cksum | awk '{print $1"_"$2}'
  )
  _cth_tree=$(
    cd "$_cth_dir" 2>/dev/null && find . \
      \( -name ".git" -o -name "build" -o -name "cmake-build-debug" -o -name "cmake-build-release" \
         -o -name "cmake-build-relwithdebinfo" -o -name "cmake-build-minsizerel" -o -name "cmake-build-*" \
         -o -name "CMakeFiles" -o -name "node_modules" -o -name "target" -o -name ".venv" -o -name "venv" \
         -o -name "dist" -o -name "out" -o -name "webroot" -o -name ".angular" -o -name ".vite" \
         -o -name ".next" -o -name ".nuxt" -o -name ".turbo" -o -name ".parcel-cache" -o -name ".gradle" \
         -o -name ".kotlin" -o -name ".cache" -o -name "__pycache__" -o -name ".pytest_cache" \
         -o -name ".mypy_cache" -o -name ".ruff_cache" -o -name ".tox" -o -name ".nox" -o -name ".terraform" \
         -o -name "logs" -o -name "tmp" -o -name "tests_tmp" -o -name "cache" \) -prune \
      -o -type f ! -name "*.pyc" ! -name "*.pyo" ! -name "*.duckdb" ! -name "*.duckdb.wal" \
         ! -name "CMakeCache.txt" ! -name ".env.libscript" -exec cksum {} + 2>/dev/null | sort | cksum | awk '{print $1"_"$2}'
  )
  _cth_raw="${_cth_git_head}-${_cth_git_dirty}-${_cth_manifest}-${_cth_locks:-0}-${_cth_tree:-0}"
  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$_cth_raw" | sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    printf '%s' "$_cth_raw" | shasum -a 256 | awk '{print $1}'
  else
    printf '%s\n' "$_cth_raw"
  fi
}

# ## libscript_sync_app_to_remote
# Synchronizes a local application directory to a remote host destination using rsync (with tar-over-ssh fallback).
# Removes remote files and directories that no longer exist locally (--delete), respects .gitignore
# (--filter=':- .gitignore'), excludes local build/cache directories from upload, and protects remote
# build/cache/state directories (./build, ./cmake-build-debug, ./cmake-build-release, ./cmake-build-*,
# ./node_modules, ./target, ./.venv, ./dist, ./.angular, ./.vite, ./.gradle, ./out, etc.) from deletion.
libscript_sync_app_to_remote() {
  _sar_src="${1:-}"
  _sar_target="${2:-}"
  _sar_dest="${3:-}"
  _sar_ssh_opts="${4:-$(libscript_ssh_mux_opts)}"

  if [ -z "$_sar_src" ] || [ -z "$_sar_target" ] || [ -z "$_sar_dest" ]; then
    printf '[ERROR] Usage: libscript_sync_app_to_remote <src_dir> <user@host> <remote_dest> [ssh_opts]\n' >&2
    return 1
  fi
  if [ ! -d "$_sar_src" ]; then
    printf '[ERROR] Local source directory does not exist: %s\n' "$_sar_src" >&2
    return 1
  fi

  _sar_src_clean="${_sar_src%/}"
  _sar_remote_rsync_dest="${_sar_dest%/}/"
  _sar_hash_dir="${HOME:-/tmp}/.cache/libscript/sync_hashes"
  mkdir -p "$_sar_hash_dir" 2>/dev/null || true
  _sar_key=$(printf '%s_%s' "$_sar_target" "$_sar_dest" | tr -c 'A-Za-z0-9_.-' '_')
  _sar_hash_file="${_sar_hash_dir}/${_sar_key}.sha256"
  _sar_cur_hash=$(libscript_compute_tree_hash "$_sar_src_clean")

  if [ "${FORCE_REINSTALL:-0}" != "1" ] && [ "${FORCE_REBUILD:-0}" != "1" ] && [ "${FORCE_UPLOAD:-0}" != "1" ] && [ -f "$_sar_hash_file" ]; then
    if [ "$(cat "$_sar_hash_file" 2>/dev/null || true)" = "$_sar_cur_hash" ]; then
      # shellcheck disable=SC2029,SC2086
      if ssh $_sar_ssh_opts "$_sar_target" "[ -d ${_sar_dest} ]" >/dev/null 2>&1; then
        printf '[REUSE] Remote directory %s:%s matches local tree hash (%s); skipping sync.\n' "$_sar_target" "$_sar_dest" "$_sar_cur_hash"
        return 0
      fi
    fi
  fi

  # shellcheck disable=SC2029,SC2086
  ssh $_sar_ssh_opts "$_sar_target" "mkdir -p ${_sar_dest}"

  if command -v rsync >/dev/null 2>&1; then
    _sar_excl_file=$(mktemp "${TMPDIR:-/tmp}/libscript_sar_excl.XXXXXX")
    if command -v git >/dev/null 2>&1 && git -C "$_sar_src_clean" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      git -C "$_sar_src_clean" ls-files --others -i --exclude-standard --directory 2>/dev/null | sed "s|^|/|" > "$_sar_excl_file" || true
      _sar_gi_arg="--exclude-from=${_sar_excl_file}"
    else
      _sar_gi_arg="--filter=:- .gitignore"
    fi
    if rsync -avz --delete \
      --filter='P build' \
      --filter='P cmake-build-debug' \
      --filter='P cmake-build-release' \
      --filter='P cmake-build-relwithdebinfo' \
      --filter='P cmake-build-minsizerel' \
      --filter='P cmake-build-*' \
      --filter='P CMakeFiles' \
      --filter='P CMakeCache.txt' \
      --filter='P node_modules' \
      --filter='P target' \
      --filter='P .venv' \
      --filter='P venv' \
      --filter='P dist' \
      --filter='P out' \
      --filter='P webroot' \
      --filter='P .angular' \
      --filter='P .vite' \
      --filter='P .next' \
      --filter='P .nuxt' \
      --filter='P .turbo' \
      --filter='P .parcel-cache' \
      --filter='P .gradle' \
      --filter='P .kotlin' \
      --filter='P .cache' \
      --filter='P __pycache__' \
      --filter='P .pytest_cache' \
      --filter='P .mypy_cache' \
      --filter='P .ruff_cache' \
      --filter='P .tox' \
      --filter='P .nox' \
      --filter='P .terraform' \
      --filter='P .env' \
      --filter='P .env.secrets' \
      --filter='P .env.libscript' \
      --filter='P .libscript_build.sha256' \
      --filter='P .libscript_src_hash' \
      --filter='P .libscript_py_hash' \
      --filter='P .libscript_kmp_build.sha256' \
      --filter='P data' \
      --filter='P logs' \
      --filter='P coverage' \
      --filter='P .coverage' \
      --filter='P .nyc_output' \
      --filter='P composeApp/build' \
      --filter='P *.duckdb' \
      --filter='P *.duckdb.wal' \
      "$_sar_gi_arg" \
      --exclude='.git' \
      --exclude='build' \
      --exclude='coverage/' \
      --exclude='.coverage' \
      --exclude='.nyc_output/' \
      --exclude='composeApp/build/' \
      --exclude='cmake-build-debug' \
      --exclude='cmake-build-release' \
      --exclude='cmake-build-relwithdebinfo' \
      --exclude='cmake-build-minsizerel' \
      --exclude='cmake-build-*' \
      --exclude='CMakeFiles' \
      --exclude='CMakeCache.txt' \
      --exclude='node_modules' \
      --exclude='target' \
      --exclude='.venv' \
      --exclude='venv' \
      --exclude='dist' \
      --exclude='out' \
      --exclude='webroot' \
      --exclude='.angular' \
      --exclude='.vite' \
      --exclude='.next' \
      --exclude='.nuxt' \
      --exclude='.turbo' \
      --exclude='.parcel-cache' \
      --exclude='.gradle' \
      --exclude='.kotlin' \
      --exclude='.cache' \
      --exclude='__pycache__' \
      --exclude='*.pyc' \
      --exclude='*.pyo' \
      --exclude='.pytest_cache' \
      --exclude='.mypy_cache' \
      --exclude='.ruff_cache' \
      --exclude='.tox' \
      --exclude='.nox' \
      --exclude='.terraform' \
      --exclude='.DS_Store' \
      --exclude='logs' \
      --exclude='*.log' \
      --exclude='*.duckdb' \
      --exclude='*.duckdb.wal' \
      --exclude='.env.libscript' \
      -e "ssh ${_sar_ssh_opts}" \
      "${_sar_src_clean}/" "${_sar_target}:${_sar_remote_rsync_dest}"; then
      rm -f "$_sar_excl_file"
      printf '%s\n' "$_sar_cur_hash" > "$_sar_hash_file" 2>/dev/null || true
      return 0
    fi
    rm -f "$_sar_excl_file"
  fi

  # Fallback: gitignore-aware tar stream over SSH with remote protected-directory prune + empty dir cleanup
  # shellcheck disable=SC2029,SC2086
  ssh $_sar_ssh_opts "$_sar_target" "find ${_sar_dest} -mindepth 1 \\( -name build -o -name cmake-build-debug -o -name cmake-build-release -o -name cmake-build-relwithdebinfo -o -name cmake-build-minsizerel -o -name 'cmake-build-*' -o -name CMakeFiles -o -name node_modules -o -name target -o -name .venv -o -name venv -o -name dist -o -name out -o -name webroot -o -name .angular -o -name .vite -o -name .next -o -name .nuxt -o -name .turbo -o -name .parcel-cache -o -name .gradle -o -name .kotlin -o -name .cache -o -name __pycache__ -o -name .pytest_cache -o -name .mypy_cache -o -name .ruff_cache -o -name .tox -o -name .nox -o -name .terraform -o -name data -o -name logs \\) -prune -o -type f ! -name '.env*' ! -name 'CMakeCache.txt' ! -name '.libscript_*' ! -name '*.duckdb*' -exec rm -f {} + 2>/dev/null || true; find ${_sar_dest} -mindepth 1 -depth \\( -name build -o -name cmake-build-debug -o -name cmake-build-release -o -name cmake-build-relwithdebinfo -o -name cmake-build-minsizerel -o -name 'cmake-build-*' -o -name CMakeFiles -o -name node_modules -o -name target -o -name .venv -o -name venv -o -name dist -o -name out -o -name webroot -o -name .angular -o -name .vite -o -name .next -o -name .nuxt -o -name .turbo -o -name .parcel-cache -o -name .gradle -o -name .kotlin -o -name .cache -o -name __pycache__ -o -name .pytest_cache -o -name .mypy_cache -o -name .ruff_cache -o -name .tox -o -name .nox -o -name .terraform -o -name data -o -name logs \\) -prune -o -type d -empty -exec rmdir {} + 2>/dev/null || true"

  if command -v tar >/dev/null 2>&1; then
    if command -v git >/dev/null 2>&1 && git -C "$_sar_src_clean" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      _sar_flist=$(mktemp "${TMPDIR:-/tmp}/libscript_sync_files.XXXXXX")
      (
        cd "$_sar_src_clean" && git ls-files --cached --others --exclude-standard | grep -vE '^(\.git|build|cmake-build-[^/]+|CMakeFiles|node_modules|target|\.venv|venv|dist|out|webroot|\.angular|\.vite|\.next|\.nuxt|\.turbo|\.parcel-cache|\.gradle|\.kotlin|\.cache|__pycache__|\.pytest_cache|\.mypy_cache|\.ruff_cache|\.tox|\.nox|\.terraform|logs)(/|$)' | grep -vE '(^|/)(\.DS_Store|CMakeCache\.txt|\.env\.libscript|.*\.pyc|.*\.pyo|.*\.log|.*\.duckdb|.*\.duckdb\.wal)$'
      ) > "$_sar_flist" || true
      if [ -f "${_sar_src_clean}/.env" ] && ! grep -Fxq '.env' "$_sar_flist" 2>/dev/null; then
        printf '.env\n' >> "$_sar_flist"
      fi
      if [ -f "${_sar_src_clean}/.env.secrets" ] && ! grep -Fxq '.env.secrets' "$_sar_flist" 2>/dev/null; then
        printf '.env.secrets\n' >> "$_sar_flist"
      fi
      # shellcheck disable=SC2029,SC2086
      if [ -s "$_sar_flist" ] && tar -czf - -C "$_sar_src_clean" -T "$_sar_flist" 2>/dev/null | ssh $_sar_ssh_opts "$_sar_target" "tar -xzf - -C ${_sar_dest}"; then
        rm -f "$_sar_flist"
        printf '%s\n' "$_sar_cur_hash" > "$_sar_hash_file" 2>/dev/null || true
        return 0
      fi
      rm -f "$_sar_flist"
    fi
    # shellcheck disable=SC2029,SC2086
    if tar -czf - \
      --exclude='.git' \
      --exclude='build' \
      --exclude='coverage' \
      --exclude='.coverage' \
      --exclude='.nyc_output' \
      --exclude='composeApp/build' \
      --exclude='cmake-build-debug' \
      --exclude='cmake-build-release' \
      --exclude='cmake-build-relwithdebinfo' \
      --exclude='cmake-build-minsizerel' \
      --exclude='cmake-build-*' \
      --exclude='CMakeFiles' \
      --exclude='CMakeCache.txt' \
      --exclude='node_modules' \
      --exclude='target' \
      --exclude='.venv' \
      --exclude='venv' \
      --exclude='dist' \
      --exclude='out' \
      --exclude='webroot' \
      --exclude='.angular' \
      --exclude='.vite' \
      --exclude='.next' \
      --exclude='.nuxt' \
      --exclude='.turbo' \
      --exclude='.parcel-cache' \
      --exclude='.gradle' \
      --exclude='.kotlin' \
      --exclude='.cache' \
      --exclude='__pycache__' \
      --exclude='*.pyc' \
      --exclude='*.pyo' \
      --exclude='.pytest_cache' \
      --exclude='.mypy_cache' \
      --exclude='.ruff_cache' \
      --exclude='.tox' \
      --exclude='.nox' \
      --exclude='.terraform' \
      --exclude='.DS_Store' \
      --exclude='logs' \
      --exclude='*.log' \
      --exclude='*.duckdb' \
      --exclude='*.duckdb.wal' \
      --exclude='.env.libscript' \
      -C "$_sar_src_clean" . | ssh $_sar_ssh_opts "$_sar_target" "tar -xzf - -C ${_sar_dest}"; then
      printf '%s\n' "$_sar_cur_hash" > "$_sar_hash_file" 2>/dev/null || true
      return 0
    fi
    return 1
  fi

  # shellcheck disable=SC2086
  if scp $_sar_ssh_opts -r "${_sar_src_clean}/"* "${_sar_target}:${_sar_remote_rsync_dest}"; then
    printf '%s\n' "$_sar_cur_hash" > "$_sar_hash_file" 2>/dev/null || true
    return 0
  fi
  return 1
}

# ## libscript_sync_runtime_to_remote
# Synchronizes the local LibScript runtime repository (LIBSCRIPT_ROOT_DIR) to libscript on a remote node,
# honoring .gitignore, removing stale remote directories (--delete), and preserving remote cache/build directories.
libscript_sync_runtime_to_remote() {
  _srr_target="${1:-}"
  _srr_dest="${2:-libscript}"
  _srr_ssh_opts="${3:-$(libscript_ssh_mux_opts)}"
  _srr_src="${LIBSCRIPT_ROOT_DIR%/}"

  if [ -z "$_srr_target" ]; then
    printf '[ERROR] Usage: libscript_sync_runtime_to_remote <user@host> [remote_dest] [ssh_opts]\n' >&2
    return 1
  fi

  _srr_rsync_dest="${_srr_dest%/}/"
  _srr_hash_dir="${HOME:-/tmp}/.cache/libscript/sync_hashes"
  mkdir -p "$_srr_hash_dir" 2>/dev/null || true
  _srr_key=$(printf 'runtime_%s_%s' "$_srr_target" "$_srr_dest" | tr -c 'A-Za-z0-9_.-' '_')
  _srr_hash_file="${_srr_hash_dir}/${_srr_key}.sha256"
  _srr_cur_hash=$(libscript_compute_tree_hash "$_srr_src")

  if [ "${FORCE_REINSTALL:-0}" != "1" ] && [ "${FORCE_REBUILD:-0}" != "1" ] && [ "${FORCE_UPLOAD:-0}" != "1" ] && [ -f "$_srr_hash_file" ]; then
    if [ "$(cat "$_srr_hash_file" 2>/dev/null || true)" = "$_srr_cur_hash" ]; then
      # shellcheck disable=SC2029,SC2086
      if ssh $_srr_ssh_opts "$_srr_target" "[ -x ${_srr_dest}/libscript.sh ]" >/dev/null 2>&1; then
        printf '[REUSE] Remote LibScript runtime %s:%s matches local tree hash (%s); skipping sync.\n' "$_srr_target" "$_srr_dest" "$_srr_cur_hash"
        return 0
      fi
    fi
  fi

  # shellcheck disable=SC2029,SC2086
  ssh $_srr_ssh_opts "$_srr_target" "mkdir -p ${_srr_dest}"

  if command -v rsync >/dev/null 2>&1; then
    _srr_excl_file=$(mktemp "${TMPDIR:-/tmp}/libscript_srr_excl.XXXXXX")
    if command -v git >/dev/null 2>&1 && git -C "$_srr_src" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      git -C "$_srr_src" ls-files --others -i --exclude-standard --directory 2>/dev/null | sed "s|^|/|" > "$_srr_excl_file" || true
      _srr_gi_arg="--exclude-from=${_srr_excl_file}"
    else
      _srr_gi_arg="--filter=:- .gitignore"
    fi
    if rsync -avz --delete \
      --filter='P cache' \
      --filter='P build' \
      --filter='P cmake-build-debug' \
      --filter='P cmake-build-release' \
      --filter='P cmake-build-*' \
      --filter='P target' \
      --filter='P node_modules' \
      --filter='P .venv' \
      --filter='P venv' \
      --filter='P logs' \
      --filter='P tmp' \
      --filter='P tests_tmp' \
      "$_srr_gi_arg" \
      --exclude='.git' \
      --exclude='cache' \
      --exclude='build' \
      --exclude='cmake-build-debug' \
      --exclude='cmake-build-release' \
      --exclude='cmake-build-*' \
      --exclude='target' \
      --exclude='node_modules' \
      --exclude='.venv' \
      --exclude='venv' \
      --exclude='logs' \
      --exclude='tmp' \
      --exclude='tests_tmp' \
      --exclude='.vagrant' \
      --exclude='*.iso' \
      --exclude='*.img' \
      --exclude='*.qcow2' \
      --exclude='*.vhdx' \
      --exclude='*.vmdk' \
      --exclude='*.msi' \
      --exclude='.DS_Store' \
      -e "ssh ${_srr_ssh_opts}" \
      "${_srr_src}/" "${_srr_target}:${_srr_rsync_dest}"; then
      rm -f "$_srr_excl_file"
      printf '%s\n' "$_srr_cur_hash" > "$_srr_hash_file" 2>/dev/null || true
      return 0
    fi
    rm -f "$_srr_excl_file"
  fi

  if command -v tar >/dev/null 2>&1; then
    # shellcheck disable=SC2029,SC2086
    ssh $_srr_ssh_opts "$_srr_target" "find ${_srr_dest} -mindepth 1 \\( -name cache -o -name build -o -name cmake-build-debug -o -name cmake-build-release -o -name 'cmake-build-*' -o -name target -o -name node_modules -o -name .venv -o -name venv -o -name logs -o -name tmp -o -name tests_tmp \\) -prune -o -type f -exec rm -f {} + 2>/dev/null || true; find ${_srr_dest} -mindepth 1 -depth \\( -name cache -o -name build -o -name cmake-build-debug -o -name cmake-build-release -o -name 'cmake-build-*' -o -name target -o -name node_modules -o -name .venv -o -name venv -o -name logs -o -name tmp -o -name tests_tmp \\) -prune -o -type d -empty -exec rmdir {} + 2>/dev/null || true"
    # shellcheck disable=SC2029,SC2086
    if tar -czf - \
      --exclude='.git' \
      --exclude='cache' \
      --exclude='build' \
      --exclude='cmake-build-debug' \
      --exclude='cmake-build-release' \
      --exclude='cmake-build-*' \
      --exclude='target' \
      --exclude='node_modules' \
      --exclude='.venv' \
      --exclude='venv' \
      --exclude='logs' \
      --exclude='tmp' \
      --exclude='tests_tmp' \
      --exclude='.vagrant' \
      --exclude='*.iso' \
      --exclude='*.img' \
      --exclude='*.qcow2' \
      --exclude='*.vhdx' \
      --exclude='*.vmdk' \
      --exclude='*.msi' \
      --exclude='.DS_Store' \
      -C "$_srr_src" . | ssh $_srr_ssh_opts "$_srr_target" "tar -xzf - -C ${_srr_dest}"; then
      printf '%s\n' "$_srr_cur_hash" > "$_srr_hash_file" 2>/dev/null || true
      return 0
    fi
    return 1
  fi

  # shellcheck disable=SC2086
  if scp $_srr_ssh_opts -r "${_srr_src}/"* "${_srr_target}:${_srr_rsync_dest}"; then
    printf '%s\n' "$_srr_cur_hash" > "$_srr_hash_file" 2>/dev/null || true
    return 0
  fi
  return 1
}

# ## libscript_scp_to_remote
# Uploads a local file or directory to a remote host destination using multiplexed SSH options.
libscript_scp_to_remote() {
  _str_src="${1:-}"
  _str_target="${2:-}"
  _str_dest="${3:-}"
  _str_ssh_opts="${4:-$(libscript_ssh_mux_opts)}"
  if [ -z "$_str_src" ] || [ -z "$_str_target" ] || [ -z "$_str_dest" ]; then
    printf '[ERROR] Usage: libscript_scp_to_remote <src> <user@host> <remote_dest> [ssh_opts]\n' >&2
    return 1
  fi
  if [ -d "$_str_src" ]; then
    libscript_sync_app_to_remote "$_str_src" "$_str_target" "$_str_dest" "$_str_ssh_opts"
    return $?
  fi
  # shellcheck disable=SC2086
  scp $_str_ssh_opts -r "$_str_src" "${_str_target}:${_str_dest}"
}

# ## libscript_scp_from_remote
# Downloads a remote file or directory from a remote host to a local destination using multiplexed SSH options.
libscript_scp_from_remote() {
  _sfr_target="${1:-}"
  _sfr_src="${2:-}"
  _sfr_dest="${3:-}"
  _sfr_ssh_opts="${4:-$(libscript_ssh_mux_opts)}"
  if [ -z "$_sfr_target" ] || [ -z "$_sfr_src" ] || [ -z "$_sfr_dest" ]; then
    printf '[ERROR] Usage: libscript_scp_from_remote <user@host> <remote_src> <local_dest> [ssh_opts]\n' >&2
    return 1
  fi
  mkdir -p "$(dirname "$_sfr_dest")"
  # shellcheck disable=SC2086
  scp $_sfr_ssh_opts -r "${_sfr_target}:${_sfr_src}" "$_sfr_dest"
}

if [ $# -gt 0 ]; then
  case "${1:-}" in
    sync-app)
      shift
      libscript_sync_app_to_remote "$@"
      ;;
    sync-runtime)
      shift
      libscript_sync_runtime_to_remote "$@"
      ;;
    scp-to)
      shift
      libscript_scp_to_remote "$@"
      ;;
    scp-from)
      shift
      libscript_scp_from_remote "$@"
      ;;
    ssh-opts)
      libscript_ssh_mux_opts
      ;;
    compute-hash)
      shift
      libscript_compute_tree_hash "$@"
      ;;
  esac
fi

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_rs_caller_dir:-}" ] && SCRIPT_DIR="$_rs_caller_dir"
[ -n "${_rs_caller_this:-}" ] && THIS_FILE="$_rs_caller_this"
unset _rs_caller_this _rs_caller_dir || true
