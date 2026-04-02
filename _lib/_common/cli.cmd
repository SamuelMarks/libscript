@echo off
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

setlocal EnableDelayedExpansion

if not "%~1"=="" goto %~1
exit /b 0

:parse_args
set "USE_DEFAULT_TAGS=true"
set "CUSTOM_TAGS="
set "BOOTSTRAP_SCRIPT="
set "DRY_RUN=false"
set "ARGS="

:parse_loop
if "%~2"=="" (
    :: Export variables to parent context before exiting
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

:info
echo [INFO]  %~2
exit /b 0

:warn
echo [WARN]  %~2
exit /b 0

:error
echo [ERROR] %~2 1>&2
exit /b 1

:debug
if "%LIBSCRIPT_DEBUG%"=="1" echo [DEBUG] %~2
exit /b 0
