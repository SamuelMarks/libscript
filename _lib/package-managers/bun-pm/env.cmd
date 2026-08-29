@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for bun-pm on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for bun-pm.

:: Windows env stub for bun-pm
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%BUN_PM_VERSION%"=="" (
    set "BUN_PM_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\bun-pm\%BUN_PM_VERSION%\bin;%PATH%"
