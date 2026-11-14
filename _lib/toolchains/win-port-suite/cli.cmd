@echo off
:: # cli.cmd
:: ## Overview
:: Command-line interface entrypoint for the `win-port-suite` component on Windows, routing `experiments` (`bench`) and `cloud-experiments` as well as standard Version Manager verbs.
:: ## Usage
:: _lib\toolchains\win-port-suite\cli.cmd [install|use|ls|experiments|cloud-experiments|...] [args]

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

if /i "%~1"=="experiments" (
    call "!SCRIPT_DIR!\benchmark_experiments.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)
if /i "%~1"=="bench" (
    call "!SCRIPT_DIR!\benchmark_experiments.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)
if /i "%~1"=="cloud-experiments" (
    if "%CORE_EXPERIMENT_SUITE%"=="" set "CORE_EXPERIMENT_SUITE=win_port"
    call "!LIBSCRIPT_ROOT_DIR!\_lib\cloud\core\experiment_cloud.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)
if /i "%~1"=="rapid-experiment" (
    if "%CORE_EXPERIMENT_SUITE%"=="" set "CORE_EXPERIMENT_SUITE=win_port"
    call "!LIBSCRIPT_ROOT_DIR!\_lib\cloud\core\experiment_cloud.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)

set "PACKAGE_NAME=win-port-suite"
call "%~dp0..\..\_common\component_core.cmd" %*
