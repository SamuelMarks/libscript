@echo off
:: # collect.cmd
:: ## Overview
:: Atomically collects `og\`, `rs\`, `ab_comparison_summary.{json,csv,md}`, and `generated_metrics.tex` from Cloud TPU VM worker 0 on Windows.
:: ## Usage
:: collect.cmd [--results-dir=<dir>] [--dry-run]

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
:: Parses CLI options and collects remote A/B results.
:root_found
set "RESULTS_DIR=%GEMMA_4_SQL_AB_RESULTS_DIR%"
if "!RESULTS_DIR!"=="" set "RESULTS_DIR=!LIBSCRIPT_ROOT_DIR!\build\experiment_results\gemma-4-sql-libtpu"
set "DRY_RUN_FLAG=%GEMMA_4_SQL_DRY_RUN%"
if "!DRY_RUN_FLAG!"=="" set "DRY_RUN_FLAG=0"
goto :parse_args

:: ## parse_args
:: Parses CLI options for collect.cmd.
:parse_args
if "%~1"=="" goto :do_collect
set "_a=%~1"
if "!_a:~0,14!"=="--results-dir=" ( set "RESULTS_DIR=!_a:~14!" & shift & goto :parse_args )
if "!_a:~0,10!"=="--out-dir=" ( set "RESULTS_DIR=!_a:~10!" & shift & goto :parse_args )
if /i "!_a!"=="--results-dir" ( set "RESULTS_DIR=%~2" & shift & shift & goto :parse_args )
if /i "!_a!"=="--dry-run" ( set "DRY_RUN_FLAG=1" & shift & goto :parse_args )
shift
goto :parse_args

:: ## do_collect
:: Transfers ~/results_ab/* from worker 0 into local RESULTS_DIR.
:do_collect
if not exist "!RESULTS_DIR!\og\raw" mkdir "!RESULTS_DIR!\og\raw"
if not exist "!RESULTS_DIR!\rs\raw" mkdir "!RESULTS_DIR!\rs\raw"
for %%I in ("!RESULTS_DIR!") do set "RESULTS_DIR=%%~fI"
if "!DRY_RUN_FLAG!"=="1" (
    echo [COLLECT] Verified local gemma-4-sql-libtpu results directory !RESULTS_DIR! ^(dry-run^).
    exit /b 0
)
if "%TPU_NAME%"=="" (
    echo [COLLECT] Verified local gemma-4-sql-libtpu results directory !RESULTS_DIR!.
    exit /b 0
)
call "%LIBSCRIPT_ROOT_DIR%\infrastructure\providers\gcp-tpu-vm\cli.cmd" scp-from "%TPU_NAME%" "%TPU_NAME%:~/results_ab/*" "!RESULTS_DIR!" --recurse --worker=0
exit /b !errorlevel!
