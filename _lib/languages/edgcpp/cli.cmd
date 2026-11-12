@echo off
:: # cli.cmd
:: ## Overview
:: Command-line interface entry point for the EDG C/C++ Compiler Frontend (edgcpp) component on Windows.
:: ## Usage
:: cli.cmd [command] [version] [options]

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
    shift
    call "!SCRIPT_DIR!\benchmark_experiments.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)
if /i "%~1"=="cloud-experiments" (
    shift
    call "!LIBSCRIPT_ROOT_DIR!\_lib\cloud\core\experiment_cloud.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)
if /i "%~1"=="torture" (
    shift
    call "!SCRIPT_DIR!\torture_suite.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)

set "PACKAGE_NAME=edgcpp"
call "%~dp0..\..\_common\component_core.cmd" %*
