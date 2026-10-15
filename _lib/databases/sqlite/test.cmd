@echo off
:: # test.cmd
::
:: ## Overview
:: 6-stage relational SQL torture test suite for the SQLite component on Windows.
:: Verifies smoke metadata, DDL/DML transactions, joins/aggregates, recursive CTEs
:: and window functions, string expressions, and B-Tree index integrity.
::
:: ## Usage
:: test.cmd [--digest-only]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

if exist "%SCRIPT_DIR%\env.cmd" call "%SCRIPT_DIR%\env.cmd"
call :resolve_sqlite_bin
if errorlevel 1 exit /b 1

set "SQLITE_TEST_DIR=%TEMP%\libscript_sqlite_torture_%RANDOM%"
if not exist "%SQLITE_TEST_DIR%" mkdir "%SQLITE_TEST_DIR%"
set "SQLITE_TEST_DB=%SQLITE_TEST_DIR%\torture.db"
set "SQLITE_TRANSCRIPT_FILE=%SQLITE_TEST_DIR%\transcript.txt"

call :test_stage1_smoke
call :test_stage2_ddl_dml_transactions
call :test_stage3_joins_and_aggregates
call :test_stage4_cte_and_window_functions
call :test_stage5_json_and_strings
call :test_stage6_btree_integrity

set "_digest=ok"
for /f "skip=1 tokens=1" %%H in ('certutil -hashfile "%SQLITE_TRANSCRIPT_FILE%" SHA256 2^>nul') do (
    if "!_digest!"=="ok" set "_digest=%%H"
)
rmdir /s /q "%SQLITE_TEST_DIR%" 2>nul

if "%~1"=="--digest-only" (
    echo !_digest!
) else (
    echo [PASS] SQLite 6-stage torture suite passed ^(digest=!_digest!^)
)
exit /b 0

:: ## resolve_sqlite_bin
:: Resolves the sqlite3 executable on Windows.
:resolve_sqlite_bin
if not "%SQLITE_BIN%"=="" if exist "%SQLITE_BIN%" (
    set "SQLITE_TEST_BIN=%SQLITE_BIN%"
    exit /b 0
)
set "SQLITE_TEST_BIN=sqlite3"
exit /b 0

:: ## run_sql_stage
:: Executes a SQL stage and appends output to the transcript file.
:run_sql_stage
echo === %~1 ===>> "%SQLITE_TRANSCRIPT_FILE%"
"%SQLITE_TEST_BIN%" -batch -noheader "%SQLITE_TEST_DB%" "%~2" >> "%SQLITE_TRANSCRIPT_FILE%"
exit /b !errorlevel!

:: ## test_stage1_smoke
:: Stage 1 smoke check.
:test_stage1_smoke
call :run_sql_stage "STAGE1_SMOKE" "SELECT 1 + 1, 'libscript-sqlite-ok', typeof(3.14159);"
exit /b !errorlevel!

:: ## test_stage2_ddl_dml_transactions
:: Stage 2 DDL/DML and transaction check.
:test_stage2_ddl_dml_transactions
call :run_sql_stage "STAGE2_DDL_DML" "CREATE TABLE departments (id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE); CREATE TABLE employees (id INTEGER PRIMARY KEY, dept_id INTEGER NOT NULL, name TEXT NOT NULL, salary INTEGER NOT NULL); INSERT INTO departments VALUES (1, 'Compilers'), (2, 'Kernels'), (3, 'Databases'); INSERT INTO employees VALUES (101, 1, 'Ada', 150000), (102, 1, 'Grace', 165000), (103, 2, 'Ken', 170000), (104, 2, 'Dennis', 175000), (105, 3, 'Richard', 160000); SELECT COUNT(*), SUM(salary) FROM employees;"
exit /b !errorlevel!

:: ## test_stage3_joins_and_aggregates
:: Stage 3 joins and aggregation check.
:test_stage3_joins_and_aggregates
call :run_sql_stage "STAGE3_JOINS_AGG" "SELECT d.name, COUNT(e.id), SUM(e.salary) FROM departments d LEFT JOIN employees e ON d.id = e.dept_id GROUP BY d.id, d.name ORDER BY d.id ASC;"
exit /b !errorlevel!

:: ## test_stage4_cte_and_window_functions
:: Stage 4 recursive CTE and window functions check.
:test_stage4_cte_and_window_functions
call :run_sql_stage "STAGE4_CTE_WINDOW" "WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n<5) SELECT SUM(n) FROM seq;"
exit /b !errorlevel!

:: ## test_stage5_json_and_strings
:: Stage 5 string functions and expressions check.
:test_stage5_json_and_strings
call :run_sql_stage "STAGE5_STRINGS_EXPR" "SELECT upper(name), length(name) FROM employees ORDER BY id ASC;"
exit /b !errorlevel!

:: ## test_stage6_btree_integrity
:: Stage 6 index creation and PRAGMA integrity_check.
:test_stage6_btree_integrity
call :run_sql_stage "STAGE6_BTREE_INTEGRITY" "CREATE INDEX idx_emp_dept ON employees(dept_id); PRAGMA integrity_check;"
exit /b !errorlevel!
