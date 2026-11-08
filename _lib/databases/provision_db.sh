#!/bin/sh
# ## Overview
# Declarative database and cache provisioning engine for LibScript manifests.
# Initializes Postgres, MySQL/MariaDB, SQLite, DuckDB, and Valkey/Redis users/databases and exports connection URLs.
#
# ## Usage
# Run `provision_db.sh <libscript.json>` to provision declared databases and emit `.env.libscript`.

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

# shellcheck disable=SC1090,SC1091
_ls_src_this="${THIS_FILE:-}"; _ls_src_dir="${SCRIPT_DIR:-}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true
[ -n "${_ls_src_this:-}" ] && THIS_FILE="$_ls_src_this"
[ -n "${_ls_src_dir:-}" ] && SCRIPT_DIR="$_ls_src_dir"

JSON_FILE="${1:-libscript.json}"
if [ ! -f "$JSON_FILE" ]; then
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

MANIFEST_DIR=$(cd -- "$(dirname -- "$JSON_FILE")" && pwd)
ENV_OUT="${MANIFEST_DIR}/.env.libscript"

if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_printer.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_printer.sh"
  # shellcheck disable=SC1090,SC1091
  . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_printer.sh"
  unset SCRIPT_NAME || true
  libscript_hydrate_manifest_env "$JSON_FILE" || true
  for _pdb_sub_ef in "${MANIFEST_DIR}"/*/.env; do
    [ -f "$_pdb_sub_ef" ] && libscript_source_env_preserve_existing "$_pdb_sub_ef"
  done
else
  for _pdb_ef in "${MANIFEST_DIR}/.env" "${MANIFEST_DIR}/.env.secrets" "${MANIFEST_DIR}/.env.libscript"; do
    if [ -f "$_pdb_ef" ]; then
      set -a
      set +u
      # shellcheck disable=SC1090,SC1091
      . "$_pdb_ef" 2>/dev/null || true
      set -u
      set +a
    fi
  done
fi
if [ -n "${SERVICE_PATH:-}" ]; then
  export PATH="${SERVICE_PATH}:${PATH}"
fi
if [ -n "${SERVICE_EXTRA_PATH:-}" ]; then
  export PATH="${SERVICE_EXTRA_PATH}:${PATH}"
fi
if type libscript_dedup_path >/dev/null 2>&1; then
  PATH=$(libscript_dedup_path "$PATH")
  export PATH
  export SERVICE_PATH="$PATH"
fi

if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/python_env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/python_env.sh"
  # shellcheck disable=SC1090,SC1091
  . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/python_env.sh"
  unset SCRIPT_NAME || true
fi

# ## ensure_manifest_python_venvs
# Ensures Python virtual environments exist in MANIFEST_DIR and immediate subdirectories before running seed_command.
ensure_manifest_python_venvs() {
  _emp_py_ver=$(jq -r '(.deps.python // .dependencies.python // (.dependencies.runtime[]? | select(.name=="python") | .version) // "3.12")' "$JSON_FILE" 2>/dev/null | head -n 1 || printf '3.12')
  [ -z "$_emp_py_ver" ] || [ "$_emp_py_ver" = "null" ] && _emp_py_ver="3.12"
  _emp_user="${SVC_OWNER_USER:-${SERVICE_USER:-${REMOTE_USER:-${SUDO_USER:-}}}}"
  _emp_home="${REMOTE_HOME:-}"
  if [ -n "$_emp_user" ] && [ -z "$_emp_home" ]; then
    if [ -r "/etc/passwd" ]; then
      _emp_home=$(awk -F: -v u="$_emp_user" '$1==u {print $6; exit}' /etc/passwd 2>/dev/null || true)
    fi
    if [ -z "$_emp_home" ] && [ -d "/home/${_emp_user}" ]; then
      _emp_home="/home/${_emp_user}"
    fi
  fi
  if [ -n "$_emp_home" ] && [ -d "$_emp_home" ]; then
    export UV_PYTHON_INSTALL_DIR="${_emp_home}/.local/share/uv/python"
    export UV_CACHE_DIR="${_emp_home}/.cache/uv"
  fi
  for _emp_proj in "$MANIFEST_DIR" "$MANIFEST_DIR"/*; do
    [ -d "$_emp_proj" ] || continue
    if [ -f "${_emp_proj}/pyproject.toml" ] || [ -f "${_emp_proj}/requirements.txt" ]; then
      if [ -L "${_emp_proj}/.venv/bin/python" ] || [ -L "${_emp_proj}/.venv/bin/python3" ]; then
        _emp_py_target=$(readlink -f "${_emp_proj}/.venv/bin/python3" 2>/dev/null || readlink "${_emp_proj}/.venv/bin/python3" 2>/dev/null || true)
        case "$_emp_py_target" in
          /root/*)
            if [ -n "$_emp_user" ] && [ "$_emp_user" != "root" ]; then
              rm -rf "${_emp_proj}/.venv"
            fi
            ;;
        esac
      fi
      if [ ! -x "${_emp_proj}/.venv/bin/python" ]; then
        if command -v uv >/dev/null 2>&1; then
          if type libscript_python_venv >/dev/null 2>&1; then
            HOME="${_emp_home:-${HOME:-/root}}" LIBSCRIPT_PYTHON_VENV_BACKEND=uv libscript_python_venv "${_emp_proj}/.venv" "$_emp_py_ver" 2>/dev/null || true
          fi
          (cd "$_emp_proj" && HOME="${_emp_home:-${HOME:-/root}}" uv sync --python "$_emp_py_ver" 2>/dev/null || HOME="${_emp_home:-${HOME:-/root}}" uv sync 2>/dev/null || true)
        elif type libscript_python_venv >/dev/null 2>&1; then
          libscript_python_venv "${_emp_proj}/.venv" "$_emp_py_ver" 2>/dev/null || true
        fi
      fi
      if [ -n "$_emp_user" ] && id "$_emp_user" >/dev/null 2>&1 && [ -d "${_emp_proj}/.venv" ]; then
        chown -R "${_emp_user}:${SERVICE_GROUP:-${REMOTE_GROUP:-$_emp_user}}" "${_emp_proj}/.venv" "${_emp_home:-/home/$_emp_user}/.local" "${_emp_home:-/home/$_emp_user}/.cache" 2>/dev/null || true
      fi
    fi
  done
}

# ## expand_manifest_vars
# Expands ${VAR:-default}, ${VAR}, and $VAR environment references inside a manifest string value.
expand_manifest_vars() {
  if type libscript_expand_manifest_vars >/dev/null 2>&1; then
    libscript_expand_manifest_vars "${1:-}"
  else
    printf '%s\n' "${1:-}"
  fi
}

DBS=$(jq -c '((.databases // .infrastructure.databases) | if type == "object" then to_entries | map(.value + {name: (.value.name // .value.db_name // .key)}) elif type == "array" then map(. + {name: (.name // .db_name // .id)}) else [] end)[]?' "$JSON_FILE" 2>/dev/null || true)
if [ -z "$DBS" ]; then
  exit 0
fi

# ## set_env_var
# Idempotently sets or updates a KEY=VALUE pair in the target .env.libscript file.
set_env_var() {
  _key="$1"
  _val="$2"
  [ -n "$_key" ] || return 0
  if [ -f "$ENV_OUT" ]; then
    _tmp_env=$(mktemp "${TMPDIR:-/tmp}/libscript_env.XXXXXX")
    grep -v "^${_key}=" "$ENV_OUT" > "$_tmp_env" 2>/dev/null || true
    cat "$_tmp_env" > "$ENV_OUT"
    rm -f "$_tmp_env"
  fi
  printf '%s=%s\n' "$_key" "$_val" >> "$ENV_OUT"
  chmod 0644 "$ENV_OUT" 2>/dev/null || true
  if [ -n "${SVC_OWNER_USER:-}" ] && id "$SVC_OWNER_USER" >/dev/null 2>&1; then
    chown "$SVC_OWNER_USER" "$ENV_OUT" 2>/dev/null || true
  fi
  export "${_key}=${_val}"
}

# ## resolve_db_asset_path
# Resolves a file or directory path relative to MANIFEST_DIR when not absolute.
resolve_db_asset_path() {
  _rap="$1"
  if [ -z "$_rap" ]; then
    return 0
  elif [ "${_rap#/}" != "$_rap" ]; then
    printf '%s\n' "$_rap"
  else
    printf '%s\n' "${MANIFEST_DIR}/${_rap}"
  fi
}

# ## resolve_min_rows
# Determines the minimum required row count for a given table from the database entry JSON.
resolve_min_rows() {
  _rmr_entry="$1"
  _rmr_table="$2"
  _rmr_val=$(printf '%s\n' "$_rmr_entry" | jq -r --arg tbl "$_rmr_table" '
    if (.min_rows | type) == "number" then .min_rows
    elif (.min_rows | type) == "object" then (.min_rows[$tbl] // 1)
    else 1 end
  ' 2>/dev/null || printf '1')
  if [ -z "$_rmr_val" ] || [ "$_rmr_val" = "null" ]; then
    _rmr_val=1
  fi
  printf '%s\n' "$_rmr_val"
}

# ## find_manifest_duckdb_python
# Searches manifest virtualenvs, LIBSCRIPT_HOME, and PATH for a Python interpreter with duckdb installed.
find_manifest_duckdb_python() {
  for _fmdp_cand in \
    "${MANIFEST_DIR}/.venv/bin/python" \
    "${MANIFEST_DIR}"/*/.venv/bin/python \
    "${LIBSCRIPT_HOME:-$HOME/.libscript}"/python/*/bin/python3 \
    "$(command -v python3 2>/dev/null || true)"; do
    if [ -n "$_fmdp_cand" ] && [ -x "$_fmdp_cand" ]; then
      if "$_fmdp_cand" -c "import duckdb" >/dev/null 2>&1; then
        printf '%s\n' "$_fmdp_cand"
        return 0
      fi
    fi
  done
  return 1
}

# ## ensure_duckdb_cli
# Ensures the duckdb binary is available in PATH by sourcing _lib/databases/duckdb/env.sh or installing it.
ensure_duckdb_cli() {
  if command -v duckdb >/dev/null 2>&1; then
    return 0
  fi
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/databases/duckdb/env.sh" ]; then
    STACK=""
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/databases/duckdb/env.sh"
    # shellcheck disable=SC1090,SC1091
    . "${LIBSCRIPT_ROOT_DIR}/_lib/databases/duckdb/env.sh" || true
    unset SCRIPT_NAME || true
  fi
  if ! command -v duckdb >/dev/null 2>&1 && [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/databases/duckdb/cli.sh" ]; then
    "${LIBSCRIPT_ROOT_DIR}/_lib/databases/duckdb/cli.sh" install latest >/dev/null 2>&1 || true
  fi
  command -v duckdb >/dev/null 2>&1
}

# ## query_duckdb_scalar
# Executes a scalar SQL query against a DuckDB database file using the duckdb CLI with WAL snapshot and Python duckdb fallback.
query_duckdb_scalar() {
  _qds_path="$1"
  _qds_sql="$2"
  _qds_mode="${3:-scalar}"
  _qds_out=""
  if ensure_duckdb_cli; then
    if [ "$_qds_mode" = "len" ]; then
      _qds_out=$(duckdb "$_qds_path" -readonly -csv -noheader -c "$_qds_sql" 2>/dev/null | awk 'NF {c++} END {print c+0}')
    else
      _qds_out=$(duckdb "$_qds_path" -readonly -csv -noheader -c "$_qds_sql" 2>/dev/null | tr -d '[:space:]' | head -n 1 || true)
    fi
    if { [ -z "$_qds_out" ] || [ "$_qds_out" = "0" ]; } && [ -f "${_qds_path}.wal" ]; then
      _qds_tmp=$(mktemp -d 2>/dev/null || printf '%s' "${TMPDIR:-/tmp}/libscript_duckdb_pv.$$")
      mkdir -p "$_qds_tmp"
      _qds_snap="${_qds_tmp}/$(basename -- "$_qds_path")"
      cp -f "$_qds_path" "$_qds_snap" 2>/dev/null || true
      if [ -f "${_qds_path}.wal" ]; then
        cp -f "${_qds_path}.wal" "${_qds_snap}.wal" 2>/dev/null || true
      fi
      if [ "$_qds_mode" = "len" ]; then
        _qds_out=$(duckdb "$_qds_snap" -readonly -csv -noheader -c "$_qds_sql" 2>/dev/null | awk 'NF {c++} END {print c+0}')
      else
        _qds_out=$(duckdb "$_qds_snap" -readonly -csv -noheader -c "$_qds_sql" 2>/dev/null | tr -d '[:space:]' | head -n 1 || true)
      fi
      rm -rf "$_qds_tmp"
    fi
  fi
  if { [ -z "$_qds_out" ] || [ "$_qds_out" = "0" ]; } && [ -s "$_qds_path" ]; then
    if _qds_py=$(find_manifest_duckdb_python 2>/dev/null); then
      _qds_py_out=$("$_qds_py" - "$_qds_path" "$_qds_sql" "$_qds_mode" << 'PY_DUCKDB_FALLBACK' 2>/dev/null || true
import os, shutil, sys, tempfile, duckdb
db_path, sql, mode = sys.argv[1], sys.argv[2], sys.argv[3]
def run_q(p, ro=True):
    con = duckdb.connect(p, read_only=ro)
    try:
        rows = con.execute(sql).fetchall()
        if mode == "len":
            return str(len(rows))
        return str(rows[0][0] if rows and rows[0] else 0)
    finally:
        con.close()
try:
    res = run_q(db_path, True)
    if res in ("0", "") and os.path.exists(db_path + ".wal"):
        raise RuntimeError("retry with wal snapshot")
    print(res)
except Exception:
    tmpdir = tempfile.mkdtemp(prefix="libscript_duck_py_")
    try:
        snap = os.path.join(tmpdir, os.path.basename(db_path))
        shutil.copy2(db_path, snap)
        if os.path.exists(db_path + ".wal"):
            shutil.copy2(db_path + ".wal", snap + ".wal")
        try:
            print(run_q(snap, False))
        except Exception:
            print(run_q(snap, True))
    except Exception:
        print("0")
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)
PY_DUCKDB_FALLBACK
      )
      _qds_py_out=$(printf '%s\n' "$_qds_py_out" | tr -d '[:space:]' | head -n 1 || true)
      if [ -n "$_qds_py_out" ] && [ "$_qds_py_out" != "0" ]; then
        _qds_out="$_qds_py_out"
      elif [ -z "$_qds_out" ] && [ -n "$_qds_py_out" ]; then
        _qds_out="$_qds_py_out"
      fi
    fi
  fi
  printf '%s\n' "${_qds_out:-0}"
}

# ## ensure_valkey_running
# Ensures a Valkey or Redis server is installed and responding to PING on the target host and port.
ensure_valkey_running() {
  _evr_host="${1:-127.0.0.1}"
  _evr_port="${2:-6379}"
  _evr_db_idx="${3:-0}"

  for _evr_cli in valkey-cli redis-cli; do
    if command -v "$_evr_cli" >/dev/null 2>&1; then
      if "$_evr_cli" -h "$_evr_host" -p "$_evr_port" -n "$_evr_db_idx" ping 2>/dev/null | grep -qi "PONG"; then
        _evr_keys=$("$_evr_cli" -h "$_evr_host" -p "$_evr_port" -n "$_evr_db_idx" dbsize 2>/dev/null | tr -d '[:space:]' || printf '0')
        log_info "[DB:VALKEY] [CONFIRM] Valkey/Redis endpoint active at ${_evr_host}:${_evr_port} (db ${_evr_db_idx}, keys: ${_evr_keys:-0})."
        return 0
      fi
    fi
  done

  log_info "[DB:VALKEY] [CREATE] Starting Valkey/Redis on ${_evr_host}:${_evr_port} (db ${_evr_db_idx})..."
  for _evr_comp in valkey redis; do
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/caches/${_evr_comp}/env.sh" ]; then
      STACK=""
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/caches/${_evr_comp}/env.sh"
      # shellcheck disable=SC1090,SC1091
      . "${LIBSCRIPT_ROOT_DIR}/_lib/caches/${_evr_comp}/env.sh" || true
      unset SCRIPT_NAME || true
    fi
  done

  if ! command -v valkey-server >/dev/null 2>&1 && ! command -v redis-server >/dev/null 2>&1; then
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/caches/valkey/cli.sh" ]; then
      env -u SCRIPT_NAME -u STACK "${LIBSCRIPT_ROOT_DIR}/_lib/caches/valkey/cli.sh" install latest >/dev/null 2>&1 || true
    fi
  fi

  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/caches/valkey/cli.sh" ]; then
    env -u SCRIPT_NAME -u STACK "${LIBSCRIPT_ROOT_DIR}/_lib/caches/valkey/cli.sh" start >/dev/null 2>&1 || true
  fi
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/caches/redis/cli.sh" ]; then
    env -u SCRIPT_NAME -u STACK "${LIBSCRIPT_ROOT_DIR}/_lib/caches/redis/cli.sh" start >/dev/null 2>&1 || true
  fi

  for _evr_cli in valkey-cli redis-cli; do
    if command -v "$_evr_cli" >/dev/null 2>&1; then
      if "$_evr_cli" -h "$_evr_host" -p "$_evr_port" -n "$_evr_db_idx" ping 2>/dev/null | grep -qi "PONG"; then
        log_info "[DB:VALKEY] [CREATE] Started Valkey/Redis server on ${_evr_host}:${_evr_port} (db ${_evr_db_idx})."
        return 0
      fi
    fi
  done

  if command -v valkey-server >/dev/null 2>&1; then
    valkey-server --port "$_evr_port" --daemonize yes >/dev/null 2>&1 || priv valkey-server --port "$_evr_port" --daemonize yes >/dev/null 2>&1 || true
  elif command -v redis-server >/dev/null 2>&1; then
    redis-server --port "$_evr_port" --daemonize yes >/dev/null 2>&1 || priv redis-server --port "$_evr_port" --daemonize yes >/dev/null 2>&1 || true
  fi
  return 0
}

# ## check_postgres_populated
# Checks whether all required_tables and min_rows in a PostgreSQL database are already satisfied.
check_postgres_populated() {
  _cpp_entry="$1"
  _cpp_host="$2"
  _cpp_port="$3"
  _cpp_user="$4"
  _cpp_pass="$5"
  _cpp_db="$6"
  [ "${LIBSCRIPT_FORCE_SEED:-0}" = "1" ] && return 1
  command -v psql >/dev/null 2>&1 || return 1
  _cpp_req=$(printf '%s\n' "$_cpp_entry" | jq -r '.required_tables[]?' 2>/dev/null || true)
  _cpp_min_tbl=$(printf '%s\n' "$_cpp_entry" | jq -r '.min_tables // empty' 2>/dev/null || true)
  [ -z "$_cpp_req" ] && [ -z "$_cpp_min_tbl" ] && return 1
  if [ -n "$_cpp_min_tbl" ]; then
    _cpp_cnt=$(PGPASSWORD="$_cpp_pass" psql -h "$_cpp_host" -p "$_cpp_port" -U "$_cpp_user" -d "$_cpp_db" -Atc "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';" 2>/dev/null | tr -d '[:space:]' || printf '0')
    : "${_cpp_cnt:=0}"
    [ "$_cpp_cnt" -lt "$_cpp_min_tbl" ] 2>/dev/null && return 1
  fi
  _cpp_summary=""
  if [ -n "$_cpp_req" ]; then
    while IFS= read -r _cpp_tbl; do
      [ -n "$_cpp_tbl" ] || continue
      _cpp_min_r=$(resolve_min_rows "$_cpp_entry" "$_cpp_tbl")
      _cpp_rc=$(PGPASSWORD="$_cpp_pass" psql -h "$_cpp_host" -p "$_cpp_port" -U "$_cpp_user" -d "$_cpp_db" -Atc "SELECT count(*) FROM \"${_cpp_tbl}\";" 2>/dev/null | tr -d '[:space:]' || printf '%s' "-1")
      if [ -z "$_cpp_rc" ] || [ "$_cpp_rc" -lt "$_cpp_min_r" ] 2>/dev/null; then
        return 1
      fi
      _cpp_summary="${_cpp_summary:+$_cpp_summary, }${_cpp_tbl}=${_cpp_rc} rows"
    done << EOF_CPP_REQ
$_cpp_req
EOF_CPP_REQ
  fi
  log_info "[DB:POSTGRES] [CONFIRM] Database '${_cpp_db}' tables verified (${_cpp_summary:-populated})."
  return 0
}

# ## quiesce_duckdb_lock_holders
# Stops manifest services or processes holding a conflicting lock on the target DuckDB file.
quiesce_duckdb_lock_holders() {
  _qdl_path="$1"
  [ -e "$_qdl_path" ] || return 0
  _qdl_locked=0
  if command -v fuser >/dev/null 2>&1 && fuser "$_qdl_path" >/dev/null 2>&1; then
    _qdl_locked=1
  elif ensure_duckdb_cli; then
    _qdl_err=$(duckdb "$_qdl_path" -c "SELECT 1;" 2>&1 >/dev/null || true)
    case "$_qdl_err" in
      *"Conflicting lock"*|*"Could not set lock"*|*"Resource temporarily unavailable"*)
        _qdl_locked=1
        ;;
    esac
  fi
  if [ "$_qdl_locked" -eq 0 ] && _qdl_py=$(find_manifest_duckdb_python 2>/dev/null); then
    _qdl_py_err=$("$_qdl_py" -c "import sys, duckdb; con = duckdb.connect(sys.argv[1], read_only=False); con.close()" "$_qdl_path" 2>&1 >/dev/null || true)
    case "$_qdl_py_err" in
      *"Conflicting lock"*|*"Could not set lock"*|*"Resource temporarily unavailable"*)
        _qdl_locked=1
        ;;
    esac
  fi
  [ "$_qdl_locked" -eq 1 ] || return 0
  log_info "[DB:DUCKDB] Releasing active service locks on '${_qdl_path}'..."
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/daemonize.sh" ]; then
    STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/daemonize.sh" stop "$JSON_FILE" >/dev/null 2>&1 || true
  fi
  if command -v fuser >/dev/null 2>&1 && fuser "$_qdl_path" >/dev/null 2>&1; then
    fuser -k "$_qdl_path" >/dev/null 2>&1 || priv fuser -k "$_qdl_path" >/dev/null 2>&1 || true
    sleep 1
  fi
  return 0
}

# ## check_duckdb_populated
# Checks whether all required_tables and min_rows in a DuckDB database file are already satisfied.
check_duckdb_populated() {
  _cdp_entry="$1"
  _cdp_path="$2"
  _cdp_ro=$(printf '%s\n' "$_cdp_entry" | jq -r 'if .read_only == true or .readonly == true then "1" else "0" end' 2>/dev/null || printf '0')
  [ "${LIBSCRIPT_FORCE_SEED:-0}" = "1" ] && [ "$_cdp_ro" != "1" ] && return 1
  [ -s "$_cdp_path" ] || return 1
  _cdp_req=$(printf '%s\n' "$_cdp_entry" | jq -r '.required_tables[]?' 2>/dev/null || true)
  _cdp_min_tbl=$(printf '%s\n' "$_cdp_entry" | jq -r '.min_tables // empty' 2>/dev/null || true)
  [ -z "$_cdp_req" ] && [ -z "$_cdp_min_tbl" ] && return 1
  _cdp_cnt=$(query_duckdb_scalar "$_cdp_path" "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'pg_catalog');" "scalar" || printf '0')
  : "${_cdp_cnt:=0}"
  if [ -n "$_cdp_min_tbl" ]; then
    [ "$_cdp_cnt" -lt "$_cdp_min_tbl" ] 2>/dev/null && return 1
  fi
  _cdp_summary=""
  if [ -n "$_cdp_req" ]; then
    while IFS= read -r _cdp_tbl; do
      [ -n "$_cdp_tbl" ] || continue
      _cdp_min_r=$(resolve_min_rows "$_cdp_entry" "$_cdp_tbl")
      _cdp_rc=$(query_duckdb_scalar "$_cdp_path" "SELECT COUNT(*) FROM \"${_cdp_tbl}\";" "scalar" || printf '%s' "-1")
      if [ -z "$_cdp_rc" ] || [ "$_cdp_rc" -lt "$_cdp_min_r" ] 2>/dev/null; then
        return 1
      fi
      _cdp_summary="${_cdp_summary:+$_cdp_summary, }${_cdp_tbl}=${_cdp_rc} rows"
    done << EOF_CDP_REQ
$_cdp_req
EOF_CDP_REQ
  fi
  log_info "[DB:DUCKDB] [CONFIRM] DuckDB '${_cdp_path}' verified (${_cdp_cnt} tables: ${_cdp_summary:-populated})."
  return 0
}

# ## exec_duckdb_sql_file
# Executes a SQL file against a DuckDB database using the duckdb CLI.
exec_duckdb_sql_file() {
  _eds_db="$1"
  _eds_sql_file="$2"
  if ensure_duckdb_cli; then
    duckdb "$_eds_db" < "$_eds_sql_file" >/dev/null 2>&1
  fi
}

# ## import_duckdb_table_file
# Imports a CSV or Parquet file into DuckDB as a table matching the filename stem.
import_duckdb_table_file() {
  _import_db="$1"
  _import_file="$2"
  _import_base=$(basename -- "$_import_file")
  _import_tbl="${_import_base%.*}"
  _import_sql="CREATE TABLE IF NOT EXISTS \"${_import_tbl}\" AS SELECT * FROM '${_import_file}';"
  if ensure_duckdb_cli; then
    duckdb "$_import_db" -c "$_import_sql" >/dev/null 2>&1
  fi
}

# ## run_manifest_seed_cmd
# Executes a database seed_command inside MANIFEST_DIR after sourcing .env, .env.secrets, and .env.libscript.
run_manifest_seed_cmd() {
  _rms_cmd="$1"
  (
    cd "$MANIFEST_DIR"
    set -a
    set +u
    for _rms_ef in "${MANIFEST_DIR}/.env" "${MANIFEST_DIR}/.env.secrets" "${MANIFEST_DIR}/.env.libscript"; do
      if [ -f "$_rms_ef" ]; then
        # shellcheck disable=SC1090
        . "$_rms_ef" 2>/dev/null || true
      fi
    done
    set -u
    set +a
    sh -c "$_rms_cmd"
  )
}

SVC_OWNER_USER=$(jq -r '((.services // .infrastructure.services) | if type == "object" then [to_entries[].value] elif type == "array" then . else [] end) | .[0].user // empty' "$JSON_FILE" 2>/dev/null || true)
SVC_OWNER_USER=$(expand_manifest_vars "$SVC_OWNER_USER")
if [ -z "$SVC_OWNER_USER" ]; then
  SVC_OWNER_USER="${SERVICE_USER:-${REMOTE_USER:-${SUDO_USER:-${ADMIN_USER:-}}}}"
fi

while IFS= read -r db_entry <&3; do
  [ -n "$db_entry" ] || continue
  ENGINE=$(printf '%s\n' "$db_entry" | jq -r '(.engine // .type // "postgres") | ascii_downcase')
  DB_NAME=$(printf '%s\n' "$db_entry" | jq -r '.name // .db_name // "app_db"')
  LEGACY_NAMES_CSV=$(printf '%s\n' "$db_entry" | jq -r '(.legacy_names // []) | join(",")' 2>/dev/null || true)
  DB_USER=$(printf '%s\n' "$db_entry" | jq -r '.user // .username // "postgres"')
  PASS_ENV=$(printf '%s\n' "$db_entry" | jq -r '.password_env // empty')
  RAW_PASS=$(printf '%s\n' "$db_entry" | jq -r '.password // empty')
  DB_HOST=$(printf '%s\n' "$db_entry" | jq -r '.host // "127.0.0.1"')
  DB_PORT=$(printf '%s\n' "$db_entry" | jq -r '.port // empty')
  ENV_VAR_NAME=$(printf '%s\n' "$db_entry" | jq -r '.url_env // "DATABASE_URL"')
  SYNC_URL_ENV=$(printf '%s\n' "$db_entry" | jq -r '.sync_url_env // empty')
  ASYNC_URL_ENV=$(printf '%s\n' "$db_entry" | jq -r '.async_url_env // empty')
  DB_ENV_NAME=$(printf '%s\n' "$db_entry" | jq -r '.db_env // empty')
  SEED_FILE=$(printf '%s\n' "$db_entry" | jq -r '.seed_file // empty')
  SEED_DIR=$(printf '%s\n' "$db_entry" | jq -r '.seed_dir // empty')
  MIGRATION_DIR=$(printf '%s\n' "$db_entry" | jq -r '.migration_dir // empty')
  SEED_CMD=$(printf '%s\n' "$db_entry" | jq -r '.seed_command // empty')
  SEED_CMD=$(expand_manifest_vars "$SEED_CMD")

  DB_PASS="$RAW_PASS"
  if [ -z "$DB_PASS" ] && [ -n "$PASS_ENV" ]; then
    DB_PASS=$(printenv "$PASS_ENV" 2>/dev/null || true)
  fi
  if [ -z "$DB_PASS" ]; then
    DB_PASS='postgres'
  fi

  case "$ENGINE" in
    postgres|postgresql)
      : "${DB_PORT:=5432}"
      log_info "[DB:POSTGRES] Provisioning PostgreSQL database '$DB_NAME' (user: '$DB_USER', host: $DB_HOST:$DB_PORT)..."
      if command -v pg_isready >/dev/null 2>&1 && pg_isready -h "$DB_HOST" -p "$DB_PORT" -q 2>/dev/null; then
        log_info "[DB:POSTGRES] [CONFIRM] PostgreSQL server is active on ${DB_HOST}:${DB_PORT}."
      elif [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/databases/postgres/cli.sh" ]; then
        log_info "[DB:POSTGRES] [CREATE] Starting PostgreSQL server on ${DB_HOST}:${DB_PORT}..."
        "${LIBSCRIPT_ROOT_DIR}/_lib/databases/postgres/cli.sh" start >/dev/null 2>&1 || true
      fi
      set_env_var "$ENV_VAR_NAME" "postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
      [ -n "$SYNC_URL_ENV" ] && set_env_var "$SYNC_URL_ENV" "postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
      [ -n "$ASYNC_URL_ENV" ] && set_env_var "$ASYNC_URL_ENV" "postgresql+asyncpg://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
      [ -n "$DB_ENV_NAME" ] && set_env_var "$DB_ENV_NAME" "$DB_NAME"
      if command -v psql >/dev/null 2>&1; then
        _db_state_dir="${REMOTE_HOME:-${HOME:-/tmp}}/.libscript_db_state"
        mkdir -p "$_db_state_dir" 2>/dev/null || _db_state_dir="${TMPDIR:-/tmp}/.libscript_db_state"
        mkdir -p "$_db_state_dir" 2>/dev/null || true
        if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_schema.sh" ]; then
          env -u SCRIPT_NAME -u STACK "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_schema.sh" \
            --engine postgres --host "$DB_HOST" --port "$DB_PORT" \
            --admin-user postgres --admin-pass "$DB_PASS" \
            --schema "$DB_NAME" --legacy-names "$LEGACY_NAMES_CSV" \
            --user "$DB_USER" --password "$DB_PASS" || true
        fi
        export PGPASSWORD="${DB_PASS}"
        if [ -n "$MIGRATION_DIR" ]; then
          RES_MIG_DIR=$(resolve_db_asset_path "$MIGRATION_DIR")
          if [ -d "$RES_MIG_DIR" ]; then
            _mig_hash=$(cksum "$RES_MIG_DIR"/*.sql 2>/dev/null | cksum | awk '{print $1"_"$2}' || printf 'none')
            _mig_stamp="${_db_state_dir}/pg_${DB_NAME}_mig.sha256"
            if [ "${LIBSCRIPT_FORCE_SEED:-0}" != "1" ] && [ -f "$_mig_stamp" ] && [ "$(cat "$_mig_stamp" 2>/dev/null || true)" = "$_mig_hash" ]; then
              log_info "[REUSE] PostgreSQL migrations in '$RES_MIG_DIR' unchanged for '$DB_NAME'; skipping."
            else
              for _mig_sql in "$RES_MIG_DIR"/*.sql; do
                [ -f "$_mig_sql" ] || continue
                psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$_mig_sql" >/dev/null 2>&1 || true
              done
              printf '%s\n' "$_mig_hash" > "$_mig_stamp" 2>/dev/null || true
            fi
          fi
        fi
        if [ -n "$SEED_FILE" ]; then
          RES_SEED_FILE=$(resolve_db_asset_path "$SEED_FILE")
          if [ -f "$RES_SEED_FILE" ]; then
            _sf_hash=$(cksum "$RES_SEED_FILE" 2>/dev/null | awk '{print $1"_"$2}' || printf 'none')
            _sf_stamp="${_db_state_dir}/pg_${DB_NAME}_seed.sha256"
            if [ "${LIBSCRIPT_FORCE_SEED:-0}" != "1" ] && [ -f "$_sf_stamp" ] && [ "$(cat "$_sf_stamp" 2>/dev/null || true)" = "$_sf_hash" ]; then
              log_info "[REUSE] PostgreSQL seed_file '$RES_SEED_FILE' unchanged for '$DB_NAME'; skipping."
            else
              psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$RES_SEED_FILE" >/dev/null 2>&1 || true
              printf '%s\n' "$_sf_hash" > "$_sf_stamp" 2>/dev/null || true
            fi
          fi
        fi
      fi
      _pg_up_name=$(printf '%s' "$DB_NAME" | tr '[:lower:]-.' '[:upper:]__')
      if [ -n "$SEED_CMD" ]; then
        if check_postgres_populated "$db_entry" "$DB_HOST" "$DB_PORT" "$DB_USER" "$DB_PASS" "$DB_NAME"; then
          log_info "[REUSE] PostgreSQL database '$DB_NAME' already has required tables and minimum rows; skipping full re-seed."
          set_env_var "LIBSCRIPT_DB_POSTGRES_POPULATED" "1"
          set_env_var "LIBSCRIPT_DB_${_pg_up_name}_POPULATED" "1"
        else
          ensure_manifest_python_venvs
          log_info "[UPSERT:POSTGRES] Running PostgreSQL seed_command for '$DB_NAME': $SEED_CMD"
          run_manifest_seed_cmd "$SEED_CMD"
          set_env_var "LIBSCRIPT_DB_POSTGRES_POPULATED" "1"
          set_env_var "LIBSCRIPT_DB_${_pg_up_name}_POPULATED" "1"
        fi
      elif check_postgres_populated "$db_entry" "$DB_HOST" "$DB_PORT" "$DB_USER" "$DB_PASS" "$DB_NAME"; then
        set_env_var "LIBSCRIPT_DB_POSTGRES_POPULATED" "1"
        set_env_var "LIBSCRIPT_DB_${_pg_up_name}_POPULATED" "1"
      fi
      ;;
    mysql|mariadb)
      : "${DB_PORT:=3306}"
      log_info "[DB:MYSQL] Provisioning MySQL/MariaDB database '$DB_NAME' (user: '$DB_USER', host: $DB_HOST:$DB_PORT)..."
      if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/databases/mariadb/cli.sh" ]; then
        "${LIBSCRIPT_ROOT_DIR}/_lib/databases/mariadb/cli.sh" start >/dev/null 2>&1 || true
      fi
      if command -v mysql >/dev/null 2>&1 && [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_schema.sh" ]; then
        env -u SCRIPT_NAME -u STACK "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_schema.sh" \
          --engine mysql --host "$DB_HOST" --port "$DB_PORT" \
          --admin-user root --schema "$DB_NAME" --user "$DB_USER" --password "$DB_PASS" || true
      fi
      set_env_var "$ENV_VAR_NAME" "mysql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
      if [ -n "$SEED_CMD" ]; then
        ensure_manifest_python_venvs
        log_info "[UPSERT:MYSQL] Running MySQL/MariaDB seed_command for '$DB_NAME': $SEED_CMD"
        run_manifest_seed_cmd "$SEED_CMD"
      fi
      ;;
    sqlite|sqlite3)
      DB_PATH=$(printf '%s\n' "$db_entry" | jq -r '.path // .file // .db_path // empty')
      DB_PATH=$(expand_manifest_vars "$DB_PATH")
      if [ -z "$DB_PATH" ]; then
        DB_PATH="${MANIFEST_DIR}/data/${DB_NAME}.sqlite"
      elif [ "${DB_PATH#/}" = "$DB_PATH" ]; then
        DB_PATH="${MANIFEST_DIR}/${DB_PATH}"
      fi
      mkdir -p "$(dirname -- "$DB_PATH")"
      log_info "[DB:SQLITE] Provisioning SQLite database at '$DB_PATH'..."
      if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_schema.sh" ] && command -v sqlite3 >/dev/null 2>&1; then
        env -u SCRIPT_NAME -u STACK "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_schema.sh" \
          --engine sqlite --schema "$DB_PATH" --user "$DB_USER" --password "$DB_PASS" || true
      fi
      set_env_var "$ENV_VAR_NAME" "sqlite:///${DB_PATH}"
      set_env_var "SQLITE_PATH" "$DB_PATH"
      if [ -n "$SEED_FILE" ] && command -v sqlite3 >/dev/null 2>&1; then
        RES_SEED_FILE=$(resolve_db_asset_path "$SEED_FILE")
        if [ -f "$RES_SEED_FILE" ]; then
          sqlite3 "$DB_PATH" < "$RES_SEED_FILE" >/dev/null 2>&1 || true
        fi
      fi
      if [ -n "$SEED_CMD" ]; then
        ensure_manifest_python_venvs
        log_info "[UPSERT:SQLITE] Running SQLite seed_command for '$DB_NAME': $SEED_CMD"
        run_manifest_seed_cmd "$SEED_CMD"
      fi
      ;;
    duckdb)
      DB_READ_ONLY=$(printf '%s\n' "$db_entry" | jq -r 'if .read_only == true or .readonly == true then "1" else "0" end' 2>/dev/null || printf '0')
      DB_PATH=$(printf '%s\n' "$db_entry" | jq -r '.path // .file // .db_path // empty')
      DB_PATH=$(expand_manifest_vars "$DB_PATH")
      if [ -z "$DB_PATH" ]; then
        _pdb_def_mount="${DATA_DISK_MOUNT:-${DATA_MOUNT_DIR:-/mnt/data}}"
        if [ -d "$_pdb_def_mount" ] && [ -w "$_pdb_def_mount" ]; then
          DB_PATH="${_pdb_def_mount}/${DB_NAME}.duckdb"
        else
          DB_PATH="${MANIFEST_DIR}/data/${DB_NAME}.duckdb"
        fi
      elif [ "${DB_PATH#/}" = "$DB_PATH" ]; then
        DB_PATH="${MANIFEST_DIR}/${DB_PATH}"
      fi
      DB_PARENT_DIR=$(dirname -- "$DB_PATH")
      if [ "$DB_READ_ONLY" != "1" ]; then
        mkdir -p "$DB_PARENT_DIR"
      fi
      PATH_ENV_VAR=$(printf '%s\n' "$db_entry" | jq -r '.path_env // .env_var // "DUCKDB_PATH"')
      set_env_var "$PATH_ENV_VAR" "$DB_PATH"
      if [ "$PATH_ENV_VAR" != "DUCKDB_PATH" ] && [ "$DB_READ_ONLY" != "1" ]; then
        set_env_var "DUCKDB_PATH" "$DB_PATH"
      fi
      if [ "$ENV_VAR_NAME" != "DATABASE_URL" ]; then
        set_env_var "$ENV_VAR_NAME" "duckdb:///${DB_PATH}"
      fi
      _duck_up_name=$(printf '%s' "$DB_NAME" | tr '[:lower:]-.' '[:upper:]__')
      if [ "$DB_READ_ONLY" = "1" ]; then
        if [ -s "$DB_PATH" ]; then
          _duck_sz=$(du -sh "$DB_PATH" 2>/dev/null | awk '{print $1}' || printf '0B')
          _duck_tcnt=$(query_duckdb_scalar "$DB_PATH" "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'pg_catalog');" "scalar" || printf '0')
          log_info "[DB:DUCKDB] [CONFIRM] Read-only DuckDB database exists at '$DB_PATH' (${_duck_sz:-0B}, ${_duck_tcnt:-0} table(s))."
          if check_duckdb_populated "$db_entry" "$DB_PATH"; then
            set_env_var "LIBSCRIPT_DB_${_duck_up_name}_POPULATED" "1"
          fi
        else
          log_warn "[DB:DUCKDB] Read-only DuckDB database '$DB_PATH' is not present yet; skipping write provisioning."
        fi
      else
        if [ ! -s "$DB_PATH" ]; then
          log_info "[DB:DUCKDB] [CREATE] Initializing new DuckDB database at '$DB_PATH'..."
          if ensure_duckdb_cli; then
            duckdb "$DB_PATH" -c "SELECT 1;" >/dev/null 2>&1 || true
          fi
        else
          _duck_sz=$(du -sh "$DB_PATH" 2>/dev/null | awk '{print $1}' || printf '0B')
          _duck_tcnt=$(query_duckdb_scalar "$DB_PATH" "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'pg_catalog');" "scalar" || printf '0')
          log_info "[DB:DUCKDB] [CONFIRM] DuckDB database exists at '$DB_PATH' (${_duck_sz:-0B}, ${_duck_tcnt:-0} table(s))."
        fi
        if [ -n "$SEED_FILE" ]; then
          RES_SEED_FILE=$(resolve_db_asset_path "$SEED_FILE")
          if [ -f "$RES_SEED_FILE" ]; then
            exec_duckdb_sql_file "$DB_PATH" "$RES_SEED_FILE" || true
          fi
        fi
        if [ -n "$SEED_DIR" ]; then
          RES_SEED_DIR=$(resolve_db_asset_path "$SEED_DIR")
          if [ -d "$RES_SEED_DIR" ]; then
            for _sd_item in "$RES_SEED_DIR"/*; do
              [ -f "$_sd_item" ] || continue
              case "$_sd_item" in
                *.sql) exec_duckdb_sql_file "$DB_PATH" "$_sd_item" || true ;;
                *.csv|*.parquet) import_duckdb_table_file "$DB_PATH" "$_sd_item" || true ;;
              esac
            done
          fi
        fi
        if [ -n "$SEED_CMD" ]; then
          if check_duckdb_populated "$db_entry" "$DB_PATH"; then
            log_info "[REUSE] DuckDB database '$DB_PATH' already has required tables and minimum rows; skipping full re-seed."
            set_env_var "LIBSCRIPT_DB_DUCKDB_POPULATED" "1"
            set_env_var "LIBSCRIPT_DB_${_duck_up_name}_POPULATED" "1"
          else
            quiesce_duckdb_lock_holders "$DB_PATH"
            ensure_manifest_python_venvs
            log_info "[UPSERT:DUCKDB] Running DuckDB seed_command for '$DB_NAME': $SEED_CMD"
            run_manifest_seed_cmd "$SEED_CMD"
            set_env_var "LIBSCRIPT_DB_DUCKDB_POPULATED" "1"
            set_env_var "LIBSCRIPT_DB_${_duck_up_name}_POPULATED" "1"
          fi
        elif check_duckdb_populated "$db_entry" "$DB_PATH"; then
          set_env_var "LIBSCRIPT_DB_DUCKDB_POPULATED" "1"
          set_env_var "LIBSCRIPT_DB_${_duck_up_name}_POPULATED" "1"
        fi
        DB_OWNER=$(printf '%s\n' "$db_entry" | jq -r '.user // empty')
        DB_OWNER=$(expand_manifest_vars "$DB_OWNER")
        if [ -z "$DB_OWNER" ] || [ "$DB_OWNER" = "postgres" ]; then
          DB_OWNER="$SVC_OWNER_USER"
        fi
        if [ -n "$DB_OWNER" ] && id "$DB_OWNER" >/dev/null 2>&1; then
          _duck_extra_paths=$(
            {
              printf '%s\n' "$db_entry" | jq -r '.extra_paths[]? // empty' 2>/dev/null || true
              env | awk -F= '/^[A-Za-z0-9_]*_DB_PATH=/ {print substr($0, index($0, "=") + 1)}' 2>/dev/null || true
            } | awk 'NF && !seen[$0]++'
          )
          if [ -n "$DB_PARENT_DIR" ] && [ -d "$DB_PARENT_DIR" ]; then
            chown "$DB_OWNER" "$DB_PARENT_DIR" 2>/dev/null || priv chown "$DB_OWNER" "$DB_PARENT_DIR" 2>/dev/null || true
            chmod u+rwX,go+rX "$DB_PARENT_DIR" 2>/dev/null || priv chmod u+rwX,go+rX "$DB_PARENT_DIR" 2>/dev/null || true
          fi
          for _own_target in "$DB_PATH" "${DB_PATH}.wal" "${MANIFEST_DIR}/data"; do
            if [ -n "$_own_target" ] && [ -e "$_own_target" ]; then
              chown -R "$DB_OWNER" "$_own_target" 2>/dev/null || priv chown -R "$DB_OWNER" "$_own_target" 2>/dev/null || true
              chmod -R u+rwX,go+rX "$_own_target" 2>/dev/null || priv chmod -R u+rwX,go+rX "$_own_target" 2>/dev/null || true
            fi
          done
          if [ -n "$_duck_extra_paths" ]; then
            while IFS= read -r _dep_target; do
              _dep_target=$(expand_manifest_vars "$_dep_target")
              if [ -n "$_dep_target" ] && [ -e "$_dep_target" ] && [ -w "$_dep_target" ]; then
                chown -R "$DB_OWNER" "$_dep_target" 2>/dev/null || priv chown -R "$DB_OWNER" "$_dep_target" 2>/dev/null || true
                chmod -R u+rwX,go+rX "$_dep_target" 2>/dev/null || priv chmod -R u+rwX,go+rX "$_dep_target" 2>/dev/null || true
              fi
            done << EOF_DUCK_EXTRA
$_duck_extra_paths
EOF_DUCK_EXTRA
          fi
        fi
      fi
      ;;
    valkey|redis)
      : "${DB_PORT:=6379}"
      DB_IDX=$(printf '%s\n' "$db_entry" | jq -r '.db_index // .database // 0' 2>/dev/null || printf '0')
      [ -z "$DB_IDX" ] || [ "$DB_IDX" = "null" ] && DB_IDX="0"
      log_info "[DB:VALKEY] Provisioning Valkey/Redis cache endpoint ($DB_HOST:$DB_PORT/${DB_IDX})..."
      ensure_valkey_running "$DB_HOST" "$DB_PORT" "$DB_IDX" || true
      set_env_var "REDIS_URL" "redis://${DB_HOST}:${DB_PORT}/${DB_IDX}"
      set_env_var "VALKEY_URL" "redis://${DB_HOST}:${DB_PORT}/${DB_IDX}"
      if [ -n "$ENV_VAR_NAME" ] && [ "$ENV_VAR_NAME" != "DATABASE_URL" ]; then
        set_env_var "$ENV_VAR_NAME" "redis://${DB_HOST}:${DB_PORT}/${DB_IDX}"
      fi
      ;;
  esac
done 3<< EOF_DBS
$DBS
EOF_DBS
