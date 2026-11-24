#!/bin/sh
# ## Overview
# Suite E2 runner (e2_sql_evaluation.sh): Evaluates seed-42 Text-to-SQL SQLite and DuckDB execution accuracy and interactive self-correcting agent accuracy across all 7 TPU backends.
#
# ## Usage
# ./experiments/gemma-4-sql/suites/e2_sql_evaluation.sh <repo_dir> <results_dir> <backend_id>

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

_e2_this="${THIS_FILE}"
_e2_dir="${SCRIPT_DIR}"
for _lib in engine/common/log.sh engine/common/remote_sync.sh workloads/ai/_common/tpu_matrix.sh experiments/gemma-4-sql/suites/stage_ab_telemetry.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _lib || true
THIS_FILE="${_e2_this}"
SCRIPT_DIR="${_e2_dir}"

REPO_ARG="$1"
RESULTS_ARG="$2"
BACKEND_ID="$3"
MODEL_NAME="${GEMMA_4_SQL_MODEL:-google/gemma-4-E4B}"
DB_TYPES="${GEMMA_4_SQL_DB_TYPES:-sqlite,duckdb}"
SHM_ROOT="${GEMMA_4_SQL_SHM_ROOT:-/dev/shm/libscript-tpu}"

# ## prepare_sql_eval_fixtures
# Idempotently creates deterministic seed-42 SQLite, DuckDB, DDL, and JSONL fixtures under RESULTS_DIR/fixtures.
prepare_sql_eval_fixtures() {
  _fix_dir="$1"
  _fix_py="$2"
  mkdir -p "${_fix_dir}"
  if [ -f "${_fix_dir}/.seed42.ready" ]; then
    return 0
  fi
  cat <<'DDL_EOF' > "${_fix_dir}/schema.sql"
CREATE TABLE IF NOT EXISTS departments (id INTEGER PRIMARY KEY, name TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS employees (id INTEGER PRIMARY KEY, dept_id INTEGER NOT NULL, name TEXT NOT NULL, salary INTEGER NOT NULL);
DDL_EOF
  cat <<'JSONL_EOF' > "${_fix_dir}/eval_seed42.jsonl"
{"prompt":"List department names with average salary above 100000","sql":"SELECT d.name FROM departments d JOIN employees e ON d.id = e.dept_id GROUP BY d.id, d.name HAVING AVG(e.salary) > 100000;"}
{"prompt":"Count total employees in Engineering","sql":"SELECT COUNT(*) FROM employees e JOIN departments d ON e.dept_id = d.id WHERE d.name = 'Engineering';"}
JSONL_EOF
  if [ "${GEMMA_4_SQL_SYNTHETIC_FIXTURES:-0}" = '1' ]; then
    : > "${_fix_dir}/eval_seed42.sqlite"
    : > "${_fix_dir}/eval_seed42.duckdb"
    printf 'ok\n' > "${_fix_dir}/.seed42.ready"
    return 0
  fi
  "${_fix_py}" - "${_fix_dir}" <<'PY_FIX'
import os
import sqlite3
import sys

fix_dir = sys.argv[1]
sq_path = os.path.join(fix_dir, "eval_seed42.sqlite")
conn = sqlite3.connect(sq_path)
conn.executescript("""
CREATE TABLE IF NOT EXISTS departments (id INTEGER PRIMARY KEY, name TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS employees (id INTEGER PRIMARY KEY, dept_id INTEGER NOT NULL, name TEXT NOT NULL, salary INTEGER NOT NULL);
DELETE FROM employees;
DELETE FROM departments;
INSERT INTO departments VALUES (1, 'Engineering'), (2, 'Support');
INSERT INTO employees VALUES (1, 1, 'Ada', 145000), (2, 1, 'Grace', 135000), (3, 2, 'Linus', 85000);
""")
conn.commit()
conn.close()

try:
    import duckdb
    dk_path = os.path.join(fix_dir, "eval_seed42.duckdb")
    duck_conn = duckdb.connect(dk_path)
    duck_conn.execute("CREATE TABLE IF NOT EXISTS departments (id INTEGER, name VARCHAR);")
    duck_conn.execute("CREATE TABLE IF NOT EXISTS employees (id INTEGER, dept_id INTEGER, name VARCHAR, salary INTEGER);")
    duck_conn.execute("DELETE FROM employees; DELETE FROM departments;")
    duck_conn.execute("INSERT INTO departments VALUES (1, 'Engineering'), (2, 'Support');")
    duck_conn.execute("INSERT INTO employees VALUES (1, 1, 'Ada', 145000), (2, 1, 'Grace', 135000), (3, 2, 'Linus', 85000);")
    duck_conn.close()
except Exception:
    pass
PY_FIX
  printf 'ok\n' > "${_fix_dir}/.seed42.ready"
}

# ## run_e2_backend
# Executes deterministic seed-42 Text-to-SQL SQLite + DuckDB evaluation and self-correcting agent benchmarks for BACKEND_ID.
run_e2_backend() {
  REPO_DIR=$(cd -- "${REPO_ARG}" && pwd)
  mkdir -p "${RESULTS_ARG}/raw"
  RESULTS_DIR=$(cd -- "${RESULTS_ARG}" && pwd)
  OUT_FILE="${RESULTS_DIR}/raw/e2_sql_eval_${BACKEND_ID}.json"

  _tree_hash=$(libscript_compute_tree_hash "${REPO_DIR}")
  if [ "${GEMMA_4_SQL_RESUME:-1}" = '1' ] && [ -f "${OUT_FILE}" ]; then
    if jq -e --arg th "${_tree_hash}" '.status == "ok" and .tree_hash == $th' "${OUT_FILE}" >/dev/null 2>&1; then
      log_info "[RESUME] Skipping completed E2 cell for ${BACKEND_ID} (tree_hash=${_tree_hash})."
      return 0
    fi
  fi

  _vdir=$(libscript_tpu_prepare_backend_venv "${BACKEND_ID}" "${REPO_DIR}" "${SHM_ROOT}")
  _spec=$(libscript_tpu_backend_spec "${BACKEND_ID}" "${SHM_ROOT}")
  _cli_be=$(printf '%s' "${_spec}" | cut -d'|' -f2)
  _benv=$(printf '%s' "${_spec}" | cut -d'|' -f7)
  _fam=$(libscript_tpu_family_label "${BACKEND_ID}")

  _fix_dir="${RESULTS_DIR}/fixtures"
  prepare_sql_eval_fixtures "${_fix_dir}" "${_vdir}/bin/python"

  _strict_flag=''
  if [ "${GEMMA_4_SQL_REQUIRE_HBM:-1}" = '1' ]; then
    _strict_flag='--strict-hardware'
  fi

  _sqlite_acc='null'
  _duckdb_acc='null'
  _acc_sum='0'
  _acc_cnt=0
  _lat_sum='0'
  _max_hbm=0
  _any_fd='false'

  _old_ifs="${IFS}"
  IFS=','
  for _dbt in ${DB_TYPES}; do
    IFS="${_old_ifs}"
    [ -n "${_dbt}" ] || continue
    _db_file="${_fix_dir}/eval_seed42.${_dbt}"
    _raw_eval="${RESULTS_DIR}/raw/.w_e2_eval_${_dbt}_${BACKEND_ID}.json"
    rm -f "${_raw_eval}"

    _eval_cmd="export ${_benv}; PATH='${_vdir}/bin':\"\$PATH\"; cd '${REPO_DIR}' && gemma-4-sql evaluate --model '${MODEL_NAME}' --dataset '${_fix_dir}/eval_seed42.jsonl' --ddl '${_fix_dir}/schema.sql' --db-type '${_dbt}' --db-path '${_db_file}' --hardware tpu ${_strict_flag} --seed 42 --backend '${_cli_be}' --output-json '${_raw_eval}'"
    gemma_4_sql_exec_with_stage_b "${BACKEND_ID}" "${_eval_cmd}" "${OUT_FILE}" "${GEMMA_4_SQL_REQUIRE_HBM:-1}" "${_raw_eval}"

    [ -f "${_raw_eval}" ] || { log_error "Missing E2 evaluate JSON output: ${_raw_eval}"; return 1; }
    _cur_acc=$(jq -er '.metrics.execution_accuracy // .execution_accuracy' "${_raw_eval}" 2>/dev/null || true)
    _cur_lat=$(jq -er '.mean_query_ms // .latency_ms' "${_raw_eval}" 2>/dev/null || true)
    rm -f "${_raw_eval}"

    case "${_cur_acc}" in ''|null|*[!0-9.-]*) log_error "Missing execution_accuracy for ${_dbt} (${BACKEND_ID})"; return 1 ;; esac
    case "${_cur_lat}" in ''|null|*[!0-9.-]*) log_error "Missing mean_query_ms for ${_dbt} (${BACKEND_ID})"; return 1 ;; esac

    if [ "${_dbt}" = 'sqlite' ]; then _sqlite_acc="${_cur_acc}"; fi
    if [ "${_dbt}" = 'duckdb' ]; then _duckdb_acc="${_cur_acc}"; fi
    _acc_sum=$(awk -v a="${_acc_sum}" -v b="${_cur_acc}" 'BEGIN { printf "%.6f", a + b }')
    _lat_sum=$(awk -v a="${_lat_sum}" -v b="${_cur_lat}" 'BEGIN { printf "%.6f", a + b }')
    _acc_cnt=$(( _acc_cnt + 1 ))
    if [ "${STAGE_B_ACCEL_FD}" = 'true' ]; then _any_fd='true'; fi
    if [ "${STAGE_B_PEAK_HBM}" -gt "${_max_hbm}" ]; then _max_hbm="${STAGE_B_PEAK_HBM}"; fi
    IFS=','
  done
  IFS="${_old_ifs}"

  if [ "${_acc_cnt}" -le 0 ]; then
    log_error "No SQL DB engines evaluated for ${BACKEND_ID}"
    return 1
  fi
  _mean_acc=$(awk -v s="${_acc_sum}" -v n="${_acc_cnt}" 'BEGIN { printf "%.4f", s / n }')
  _mean_lat=$(awk -v s="${_lat_sum}" -v n="${_acc_cnt}" 'BEGIN { printf "%.2f", s / n }')

  _raw_agent="${RESULTS_DIR}/raw/.w_e2_agent_${BACKEND_ID}.json"
  rm -f "${_raw_agent}"
  _agent_cmd="export ${_benv}; PATH='${_vdir}/bin':\"\$PATH\"; cd '${REPO_DIR}' && gemma-4-sql agent --prompt 'List department names with average salary above 100000' --db-path '${_fix_dir}/eval_seed42.sqlite' --max-retries 3 --model '${MODEL_NAME}' --hardware tpu ${_strict_flag} --seed 42 --backend '${_cli_be}' --output-json '${_raw_agent}'"
  gemma_4_sql_exec_with_stage_b "${BACKEND_ID}" "${_agent_cmd}" "${OUT_FILE}" "${GEMMA_4_SQL_REQUIRE_HBM:-1}" "${_raw_agent}"

  [ -f "${_raw_agent}" ] || { log_error "Missing E2 agent JSON output: ${_raw_agent}"; return 1; }
  _agent_acc=$(jq -er 'if (.execution_accuracy != null) then .execution_accuracy elif (.success == true) then 1.0 elif (.success == false) then 0.0 else error("missing") end' "${_raw_agent}" 2>/dev/null || true)
  rm -f "${_raw_agent}"
  case "${_agent_acc}" in ''|null|*[!0-9.-]*) log_error "Invalid agent accuracy for ${BACKEND_ID}"; return 1 ;; esac

  jq -n \
    --arg b "${BACKEND_ID}" \
    --arg fam "${_fam}" \
    --arg m "${MODEL_NAME}" \
    --arg th "${_tree_hash}" \
    --argjson sq_acc "${_sqlite_acc}" \
    --argjson dk_acc "${_duckdb_acc}" \
    --argjson sql_acc "${_mean_acc}" \
    --argjson agent_acc "${_agent_acc}" \
    --argjson lat "${_mean_lat}" \
    --argjson fd "${_any_fd}" \
    --argjson hbm "${_max_hbm}" \
    '{
      suite: "E2",
      experiment_id: "gemma-4-sql",
      backend_id: $b,
      comparison_family: $fam,
      model: $m,
      status: "ok",
      seed: 42,
      tree_hash: $th,
      sqlite_execution_accuracy: $sq_acc,
      duckdb_execution_accuracy: $dk_acc,
      sql_execution_accuracy: $sql_acc,
      agent_execution_accuracy: $agent_acc,
      mean_query_ms: $lat,
      telemetry: { accelerator_fd_opened: $fd, peak_tpu_hbm_bytes: $hbm }
    }' > "${OUT_FILE}.tmp"
  jq -e . "${OUT_FILE}.tmp" >/dev/null
  mv -f "${OUT_FILE}.tmp" "${OUT_FILE}"
  log_info "Emitted E2 SQL evaluation artifact -> ${OUT_FILE}"
}

run_e2_backend
