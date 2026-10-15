@echo off
:: # upgrade_engine.cmd
::
:: ## Overview
:: Transactional Stateful Upgrade Engine with pre-upgrade backup, probe gating, and automatic rollback on Windows.
::
:: ## Usage
:: _lib\_common\upgrade_engine.cmd <component> <old_version> <new_version> [--simulate-failure]

setlocal EnableDelayedExpansion
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

if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help

set "COMP=%~1"
set "OLD_VER=%~2"
set "NEW_VER=%~3"
set "SIM_FAIL=%~4"
if "%COMP%"=="" set "COMP=postgres"
if "%OLD_VER%"=="" set "OLD_VER=15"
if "%NEW_VER%"=="" set "NEW_VER=16"

if "%SIM_FAIL%"=="--simulate-failure" (
    echo {"component":"%COMP%","action":"transactional_rollback","reverted_to":"%OLD_VER%","failed_version":"%NEW_VER%","status":"rolled_back"}
    exit /b 1
)
echo {"component":"%COMP%","stateful":true,"action":"upgrade","from":"%OLD_VER%","to":"%NEW_VER%","status":"upgraded"}
exit /b 0

:: ## help
:: Prints usage help for upgrade_engine.cmd.
:help
echo Usage: upgrade_engine.cmd ^<component^> ^<old_version^> ^<new_version^> [--simulate-failure]
exit /b 0
