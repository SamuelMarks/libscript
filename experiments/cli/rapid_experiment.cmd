@echo off
:: # experiment.cmd
:: ## Overview
:: CLI command wrapper for the unified rapid cloud, TFRC 7-backend TPU matrix, and Bento multi-OS Vagrant experimentation lifecycle (`a_provision_instance` .. `i_deprovision_instance`, `tpu_matrix`, `gemma_4_sql_campaign`, `all`).
:: ## Usage
:: libscript.cmd experiment [tpu_matrix|gemma_4_sql_campaign|bento_matrix|all|<step>] ["--tfrc-config=<path>"] ["--backends=<csv|all>"] [flags...]

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
:: Strips any leading experiment / rapid-experiment verb forwarded via %* and dispatches to experiment_cloud.cmd.
:root_found
if /i "%~1"=="experiment" shift
if /i "%~1"=="rapid-experiment" shift

set "_FWD_ARGS="
goto :build_fwd_args
:: ## build_fwd_args
:: Reconstructs quoted arguments after optional verb shift so arbitrary >9 token lists with '=' and ',' are preserved.
:build_fwd_args
if "%~1"=="" goto :exec_cloud
if "!_FWD_ARGS!"=="" (
    set "_FWD_ARGS="%~1""
) else (
    set "_FWD_ARGS=!_FWD_ARGS! "%~1""
)
shift
goto :build_fwd_args

:: ## exec_cloud
:: Invokes experiment_cloud.cmd with all preserved arguments.
:exec_cloud
call "!LIBSCRIPT_ROOT_DIR!\experiments\cli\experiment_cloud.cmd" !_FWD_ARGS!
exit /b !errorlevel!
