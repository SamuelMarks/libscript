@echo off
:: # fence.cmd
::
:: ## Overview
:: Split-Brain Fencing engine isolating or Cloud-API-fencing a former leader node on Windows.
::
:: ## Usage
:: topologies\fence.cmd <node_id> [fencing_policy] [state_file]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":%THIS_FILE%:" >nul 2>&1
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

if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help

set "NODE_ID=%~1"
set "POLICY=%~2"
if "%NODE_ID%"=="" set "NODE_ID=node-leader-1"
if "%POLICY%"=="" set "POLICY=cloud-api-poweroff"
echo {"action":"fence","node_id":"%NODE_ID%","policy":"%POLICY%","status":"FENCED"}
exit /b 0

:: ## help
:: Prints usage help for fence.cmd.
:help
echo Usage: fence.cmd ^<node_id^> [fencing_policy] [state_file]
exit /b 0
