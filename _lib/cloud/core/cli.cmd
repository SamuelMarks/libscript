@echo off
:: # cli.cmd
::
:: ## Overview
:: Windows entry point for cloud orchestration commands (deploy, teardown, backup, restore).
::
:: ## Usage
:: Dispatches sub-commands (e.g., `deploy_cloud`, `teardown_cloud`) and manages remote state lock/unlock.

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

set "PACKAGE_NAME=core"

set "SKIP_STATE=0"
for %%a in (%*) do (
    if "%%a"=="diff" set "SKIP_STATE=1"
    if "%%a"=="list-managed" set "SKIP_STATE=1"
    if "%%a"=="status" set "SKIP_STATE=1"
    if "%%a"=="--help" set "SKIP_STATE=1"
    if "%%a"=="-h" set "SKIP_STATE=1"
)

if "%SKIP_STATE%"=="0" (
    if exist "%~dp0state_backend.cmd" (
        call "%~dp0state_backend.cmd" pull_state
        call "%~dp0state_backend.cmd" lock_state
        if errorlevel 1 exit /b 1
    )
)

call "%~dp0\..\..\_common\component_core.cmd" %*
set "CLI_ERR=%ERRORLEVEL%"

if "%SKIP_STATE%"=="0" (
    if exist "%~dp0state_backend.cmd" (
        call "%~dp0state_backend.cmd" push_state
        call "%~dp0state_backend.cmd" unlock_state
    )
)

exit /b %CLI_ERR%
