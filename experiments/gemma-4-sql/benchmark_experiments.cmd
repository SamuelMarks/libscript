@echo off
:: # benchmark_experiments.cmd
:: ## Overview
:: Master idempotent 7-backend TFRC TPU benchmark orchestrator on Windows for `gemma-4-sql`, routing E0-E4 locally or across Cloud TPU VM --worker=all with per-cell result streaming and LaTeX synthesis.
:: ## Usage
:: benchmark_experiments.cmd [--tfrc-config=<path>] [--repo-dir=<dir>] [--results-dir=<dir>] [--backends=<csv|all>] [--subsuites=E0,E1,E2,E3,E4] [--render-latex]

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
:: Initializes GEMMA_4_SQL_* variables and parses CLI arguments via shift.
:root_found
if "%GEMMA_4_SQL_REPO_DIR%"=="" set "GEMMA_4_SQL_REPO_DIR=%REPO_DIR%"
if "!GEMMA_4_SQL_REPO_DIR!"=="" set "GEMMA_4_SQL_REPO_DIR=%CD%"
if "%GEMMA_4_SQL_RESULTS_DIR%"=="" set "GEMMA_4_SQL_RESULTS_DIR=%RESULTS_DIR%"
if "!GEMMA_4_SQL_RESULTS_DIR!"=="" set "GEMMA_4_SQL_RESULTS_DIR=%OUT_DIR%"
if "!GEMMA_4_SQL_RESULTS_DIR!"=="" set "GEMMA_4_SQL_RESULTS_DIR=%LIBSCRIPT_ROOT_DIR%\build\experiment_results\gemma-4-sql"
if "%GEMMA_4_SQL_PAPER_DIR%"=="" set "GEMMA_4_SQL_PAPER_DIR=%PAPER_DIR%"
if "%GEMMA_4_SQL_MODEL%"=="" set "GEMMA_4_SQL_MODEL=%MODEL%"
if "!GEMMA_4_SQL_MODEL!"=="" set "GEMMA_4_SQL_MODEL=google/gemma-4-E4B"
if "%GEMMA_4_SQL_BACKENDS%"=="" set "GEMMA_4_SQL_BACKENDS=%BACKENDS%"
if "!GEMMA_4_SQL_BACKENDS!"=="" set "GEMMA_4_SQL_BACKENDS=hf_transformers,pytorch_native,keras_jax,keras_tensorflow,keras_pytorch,maxtext,jax_native"
if "%GEMMA_4_SQL_SUBSUITES%"=="" set "GEMMA_4_SQL_SUBSUITES=%SUBSUITES%"
if "!GEMMA_4_SQL_SUBSUITES!"=="" set "GEMMA_4_SQL_SUBSUITES=E0,E1,E2,E3,E4"
if "%GEMMA_4_SQL_BATCH_SIZES%"=="" set "GEMMA_4_SQL_BATCH_SIZES=1,8,32"
if "%GEMMA_4_SQL_WARMUP%"=="" set "GEMMA_4_SQL_WARMUP=%WARMUP%"
if "!GEMMA_4_SQL_WARMUP!"=="" set "GEMMA_4_SQL_WARMUP=2"
if "%GEMMA_4_SQL_TRIALS%"=="" set "GEMMA_4_SQL_TRIALS=%TRIALS%"
if "!GEMMA_4_SQL_TRIALS!"=="" set "GEMMA_4_SQL_TRIALS=5"
if "%GEMMA_4_SQL_DATASET%"=="" set "GEMMA_4_SQL_DATASET=gemma-4-sql-bench"
if "%GEMMA_4_SQL_DB_TYPES%"=="" set "GEMMA_4_SQL_DB_TYPES=sqlite,duckdb"
if "%GEMMA_4_SQL_REQUIRE_HBM%"=="" set "GEMMA_4_SQL_REQUIRE_HBM=1"
if "%GEMMA_4_SQL_RESUME%"=="" set "GEMMA_4_SQL_RESUME=1"
if "%GEMMA_4_SQL_LOCAL_EXEC%"=="" set "GEMMA_4_SQL_LOCAL_EXEC=0"
if "%GEMMA_4_SQL_SHM_ROOT%"=="" set "GEMMA_4_SQL_SHM_ROOT=%TEMP%\libscript-tpu"
if "%GEMMA_4_SQL_LIBTPU_PROVIDER%"=="" set "GEMMA_4_SQL_LIBTPU_PROVIDER=og"
if "%GEMMA_4_SQL_RENDER_LATEX%"=="" set "GEMMA_4_SQL_RENDER_LATEX=0"
if "%GEMMA_4_SQL_BUILD_PDF%"=="" set "GEMMA_4_SQL_BUILD_PDF=0"
if "%GEMMA_4_SQL_DRY_RUN%"=="" set "GEMMA_4_SQL_DRY_RUN=%DRY_RUN%"
if "!GEMMA_4_SQL_DRY_RUN!"=="" set "GEMMA_4_SQL_DRY_RUN=0"

if /i "%~1"=="experiments" shift
if /i "%~1"=="benchmark-matrix" shift
if /i "%~1"=="tpu_matrix" shift
goto :parse_args

:: ## parse_args
:: Parses arbitrary-length CLI arguments via shift.
:parse_args
if "%~1"=="" goto :after_args
set "_arg=%~1"
if /i "!_arg!"=="--help" goto :show_help
if /i "!_arg!"=="-h" goto :show_help
if "!_arg:~0,14!"=="--tfrc-config=" ( set "TFRC_CONFIG=!_arg:~14!" & set "TFRC_STRICT=1" & shift & goto :parse_args )
if /i "!_arg!"=="--tfrc-config" ( set "TFRC_CONFIG=%~2" & set "TFRC_STRICT=1" & shift & shift & goto :parse_args )
if "!_arg:~0,11!"=="--repo-dir=" ( set "GEMMA_4_SQL_REPO_DIR=!_arg:~11!" & shift & goto :parse_args )
if "!_arg:~0,7!"=="--repo=" ( set "GEMMA_4_SQL_REPO_DIR=!_arg:~7!" & shift & goto :parse_args )
if /i "!_arg!"=="--repo-dir" ( set "GEMMA_4_SQL_REPO_DIR=%~2" & shift & shift & goto :parse_args )
if "!_arg:~0,14!"=="--results-dir=" ( set "GEMMA_4_SQL_RESULTS_DIR=!_arg:~14!" & shift & goto :parse_args )
if "!_arg:~0,10!"=="--out-dir=" ( set "GEMMA_4_SQL_RESULTS_DIR=!_arg:~10!" & shift & goto :parse_args )
if /i "!_arg!"=="--results-dir" ( set "GEMMA_4_SQL_RESULTS_DIR=%~2" & shift & shift & goto :parse_args )
if "!_arg:~0,12!"=="--paper-dir=" ( set "GEMMA_4_SQL_PAPER_DIR=!_arg:~12!" & shift & goto :parse_args )
if /i "!_arg!"=="--paper-dir" ( set "GEMMA_4_SQL_PAPER_DIR=%~2" & shift & shift & goto :parse_args )
if "!_arg:~0,8!"=="--model=" ( set "GEMMA_4_SQL_MODEL=!_arg:~8!" & shift & goto :parse_args )
if /i "!_arg!"=="--model" ( set "GEMMA_4_SQL_MODEL=%~2" & shift & shift & goto :parse_args )
if "!_arg:~0,11!"=="--backends=" ( set "GEMMA_4_SQL_BACKENDS=!_arg:~11!" & shift & goto :parse_args )
if /i "!_arg!"=="--backends" ( set "GEMMA_4_SQL_BACKENDS=%~2" & shift & shift & goto :parse_args )
if "!_arg:~0,12!"=="--subsuites=" ( set "GEMMA_4_SQL_SUBSUITES=!_arg:~12!" & shift & goto :parse_args )
if /i "!_arg!"=="--subsuites" ( set "GEMMA_4_SQL_SUBSUITES=%~2" & shift & shift & goto :parse_args )
if "!_arg:~0,14!"=="--batch-sizes=" ( set "GEMMA_4_SQL_BATCH_SIZES=!_arg:~14!" & shift & goto :parse_args )
if /i "!_arg!"=="--batch-sizes" ( set "GEMMA_4_SQL_BATCH_SIZES=%~2" & shift & shift & goto :parse_args )
if "!_arg:~0,9!"=="--warmup=" ( set "GEMMA_4_SQL_WARMUP=!_arg:~9!" & shift & goto :parse_args )
if /i "!_arg!"=="--warmup" ( set "GEMMA_4_SQL_WARMUP=%~2" & shift & shift & goto :parse_args )
if "!_arg:~0,9!"=="--trials=" ( set "GEMMA_4_SQL_TRIALS=!_arg:~9!" & shift & goto :parse_args )
if /i "!_arg!"=="--trials" ( set "GEMMA_4_SQL_TRIALS=%~2" & shift & shift & goto :parse_args )
if "!_arg:~0,10!"=="--dataset=" ( set "GEMMA_4_SQL_DATASET=!_arg:~10!" & shift & goto :parse_args )
if /i "!_arg!"=="--dataset" ( set "GEMMA_4_SQL_DATASET=%~2" & shift & shift & goto :parse_args )
if "!_arg:~0,11!"=="--db-types=" ( set "GEMMA_4_SQL_DB_TYPES=!_arg:~11!" & shift & goto :parse_args )
if /i "!_arg!"=="--db-types" ( set "GEMMA_4_SQL_DB_TYPES=%~2" & shift & shift & goto :parse_args )
if "!_arg:~0,19!"=="--command-template=" ( set "GEMMA_4_SQL_COMMAND_TEMPLATE=!_arg:~19!" & shift & goto :parse_args )
if /i "!_arg!"=="--command-template" ( set "GEMMA_4_SQL_COMMAND_TEMPLATE=%~2" & shift & shift & goto :parse_args )
if "!_arg:~0,11!"=="--shm-root=" ( set "GEMMA_4_SQL_SHM_ROOT=!_arg:~11!" & shift & goto :parse_args )
if "!_arg:~0,18!"=="--libtpu-provider=" ( set "GEMMA_4_SQL_LIBTPU_PROVIDER=!_arg:~18!" & shift & goto :parse_args )
if /i "!_arg!"=="--libtpu-provider" ( set "GEMMA_4_SQL_LIBTPU_PROVIDER=%~2" & shift & shift & goto :parse_args )
if /i "!_arg!"=="--fresh-vm-per-backend" ( set "TPU_FRESH_VM_PER_BACKEND=1" & shift & goto :parse_args )
if /i "!_arg!"=="--resume" ( set "GEMMA_4_SQL_RESUME=1" & shift & goto :parse_args )
if /i "!_arg!"=="--no-resume" ( set "GEMMA_4_SQL_RESUME=0" & shift & goto :parse_args )
if /i "!_arg!"=="--require-tpu-hbm" ( set "GEMMA_4_SQL_REQUIRE_HBM=1" & shift & goto :parse_args )
if /i "!_arg!"=="--no-require-tpu-hbm" ( set "GEMMA_4_SQL_REQUIRE_HBM=0" & shift & goto :parse_args )
if /i "!_arg!"=="--local-exec" ( set "GEMMA_4_SQL_LOCAL_EXEC=1" & shift & goto :parse_args )
if /i "!_arg!"=="--render-latex" ( set "GEMMA_4_SQL_RENDER_LATEX=1" & shift & goto :parse_args )
if /i "!_arg!"=="--build-pdf" ( set "GEMMA_4_SQL_BUILD_PDF=1" & shift & goto :parse_args )
if /i "!_arg!"=="--dry-run" ( set "GEMMA_4_SQL_DRY_RUN=1" & shift & goto :parse_args )
shift
goto :parse_args

:: ## show_help
:: Displays usage instructions for benchmark_experiments.cmd.
:show_help
echo Usage: benchmark_experiments.cmd [--tfrc-config=^<path^>] [--repo-dir=^<dir^>] [--results-dir=^<dir^>] [--paper-dir=^<dir^>] [--model=^<id^>] [--backends=^<csv^|all^>] [--subsuites=E0,E1,E2,E3,E4] [--batch-sizes=1,8,32] [--warmup=^<n^>] [--trials=^<n^>] [--dataset=^<id^>] [--db-types=sqlite,duckdb] [--command-template=^<tpl^>] [--fresh-vm-per-backend] [--resume] [--local-exec] [--render-latex] [--build-pdf] [--dry-run]
exit /b 0

:: ## after_args
:: Canonicalizes paths and dispatches dry-run, render-latex, local, or remote Cloud TPU VM execution.
:after_args
if /i "!GEMMA_4_SQL_BACKENDS!"=="all" set "GEMMA_4_SQL_BACKENDS=hf_transformers,pytorch_native,keras_jax,keras_tensorflow,keras_pytorch,maxtext,jax_native"
for %%I in ("!GEMMA_4_SQL_REPO_DIR!") do set "GEMMA_4_SQL_REPO_DIR=%%~fI"
if not exist "!GEMMA_4_SQL_RESULTS_DIR!\raw" mkdir "!GEMMA_4_SQL_RESULTS_DIR!\raw"
for %%I in ("!GEMMA_4_SQL_RESULTS_DIR!") do set "GEMMA_4_SQL_RESULTS_DIR=%%~fI"
set "TPU_SUITE_MANIFEST_PATH=!SCRIPT_DIR!\suite.json"
set "TPU_LIBTPU_PROVIDER=!GEMMA_4_SQL_LIBTPU_PROVIDER!"

if /i "!GEMMA_4_SQL_DRY_RUN!"=="true" set "GEMMA_4_SQL_DRY_RUN=1"
if "!GEMMA_4_SQL_DRY_RUN!"=="1" (
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\tfrc_guard.cmd" :libscript_tfrc_is_enabled
    if not errorlevel 1 (
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\tfrc_guard.cmd" :libscript_tfrc_require_config "!GEMMA_4_SQL_REPO_DIR!"
        if errorlevel 1 exit /b !errorlevel!
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\tfrc_guard.cmd" :libscript_tfrc_enforce_zero_cost_env
        if errorlevel 1 exit /b !errorlevel!
    )
    echo [INFO] [DRY-RUN] gemma-4-sql validated: backends=!GEMMA_4_SQL_BACKENDS! subsuites=!GEMMA_4_SQL_SUBSUITES! model=!GEMMA_4_SQL_MODEL! results=!GEMMA_4_SQL_RESULTS_DIR!
    exit /b 0
)

if "!GEMMA_4_SQL_RENDER_LATEX!"=="1" (
    set "GEMMA_4_SQL_SKIP_CUSTOM_EXEC=1"
    set "GEMMA_4_SQL_LOCAL_EXEC=1"
    call "!SCRIPT_DIR!\suites\e4_custom_matrix_and_synthesis.cmd" "!GEMMA_4_SQL_REPO_DIR!" "!GEMMA_4_SQL_RESULTS_DIR!" "!GEMMA_4_SQL_BACKENDS!"
    if errorlevel 1 exit /b !errorlevel!
    call :sync_paper_and_build_pdf
    exit /b !errorlevel!
)

if "!GEMMA_4_SQL_LOCAL_EXEC!"=="1" goto :run_local_matrix
if "%TPU_NAME%"=="" goto :run_local_matrix
goto :run_remote_matrix

:: ## sync_paper_and_build_pdf
:: Copies generated_metrics.tex into GEMMA_4_SQL_PAPER_DIR and optionally compiles the PDF manuscript.
:sync_paper_and_build_pdf
if "!GEMMA_4_SQL_PAPER_DIR!"=="" exit /b 0
if not exist "!GEMMA_4_SQL_RESULTS_DIR!\generated_metrics.tex" exit /b 0
if not exist "!GEMMA_4_SQL_PAPER_DIR!" mkdir "!GEMMA_4_SQL_PAPER_DIR!"
copy /y "!GEMMA_4_SQL_RESULTS_DIR!\generated_metrics.tex" "!GEMMA_4_SQL_PAPER_DIR!\generated_metrics.tex.tmp" >nul
move /y "!GEMMA_4_SQL_PAPER_DIR!\generated_metrics.tex.tmp" "!GEMMA_4_SQL_PAPER_DIR!\generated_metrics.tex" >nul
if "!GEMMA_4_SQL_BUILD_PDF!"=="1" (
    pushd "!GEMMA_4_SQL_PAPER_DIR!"
    where latexmk >nul 2>&1
    if not errorlevel 1 (
        call latexmk -pdf -interaction=nonstopmode main.tex
        set "_pdf_rc=!errorlevel!"
        popd
        exit /b !_pdf_rc!
    )
    where pdflatex >nul 2>&1
    if not errorlevel 1 (
        call pdflatex -interaction=nonstopmode main.tex
        set "_pdf_rc=!errorlevel!"
        popd
        exit /b !_pdf_rc!
    )
    popd
    echo [ERROR] Neither latexmk nor pdflatex is installed for --build-pdf. 1>&2
    exit /b 1
)
exit /b 0

:: ## run_local_matrix
:: Executes E0-E4 locally in-process across every selected backend.
:run_local_matrix
call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_ensure_host_tools "0"
echo ,!GEMMA_4_SQL_SUBSUITES!, | findstr /I /C:",E0," >nul 2>&1
if not errorlevel 1 (
    call "!SCRIPT_DIR!\suites\e0_tfrc_provenance.cmd" "!GEMMA_4_SQL_REPO_DIR!" "!GEMMA_4_SQL_RESULTS_DIR!" "!GEMMA_4_SQL_BACKENDS!"
    if errorlevel 1 exit /b !errorlevel!
)
set "_first_be=1"
set "_be_list=!GEMMA_4_SQL_BACKENDS:,= !"
for %%B in (!_be_list!) do (
    if "!_first_be!"=="0" if not "%TPU_NAME%"=="" (
        call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_cycle_vm_for_backend "%TPU_NAME%" "%%B" "!GEMMA_4_SQL_REPO_DIR!"
        if errorlevel 1 exit /b !errorlevel!
    )
    set "_first_be=0"
    echo ,!GEMMA_4_SQL_SUBSUITES!, | findstr /I /C:",E1," >nul 2>&1
    if not errorlevel 1 (
        call "!SCRIPT_DIR!\suites\e1_inference_throughput.cmd" "!GEMMA_4_SQL_REPO_DIR!" "!GEMMA_4_SQL_RESULTS_DIR!" "%%B"
        if errorlevel 1 exit /b !errorlevel!
    )
    echo ,!GEMMA_4_SQL_SUBSUITES!, | findstr /I /C:",E2," >nul 2>&1
    if not errorlevel 1 (
        call "!SCRIPT_DIR!\suites\e2_sql_evaluation.cmd" "!GEMMA_4_SQL_REPO_DIR!" "!GEMMA_4_SQL_RESULTS_DIR!" "%%B"
        if errorlevel 1 exit /b !errorlevel!
    )
    echo ,!GEMMA_4_SQL_SUBSUITES!, | findstr /I /C:",E3," >nul 2>&1
    if not errorlevel 1 (
        call "!SCRIPT_DIR!\suites\e3_training_finetuning.cmd" "!GEMMA_4_SQL_REPO_DIR!" "!GEMMA_4_SQL_RESULTS_DIR!" "%%B"
        if errorlevel 1 exit /b !errorlevel!
    )
)
echo ,!GEMMA_4_SQL_SUBSUITES!, | findstr /I /C:",E4," >nul 2>&1
if not errorlevel 1 (
    call "!SCRIPT_DIR!\suites\e4_custom_matrix_and_synthesis.cmd" "!GEMMA_4_SQL_REPO_DIR!" "!GEMMA_4_SQL_RESULTS_DIR!" "!GEMMA_4_SQL_BACKENDS!"
    if errorlevel 1 exit /b !errorlevel!
)
call :sync_paper_and_build_pdf
exit /b !errorlevel!

:: ## run_remote_matrix
:: Dispatches E0-E4 remotely across TPU_NAME workers and streams back each JSON artifact atomically.
:run_remote_matrix
call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_ensure_host_tools "1"
set "_rem_env=GEMMA_4_SQL_LOCAL_EXEC=1 GEMMA_4_SQL_MODEL='!GEMMA_4_SQL_MODEL!' GEMMA_4_SQL_BATCH_SIZES='!GEMMA_4_SQL_BATCH_SIZES!' GEMMA_4_SQL_WARMUP='!GEMMA_4_SQL_WARMUP!' GEMMA_4_SQL_TRIALS='!GEMMA_4_SQL_TRIALS!' GEMMA_4_SQL_DATASET='!GEMMA_4_SQL_DATASET!' GEMMA_4_SQL_DB_TYPES='!GEMMA_4_SQL_DB_TYPES!' GEMMA_4_SQL_REQUIRE_HBM='!GEMMA_4_SQL_REQUIRE_HBM!' GEMMA_4_SQL_RESUME='!GEMMA_4_SQL_RESUME!' GEMMA_4_SQL_LIBTPU_PROVIDER='!GEMMA_4_SQL_LIBTPU_PROVIDER!' TPU_LIBTPU_PROVIDER='!GEMMA_4_SQL_LIBTPU_PROVIDER!'"
echo ,!GEMMA_4_SQL_SUBSUITES!, | findstr /I /C:",E0," >nul 2>&1
if not errorlevel 1 (
    call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_run_lockstep "%TPU_NAME%" "jax_native" "!_rem_env! $HOME/libscript/experiments/gemma-4-sql/suites/e0_tfrc_provenance.sh $HOME/workspace $HOME/results '!GEMMA_4_SQL_BACKENDS!'" "!GEMMA_4_SQL_RESULTS_DIR!\logs\e0"
    if errorlevel 1 exit /b !errorlevel!
    call :pull_remote_artifact "%TPU_NAME%" "raw/e0_provenance.json"
    if errorlevel 1 exit /b !errorlevel!
)
set "_first_be=1"
set "_be_list=!GEMMA_4_SQL_BACKENDS:,= !"
for %%B in (!_be_list!) do (
    if "!_first_be!"=="0" (
        call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_cycle_vm_for_backend "%TPU_NAME%" "%%B" "!GEMMA_4_SQL_REPO_DIR!"
        if errorlevel 1 exit /b !errorlevel!
    )
    set "_first_be=0"
    echo ,!GEMMA_4_SQL_SUBSUITES!, | findstr /I /C:",E1," >nul 2>&1
    if not errorlevel 1 (
        call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_run_lockstep "%TPU_NAME%" "%%B" "!_rem_env! $HOME/libscript/experiments/gemma-4-sql/suites/e1_inference_throughput.sh $HOME/workspace $HOME/results '%%B'" "!GEMMA_4_SQL_RESULTS_DIR!\logs\e1_%%B"
        if errorlevel 1 (
            call :pull_remote_artifact "%TPU_NAME%" "raw/e1_inference_%%B.json"
            exit /b 65
        )
        call :pull_remote_artifact "%TPU_NAME%" "raw/e1_inference_%%B.json"
        if errorlevel 1 exit /b !errorlevel!
    )
    echo ,!GEMMA_4_SQL_SUBSUITES!, | findstr /I /C:",E2," >nul 2>&1
    if not errorlevel 1 (
        call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_run_lockstep "%TPU_NAME%" "%%B" "!_rem_env! $HOME/libscript/experiments/gemma-4-sql/suites/e2_sql_evaluation.sh $HOME/workspace $HOME/results '%%B'" "!GEMMA_4_SQL_RESULTS_DIR!\logs\e2_%%B"
        if errorlevel 1 (
            call :pull_remote_artifact "%TPU_NAME%" "raw/e2_sql_eval_%%B.json"
            exit /b 65
        )
        call :pull_remote_artifact "%TPU_NAME%" "raw/e2_sql_eval_%%B.json"
        if errorlevel 1 exit /b !errorlevel!
    )
    echo ,!GEMMA_4_SQL_SUBSUITES!, | findstr /I /C:",E3," >nul 2>&1
    if not errorlevel 1 (
        call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_run_lockstep "%TPU_NAME%" "%%B" "!_rem_env! $HOME/libscript/experiments/gemma-4-sql/suites/e3_training_finetuning.sh $HOME/workspace $HOME/results '%%B'" "!GEMMA_4_SQL_RESULTS_DIR!\logs\e3_%%B"
        if errorlevel 1 (
            call :pull_remote_artifact "%TPU_NAME%" "raw/e3_training_%%B.json"
            exit /b 65
        )
        call :pull_remote_artifact "%TPU_NAME%" "raw/e3_training_%%B.json"
        if errorlevel 1 exit /b !errorlevel!
    )
)
echo ,!GEMMA_4_SQL_SUBSUITES!, | findstr /I /C:",E4," >nul 2>&1
if not errorlevel 1 (
    call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_run_lockstep "%TPU_NAME%" "jax_native" "!_rem_env! GEMMA_4_SQL_COMMAND_TEMPLATE='!GEMMA_4_SQL_COMMAND_TEMPLATE!' $HOME/libscript/experiments/gemma-4-sql/suites/e4_custom_matrix_and_synthesis.sh $HOME/workspace $HOME/results '!GEMMA_4_SQL_BACKENDS!'" "!GEMMA_4_SQL_RESULTS_DIR!\logs\e4"
    if errorlevel 1 exit /b !errorlevel!
    call :pull_remote_custom_artifacts "%TPU_NAME%"
    set "GEMMA_4_SQL_SKIP_CUSTOM_EXEC=1"
    set "GEMMA_4_SQL_LOCAL_EXEC=1"
    call "!SCRIPT_DIR!\suites\e4_custom_matrix_and_synthesis.cmd" "!GEMMA_4_SQL_REPO_DIR!" "!GEMMA_4_SQL_RESULTS_DIR!" "!GEMMA_4_SQL_BACKENDS!"
    if errorlevel 1 exit /b !errorlevel!
)
call :sync_paper_and_build_pdf
exit /b !errorlevel!

:: ## pull_remote_custom_artifacts
:: Discovers and pulls all remote raw/e4_custom_*.json files from worker 0 prior to local E4 synthesis.
:pull_remote_custom_artifacts
set "_prc_tpu=%~1"
set "_prc_tmp=%TEMP%\g4s_custom_ls_%RANDOM%.txt"
call "%LIBSCRIPT_ROOT_DIR%\infrastructure\providers\gcp-tpu-vm\cli.cmd" ssh "!_prc_tpu!" --worker=0 "--command=ls -1 $HOME/results/raw/e4_custom_*.json 2>/dev/null || true" > "!_prc_tmp!" 2>nul
if exist "!_prc_tmp!" (
    for /f "usebackq delims=" %%F in ("!_prc_tmp!") do (
        for %%N in ("%%F") do (
            set "_prc_bn=%%~nxN"
            if /i "!_prc_bn:~0,10!"=="e4_custom_" (
                call :pull_remote_artifact "!_prc_tpu!" "raw/!_prc_bn!"
            )
        )
    )
    del /f /q "!_prc_tmp!" >nul 2>&1
)
exit /b 0

:: ## pull_remote_artifact
:: Copies a single JSON artifact from worker 0 to local RESULTS_DIR via .tmp + jq check + move /y.
:pull_remote_artifact
set "_pra_tpu=%~1"
set "_pra_rel=%~2"
set "_pra_win=!_pra_rel:/=\!"
set "_pra_local=!GEMMA_4_SQL_RESULTS_DIR!\!_pra_win!"
for %%D in ("!_pra_local!") do if not exist "%%~dpD" mkdir "%%~dpD"
call "%LIBSCRIPT_ROOT_DIR%\infrastructure\providers\gcp-tpu-vm\cli.cmd" scp-from "!_pra_tpu!" "!_pra_tpu!:~/results/!_pra_rel!" "!_pra_local!.tmp" --worker=0
if errorlevel 1 exit /b !errorlevel!
jq -e . "!_pra_local!.tmp" >nul
if errorlevel 1 exit /b 1
move /y "!_pra_local!.tmp" "!_pra_local!" >nul
exit /b 0
