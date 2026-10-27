@echo off
:: # merge_location_into_server.cmd
::
:: ## Overview
:: Lifecycle script for merge_location_into_server.cmd.
::
:: ## Usage
:: See merge_location_into_server.cmd for implementation details.

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

if "%~1"=="" (
    echo Usage: %0 ^<EXISTING_CONFIG^> ^<NEW_LOCATION_BLOCK^> ^<TARGET_SERVER_NAME^> [TARGET_LISTEN_REGEX]
    exit /b 1
)

set "TARGET_LISTEN_REGEX=443.*ssl"
if not "%~4"=="" set "TARGET_LISTEN_REGEX=%~4"

powershell -NoProfile -ExecutionPolicy Bypass -Command "& { . '%~dp0merge_location_into_server.ps1'; Merge-LocationIntoServer -ExistingConfig '%~1' -NewLocationBlock '%~2' -TargetServerName '%~3' -TargetListenRegex '%TARGET_LISTEN_REGEX%' }"
exit /b %ERRORLEVEL%
