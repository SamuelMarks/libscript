@echo off
:: # update.cmd
::
:: ## Overview
:: Updates the local package registry with the latest upstream information.
:: 
:: ## Usage
:: Execute this script to refresh registry indices.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if exist "%SCRIPT_DIR%update_db.cmd" (
    call "%SCRIPT_DIR%update_db.cmd"
) else if exist "%SCRIPT_DIR%update_db.sh" (
    REM If WSL or git bash is available
    sh "%SCRIPT_DIR%update_db.sh"
) else (
    echo Error: update_db script not found. 1>&2
    exit /b 1
)
exit /b !errorlevel!
