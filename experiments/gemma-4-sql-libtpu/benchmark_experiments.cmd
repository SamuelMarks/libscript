@echo off
:: # benchmark_experiments.cmd
:: ## Overview
:: Master idempotent Windows A/B orchestrator (`benchmark_experiments.cmd`) for `gemma-4-sql-libtpu`, running all 7 Gemma 4 TPU backends across `og` and `rs` providers and synthesizing differential tables.
:: ## Usage
:: benchmark_experiments.cmd [--tfrc-config=<path>] [--repo-dir=<dir>] [--results-dir=<dir>] [--providers=og,rs] [--fresh-vm-per-provider] [--render-latex] [--dry-run]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
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
:: Initializes defaults and parses CLI flags.
:root_found
if "%GEMMA_4_SQL_REPO_DIR%"=="" set "GEMMA_4_SQL_REPO_DIR=%CD%"
if "%GEMMA_4_SQL_AB_RESULTS_DIR%"=="" set "GEMMA_4_SQL_AB_RESULTS_DIR=!LIBSCRIPT_ROOT_DIR!\build\experiment_results\gemma-4-sql-libtpu"
if "%GEMMA_4_SQL_AB_PROVIDERS%"=="" set "GEMMA_4_SQL_AB_PROVIDERS=og,rs"
if "%GEMMA_4_SQL_AB_FRESH_VM_PER_PROVIDER%"=="" set "GEMMA_4_SQL_AB_FRESH_VM_PER_PROVIDER=0"
if "%GEMMA_4_SQL_BACKENDS%"=="" set "GEMMA_4_SQL_BACKENDS=hf_transformers,pytorch_native,keras_jax,keras_tensorflow,keras_pytorch,maxtext,jax_native"
if "%GEMMA_4_SQL_SUBSUITES%"=="" set "GEMMA_4_SQL_SUBSUITES=E0,E1,E2,E3,E4"
if "%GEMMA_4_SQL_RENDER_LATEX%"=="" set "GEMMA_4_SQL_RENDER_LATEX=0"
if "%GEMMA_4_SQL_DRY_RUN%"=="" set "GEMMA_4_SQL_DRY_RUN=0"
goto :parse_args

:: ## parse_args
:: Parses CLI options for benchmark_experiments.cmd.
:parse_args
if "%~1"=="" goto :run_ab
set "_a=%~1"
if "!_a:~0,14!"=="--tfrc-config=" ( set "TFRC_CONFIG=!_a:~14!" & set "TFRC_STRICT=1" & shift & goto :parse_args )
if /i "!_a!"=="--tfrc-config" ( set "TFRC_CONFIG=%~2" & set "TFRC_STRICT=1" & shift & shift & goto :parse_args )
if "!_a:~0,11!"=="--repo-dir=" ( set "GEMMA_4_SQL_REPO_DIR=!_a:~11!" & shift & goto :parse_args )
if /i "!_a!"=="--repo-dir" ( set "GEMMA_4_SQL_REPO_DIR=%~2" & shift & shift & goto :parse_args )
if "!_a:~0,14!"=="--results-dir=" ( set "GEMMA_4_SQL_AB_RESULTS_DIR=!_a:~14!" & shift & goto :parse_args )
if "!_a:~0,10!"=="--out-dir=" ( set "GEMMA_4_SQL_AB_RESULTS_DIR=!_a:~10!" & shift & goto :parse_args )
if /i "!_a!"=="--results-dir" ( set "GEMMA_4_SQL_AB_RESULTS_DIR=%~2" & shift & shift & goto :parse_args )
if "!_a:~0,12!"=="--providers=" ( set "GEMMA_4_SQL_AB_PROVIDERS=!_a:~12!" & shift & goto :parse_args )
if "!_a:~0,11!"=="--backends=" ( set "GEMMA_4_SQL_BACKENDS=!_a:~11!" & shift & goto :parse_args )
if "!_a:~0,12!"=="--subsuites=" ( set "GEMMA_4_SQL_SUBSUITES=!_a:~12!" & shift & goto :parse_args )
if /i "!_a!"=="--fresh-vm-per-provider" ( set "GEMMA_4_SQL_AB_FRESH_VM_PER_PROVIDER=1" & shift & goto :parse_args )
if /i "!_a!"=="--render-latex" ( set "GEMMA_4_SQL_RENDER_LATEX=1" & shift & goto :parse_args )
if /i "!_a!"=="--dry-run" ( set "GEMMA_4_SQL_DRY_RUN=1" & shift & goto :parse_args )
if /i "!_a!"=="--local-exec" ( set "GEMMA_4_SQL_LOCAL_EXEC=1" & shift & goto :parse_args )
shift
goto :parse_args

:: ## run_ab
:: Executes dry-run validation, LaTeX-only synthesis, or full two-provider evaluation.
:run_ab
if /i "!GEMMA_4_SQL_BACKENDS!"=="all" set "GEMMA_4_SQL_BACKENDS=hf_transformers,pytorch_native,keras_jax,keras_tensorflow,keras_pytorch,maxtext,jax_native"
for %%I in ("!GEMMA_4_SQL_REPO_DIR!") do set "GEMMA_4_SQL_REPO_DIR=%%~fI"
if not exist "!GEMMA_4_SQL_AB_RESULTS_DIR!\og\raw" mkdir "!GEMMA_4_SQL_AB_RESULTS_DIR!\og\raw"
if not exist "!GEMMA_4_SQL_AB_RESULTS_DIR!\rs\raw" mkdir "!GEMMA_4_SQL_AB_RESULTS_DIR!\rs\raw"
for %%I in ("!GEMMA_4_SQL_AB_RESULTS_DIR!") do set "GEMMA_4_SQL_AB_RESULTS_DIR=%%~fI"

if "!GEMMA_4_SQL_DRY_RUN!"=="1" (
    echo [INFO] [DRY-RUN] gemma-4-sql-libtpu validated: providers=!GEMMA_4_SQL_AB_PROVIDERS! backends=!GEMMA_4_SQL_BACKENDS! results=!GEMMA_4_SQL_AB_RESULTS_DIR!
    exit /b 0
)

if "!GEMMA_4_SQL_RENDER_LATEX!"=="1" (
    set "STACK="
    call "!SCRIPT_DIR!\suites\synthesize_ab.cmd" "!GEMMA_4_SQL_REPO_DIR!" "!GEMMA_4_SQL_AB_RESULTS_DIR!" "!GEMMA_4_SQL_BACKENDS!"
    exit /b !errorlevel!
)

set "_FIRST=1"
set "_PLIST=!GEMMA_4_SQL_AB_PROVIDERS:,= !"
for %%P in (!_PLIST!) do (
    if "!_FIRST!"=="0" (
        if not "%TPU_NAME%"=="" (
            call "%LIBSCRIPT_ROOT_DIR%\infrastructure\providers\gcp-tpu-vm\cli.cmd" release-locks "%TPU_NAME%"
            if errorlevel 1 exit /b !errorlevel!
        )
    )
    set "_FIRST=0"
    set "GEMMA_4_SQL_LIBTPU_PROVIDER=%%P"
    set "TPU_LIBTPU_PROVIDER=%%P"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\experiments\gemma-4-sql\benchmark_experiments.cmd" "--repo-dir=!GEMMA_4_SQL_REPO_DIR!" "--results-dir=!GEMMA_4_SQL_AB_RESULTS_DIR!\%%P" "--backends=!GEMMA_4_SQL_BACKENDS!" "--subsuites=!GEMMA_4_SQL_SUBSUITES!" "--libtpu-provider=%%P"
    if errorlevel 1 exit /b !errorlevel!
)

set "STACK="
call "!SCRIPT_DIR!\suites\synthesize_ab.cmd" "!GEMMA_4_SQL_REPO_DIR!" "!GEMMA_4_SQL_AB_RESULTS_DIR!" "!GEMMA_4_SQL_BACKENDS!"
exit /b !errorlevel!
