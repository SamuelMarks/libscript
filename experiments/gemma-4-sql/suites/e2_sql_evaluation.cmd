@echo off
:: # e2_sql_evaluation.cmd
:: ## Overview
:: Suite E2 Windows runner evaluating seed-42 Text-to-SQL SQLite and DuckDB execution accuracy and interactive agent accuracy with Stage B HBM verification.
:: ## Usage
:: e2_sql_evaluation.cmd <repo_dir> <results_dir> <backend_id>

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        if "%LIBSCRIPT_DEBUG%"=="1" echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
if exist "!d!\ROOT" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" ( echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2 & exit /b 1 )
goto :find_root

:: ## root_found
:: Canonicalizes paths and executes E2 SQLite/DuckDB + agent evaluation for BACKEND_ID.
:root_found
set "_e2_repo_arg=%~1"
set "_e2_res_arg=%~2"
set "BACKEND_ID=%~3"
set "MODEL_NAME=%GEMMA_4_SQL_MODEL%"
if "!MODEL_NAME!"=="" set "MODEL_NAME=google/gemma-4-E4B"
set "DB_TYPES=%GEMMA_4_SQL_DB_TYPES%"
if "!DB_TYPES!"=="" set "DB_TYPES=sqlite,duckdb"
set "SHM_ROOT=%GEMMA_4_SQL_SHM_ROOT%"
if "!SHM_ROOT!"=="" set "SHM_ROOT=%TEMP%\libscript-tpu"
set "LIBTPU_PROVIDER=%GEMMA_4_SQL_LIBTPU_PROVIDER%"
if "!LIBTPU_PROVIDER!"=="" set "LIBTPU_PROVIDER=og"

for %%I in ("!_e2_repo_arg!") do set "REPO_DIR=%%~fI"
if not exist "!_e2_res_arg!\raw" mkdir "!_e2_res_arg!\raw"
for %%I in ("!_e2_res_arg!") do set "RESULTS_DIR=%%~fI"
set "OUT_FILE=!RESULTS_DIR!\raw\e2_sql_eval_!BACKEND_ID!.json"

call "%LIBSCRIPT_ROOT_DIR%\engine\common\remote_sync.cmd" :libscript_compute_tree_hash "!REPO_DIR!" >nul
set "_tree_hash=!LIBSCRIPT_TREE_HASH!"

if not "%GEMMA_4_SQL_RESUME%"=="0" if exist "!OUT_FILE!" (
    jq -e --arg th "!_tree_hash!" --arg prov "!LIBTPU_PROVIDER!" --arg prov "!LIBTPU_PROVIDER!" ".status == \"ok\" and .tree_hash == $th and (.libtpu_provider // \"og\") == $prov" "!OUT_FILE!" >nul 2>&1
    if not errorlevel 1 exit /b 0
)

call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_prepare_backend_venv "!BACKEND_ID!" "!REPO_DIR!" "!SHM_ROOT!" "!LIBTPU_PROVIDER!" >nul
call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_provider_env "!TPU_BACKEND_VENV_DIR!" "!LIBTPU_PROVIDER!" >nul
if errorlevel 1 exit /b 1
call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_backend_spec "!BACKEND_ID!" "!SHM_ROOT!" >nul
call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_family_label "!BACKEND_ID!" >nul
for /f "tokens=2,3 delims=|" %%C in ("!TPU_BACKEND_SPEC!") do (
    set "_cli_be=%%C"
    set "_kbe=%%D"
)
if /i "!_kbe!"=="none" set "_kbe="
set "KERAS_BACKEND=!_kbe!"
set "PATH=!TPU_BACKEND_VENV_DIR!\Scripts;!TPU_BACKEND_VENV_DIR!\bin;!PATH!"
set "_py_exe=!TPU_BACKEND_VENV_DIR!\Scripts\python.exe"
if not exist "!_py_exe!" if exist "!TPU_BACKEND_VENV_DIR!\bin\python" set "_py_exe=!TPU_BACKEND_VENV_DIR!\bin\python"

set "_fix_dir=!RESULTS_DIR!\fixtures"
call :prepare_sql_eval_fixtures "!_fix_dir!" "!_py_exe!"

set "_strict_flag="
if not "%GEMMA_4_SQL_REQUIRE_HBM%"=="0" set "_strict_flag=--strict-hardware"

set "_sqlite_acc=null"
set "_duckdb_acc=null"
set "_acc_sum=0"
set "_acc_cnt=0"
set "_lat_sum=0"
set "_any_fd=false"
set "_max_hbm=0"

set "_db_list=!DB_TYPES:,= !"
for %%D in (!_db_list!) do (
    call :run_single_db "%%D"
    if errorlevel 1 exit /b !errorlevel!
)
if "!_acc_cnt!"=="0" exit /b 1

for /f "usebackq delims=" %%A in (`jq -rn --argjson s !_acc_sum! --argjson n !_acc_cnt! "($s / $n * 10000 | round) / 10000"`) do set "_mean_acc=%%A"
for /f "usebackq delims=" %%L in (`jq -rn --argjson s !_lat_sum! --argjson n !_acc_cnt! "($s / $n * 100 | round) / 100"`) do set "_mean_lat=%%L"

set "_raw_agent=!RESULTS_DIR!\raw\.w_e2_agent_!BACKEND_ID!.json"
del /f /q "!_raw_agent!" >nul 2>&1
set "_agent_cmd=cd /d \"!REPO_DIR!\" && gemma-4-sql agent --prompt \"List department names with average salary above 100000\" --db-path \"!_fix_dir!\eval_seed42.sqlite\" --max-retries 3 --model \"!MODEL_NAME!\" --hardware tpu !_strict_flag! --seed 42 --backend \"!_cli_be!\" --output-json \"!_raw_agent!\""
call "!SCRIPT_DIR!\stage_ab_telemetry.cmd" :gemma_4_sql_exec_with_stage_b "!BACKEND_ID!" "!_agent_cmd!" "!OUT_FILE!" "%GEMMA_4_SQL_REQUIRE_HBM%" "!_raw_agent!"
if errorlevel 1 exit /b !errorlevel!
if not exist "!_raw_agent!" exit /b 1
set "_agent_acc="
for /f "usebackq delims=" %%V in (`jq -er "if (.execution_accuracy != null) then .execution_accuracy elif (.success == true) then 1.0 elif (.success == false) then 0.0 else error(\"missing\") end" "!_raw_agent!" 2^>nul`) do set "_agent_acc=%%V"
del /f /q "!_raw_agent!" >nul 2>&1
if "!_agent_acc!"=="" exit /b 1

jq -n --arg b "!BACKEND_ID!" --arg fam "!TPU_BACKEND_FAMILY!" --arg m "!MODEL_NAME!" --arg th "!_tree_hash!" --argjson sq_acc !_sqlite_acc! --argjson dk_acc !_duckdb_acc! --argjson sql_acc !_mean_acc! --argjson agent_acc !_agent_acc! --argjson lat !_mean_lat! --argjson fd !_any_fd! --argjson hbm !_max_hbm! "{suite: \"E2\", experiment_id: \"gemma-4-sql\", backend_id: $b, libtpu_provider: $prov, comparison_family: $fam, model: $m, status: \"ok\", seed: 42, tree_hash: $th, sqlite_execution_accuracy: $sq_acc, duckdb_execution_accuracy: $dk_acc, sql_execution_accuracy: $sql_acc, agent_execution_accuracy: $agent_acc, mean_query_ms: $lat, telemetry: {accelerator_fd_opened: $fd, peak_tpu_hbm_bytes: $hbm}}" > "!OUT_FILE!.tmp"
jq -e . "!OUT_FILE!.tmp" >nul
if errorlevel 1 exit /b 1
move /y "!OUT_FILE!.tmp" "!OUT_FILE!" >nul
exit /b 0

:: ## prepare_sql_eval_fixtures
:: Idempotently writes schema.sql, eval_seed42.jsonl, eval_seed42.sqlite, and eval_seed42.duckdb inside RESULTS_DIR\fixtures.
:prepare_sql_eval_fixtures
set "_pf_dir=%~1"
set "_pf_py=%~2"
if not exist "!_pf_dir!" mkdir "!_pf_dir!"
if exist "!_pf_dir!\.seed42.ready" exit /b 0
> "!_pf_dir!\schema.sql" echo CREATE TABLE IF NOT EXISTS departments ^(id INTEGER PRIMARY KEY, name TEXT NOT NULL^);
>> "!_pf_dir!\schema.sql" echo CREATE TABLE IF NOT EXISTS employees ^(id INTEGER PRIMARY KEY, dept_id INTEGER NOT NULL, name TEXT NOT NULL, salary INTEGER NOT NULL^);
> "!_pf_dir!\eval_seed42.jsonl" echo {"prompt":"List department names with average salary above 100000","sql":"SELECT d.name FROM departments d JOIN employees e ON d.id = e.dept_id GROUP BY d.id, d.name HAVING AVG(e.salary) > 100000;"}
if "%GEMMA_4_SQL_SYNTHETIC_FIXTURES%"=="1" (
    type nul > "!_pf_dir!\eval_seed42.sqlite"
    type nul > "!_pf_dir!\eval_seed42.duckdb"
    > "!_pf_dir!\.seed42.ready" echo ok
    exit /b 0
)
if exist "!_pf_py!" (
    "!_pf_py!" -c "import os,sqlite3,sys; d=sys.argv[1]; c=sqlite3.connect(os.path.join(d,'eval_seed42.sqlite')); c.executescript('CREATE TABLE IF NOT EXISTS departments(id INT,name TEXT); CREATE TABLE IF NOT EXISTS employees(id INT,dept_id INT,name TEXT,salary INT); DELETE FROM employees; DELETE FROM departments; INSERT INTO departments VALUES(1,\"Engineering\"),(2,\"Support\"); INSERT INTO employees VALUES(1,1,\"Ada\",145000),(2,1,\"Grace\",135000),(3,2,\"Linus\",85000);'); c.commit(); c.close()" "!_pf_dir!" 2>nul || rem
    "!_pf_py!" -c "import duckdb,os,sys; d=sys.argv[1]; c=duckdb.connect(os.path.join(d,'eval_seed42.duckdb')); c.execute('CREATE TABLE IF NOT EXISTS departments(id INT,name VARCHAR); CREATE TABLE IF NOT EXISTS employees(id INT,dept_id INT,name VARCHAR,salary INT); DELETE FROM employees; DELETE FROM departments; INSERT INTO departments VALUES(1,\x27Engineering\x27),(2,\x27Support\x27); INSERT INTO employees VALUES(1,1,\x27Ada\x27,145000),(2,1,\x27Grace\x27,135000),(3,2,\x27Linus\x27,85000);'); c.close()" "!_pf_dir!" 2>nul || rem
)
> "!_pf_dir!\.seed42.ready" echo ok
exit /b 0

:: ## run_single_db
:: Evaluates a single SQL DB engine (sqlite or duckdb) and accumulates accuracy and query latency.
:run_single_db
set "_dbt=%~1"
set "_db_f=!_fix_dir!\eval_seed42.!_dbt!"
set "_raw_ev=!RESULTS_DIR!\raw\.w_e2_eval_!_dbt!_!BACKEND_ID!.json"
del /f /q "!_raw_ev!" >nul 2>&1
set "_eval_cmd=cd /d \"!REPO_DIR!\" && gemma-4-sql evaluate --model \"!MODEL_NAME!\" --dataset \"!_fix_dir!\eval_seed42.jsonl\" --ddl \"!_fix_dir!\schema.sql\" --db-type \"!_dbt!\" --db-path \"!_db_f!\" --hardware tpu !_strict_flag! --seed 42 --backend \"!_cli_be!\" --output-json \"!_raw_ev!\""
call "!SCRIPT_DIR!\stage_ab_telemetry.cmd" :gemma_4_sql_exec_with_stage_b "!BACKEND_ID!" "!_eval_cmd!" "!OUT_FILE!" "%GEMMA_4_SQL_REQUIRE_HBM%" "!_raw_ev!"
if errorlevel 1 exit /b !errorlevel!
if not exist "!_raw_ev!" exit /b 1
set "_cur_acc="
set "_cur_lat="
for /f "usebackq delims=" %%V in (`jq -er ".metrics.execution_accuracy // .execution_accuracy" "!_raw_ev!" 2^>nul`) do set "_cur_acc=%%V"
for /f "usebackq delims=" %%V in (`jq -er ".mean_query_ms // .latency_ms" "!_raw_ev!" 2^>nul`) do set "_cur_lat=%%V"
del /f /q "!_raw_ev!" >nul 2>&1
if "!_cur_acc!"=="" exit /b 1
if "!_cur_lat!"=="" exit /b 1
if /i "!_dbt!"=="sqlite" set "_sqlite_acc=!_cur_acc!"
if /i "!_dbt!"=="duckdb" set "_duckdb_acc=!_cur_acc!"
for /f "usebackq delims=" %%S in (`jq -rn --argjson a !_acc_sum! --argjson b !_cur_acc! "$a + $b"`) do set "_acc_sum=%%S"
for /f "usebackq delims=" %%S in (`jq -rn --argjson a !_lat_sum! --argjson b !_cur_lat! "$a + $b"`) do set "_lat_sum=%%S"
set /a "_acc_cnt+=1"
if /i "!STAGE_B_ACCEL_FD!"=="true" set "_any_fd=true"
set "_max_hbm=!STAGE_B_PEAK_HBM!"
exit /b 0
