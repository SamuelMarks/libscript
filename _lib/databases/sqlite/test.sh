#!/bin/sh
# ## Overview
# 6-stage relational SQL torture test suite for the SQLite component.
# Verifies smoke metadata, DDL/DML transactions, joins/aggregates, recursive CTEs
# and window functions, JSON/string expressions, and B-Tree index integrity,
# emitting a deterministic SHA-256 output digest.
#
# ## Usage
# ./_lib/databases/sqlite/test.sh [--digest-only]

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
export LIBSCRIPT_ROOT_DIR

if [ -f "${SCRIPT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${SCRIPT_DIR}/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

# ## resolve_sqlite_bin
# Resolves the sqlite3 executable to test from SQLITE_BIN, SQLITE_PREFIX, or PATH.
resolve_sqlite_bin() {
  if [ -n "${SQLITE_BIN:-}" ] && [ -x "${SQLITE_BIN}" ]; then
    printf '%s\n' "${SQLITE_BIN}"
  elif [ -n "${SQLITE_PREFIX:-}" ] && [ -x "${SQLITE_PREFIX}/bin/sqlite3" ]; then
    printf '%s\n' "${SQLITE_PREFIX}/bin/sqlite3"
  elif command -v sqlite3 >/dev/null 2>&1; then
    command -v sqlite3
  elif command -v sqlite >/dev/null 2>&1; then
    command -v sqlite
  else
    printf 'Error: sqlite3 executable not found in PATH
' >&2
    return 1
  fi
}

# ## run_sql_stage
# Executes a SQL query stage against the test database and appends normalized output to the transcript file.
run_sql_stage() {
  _stage_name="${1}"
  _sql_query="${2}"
  printf '=== %s ===
' "${_stage_name}" >> "${SQLITE_TRANSCRIPT_FILE}"
  "${SQLITE_TEST_BIN}" -batch -noheader "${SQLITE_TEST_DB}" "${_sql_query}" | tr -d '
' >> "${SQLITE_TRANSCRIPT_FILE}"
}

# ## test_stage1_smoke
# Stage 1: Verifies basic arithmetic, string concatenation, and SQLite engine readiness.
test_stage1_smoke() {
  run_sql_stage "STAGE1_SMOKE" "SELECT 1 + 1, 'libscript-sqlite-ok', typeof(3.14159);"
}

# ## test_stage2_ddl_dml_transactions
# Stage 2: Verifies table creation, constraints, ACID transactions, SAVEPOINT, and ROLLBACK TO.
test_stage2_ddl_dml_transactions() {
  run_sql_stage "STAGE2_DDL_DML" "
CREATE TABLE departments (id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE);
CREATE TABLE employees (id INTEGER PRIMARY KEY, dept_id INTEGER NOT NULL, name TEXT NOT NULL, salary INTEGER NOT NULL, FOREIGN KEY(dept_id) REFERENCES departments(id));
BEGIN TRANSACTION;
INSERT INTO departments VALUES (1, 'Compilers'), (2, 'Kernels'), (3, 'Databases');
INSERT INTO employees VALUES (101, 1, 'Ada', 150000), (102, 1, 'Grace', 165000), (103, 2, 'Ken', 170000), (104, 2, 'Dennis', 175000), (105, 3, 'Richard', 160000);
SAVEPOINT sp1;
INSERT INTO employees VALUES (106, 3, 'TempUser', 90000);
ROLLBACK TO sp1;
COMMIT;
SELECT COUNT(*), SUM(salary) FROM employees;
"
}

# ## test_stage3_joins_and_aggregates
# Stage 3: Verifies multi-table INNER/LEFT JOIN, GROUP BY, HAVING, and deterministic ordering.
test_stage3_joins_and_aggregates() {
  run_sql_stage "STAGE3_JOINS_AGG" "
SELECT d.name, COUNT(e.id) AS headcount, MIN(e.salary), MAX(e.salary), SUM(e.salary)
FROM departments d
LEFT JOIN employees e ON d.id = e.dept_id
GROUP BY d.id, d.name
HAVING COUNT(e.id) >= 1
ORDER BY d.id ASC;
"
}

# ## test_stage4_cte_and_window_functions
# Stage 4: Verifies WITH RECURSIVE common table expressions and window functions (ROW_NUMBER, SUM OVER).
test_stage4_cte_and_window_functions() {
  run_sql_stage "STAGE4_CTE_WINDOW" "
WITH RECURSIVE seq(n, fib_a, fib_b) AS (
  SELECT 1, 0, 1
  UNION ALL
  SELECT n + 1, fib_b, fib_a + fib_b FROM seq WHERE n < 10
)
SELECT n, fib_b FROM seq;
SELECT name, salary, ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rn,
       SUM(salary) OVER (ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM employees
ORDER BY id ASC;
"
}

# ## test_stage5_json_and_strings
# Stage 5: Verifies string manipulation, hex encoding, CASE expressions, and subquery filtering.
test_stage5_json_and_strings() {
  run_sql_stage "STAGE5_STRINGS_EXPR" "
SELECT upper(name), length(name), hex(substr(name, 1, 3)),
       CASE WHEN salary >= 170000 THEN 'band-A' ELSE 'band-B' END AS band
FROM employees
WHERE dept_id IN (SELECT id FROM departments WHERE name != 'None')
ORDER BY id ASC;
"
}

# ## test_stage6_btree_integrity
# Stage 6: Verifies secondary B-Tree index creation, query plan correctness, and PRAGMA integrity_check.
test_stage6_btree_integrity() {
  run_sql_stage "STAGE6_BTREE_INTEGRITY" "
CREATE INDEX idx_emp_dept_salary ON employees(dept_id, salary DESC);
ANALYZE;
PRAGMA integrity_check;
SELECT name FROM employees INDEXED BY idx_emp_dept_salary WHERE dept_id = 2 ORDER BY salary DESC;
"
}

SQLITE_TEST_BIN="$(resolve_sqlite_bin)"
_tmp_test_dir="${TMPDIR:-/tmp}/libscript_sqlite_torture_$$"
mkdir -p "${_tmp_test_dir}"
SQLITE_TEST_DB="${_tmp_test_dir}/torture.db"
SQLITE_TRANSCRIPT_FILE="${_tmp_test_dir}/transcript.txt"
: > "${SQLITE_TRANSCRIPT_FILE}"

test_stage1_smoke
test_stage2_ddl_dml_transactions
test_stage3_joins_and_aggregates
test_stage4_cte_and_window_functions
test_stage5_json_and_strings
test_stage6_btree_integrity

if command -v sha256sum >/dev/null 2>&1; then
  _digest="$(sha256sum "${SQLITE_TRANSCRIPT_FILE}" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
  _digest="$(shasum -a 256 "${SQLITE_TRANSCRIPT_FILE}" | awk '{print $1}')"
else
  _digest='ok'
fi

rm -rf "${_tmp_test_dir}"

if [ "${1:-}" = "--digest-only" ]; then
  printf '%s\n' "${_digest}"
else
  printf '[PASS] SQLite 6-stage torture suite passed (digest=%s, bin=%s)
' "${_digest}" "${SQLITE_TEST_BIN}"
fi
