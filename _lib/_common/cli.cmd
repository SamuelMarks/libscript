@echo off
:: # cli.cmd
setlocal EnableDelayedExpansion
:: # LibScript CLI Utility Module (Windows Batch)
::
:: ## Overview
:: This module provides reusable CLI utilities for LibScript components,
:: primarily focused on consistent argument parsing and standardized output.
::
:: ## Usage
:: Call this script in your component's `cli.cmd`.
::
:: ```batch
:: call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\cli.cmd" :parse_args %*
:: ```

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
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

if not "%~1"=="" (
    if /i "%~1"=="help" goto :help
    if /i "%~1"=="--help" goto :help
    if /i "%~1"=="-h" goto :help
    goto %~1
)
exit /b 0

:: ## help
:: Displays usage assistance.
:help
:--help
:-h
echo Usage: %~n0 [command] [options]
exit /b 0

:: ## parse_args
:: Parses command-line arguments and populates configuration variables.
:parse_args
set "USE_DEFAULT_TAGS=true"
set "CUSTOM_TAGS="
set "BOOTSTRAP_SCRIPT="
set "DRY_RUN=false"
set "ARGS="

:: ## parse_loop
:: Parses command-line arguments and populates configuration variables.
:parse_loop
if "%~2"=="" (
    REM Export variables to parent context before exiting
    endlocal & (
        set "USE_DEFAULT_TAGS=%USE_DEFAULT_TAGS%"
        set "CUSTOM_TAGS=%CUSTOM_TAGS%"
        set "BOOTSTRAP_SCRIPT=%BOOTSTRAP_SCRIPT%"
        set "DRY_RUN=%DRY_RUN%"
        set "ARGS=%ARGS%"
    )
    exit /b 0
)
set "current_arg=%~2"

if /i "%current_arg%"=="--help" (
    echo Usage: [OPTIONS]
    exit /b 0
)
if /i "%current_arg%"=="-h" (
    echo Usage: [OPTIONS]
    exit /b 0
)

if /i "%current_arg%"=="--no-default-tags" (
    set "USE_DEFAULT_TAGS=false"
    shift & goto :parse_loop
)

if /i "%current_arg%"=="--tags" (
    if defined CUSTOM_TAGS (
        set "CUSTOM_TAGS=!CUSTOM_TAGS! %~3"
    ) else (
        set "CUSTOM_TAGS=%~3"
    )
    shift & shift & goto :parse_loop
)

if /i "%current_arg%"=="--bootstrap" (
    set "BOOTSTRAP_SCRIPT=%~3"
    shift & shift & goto :parse_loop
)

if /i "%current_arg%"=="--dry-run" (
    set "DRY_RUN=true"
    shift & goto :parse_loop
)

:: If it doesn't match an option, it's a positional argument
if defined ARGS (
    set "ARGS=!ARGS! !current_arg!"
) else (
    set "ARGS=!current_arg!"
)
shift
goto :parse_loop




