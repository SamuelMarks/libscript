@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entrypoint for the psmux component on Windows.
:: It initializes the lifecycle and delegates execution to the shared batch components.
::
:: ## Usage
:: Execute this script directly to run the CLI functionality for the component.

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

set "PACKAGE_NAME=psmux"

set "ACTION=%~1"
if "%ACTION%"=="install" goto :delegate
if "%ACTION%"=="test" goto :delegate
if "%ACTION%"=="uninstall" goto :delegate
if "%ACTION%"=="remove" goto :delegate
if "%ACTION%"=="info" goto :delegate
if "%ACTION%"=="env" goto :delegate

set "LOG_CMD=%~dp0..\..\_common\log.cmd"

if "%~1"=="--help" (
    echo Usage: %~nx0 ^<action^> [args...]
    echo See README.md for details.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 ^<action^> [args...]
    echo See README.md for details.
    exit /b 0
)

where psmux >nul 2>nul
if %errorlevel% neq 0 (
    if exist "%ProgramFiles%\psmux\psmux.cmd" set "PATH=%ProgramFiles%\psmux;!PATH!"
    if exist "%USERPROFILE%\.local\bin\psmux.cmd" set "PATH=%USERPROFILE%\.local\bin;!PATH!"
)

where psmux >nul 2>nul
if %errorlevel% neq 0 (
    call "!LOG_CMD!" :log_error "psmux not found. Please ensure it is installed and in your PATH."
    exit /b 1
)

psmux %*
exit /b %errorlevel%

:: ## delegate
:: Delegates execution to the shared component_core router.
:delegate
call "%~dp0\..\..\_common\component_core.cmd" %*
exit /b %errorlevel%
